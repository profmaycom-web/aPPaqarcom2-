import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/advertisement/fetch_ad_banners_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/cubits/appointment/post/create_appointment_request_cubit.dart';
import 'package:ebroker/data/cubits/interested/get_interested_user_cubit.dart';
import 'package:ebroker/data/cubits/property/change_property_status_cubit.dart';
import 'package:ebroker/data/cubits/property/create_advertisement_cubit.dart';
import 'package:ebroker/data/cubits/property/delete_property_cubit.dart';
import 'package:ebroker/data/cubits/property/fetch_similar_properties_cubit.dart';
import 'package:ebroker/data/cubits/property/interest/change_interest_in_property_cubit.dart';
import 'package:ebroker/data/cubits/property/renew_listing_cubit.dart';
import 'package:ebroker/data/cubits/property/report/property_report_cubit.dart';
import 'package:ebroker/data/cubits/property/update_property_status.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/cubits/utility/mortgage_calculator_cubit.dart';
import 'package:ebroker/data/model/ad_banner_model.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/property_details/property_sheet_controller.dart';
import 'package:ebroker/ui/screens/proprties/property_details/utils/property_details_helpers.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_agent_gallery_section.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_description_section.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_documents_section.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_enable_disable_section.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_header.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_image_carousel.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_interest_button.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_mortgage_banner.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_owner_bottom_bar.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_similar_properties_section.dart';
import 'package:ebroker/ui/screens/proprties/property_details/widgets/property_top_actions.dart';
import 'package:ebroker/ui/screens/proprties/widgets/interested_users.dart';
import 'package:ebroker/ui/screens/proprties/widgets/mortgage_calculator.dart';
import 'package:ebroker/ui/screens/proprties/widgets/outdoor_facilities.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_contact_buttons.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_location_section.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_parameters_grid.dart';
import 'package:ebroker/ui/screens/proprties/widgets/report_property_widget.dart';
import 'package:ebroker/ui/screens/widgets/panaroma_image_view.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:ebroker/utils/admob/interstitial_ad_manager.dart';
import 'package:material_ui/material_ui.dart';

typedef PropertyDetailsScreen = PropertyDetails;

class PropertyDetails extends StatefulWidget {
  const PropertyDetails({
    required this.property,
    super.key,
    this.fromPropertyAddSuccess,
    this.fromMyProperty,
    this.fromCompleteEnquiry,
    this.fromAgentDetails = false,
    this.heroTag,
    this.onClose,
  });

  final PropertyModel? property;
  final bool? fromMyProperty;
  final bool? fromCompleteEnquiry;
  final bool? fromPropertyAddSuccess;
  final bool fromAgentDetails;
  final String? heroTag;
  final VoidCallback? onClose;

  @override
  PropertyDetailsState createState() => PropertyDetailsState();

  static Widget buildWithProviders({
    required PropertyModel property,
    Key? key,
    bool fromMyProperty = false,
    bool fromCompleteEnquiry = false,
    bool fromSuccess = false,
    bool fromAgentDetails = false,
    String? heroTag,
    VoidCallback? onClose,
  }) {
    return MultiBlocProvider(
      key: key,
      providers: [
        BlocProvider(
          create: (context) => ChangeInterestInPropertyCubit(),
        ),
        BlocProvider(
          create: (context) => UpdatePropertyStatusCubit(),
        ),
        BlocProvider(
          create: (context) => DeletePropertyCubit(),
        ),
        BlocProvider(
          create: (context) => PropertyReportCubit(),
        ),
        BlocProvider(
          create: (context) => GetInterestedUserCubit(),
        ),
        BlocProvider(
          create: (context) => FetchAgentsPropertyCubit(),
        ),
        BlocProvider(
          create: (context) => FetchSimilarPropertiesCubit(),
        ),
        BlocProvider(
          create: (context) => RenewListingCubit(),
        ),
      ],
      child: PropertyDetails(
        key: key != null ? ValueKey('details-$key') : null,
        property: property,
        fromMyProperty: fromMyProperty,
        fromCompleteEnquiry: fromCompleteEnquiry,
        fromPropertyAddSuccess: fromSuccess,
        fromAgentDetails: fromAgentDetails,
        heroTag: heroTag,
        onClose: onClose,
      ),
    );
  }

  static Future<dynamic> open(
    BuildContext context, {
    required PropertyModel property,
    bool fromMyProperty = false,
    bool fromCompleteEnquiry = false,
    bool fromSuccess = false,
    bool fromAgentDetails = false,
    String? heroTag,
  }) {
    if (Navigator.of(context).canPop() || PropertySheetController.isShowing) {
      return Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {
          'propertyData': property,
          'fromMyProperty': fromMyProperty,
          'fromCompleteEnquiry': fromCompleteEnquiry,
          'fromSuccess': fromSuccess,
          'fromAgentDetails': fromAgentDetails,
          'heroTag': heroTag,
        },
      );
    }

