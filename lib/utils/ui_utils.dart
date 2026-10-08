import 'package:ebroker/exports/main_export.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

class UiUtils {
  static String getExpiryCountdown(BuildContext context, String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return '';

    final expiry = DateTime.parse(expiryDate);
    final now = DateTime.now();

    if (expiry.isBefore(now)) {
      return '';
    }

    final difference = expiry.difference(now);

    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '${'expiresIn'.translate(context)} $months ${_plural(context, months, 'month', 'months')} ';
    } else if (difference.inDays >= 1) {
      return '${'expiresIn'.translate(context)} ${difference.inDays} ${_plural(context, difference.inDays, 'day', 'days')} ';
    } else if (difference.inHours >= 1) {
      return '${'expiresIn'.translate(context)} ${difference.inHours} ${_plural(context, difference.inHours, 'hour', 'hours')} ';
    } else if (difference.inMinutes >= 1) {
      return '${'expiresIn'.translate(context)} ${difference.inMinutes} ${_plural(context, difference.inMinutes, 'minute', 'minutes')} ';
    } else {
      return 'lessThanMinuteLeft'.translate(context);
    }
  }

  static String _plural(
    BuildContext context,
    int count,
    String singularKey,
    String pluralKey,
  ) {
    return (count == 1 ? singularKey : pluralKey).translate(context);
  }

  static Widget getDivider(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 1,
      endIndent: 0,
      indent: 0,
      color: context.color.borderColor,
    );
  }

  static Widget progress({
    double? width,
    double? height,
    Color? normalProgressColor,
    bool play = true, // NEW: control whether animation plays
  }) {
    final primaryColor =
        Constant.navigatorKey.currentContext?.color.tertiaryColor ??
        tertiaryColor_;
    const secondaryColor = secondaryColor_;

    if (AppConfig.useLottieProgress) {
      return LottieBuilder.asset(
        'assets/lottie/${AppConfig.progressLottieFile}',
        width: width ?? 45,
        height: height ?? 45,
        animate: play,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(
              ['Layer 5 Outlines', 'Group 1', '**'],
              value: primaryColor,
            ),
            ValueDelegate.color(
              ['cube 4 Outlines', 'Group 1', '**'],
              value: primaryColor,
            ),
            ValueDelegate.color(
              ['cube 2 Outlines', 'Group 1', '**'],
              value: secondaryColor,
            ),
            ValueDelegate.color(
              ['cube 3 Outlines', 'Group 1', '**'],
              value: secondaryColor,
            ),
          ],
        ),
      );
    } else {
      return CircularProgressIndicator(
        color: normalProgressColor,
      );
    }
  }

  static SystemUiOverlayStyle getSystemUiOverlayStyle({
    required BuildContext context,
  }) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: context.color.brightness == .light
          ? .dark
          : .light,
      statusBarBrightness: context.color.brightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarColor: context.color.secondaryColor,
      systemNavigationBarIconBrightness: context.color.brightness == .light
          ? .dark
          : .light,
    );
  }

  static Widget buildButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required String buttonTitle,
    double? height,
    double? width,
    BorderSide? border,
    String? titleWhenProgress,
    bool isInProgress = false,
    double? fontSize,
    double? radius,
    bool? autoWidth,
    Widget? prefixWidget,
    Widget? suffixWidget,
    EdgeInsetsGeometry? padding,
    bool? showProgressTitle,
    double? progressWidth,
    double? progressHeight,
    bool? showElevation,
    Color? textColor,
    Color? buttonColor,
    EdgeInsetsGeometry? outerPadding,
    Color? disabledColor,
    VoidCallback? onTapDisabledButton,
    bool? disabled,
    MaterialTapTargetSize? materialTapTargetSize,
  }) {
    var title = '';
    final isRTL = context.read<LanguageCubit>().isRTL;
    if (isInProgress) {
      title = titleWhenProgress ?? buttonTitle;
    } else {
      title = buttonTitle;
    }
    return Padding(
      padding: outerPadding ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: (disabled ?? false) ? onTapDisabledButton : null,
        child: MaterialButton(
          materialTapTargetSize: materialTapTargetSize,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          minWidth: autoWidth ?? false ? null : (width ?? double.infinity),
          height: height ?? 56.rh(context),
          padding: padding,
          shape: RoundedRectangleBorder(
            side: border ?? BorderSide.none,
            borderRadius: BorderRadius.circular(radius ?? 4),
          ),
          elevation: (showElevation ?? true) ? 0.5 : 0,
          color: buttonColor ?? context.color.tertiaryColor,
          disabledColor: disabledColor ?? context.color.tertiaryColor,
          onPressed: (isInProgress || (disabled ?? false))
              ? null
              : () {
                  HelperUtils.unfocus();
                  onPressed.call();
                },
          child: Row(
            spacing: 4.rw(context),
            mainAxisSize: .min,
            mainAxisAlignment: .center,
            children: [
              if (prefixWidget != null && !isInProgress && isRTL) ...[
                prefixWidget,
              ],
              if (isInProgress) ...[
                SizedBox(
                  width: progressWidth ?? 16,
                  height: progressHeight ?? 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.color.buttonColor,
                  ),
                ),
              ],
              if (prefixWidget != null && !isInProgress && !isRTL) ...[
                prefixWidget,
              ],
              if (!isInProgress) ...[
                Flexible(
                  child: CustomText(
                    title,
                    maxLines: 1,
                    color: textColor ?? context.color.buttonColor,
                    fontSize: (fontSize ?? context.font.lg).rf(context),
                  ),
                ),
              ] else ...[
                if (showProgressTitle ?? false)
                  CustomText(
                    title,
                    maxLines: 1,
                    color: context.color.buttonColor,
                    fontSize: fontSize ?? context.font.lg,
                  ),
              ],
              if (suffixWidget != null && !isInProgress) ...[
                suffixWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showFullScreenImage(
    BuildContext context, {
    required ImageProvider provider,
    String? imageUrl,
    VoidCallback? then,
    bool? downloadOption,
    VoidCallback? onTapDownload,
  }) async {
    await Navigator.of(context)
        .push(
          CupertinoPageRoute<dynamic>(
            barrierDismissible: true,
            builder: (context) => FullScreenImageView(
              provider: provider,
              imageUrl: imageUrl,
              showDownloadButton: downloadOption,
              onTapDownload: onTapDownload,
            ),
          ),
        )
        .then((value) {
          then?.call();
        });
  }

  static Future<void> imageGallaryView(
    BuildContext context, {
    required List<dynamic> images,
    required int initalIndex,
    VoidCallback? then,
  }) async {
    await Navigator.of(context)
        .push(
          CupertinoPageRoute<dynamic>(
            builder: (context) => GalleryViewWidget(
              initalIndex: initalIndex,
              images: images,
            ),
          ),
        )
        .then((value) {
          then?.call();
        });
  }

  static Future<void> showAutoScrollImageDialog(
    BuildContext context, {
    required List<String> images,
    Duration autoScrollDuration = const Duration(seconds: 2),
    String? title,
    String? category,
    String? type,
    String? location,
  }) async {
    if (images.isEmpty) return;
    await showBlurredDialoge(
      context,
      dialog: EmptyDialogBox(
        barrierDismisable: true,
        child: AutoScrollImageDialog(
          images: images,
          autoScrollDuration: autoScrollDuration,
          title: title,
          category: category,
          type: type,
          location: location,
        ),
      ),
    );
  }

  static Future<dynamic> showBlurredDialoge(
    BuildContext context, {
    required BlurDialoge dialog,
    double? sigmaX,
    double? sigmaY,
  }) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .7),
      useSafeArea: false,
      builder: (context) {
        if (dialog is BlurredDialogBox) {
          return dialog;
        } else if (dialog is BlurredDialogBuilderBox) {
          return dialog;
        } else if (dialog is EmptyDialogBox) {
          return dialog;
        } else if (dialog is BlurredSubscriptionDialogBox) {
          return dialog;
        } else if (dialog is BlurredRoleRequiredDialogBox) {
          return dialog;
        } else if (dialog is AutoScrollImageDialog) {
          return dialog;
        }

        return Container();
      },
    );
  }

  static Widget buildHorizontalShimmer(BuildContext context) {
    return ResponsiveHelper.isLargeTablet(context)
        ? GridView.builder(
            shrinkWrap: true,
            physics: Constant.scrollPhysics,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 130.rh(context),
              crossAxisSpacing: 12,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            itemCount: 15,
            itemBuilder: (context, index) {
              return buildShimmerItem(context);
            },
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: Constant.scrollPhysics,
            itemCount: 8,
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            separatorBuilder: (context, index) {
              return const SizedBox(
                height: 12,
              );
            },
            itemBuilder: (context, index) {
              return buildShimmerItem(context);
            },
          );
  }

  static Widget buildBigCardShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: Constant.scrollPhysics,
      itemCount: 8,
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      separatorBuilder: (context, index) {
        return SizedBox(height: 12.rh(context));
      },
      itemBuilder: (context, index) {
        return buildBigShimmerItem(context);
      },
    );
  }

  static Widget buildBigShimmerItem(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: .start,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: CustomShimmer(
                  height: 50.rh(context),
                  width: 50.rw(context),
                ),
              ),
              SizedBox(
                width: 12.rw(context),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    CustomShimmer(
                      height: 12.rh(context),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    CustomShimmer(
                      height: 12.rh(context),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    CustomShimmer(
                      height: 12.rh(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.rh(context)),
          Row(
            children: [
              Expanded(child: CustomShimmer(height: 54.rh(context))),
              SizedBox(width: 12.rw(context)),
              Expanded(child: CustomShimmer(height: 54.rh(context))),
            ],
          ),
          SizedBox(height: 16.rh(context)),
          CustomShimmer(height: 36.rh(context)),
        ],
      ),
    );
  }

  static Widget buildShimmerItem(BuildContext context) {
    return Container(
      height: 130.rh(context),
      width: double.maxFinite,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: CustomShimmer(
              height: 114.rh(context),
              width: 124.rw(context),
            ),
          ),
          SizedBox(
            width: 12.rw(context),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                CustomShimmer(
                  height: 12.rh(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomShimmer(
                  height: 12.rh(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomShimmer(
                  height: 12.rh(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomShimmer(
                  height: 12.rh(context),
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomShimmer(
                  height: 24.rh(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///Format string
extension FormatAmount on String {
  String formatDate({
    String? format,
  }) {
    try {
      // only pass fist two letters of language code
      final validLanguageCode = HelperUtils.isValidLocale(
        HiveUtils.getLanguageCode(),
      );
      final dateFormat = DateFormat(
        format ?? 'MMM d, yyyy',
        validLanguageCode ? HiveUtils.getLanguageCode() : 'en',
      );
      final formatted = dateFormat.format(DateTime.parse(this));
      return formatted;
    } on Exception catch (_) {
      final dateFormat = DateFormat(
        format ?? 'MMM d, yyyy',
      );
      final formatted = dateFormat.format(DateTime.parse(this));
      return formatted;
    }
  }

  String firstUpperCase() {
    var upperCase = '';
    var suffix = '';
    if (isNotEmpty) {
      upperCase = this[0].toUpperCase();
      suffix = substring(1, length);
    }
    return upperCase + suffix;
  }
}

//scroll controller extenstion

extension ScrollEndListen on ScrollController {
  ///It will check if scroll is at the bottom or not
  bool isEndReached() {
    if (!hasClients) return false;

    // Check if we have positions before accessing them
    for (final position in positions) {
      if (position.pixels >= position.maxScrollExtent) {
        return true;
      }
    }
    return false;
  }
}
