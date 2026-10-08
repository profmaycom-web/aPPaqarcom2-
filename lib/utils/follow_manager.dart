import 'dart:async';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/utils/hive_utils.dart';

class FollowChangeEvent {
  const FollowChangeEvent({
    required this.agentId,
    required this.isFollowing,
    this.followersCount,
  });

  final int agentId;
  final bool isFollowing;
  final String? followersCount;
}

class FollowManager {
  static final AgentsRepository _agentsRepository = AgentsRepository();
  static final StreamController<FollowChangeEvent> _followStreamController =
      StreamController<FollowChangeEvent>.broadcast();

  static final Set<int> _sessionFollowed = {};
  static final Set<int> _sessionUnfollowed = {};
  static final Map<int, String> _followersCountMap = {};

  static Stream<FollowChangeEvent> get onFollowChanged =>
      _followStreamController.stream;

  /// Caches an agent follower count.
  static void registerFollowersCount(
    int agentId,
    String count, {
    bool force = false,
  }) {
    if (count.isNotEmpty &&
        (force || !_followersCountMap.containsKey(agentId))) {
      _followersCountMap[agentId] = count;
    }
  }

  /// Returns cached follower count for an agent.
  static String? getFollowersCount(int agentId) {
    return _followersCountMap[agentId];
  }

  /// Asynchronously fetches follower count for an agent if not already cached.
  static Future<String?> fetchFollowersCount(
    int agentId, {
    bool isAdmin = false,
  }) async {
    final targetId = isAdmin ? 0 : agentId;
    final cached = _followersCountMap[targetId];
    if (cached != null && cached.isNotEmpty && cached != '0') {
      return cached;
    }

    try {
      final result = await _agentsRepository.fetchAgentProperties(
        offset: 0,
        agentId: targetId.toString(),
        isAdmin: isAdmin,
      );
      final customerData = result.agentsProperty.customerData;
      registerFollowStatus(
        targetId,
        isFollowing: customerData.isFollowing,
        isAdmin: isAdmin,
      );
      if (customerData.followersCount != null &&
          customerData.followersCount!.isNotEmpty) {
        _followersCountMap[targetId] = customerData.followersCount!;
        return customerData.followersCount;
      }
    } on Object catch (_) {}
    return null;
  }

  /// Registers an agent/admin follow status discovered from API responses or widgets.
  static void registerFollowStatus(
    int agentId, {
    required bool isFollowing,
    int? secondaryId,
    bool isAdmin = false,
  }) {
    final targetId = isAdmin ? 0 : agentId;
    if (isFollowing) {
      if (!_sessionUnfollowed.contains(targetId)) {
        _sessionFollowed.add(targetId);
        if (secondaryId != null) _sessionFollowed.add(secondaryId);
        unawaited(HiveUtils.setAgentFollowed(targetId, isFollowing: true));
        if (secondaryId != null) {
          unawaited(HiveUtils.setAgentFollowed(secondaryId, isFollowing: true));
        }
      }
    } else {
      if (!_sessionFollowed.contains(targetId) &&
          !HiveUtils.isAgentFollowedInHive(targetId)) {
        _sessionUnfollowed.add(targetId);
        if (secondaryId != null) _sessionUnfollowed.add(secondaryId);
      }
    }
  }

  /// Returns current in-memory session or Hive follow status, falling back to [initialValue].
  static bool isFollowingStatus(
    int agentId, {
    required bool initialValue,
    int? secondaryId,
    bool isAdmin = false,
  }) {
    final targetId = isAdmin ? 0 : agentId;
    if (isAdmin) {
      if (_sessionFollowed.contains(0)) return true;
      if (_sessionUnfollowed.contains(0)) return false;
      if (HiveUtils.isAgentFollowedInHive(0)) return true;
    } else {
      if (_sessionFollowed.contains(targetId) ||
          (secondaryId != null && _sessionFollowed.contains(secondaryId))) {
        return true;
      }
      if (_sessionUnfollowed.contains(targetId) ||
          (secondaryId != null && _sessionUnfollowed.contains(secondaryId))) {
        return false;
      }
      if (HiveUtils.isAgentFollowedInHive(targetId) ||
          (secondaryId != null &&
              HiveUtils.isAgentFollowedInHive(secondaryId))) {
        return true;
      }
    }
    return initialValue;
  }

