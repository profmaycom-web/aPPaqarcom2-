import 'package:ebroker/data/cubits/chat_cubits/get_chat_users.dart';
import 'package:ebroker/data/cubits/project/fetch_my_projects_cubit.dart';
import 'package:ebroker/data/cubits/property/fetch_my_properties_cubit.dart';
import 'package:ebroker/utils/hive_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:material_ui/material_ui.dart';

/// The two roles a logged-in user can assume.
enum ActiveRole {
  user,
  agent;

  /// Serialise to the string stored in Hive / sent in the API header.
  String get value => name; // 'user' | 'agent'

  /// Deserialise from a raw Hive / API string.
  /// Falls back to [ActiveRole.user] for unknown values.
  static ActiveRole fromString(String? raw) {
    return ActiveRole.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => ActiveRole.user,
    );
  }
}

/// Tracks the user's active role globally.
/// Persists across restarts via Hive (userDetailsBox / activeRole key).
/// Pattern mirrors GuestChecker.
class ActiveRoleManager {
  ActiveRoleManager._();

  static final ValueNotifier<ActiveRole> _role = ValueNotifier<ActiveRole>(
    _readFromHive(),
  );

  static ActiveRole _readFromHive() {
    final raw = Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).get(HiveKeys.activeRole)?.toString();
    return ActiveRole.fromString(raw);
  }

  /// Re-reads from Hive. Call in MainActivityState.initState() so
  /// re-login after logout resets the notifier (userDetailsBox is
  /// cleared on logout, so next read returns [ActiveRole.user]).
  static void syncFromHive() {
    _role.value = _readFromHive();
  }

  static ActiveRole get currentRole => _role.value;

  /// Convenience: the string value sent in the `X-Active-Role` header.
  static String get currentRoleValue => _role.value.value;

  static bool get isAgent => _role.value == ActiveRole.agent;

  static ValueNotifier<ActiveRole> get notifier => _role;

  static Future<void> switchToAgent(BuildContext context) async {
    await Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.activeRole, ActiveRole.agent.value);
    _role.value = ActiveRole.agent;
    clear(context);
  }

  static Future<void> switchToUser(BuildContext context) async {
    await Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.activeRole, ActiveRole.user.value);
    _role.value = ActiveRole.user;
    clear(context);
  }

  static void clear(BuildContext context) {
    context.read<FetchMyPropertiesCubit>().clear();
    context.read<FetchMyProjectsCubit>().clear();
    context.read<GetChatListCubit>().clear();
  }
}

/// Freezes a role value for a subtree so descendants render that role
/// regardless of the global [ActiveRoleManager.notifier]. Used during
/// role-switch animations so the outgoing tree keeps its look while the
/// incoming tree shows the new role — both visible simultaneously.
class RoleScope extends InheritedWidget {
  const RoleScope({required this.role, required super.child, super.key});

  final ActiveRole role;

  static ActiveRole of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RoleScope>();
    return scope?.role ?? ActiveRoleManager.currentRole;
  }

  @override
  bool updateShouldNotify(RoleScope oldWidget) => role != oldWidget.role;
}
