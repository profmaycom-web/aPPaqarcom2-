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

class ArticleCard extends StatefulWidget {
  const ArticleCard({
    required this.article,
    super.key,
    this.isFromHome = false,
  });
  final bool isFromHome;
  final ArticleModel article;

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
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
                type: MessageType.error,
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
            padding: const EdgeInsets.all(8),
            width: widget.isFromHome ? 280.rw(context) : double.infinity,
            height: widget.isFromHome ? 240.rh(context) : 279.rh(context),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.color.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'article-hero-${widget.article.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomImage(
                      imageUrl: widget.article.image ?? '',
                      width: double.infinity,
                      height: 151.rh(context),
                    ),
                  ),
                ),
                SizedBox(height: 8.rh(context)),
                Hero(
                  tag: '$resolvedHeroTag-title',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      (widget.article.translatedTitle ??
                              widget.article.title ??
                              '')
                          .firstUpperCase(),
                      maxLines: widget.isFromHome ? 1 : 2,
                      color: context.color.textColorDark,
                      fontWeight: FontWeight.w500,
                      fontSize: context.font.sm,
                    ),
                  ),
                ),
                CustomText(
                  stripHtmlTags(
                    widget.article.translatedDescription ??
                        widget.article.description ??
                        '',
                  ).trim(),
                  maxLines: widget.isFromHome ? 1 : 2,
                  color: context.color.textLightColor,
                  fontWeight: FontWeight.w400,
                  fontSize: context.font.xs,
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
                    Hero(
                      tag: '$resolvedHeroTag-date',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CustomText(
                          widget.article.date == null
                              ? widget.article.postedOn == null
                                    ? ''
                                    : widget.article.postedOn.toString()
                              : widget.article.date.toString().formatDate(),
                          color: context.color.textLightColor,
                          fontWeight: FontWeight.w400,
                          fontSize: context.font.xxs,
                          maxLines: 1,
                        ),
                      ),
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
                      widget.article.viewCount ?? '',
                      color: context.color.textLightColor,
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
                      fontSize: context.font.xxs,
                    ),
                  ],
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
