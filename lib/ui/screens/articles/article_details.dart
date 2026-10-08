import 'package:ebroker/data/cubits/fetch_single_article_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:material_ui/material_ui.dart';

class ArticleDetails extends StatefulWidget {
  const ArticleDetails({
    this.articleId,
    this.slug,
    this.heroTag,
    this.heroImageUrl,
    this.articleTitle,
    this.articleDate,
    super.key,
  });

  final String? articleId;
  final String? slug;
  final String? heroTag;
  final String? heroImageUrl;
  final String? articleTitle;
  final String? articleDate;

  static Widget buildWithProviders({
    String? articleId,
    String? slug,
    String? heroTag,
    String? heroImageUrl,
    String? articleTitle,
    String? articleDate,
  }) {
    return ArticleDetails(
      articleId: articleId,
      slug: slug,
      heroTag: heroTag,
      heroImageUrl: heroImageUrl,
      articleTitle: articleTitle,
      articleDate: articleDate,
    );
  }

  static Route<dynamic> route(RouteSettings settings) {
    final args = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return ArticleDetails.buildWithProviders(
          articleId: args?['id'] as String?,
          slug: args?['slug'] as String?,
          heroTag: args?['heroTag'] as String?,
          heroImageUrl: args?['heroImageUrl'] as String?,
          articleTitle: args?['articleTitle'] as String?,
          articleDate: args?['articleDate'] as String?,
        );
      },
    );
  }

  @override
  State<ArticleDetails> createState() => _ArticleDetailsState();
}

