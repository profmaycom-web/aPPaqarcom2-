import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/data/model/article_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/articles/article_horizontal_card.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:material_ui/material_ui.dart';

class ArticlesSection extends StatefulWidget {
  const ArticlesSection({
    required this.title,
    required this.articles,
    super.key,
  });

  final String title;
  final List<ArticleModel> articles;

  @override
  State<ArticlesSection> createState() => _ArticlesSectionState();
}

class _ArticlesSectionState extends State<ArticlesSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) return const SliverToBoxAdapter();

    final chunks = <List<ArticleModel>>[];
    final limitedArticles = widget.articles.take(6).toList();
    for (var i = 0; i < limitedArticles.length; i += 2) {
      chunks.add(
        limitedArticles.sublist(
          i,
          i + 2 > limitedArticles.length ? limitedArticles.length : i + 2,
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: .min,
        children: [
          TitleHeader(
            title: widget.title,
            enableShowAll: widget.articles.length > 1,
            onSeeAll: () async {
              await Navigator.pushNamed(
                context,
                Routes.articlesScreenRoute,
                arguments: {'isFromHome': true},
              );
            },
          ),
          CarouselSlider.builder(
            itemCount: chunks.length,
            itemBuilder: (context, index, realIndex) {
              final chunk = chunks[index];
              return Column(
                mainAxisSize: .min,
                children: chunk.map((article) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: ArticleHorizontalCard(article: article),
                  );
                }).toList(),
              );
            },
            options: CarouselOptions(
              height: 216.rh(context),
              viewportFraction: 1,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          if (chunks.length > 1)
            Row(
              mainAxisAlignment: .center,
              children: List.generate(chunks.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == index
                      ? 24.rw(context)
                      : 8.rw(context),
                  height: 8.rh(context),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: _currentIndex == index
                        ? null
                        : Border.all(color: context.color.textLightColor),
                    color: _currentIndex == index
                        ? context.color.tertiaryColor
                        : Colors.transparent,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