  /// Clears in-memory follow session cache (e.g. upon user logout).
  static void clearCache() {
    _sessionFollowed.clear();
    _sessionUnfollowed.clear();
    _followersCountMap.clear();
  }

  /// Internal helper to adjust cached follower count by [delta].
  static void _adjustFollowersCount(int agentId, {required int delta}) {
    final cached = _followersCountMap[agentId];
    final current = int.tryParse(cached ?? '0') ?? 0;
    final updated = (current + delta).clamp(0, 999999999);
    _followersCountMap[agentId] = updated.toString();
  }

  /// Internal helper to apply follow status to in-memory sets and Hive storage.
  static void _applyFollowStatus(
    int targetId, {
    required bool isFollowing,
    int? secondaryId,
  }) {
    if (isFollowing) {
      _sessionFollowed.add(targetId);
      if (secondaryId != null) _sessionFollowed.add(secondaryId);
      _sessionUnfollowed.remove(targetId);
      if (secondaryId != null) _sessionUnfollowed.remove(secondaryId);
      unawaited(HiveUtils.setAgentFollowed(targetId, isFollowing: true));
      if (secondaryId != null) {
        unawaited(HiveUtils.setAgentFollowed(secondaryId, isFollowing: true));
      }
    } else {
      _sessionUnfollowed.add(targetId);
      if (secondaryId != null) _sessionUnfollowed.add(secondaryId);
      _sessionFollowed.remove(targetId);
      if (secondaryId != null) _sessionFollowed.remove(secondaryId);
      unawaited(HiveUtils.setAgentFollowed(targetId, isFollowing: false));
      if (secondaryId != null) {
        unawaited(HiveUtils.setAgentFollowed(secondaryId, isFollowing: false));
      }
    }
  }

  /// Toggles follow status for an agent or platform admin (isAdmin = true sends agent_id: 0).
  ///
  /// Optimistically flips local state & broadcasts update immediately.
  /// Overwrites with server response on success.
  /// Reverts and rethrows on network/API failure so callers can display error toasts.
  static Future<bool> toggleFollow(
    int agentId, {
    int? secondaryId,
    bool isAdmin = false,
  }) async {
    final targetId = isAdmin ? 0 : agentId;
    final prevStatus = isFollowingStatus(
      targetId,
      initialValue: false,
      secondaryId: secondaryId,
      isAdmin: isAdmin,
    );
    final optimisticStatus = !prevStatus;

    // 1. Optimistic local update & count adjustment
    _applyFollowStatus(
      targetId,
      secondaryId: secondaryId,
      isFollowing: optimisticStatus,
    );
    _adjustFollowersCount(targetId, delta: optimisticStatus ? 1 : -1);
    _followStreamController.add(
      FollowChangeEvent(
        agentId: targetId,
        isFollowing: optimisticStatus,
        followersCount: _followersCountMap[targetId],
      ),
    );

    try {
      // 2. Call server endpoint POST toggle-follow-agent
      final serverStatus = await _agentsRepository.toggleFollowAgent(
        agentId: targetId,
      );

      // 3. Overwrite local with server source of truth
      _applyFollowStatus(
        targetId,
        secondaryId: secondaryId,
        isFollowing: serverStatus,
      );
      if (serverStatus != optimisticStatus) {
        _adjustFollowersCount(targetId, delta: serverStatus ? 1 : -1);
        _followStreamController.add(
          FollowChangeEvent(
            agentId: targetId,
            isFollowing: serverStatus,
            followersCount: _followersCountMap[targetId],
          ),
        );
      }
      return serverStatus;
    } catch (e) {
      // 4. Roll back optimistic changes on failure and rethrow
      _applyFollowStatus(
        targetId,
        secondaryId: secondaryId,
        isFollowing: prevStatus,
      );
      _adjustFollowersCount(targetId, delta: prevStatus ? 1 : -1);
      _followStreamController.add(
        FollowChangeEvent(
          agentId: targetId,
          isFollowing: prevStatus,
          followersCount: _followersCountMap[targetId],
        ),
      );
      rethrow;
    }
  }
}
