import 'package:ebroker/data/cubits/stories/delete_story_cubit.dart';
import 'package:ebroker/data/cubits/stories/fetch_my_stories_cubit.dart';
import 'package:ebroker/data/cubits/stories/fetch_stories_cubit.dart';
import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyStoriesScreen extends StatefulWidget {
  const MyStoriesScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const MyStoriesScreen());
  }

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<FetchMyStoriesCubit>().fetch());
    });
  }

  bool _canDelete(StoryItemModel story) {
    final createdAt = DateTime.tryParse(story.createdAt ?? '');
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt) < const Duration(hours: 24);
  }

  Future<void> _onTapDelete(StoryItemModel story) async {
    if (story.storyId == null) return;
    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }
    if (!_canDelete(story)) {
      HelperUtils.showSnackBarMessage(
        context,
        'storyDeleteWindowExpired',
        type: .error,
      );
      return;
    }
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'areYouSure'.translate(context),
        svgImagePath: AppIcons.deleteIllustration,
        content: CustomText(
          'thisStoryWillBeDeletedPermanently'.translate(context),
          textAlign: .center,
        ),
        onAccept: () async {
          await context.read<DeleteStoryCubit>().delete(story.storyId!);
        },
      ),
    );
  }

  /// Opens the story viewer scoped to just this one story, so tapping a
  /// card previews it without pulling in the rest of the user's stories.
  Future<void> _onTapPreview(StoryItemModel story) async {
    final user = HiveUtils.getUserDetails();
    final agent = StoryAgentModel(
      agentId: int.tryParse(HiveUtils.getUserId() ?? ''),
      agentName: user.name,
      agentProfileImage: user.profile,
      isAgentVerified: user.isAgentVerified ?? false,
      premiumStories: story.isPremium ? [story] : const [],
      nonPremiumStories: story.isPremium ? const [] : [story],
    );
    await Navigator.pushNamed(
      context,
      Routes.storyViewer,
      arguments: {
        'agents': [agent],
        'initialAgentIndex': 0,
        'userHasPremiumPropertiesAccess': true,
        'userHasPremiumProjectsAccess': true,
        'isGuest': false,
        'trackView': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteStoryCubit, DeleteStoryState>(
      listener: (context, state) {
        if (state is DeleteStorySuccess) {
          context.read<FetchMyStoriesCubit>().removeStory(state.storyId);
          unawaited(
            context.read<FetchStoriesCubit>().fetch(forceRefresh: true),
          );
          HelperUtils.showSnackBarMessage(
            context,
            'storyDeletedSuccessfully',
            type: .success,
          );
        }
        if (state is DeleteStoryFailure) {
          HelperUtils.showSnackBarMessage(
            context,
            state.errorMessage,
            type: .error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(title: 'myStories'.translate(context)),
        body: BlocBuilder<FetchMyStoriesCubit, FetchMyStoriesState>(
          builder: (context, state) {
            if (state is FetchMyStoriesLoading ||
                state is FetchMyStoriesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FetchMyStoriesFailure) {
              return CustomRefreshIndicator(
                onRefresh: () => context.read<FetchMyStoriesCubit>().fetch(),
                child: ListView(
                  physics: Constant.scrollPhysics,
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: SomethingWentWrong(
                        errorMessage: state.errorMessage,
                      ),
                    ),
                  ],
                ),
              );
            }
            final data = (state as FetchMyStoriesSuccess).data;
            // Newest first — the opposite of the public viewer's ascending
            // playback order (management view = "what did I just post").
            final all = [...data.premiumStories, ...data.nonPremiumStories]
              ..sort(
                (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
              );
            if (all.isEmpty) {
              return NoDataFound(
                title: 'noStoriesYet'.translate(context),
                description: 'noStoriesYetDescription'.translate(context),
                showRetryButton: false,
                onTapRetry: () {},
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<FetchMyStoriesCubit>().fetch(),
              child: ListView.separated(
                padding: EdgeInsets.all(16.rw(context)),
                itemCount: all.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: 12.rh(context)),
                itemBuilder: (context, index) {
                  return _MyStoryTile(
                    story: all[index],
                    canDelete: _canDelete(all[index]),
                    onDelete: () => _onTapDelete(all[index]),
                    onTap: () => _onTapPreview(all[index]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyStoryTile extends StatelessWidget {
  const _MyStoryTile({
    required this.story,
    required this.canDelete,
    required this.onDelete,
    required this.onTap,
  });

  final StoryItemModel story;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  /// e.g. "12h" — story createdAt relative to now, since stories expire in
  /// 24h. Falls back to empty when createdAt is missing/unparsable.
  String get _timeAgo {
    final createdAt = story.createdAt;
    if (createdAt == null || createdAt.isEmpty) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    return timeago.format(date, locale: 'en_short');
  }

  @override
  Widget build(BuildContext context) {
    final isExpiredOrDisabled = story.isActive == false;
    return Opacity(
      opacity: isExpiredOrDisabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10.rw(context)),
          decoration: BoxDecoration(
            border: Border.all(color: context.color.borderColor),
            borderRadius: BorderRadius.circular(10),
            color: context.color.secondaryColor,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImage(
                  imageUrl: story.thumbnailUrl ?? story.mediaUrl ?? '',
                  width: 56.rw(context),
                  height: 56.rh(context),
                ),
              ),
              SizedBox(width: 12.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      story.linkedEntity?.title ?? '',
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4.rh(context)),
                    Row(
                      spacing: 6.rw(context),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          isExpiredOrDisabled
                              ? 'expired'.translate(context)
                              : '${story.viewCount ?? 0} ${'views'.translate(context)}',
                          fontSize: context.font.sm,
                          color: context.color.textLightColor,
                        ),
                        if (_timeAgo.isNotEmpty) ...[
                          CustomText(
                            _timeAgo,
                            fontSize: context.font.sm,
                            color: context.color.textLightColor,
                          ),
                        ],
                        if (story.linkedEntity?.type != null) ...[
                          _ListingTypeChip(type: story.linkedEntity!.type!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Opacity(
                  opacity: canDelete ? 1 : 0.4,
                  child: CustomImage(
                    imageUrl: AppIcons.delete,
                    width: 20.rw(context),
                    height: 20.rh(context),
                    color: context.color.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill badge for the linked entity's kind ('property' / 'project') —
/// the my-stories API's `linked_entity` doesn't include a sell/rent or
/// construction-stage field, so this just distinguishes the two kinds.
class _ListingTypeChip extends StatelessWidget {
  const _ListingTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22.rh(context),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10.rw(context)),
      decoration: BoxDecoration(
        color: context.color.tertiaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(48),
      ),
      child: CustomText(
        type.toLowerCase().translate(context),
        fontWeight: FontWeight.w500,
        fontSize: context.font.xxs,
        color: context.color.tertiaryColor,
      ),
    );
  }
}
