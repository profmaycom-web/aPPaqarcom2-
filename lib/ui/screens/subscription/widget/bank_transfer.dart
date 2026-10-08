import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/subscription/fetch_subscription_packages_cubit.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/data/repositories/subscription_repository.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/subscription/widget/document_upload.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';

class BankTransfer extends StatefulWidget {
  const BankTransfer({
    this.subscriptionPackage,
    this.payAsYouGo,
    this.listingId,
    this.listingType,
    super.key,
  });
  final SubscriptionPackageModel? subscriptionPackage;
  final PayAsYouGoModel? payAsYouGo;
  final int? listingId;
  final String? listingType;

  /// Shows the bank transfer bottom sheet. Returns true on successful upload.
  static Future<bool> show({
    required BuildContext context,
    SubscriptionPackageModel? subscriptionPackage,
    PayAsYouGoModel? payAsYouGo,
    int? listingId,
    String? listingType,
  }) async {
    final result = await CustomBottomSheet.show<bool>(
      context: context,
      title: 'bankDetails'.translate(context),
      isScrollControlled: true,
      child: BankTransfer(
        subscriptionPackage: subscriptionPackage,
        payAsYouGo: payAsYouGo,
        listingId: listingId,
        listingType: listingType,
      ),
    );
    return result == true;
  }

  @override
  State<BankTransfer> createState() => _BankTransferState();
}

class _BankTransferState extends State<BankTransfer> {
  MultipartFile? _bankReceiptFile;

  // Map to track copied states for clipboard buttons
  final Map<String, ValueNotifier<bool>> _copiedStates = {};

  bool isContinued = false;

  @override
  void dispose() {
    // Dispose all ValueNotifiers in the map
    for (final notifier in _copiedStates.values) {
      notifier.dispose();
    }
    _copiedStates.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBankTransferBottomSheet();
  }

  // Build the bank transfer bottom sheet
  Widget _buildBankTransferBottomSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBankDetailsList(),
        SizedBox(height: 18.rh(context)),
        _buildUploadReceiptButton(),
        SizedBox(height: 18.rh(context)),
        _buildContinueButton(),
      ],
    );
  }

  // List of bank details
  Widget _buildBankDetailsList() {
    return Column(
      children: AppSettings.bankTransferDetails
          .map(
            (e) => _buildCopyToClipboardButton(
              title:
                  e['translated_title']?.toString() ??
                  e['title']?.toString() ??
                  '',
              value: e['value']?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }

  // Continue button for bank transfer
  Widget _buildContinueButton() {
    return UiUtils.buildButton(
      context,
      isInProgress: isContinued,
      buttonTitle: 'completePayment'.translate(context),
      onPressed: () async {
        await _handleReceiptUpload(
          widget.subscriptionPackage?.id.toString(),
          widget.payAsYouGo?.id.toString(),
        );
      },
    );
  }

  // Upload receipt button
  Widget _buildUploadReceiptButton() {
    return DocumentUpload(
      maxFileSizeInMB: 3,
      onDocumentSelected: (file) async {
        if (file != null) {
          _bankReceiptFile = await MultipartFile.fromFile(
            file.file ?? '',
            filename: file.name,
          );
        }
      },
    );
  }

  // Handle receipt upload logic
  Future<void> _handleReceiptUpload(
    String? packageId,
    String? payAsYouGoId,
  ) async {
    if (isContinued) return;
    setState(() {
      isContinued = true;
    });

    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      Navigator.pop(context); // Close the bottom sheet
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }

    await _initiateBankTransfer(
      packageId: packageId,
      payAsYouGoId: payAsYouGoId,
      file: _bankReceiptFile ?? MultipartFile.fromString(''),
    );
    setState(() {
      isContinued = false;
    });
  }

  // Initiate bank transfer API call
  Future<void> _initiateBankTransfer({
    required MultipartFile file,
    String? packageId,
    String? payAsYouGoId,
  }) async {
    try {
      final response = await SubscriptionRepository().initiateBankTransfer(
        packageId: packageId,
        payAsYouGoId: payAsYouGoId,
        listingId: widget.listingId,
        listingType: widget.listingType,
        file: file,
      );
      if (response['error'] == false) {
        await context.read<FetchSubscriptionPackagesCubit>().fetchPackages();
        await Fluttertoast.showToast(
          msg: response['message'].toString(),
          fontSize: context.font.md,
          backgroundColor: context.color.tertiaryColor,
          textColor: context.color.buttonColor,
        );
        Navigator.pop(context, true); // Close the bottom sheet, signal success
      } else {
        if (mounted) {
          await Fluttertoast.showToast(
            msg: response['message'].toString(),
          );
        }
      }
    } on Exception catch (e) {
      await Fluttertoast.showToast(
        msg: e.toString(),
      );
    }
  }

  // Copy to clipboard button for bank details
  Widget _buildCopyToClipboardButton({
    required String title,
    required String value,
  }) {
    // Initialize a ValueNotifier for this specific item if it doesn't exist
    if (!_copiedStates.containsKey(title)) {
      _copiedStates[title] = ValueNotifier<bool>(false);
    }
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(height: 12.rh(context)),
        CustomText(
          title,
          fontSize: context.font.xs,
          fontWeight: .w500,
          color: context.color.textColorDark,
        ),
        Row(
          children: [
            Expanded(
              child: CustomText(
                value,
                fontSize: context.font.md,
                fontWeight: .w500,
                color: context.color.textColorDark,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value));
                _copiedStates[title]!.value = true;
                await Future<dynamic>.delayed(const Duration(seconds: 2));
                _copiedStates[title]!.value = false;
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: _copiedStates[title]!,
                builder: (context, isCopied, child) {
                  return Icon(
                    isCopied ? Icons.check : Icons.copy,
                    color: isCopied
                        ? Colors.green
                        : context.color.textColorDark.withValues(alpha: 0.5),
                    size: 24,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
