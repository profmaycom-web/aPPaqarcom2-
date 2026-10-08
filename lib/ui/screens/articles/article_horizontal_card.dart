import 'dart:async';

import 'package:ebroker/data/model/article_model.dart';
import 'package:ebroker/ui/screens/articles/article_details.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class ArticleHorizontalCard extends StatefulWidget {
  const ArticleHorizontalCard({
    required this.article,
    super.key,
  });
  final ArticleModel article;

  @override
  State<ArticleHorizontalCard> createState() => _ArticleHorizontalCardState();
}

class _ArticleHorizontalCardState extends State<ArticleHorizontalCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return CustomOpenContainer(
      openBuilder: (context, closeContainer) {
        return ArticleDetails.buildWithProviders(
          articleId: widget.article.id.toString(),
          heroTag: 'article-hero-${widget.article.id}',
          heroImageUrl: widget.article.image,
          articleTitle:
              widget.article.translatedTitle ?? widget.article.title ?? '',
          articleDate: widget.article.date,
        );
      },
      closedBuilder: (context, openContainer) {
        final resolvedHeroTag = 'article-hero-${widget.article.id}';
        return GestureDetector(
          onTap: () async {
            if (_isNavigating) return;
            final hasInternet = await HelperUtils.checkInternet();

            if (!hasInternet) {
              return HelperUtils.showSnackBarMessage(
                context,
                'noInternet',
                type: .error,
              );
            }
            setState(() {
              _isNavigating = true;
            });
            openContainer();
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _isNavigating = false;
                });
              }
            });
          },
          child: Container(
            padding: .all(8.rw(context)),
            height: 98.rh(context),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: .circular(8.rw(context)),
              border: Border.all(
                color: context.color.borderColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'article-hero-${widget.article.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.rw(context)),
                    child: CustomImage(
                      imageUrl: widget.article.image ?? '',
                      width: 140.rw(context),
                      height: double.infinity,
                    ),
                  ),
                ),
                SizedBox(width: 12.rw(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.rh(context)),
                      Hero(
                        tag: '$resolvedHeroTag-title',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CustomText(
                            (widget.article.translatedTitle ??
                                    widget.article.title ??
                                    '')
                                .firstUpperCase(),
                            maxLines: 2,
                            color: context.color.textColorDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      UiUtils.getDivider(context),
                      SizedBox(height: 8.rh(context)),
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
                          Expanded(
                            child: Hero(
                              tag: '$resolvedHeroTag-date',
                              child: Material(
                                type: MaterialType.transparency,
                                child: CustomText(
                                  widget.article.date == null
                                      ? widget.article.postedOn == null
                                            ? ''
                                            : widget.article.postedOn.toString()
                                      : widget.article.date
                                            .toString()
                                            .formatDate(),
                                  color: context.color.textLightColor,
                                  fontWeight: FontWeight.w400,
                                  fontSize: context.font.xxs,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.rw(context)),
                          CustomImage(
                            imageUrl: AppIcons.eye,
                            height: 16.rh(context),
                            fit: .contain,
                            color: context.color.textLightColor,
                          ),
                          SizedBox(width: 4.rw(context)),
                          CustomText(
                            widget.article.viewCount ?? '',
                            color: context.color.textLightColor,
                            fontWeight: FontWeight.w400,
                            maxLines: 1,
                            fontSize: context.font.xxs,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.rh(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String stripHtmlTags(String htmlString) {
  final exp = RegExp('<[^>]*>', multiLine: true);
  final strippedString = htmlString.replaceAll(exp, '');
  return strippedString;
}
