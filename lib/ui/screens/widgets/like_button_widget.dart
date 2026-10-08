import 'package:ebroker/data/cubits/favorite/add_to_favorite_cubit.dart';
import 'package:ebroker/data/cubits/favorite/fetch_favorites_cubit.dart';
import 'package:ebroker/data/cubits/utility/like_properties.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/guest_checker.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class LikeButtonWidget extends StatefulWidget {
  const LikeButtonWidget({
    required this.propertyId,
    required this.isFavourite,
    super.key,
    this.size,
    this.backgroundColor,
  });

  final int propertyId;
  final bool isFavourite;
  final double? size;
  final Color? backgroundColor;

  @override
  State<LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1, end: 1.4),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.4, end: 1),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncInitialFavorite());
  }

  @override
  void didUpdateWidget(covariant LikeButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyId != widget.propertyId ||
        oldWidget.isFavourite != widget.isFavourite) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncInitialFavorite(),
      );
    }
  }

  void _syncInitialFavorite() {
    if (!mounted || !widget.isFavourite) return;
    context.read<LikedPropertiesCubit>().setLike(
      widget.propertyId,
      isLiked: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget setFavorite(int propertyId, BuildContext context) {
    final size = widget.size?.rw(context) ?? 24.rw(context);
    return BlocListener<AddToFavoriteCubitCubit, AddToFavoriteCubitState>(
      listener: (context, state) {
        if (state is AddToFavoriteCubitFailure &&
            state.id == widget.propertyId) {
          context.read<LikedPropertiesCubit>().toggleLike(widget.propertyId);
        }
      },
      child: BlocBuilder<LikedPropertiesCubit, LikedPropertiesState>(
        builder: (context, likedState) {
          final isLiked = likedState.likedProperties.contains(
            widget.propertyId,
          );
          return GestureDetector(
            onTap: () async {
              await GuestChecker.check(
                onNotGuest: () async {
                  await _controller.forward(from: 0);

                  context.read<LikedPropertiesCubit>().toggleLike(
                    widget.propertyId,
                  );

                  final type = isLiked ? FavoriteType.remove : FavoriteType.add;
                  await context.read<AddToFavoriteCubitCubit>().setFavorite(
                    propertyId: widget.propertyId,
                    type: type,
                  );
                  if (type == FavoriteType.remove) {
                    context.read<FetchFavoritesCubit>().remove(
                      widget.propertyId,
                    );
                  }
                },
              );
            },
            child: Container(
              padding: widget.backgroundColor == null
                  ? .all(6.rw(context))
                  : .zero,
              alignment: Alignment.center,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? context.color.primaryColor,
                shape: .circle,
                boxShadow: [
                  if (widget.backgroundColor == null)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 12,
                    ),
                ],
              ),
              child: BlocBuilder<LikedPropertiesCubit, LikedPropertiesState>(
                builder: (context, state) {
                  return ScaleTransition(
                    scale: _scaleAnimation,
                    child: CustomImage(
                      width: size,
                      height: size,
                      fit: .contain,
                      imageUrl: isLiked ? AppIcons.heartFilled : AppIcons.heart,
                      color: widget.backgroundColor == null
                          ? context.color.tertiaryColor
                          : Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (RoleScope.of(context) == ActiveRole.agent) {
      return const SizedBox.shrink();
    }
    return setFavorite(widget.propertyId, context);
  }
}
