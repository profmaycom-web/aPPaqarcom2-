import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/cubits/utility/mortgage_calculator_cubit.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/widgets/donut_chart.dart';
import 'package:ebroker/ui/screens/proprties/widgets/yearly_breakdown_screen.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class MortgageCalculator extends StatefulWidget {
  const MortgageCalculator({required this.property, super.key});
  final PropertyModel property;

  @override
  State<MortgageCalculator> createState() => _MortgageCalculatorState();
}

class _MortgageCalculatorState extends State<MortgageCalculator> {
  //mortgage calculator controllers
  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _loanTermController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _downPaymentFocusNode = FocusNode();
  final FocusNode _interestRateFocusNode = FocusNode();
  final FocusNode _loanTermFocusNode = FocusNode();
  Timer? _debounceTimer;
  final _formKey = GlobalKey<FormState>();
  bool isPercentage = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void initState() {
    super.initState();
    _downPaymentController.text = '';
    _interestRateController.text = '';
    _loanTermController.text = ''; // Default to 1 year
    _downPaymentFocusNode.addListener(_scrollToFocusedField);
    _interestRateFocusNode.addListener(_scrollToFocusedField);
    _loanTermFocusNode.addListener(_scrollToFocusedField);
  }

  void _scrollToFocusedField() {
    final focusNode = [
      _downPaymentFocusNode,
      _interestRateFocusNode,
      _loanTermFocusNode,
    ].firstWhereOrNull((node) => node.hasFocus);
    if (focusNode?.context == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Scrollable.ensureVisible(
        focusNode!.context!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
  }

  @override
  void dispose() {
    _downPaymentController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    _downPaymentFocusNode.dispose();
    _interestRateFocusNode.dispose();
    _loanTermFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _getMortgageCalculator(context: context);
  }

  Widget _getMortgageCalculator({required BuildContext context}) {
    if (context.read<MortgageCalculatorCubit>().state
        is! MortgageCalculatorSuccess) {
      return SingleChildScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Container(
            color: context.color.secondaryColor,
            padding: EdgeInsets.symmetric(horizontal: 12.rw(context)),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                CustomText(
                  'mortgageCalculator'.translate(context),
                  fontSize: context.font.xl,
                  fontWeight: .bold,
                ),
                SizedBox(height: 8.rh(context)),
                CustomText(
                  '${'principalAmount'.translate(context)}: ${(widget.property.price ?? '0').priceFormat(context: context, currencyCode: widget.property.currencyCode, currencySymbol: widget.property.currencySymbol)}',
                  color: context.color.tertiaryColor,
                  fontSize: context.font.lg,
                  fontWeight: .w600,
                ),
                SizedBox(height: 8.rh(context)),
                _buildDownPaymentTextField(),
                SizedBox(height: 8.rh(context)),
                Row(
                  mainAxisSize: .min,
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        readOnly: false,
                        controller: _interestRateController,
                        focusNode: _interestRateFocusNode,
                        label: 'interestRate'.translate(context),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.rw(context)),
                    Expanded(
                      child: _buildTextFormField(
                        readOnly: false,
                        controller: _loanTermController,
                        focusNode: _loanTermFocusNode,
                        label: 'noOfYears'.translate(context),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.rh(context)),
                if (context.read<MortgageCalculatorCubit>().state
                    is! MortgageCalculatorSuccess)
                  _buildMortgageCalculatorButton(context: context),
              ],
            ),
          ),
        ),
      );
    } else if (context.read<MortgageCalculatorCubit>().state
        is MortgageCalculatorSuccess) {
      return _buildMortgageCalculatorOutput();
    }
    return const SizedBox.shrink();
  }

  Widget _buildDownPaymentTextField() {
    final price = double.parse(widget.property.price!);
    return TextFormField(
      controller: _downPaymentController,
      focusNode: _downPaymentFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: context.color.textColorDark,
      ),
      decoration: InputDecoration(
        hintText: isPercentage
            ? '${'downPaymentDescription'.translate(context)} 10%'
            : '${'downPaymentDescription'.translate(context)} ${(price * 0.1).toStringAsFixed(2)}',
        hintStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: context.color.tertiaryColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        suffixIcon: _buildDownPaymentTypeSelector(
          _downPaymentController,
          price,
        ),
      ),
      validator: (value) {
        final number = double.tryParse(value ?? '0') ?? 0;

        if (isPercentage) {
          if (number < 0 || number > 100) {
            return 'percentageRateWarning'.translate(context);
          }
        } else {
          if (number < 0 || number > double.parse(widget.property.price!)) {
            return 'amountLimitWarning'.translate(context);
          }
          if (number < 0 || number >= price) {
            return 'amountLimitWarning'.translate(context);
          }
        }
        return null;
      },
    );
  }

  Widget _buildDownPaymentTypeSelector(
    TextEditingController controller,
    double propertyPrice,
  ) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 8),
      child: Row(
        mainAxisSize: .min,
        children: <Widget>[
          // Currency button
          SizedBox(
            width: 50,
            child: GestureDetector(
              onTap: () {
                if (isPercentage) {
                  setState(() {
                    isPercentage = false;
                    // Convert current percentage to value
                    final currentPercentage = double.tryParse(controller.text);
                    if (currentPercentage != null) {
                      final value = (currentPercentage / 100) * propertyPrice;
                      controller.text = value.toStringAsFixed(2);
                    } else {
                      controller.clear();
                    }
                  });
                }
              },
              child: Container(
                height: 48.rh(context),
                decoration: BoxDecoration(
                  color: !isPercentage
                      ? context.color.tertiaryColor
                      : context.color.tertiaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: CustomText(
                    (widget.property.currencySymbol != null &&
                            widget.property.currencySymbol!.isNotEmpty)
                        ? widget.property.currencySymbol!
                        : (widget.property.currencyCode != null &&
                              widget.property.currencyCode!.isNotEmpty)
                        ? widget.property.currencyCode!
                        : AppSettings.currencySymbol,
                    color: !isPercentage
                        ? context.color.secondaryColor
                        : context.color.tertiaryColor,
                    fontSize: context.font.md,
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.rw(context)),
          // Percentage button
          SizedBox(
            width: 48.rw(context),
            child: GestureDetector(
              onTap: () {
                if (!isPercentage) {
                  setState(() {
                    isPercentage = true;
                    // Convert current value to percentage
                    final currentValue = double.tryParse(controller.text);
                    if (currentValue != null) {
                      final percentage = (currentValue / propertyPrice) * 100;
                      controller.text = percentage.toStringAsFixed(1);
                    } else {
                      controller.clear();
                    }
                  });
                }
              },
              child: Container(
                height: 48.rh(context),
                decoration: BoxDecoration(
                  color: isPercentage
                      ? context.color.tertiaryColor
                      : context.color.tertiaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: CustomText(
                    '%',
                    color: isPercentage
                        ? context.color.secondaryColor
                        : context.color.tertiaryColor,
                    fontSize: context.font.md,
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMortgageCalculatorButton({required BuildContext context}) {
    return BlocBuilder<MortgageCalculatorCubit, MortgageCalculatorState>(
      builder: (context, state) {
        return UiUtils.buildButton(
          context,
          buttonTitle: 'calculateMortgage'.translate(context),
          buttonColor: state is MortgageCalculatorLoading
              ? context.color.borderColor
              : context.color.tertiaryColor,
          onPressed: () async {
            if (state is MortgageCalculatorLoading) {
              return;
            }
            if (_formKey.currentState!.validate()) {
              try {
                await context.read<MortgageCalculatorCubit>().calculateMortgage(
                  parameters: {
                    'loan_amount': double.parse(widget.property.price ?? '0'),
                    'down_payment': _downPaymentController.text == ''
                        ? 0
                        : isPercentage
                        ? ((double.parse(
                                    widget.property.price ?? '0',
                                  ) *
                                  double.parse(_downPaymentController.text)) /
                              100)
                        : double.parse(_downPaymentController.text),
                    'interest_rate': double.parse(_interestRateController.text),
                    'loan_term_years': double.parse(_loanTermController.text),
                    // !TODO(R): Manage this show_all_details
                    'show_all_details': 1,
                  },
                );
                setState(() {});
              } on Exception catch (e) {
                setState(() {});
                HelperUtils.showSnackBarMessage(
                  context,
                  e.toString(),
                  type: .error,
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildMortgageCalculatorOutput() {
    return BlocBuilder<MortgageCalculatorCubit, MortgageCalculatorState>(
      builder: (context, state) {
        if (state is MortgageCalculatorLoading) {
          return Center(
            child: UiUtils.progress(),
          );
        } else if (state is MortgageCalculatorSuccess) {
          return Container(
            padding: const EdgeInsetsDirectional.only(
              bottom: 16,
              end: 16,
              start: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Row(
                    mainAxisSize: .min,
                    children: [
                      CustomText(
                        'mortgageCalculator'.translate(context),
                        fontSize: context.font.xl,
                        fontWeight: .bold,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          setState(() {});
                          context
                              .read<MortgageCalculatorCubit>()
                              .emptyMortgageCalculatorData();
                        },
                        child: CustomText(
                          'reset'.translate(context),
                          showUnderline: true,
                          color: context.color.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.rh(context)),
                  EMIDonutChart(
                    principalAmount: double.parse(
                      state
                              .mortgageCalculatorModel
                              .mainTotal
                              ?.principalAmount ??
                          '0',
                    ),
                    interestPayable: double.parse(
                      state
                              .mortgageCalculatorModel
                              .mainTotal
                              ?.payableInterest ??
                          '0',
                    ),
                    monthlyEMI: double.parse(
                      state.mortgageCalculatorModel.mainTotal?.monthlyEmi ??
                          '0',
                    ),
                    currencyCode: widget.property.currencyCode,
                    currencySymbol: widget.property.currencySymbol,
                  ),
                  SizedBox(height: 8.rh(context)),
                  Row(
                    children: [
                      SizedBox(width: 16.rw(context)),
                      Column(
                        crossAxisAlignment: .start,
                        children: [
                          CustomText(
                            'downPayment'.translate(context),
                            fontSize: context.font.md,
                            fontWeight: .w600,
                          ),
                          SizedBox(height: 5.rh(context)),
                          CustomText(
                            (state
                                        .mortgageCalculatorModel
                                        .mainTotal
                                        ?.downPayment ??
                                    '0')
                                .priceFormat(
                                  context: context,
                                  currencyCode: widget.property.currencyCode,
                                  currencySymbol:
                                      widget.property.currencySymbol,
                                ),
                            fontSize: context.font.lg,
                            fontWeight: .w600,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: .start,
                        children: [
                          CustomText(
                            'monthlyEMI'.translate(context),
                            fontSize: context.font.md,
                            fontWeight: .w600,
                          ),
                          SizedBox(height: 5.rh(context)),
                          CustomText(
                            (state
                                        .mortgageCalculatorModel
                                        .mainTotal
                                        ?.monthlyEmi ??
                                    '0')
                                .priceFormat(
                                  context: context,
                                  currencyCode: widget.property.currencyCode,
                                  currencySymbol:
                                      widget.property.currencySymbol,
                                ),
                            fontSize: context.font.lg,
                            fontWeight: .w600,
                          ),
                        ],
                      ),
                      SizedBox(width: 16.rw(context)),
                    ],
                  ),
                  SizedBox(height: 8.rh(context)),
                  BlocBuilder<CheckPackageCubit, CheckPackageState>(
                    bloc: _checkPackageCubit,
                    builder: (context, checkPackageState) {
                      return UiUtils.buildButton(
                        context,
                        isInProgress:
                            checkPackageState is CheckPackageInProgress,
                        onPressed: () async {
                          if (_checkPackageCubit.state
                              is CheckPackageInProgress) {
                            return;
                          }
                          await GuestChecker.check(
                            onNotGuest: () async {
                              final packageAvailable = await _checkPackageCubit
                                  .checkAvailability(
                                    packageType:
                                        PackageType.mortgageCalculatorDetail,
                                  );

                              if (_checkPackageCubit.state
                                  is CheckPackageFail) {
                                if (context.mounted) {
                                  HelperUtils.showSnackBarMessage(
                                    context,
                                    (_checkPackageCubit.state
                                            as CheckPackageFail)
                                        .error,
                                    type: .error,
                                  );
                                }
                                return;
                              }

                              if (packageAvailable) {
                                await Navigator.push(
                                  context,
                                  CupertinoPageRoute<dynamic>(
                                    builder: (context) {
                                      return YearlyBreakdownScreen(
                                        mortgageCalculatorModel:
                                            state.mortgageCalculatorModel,
                                        currencyCode:
                                            widget.property.currencyCode,
                                        currencySymbol:
                                            widget.property.currencySymbol,
                                      );
                                    },
                                  ),
                                );
                              } else {
                                await UiUtils.showBlurredDialoge(
                                  context,
                                  dialog: const BlurredSubscriptionDialogBox(
                                    packageType: SubscriptionPackageType
                                        .mortgageCalculatorDetail,
                                    isAcceptContainesPush: true,
                                  ),
                                );
                              }
                            },
                          );
                        },
                        buttonTitle: 'yearlyBreakdown'.translate(context),
                        fontSize: context.font.md,
                        radius: 4,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        } else if (state is MortgageCalculatorFailure) {
          return Center(
            child: CustomText(
              state.errorMessage.translate(context),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    required bool readOnly,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      readOnly: readOnly,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: TextStyle(
        color: context.color.textColorDark,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: context.color.tertiaryColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      validator: _validateNumber,
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'pleaseFillValue'.translate(context);
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'enterValidNumber'.translate(context);
    }

    if (isPercentage) {
      if (number <= 0 || number > 100) {
        return 'percentageRateWarning'.translate(context);
      }
    } else {
      final propertyPrice = double.parse(widget.property.price ?? '0');
      if (number <= 0 || number > propertyPrice) {
        return 'amountLimitWarning'.translate(context);
      }
    }
    return null;
  }
}
