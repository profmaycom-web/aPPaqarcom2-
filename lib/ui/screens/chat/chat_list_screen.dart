import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const ChatListScreen();
      },
    );
  }

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(() async {
      if (_scrollController.isEndReached() && mounted) {
        if (context.read<GetChatListCubit>().hasMoreData()) {
          await context.read<GetChatListCubit>().loadMore();
        }
      }
    });
    if (context.read<GetChatListCubit>().state is! GetChatListSuccess) {
      unawaited(context.read<GetChatListCubit>().fetch(forceRefresh: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: 'message'.translate(context),
          isFromHome: true,
          showBackButton: false,
        ),
        body: CustomRefreshIndicator(
          onRefresh: () async {
            await context.read<GetChatListCubit>().fetch(forceRefresh: true);
          },
          child: BlocBuilder<GetChatListCubit, GetChatListState>(
            builder: (context, state) {
              final activeTab = state is GetChatListSuccess
                  ? state.activeTab
                  : context.read<GetChatListCubit>().activeTab;

              if (state is GetChatListFailed) {
                return Column(
                  children: [
                    _buildTabBar(context, activeTab),
                    Expanded(
                      child: Center(
                        child: SomethingWentWrong(
                          errorMessage: state.error.toString(),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state is GetChatListInProgress) {
                return Column(
                  children: [
                    _buildTabBar(context, activeTab),
                    Expanded(child: buildChatListShimmer()),
                  ],
                );
              }

              if (state is GetChatListSuccess) {
                return Column(
                  children: [
                    _buildTabBar(context, state.activeTab),
                    Expanded(
                      child: state.chatedUserList.isEmpty
                          ? NoDataFound(
                              onTapRetry: () {
                                context.read<GetChatListCubit>().fetch(
                                  forceRefresh: true,
                                );
                              },
                              title: 'noChatFound'.translate(context),
                              description:
                                  'startConversingToSeeYourMessagesHere'
                                      .translate(context),
                              svgImagePath: AppIcons.noChatFound,
                            )
                          : ListView.builder(
                              physics: Constant.scrollPhysics,
                              controller: _scrollController,
                              itemCount: state.chatedUserList.length,
                              padding: EdgeInsets.fromLTRB(
                                16.rw(context),
                                _listTopPadding(context),
                                16.rw(context),
                                32.rh(context),
                              ),
                              itemBuilder: (context, index) {
                                final chatedUser = state.chatedUserList[index];

                                return ChatTile(
                                  id: chatedUser.userId.toString(),
                                  propertyId:
                                      chatedUser.propertyId?.toString() ?? '0',
                                  profilePicture: chatedUser.profile ?? '',
                                  userName: chatedUser.name ?? '',
                                  propertyPicture: chatedUser.titleImage ?? '',
                                  propertyName:
                                      chatedUser.translatedTitle ??
                                      chatedUser.title ??
                                      '',
                                  pendingMessageCount:
                                      chatedUser.unreadCount?.toString() ?? '',
                                  isBlockedByMe:
                                      chatedUser.isBlockedByMe ?? false,
                                  isBlockedByUser:
                                      chatedUser.isBlockedByUser ?? false,
                                  isAgent: chatedUser.isAgent ?? false,
                                  isAgentVerified:
                                      chatedUser.isAgentVerified ?? false,
                                  isUserVerified:
                                      chatedUser.isUserVerified ?? false,
                                  isAdmin: chatedUser.isAdmin ?? false,
                                  phoneNumber: chatedUser.phoneNumber,
                                  propertySlugId: chatedUser.propertySlugId,
                                  hasProperty:
                                      chatedUser.hasProperty ??
                                      (chatedUser.propertyId != null &&
                                          chatedUser.propertyId != 0),
                                  receiverRoleContext:
                                      chatedUser.receiverRoleContext,
                                  isAppointmentAvailable:
                                      chatedUser.isAppointmentAvailable ??
                                      false,
                                  chatType:
                                      chatedUser.chatType ?? state.activeTab,
                                  lastMessage: chatedUser.lastMessage,
                                  time:
                                      chatedUser.timeAgo ??
                                      ChatTile.formatTime(
                                        chatedUser.date ?? chatedUser.createdAt,
                                      ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // The tab bar already has its own bottom margin, so the list only needs
  // top spacing when the tab bar is hidden (agent mode).
  double _listTopPadding(BuildContext context) =>
      RoleScope.of(context) == ActiveRole.agent ? 16.rh(context) : 0;

  Widget _buildTabBar(BuildContext context, String currentTab) {
    // Agents only receive messages, so there is no sent/received switch.
    if (RoleScope.of(context) == ActiveRole.agent) {
      return const SizedBox.shrink();
    }

    final expectedIndex = currentTab.toLowerCase() == 'received' ? 1 : 0;
    if (_tabController.index != expectedIndex) {
      _tabController.index = expectedIndex;
    }

    return CustomTabBar(
      tabController: _tabController,
      isScrollable: false,
      tabBackgroundColor: context.color.tertiaryColor,
      tabs: [
        Tab(text: 'sent'.translate(context)),
        Tab(text: 'received'.translate(context)),
      ],
      onTap: (index) {
        final newTab = index == 0 ? 'sent' : 'received';
        if (newTab != context.read<GetChatListCubit>().activeTab) {
          unawaited(
            context.read<GetChatListCubit>().fetch(
              forceRefresh: true,
              chatType: newTab,
            ),
          );
        }
      },
    );
  }

  Widget buildChatListShimmer() {
    return ListView.builder(
      itemCount: 10,
      physics: Constant.scrollPhysics,
      padding: EdgeInsets.fromLTRB(
        16.rw(context),
        _listTopPadding(context),
        16.rw(context),
        32.rh(context),
      ),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsetsDirectional.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.color.borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                highlightColor: Theme.of(
                  context,
                ).colorScheme.shimmerHighlightColor,
                child: Container(
                  width: 48.rw(context),
                  height: 48.rh(context),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(width: 12.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(
                      height: 12,
                      borderRadius: 4,
                      width: 160.rw(context),
                    ),
                    SizedBox(height: 8.rh(context)),
                    CustomShimmer(
                      height: 10,
                      borderRadius: 4,
                      width: 220.rw(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => false;
}

class ChatTile extends StatelessWidget {
  const ChatTile({
    required this.profilePicture,
    required this.userName,
    required this.propertyPicture,
    required this.propertyName,
    required this.pendingMessageCount,
    required this.id,
    required this.propertyId,
    required this.isBlockedByMe,
    required this.isBlockedByUser,
    required this.isAgent,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.isAdmin,
    this.phoneNumber,
    this.propertySlugId,
    this.hasProperty = true,
    this.receiverRoleContext,
    this.isAppointmentAvailable = false,
    this.chatType = 'sent',
    this.lastMessage,
    this.time,
    super.key,
  });

  final String profilePicture;
  final String userName;
  final String propertyPicture;
  final String propertyName;
  final String propertyId;
  final String pendingMessageCount;
  final String id;
  final bool isBlockedByMe;
  final bool isBlockedByUser;
  final bool isAgent;
  final bool isAgentVerified;
  final bool isUserVerified;
  final bool isAdmin;
  final String? phoneNumber;
  final String? propertySlugId;
  final bool hasProperty;
  final String? receiverRoleContext;
  final bool isAppointmentAvailable;
  final String chatType;
  final String? lastMessage;
  final String? time;

  /// Formats the last message time: "5s ago" / "34m ago" within the last
  /// hour, "2:38 pm" earlier today, and "17 Sep" for older days.
  static String formatTime(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return '';
    final date = parsed.toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '${diff.inSeconds.clamp(1, 59)}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return DateFormat('h:mm a').format(date).toLowerCase();
    return DateFormat('d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isAgentFacing = RoleScope.of(context) == ActiveRole.agent;

    final bool showVerifiedBadge;
    final bool isAgentBadge;
    if (isAgentFacing) {
      showVerifiedBadge = isUserVerified;
      isAgentBadge = false;
    } else {
      final otherRole =
          receiverRoleContext ??
          (isAgent ? 'agent' : (isAdmin ? 'admin' : 'user'));
      if (otherRole == 'agent' || isAdmin) {
        showVerifiedBadge = isAgentVerified;
        isAgentBadge = true;
      } else {
        showVerifiedBadge = isUserVerified;
        isAgentBadge = false;
      }
    }

    // Direct chats (e.g. with an agent) have no property to show.
    final isDirectChat = !hasProperty;
    final subtitleText = isDirectChat
        ? 'directMessage'.translate(context)
        : (lastMessage != null && lastMessage!.isNotEmpty)
        ? lastMessage!
        : propertyName;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          CupertinoPageRoute<dynamic>(
            builder: (context) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => LoadChatMessagesCubit()),
                  BlocProvider(create: (context) => DeleteMessageCubit()),
                ],
                child: Builder(
                  builder: (context) {
                    return ChatScreenNew(
                      profilePicture: profilePicture,
                      proeprtyTitle: propertyName,
                      userId: id,
                      propertyImage: propertyPicture,
                      userName: userName,
                      propertyId: propertyId,
                      isBlockedByMe: isBlockedByMe,
                      isBlockedByUser: isBlockedByUser,
                      isAgent: isAgent,
                      isAgentVerified: isAgentVerified,
                      isUserVerified: isUserVerified,
                      isAdmin: isAdmin,
                      phoneNumber: phoneNumber,
                      propertySlugId: propertySlugId,
                      hasProperty: hasProperty,
                      receiverRoleContext: receiverRoleContext,
                      isAppointmentAvailable: isAppointmentAvailable,
                      chatType: chatType,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.color.borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            ClipOval(
              child: profilePicture.isNotEmpty
                  ? CustomImage(
                      imageUrl: profilePicture,
                      width: 48.rw(context),
                      height: 48.rh(context),
                    )
                  : Container(
                      width: 48.rw(context),
                      height: 48.rh(context),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CustomText(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        fontSize: context.font.lg,
                        fontWeight: FontWeight.w600,
                        color: context.color.tertiaryColor,
                      ),
                    ),
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          userName,
                          maxLines: 1,
                          fontWeight: FontWeight.bold,
                          fontSize: context.font.md,
                          color: context.color.textColorDark,
                        ),
                      ),
                      if (showVerifiedBadge) ...[
                        SizedBox(width: 4.rw(context)),
                        VerifiedBadge(
                          type: isAgentBadge ? BadgeType.agent : BadgeType.user,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.rh(context)),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          subtitleText,
                          maxLines: 1,
                          fontSize: context.font.xs,
                          fontStyle: isDirectChat ? FontStyle.italic : null,
                          color: context.color.textColorDark.withValues(
                            alpha: isDirectChat ? 0.5 : 0.7,
                          ),
                        ),
                      ),
                      if (time != null && time!.isNotEmpty) ...[
                        SizedBox(width: 8.rw(context)),
                        CustomText(
                          time!,
                          maxLines: 1,
                          fontSize: context.font.xxs,
                          color: context.color.textColorDark.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ],
                      if (isBlockedByMe || isBlockedByUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText(
                            'blocked'.translate(context),
                            color: Colors.red,
                            fontSize: context.font.xxs,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (pendingMessageCount != '0' &&
                          pendingMessageCount.isNotEmpty) ...[
                        SizedBox(width: 8.rw(context)),
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.color.tertiaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: CustomText(
                            pendingMessageCount,
                            color: context.color.buttonColor,
                            fontWeight: FontWeight.bold,
                            fontSize: context.font.xxs,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
