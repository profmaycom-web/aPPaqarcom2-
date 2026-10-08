import 'package:ebroker/data/cubits/auth/get_user_data_cubit.dart';
import 'package:ebroker/data/cubits/payment/payment_intent_cubit.dart';
import 'package:ebroker/data/cubits/payment/payment_link_cubit.dart';
import 'package:ebroker/data/cubits/subscription/assign_free_package.dart';
import 'package:ebroker/data/cubits/subscription/assign_package.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/subscription/widget/bank_transfer.dart';
import 'package:ebroker/ui/screens/subscription/widget/my_packages_tile.dart';
import 'package:ebroker/ui/screens/subscription/widget/package_tile.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:ebroker/utils/admob/interstitial_ad_manager.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/payment/in_app_purchase/in_app_purchase_manager.dart';
import 'package:ebroker/utils/payment/payment_manager.dart';
import 'package:material_ui/material_ui.dart';

class SubscriptionPackageListScreen extends StatefulWidget {
  const SubscriptionPackageListScreen({
    super.key,
    this.from,
  });
  final String? from;

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => GetApiKeysCubit(),
            ),
            BlocProvider(
              create: (context) => GetSubsctiptionPackageLimitsCubit(),
            ),
            BlocProvider(
              create: (context) => AssignFreePackageCubit(),
            ),
            BlocProvider(
              create: (context) => AssignInAppPackageCubit(),
            ),
            BlocProvider(
              create: (context) => PaymentIntentCubit(),
            ),
            BlocProvider(
              create: (context) => PaymentLinkCubit(),
            ),
          ],
          child: SubscriptionPackageListScreen(
            from: arguments?['from']?.toString() ?? '',
          ),
        );
      },
    );
  }

  @override
  State<SubscriptionPackageListScreen> createState() =>
      SubscriptionPackageListScreenState();
}

