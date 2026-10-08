import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/data/cubits/project/change_project_status_cubit.dart';
import 'package:ebroker/data/cubits/project/delete_project_cubit.dart';
import 'package:ebroker/data/cubits/property/create_advertisement_cubit.dart';
import 'package:ebroker/data/cubits/property/renew_listing_cubit.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/data/repositories/project_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/chat/helpers/open_chat_screen.dart';
import 'package:ebroker/ui/screens/project/widgets/project_helpers.dart';
import 'package:ebroker/ui/screens/proprties/property_details/property_sheet_controller.dart';
import 'package:ebroker/ui/screens/proprties/widgets/agent_profile.dart';
import 'package:ebroker/ui/screens/proprties/widgets/google_map_screen.dart';
import 'package:ebroker/ui/screens/widgets/interactive_property_map.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({
    required this.project,
    super.key,
    this.heroTag,
    this.fromAgentDetails = false,
    this.onClose,
  });

  final ProjectModel project;
  final String? heroTag;
  final bool fromAgentDetails;
  final VoidCallback? onClose;

  static Widget buildWithProviders({
    required ProjectModel project,
    Key? key,
    String? heroTag,
    bool fromAgentDetails = false,
    VoidCallback? onClose,
  }) {
    return MultiBlocProvider(
      key: key,
      providers: [
        BlocProvider(create: (context) => DeleteProjectCubit()),
        BlocProvider(create: (context) => RenewListingCubit()),
      ],
      child: ProjectDetailsScreen(
        key: key != null ? ValueKey('project-details-$key') : null,
        project: project,
        heroTag: heroTag,
        fromAgentDetails: fromAgentDetails,
        onClose: onClose,
      ),
    );
  }

  static PageRouteBuilder<dynamic> route(RouteSettings settings) {
    final arguement = settings.arguments as Map?;
    final project = arguement?['project'] as ProjectModel? ?? ProjectModel();
    final heroTag = arguement?['heroTag'] as String?;
    final fromAgentDetails = arguement?['fromAgentDetails'] as bool? ?? false;

    return PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      // ExpandableDetailsCard draws its own backdrop and slides itself in
      // and out, so the route adds no transition of its own.
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectDetailsScreen.buildWithProviders(
          project: project,
          heroTag: heroTag,
          fromAgentDetails: fromAgentDetails,
        );
      },
    );
  }

  static Future<dynamic> open(
    BuildContext context, {
    required ProjectModel project,
    String? heroTag,
    bool fromAgentDetails = false,
  }) {
    if (Navigator.of(context).canPop() || PropertySheetController.isShowing) {
      return Navigator.pushNamed(
        context,
        Routes.projectDetailsScreen,
        arguments: {
          'project': project,
          'heroTag': heroTag,
          'fromAgentDetails': fromAgentDetails,
        },
      );
    }

    PropertySheetController.showProject(
      project: project,
      heroTag: heroTag,
      fromAgentDetails: fromAgentDetails,
    );
    return Future.value();
  }

  @override
  CloudState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends CloudState<ProjectDetailsScreen>
    with TickerProviderStateMixin {
  static const detailsPageSizedBoxHeight = 8.0;

  final GlobalKey<ExpandableDetailsCardState> _cardKey =
      GlobalKey<ExpandableDetailsCardState>();
  bool _isExpanded = false;

  int _currentImageIndex = 0;

  final ValueNotifier<bool> _isEnabled = ValueNotifier(false);

  late ProjectModel _project;
  late final bool _isMyProject;

  late final FetchMyProjectsCubit _myProjectsCubit;
  bool _isLoading = true;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _myProjectsCubit = context.read<FetchMyProjectsCubit>();

    _isEnabled.value = _project.status.toString() == '1';
    _isMyProject = _checkIsProjectMine();
    if (widget.project.videoLink != '' && widget.project.videoLink != null) {
      setState(() {});
    }

    HelperUtils.runAfterTransition(context, () {
      if (!mounted) return;
      unawaited(_fetchDetails());
    });
  }

  Future<void> _fetchDetails() async {
    try {
      final loadedProject = await HelperUtils.loadProjectDetails(
        projectId: _project.id!,
        isMyProject: _isMyProject,
        context: context,
      );
      if (loadedProject != null) {
        if (mounted) {
          setState(() {
            _project = loadedProject;
            _isEnabled.value = _project.status.toString() == '1';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          await _onBackPress();
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
  void dispose() {
    _isEnabled.dispose();
    unawaited(_checkPackageCubit.close());

    super.dispose();
  }

  bool _checkIsProjectMine() {
    return _project.addedBy.toString() == HiveUtils.getUserId();
  }

  List<Plan> get _floors => (_project.plans ?? [])
      .where((plan) => plan.document?.isNotEmpty ?? false)
      .toList();
  bool get _hasFloors => _floors.isNotEmpty;
  bool get _hasDocuments => _project.documents?.isNotEmpty ?? false;

  Future<void> _onBackPress() async {
    if (!mounted) return;

    if (_isMyProject) {
      final rootContext = Constant.navigatorKey.currentContext;
      if (rootContext != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (rootContext.mounted) {
            unawaited(
              rootContext.read<FetchMyProjectsCubit>().fetchMyProjects(),
            );
          }
        });
      }
    }

    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    await Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      Routes.main,
      (route) => false,
    );
  }

  Future<void> _handleStatusChange(bool newValue) async {
    if (_project.isExpired ?? false) return;

    final cubit = context.read<ChangeProjectStatusCubit>();
    final currentState = cubit.state;

    if (currentState is ChangeProjectStatusInProgress) return;

    final status = _isEnabled.value ? 0 : 1;
    _isEnabled.value = newValue;

    try {
      await cubit.enableProject(
        projectId: _project.id!,
        status: status,
      );

      final newState = cubit.state;
      if (newState is ChangeProjectStatusFailure) {
        _isEnabled.value = !newValue;
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
      _isEnabled.value = !newValue;
      HelperUtils.showSnackBarMessage(
        context,
        'somethingWentWrong',
        type: .error,
      );
    }
  }

  Widget _buildEnableDisableSwitch() {
    final isDisabled =
        _project.requestStatus.toString().toLowerCase() != 'approved' ||
        (_project.isExpired ?? false);

    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Row(
        children: [
          CustomText(
            'updateProjectStatus'.translate(context),
            fontSize: context.font.md,
            color: context.color.textColorDark,
            fontWeight: .w600,
          ),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: _isEnabled,
            builder: (context, value, child) {
              return UiSwitch(
                trackColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.disabled)) {
                      return context.color.textColorDark.withValues(alpha: 0.1);
                    }
                    if (states.contains(WidgetState.selected)) {
                      return context.color.tertiaryColor;
                    }
                    return Colors.grey;
                  },
                ),
                value: value,
                onChanged: isDisabled ? null : _handleStatusChange,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDescription() {
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'aboutThisProjectLbl'.translate(context),
            fontWeight: .w500,
            fontSize: context.font.md,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          ReadMoreText(
            text:
                _project.translatedDescription ??
                _project.description?.trim() ??
                '',
            style: TextStyle(
              fontWeight: .w400,
              fontSize: context.font.xs,
              color: context.color.textColorDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    if (!_hasDocuments) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Documents'.translate(context),
            fontWeight: FontWeight.bold,
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
          const SizedBox(height: 12),
          Divider(
            color: context.color.textColorDark.withValues(alpha: 0.1),
            height: 1,
          ),
          ListView.separated(
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => Divider(
              color: context.color.textColorDark.withValues(alpha: 0.08),
              height: 1,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final document = _project.documents![index];
              return DownloadableDocument(url: document.name!);
            },
            itemCount: _project.documents!.length,
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlansSection() {
    if (!_hasFloors) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'floorPlans'.translate(context),
            fontWeight: FontWeight.bold,
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
          const SizedBox(height: 12),
          Divider(
            color: context.color.textColorDark.withValues(alpha: 0.1),
            height: 1,
          ),
          ListView.separated(
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => Divider(
              color: context.color.textColorDark.withValues(alpha: 0.08),
              height: 1,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _floors.length,
            itemBuilder: (context, index) {
              final floor = _floors[index];
              return CustomFloorPlanTile(
                title: floor.title ?? '',
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      floor.document!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'projectLocation'.translate(context),
            fontWeight: .w500,
            fontSize: context.font.md,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          Column(
            crossAxisAlignment: .start,
            children: [
              _buildLocation(
                address: _project.location!,
              ),
              SizedBox(height: 8.rh(context)),
              _buildMapPreview(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocation({required String address}) {
    return CustomText(
      '${'addressLbl'.translate(context)}: $address',
      fontWeight: .w500,
      fontSize: context.font.sm,
      color: context.color.textColorDark.withValues(alpha: 0.89),
    );
  }

  Widget _buildMapPreview() {
    if (!_isExpanded) {
      return GestureDetector(
        onTap: () => unawaited(_cardKey.currentState?.expand()),
        child: Container(
          height: 168.rh(context),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.color.textColorDark.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.color.borderColor,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomShimmer(
                  height: 168.rh(context),
                  width: double.infinity,
                  borderRadius: 8,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.location,
                      height: 28.rh(context),
                      color: context.color.tertiaryColor,
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      'mapViewLbl'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textColorDark.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 168.rh(context),
      child: InteractivePropertyMap(
        latitude: double.tryParse(_project.latitude ?? '') ?? 0,
        longitude: double.tryParse(_project.longitude ?? '') ?? 0,
        propertyType: _project.type ?? '',
        delayMs: 300,
        onFullScreenTap: _navigateToMap,
      ),
    );
  }

  Future<void> _navigateToMap() async {
    await Navigator.push(
      context,
      CupertinoPageRoute<dynamic>(
        builder: (context) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            iconTheme: IconThemeData(color: context.color.tertiaryColor),
            backgroundColor: Colors.transparent,
          ),
          body: GoogleMapScreen(
            latitude: double.tryParse(_project.latitude ?? '') ?? 0,
            longitude: double.tryParse(_project.longitude ?? '') ?? 0,
            propertyType: _project.type ?? '',
          ),
        ),
      ),
    );
  }

  Future<void> _handleRenewProject() async {
    if (_checkPackageCubit.state is CheckPackageInProgress) {
      return;
    }

    unawaited(Widgets.showLoader(context));
    final packageAvailable = await _checkPackageCubit.checkAvailability(
      packageType: PackageType.projectList,
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
                .where((p) => p.type == 'project')
                .toList();
            if (match.isNotEmpty) payAsYouGoPackage = match.first;
          }
        }
      } on Exception catch (_) {}

      await UiUtils.showBlurredDialoge(
        context,
        dialog: BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.projectList,
          isAcceptContainesPush: true,
          preFetchedPayAsYouGo: payAsYouGoPackage,
          preFetchedIsBankTransferActive: isBankTransferActive,
          preFetchedAvailableOnlineGateways: availableOnlineGateways,
        ),
      );
      return;
    }

    await context.read<RenewListingCubit>().renew(
      id: _project.id!,
      type: 'project',
    );
  }

  Future<void> _handleFeaturePress() async {
    await context.read<GetSubsctiptionPackageLimitsCubit>().getLimits(
      packageType: 'project_feature',
    );

    final state = context.read<GetSubsctiptionPackageLimitsCubit>().state;

    if (state is GetSubsctiptionPackageLimitsFailure) {
      await UiUtils.showBlurredDialoge(
        context,
        dialog: const BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.projectFeature,
          isAcceptContainesPush: true,
        ),
      );
    } else if (state is GetSubscriptionPackageLimitsSuccess) {
      if (state.error) {
        await _showPackageLimitDialog(state.message.translate(context));
      } else {
        await _showCreateAdvertisementDialog();
      }
    }
  }

  Future<void> _showPackageLimitDialog(String message) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: message.firstUpperCase(),
        isAcceptContainesPush: true,
        onAccept: () async {
          await Navigator.popAndPushNamed(
            context,
            Routes.subscriptionPackageListRoute,
            arguments: {
              'from': 'propertyDetails',
              'isBankTransferEnabled':
                  (context.read<GetApiKeysCubit>().state as GetApiKeysSuccess)
                      .bankTransferStatus ==
                  '1',
            },
          );
        },
        content: CustomText('yourPackageLimitOver'.translate(context)),
      ),
    );
  }

  Future<void> _showCreateAdvertisementDialog() async {
    try {
      await showDialog<dynamic>(
        context: context,
        builder: (context) => CreateAdvertisementPopup(
          property: PropertyModel(),
          isProject: true,
          project: _project,
        ),
      );
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: .error,
      );
    }
  }

  Future<void> _handleEditPress() async {
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
      await Navigator.pushNamed(
        context,
        Routes.addProjectDetails,
        arguments: {
          'id': _project.id,
          'meta_title': _project.metaTitle,
          'meta_description': _project.metaDescription,
          'meta_image': _project.metaImage,
          'slug_id': _project.slugId,
          'category_id': _project.category!.id,
          'translations': _project.translations,
          'project': _project,
          'is_premium': _project.isPremium ?? false,
          'video_type': _project.videoType,
        },
      );
    } on Exception catch (_) {
      HelperUtils.showSnackBarMessage(
        context,
        'somethingWentWrong',
        type: .error,
      );
    }
  }

  Future<void> _handleDeletePress() async {
    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }

    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'areYouSure'.translate(context),
        svgImagePath: AppIcons.deleteIllustration,
        onAccept: () async {
          await context.read<DeleteProjectCubit>().delete(_project.id!);
        },
        content: CustomText(
          'projectWillNotRecover'.translate(context),
          textAlign: .center,
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: context.color.textColorDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        // border: Border.all(
        //   color: context.color.textColorDark.withValues(alpha: 0.12),
        // ),
      ),
      child: CustomText(
        text,
        color: context.color.textColorDark,
        fontSize: 11,
      ),
    );
  }

  String? get _projectPhoneNumber {
    final directMobile =
        _project.agentProfile?.agentMobile ??
        _project.customer?.mobile ??
        _project.contactNumber;
    if (directMobile != null && directMobile.trim().isNotEmpty) {
      return directMobile.trim();
    }
    if (_project.isAdmin == true || _project.roleContext == 'admin') {
      final companyData = context.read<FetchSystemSettingsCubit>().companyData;
      final tel1 = companyData?.companyTel1?.trim();
      final tel2 = companyData?.companyTel2?.trim();
      if (tel1 != null && tel1.isNotEmpty) return tel1;
      if (tel2 != null && tel2.isNotEmpty) return tel2;
    }
    return null;
  }

  bool get _canShowWhatsapp => WhatsappHelper.canShow(
    _projectPhoneNumber,
    _project.agentProfile?.agentCountryCode,
  );

  Widget _buildBottomNavigationContent() {
    if (_isLoading) return const SizedBox.shrink();

    if (!_isMyProject) {
      return _buildAgentContactButtons();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.primaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.12),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!HiveUtils.isGuest() && !AppSettings.isDemoModeOn) ...[
            if ((_project.isFeatureAvailable ?? false) &&
                !(_project.isPromoted ?? false) &&
                _project.isExpired != true) ...[
              Expanded(
                child:
                    BlocBuilder<
                      GetSubsctiptionPackageLimitsCubit,
                      GetSubscriptionPackageLimitsState
                    >(
                      builder: (context, state) {
                        return UiUtils.buildButton(
                          context,
                          height: 48.rh(context),
                          disabled: _project.status.toString() == '0',
                          onPressed: _handleFeaturePress,
                          prefixWidget: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 4),
                            child: CustomImage(
                              imageUrl: AppIcons.promoted,
                              color: context.color.buttonColor,
                              width: 18.rw(context),
                              height: 18.rh(context),
                            ),
                          ),
                          fontSize: context.font.md,
                          buttonTitle: 'feature'.translate(context),
                        );
                      },
                    ),
              ),
              SizedBox(width: 16.rw(context)),
            ],
          ],
          if (_project.requestStatus != 'pending' &&
              _project.isExpired != true) ...[
            Expanded(
              child: UiUtils.buildButton(
                context,
                height: 48.rh(context),
                onPressed: _handleEditPress,
                fontSize: context.font.md,
                prefixWidget: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: CustomImage(
                    imageUrl: AppIcons.edit,
                    color: context.color.buttonColor,
                    height: 18.rh(context),
                    width: 18.rw(context),
                  ),
                ),
                buttonTitle: 'edit'.translate(context),
              ),
            ),
            SizedBox(width: 16.rw(context)),
          ],
          Expanded(
            child: UiUtils.buildButton(
              context,
              height: 48.rh(context),
              padding: const EdgeInsets.symmetric(horizontal: 1),
              prefixWidget: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: CustomImage(
                  imageUrl: AppIcons.delete,
                  color: context.color.buttonColor,
                  width: 18.rw(context),
                  height: 18.rh(context),
                ),
              ),
              onPressed: _handleDeletePress,
              fontSize: context.font.md,
              buttonTitle: 'deleteBtnLbl'.translate(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentContactButtons() {
    final canShowWhatsapp = _canShowWhatsapp;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.12),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      height: 72.rh(context),
      child: Row(
        spacing: 12.rw(context),
        children: <Widget>[
          if (canShowWhatsapp) ...[
            _buildContactIconButton(
              AppIcons.callFilled,
              onPressed: _onTapCall,
            ),
            _buildContactIconButton(
              AppIcons.chatActive,
              onPressed: _onTapChat,
            ),
            Expanded(child: _buildContactWhatsappButton()),
          ] else ...[
            _buildContactButton(
              'call',
              AppIcons.callFilled,
              onPressed: _onTapCall,
            ),
            _buildContactButton(
              'chat',
              AppIcons.chatActive,
              onPressed: _onTapChat,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactIconButton(
    String icon, {
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48.rh(context),
        width: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.tertiaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomImage(
          imageUrl: icon,
          height: 24.rh(context),
          fit: BoxFit.contain,
          color: context.color.tertiaryColor,
        ),
      ),
    );
  }

  Widget _buildContactWhatsappButton() {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      buttonTitle: 'whatsapp'.translate(context),
      height: 48.rh(context),
      onPressed: _onTapWhatsapp,
      prefixWidget: CustomImage(
        imageUrl: AppIcons.whatsapp,
        height: 24.rh(context),
        fit: BoxFit.contain,
        color: context.color.buttonColor,
      ),
    );
  }

  Widget _buildContactButton(
    String title,
    String icon, {
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: UiUtils.buildButton(
        context,
        fontSize: context.font.md,
        buttonTitle: title.translate(context),
        padding: const EdgeInsets.all(2),
        height: 48.rh(context),
        onPressed: onPressed,
        prefixWidget: Container(
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: CustomImage(
            imageUrl: icon,
            width: 18.rw(context),
            height: 18.rh(context),
            color: context.color.buttonColor,
          ),
        ),
      ),
    );
  }

  Future<void> _onTapCall() async {
    final contactNumber = _projectPhoneNumber;

    if (contactNumber == null || contactNumber.isEmpty) return;

    final cleanPhone = contactNumber.replaceAll(RegExp('[^0-9]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _onTapWhatsapp() async {
    final mobile = _projectPhoneNumber;
    final countryCode = _project.agentProfile?.agentCountryCode ?? '';
    if (mobile == null || mobile.isEmpty) return;
    await WhatsappHelper.open(mobile, countryCode);
  }

  Future<void> _onTapChat() async {
    await openChatScreen(
      context,
      chatScreen: ChatScreenNew(
        profilePicture:
            _project.customer?.profile ??
            _project.agentProfile?.agentProfilePhoto ??
            '',
        userName:
            _project.agentProfile?.agentName ?? _project.customer?.name ?? '',
        propertyImage: _project.image ?? '',
        proeprtyTitle: _project.translatedTitle ?? _project.title ?? '',
        userId: _project.addedBy.toString(),
        from: 'project',
        propertyId: _project.id.toString(),
        isBlockedByMe: false,
        isBlockedByUser: false,
        isAgent: _project.isAgent ?? false,
        isAgentVerified: _project.isAgentVerified ?? false,
        isUserVerified: _project.isUserVerified ?? false,
        isAdmin: _project.isAdmin ?? false,
        phoneNumber: _projectPhoneNumber,
        propertySlugId: _project.slugId,
        receiverRoleContext: _project.isAdmin == true
            ? 'admin'
            : ((_project.isAgent ?? false) ? 'agent' : 'user'),
        isAppointmentAvailable: _project.isAppointmentAvailable ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final imageHeight = screenHeight * 0.32;

    // final locationParts = [
    //   _project.city,
    //   _project.state,
    //   _project.country,
    // ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
    // final locationText = locationParts.isNotEmpty
    //     ? locationParts
    //     : (_project.location ?? '');

    return MultiBlocListener(
      listeners: [
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
              unawaited(_myProjectsCubit.fetchMyProjects());
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
        BlocListener<DeleteProjectCubit, DeleteProjectState>(
          listener: (context, state) async {
            if (state is DeleteProjectSuccess) {
              if (!mounted) return;
              HelperUtils.showSnackBarMessage(
                context,
                'projectDeleteSuccessfully',
                type: .success,
              );
              context.read<FetchMyProjectsCubit>().delete(
                state.id,
              );
              await _onBackPress();
            }
          },
        ),
        BlocListener<CreateAdvertisementCubit, CreateAdvertisementState>(
          listener: (context, state) async {
            if (state is! CreateAdvertisementSuccess) return;
            final id = _project.id;
            if (id == null || !mounted) return;
            try {
              final result = await ProjectRepository()
                  .fetchProjectFromProjectId(id);
              if (!mounted) return;
              if (result.modelList.isNotEmpty) {
                final updated = result.modelList.first;
                setState(() {
                  _project = updated;
                  _isEnabled.value = updated.status.toString() == '1';
                });
              }
            } on Exception catch (_) {}
            unawaited(_myProjectsCubit.fetchMyProjects());
          },
        ),
      ],
      child: ExpandableDetailsCard(
        key: _cardKey,
        onClose: _onBackPress,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        bottomNavigationBar: _isLoading
            ? null
            : _buildBottomNavigationContent(),
        appBarTitle: CustomText(
          _project.translatedTitle ??
              _project.title ??
              'projectDetails'.translate(context),
          color: context.color.textColorDark,
          fontWeight: FontWeight.bold,
          fontSize: context.font.lg,
          maxLines: 1,
        ),
        appBarActions: _appBarActions(),
        slivers: [
          SliverAppBar(
            expandedHeight: imageHeight,
            automaticallyImplyLeading: false,
            backgroundColor: context.color.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildProjectImage(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      padding: const EdgeInsets.all(
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            spacing: 4,
                            children: [
                              CustomImage(
                                height: 20,
                                imageUrl: _project.category?.image ?? '',
                                color: context.color.textColorDark,
                              ),

                              Expanded(
                                child: CustomText(
                                  _project.category?.translatedName ??
                                      _project.category?.category ??
                                      '',
                                ),
                              ),

                              if (_project.type != null &&
                                  _project.type!.isNotEmpty)
                                _buildBadge(
                                  _project.type!.translate(
                                    context,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                            _project.translatedTitle ?? _project.title ?? '',
                            color: context.color.textColorDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      child: CustomShimmer(
                        width: double.infinity,
                        height: 250.rh(context),
                        borderRadius: 8,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isMyProject) ...[
                          _buildEnableDisableSwitch(),
                          SizedBox(
                            height: detailsPageSizedBoxHeight.rh(context),
                          ),
                        ],

                        _buildProjectDescription(),
                        SizedBox(
                          height: detailsPageSizedBoxHeight.rh(context),
                        ),
                        _buildAddressSection(),
                        SizedBox(
                          height: detailsPageSizedBoxHeight.rh(context),
                        ),
                        if (_project.addedBy.toString() !=
                            HiveUtils.getUserId()) ...[
                          buildAgentProfileAndGallery(),
                          SizedBox(
                            height: detailsPageSizedBoxHeight.rh(context),
                          ),
                        ],
                        _buildDocumentsSection(),
                        SizedBox(
                          height: detailsPageSizedBoxHeight.rh(context),
                        ),
                        _buildFloorPlansSection(),
                        SizedBox(
                          height: _isExpanded ? 120 : 60,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBarActions() {
    if (_isMyProject) {
      return PopupMenuButton<String>(
        color: context.color.secondaryColor,
        position: PopupMenuPosition.under,
        padding: .zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: context.color.borderColor),
          borderRadius: .circular(12.rw(context)),
        ),
        menuPadding: .symmetric(
          horizontal: 12.rw(context),
          vertical: 8.rh(context),
        ),
        onSelected: (value) async {
          if (value == 'share') {
            await HelperUtils.shareProject(
              context,
              _project.slugId ?? '',
            );
          }
          if (value == 'renewListing') {
            await _handleRenewProject();
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  SizedBox(
                    height: 20.rh(context),
                    width: 20.rw(context),
                    child: CustomImage(
                      imageUrl: AppIcons.shareIcon,
                      fit: .contain,
                      color: context.color.textColorDark,
                    ),
                  ),
                  SizedBox(width: 8.rw(context)),
                  CustomText('share'.translate(context)),
                ],
              ),
            ),
            if (_project.isExpired ?? false)
              PopupMenuItem<String>(
                value: 'renewListing',
                child: Row(
                  children: [
                    SizedBox(
                      height: 20.rh(context),
                      width: 20.rw(context),
                      child: CustomImage(
                        imageUrl: AppIcons.changeStatus,
                        fit: .contain,
                        color: context.color.textColorDark,
                      ),
                    ),
                    SizedBox(width: 8.rw(context)),
                    CustomText('renewListing'.translate(context)),
                  ],
                ),
              ),
          ];
        },
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: 16),
          alignment: Alignment.center,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 24.rh(context),
            color: context.color.textColorDark,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () async {
          await HelperUtils.shareProject(
            context,
            _project.slugId ?? '',
          );
        },
        child: Container(
          margin: EdgeInsetsDirectional.only(end: 16.rw(context)),
          alignment: Alignment.center,
          child: CustomImage(
            imageUrl: AppIcons.shareIcon,
            height: 24.rh(context),
            color: context.color.textColorDark,
          ),
        ),
      );
    }
  }

  Future<void> _scheduleAppointment() async {
    await GuestChecker.check(
      onNotGuest: () async {
        final agentData = CustomerData(
          id: int.tryParse(_project.addedBy ?? '0') ?? 0,
          slugId: _project.slugId ?? '',
          name: _project.customer?.name ?? '',
          profile: _project.customer?.profile ?? '',
          mobile: _project.customer?.mobile ?? '',
          email: _project.customer?.email ?? '',
          address: '',
          city: _project.city ?? '',
          country: _project.country ?? '',
          state: _project.state ?? '',
          agentProfile: _project.agentProfile ?? AgentProfileModel(),
          projectCount: _project.customer?.totalProjects ?? '',
          propertyCount: _project.customer?.totalProperties ?? '',
          propertiesSoldCount: '',
          propertiesRentedCount: '',
          isAppointmentAvailable: _project.isAppointmentAvailable ?? false,
          isAgentVerified: _project.isAgentVerified ?? false,
          isAdmin: _project.isAdmin ?? false,
        );

        await Navigator.pushNamed(
          context,
          Routes.appointmentFlow,
          arguments: {
            'isAdmin': _project.isAdmin ?? false,
            'agentDetails': agentData,
          },
        );
      },
    );
  }

  Widget buildAgentProfileAndGallery() {
    final isAddedByMe = _project.addedBy.toString() == HiveUtils.getUserId();

    if (isAddedByMe) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 142.rh(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14.rw(context),
        vertical: 12.rh(context),
      ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8.rw(context)),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: AgentProfileWidget(
        addedBy: _project.addedBy ?? '',
        name: _project.customer?.name ?? '',
        email: _project.customer?.email ?? '',
        profileImage: _project.customer?.profile ?? '',
        isUserVerified: _project.isUserVerified ?? false,
        isAgentVerified: _project.isAgentVerified ?? false,
        isAgent: _project.isAgent ?? false,
        propertiesCount: _project.customer?.totalProperties ?? '',
        projectsCount: _project.customer?.totalProjects ?? '',
        followersCount:
            (_project.agentProfile?.totalFollowers?.isNotEmpty ?? false)
            ? _project.agentProfile!.totalFollowers!
            : (_project.customer?.totalFollowers?.isNotEmpty ?? false)
            ? _project.customer!.totalFollowers!
            : '',
        isFollowing: _project.customer?.isFollowing ?? false,
        canScheduleAppointment:
            (_project.isAppointmentAvailable ?? false) &&
            (_project.roleContext == 'agent' ||
                _project.isAgent == true ||
                _project.isAdmin == true),
        onScheduleAppointment: _scheduleAppointment,
        isAdmin: _project.isAdmin ?? false,
        agentProfile: _project.agentProfile,
        roleContext: _project.roleContext,
        popOnTap: widget.fromAgentDetails,
      ),
    );
  }

  void _openFullGallery({int initialIndex = 0}) {
    final effectiveGallery =
        _project.gallaryImages ?? const <ProjectGalleryModel>[];
    final hasTitleInGallery = effectiveGallery.any(
      (g) => g.imageUrl == _project.image,
    );

    final allImages = <dynamic>[
      if (_project.image != null &&
          _project.image!.trim().isNotEmpty &&
          !hasTitleInGallery)
        ProjectGalleryModel(
          id: -1,
          imageUrl: _project.image!,
          type: 'image',
          isVideo: false,
        ),
      ...effectiveGallery,
    ];

    if (allImages.isEmpty) return;

    unawaited(
      UiUtils.imageGallaryView(
        context,
        images: allImages,
        initalIndex: initialIndex,
      ),
    );
  }

  Widget _buildProjectImage() {
    final videoUrl = _project.videoLink?.trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    final effectiveGallery =
        _project.gallaryImages ?? const <ProjectGalleryModel>[];
    final hasTitleInGallery = effectiveGallery.any(
      (g) => g.imageUrl == _project.image,
    );
    final totalGalleryCount =
        (_project.image != null &&
                _project.image!.trim().isNotEmpty &&
                !hasTitleInGallery
            ? 1
            : 0) +
        effectiveGallery.length;

    // Combine title image and gallery images (excluding videos)
    final imageUrls = <String>[
      if (_project.image != null && _project.image!.isNotEmpty) _project.image!,
      ...?_project.gallaryImages
          ?.where((element) => !element.isVideo)
          .map((e) => e.imageUrl),
    ];

    // Build carousel items: cover image first, then video (if exists),
    // then remaining images.
    final carouselItems = <Widget>[
      ...imageUrls.asMap().entries.map((entry) {
        Widget image = CustomImage(
          imageUrl: entry.value,
          width: double.infinity,
          height: double.infinity,
        );
        // Wrap the first image in a Hero for shared-element transition
        if (entry.key == 0 && widget.heroTag != null) {
          image = Hero(tag: widget.heroTag!, child: image);
        }
        return GestureDetector(
          onTap: () => _openFullGallery(initialIndex: _currentImageIndex),
          child: image,
        );
      }),
    ];

    // Insert video after the first image (cover image)
    if (hasVideo) {
      final videoWidget = _buildVideoThumbnailItem(videoUrl);
      if (carouselItems.isNotEmpty) {
        carouselItems.insert(1, videoWidget);
      } else {
        carouselItems.add(videoWidget);
      }
    }

    final totalItems = carouselItems.length;

    return SizedBox.expand(
      child: Stack(
        children: [
          if (totalItems > 1)
            Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    viewportFraction: 1,
                    height: double.infinity,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                  items: carouselItems,
                ),
                PositionedDirectional(
                  bottom: 16.rh(context),
                  start: 16.rw(context),
                  child: ScrollingDotsIndicator(
                    count: totalItems,
                    currentIndex: _currentImageIndex,
                    dotSize: 7,
                  ),
                ),
              ],
            )
          else if (totalItems == 1)
            carouselItems.first
          else
            GestureDetector(
              onTap: _openFullGallery,
              child: Container(
                alignment: Alignment.center,
                child: CustomImage(
                  imageUrl: _project.image ?? '',
                  width: double.infinity,
                  height: double.infinity,
                  loadingImageHash: _project.lowQualityImage,
                ),
              ),
            ),
          if (totalGalleryCount > 1)
            PositionedDirectional(
              bottom: 12.rh(context),
              end: 16.rw(context),
              child: GestureDetector(
                onTap: () => _openFullGallery(initialIndex: _currentImageIndex),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.rw(context),
                    vertical: 4.rh(context),
                  ),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.color.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: context.color.textColorDark,
                        size: 14.rs(context),
                      ),
                      SizedBox(width: 4.rw(context)),
                      CustomText(
                        '$totalGalleryCount',
                        color: context.color.textColorDark,
                        fontSize: context.font.xs,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.project.isPromoted ?? false)
            PositionedDirectional(
              bottom: 16.rh(context),
              start: 16.rw(context),
              child: widget.heroTag != null
                  ? Hero(
                      tag: '${widget.heroTag}-promoted',
                      child: const PromotedCard(),
                    )
                  : const PromotedCard(),
            ),
          if (widget.project.isPremium ?? false)
            PositionedDirectional(
              top: 16.rh(context),
              start: 10.rw(context),
              child: Container(
                alignment: Alignment.center,
                width: 24.rw(context),
                height: 24.rh(context),
                child: widget.heroTag != null
                    ? Hero(
                        tag: '${widget.heroTag}-premium',
                        child: CustomImage(
                          imageUrl: AppIcons.premium,
                        ),
                      )
                    : CustomImage(
                        imageUrl: AppIcons.premium,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds an inline video player widget for the carousel
  Widget _buildVideoThumbnailItem(String videoUrl) {
    return CustomVideoPlayer(
      videoUrl: videoUrl,
      autoPlay: true,
    );
  }
}