    PropertySheetController.showProperty(
      property: property,
      fromMyProperty: fromMyProperty,
      fromCompleteEnquiry: fromCompleteEnquiry,
      fromSuccess: fromSuccess,
      fromAgentDetails: fromAgentDetails,
      heroTag: heroTag,
    );
    return Future.value();
  }

  static Route<dynamic> route(RouteSettings routeSettings) {
    try {
      final arguments = routeSettings.arguments as Map?;
      final property =
          arguments?['propertyData'] as PropertyModel? ?? PropertyModel();
      final fromMyProperty = arguments?['fromMyProperty'] as bool? ?? false;
      final fromCompleteEnquiry =
          arguments?['fromCompleteEnquiry'] as bool? ?? false;
      final fromSuccess = arguments?['fromSuccess'] as bool? ?? false;
      final fromAgentDetails = arguments?['fromAgentDetails'] as bool? ?? false;
      final heroTag = arguments?['heroTag'] as String?;

      return PageRouteBuilder<dynamic>(
        opaque: false,
        barrierDismissible: true,
        // ExpandableDetailsCard draws its own backdrop and slides itself in
        // and out, so the route adds no transition of its own.
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PropertyDetails.buildWithProviders(
            property: property,
            fromMyProperty: fromMyProperty,
            fromCompleteEnquiry: fromCompleteEnquiry,
            fromSuccess: fromSuccess,
            fromAgentDetails: fromAgentDetails,
            heroTag: heroTag,
          );
        },
      );
    } on Exception catch (_) {
      rethrow;
    }
  }
}

