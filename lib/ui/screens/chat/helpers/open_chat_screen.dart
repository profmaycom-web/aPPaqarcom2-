import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/utils/network/network_availability.dart';

/// Opens [chatScreen] with the same checks and cubits used by the property
/// chat, so every entry point (property, project, agent) behaves the same.
Future<void> openChatScreen(
  BuildContext context, {
  required ChatScreenNew chatScreen,
}) async {
  await CheckInternet.check(
    onInternet: () async {
      await GuestChecker.check(
        onNotGuest: () async {
          final cubit = context.read<GetChatListCubit>();

          // On a fresh install (or right after login) the cubit may still be in
          // Initial or InProgress state because the fetch launched in app.dart
          // hasn't completed yet.  Wait for it to settle so the button works
          // immediately without needing an app restart.
          if (cubit.state is! GetChatListSuccess &&
              cubit.state is! GetChatListFailed) {
            // Trigger a fetch if it hasn't started yet.
            if (cubit.state is GetChatListInitial) {
              unawaited(cubit.fetch(forceRefresh: false));
            }
            // Wait until the cubit leaves the loading state.
            await cubit.stream.firstWhere(
              (s) => s is GetChatListSuccess || s is GetChatListFailed,
            );
          }

          if (!context.mounted) return;
          final chatState = cubit.state;

          if (chatState is GetChatListSuccess) {
            await Navigator.push(
              context,
              CupertinoPageRoute<dynamic>(
                builder: (context) {
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) => SendMessageCubit(),
                      ),
                      BlocProvider(
                        create: (context) => LoadChatMessagesCubit(),
                      ),
                      BlocProvider(
                        create: (context) => DeleteMessageCubit(),
                      ),
                    ],
                    child: chatScreen,
                  );
                },
              ),
            );
          }
          if (chatState is GetChatListFailed) {
            HelperUtils.showSnackBarMessage(
              context,
              chatState.error.toString(),
              type: .error,
            );
          }
        },
      );
    },
    onNoInternet: () {
      HelperUtils.showSnackBarMessage(
        context,
        'noInternet',
        type: .error,
      );
    },
  );
}
