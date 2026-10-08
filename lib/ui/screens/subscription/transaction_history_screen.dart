import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/utility/fetch_transactions_cubit.dart';
import 'package:ebroker/data/model/transaction_model.dart';
import 'package:ebroker/data/repositories/subscription_repository.dart';
import 'package:ebroker/data/repositories/transaction.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:ebroker/ui/screens/widgets/custom_shimmer.dart';
import 'package:ebroker/ui/screens/widgets/errors/no_data_found.dart';
import 'package:ebroker/ui/screens/widgets/errors/no_internet.dart';
import 'package:ebroker/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/app_file_picker.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});
  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) {
            return FetchTransactionsCubit();
          },
          child: const TransactionHistory(),
        );
      },
    );
  }

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  late final ScrollController _pageScrollController = ScrollController();

  late Map<String, String> statusMap;
  // Map to track copied states for clipboard buttons
  final Map<String, ValueNotifier<bool>> _copiedStates = {};
  final ValueNotifier<bool> _isDownloadingReceipt = ValueNotifier<bool>(false);

  MultipartFile? _bankReceiptFile;
  @override
  void initState() {
    super.initState();
    unawaited(context.read<FetchTransactionsCubit>().fetchTransactions());
    addPageScrollListener();
  }

  @override
  void dispose() {
    _pageScrollController
      ..removeListener(_pageScrollListener)
      ..dispose();
    // Dispose all ValueNotifiers in the map
    for (final notifier in _copiedStates.values) {
      notifier.dispose();
    }
    _copiedStates.clear();
    _isDownloadingReceipt.dispose();
    super.dispose();
  }

  void addPageScrollListener() {
    _pageScrollController.addListener(_pageScrollListener);
  }

  Future<void> _pageScrollListener() async {
    if (_pageScrollController.isEndReached()) {
      if (mounted) {
        final cubit = context.read<FetchTransactionsCubit>();
        if (cubit.hasMoreData()) {
          await cubit.fetchTransactionsMore();
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    statusMap = {
      'success': 'statusSuccess'.translate(context),
      'failed': 'statusFail'.translate(context),
      'pending': 'pendingLbl'.translate(context),
      'review': 'review'.translate(context),
      'rejected': 'rejected'.translate(context),
    };
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: 'transactionHistory'.translate(context),
      ),
      body: BlocBuilder<FetchTransactionsCubit, FetchTransactionsState>(
        builder: (context, state) {
          if (state is FetchTransactionsInProgress) {
            return buildTransactionHistoryShimmer();
          }
          if (state is FetchTransactionsFailure) {
            if (state.errorMessage is NoInternetConnectionError) {
              return NoInternet(
                onRetry: () async {
                  await context
                      .read<FetchTransactionsCubit>()
                      .fetchTransactions();
                },
              );
            }

            return SomethingWentWrong(
              errorMessage: state.errorMessage,
            );
          }
          if (state is FetchTransactionsSuccess) {
            if (state.transactionmodel.isEmpty) {
              return NoDataFound(
                title: 'noTransactionsFound'.translate(context),
                description: 'noTransactionsFoundDescription'.translate(
                  context,
                ),
                onTapRetry: () async {
                  await context
                      .read<FetchTransactionsCubit>()
                      .fetchTransactions();
                },
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    controller: _pageScrollController,
                    itemCount: state.transactionmodel.length,
                    itemBuilder: (context, index) {
                      final transaction = state.transactionmodel[index];

                      return customTransactionItem(context, transaction);
                    },
                  ),
                ),
                if (context
                    .watch<FetchTransactionsCubit>()
                    .isLoadingMore()) ...[
                  SizedBox(height: 16.rh(context)),
                  UiUtils.progress(),
                ],
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  Widget buildTransactionHistoryShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      padding: const EdgeInsets.only(top: 16),
      itemBuilder: (context, index) {
        return buildTransactionHistoryShimmerItem();
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 16.rh(context));
      },
    );
  }

  Widget buildTransactionHistoryShimmerItem() {
    return CustomShimmer(
      height: 66.rh(context),
      width: double.infinity,
      borderRadius: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget customTransactionItem(
    BuildContext context,
    TransactionModel transaction,
  ) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () async {
            await buildTransationDetailsBottomSheet(transaction: transaction);
          },
          child: Container(
            height: 66.rh(context),
            width: MediaQuery.sizeOf(context).width,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 8, 8),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              border: Border.all(
                color: context.color.borderColor,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 4.rw(context),
                  height: 42.rh(context),
                  decoration: BoxDecoration(
                    color: statusColor(transaction.paymentStatus.toString()),
                    borderRadius: const BorderRadiusDirectional.only(
                      topEnd: Radius.circular(2),
                      bottomEnd: Radius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: .center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          mainAxisAlignment: .center,
                          children: [
                            CustomText(
                              transaction.package?.name ??
                                  transaction.paymentType?.firstUpperCase() ??
                                  '',
                              fontWeight: .w700,
                              fontSize: context.font.md,
                            ),
                            SizedBox(height: 4.rh(context)),
                            CustomText(
                              transaction.createdAt.toString().formatDate(),
                              fontSize: context.font.xs,
                            ),
                          ],
                        ),
                      ),
                      if (transaction.paymentType == 'bank transfer' &&
                          (transaction.paymentStatus == 'pending' ||
                              transaction.paymentStatus == 'rejected'))
                        buildUploadReceiptButton(
                          transaction: transaction,
                        ),
                      Column(
                        crossAxisAlignment: .end,
                        mainAxisAlignment: .center,
                        children: [
                          CustomText(
                            transaction.amount.toString().priceFormat(
                              context: context,
                            ),
                            fontWeight: .w700,
                            color: context.color.tertiaryColor,
                          ),
                          SizedBox(height: 4.rh(context)),
                          CustomText(
                            statusMap[transaction.paymentStatus?.toString() ??
                                    '']
                                .toString(),
                          ),
                        ],
                      ),
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

  String statusText(String text) {
    if (text == 'success') {
      return 'statusSuccess'.translate(context);
    } else if (text == 'pending') {
      return 'pendingLbl'.translate(context);
    } else if (text == 'failed') {
      return 'statusFail'.translate(context);
    } else if (text == 'review') {
      return 'review'.translate(context);
    } else if (text == 'rejected') {
      return 'rejected'.translate(context);
    }
    return '';
  }

  Color statusColor(String text) {
    if (text == 'success') {
      return Colors.green;
    } else if (text == 'pending') {
      return Colors.orangeAccent;
    } else if (text == 'failed') {
      return Colors.redAccent;
    } else if (text == 'review') {
      return Colors.blue;
    } else if (text == 'rejected') {
      return Colors.redAccent;
    }
    return Colors.transparent;
  }

  Future<void> buildTransationDetailsBottomSheet({
    required TransactionModel transaction,
  }) async {
    final paymentGatewayName =
        (transaction.paymentGateway != '' &&
            transaction.paymentGateway != null &&
            transaction.paymentGateway != 'null' &&
            transaction.paymentGateway!.isNotEmpty)
        ? transaction.paymentGateway
        : transaction.paymentType;

    await CustomBottomSheet.show<dynamic>(
      context: context,
      isScrollControlled: true,
      padding: .symmetric(horizontal: 16.rw(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (paymentGatewayName != 'free')
                CustomImage(
                  imageUrl: _getPaymentGatewayIcon(
                    paymentGatewayName ?? '',
                  ),
                  color: paymentGatewayName!.contains('bank')
                      ? context.color.inverseSurface
                      : null,
                  height: 30,
                  width: 30,
                ),
              SizedBox(width: 10.rw(context)),
              CustomText(
                paymentGatewayName?.firstUpperCase() ?? '',
                fontSize: context.font.lg,
                fontWeight: FontWeight.w700,
              ),
              const Spacer(),
              CustomText(
                statusText(
                  transaction.paymentStatus?.toString() ?? '',
                ),
                fontSize: context.font.md,
                fontWeight: FontWeight.w700,
                color: statusColor(
                  transaction.paymentStatus?.toString() ?? '',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.rh(context)),
          buildAmountSection(
            amount: (transaction.amount?.toString() ?? '0').priceFormat(
              context: context,
            ),
            status: statusText(
              transaction.paymentStatus?.toString() ?? '',
            ),
            packageId: transaction.id.toString(),
          ),
          buildPackageNameSection(
            packageName: transaction.package?.name ?? '',
          ),
          SizedBox(height: 8.rh(context)),
          buildDateSection(createdAt: transaction.createdAt.toString()),
          if (transaction.transactionId != null &&
              transaction.transactionId != '' &&
              transaction.transactionId!.isNotEmpty) ...[
            SizedBox(height: 8.rh(context)),
            buildTransactionIdWithCopyButton(
              value: 'transaction_id',
              title: 'transactionId'.translate(context),
              transactionId: transaction.transactionId.toString(),
            ),
          ],
          SizedBox(height: 8.rh(context)),
          buildTransactionIdWithCopyButton(
            value: 'order_id',
            title: 'orderId'.translate(context),
            transactionId: transaction.orderId.toString(),
          ),
          SizedBox(height: 8.rh(context)),
          if (transaction.paymentStatus == 'success') ...[
            buildDownloadReceiptButton(
              packageId: transaction.id.toString(),
            ),
          ] else if (transaction.rejectReason!.isNotEmpty &&
              transaction.rejectReason != '' &&
              transaction.rejectReason != null) ...[
            rejectReasonSection(
              rejectReason: transaction.rejectReason ?? '',
            ),
          ],
        ],
      ),
    );
  }

  Widget buildDateSection({
    required String createdAt,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          'date'.translate(context),
          fontSize: context.font.xs,
        ),
        CustomText(
          createdAt.formatDate(),
          fontWeight: .w700,
          fontSize: context.font.md,
        ),
      ],
    );
  }

  Widget buildDownloadReceiptButton({
    required String packageId,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDownloadingReceipt,
      builder: (context, isDownloading, child) {
        return UiUtils.buildButton(
          context,
          height: 48,
          isInProgress: isDownloading,
          onPressed: () async {
            _isDownloadingReceipt.value = true;
            try {
              await createDocument(packageId, context);
            } finally {
              if (mounted) {
                _isDownloadingReceipt.value = false;
              }
            }
          },
          buttonTitle: 'downloadReceiptLbl'.translate(context),
        );
      },
    );
  }

  Widget buildPackageNameSection({
    required String packageName,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          'packageName'.translate(context),
          fontSize: context.font.xs,
        ),
        CustomText(
          packageName,
          fontWeight: .w700,
          fontSize: context.font.md,
        ),
      ],
    );
  }

  Widget rejectReasonSection({
    required String rejectReason,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          'reason'.translate(context),
          fontSize: context.font.xs,
        ),
        CustomText(
          rejectReason,
          fontWeight: .w700,
          fontSize: context.font.md,
        ),
      ],
    );
  }

  Widget buildAmountSection({
    required String amount,
    required String status,
    required String packageId,
  }) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            CustomText(
              'amount'.translate(context),
              fontSize: context.font.xs,
            ),
            CustomText(
              amount,
              fontWeight: .w700,
              fontSize: context.font.md,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTransactionIdWithCopyButton({
    required String title,
    required String value,
    required String transactionId,
  }) {
    if (transactionId == '') return const SizedBox.shrink();
    // Initialize a ValueNotifier for this specific item if it doesn't exist
    if (!_copiedStates.containsKey(title)) {
      _copiedStates[title] = ValueNotifier<bool>(false);
    }
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Flexible(
          flex: 10,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              CustomText(
                title,
                fontSize: context.font.xs,
              ),
              CustomText(
                transactionId,
                fontWeight: .w700,
                fontSize: context.font.md,
              ),
            ],
          ),
        ),
        const Spacer(),
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
    );
  }

  // Helper method to determine payment gateway icon
  String _getPaymentGatewayIcon(String enabledPaymentGatway) {
    final name = enabledPaymentGatway.toLowerCase();
    if (name == 'flutterwave') {
      return AppIcons.flutterwave;
    } else if (name == 'paystack') {
      return AppIcons.paystack;
    } else if (name == 'razorpay') {
      return AppIcons.razorpay;
    } else if (name == 'paypal') {
      return AppIcons.paypal;
    } else if (name == 'stripe') {
      return AppIcons.stripe;
    } else if (name.contains('bank')) {
      return AppIcons.bankTransfer;
    } else if (name == 'midtrans') {
      return AppIcons.midtrans;
    }
    return '';
  }

  Future<String> downloadRecipt(
    String packageId,
  ) async {
    final transactionRepository = TransactionRepository();
    final response = await transactionRepository.getPaymentReceipt(packageId);
    return response;
  }

  Future<void> createDocument(String packageId, BuildContext context) async {
    final htmlResponse = await downloadRecipt(packageId);
    try {
      // Convert HTML directly to PDF bytes using native WebView
      final converter = HtmlToPdfConverter();
      final pdfBytes = await converter.convertHtmlToPdfBytes(
        html: htmlResponse,
      );

      // Display the PDF
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
      );
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: .error,
      );
    }
  }

  Widget buildUploadReceiptButton({
    required TransactionModel transaction,
  }) {
    return GestureDetector(
      onTap: () async {
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
            paymentTransactionId: transaction.id.toString(),
            file: _bankReceiptFile!,
          );
          if (result['error'] == false) {
            await context.read<FetchTransactionsCubit>().fetchTransactions();
            HelperUtils.showSnackBarMessage(
              context,
              'receiptUploaded',
              type: .success,
            );
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
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: context.color.textLightColor.withValues(alpha: 0.2),
          ),
        ),
        margin: const EdgeInsetsDirectional.only(end: 16),
        child: Icon(
          Icons.file_upload_outlined,
          color: context.color.textLightColor.withValues(alpha: 0.5),
          size: 18,
        ),
      ),
    );
  }
}
