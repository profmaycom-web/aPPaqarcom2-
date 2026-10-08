import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/subscription/widget/bank_transfer.dart';
import 'package:ebroker/ui/screens/subscription/widget/package_tile.dart';
import 'package:ebroker/ui/screens/widgets/premium_property_subscription_box.dart';
import 'package:ebroker/utils/payment/in_app_purchase/in_app_purchase_manager.dart';
import 'package:ebroker/utils/payment/payment_manager.dart';
import 'package:material_ui/material_ui.dart';

mixin BlurDialoge {}

/// Base class for common dialog functionality
abstract class _BaseBlurredDialog extends StatelessWidget
    implements BlurDialoge {
  const _BaseBlurredDialog({
    required this.title,
    super.key,
    this.cancelButtonName,
    this.acceptButtonName,
    this.onCancel,
    this.onAccept,
    this.cancelButtonColor,
    this.cancelTextColor,
    this.acceptButtonColor,
    this.acceptTextColor,
    this.backAllowedButton,
    this.showCancleButton,
    this.svgImagePath,
    this.svgImageColor,
    this.isAcceptContainesPush,
    this.titleColor,
    this.titleSize,
    this.titleWeight,
  });

  final String? cancelButtonName;
  final String? acceptButtonName;
  final VoidCallback? onCancel;
  final String? svgImagePath;
  final Color? svgImageColor;
  final Future<dynamic> Function()? onAccept;
  final String title;
  final Color? cancelButtonColor;
  final Color? cancelTextColor;
  final Color? acceptButtonColor;
  final Color? acceptTextColor;
  final bool? backAllowedButton;
  final bool? showCancleButton;
  final bool? isAcceptContainesPush;
  final Color? titleColor;
  final double? titleSize;
  final FontWeight? titleWeight;

  /// Template method for building dialog content
  Widget buildDialogContent(BuildContext context, BoxConstraints constraints);

  /// Template method for building action buttons
  Widget buildActionButtons(BuildContext context, BoxConstraints constraints);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(context),
        _buildPopScope(context),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.14),
    );
  }

  Widget _buildPopScope(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (backAllowedButton == false) {}
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AlertDialog(
            backgroundColor: context.color.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: _buildTitle(context),
            content: buildDialogContent(context, constraints),
            actionsOverflowAlignment: OverflowBarAlignment.center,
            actionsAlignment: .center,
            actions: [buildActionButtons(context, constraints)],
          );
        },
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        if (svgImagePath != null) ...[
          CustomImage(
            imageUrl: svgImagePath!,
            height: 180.rh(context),
            color: svgImageColor,
          ),
          SizedBox(height: 20.rh(context)),
        ],
        CustomText(
          title.firstUpperCase(),
          fontSize: titleSize ?? context.font.xl,
          color: titleColor ?? context.color.textColorDark,
          fontWeight: titleWeight ?? .w400,
          textAlign: .center,
        ),
      ],
    );
  }

  Widget buildButton(
    BuildContext context, {
    required BoxConstraints constraints,
    required Color buttonColor,
    required String buttonName,
    required Color textColor,
    required VoidCallback onTap,
    double? width,
    EdgeInsetsGeometry? margin,
    BorderSide? borderSide,
  }) {
    return Container(
      margin: margin,
      width: width,
      child: MaterialButton(
        elevation: 0,
        height: 40.rh(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: borderSide ?? BorderSide(color: context.color.borderColor),
        ),
        color: buttonColor,
        onPressed: onTap,
        child: CustomText(
          buttonName,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> handleAcceptTap(BuildContext context) async {
    if (!context.mounted) return;
    await onAccept?.call();
    if (isAcceptContainesPush == false || isAcceptContainesPush == null) {
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void handleCancelTap(BuildContext context) {
    onCancel?.call();
    Navigator.pop(context, false);
  }
}

/// Blurred dialog box with static content
class BlurredDialogBox extends StatefulWidget implements BlurDialoge {
  const BlurredDialogBox({
    required this.title,
    required this.content,
    super.key,
    this.showAcceptButton = true,
    this.cancelButtonName,
    this.acceptButtonName,
    this.onCancel,
    this.onAccept,
    this.cancelButtonColor,
    this.cancelTextColor,
    this.acceptButtonColor,
    this.acceptTextColor,
    this.backAllowedButton,
    this.showCancleButton,
    this.svgImagePath,
    this.svgImageColor,
    this.barrierDismissable,
    this.isAcceptContainesPush,
    this.titleSize,
    this.titleColor,
    this.titleWeight,
  });

  final String title;
  final Widget content;
  final bool showAcceptButton;
  final String? cancelButtonName;
  final String? acceptButtonName;
  final VoidCallback? onCancel;
  final Future<dynamic> Function()? onAccept;
  final Color? cancelButtonColor;
  final Color? cancelTextColor;
  final Color? acceptButtonColor;
  final Color? acceptTextColor;
  final bool? backAllowedButton;
  final bool? showCancleButton;
  final String? svgImagePath;
  final Color? svgImageColor;
  final bool? barrierDismissable;
  final bool? isAcceptContainesPush;
  final Color? titleColor;
  final double? titleSize;
  final FontWeight? titleWeight;

  @override
  State<BlurredDialogBox> createState() => _BlurredDialogBoxState();
}

class _BlurredDialogBoxState extends State<BlurredDialogBox> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(context),
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (widget.backAllowedButton == false) return;
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AlertDialog(
                backgroundColor: context.color.secondaryColor,
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width * 0.7,
                  maxWidth: MediaQuery.sizeOf(context).width * 0.9,
                ),
                actionsPadding: widget.showAcceptButton
                    ? EdgeInsets.symmetric(vertical: 8.rh(context))
                    : EdgeInsets.zero,
                contentPadding: EdgeInsets.all(12.rw(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.rw(context)),
                ),
                title: _buildTitle(context),
                content: widget.content,
                actionsOverflowAlignment: OverflowBarAlignment.center,
                actionsAlignment: .center,
                actions: [_buildActionButtons(context, constraints)],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.barrierDismissable ?? false) {
          Navigator.pop(context);
        }
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.14),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        if (widget.svgImagePath != null) ...[
          CustomImage(
            height: 180.rh(context),
            fit: .contain,
            imageUrl: widget.svgImagePath!,
            color: widget.svgImageColor,
          ),
          SizedBox(height: 18.rh(context)),
        ],
        CustomText(
          widget.title.firstUpperCase(),
          fontSize: widget.titleSize ?? context.font.xl,
          color: widget.titleColor ?? context.color.textColorDark,
          fontWeight: widget.titleWeight ?? .w400,
          textAlign: .center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        if (widget.showCancleButton ?? true) ...[
          _buildButton(
            context,
            margin: const EdgeInsetsDirectional.only(start: 8, end: 8),
            constraints: constraints,
            buttonColor: widget.cancelButtonColor ?? context.color.primaryColor,
            buttonName:
                widget.cancelButtonName ?? 'cancelLbl'.translate(context),
            textColor: widget.cancelTextColor ?? context.color.textColorDark,
            onTap: _isLoading ? null : () => _handleCancelTap(context),
          ),
        ],
        if (widget.showAcceptButton) ...[
          _buildButton(
            context,
            margin: const EdgeInsetsDirectional.only(end: 8),
            constraints: constraints,
            buttonColor:
                widget.acceptButtonColor ?? context.color.tertiaryColor,
            buttonName: widget.acceptButtonName ?? 'ok'.translate(context),
            textColor:
                widget.acceptTextColor ??
                (widget.showCancleButton == false
                    ? context.color.textColorDark
                    : context.color.buttonColor),
            width: widget.showCancleButton == false
                ? context.screenWidth / 2
                : null,
            onTap: _isLoading ? null : () => _handleAcceptTap(context),
            isLoading: _isLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required BoxConstraints constraints,
    required Color buttonColor,
    required String buttonName,
    required Color textColor,
    required VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? margin,
    BorderSide? borderSide,
    bool isLoading = false,
  }) {
    return Container(
      margin: margin,
      width:
          width ??
          (ResponsiveHelper.isSmallPhone(context)
              ? 96.rw(context)
              : 124.rw(context)),
      child: MaterialButton(
        elevation: 0,
        height: 48.rh(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: borderSide ?? BorderSide(color: context.color.borderColor),
        ),
        color: buttonColor,
        onPressed: onTap,
        disabledColor: buttonColor,
        disabledTextColor: textColor,
        disabledElevation: 0,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : CustomText(buttonName, color: textColor),
      ),
    );
  }

  Future<void> _handleAcceptTap(BuildContext context) async {
    if (!context.mounted) return;
    setState(() => _isLoading = true);
    try {
      await widget.onAccept?.call();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (widget.isAcceptContainesPush == false ||
        widget.isAcceptContainesPush == null) {
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _handleCancelTap(BuildContext context) {
    widget.onCancel?.call();
    Navigator.pop(context, false);
  }
}

/// Blurred dialog box with builder content
class BlurredDialogBuilderBox extends _BaseBlurredDialog {
  const BlurredDialogBuilderBox({
    required super.title,
    required this.contentBuilder,
    required this.cancelButtonBorderColor,
    super.key,
    super.cancelButtonName,
    super.acceptButtonName,
    super.onCancel,
    super.onAccept,
    super.cancelButtonColor,
    super.cancelTextColor,
    super.acceptButtonColor,
    super.acceptTextColor,
    super.backAllowedButton,
    super.showCancleButton,
    super.svgImagePath,
    super.svgImageColor,
    super.isAcceptContainesPush,
    super.titleSize,
    super.titleColor,
    super.titleWeight,
  });

  final Widget? Function(BuildContext context, BoxConstraints constrains)
  contentBuilder;
  final Color cancelButtonBorderColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.14)),
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (backAllowedButton == false) return;
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AlertDialog(
                backgroundColor: context.color.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                title: _buildTitle(context),
                content: contentBuilder.call(context, constraints),
                actionsOverflowAlignment: OverflowBarAlignment.center,
                actionsAlignment: .center,
                actions: [buildActionButtons(context, constraints)],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (svgImagePath != null) ...[
          SizedBox(
            width: 48.rw(context),
            height: 48.rh(context),
            child: CustomImage(
              imageUrl: svgImagePath!,
              color: svgImageColor,
            ),
          ),
          SizedBox(height: 20.rh(context)),
        ],
        CustomText(
          title.firstUpperCase(),
          textAlign: .center,
          fontSize: titleSize ?? context.font.xl,
          fontWeight: titleWeight ?? .w400,
          color: titleColor ?? context.color.textColorDark,
        ),
      ],
    );
  }

  @override
  Widget buildDialogContent(BuildContext context, BoxConstraints constraints) {
    return contentBuilder.call(context, constraints) ?? const SizedBox.shrink();
  }

  @override
  Widget buildActionButtons(BuildContext context, BoxConstraints constraints) {
    return Row(
      children: [
        if (showCancleButton ?? true) ...[
          Expanded(
            child: buildButton(
              context,
              constraints: constraints,
              buttonColor:
                  cancelButtonColor ??
                  context.color.tertiaryColor.withValues(alpha: .1),
              buttonName: cancelButtonName ?? 'cancelLbl'.translate(context),
              textColor: cancelTextColor ?? context.color.textColorDark,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: constraints.maxWidth / 3.2,
              borderSide: BorderSide(color: cancelButtonBorderColor),
              onTap: () => handleCancelTap(context),
            ),
          ),
        ],
        Expanded(
          child: buildButton(
            context,
            constraints: constraints,
            buttonColor: acceptButtonColor ?? context.color.tertiaryColor,
            buttonName: acceptButtonName ?? 'ok'.translate(context),
            textColor:
                acceptTextColor ??
                (showCancleButton == false
                    ? context.color.textColorDark
                    : context.color.buttonColor),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () => handleAcceptTap(context),
          ),
        ),
      ],
    );
  }

  @override
  Future<void> handleAcceptTap(BuildContext context) async {
    await onAccept?.call();
    if (isAcceptContainesPush == false || isAcceptContainesPush == null) {
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void handleCancelTap(BuildContext context) {
    onCancel?.call();
    Navigator.pop(context, false);
  }
}

class BlurredRoleRequiredDialogBox extends StatelessWidget
    implements BlurDialoge {
  const BlurredRoleRequiredDialogBox({
    required this.requiredRole,
    super.key,
    this.onRoleSwitched,
  });

  final String requiredRole;
  final VoidCallback? onRoleSwitched;

  bool get _requiresAgent => requiredRole.toLowerCase() == 'agent';

  @override
  Widget build(BuildContext context) {
    final descriptionKey = _requiresAgent
        ? 'requiredAgentRoleDescription'
        : 'requiredUserRoleDescription';

    return BlurredDialogBox(
      title: 'warning'.translate(context),
      svgImagePath: AppIcons.noDataFound,
      acceptButtonName: 'switchNow'.translate(context),
      cancelButtonName: 'cancelLbl'.translate(context),
      content: CustomText(
        descriptionKey.translate(context),
        color: context.color.textColorDark.withValues(alpha: 0.7),
        fontSize: context.font.md,
        textAlign: .center,
      ),
      onAccept: () async {
        if (_requiresAgent) {
          await ActiveRoleManager.switchToAgent(context);
        } else {
          await ActiveRoleManager.switchToUser(context);
        }
        onRoleSwitched?.call();
      },
    );
  }
}

/// Specialized subscription dialog
class BlurredSubscriptionDialogBox extends StatefulWidget
    implements BlurDialoge {
  const BlurredSubscriptionDialogBox({
    required this.packageType,
    super.key,
    this.backAllowedButton,
    this.barrierDismissable,
    this.isAcceptContainesPush,
    this.preFetchedPayAsYouGo,
    this.preFetchedIsBankTransferActive,
    this.preFetchedAvailableOnlineGateways,
    this.linkedListingId,
    this.linkedListingType,
    this.onPaymentSuccess,
  });

  final SubscriptionPackageType packageType;
  final bool? backAllowedButton;
  final bool? barrierDismissable;
  final bool? isAcceptContainesPush;
  final PayAsYouGoModel? preFetchedPayAsYouGo;
  final bool? preFetchedIsBankTransferActive;
  final List<String>? preFetchedAvailableOnlineGateways;
  final int? linkedListingId;
  final String? linkedListingType;
  final Future<void> Function()? onPaymentSuccess;

  @override
  State<BlurredSubscriptionDialogBox> createState() =>
      _BlurredSubscriptionDialogBoxState();
}

class _BlurredSubscriptionDialogBoxState
    extends State<BlurredSubscriptionDialogBox> {
  bool isLoading = true;
  PayAsYouGoModel? payAsYouGoPackage;
  String? _selectedPaymentMethod;
  List<String> _availableOnlineGateways = [];
  bool? isBankTransferActive;
  InAppPurchaseManager inAppPurchase = InAppPurchaseManager();

  @override
  void initState() {
    super.initState();
    if (widget.preFetchedAvailableOnlineGateways != null ||
        widget.preFetchedIsBankTransferActive != null) {
      isLoading = false;
      final isAddOperation =
          widget.packageType == SubscriptionPackageType.propertyList ||
          widget.packageType == SubscriptionPackageType.propertyFeature ||
          widget.packageType == SubscriptionPackageType.projectList ||
          widget.packageType == SubscriptionPackageType.projectFeature;
      payAsYouGoPackage = isAddOperation ? widget.preFetchedPayAsYouGo : null;
      isBankTransferActive = widget.preFetchedIsBankTransferActive;
      _availableOnlineGateways = widget.preFetchedAvailableOnlineGateways ?? [];
    } else {
      Future.delayed(Duration.zero, () async {
        await _fetchPayAsYouGoData();
      });
    }
  }

  Future<void> _fetchPayAsYouGoData() async {
    try {
      await context.read<GetApiKeysCubit>().fetch();
      if (!mounted) return;
      final apiKeyState = context.read<GetApiKeysCubit>().state;
      if (apiKeyState is GetApiKeysSuccess) {
        isBankTransferActive = apiKeyState.bankTransferStatus == '1';
        _availableOnlineGateways = apiKeyState.enabledPaymentGateways;

        await context.read<FetchSubscriptionPackagesCubit>().fetchPackages();
        if (!mounted) return;
        final packageState = context
            .read<FetchSubscriptionPackagesCubit>()
            .state;
        if (packageState is FetchSubscriptionPackagesSuccess) {
          final isAddOperation =
              widget.packageType == SubscriptionPackageType.propertyList ||
              widget.packageType == SubscriptionPackageType.propertyFeature ||
              widget.packageType == SubscriptionPackageType.projectList ||
              widget.packageType == SubscriptionPackageType.projectFeature;

          if (isAddOperation) {
            final payAsYouGoList = packageState.packageResponseModel.payAsYouGo;
            var typeStr = 'property';
            if (widget.packageType == SubscriptionPackageType.projectList ||
                widget.packageType == SubscriptionPackageType.projectFeature) {
              typeStr = 'project';
            }
            final match = payAsYouGoList
                .where((p) => p.type == typeStr)
                .toList();
            if (match.isNotEmpty) {
              payAsYouGoPackage = match.first;
            }
          }
        }
      }
    } on Exception catch (_) {}

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(context),
        _buildPopScope(context),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.barrierDismissable ?? false) {
          Navigator.pop(context);
        }
      },
      child: Container(color: Colors.black12),
    );
  }

  Widget _buildPopScope(BuildContext context) {
    if (widget.packageType == SubscriptionPackageType.premiumProperties) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (widget.backAllowedButton == false) return;
          Future.delayed(Duration.zero, () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        },
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: PremiumPropertySubscriptionBox(
              showCloseButton: true,
              onClosePressed: () => Navigator.pop(context),
              onSubscribePressed: () => _handleViewPlansPress(context),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (widget.backAllowedButton == false) return;
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: AlertDialog(
        elevation: 0,
        titlePadding: const EdgeInsets.only(top: 18, left: 24, right: 24),
        contentPadding: EdgeInsets.zero,
        backgroundColor: context.color.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: _buildTitle(context),
        content: isLoading
            ? Padding(
                padding: .all(16.rw(context)),
                child: Column(
                  spacing: 16.rh(context),
                  mainAxisSize: .min,
                  children: [
                    CustomShimmer(
                      height: 76.rh(context),
                      width: 267.rw(context),
                      borderRadius: 4,
                    ),
                    CustomShimmer(
                      height: 48.rh(context),
                      width: 267.rw(context),
                      borderRadius: 4,
                    ),
                  ],
                ),
              )
            : _buildContent(context),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        CustomText(
          payAsYouGoPackage != null
              ? 'payAsYouGo'.translate(context)
              : 'subscribeNow'.translate(context),
          fontSize: context.font.lg,
          fontWeight: .w700,
        ),
        const Spacer(),
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 24.rh(context),
        width: 24.rw(context),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          boxShadow: [
            BoxShadow(
              color: context.color.textColorDark.withValues(alpha: .3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          borderRadius: BorderRadius.circular(99999),
        ),
        child: Icon(
          Icons.close,
          color: context.color.inverseSurface,
          size: 16.rh(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (payAsYouGoPackage != null) {
      return Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: 267.rw(context),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.rh(context),
                    horizontal: 12.rw(context),
                  ),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: context.color.tertiaryColor.withValues(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: .center,
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: BoxBorder.fromLTRB(
                              top: BorderSide(
                                color: context.color.secondaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(2),
                                bottomRight: Radius.circular(2),
                              ),
                              border: BoxBorder.fromLTRB(
                                bottom: BorderSide(
                                  color: context.color.secondaryColor,
                                  width: 1.5,
                                ),
                                left: BorderSide(
                                  color: context.color.secondaryColor,
                                  width: 1.5,
                                ),
                                right: BorderSide(
                                  color: context.color.secondaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            height: 18.rh(context),
                            width: 16.rw(context),
                            alignment: .center,
                            child: CustomText(
                              AppSettings.currencySymbol,
                              textAlign: .center,
                              fontSize: context.font.xs,
                              fontWeight: .w700,
                              color: context.color.secondaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.rw(context)),
                      Expanded(
                        child: CustomText(
                          '${'payAsYouGoDescription'.translate(context)} ${payAsYouGoPackage!.type}',
                          fontSize: context.font.sm,
                          maxLines: 3,
                          fontWeight: .w400,
                          color: context.color.textColorDark,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.rh(context)),
                MySeparator(
                  color: context.color.tertiaryColor,
                  dashWidth: 4,
                ),
                SizedBox(height: 16.rh(context)),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: context.color.tertiaryColor,
                    ),
                    SizedBox(width: 4.rw(context)),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'yourListingWillExpireIn'.translate(
                                context,
                              ),
                              style: TextStyle(
                                fontSize: context.font.sm,
                                color: context.color.textColorDark,
                              ),
                            ),
                            TextSpan(
                              text: ' 30 ',
                              style: TextStyle(
                                fontSize: context.font.sm,
                                color: context.color.tertiaryColor,
                                fontWeight: .w600,
                              ),
                            ),
                            TextSpan(
                              text: 'days'.translate(context),
                              style: TextStyle(
                                fontSize: context.font.sm,
                                color: context.color.textColorDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.rw(context)),
                    CustomText(
                      AppSettings.currencySymbol +
                          payAsYouGoPackage!.price.toStringAsFixed(2),
                      fontSize: context.font.xl,
                      color: context.color.textColorDark,
                      fontWeight: .w700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Center(
            child: UiUtils.buildButton(
              context,
              onPressed: () => _handlePayAsYouGoPress(context),
              buttonTitle: 'continuePayment'.translate(context),
              fontSize: context.font.md,
              height: 48.rh(context),
              outerPadding: EdgeInsets.symmetric(horizontal: 12.rw(context)),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => _handleViewPlansPress(context),
              child: CustomText(
                'viewMorePlans'.translate(context),
                fontSize: context.font.sm,
                fontWeight: .w600,
                color: context.color.tertiaryColor,
                showUnderline: true,
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: 267.rw(context),
            margin: .all(16.rw(context)),
            padding: .all(12.rw(context)),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              border: Border.all(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildPackageInfo(context),
          ),
          _buildViewPlansButton(context),
          SizedBox(height: 12.rh(context)),
        ],
      );
    }
  }

  Widget _buildPackageInfo(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: CustomImage(imageUrl: AppIcons.premium),
          ),
        ),
        SizedBox(width: 14.rw(context)),
        Flexible(
          flex: 3,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              CustomText(
                widget.packageType.title.translate(context),
                fontSize: context.font.md,
                fontWeight: .w700,
              ),
              SizedBox(height: 2.rh(context)),
              CustomText(
                widget.packageType.description.translate(context),
                fontSize: context.font.xs,
                color: context.color.textColorDark.withValues(alpha: 0.5),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewPlansButton(
    BuildContext context,
  ) {
    return Center(
      child: UiUtils.buildButton(
        context,
        onPressed: () => _handleViewPlansPress(context),
        buttonTitle: 'viewPlans'.translate(context),
        fontSize: context.font.md,
        outerPadding: EdgeInsets.symmetric(horizontal: 14.rw(context)),
        height: 48.rh(context),
      ),
    );
  }

  Future<void> _handleViewPlansPress(BuildContext context) async {
    final apiKeyState = context.read<GetApiKeysCubit>().state;
    final isBankTransferEnabled =
        apiKeyState is GetApiKeysSuccess &&
        apiKeyState.bankTransferStatus == '1';

    await Navigator.popAndPushNamed<dynamic, String>(
      context,
      Routes.subscriptionPackageListRoute,
      result: 'view_plans',
      arguments: {
        'from': 'home',
        'isBankTransferEnabled': isBankTransferEnabled,
      },
    );
  }

  Future<void> _handlePayAsYouGoPress(BuildContext context) async {
    if (Platform.isIOS && payAsYouGoPackage != null) {
      // In-App Purchase flow
      final iosProductId = payAsYouGoPackage!.iosProductId;
      if (iosProductId != null && iosProductId.isNotEmpty) {
        await inAppPurchase.buy(
          iosProductId,
          payAsYouGoPackage!.id.toString(),
        );
      } else {
        Navigator.pop(context);
        HelperUtils.showSnackBarMessage(
          context,
          'purchaseFailed',
          type: .error,
        );
      }
      return;
    }

    final hasBankTransfer = isBankTransferActive ?? false;
    final hasOnlineGateways = _availableOnlineGateways.isNotEmpty;
    final shouldShowPaymentSheet =
        (hasBankTransfer && hasOnlineGateways) ||
        _availableOnlineGateways.length > 1;

    if (shouldShowPaymentSheet) {
      setState(() {
        _selectedPaymentMethod ??= _deriveDefaultPaymentMethod();
      });
      await CustomBottomSheet.show<dynamic>(
        context: context,
        title: 'selectPaymentMethod'.translate(context),
        isScrollControlled: true,
        elevation: 10,
        child: buildPaymentMethodsBottomSheet(),
      );
    } else if (hasOnlineGateways) {
      await onOnlineSubscribe(
        gatewayKey: _availableOnlineGateways.first,
      );
    } else if (hasBankTransfer) {
      await onBankTransferSubscribe();
    } else {
      HelperUtils.showSnackBarMessage(
        context,
        'purchaseFailed',
        type: .error,
      );
    }
  }

  String? _deriveDefaultPaymentMethod() {
    if (_availableOnlineGateways.isNotEmpty) {
      return _availableOnlineGateways.first;
    }
    if (isBankTransferActive ?? false) {
      return 'bank_transfer';
    }
    return null;
  }

  Widget buildPaymentMethodsBottomSheet() {
    final hasBankTransfer = isBankTransferActive ?? false;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: Constant.scrollPhysics,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._availableOnlineGateways.map(
                        (gateway) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPaymentOptionForBottomSheet(
                            value: gateway,
                            title: _getPaymentGatewayTitle(gateway),
                            icon: _getPaymentGatewayIcon(gateway),
                            setSheetState: setSheetState,
                          ),
                        ),
                      ),
                      if (hasBankTransfer) ...[
                        SizedBox(height: 4.rh(context)),
                        _buildPaymentOptionForBottomSheet(
                          value: 'bank_transfer',
                          title: 'bankTransfer'.translate(context),
                          icon: AppIcons.bankTransfer,
                          iconColor: context.color.textColorDark,
                          setSheetState: setSheetState,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18.rh(context)),
              UiUtils.buildButton(
                context,
                height: 48,
                buttonTitle: 'continue'.translate(context),
                onPressed: () async {
                  _selectedPaymentMethod ??= _deriveDefaultPaymentMethod();
                  if (_selectedPaymentMethod == null) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      'purchaseFailed',
                      type: .error,
                    );
                    return;
                  }
                  if (_selectedPaymentMethod == 'bank_transfer') {
                    Navigator.pop(context);
                    await onBankTransferSubscribe();
                  } else {
                    Navigator.pop(context);
                    await onOnlineSubscribe(
                      gatewayKey: _selectedPaymentMethod,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentOptionForBottomSheet({
    required String value,
    required String title,
    required String icon,
    required StateSetter setSheetState,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == value
              ? context.color.tertiaryColor.withValues(alpha: .1)
              : Colors.transparent,
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? context.color.tertiaryColor
                : context.color.borderColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon.endsWith('.svg')) ...[
              CustomImage(
                imageUrl: icon,
                width: 24,
                height: 24,
                color: iconColor,
              ),
            ] else ...[
              Image.asset(
                icon,
                width: 24,
                height: 24,
                color: iconColor,
              ),
            ],
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: CustomText(
                title,
                fontSize: context.font.md,
                fontWeight: .w600,
                color: context.color.textColorDark,
              ),
            ),
            if (_selectedPaymentMethod == value)
              Icon(
                Icons.check_circle,
                color: context.color.tertiaryColor,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: context.color.textColorDark.withValues(alpha: .5),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine payment gateway icon
  String _getPaymentGatewayIcon(String enabledPaymentGatway) {
    final name = enabledPaymentGatway.toLowerCase();
    if (name == 'flutterwave') return AppIcons.flutterwave;
    if (name == 'paystack') return AppIcons.paystack;
    if (name == 'razorpay') return AppIcons.razorpay;
    if (name == 'paypal') return AppIcons.paypal;
    if (name == 'phonepe') return AppIcons.phonepe;
    if (name == 'cashfree') return AppIcons.cashfree;
    if (name == 'midtrans') return AppIcons.midtrans;
    return AppIcons.stripe;
  }

  String _getPaymentGatewayTitle(String gateway) {
    final name = gateway.toLowerCase();
    if (name == 'flutterwave') return 'Flutterwave';
    if (name == 'paystack') return 'Paystack';
    if (name == 'razorpay') return 'Razorpay';
    if (name == 'paypal') return 'Paypal';
    if (name == 'phonepe') return 'PhonePe';
    if (name == 'cashfree') return 'Cashfree';
    if (name == 'midtrans') return 'Midtrans';
    if (name == 'stripe') return 'Stripe';
    return gateway.firstUpperCase();
  }

  Future<void> onOnlineSubscribe({String? gatewayKey}) async {
    final targetGateway = gatewayKey;
    if (targetGateway == null || targetGateway.isEmpty) return;

    final nav = Navigator.of(context);
    final paymentManager = PaymentManager();
    final success = await paymentManager.pay(
      context: context,
      payAsYouGo: payAsYouGoPackage,
      gatewayKey: targetGateway,
      listingId: widget.linkedListingId,
      listingType: widget.linkedListingType,
    );

    // Close the dialog with the payment result so the caller (e.g. the add
    // property/project wizard) can continue with the submission.
    if (mounted) nav.pop(success);

    if (success && widget.onPaymentSuccess != null) {
      await widget.onPaymentSuccess!();
    }
  }

  Future<void> onBankTransferSubscribe() async {
    // Dismiss the dialog immediately when bank transfer is initiated so it
    // doesn't reappear if the user navigates back from the payment sheet.
    final nav = Navigator.of(context);
    if (mounted) nav.pop('bank_transfer_pending');

    final success = await BankTransfer.show(
      context: nav.context,
      payAsYouGo: payAsYouGoPackage,
      listingId: widget.linkedListingId,
      listingType: widget.linkedListingType,
    );

    if (success) {
      // Bank transfer is pending admin review — calling onPaymentSuccess here
      // would re-run activate(), find the limit still exceeded, and reshow the
      // dialog. Skip it; navigate straight to the main screen instead.
      nav.popUntil((route) => route.isFirst);
    }
  }
}

/// Empty dialog box with custom child
class EmptyDialogBox extends StatelessWidget with BlurDialoge {
  const EmptyDialogBox({
    required this.child,
    super.key,
    this.barrierDismisable,
  });

  final Widget child;
  final bool? barrierDismisable;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (barrierDismisable ?? true) Navigator.pop(context);
            },
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

/// Subscription package types enum
enum SubscriptionPackageType {
  propertyList(
    'property_list',
    title: 'propertyListTitle',
    description: 'propertyListDescription',
  ),
  propertyFeature(
    'property_feature',
    title: 'propertyFeatureTitle',
    description: 'propertyFeatureDescription',
  ),
  projectList(
    'project_list',
    title: 'projectListTitle',
    description: 'projectListDescription',
  ),
  projectFeature(
    'project_feature',
    title: 'projectFeatureTitle',
    description: 'projectFeatureDescription',
  ),
  mortgageCalculatorDetail(
    'mortgage_calculator_detail',
    title: 'mortgageCalculatorDetailTitle',
    description: 'mortgageCalculatorDetailDescription',
  ),
  premiumProperties(
    'premium_properties',
    title: 'premiumPropertiesTitle',
    description: 'premiumPropertiesDescription',
  ),
  premiumProjects(
    'premium_projects',
    title: 'projectAccessTitle',
    description: 'projectAccessDescription',
  ),
  agentWatermark(
    'agent_watermark',
    title: 'agentWatermarkTitle',
    description: 'agentWatermarkDescription',
  );

  const SubscriptionPackageType(
    this.value, {
    required this.title,
    required this.description,
  });

  final String value;
  final String title;
  final String description;
}