class PropertyDetailsState extends State<PropertyDetails>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const detailsPageSizedBoxHeight = 8.0;

  final ValueNotifier<bool> isEnabled = ValueNotifier(false);
  final InterstitialAdManager interstitialAdManager = InterstitialAdManager();

  PropertyModel? _property;
  List<Gallery> _galleryItems = [];
  bool _adLoaded = false;
  bool _isReported = false;
  int _currentImageIndex = 0;
  bool _isMortgageCalculatorOpening = false;
  bool _isLoading = true;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();
  final GlobalKey<ExpandableDetailsCardState> _cardKey =
      GlobalKey<ExpandableDetailsCardState>();

  bool get _isAddedByCurrentUser =>
      widget.fromMyProperty == true ||
      widget.property?.addedBy.toString() == HiveUtils.getUserId();

  bool get _isProfileCompleted {
    final isAgent = ActiveRoleManager.isAgent;
    if (isAgent) {
      final user = HiveUtils.getAgentProfileData();
      return user?.agentEmail != '' &&
          user?.agentMobile != '' &&
          user?.agentName != '' &&
          user?.agentAddress != '' &&
          user?.agentProfilePhoto != '';
    }
    final user = HiveUtils.getUserDetails();
    return user.email != '' &&
        user.mobile != '' &&
        user.name != '' &&
        user.address != '' &&
        user.profile != '';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    isEnabled.dispose();
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final loadedProperty = await HelperUtils.loadPropertyDetails(
        propertyId: widget.property?.id ?? 0,
        isMyProperty: _isAddedByCurrentUser,
        context: context,
      );
      if (loadedProperty != null) {
        if (mounted) {
          setState(() {
            _property = loadedProperty;
            _galleryItems = List.from(
              loadedProperty.gallery ?? const <Gallery>[],
            );
            isEnabled.value = loadedProperty.status.toString() == '1';
            _isReported =
                loadedProperty.allPropData?['is_reported'] as bool? ?? false;
            _isLoading = false;
          });
          _injectVideoInGallery();
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString(), type: .error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _galleryItems = List.from(widget.property?.gallery ?? const <Gallery>[]);
    isEnabled.value = widget.property?.status.toString() == '1';
    _isReported =
        widget.property?.allPropData?['is_reported'] as bool? ?? false;

    HelperUtils.runAfterTransition(context, () {
      if (!mounted) return;
      unawaited(_fetchDetails());

      if (!_isAddedByCurrentUser) {
        unawaited(_loadAd());
        unawaited(interstitialAdManager.load());
      }

      unawaited(
        context.read<FetchAdBannersCubit>().fetch(page: 'property_detail'),
      );
      unawaited(context.read<FetchOutdoorFacilityListCubit>().fetch());

      if (_isAddedByCurrentUser) {
        try {
          unawaited(
            context.read<GetInterestedUserCubit>().fetch(
              '${widget.property?.id}',
            ),
          );
        } on Exception catch (_) {
          Widgets.hideLoder(context);
        }
      }

      if (!HiveUtils.isGuest()) {
        unawaited(context.read<GetChatListCubit>().fetch(forceRefresh: false));
      }

      if (HiveUtils.getActiveRole() != ActiveRole.agent &&
          widget.property?.id != null) {
        unawaited(
          context.read<FetchSimilarPropertiesCubit>().fetchSimilarProperty(
            propertyId: widget.property!.id!,
          ),
        );
        unawaited(context.read<FetchPropertyReportReasonsListCubit>().fetch());
      }

      _injectVideoInGallery();
    });
  }

  Future<void> _onBackPress() async {
    final rootContext = Constant.navigatorKey.currentContext;

    // Defer heavy ad display and banner fetching until after pop transition completes (approx 400ms)
    if (!_isAddedByCurrentUser) {
      Future.delayed(const Duration(milliseconds: 400), () {
        unawaited(interstitialAdManager.show());
      });
    }

    if (rootContext != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (rootContext.mounted) {
          unawaited(
            rootContext.read<FetchAdBannersCubit>().fetch(page: 'homepage'),
          );
        }
      });
    }

    context.read<MortgageCalculatorCubit>().emptyMortgageCalculatorData();

    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    await Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      Routes.main,
      (route) => false,
    );
  }

  Future<void> _loadAd() async {
    if (_isAddedByCurrentUser || !AppSettings.isAdmobAdsEnabled) {
      return;
    }

    setState(() {
      _adLoaded = true;
    });
  }

  void _injectVideoInGallery() {
    final videoUrl = widget.property?.video?.trim();
    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    final hasVideo = _galleryItems.any((item) => item.isVideo ?? false);
    if (hasVideo) {
      return;
    }

    final videoGallery = Gallery(
      id: 99999999999,
      image: videoUrl,
      imageUrl: '',
      isVideo: true,
    );

    if (_galleryItems.length < 2) {
      _galleryItems.add(videoGallery);
    } else {
      // Insert video after the cover image (index 1) instead of first
      _galleryItems.insert(1, videoGallery);
    }

    if (mounted) {
      setState(() {});
    }
  }

  String? _statusFilter(String value) {
    if (value == 'Sell' || value == 'sell') {
      return 'sold'.translate(context);
    }
    if (value == 'Rent' || value == 'rent') {
      return 'rented'.translate(context);
    }
    if (value == 'Rented' || value == 'rented') {
      return 'rent'.translate(context);
    }

    return null;
  }

  int? _getStatus(String type) {
    int? value;
    if (type == 'Sell' || type == 'sell') {
      value = 2;
    } else if (type == 'Rent' || type == 'rent') {
      value = 3;
    } else if (type == 'Rented' || type == 'rented') {
      value = 1;
    }
    return value;
  }

  bool _hasDocuments() {
    return _property?.documents?.isNotEmpty ?? false;
  }

  bool _isThreeDImageAvailable() {
    final threeDImage = _property?.threeDImage;
    return !(threeDImage == '' || threeDImage == null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final property = _property;
    if (property == null) {
      return const SizedBox.shrink();
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<
          CreateAppointmentRequestCubit,
          CreateAppointmentRequestState
        >(
          listener: (context, state) {
            if (state is CreateAppointmentRequestSuccess) {
              HelperUtils.showSnackBarMessage(
                context,
                'appointmentScheduledSuccessfully',
                type: .success,
              );
              Navigator.pop(context);
            }
            if (state is CreateAppointmentRequestFailure) {
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: .error,
              );
            }
          },
        ),
        BlocListener<RenewListingCubit, RenewListingState>(
          listener: (context, state) {
            if (state is RenewListingInProgress) {
              unawaited(Widgets.showLoader(context));
            }
            if (state is RenewListingSuccess) {
              Widgets.hideLoder(context);
              HelperUtils.showSnackBarMessage(
                context,
                state.message,
                type: .success,
              );
              unawaited(_fetchDetails());
              unawaited(HelperUtils.loadMyProperties(context));
            }
            if (state is RenewListingFailure) {
              Widgets.hideLoder(context);
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: .error,
              );
            }
          },
        ),
        BlocListener<DeletePropertyCubit, DeletePropertyState>(
          listener: (context, state) async {
            if (state is DeletePropertySuccess) {
              if (!mounted) return;
              HelperUtils.showSnackBarMessage(
                context,
                'propertyDeletedSuccessfully'.translate(context),
                type: .success,
              );
              await HelperUtils.loadMyProperties(context);
              await _onBackPress();
            }
            if (state is DeletePropertyFailure) {
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: .error,
              );
            }
          },
        ),
        BlocListener<UpdatePropertyStatusCubit, UpdatePropertyStatusState>(
          listener: (context, state) async {
            if (state is UpdatePropertyStatusSuccess) {
              Widgets.hideLoder(context);
              HelperUtils.showSnackBarMessage(
                context,
                'statusUpdated'.translate(context),
                type: .success,
              );

              _refreshMyPropertiesStatus();
              setState(() {});
            }
            if (state is UpdatePropertyStatusFail) {
              Widgets.hideLoder(context);
            }
          },
        ),
        BlocListener<CreateAdvertisementCubit, CreateAdvertisementState>(
          listener: (context, state) async {
            if (state is! CreateAdvertisementSuccess) return;
            final id = _property?.id;
            if (id == null || !mounted) return;
            try {
              final refreshed = await HelperUtils.fetchPropertyDetails(
                propertyId: id,
                isMyProperty: _isAddedByCurrentUser,
              );
              if (!mounted) return;
              setState(() {
                _property = refreshed;
                _galleryItems = List.from(
                  refreshed.gallery ?? const <Gallery>[],
                );
                isEnabled.value = refreshed.status.toString() == '1';
                _isReported =
                    refreshed.allPropData?['is_reported'] as bool? ?? false;
              });
              _injectVideoInGallery();
              if (_isAddedByCurrentUser) {
                unawaited(HelperUtils.loadMyProperties(context));
              }
            } on Exception catch (_) {}
          },
        ),
      ],
      child: AnnotatedRegion(
        value: UiUtils.getSystemUiOverlayStyle(context: context),
        child: ExpandableDetailsCard(
          key: _cardKey,
          onClose: _onBackPress,
          bottomNavigationBar: _isLoading
              ? null
              : _buildBottomNavigationBar(property),
          appBarActions: _isLoading
              ? null
              : PropertyTopActions(
                  property: property,
                  isThreeDImageAvailable: _isThreeDImageAvailable(),
                  onActionSelected: _handleTopActionSelection,
                  onTapThreeDView: _openThreeDView,
                ),
          slivers: [
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingWithHeroImage(property)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PropertyImageCarousel(
                          property: property,
                          galleryItems: _galleryItems,
                          currentIndex: _currentImageIndex,
                          heroTag: widget.heroTag,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 12.rh(context),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: context.color.secondaryColor,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                  border: Border.all(
                                    color: context.color.borderColor,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    bottom: 2,
                                  ),
                                  child: PropertyHeader(
                                    property: property,
                                    heroTag: widget.heroTag,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: detailsPageSizedBoxHeight.rh(context),
                              ),
                              if (_isAddedByCurrentUser) ...[
                                PropertyEnableDisableSection(
                                  isEnabled: isEnabled,
                                  isDisabled:
                                      property.requestStatus.toString() ==
                                          'pending' ||
                                      (property.isExpired ?? false),
                                  onChanged: _handleEnableDisableChanged,
                                ),
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                              ],
                              if (property.description != null) ...[
                                PropertyDescriptionSection(
                                  property: property,
                                ),
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                              ],
                              if (property.propertyType
                                          .toString()
                                          .toLowerCase() ==
                                      'sell' &&
                                  !ActiveRoleManager.isAgent) ...[
                                PropertyMortgageBanner(
                                  property: property,
                                  onPressed: _openMortgageCalculator,
                                ),
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                              ],
                              _buildAboveFacilitiesBanner(),
                              if (property.parameters?.isNotEmpty ?? false) ...[
                                PropertyParametersGrid(
                                  property: property,
                                ),
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                              ],
                              _buildAdWidget(),
                              if (property
                                      .assignedOutdoorFacility
                                      ?.isNotEmpty ??
                                  false) ...[
                                OutdoorFacilityListWidget(
                                  outdoorFacilityList:
                                      property.assignedOutdoorFacility ?? [],
                                ),
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                              ],
                              if (property.addedBy.toString() !=
                                  HiveUtils.getUserId()) ...[
                                PropertyAgentGallerySection(
                                  property: property,
                                  gallery: _galleryItems,
                                  onScheduleAppointment: _scheduleAppointment,
                                  popAgentOnTap: widget.fromAgentDetails,
                                ),
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                              ],
                              PropertyLocationSection(
                                property: property,
                                heroTag: widget.heroTag,
                              ),
                              if (!HiveUtils.isGuest() &&
                                  HiveUtils.getUserId() !=
                                      property.addedBy) ...[
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                                PropertyInterestButton(
                                  property: property,
                                ),
                              ],
                              const SizedBox(
                                height: detailsPageSizedBoxHeight,
                              ),

                              if (!reportedProperties.contains(
                                    property.id,
                                  ) &&
                                  property.addedBy.toString() !=
                                      HiveUtils.getUserId() &&
                                  !_isReported &&
                                  property.id != null) ...[
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                                ReportPropertyButton(
                                  propertyId: property.id!,
                                  onSuccess: () {
                                    setState(() {});
                                  },
                                ),
                              ],
                              if (_hasDocuments()) ...[
                                const SizedBox(
                                  height: detailsPageSizedBoxHeight,
                                ),
                                PropertyDocumentsSection(
                                  property: property,
                                ),
                              ],
                              const SizedBox(
                                height: detailsPageSizedBoxHeight,
                              ),
                              PropertySimilarPropertiesSection(
                                property: property,
                              ),
                              SizedBox(
                                height: 24.rh(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTopActionSelection(String value) async {
    if (value == 'share') {
      await HelperUtils.share(
        context,
        _property?.slugId ?? '',
      );
      return;
    }

    if (value == 'renewListing') {
      await _handleRenewProperty();
      return;
    }

    if (value == 'interestedUsers') {
      await _showInterestedUsersBottomSheet();
      return;
    }

    if (value == 'markAsSold' ||
        value == 'markAsRented' ||
        value == 'markAsRent') {
      await _showStatusChangeDialog(value);
    }
  }

  Future<void> _openThreeDView() async {
    await Navigator.push(
      context,
      CupertinoPageRoute<dynamic>(
        builder: (context) => PanaromaImageScreen(
          imageUrl: _property?.threeDImage ?? '',
        ),
      ),
    );
  }

  Future<void> _showInterestedUsersBottomSheet() async {
    final interestedUserCubitReference = context.read<GetInterestedUserCubit>();

    await CustomBottomSheet.show<dynamic>(
      context: context,
      isScrollControlled: true,
      borderRadius: 8,
      showDragHandle: false,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: double.infinity,
        maxHeight: context.screenHeight * 0.7,
        minHeight: context.screenHeight * 0.3,
      ),
      child: InterestedUserListWidget(
        totalCount: '${widget.property?.totalInterestedUsers}',
        interestedUserCubitReference: interestedUserCubitReference,
      ),
    );
  }

  Future<void> _showStatusChangeDialog(String value) async {
    final property = _property;
    if (property == null) {
      return;
    }

    final statusValue = value == 'markAsRented'
        ? 'rent'
        : value == 'markAsRent'
        ? 'rented'
        : 'sold';

    final action = await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBuilderBox(
        title: 'changePropertyStatus'.translate(context),
        acceptButtonName: 'change'.translate(context),
        titleSize: context.font.md,
        titleWeight: .w500,
        cancelButtonBorderColor: context.color.tertiaryColor,
        acceptTextColor: context.color.buttonColor,
        cancelTextColor: context.color.tertiaryColor,
        cancelButtonColor: context.color.secondaryColor,
        contentBuilder: (context, s) {
          return Column(
            mainAxisSize: .min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: context.color.borderColor,
                  ),
                ),
                width: s.maxWidth,
                height: 48.rh(context),
                child: Center(
                  child: CustomText(
                    '${(property.propertyType ?? '').translate(context)} ${'property'.translate(context)}',
                    color: context.color.inverseSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CustomText(
                  'to'.translate(context),
                  fontSize: 15,
                  fontWeight: .w600,
                ),
              ),
              Container(
                width: s.maxWidth,
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: context.color.borderColor,
                  ),
                ),
                height: 48.rh(context),
                child: Center(
                  child: CustomText(
                    '${_statusFilter(statusValue) ?? statusValue.translate(context)} ${'property'.translate(context)}',
                    color: context.color.inverseSurface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (action == true) {
      if (AppSettings.isDemoModeOn) {
        return HelperUtils.showSnackBarMessage(
          context,
          'thisActionNotValidDemo'.translate(context),
          type: .warning,
        );
      }
      Future.delayed(Duration.zero, () async {
        await context.read<UpdatePropertyStatusCubit>().update(
          propertyId: property.id,
          status: _getStatus(property.propertyType ?? ''),
        );
        await _onBackPress();
      });
    }
  }

  void _refreshMyPropertiesStatus() {
    final property = _property;
    if (property?.id == null || property?.propertyType == null) {
      return;
    }

    try {
      context.read<FetchMyPropertiesCubit>().updateStatus(
        property!.id!,
        property.propertyType!,
      );
    } on Exception catch (_) {}
  }

  Widget _buildAboveFacilitiesBanner() {
    return BlocBuilder<FetchAdBannersCubit, FetchAdBannersState>(
      builder: (context, adBannerState) {
        AdBanner? banner;
        if (adBannerState is FetchAdBannersSuccess) {
          banner = adBannerState.banners.firstWhereOrNull(
            (item) =>
                item.placement == AdBannerPlacementType.aboveFacilities.value,
          );
        }

        if (adBannerState is! FetchAdBannersSuccess ||
            adBannerState.banners.isEmpty ||
            banner == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 18,
          ),
          child: GestureDetector(
            onTap: () => HelperUtils.onTapBanner(
              context,
              banner,
            ),
            child: CustomImage(
              imageUrl: banner.image ?? '',
              width: context.screenWidth,
              height: 80.rs(context),
              fit: .fill,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRenewProperty() async {
    final property = _property;
    if (property?.id == null) {
      return;
    }

    if (_checkPackageCubit.state is CheckPackageInProgress) {
      return;
    }

    unawaited(Widgets.showLoader(context));
    final packageAvailable = await _checkPackageCubit.checkAvailability(
      packageType: PackageType.propertyList,
    );
    Widgets.hideLoader(context);

    if (_checkPackageCubit.state is CheckPackageFail) {
      if (context.mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          (_checkPackageCubit.state as CheckPackageFail).error,
          type: .error,
        );
      }
      return;
    }

    if (!packageAvailable) {
      PayAsYouGoModel? payAsYouGoPackage;
      bool? isBankTransferActive;
      var availableOnlineGateways = <String>[];

      try {
        await context.read<GetApiKeysCubit>().fetch();
        if (!mounted) return;
        final apiKeyState = context.read<GetApiKeysCubit>().state;
        if (apiKeyState is GetApiKeysSuccess) {
          isBankTransferActive = apiKeyState.bankTransferStatus == '1';
          availableOnlineGateways = apiKeyState.enabledPaymentGateways;

          await context.read<FetchSubscriptionPackagesCubit>().fetchPackages();
          if (!mounted) return;
          final packageState = context
              .read<FetchSubscriptionPackagesCubit>()
              .state;
          if (packageState is FetchSubscriptionPackagesSuccess) {
            final match = packageState.packageResponseModel.payAsYouGo
                .where((p) => p.type == 'property')
                .toList();
            if (match.isNotEmpty) {
              payAsYouGoPackage = match.first;
            }
          }
        }
      } on Exception catch (_) {}

      await UiUtils.showBlurredDialoge(
        context,
        dialog: BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.propertyList,
          isAcceptContainesPush: true,
          preFetchedPayAsYouGo: payAsYouGoPackage,
          preFetchedIsBankTransferActive: isBankTransferActive,
          preFetchedAvailableOnlineGateways: availableOnlineGateways,
        ),
      );
      return;
    }

    await context.read<RenewListingCubit>().renew(
      id: property!.id!,
      type: 'property',
    );
  }

  Future<void> _scheduleAppointment() async {
    final property = _property;
    if (property == null) {
      return;
    }

    final propertiesData = PropertyDetailsHelpers.toPropertiesData(property);
    final agentData = PropertyDetailsHelpers.createAgentCustomerData(property);

    await Navigator.pushNamed(
      context,
      Routes.appointmentFlow,
      arguments: {
        'isAdmin': property.isAdmin ?? false,
        'agentDetails': agentData,
        'preSelectedProperty': propertiesData,
      },
    );
  }

  Future<void> _handleEnableDisableChanged(bool newValue) async {
    final property = _property;
    if (property?.id == null) {
      return;
    }

    final cubit = context.read<ChangePropertyStatusCubit>();
    final currentState = cubit.state;

    if (currentState is ChangePropertyStatusInProgress) {
      return;
    }

    final status = !isEnabled.value ? 1 : 0;
    isEnabled.value = newValue;

    try {
      await cubit.enableProperty(
        propertyId: property!.id!,
        status: status,
      );

      final newState = cubit.state;
      if (newState is ChangePropertyStatusFailure) {
        isEnabled.value = !newValue;

        final errorMessage = newState.error.contains('429')
            ? 'tooManyRequestsPleaseWait'.translate(context)
            : newState.error;

        HelperUtils.showSnackBarMessage(
          context,
          errorMessage,
          type: .error,
        );
      }
    } on Exception catch (_) {
      isEnabled.value = !newValue;
      HelperUtils.showSnackBarMessage(
        context,
        'somethingWentWrong',
        type: .error,
      );
    }
  }

  Future<void> _openMortgageCalculator() async {
    if (_isMortgageCalculatorOpening) {
      return;
    }

    setState(() {
      _isMortgageCalculatorOpening = true;
    });

    try {
      await GuestChecker.check(
        onNotGuest: () async {
          final isAvailable = await _checkPackageCubit.checkAvailability(
            packageType: PackageType.mortgageCalculatorDetail,
          );

          if (!isAvailable) {
            if (context.mounted) {
              await UiUtils.showBlurredDialoge(
                context,
                dialog: const BlurredSubscriptionDialogBox(
                  packageType: SubscriptionPackageType.mortgageCalculatorDetail,
                  isAcceptContainesPush: true,
                ),
              );
            }
            return;
          }

          unawaited(_cardKey.currentState?.expand());
          await CustomBottomSheet.show<dynamic>(
            context: context,
            sheetAnimationStyle: const AnimationStyle(
              duration: Duration(milliseconds: 350),
              reverseDuration: Duration(milliseconds: 250),
            ),
            isScrollControlled: true,
            borderRadius: 16,
            child: MortgageCalculator(
              property: widget.property!,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMortgageCalculatorOpening = false;
        });
      }
    }
  }

  Widget _buildBottomNavigationBar(PropertyModel property) {
    if (HiveUtils.isGuest() || HiveUtils.getUserId() != property.addedBy) {
      return PropertyContactButtons(property: property);
    }

    return BlocBuilder<FetchMyPropertiesCubit, FetchMyPropertiesState>(
      builder: (context, state) {
        final model = _getPropertyModel(state);
        if (model == null) {
          return const SizedBox.shrink();
        }

        return PropertyOwnerBottomBar(
          showFeatureButton:
              !HiveUtils.isGuest() &&
              !AppSettings.isDemoModeOn &&
              (model.isFeatureAvailable ?? false) &&
              !(model.promoted ?? false) &&
              model.isExpired != true,
          showEditButton:
              model.propertyType?.toLowerCase() != 'sold' &&
              model.propertyType?.toLowerCase() != 'rented' &&
              model.requestStatus?.toLowerCase() != 'pending' &&
              model.isExpired != true,
          onFeaturePressed: _handleFeatureButtonPress,
          onEditPressed: _handleEditButtonPress,
          onDeletePressed: _handleDeleteButtonPress,
        );
      },
    );
  }

  PropertyModel? _getPropertyModel(FetchMyPropertiesState state) {
    if (state is FetchMyPropertiesSuccess) {
      if (_property?.id == null) {
        return null;
      }
      try {
        return state.myProperty.firstWhere(
          (element) => element.id == _property?.id,
          orElse: () {
            return widget.property ?? PropertyModel();
          },
        );
      } on Exception catch (_) {}
    }
    return widget.property;
  }

  Future<void> _handleFeatureButtonPress(
    GetSubscriptionPackageLimitsState _,
  ) async {
    await context.read<GetSubsctiptionPackageLimitsCubit>().getLimits(
      packageType: 'property_feature',
    );

    final state = context.read<GetSubsctiptionPackageLimitsCubit>().state;

    if (state is GetSubsctiptionPackageLimitsFailure) {
      await _showFeatureSubscriptionDialog();
    } else if (state is GetSubscriptionPackageLimitsSuccess) {
      if (state.error) {
        await _showPackageLimitDialog(state.message);
      } else {
        await _showCreateAdvertisementDialog();
      }
    }
  }

  Future<void> _showFeatureSubscriptionDialog() async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: const BlurredSubscriptionDialogBox(
        packageType: SubscriptionPackageType.propertyFeature,
        isAcceptContainesPush: true,
      ),
    );
  }

  Future<void> _showPackageLimitDialog(String message) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: message.firstUpperCase(),
        isAcceptContainesPush: true,
        onAccept: _navigateToSubscriptionPackages,
        content: CustomText('yourPackageLimitOver'.translate(context)),
      ),
    );
  }

  Future<void> _navigateToSubscriptionPackages() async {
    await Navigator.popAndPushNamed(
      context,
      Routes.subscriptionPackageListRoute,
      arguments: {
        'from': 'propertyDetails',
        'isBankTransferEnabled': _getBankTransferStatus(),
      },
    );
  }

  bool _getBankTransferStatus() {
    final apiKeysState = context.read<GetApiKeysCubit>().state;
    return apiKeysState is GetApiKeysSuccess &&
        apiKeysState.bankTransferStatus == '1';
  }

  Future<void> _showCreateAdvertisementDialog() async {
    final property = _property;
    if (property == null) {
      return;
    }

    try {
      await showDialog<dynamic>(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => CreateAdvertisementPopup(
          property: property,
          isProject: false,
          project: ProjectModel(),
        ),
      );
    } on Exception catch (error) {
      HelperUtils.showSnackBarMessage(
        context,
        error.toString(),
        type: .error,
      );
    }
  }

  Future<void> _handleEditButtonPress() async {
    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }

    try {
      if (!await _checkProfileCompletion()) {
        return;
      }

      await _processEditProperty();
    } on Exception catch (_) {
      // Error handling is done in _processEditProperty
    } finally {
      Widgets.hideLoder(context);
    }
  }

  Future<bool> _checkProfileCompletion() async {
    final verificationRequired = ActiveRoleManager.isAgent
        ? AppSettings.isVerificationRequiredForAgent
        : AppSettings.isVerificationRequiredForUser;

    if (verificationRequired && !_isProfileCompleted) {
      await _showProfileCompletionDialog();
      Widgets.hideLoder(context);
      return false;
    }
    return true;
  }

  Future<void> _showProfileCompletionDialog() async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'completeProfile'.translate(context),
        isAcceptContainesPush: true,
        onAccept: _navigateToEditProfile,
        content: CustomText('completeProfileFirst'.translate(context)),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    await Navigator.popAndPushNamed(
      context,
      Routes.editProfile,
      arguments: {
        'from': 'home',
        'navigateToHome': true,
      },
    );
  }

  Future<void> _processEditProperty() async {
    final property = _property;
    if (property?.category?.id == null) {
      return;
    }

    try {
      final category = await context.read<FetchCategoryCubit>().get(
        property!.category!.id!,
      );

      final mappedParameters = PropertyDetailsHelpers.mapCategoryParameters(
        category: category,
        property: property,
      );

      _updateConstantAddProperty(category, mappedParameters);

      await Navigator.pushNamed(
        context,
        Routes.addPropertyDetailsScreen,
        arguments: {
          'property': property,
          'details': PropertyDetailsHelpers.buildEditablePropertyDetails(
            property,
            category: category,
            mappedParameters: mappedParameters,
          ),
        },
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  void _updateConstantAddProperty(
    Category category,
    List<dynamic> mappedParameters,
  ) {
    final property = _property;
    if (property?.category == null) {
      return;
    }

    Constant.addProperty.addAll({
      'category': Category(
        category: property?.category!.category,
        id: property?.category?.id,
        image: property?.category?.image,
        parameterTypes: mappedParameters,
      ),
    });
  }

  Future<void> _handleDeleteButtonPress() async {
    if (!(await _checkDemoModeDelete())) {
      return;
    }

    await _showDeleteConfirmationDialog();
  }

  Future<bool> _checkDemoModeDelete() async {
    final isPropertyActive = _property?.status.toString() == '1';
    if (AppSettings.isDemoModeOn &&
        isPropertyActive &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return false;
    }
    return true;
  }

  Future<dynamic> _showDeleteConfirmationDialog() async {
    final property = _property;
    if (property?.id == null) {
      return null;
    }

    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'areYouSure'.translate(context),
        svgImagePath: AppIcons.deleteIllustration,
        onAccept: () async {
          await context.read<DeletePropertyCubit>().delete(property!.id!);
        },
        content: CustomText(
          'deletepropertywarning'.translate(context),
          maxLines: 5,
          textAlign: .center,
        ),
      ),
    );
  }

  Widget _buildAdWidget() {
    if (!_adLoaded || !AppSettings.isAdmobAdsEnabled) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<FetchAdBannersCubit, FetchAdBannersState>(
      builder: (context, adBannerState) {
        if (adBannerState is FetchAdBannersSuccess &&
            adBannerState.banners.isNotEmpty) {
          return Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 8),
            child: const BannerAdWidget(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingWithHeroImage(PropertyModel property) {
    final imageUrl = property.titleImage ?? '';
    final heroTag = widget.heroTag;

    Widget heroImage = CustomImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 218.rs(context),
      loadingImageHash: property.lowQualityTitleImage,
    );

    if (heroTag != null) {
      heroImage = Hero(
        tag: heroTag,
        child: heroImage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            heroImage,
            if (property.isPremium == true ||
                property.allPropData?['is_premium'] == true)
              PositionedDirectional(
                start: 16.rh(context),
                top: 16.rh(context),
                child: Container(
                  alignment: Alignment.center,
                  child: heroTag != null
                      ? Hero(
                          tag: '$heroTag-premium',
                          child: CustomImage(
                            imageUrl: AppIcons.premium,
                            height: 24.rh(context),
                            width: 24.rw(context),
                          ),
                        )
                      : CustomImage(
                          imageUrl: AppIcons.premium,
                          height: 24.rh(context),
                          width: 24.rw(context),
                        ),
                ),
              ),
            if (property.promoted == true)
              PositionedDirectional(
                bottom: 16.rh(context),
                start: 16.rh(context),
                child: heroTag != null
                    ? Hero(
                        tag: '$heroTag-promoted',
                        child: const PromotedCard(),
                      )
                    : const PromotedCard(),
              ),
          ],
        ),
        Padding(
          padding: .symmetric(horizontal: 16.rw(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertyHeader(
                property: property,
                heroTag: heroTag,
              ),
              SizedBox(height: detailsPageSizedBoxHeight.rh(context)),
              CustomShimmer(
                width: double.infinity,
                height: 120.rh(context),
                borderRadius: 4,
              ),
              SizedBox(height: 24.rh(context)),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 2 ? 8.rw(context) : 0,
                      ),
                      child: CustomShimmer(
                        width: double.infinity,
                        height: 70.rh(context),
                        borderRadius: 8,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.rh(context)),
              CustomShimmer(
                width: double.infinity,
                height: 100.rh(context),
                borderRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
