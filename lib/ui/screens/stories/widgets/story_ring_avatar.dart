import 'package:ebroker/data/cubits/stories/fetch_my_stories_cubit.dart';
import 'package:ebroker/data/cubits/stories/fetch_stories_cubit.dart';
import 'package:ebroker/data/cubits/stories/upload_story_cubit.dart';
import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/data/repositories/stories_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps an existing avatar [child] with a themed "has stories" ring.
///
/// Does a single scoped fetch on init using exactly one of [agentId].
/// If the fetch fails or returns no stories,
/// [child] is rendered unchanged — this is decorative, not critical UI, so
/// it never surfaces its own error state. On success, wraps [child] in a
/// themed ring and a tap handler that opens the story viewer directly
/// (no bubble/preview step), scoped to just the stories this fetch found.
///
/// When [showAddButton] is true (only used for the signed-in agent's own
/// avatar), this also overlays a "+" button that calls [onAddTap], and
/// watches the global [UploadStoryCubit] to show an in-progress spinner
/// (disabling the "+" button) and success/failure snackbars — this is the
/// single centralized place story-upload progress is surfaced anywhere in
/// the app.
class StoryRingAvatar extends StatefulWidget {
  const StoryRingAvatar({
    required this.child,
    this.borderRadius,
    this.agentId,
    this.isAdmin = false,
    this.showAddButton = false,
    this.onAddTap,
    super.key,
  }) : assert(
         (agentId != null ? 1 : 0) == 1,
         'Pass exactly one of agentId',
       );

  final Widget child;

  /// Null draws a circular ring; non-null draws a rounded-rect ring with
  /// this radius. Should match the corner radius `child` already uses.
  final double? borderRadius;
  final int? agentId;

  /// Whether the current viewer is an admin — threaded to the stories
  /// fetch so admins viewing another agent's details page are authorized
  /// to see that agent's story ring.
  final bool isAdmin;

  /// When true, overlays a "+" button and watches [UploadStoryCubit].
  final bool showAddButton;
  final VoidCallback? onAddTap;

  @override
  State<StoryRingAvatar> createState() => _StoryRingAvatarState();
}

class _StoryRingAvatarState extends State<StoryRingAvatar> {
  final StoriesRepository _repository = StoriesRepository();
  StoriesResponseModel? _data;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final data = await _repository.fetchStories(
        agentId: widget.agentId,
        isAdmin: widget.isAdmin,
      );
      final hasStories = data.agents.any(
        (agent) => agent.orderedStories.isNotEmpty,
      );
      if (mounted) {
        setState(() {
          _data = hasStories ? data : null;
        });
      }
    } on Exception {
      // Decorative ring only — any failure is treated as "no stories".
    }
  }

  void _onUploadStateChanged(BuildContext context, UploadStoryState state) {
    if (state is UploadStorySuccess) {
      unawaited(_load());
      unawaited(context.read<FetchStoriesCubit>().fetch(forceRefresh: true));
      unawaited(context.read<FetchMyStoriesCubit>().fetch());
      HelperUtils.showSnackBarMessage(
        context,
        'storyUploadedSuccessfully',
        type: .success,
      );
      context.read<UploadStoryCubit>().reset();
    }
    if (state is UploadStoryFailure) {
      HelperUtils.showSnackBarMessage(
        context,
        state.errorMessage,
        type: .error,
      );
      context.read<UploadStoryCubit>().reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAddButton) {
      final data = _data;
      return data == null ? widget.child : _buildRing(context, data);
    }
    return BlocConsumer<UploadStoryCubit, UploadStoryState>(
      listener: _onUploadStateChanged,
      builder: (context, uploadState) {
        final data = _data;
        final base = data == null ? widget.child : _buildRing(context, data);
        return _buildAddOverlay(context, base, uploadState);
      },
    );
  }

  Widget _buildRing(BuildContext context, StoriesResponseModel data) {
    final hasUnseen =
        data.isGuest || data.agents.any((agent) => agent.hasUnseenStory);
    final ringColor = hasUnseen ? context.color.tertiaryColor : Colors.grey;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.storyViewer,
          arguments: {
            'agents': data.agents,
            'initialAgentIndex': 0,
            'userHasPremiumPropertiesAccess':
                data.userHasPremiumPropertiesAccess,
            'userHasPremiumProjectsAccess': data.userHasPremiumProjectsAccess,
            'isGuest': data.isGuest,
            'isAdmin': widget.isAdmin,
            // showAddButton is only ever true for the signed-in agent's own
            // avatar (profile_header.dart) — viewing your own stories there
            // shouldn't count as a view.
            'trackView': !widget.showAddButton,
          },
        );
        // Refresh with the same agentId filter this ring was scoped to so
        // its seen/unseen ring color reflects what was just viewed.
        if (mounted) unawaited(_load());
      },
      child: Container(
        //padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: widget.borderRadius == null
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: widget.borderRadius != null
              ? BorderRadius.circular((widget.borderRadius ?? 0) + 4)
              : null,
          border: Border.all(color: ringColor, width: 2.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 100),
          child: widget.child,
        ),
      ),
    );
  }

  Widget _buildAddOverlay(
    BuildContext context,
    Widget base,
    UploadStoryState uploadState,
  ) {
    final isUploading = uploadState is UploadStoryInProgress;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        base,
        if (isUploading)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: widget.borderRadius == null
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  borderRadius: widget.borderRadius != null
                      ? .circular(widget.borderRadius ?? 0)
                      : null,
                  color: Colors.black26,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          end: 0,
          start: 0,
          bottom: -10.rh(context),
          child: GestureDetector(
            onTap: isUploading ? null : widget.onAddTap,
            child: Opacity(
              opacity: isUploading ? 0.5 : 1,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.color.tertiaryColor,
                  border: Border.all(
                    color: context.color.secondaryColor,
                    width: 2,
                  ),
                ),
                child: CustomImage(
                  imageUrl: AppIcons.plusButtonIcon,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.buttonColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
