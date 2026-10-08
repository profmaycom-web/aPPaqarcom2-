import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/payment/payment_intent_cubit.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/data/repositories/subscription_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/payment/in_app_purchase/in_app_purchase_manager.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class SubscriptionPackageTile extends StatefulWidget {
  const SubscriptionPackageTile({
    required this.onTap,
    required this.package,
    required this.packageFeatures,
    super.key,
  });

  final SubscriptionPackageModel package;
  final List<AllFeature> packageFeatures;
  final VoidCallback onTap;

  @override
  State<SubscriptionPackageTile> createState() =>
      _SubscriptionPackageTileState();
}

class _SubscriptionPackageTileState extends State<SubscriptionPackageTile> {
  InAppPurchaseManager inAppPurchase = InAppPurchaseManager();
  MultipartFile? _bankReceiptFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          buildPackageTitle(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              border: Border(
                left: BorderSide(
                  color: context.color.borderColor,
                ),
                right: BorderSide(
                  color: context.color.borderColor,
                ),
                bottom: BorderSide(
                  color: context.color.borderColor,
                ),
              ),
            ),
            child: Column(
              children: [
                packageFeaturesAndValidity(),
                buildSeparator(),
                buildPriceAndSubscribe(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPriceAndSubscribe() {
    final packageDuration = HelperUtils.getPackageDuration(
      duration: widget.package.duration,
    );
    final isUnderReview = widget.package.packageStatus == 'review';
    final isRejected = widget.package.packageStatus == 'rejected';
    return Column(
      children: [
        if (isUnderReview) ...[
          Row(
            mainAxisAlignment: .center,
            children: [
              Icon(
                Icons.access_time,
                size: 18.rh(context),
                color: Colors.orangeAccent,
              ),
              SizedBox(width: 4.rw(context)),
              Flexible(
                child: CustomText(
                  'adminVerificationPending'.translate(context),
                  fontSize: context.font.sm,
                  color: Colors.orangeAccent,
                  fontWeight: .w500,
                  maxLines: 2,
                  textAlign: .center,
                ),
              ),
            ],
          ),
        ],
        Container(
          padding: .fromLTRB(
            16.rw(context),
            8.rh(context),
            16.rw(context),
            8.rh(context),
          ),
          margin: .only(top: 16.rh(context)),
          decoration: BoxDecoration(
            color: context.color.textColorDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            spacing: 8.rw(context),
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(
                      widget.package.price == 0
                          ? 'free'.translate(context)
                          : widget.package.price.toString().priceFormat(
                              context: context,
                            ),
                      fontSize: context.font.lg,
                      color: context.color.textColorDark,
                      fontWeight: .bold,
                    ),
                    CustomText(
                      '$packageDuration ${packageDuration == '1' ? 'day'.translate(context) : 'days'.translate(context)}',
                      fontSize: context.font.md,
                      color: context.color.textColorDark,
                    ),
                  ],
                ),
              ),
              if (isUnderReview)
                UiUtils.buildButton(
                  context,
                  height: 32.rh(context),
                  autoWidth: true,
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      Routes.transactionHistory,
                    );
                  },
                  buttonTitle: 'view'.translate(context),
                )
              else if (isRejected)
                buildUploadReceiptButton(
                  transactionId: widget.package.paymentTransactionId ?? '',
                )
              else
                BlocBuilder<PaymentIntentCubit, PaymentIntentState>(
                  builder: (context, state) {
                    final isInProgress =
                        state is PaymentIntentInProgress &&
                        state.packageId == widget.package.id;
                    return UiUtils.buildButton(
                      context,
                      height: 32.rh(context),
                      autoWidth: true,
                      isInProgress: isInProgress,
                      onPressed: widget.onTap,
                      buttonTitle: 'subscribe'.translate(context),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSeparator() {
    return Container(
      margin: const EdgeInsets.only(top: 18, bottom: 18),
      child: MySeparator(
        color: context.color.tertiaryColor.withValues(alpha: 0.7),
      ),
    );
  }

  Widget buildPackageTitle() {
    return Container(
      height: 48.rh(context),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: context.color.brightness == .dark
            ? context.color.textColorDark.withValues(alpha: 0.1)
            : context.color.textColorDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: CustomText(
        widget.package.translatedName ?? widget.package.name,
        fontSize: context.font.md,
        color: Colors.white,
        fontWeight: .w600,
      ),
    );
  }

  Widget packageFeaturesAndValidity() {
    return Column(
      children: [
        buildValidity(
          duration: widget.package.duration.toString(),
        ),
        SizedBox(height: 18.rh(context)),
        buildPackageFeatures(
          packageFeatures: widget.packageFeatures,
          package: widget.package,
        ),
      ],
    );
  }

  Widget buildValidity({required String duration}) {
    final packageDuration = HelperUtils.getPackageDuration(
      duration: int.parse(duration),
    );
    return Row(
      children: [
        CustomImage(
          imageUrl: AppIcons.featureAvailable,
          height: 20.rh(context),
          width: 20.rw(context),
        ),
        SizedBox(width: 8.rw(context)),
        CustomText(
          '${'validUntil'.translate(context)} $packageDuration ${packageDuration == '1' ? 'day'.translate(context) : 'days'.translate(context)}',
          fontSize: context.font.xs,
          color: context.color.textColorDark,
          fontWeight: .w500,
        ),
      ],
    );
  }

  Widget buildPackageFeatures({
    required List<AllFeature> packageFeatures,
    required SubscriptionPackageModel package,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) {
        return SizedBox(height: 18.rh(context));
      },
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packageFeatures.length,
      itemBuilder: (context, index) {
        final allFeatures = packageFeatures[index];
        final includedFeatures = package.features
            .where((element) => element.id == allFeatures.id)
            .toList();
        // Check if we have matching features before accessing
        var getLimit = '';
        if (includedFeatures.isNotEmpty) {
          if (includedFeatures[0].limit?.toString() != '0') {
            getLimit =
                includedFeatures[0].limit?.toString() ??
                includedFeatures[0].limitType.toString();
          } else {
            getLimit = includedFeatures[0].limitType.name.translate(context);
          }
        }

        return Row(
          children: [
            CustomImage(
              imageUrl:
                  package.features.any(
                    (element) => element.id == allFeatures.id,
                  )
                  ? AppIcons.featureAvailable
                  : AppIcons.featureNotAvailable,
              height: 20.rh(context),
              width: 20.rw(context),
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: CustomText(
                '${allFeatures.translatedName ?? allFeatures.name} ${getLimit != '' ? ': ${getLimit.firstUpperCase()}' : ''}',
                fontSize: context.font.xs,
                color: context.color.textColorDark,
                fontWeight: .w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildUploadReceiptButton({
    required String transactionId,
  }) {
    return Flexible(
      child: UiUtils.buildButton(
        context,
        height: 32.rh(context),
        autoWidth: true,
        onPressed: () async {
          final file = await AppFilePicker.pickFile(
            allowedExtensions: [
              'jpeg',
              'png',
              'jpg',
              'pdf',
              'doc',
              'docx',
              'webp',
            ],
          );
          if (file != null) {
            _bankReceiptFile = await MultipartFile.fromFile(
              file.path!,
              filename: file.path!.split('/').last,
            );
          }
          if (_bankReceiptFile == null) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseUploadReceipt',
              type: .error,
            );
            return;
          }
          try {
            final result = await SubscriptionRepository().uploadBankReceiptFile(
              paymentTransactionId: transactionId,
              file: _bankReceiptFile!,
            );
            if (result['error'] == false) {
              HelperUtils.showSnackBarMessage(
                context,
                'receiptUploaded',
                type: .success,
              );
              await context
                  .read<FetchSubscriptionPackagesCubit>()
                  .fetchPackages();
            } else {
              HelperUtils.showSnackBarMessage(
                context,
                result['message'].toString(),
                type: .error,
              );
            }
          } on Exception catch (e) {
            HelperUtils.showSnackBarMessage(
              context,
              e.toString(),
              type: .error,
            );
          }
        },
        buttonTitle: 'reUploadReceipt'.translate(context),
      ),
    );
  }
}

class MySeparator extends StatelessWidget {
  const MySeparator({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
    this.isShimmer = false,
    this.dashWidth = 10.0,
  });
  final double height;
  final Color color;
  final bool isShimmer;
  final double dashWidth;

  @override
  Widget build(BuildContext context) {
    if (isShimmer) {
      return SizedBox(
        height: height,
        child: CustomPaint(
          size: const Size(double.infinity, 0),
          painter: _DashLinePainter(
            color: Colors.grey.withValues(alpha: 0.3),
            dashWidth: dashWidth,
            dashHeight: height,
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: const Size(double.infinity, 0),
        painter: _DashLinePainter(
          color: color,
          dashWidth: dashWidth,
          dashHeight: height,
        ),
      ),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  _DashLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashHeight,
  });

  final Color color;
  final double dashWidth;
  final double dashHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashHeight
      ..style = .fill;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DashLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashHeight != dashHeight;
}