class _ArticleDetailsState extends State<ArticleDetails> {
  @override
  void initState() {
    super.initState();
    HelperUtils.runAfterTransition(context, () {
      if (!mounted) return;
      if (widget.articleId != null) {
        unawaited(
          context.read<FetchSingleArticleCubit>().fetchArticlesById(
            widget.articleId!,
          ),
        );
      } else if (widget.slug != null) {
        unawaited(
          context.read<FetchSingleArticleCubit>().fetchArticlesBySlug(
            widget.slug!,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        context.read<FetchSingleArticleCubit>().clear();
      },
      child: BlocBuilder<FetchSingleArticleCubit, FetchSingleArticleState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.color.primaryColor,
            appBar: CustomAppBar(
              onTapBackButton: () {
                context.read<FetchSingleArticleCubit>().clear();
              },
              actions: [
                if (state is FetchSingleArticleSuccess)
                  GestureDetector(
                    onTap: () async {
                      await HelperUtils.shareArticle(
                        context,
                        state.articlemodel.slugId ?? '',
                      );
                    },
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 16),
                      alignment: Alignment.center,
                      child: CustomImage(
                        imageUrl: AppIcons.shareIcon,
                        height: 24.rh(context),
                        color: context.color.textColorDark,
                      ),
                    ),
                  ),
              ],
            ),
            body: _buildBody(state),
          );
        },
      ),
    );
  }

  Widget _buildShimmerView() {
    // Show the Hero-wrapped image immediately if available,
    // otherwise fall back to shimmer for the image area.
    final heroTag = widget.heroTag;
    final heroImageUrl = widget.heroImageUrl;

    Widget imageSection;
    if (heroImageUrl != null && heroImageUrl.isNotEmpty) {
      Widget image = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomImage(
          height: 200.rs(context),
          width: double.infinity,
          imageUrl: heroImageUrl,
        ),
      );
      if (heroTag != null) {
        image = Hero(tag: heroTag, child: image);
      }
      imageSection = image;
    } else {
      imageSection = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 200.rs(context),
          width: double.infinity,
          child: const CustomShimmer(),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageSection,
            SizedBox(height: 12.rh(context)),
            if (widget.articleDate != null)
              Row(
                children: [
                  Container(
                    height: 16.rh(context),
                    width: 16.rw(context),
                    alignment: Alignment.center,
                    child: CustomImage(
                      imageUrl: AppIcons.calendar,
                      color: context.color.textLightColor,
                    ),
                  ),
                  SizedBox(width: 4.rw(context)),
                  if (widget.heroTag != null)
                    Hero(
                      tag: '${widget.heroTag}-date',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CustomText(
                          widget.articleDate!.formatDate(),
                          color: context.color.textLightColor,
                          fontWeight: .w400,
                          fontSize: context.font.xxs,
                        ),
                      ),
                    )
                  else
                    CustomText(
                      widget.articleDate!.formatDate(),
                      color: context.color.textLightColor,
                      fontWeight: .w400,
                      fontSize: context.font.xxs,
                    ),
                ],
              )
            else
              Row(
                children: [
                  SizedBox(
                    height: 16.rh(context),
                    width: 80.rw(context),
                    child: const CustomShimmer(),
                  ),
                  SizedBox(width: 8.rw(context)),
                  SizedBox(
                    height: 16.rh(context),
                    width: 50.rw(context),
                    child: const CustomShimmer(),
                  ),
                ],
              ),
            SizedBox(height: 12.rh(context)),
            if (widget.articleTitle != null)
              if (widget.heroTag != null)
                Hero(
                  tag: '${widget.heroTag}-title',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      widget.articleTitle!.firstUpperCase(),
                      fontWeight: .w500,
                      fontSize: context.font.md,
                      color: context.color.textColorDark,
                    ),
                  ),
                )
              else
                CustomText(
                  widget.articleTitle!.firstUpperCase(),
                  fontWeight: .w500,
                  fontSize: context.font.md,
                  color: context.color.textColorDark,
                )
            else
              SizedBox(
                height: 24.rh(context),
                width: MediaQuery.of(context).size.width * 0.7,
                child: const CustomShimmer(),
              ),
            SizedBox(height: 12.rh(context)),
            SizedBox(
              height: 16.rh(context),
              width: double.infinity,
              child: const CustomShimmer(),
            ),
            SizedBox(height: 8.rh(context)),
            SizedBox(
              height: 16.rh(context),
              width: double.infinity,
              child: const CustomShimmer(),
            ),
            SizedBox(height: 8.rh(context)),
            SizedBox(
              height: 16.rh(context),
              width: MediaQuery.of(context).size.width * 0.8,
              child: const CustomShimmer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FetchSingleArticleState state) {
    return Builder(
      builder: (context) {
        if (state is FetchSingleArticleFailure) {
          return SomethingWentWrong(
            errorMessage: state.errorMessage,
          );
        }
        if (state is FetchSingleArticleInProgress ||
            state is FetchSingleArticleInitial) {
          return _buildShimmerView();
        }
        if (state is FetchSingleArticleSuccess) {
          return SingleChildScrollView(
            physics: Constant.scrollPhysics,
            clipBehavior: .none,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Builder(
                      builder: (context) {
                        Widget image = CustomImage(
                          height: 200.rs(context),
                          width: double.infinity,
                          showFullScreenImage: true,
                          imageUrl: state.articlemodel.image ?? '',
                        );
                        if (widget.heroTag != null) {
                          image = Hero(
                            tag: widget.heroTag!,
                            child: image,
                          );
                        }
                        return image;
                      },
                    ),
                  ),
                  SizedBox(height: 12.rh(context)),
                  Row(
                    children: [
                      Container(
                        height: 16.rh(context),
                        width: 16.rw(context),
                        alignment: Alignment.center,
                        child: CustomImage(
                          imageUrl: AppIcons.calendar,
                          color: context.color.textLightColor,
                        ),
                      ),
                      SizedBox(width: 4.rw(context)),
                      if (widget.heroTag != null)
                        Hero(
                          tag: '${widget.heroTag}-date',
                          child: Material(
                            type: MaterialType.transparency,
                            child: CustomText(
                              state.articlemodel.date == null
                                  ? ''
                                  : state.articlemodel.date
                                        .toString()
                                        .formatDate(),
                              color: context.color.textLightColor,
                              fontWeight: .w400,
                              fontSize: context.font.xxs,
                            ),
                          ),
                        )
                      else
                        CustomText(
                          state.articlemodel.date == null
                              ? ''
                              : state.articlemodel.date.toString().formatDate(),
                          color: context.color.textLightColor,
                          fontWeight: .w400,
                          fontSize: context.font.xxs,
                        ),
                      SizedBox(width: 8.rw(context)),
                      Container(
                        height: 16.rh(context),
                        width: 16.rw(context),
                        alignment: Alignment.center,
                        child: CustomImage(
                          imageUrl: AppIcons.eye,
                          color: context.color.textLightColor,
                        ),
                      ),
                      SizedBox(width: 4.rw(context)),
                      CustomText(
                        state.articlemodel.viewCount ?? '',
                        color: context.color.textLightColor,
                        fontWeight: .w400,
                        fontSize: context.font.xxs,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.rh(context)),
                  if (widget.heroTag != null)
                    Hero(
                      tag: '${widget.heroTag}-title',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CustomText(
                          (state.articlemodel.translatedTitle ??
                                  state.articlemodel.title ??
                                  '')
                              .firstUpperCase(),
                          fontWeight: .w500,
                          fontSize: context.font.md,
                          color: context.color.textColorDark,
                        ),
                      ),
                    )
                  else
                    CustomText(
                      (state.articlemodel.translatedTitle ??
                              state.articlemodel.title ??
                              '')
                          .firstUpperCase(),
                      fontWeight: .w500,
                      fontSize: context.font.md,
                      color: context.color.textColorDark,
                    ),
                  SizedBox(height: 12.rh(context)),
                  HtmlWidget(
                    state.articlemodel.translatedDescription ??
                        state.articlemodel.description ??
                        '',
                    textStyle: TextStyle(
                      fontSize: context.font.sm,
                      height: 1.45,
                      color: context.color.textLightColor,
                      fontWeight: .w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