class SubscriptionPackageListScreenState
    extends State<SubscriptionPackageListScreen>
    with SingleTickerProviderStateMixin {
  InterstitialAdManager interstitialAdManager = InterstitialAdManager();
  InAppPurchaseManager inAppPurchase = InAppPurchaseManager();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  String? _selectedPaymentMethod;
  List<String> _availableOnlineGateways = [];
  bool? isBankTransferActive;
  // Bank transfer related state variables have been moved to bank_transfer.dart

  @override
  void initState() {
    super.initState();

    _selectedPaymentMethod = null;
    // Initialize tab controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1;

    // Fetch API keys first
    unawaited(_fetchApiKeys());

    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchSubscriptionPackagesCubit>().hasMore()) {
          unawaited(
            context.read<FetchSubscriptionPackagesCubit>().fetchMorePackages(),
          );
        }
      }
    });
    unawaited(interstitialAdManager.load());
    InAppPurchaseManager.getPendings();
    inAppPurchase.listenIAP(context);
  }

  Future<void> _fetchApiKeys() async {
    try {
      await context.read<GetApiKeysCubit>().fetch();
      if (!mounted) return;
      final state = context.read<GetApiKeysCubit>().state;

      if (state is GetApiKeysSuccess) {
        setState(() {
          isBankTransferActive = state.bankTransferStatus == '1';
          _availableOnlineGateways = state.enabledPaymentGateways;
          _selectedPaymentMethod = _deriveDefaultPaymentMethod();
        });

        // Now fetch subscription packages after API keys are loaded
        if (!mounted) return;
        await context.read<FetchSubscriptionPackagesCubit>().fetchPackages();
      } else if (state is GetApiKeysFail) {
        // Handle API keys fetch failure
        if (mounted) {
          HelperUtils.showSnackBarMessage(
            context,
            state.error.toString(),
            type: .error,
          );
        }
      }
    } on Exception catch (e) {
      // Handle any other exceptions
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          e.toString(),
          type: .error,
        );
      }
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  dynamic ifServiceUnlimited(dynamic text, {dynamic remining}) {
    if (text == 'unlimited') {
      return 'unlimited';
    }
    if (text == 'not_available') {
      return '';
    }
    if (remining != null) {
      return '';
    }

    return text;
  }

  bool isUnlimited(int text, {dynamic remining}) {
    if (text == 0) {
      return true;
    }
    if (remining != null) {
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'subscriptionPlan'.translate(context),
        actions: [
          GestureDetector(
            onTap: () async {
              await GuestChecker.check(
                onNotGuest: () async {
                  await Navigator.pushNamed(
                    context,
                    Routes.transactionHistory,
                  );
                },
              );
            },
            child: Container(
              height: 40.rh(context),
              width: 40.rw(context),
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.color.borderColor,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.all(4.rw(context)),
              child: CustomImage(
                imageUrl: AppIcons.transaction,
                color: context.color.textColorDark,
                width: 24.rw(context),
                height: 24.rh(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: BannerAdWidget(bannerSize: AdSize.banner),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await interstitialAdManager.show();
          Future.delayed(
            Duration.zero,
            () {
              Navigator.pop(context);
            },
          );
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<AssignInAppPackageCubit, AssignInAppPackageState>(
              listener: (context, state) async {
                if (state is AssignInAppPackageSuccess) {
                  await context.read<FetchSystemSettingsCubit>().fetchSettings(
                    isAnonymous: false,
                    forceRefresh: true,
                  );
                  await context.read<GetUserDataCubit>().getUserData();
                  HelperUtils.showSnackBarMessage(
                    context,
                    'packagePurchasedSuccessfully',
                    type: .success,
                  );
                }
              },
            ),
          ],
          child: Builder(
            builder: (context) {
              return BlocListener<
                AssignFreePackageCubit,
                AssignFreePackageState
              >(
                listener: (context, state) async {
                  if (state is AssignFreePackageSuccess) {
                    await context
                        .read<FetchSubscriptionPackagesCubit>()
                        .fetchPackages();
                    await context
                        .read<FetchSystemSettingsCubit>()
                        .fetchSettings(
                          isAnonymous: false,
                          forceRefresh: true,
                        );
                    await context.read<GetUserDataCubit>().getUserData();
                    HelperUtils.showSnackBarMessage(
                      context,
                      'freePackageAssigned',
                      type: .success,
                    );
                  }

                  if (state is AssignFreePackageFail) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      state.error.isNotEmpty
                          ? state.error
                          : 'failedToAssignFreePackage',
                      type: .error,
                    );
                  }
                },
                child: BlocBuilder<GetApiKeysCubit, GetApiKeysState>(
                  builder: (context, apiKeysState) {
                    if (apiKeysState is GetApiKeysInProgress) {
                      return buildSubscriptionShimmer();
                    }
                    if (apiKeysState is GetApiKeysFail) {
                      return NoDataFound(
                        title: 'noPackagesFound'.translate(context),
                        description: 'noPackagesFoundDescription'.translate(
                          context,
                        ),
                        onTapRetry: () async {
                          await _fetchApiKeys();
                        },
                      );
                    }
                    if (apiKeysState is GetApiKeysSuccess) {
                      return BlocBuilder<
                        FetchSubscriptionPackagesCubit,
                        FetchSubscriptionPackagesState
                      >(
                        builder: (context, state) {
                          if (state is FetchSubscriptionPackagesInProgress) {
                            return buildSubscriptionShimmer();
                          }
                          if (state is FetchSubscriptionPackagesFailure) {
                            if (state.errorMessage
                                is NoInternetConnectionError) {
                              return NoInternet(
                                onRetry: () async {
                                  await context
                                      .read<FetchSubscriptionPackagesCubit>()
                                      .fetchPackages();
                                },
                              );
                            }

                            return SomethingWentWrong(
                              errorMessage: state.errorMessage,
                            );
                          }
                          if (state is FetchSubscriptionPackagesSuccess) {
                            return Column(
                              children: [
                                CustomTabBar(
                                  tabController: _tabController,
                                  isScrollable: false,
                                  tabs: [
                                    Tab(text: 'myPlans'.translate(context)),
                                    Tab(text: 'allPlans'.translate(context)),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Current Plan Tab
                                      _buildCurrentPlanTab(state),

                                      // Other Plans Tab
                                      _buildOtherPlansTab(state),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return Container();
                        },
                      );
                    }
                    return Container();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildSubscriptionShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomShimmer(
              borderRadius: 4,
              height: 48,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          buildSubscriptionShimmerItem(),
          buildSubscriptionShimmerItem(),
        ],
      ),
    );
  }

  Widget buildSubscriptionShimmerItem() {
    return Container(
      margin: const EdgeInsetsDirectional.only(
        top: 10,
        start: 16,
        end: 16,
      ),
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          const CustomShimmer(
            borderRadius: 4,
            height: 50,
          ),
          ...List.generate(
            8,
            (index) => const Padding(
              padding: EdgeInsetsDirectional.only(
                start: 12,
                end: 12,
              ),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Row(
                    children: [
                      CustomShimmer(
                        borderRadius: 4,
                        height: 20,
                        width: 20,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: CustomShimmer(
                          borderRadius: 4,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.rh(context)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: MySeparator(
              color: context.color.tertiaryColor.withValues(alpha: 0.7),
              isShimmer: true,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(
              top: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomShimmer(
              borderRadius: 4,
              height: 60,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanTab(FetchSubscriptionPackagesSuccess state) {
    // Find and display only the active package
    final currentPackage = state.packageResponseModel.activePackage;

    return currentPackage.isNotEmpty
        ? ListView.builder(
            itemCount: currentPackage.length,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return CurrentPackageTileCard(
                onRenew: () async {
                  await onRenewSubscription(
                    activePackage: currentPackage[index],
                  );
                },
                package: currentPackage[index],
                allFeatures: state.packageResponseModel.allFeature,
              );
            },
          )
        : Center(
            heightFactor: double.infinity,
            child: NoDataFound(
              title: 'noMyPackagesFound'.translate(context),
              description: 'noMyPackagesFoundDescription'.translate(context),
              onTapRetry: () async {
                await _fetchApiKeys();
              },
            ),
          );
  }

  Widget _buildOtherPlansTab(FetchSubscriptionPackagesSuccess state) {
    final otherPackages = state.packageResponseModel.subscriptionPackage;

    if (otherPackages.isEmpty) {
      return Center(
        heightFactor: double.infinity,
        child: NoDataFound(
          title: 'noPackagesFound'.translate(context),
          description: 'noPackagesFoundDescription'.translate(context),
          onTapRetry: () async {
            await _fetchApiKeys();
          },
        ),
      );
    }

    return ListView.builder(
      physics: Constant.scrollPhysics,
      itemCount: otherPackages.length + 2, // +2 for loading and error widgets
      itemBuilder: (context, index) {
        if (index < otherPackages.length) {
          final subscriptionPackage = otherPackages[index];
          return SubscriptionPackageTile(
            package: subscriptionPackage,
            packageFeatures: state.packageResponseModel.allFeature,
            onTap: () async {
              await onTapSubscriptionTile(
                subscriptionPackage: subscriptionPackage,
              );
            },
          );
        } else if (index == otherPackages.length && state.isLoadingMore) {
          return UiUtils.progress();
        } else if (index == otherPackages.length + 1 && state.hasError) {
          return const CustomText('Something went wrong');
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> onTapSubscriptionTile({
    required SubscriptionPackageModel subscriptionPackage,
  }) async {
    await GuestChecker.check(
      onNotGuest: () async {
        if (subscriptionPackage.price == 0) {
          await onOnlineSubscribe(subscriptionPackage);
          return;
        }

        if (subscriptionPackage.packageStatus == 'review') {
          await CustomBottomSheet.show<dynamic>(
            context: context,
            title: 'review'.translate(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  'packageStatus'.translate(context),
                  fontSize: 16,
                ),
                SizedBox(height: 16.rh(context)),
                UiUtils.buildButton(
                  context,
                  onPressed: () async {
                    await Navigator.popAndPushNamed(
                      context,
                      Routes.transactionHistory,
                    );
                  },
                  buttonTitle: 'transactionHistory'.translate(context),
                ),
              ],
            ),
          );
          return;
        }

        if (Platform.isIOS) {
          await inAppPurchase.buy(
            subscriptionPackage.iosProductId,
            subscriptionPackage.id.toString(),
          );
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
            child: buildPaymentMethodsBottomSheet(
              subscriptionPackage: subscriptionPackage,
            ),
          );
        } else if (hasOnlineGateways) {
          await onOnlineSubscribe(
            subscriptionPackage,
            gatewayKey: _availableOnlineGateways.first,
          );
        } else if (hasBankTransfer) {
          await onBankTransferSubscribe(subscriptionPackage);
        } else {
          HelperUtils.showSnackBarMessage(
            context,
            'purchaseFailed',
            type: .error,
          );
        }
      },
    );
  }

  Future<void> onRenewSubscription({
    required ActivePackage activePackage,
  }) async {
    // Convert ActivePackage to SubscriptionPackageModel for subscription flow
    final subscriptionPackage = SubscriptionPackageModel(
      id: activePackage.id,
      iosProductId: activePackage.iosProductId,
      name: activePackage.name,
      translatedName: activePackage.translatedName,
      packageType: activePackage.packageType,
      price: activePackage.price,
      duration: activePackage.duration,
      createdAt: activePackage.createdAt,
      features: [], // Features not needed for subscription flow
      packageStatus:
          '', // Active packages are already active, so no review status
    );

    await GuestChecker.check(
      onNotGuest: () async {
        if (subscriptionPackage.price == 0) {
          await onOnlineSubscribe(subscriptionPackage);
          return;
        }

        // For active packages being renewed, skip review status check
        // as they are already active

        if (Platform.isIOS) {
          await inAppPurchase.buy(
            subscriptionPackage.iosProductId,
            subscriptionPackage.id.toString(),
          );
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
            child: buildPaymentMethodsBottomSheet(
              subscriptionPackage: subscriptionPackage,
            ),
          );
        } else if (hasOnlineGateways) {
          await onOnlineSubscribe(
            subscriptionPackage,
            gatewayKey: _availableOnlineGateways.first,
          );
        } else if (hasBankTransfer) {
          await onBankTransferSubscribe(subscriptionPackage);
        } else {
          HelperUtils.showSnackBarMessage(
            context,
            'purchaseFailed',
            type: .error,
          );
        }
      },
    );
  }

  Widget buildPaymentMethodsBottomSheet({
    required SubscriptionPackageModel subscriptionPackage,
  }) {
    final hasBankTransfer = isBankTransferActive ?? false;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
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
            SizedBox(height: 16.rh(context)),
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
                  await onBankTransferSubscribe(subscriptionPackage);
                } else {
                  Navigator.pop(context);
                  await onOnlineSubscribe(
                    subscriptionPackage,
                    gatewayKey: _selectedPaymentMethod,
                  );
                }
              },
            ),
          ],
        );
      },
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
    } else if (name == 'phonepe') {
      return AppIcons.phonepe;
    } else if (name == 'cashfree') {
      return AppIcons.cashfree;
    } else if (name == 'midtrans') {
      return AppIcons.midtrans;
    } else {
      return AppIcons.stripe;
    }
  }

  String _getPaymentGatewayTitle(String gateway) {
    final name = gateway.toLowerCase();
    if (name == 'flutterwave') {
      return 'Flutterwave';
    } else if (name == 'paystack') {
      return 'Paystack';
    } else if (name == 'razorpay') {
      return 'Razorpay';
    } else if (name == 'paypal') {
      return 'Paypal';
    } else if (name == 'phonepe') {
      return 'PhonePe';
    } else if (name == 'cashfree') {
      return 'Cashfree';
    } else if (name == 'midtrans') {
      return 'Midtrans';
    } else if (name == 'stripe') {
      return 'Stripe';
    }
    return gateway.firstUpperCase();
  }

  // PAYMENT METHODS

  // Method to handle online subscriptions
  Future<void> onOnlineSubscribe(
    SubscriptionPackageModel subscriptionPackage, {
    String? gatewayKey,
  }) async {
    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }

    // Handle free packages
    if (subscriptionPackage.price == 0) {
      await UiUtils.showBlurredDialoge(
        context,
        dialog: BlurredDialogBox(
          title: 'areYouSure'.translate(context),
          content: CustomText(
            'areYourSureForFreePackage'.translate(context),
          ),
          onAccept: () async {
            await context.read<AssignFreePackageCubit>().assign(
              subscriptionPackage.id,
            );
          },
        ),
      );
      return;
    }

    // Handle iOS in-app purchases
    if (Platform.isIOS) {
      await inAppPurchase.buy(
        subscriptionPackage.iosProductId,
        subscriptionPackage.id.toString(),
      );
      return;
    }

    final targetGateway =
        gatewayKey ??
        (_availableOnlineGateways.isNotEmpty
            ? _availableOnlineGateways.first
            : AppSettings.enabledPaymentGateway);
    if (targetGateway.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'purchaseFailed',
        type: .error,
      );
      return;
    }

    // Handle other payment gateways
    final paymentManager = PaymentManager();
    await paymentManager.pay(
      context: context,
      package: subscriptionPackage,
      gatewayKey: targetGateway,
    );
  }

  // Method to handle bank transfer subscriptions
  Future<void> onBankTransferSubscribe(
    SubscriptionPackageModel subscriptionPackage,
  ) async {
    await BankTransfer.show(
      context: context,
      subscriptionPackage: subscriptionPackage,
    );
  }

  // Bank transfer UI components have been moved to bank_transfer.dart

  // PAYMENT METHOD SELECTION UI

  // Payment option button for bottom sheet
  Widget _buildPaymentOptionForBottomSheet({
    required String value,
    required String title,
    required String icon,
    required dynamic Function(void Function()) setSheetState,
    Color? iconColor,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        // Update the parent state
        setState(() {
          _selectedPaymentMethod = value;
        });
        // Also update the bottom sheet UI
        setSheetState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? context.color.tertiaryColor
                : context.color.borderColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CustomImage(
              imageUrl: icon,
              color: iconColor,
              width: 24,
              height: 24,
            ),
            SizedBox(width: 12.rw(context)),
            CustomText(
              title,
              fontSize: 16,
              fontWeight: .w500,
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: context.color.primaryColor,
                  border: Border.all(
                    color: context.color.tertiaryColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: context.color.tertiaryColor,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
