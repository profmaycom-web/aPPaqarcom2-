import 'package:ebroker/data/model/article_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/articles/article_card.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:material_ui/material_ui.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key, this.isFromHome = false});

  final bool isFromHome;

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map<String, dynamic>? ?? {};
    final isFromHome = arguments['isFromHome'] as bool? ?? false;
    return CupertinoPageRoute(
      builder: (context) {
        return ArticlesScreen(isFromHome: isFromHome);
      },
    );
  }

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final ScrollController _pageScrollController = ScrollController();
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (context.read<FetchCategoryCubit>().state is! FetchCategorySuccess) {
      unawaited(context.read<FetchCategoryCubit>().fetchCategories());
    }
    unawaited(
      context.read<FetchArticlesCubit>().fetchArticles(
        categoryId: selectedCategoryId,
      ),
    );
    _pageScrollController.addListener(pageScrollListen);
  }

  Future<void> pageScrollListen() async {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchArticlesCubit>().hasMoreData()) {
        await context.read<FetchArticlesCubit>().fetchArticlesMore();
      }
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'articles'.translate(context),
      ),
      body: Column(
        children: [
          buildCategoryFilterBar(),
          Expanded(
            child: CustomRefreshIndicator(
              onRefresh: () async {
                await context.read<FetchArticlesCubit>().fetchArticles(
                  categoryId: selectedCategoryId,
                );
              },
              child: BlocBuilder<FetchArticlesCubit, FetchArticlesState>(
                builder: (context, state) {
                  if (state is FetchArticlesInProgress) {
                    return buildArticlesShimmer();
                  }
                  if (state is FetchArticlesFailure) {
                    if (state.errorMessage is NoInternetConnectionError) {
                      return NoInternet(
                        onRetry: () {
                          unawaited(
                            context.read<FetchArticlesCubit>().fetchArticles(
                              categoryId: selectedCategoryId,
                            ),
                          );
                        },
                      );
                    }

                    return SomethingWentWrong(
                      errorMessage: state.errorMessage,
                    );
                  }
                  if (state is FetchArticlesSuccess) {
                    if (state.articlemodel.isEmpty) {
                      return NoDataFound(
                        title: 'noArticlesFound'.translate(context),
                        description: '',
                        onTapRetry: () async {
                          await context
                              .read<FetchArticlesCubit>()
                              .fetchArticles(
                                categoryId: selectedCategoryId,
                              );
                        },
                      );
                    }
                    return Column(
                      mainAxisSize: .min,
                      children: <Widget>[
                        Expanded(
                          child: ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                                  height: 8,
                                ),
                            controller: _pageScrollController,
                            shrinkWrap: true,
                            physics: Constant.scrollPhysics,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.articlemodel.length,
                            itemBuilder: (context, index) {
                              final article = state.articlemodel[index];

                              return buildArticleCard(
                                context,
                                article: article,
                                isFromHome: widget.isFromHome,
                              );
                            },
                          ),
                        ),
                        if (state.isLoadingMore)
                          const CircularProgressIndicator(),
                        if (state.loadingMoreError)
                          CustomText('somethingWentWrong'.translate(context)),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildArticleCard(
    BuildContext context, {
    required ArticleModel article,
    required bool isFromHome,
  }) {
    return ArticleCard(article: article, isFromHome: isFromHome);
  }

  Widget buildArticlesShimmer() {
    return ListView.separated(
      separatorBuilder: (context, index) => SizedBox(height: 8.rh(context)),
      itemCount: 10,
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          width: double.infinity,
          height: 279.rh(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: context.color.secondaryColor,
            border: Border.all(
              color: context.color.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              CustomShimmer(
                width: double.infinity,
                height: 160.rh(context),
              ),
              SizedBox(height: 8.rh(context)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 100.rw(context),
                  height: 10.rh(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 160.rw(context),
                  height: 10.rh(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 150.rw(context),
                  height: 10.rh(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomShimmer(
                  width: 100.rw(context),
                  height: 10.rh(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Container article(FetchArticlesSuccess state, int index) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 50,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .start,
            children: <Widget>[
              CustomText(
                state.articlemodel[index].title!,
                color: Colors.black,
              ),
              const Divider(),
              if (state.articlemodel[index].image != '') ...[
                Image.network(state.articlemodel[index].image!),
              ],
              const Divider(),
              HtmlWidget(state.articlemodel[index].description ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategoryFilterBar() {
    return BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
      builder: (context, state) {
        if (state is FetchCategorySuccess) {
          final categories = state.categories;

          if (categories.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            height: 40.rh(context),
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: .horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return buildCategoryChip(
                    context,
                    name: 'all'.translate(context),
                    categoryId: null,
                    imageUrl: null,
                  );
                }
                final category = categories[index - 1];
                return buildCategoryChip(
                  context,
                  name: category.translatedName ?? category.category ?? '',
                  imageUrl: category.image,
                  categoryId: int.parse(category.id!.toString()),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget buildCategoryChip(
    BuildContext context, {
    required String name,
    required int? categoryId,
    required String? imageUrl,
  }) {
    final isSelected = selectedCategoryId == categoryId;
    return GestureDetector(
      onTap: () {
        if (selectedCategoryId != categoryId) {
          setState(() {
            selectedCategoryId = categoryId;
          });
          unawaited(
            context.read<FetchArticlesCubit>().fetchArticles(
              categoryId: selectedCategoryId,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? context.color.tertiaryColor
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: context.color.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              CustomImage(
                imageUrl: imageUrl,
                height: 18.rh(context),
                width: 18.rw(context),
                color: isSelected
                    ? context.color.buttonColor
                    : context.color.textColorDark,
              ),
              SizedBox(width: 8.rw(context)),
            ],
            CustomText(
              name,
              fontSize: context.font.md,
              color: isSelected
                  ? context.color.buttonColor
                  : context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }
}
