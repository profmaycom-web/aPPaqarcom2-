import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/ai/generate_ai_content_cubit.dart';
import 'package:ebroker/data/cubits/property/create_property_cubit.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step1_categories_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step2_property_details_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step3_images_video_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step4_facilities_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step5_outdoor_facilities_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step6_location_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/steps/step7_seo_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_propery_screens/property_success.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({
    super.key,
    this.initialProperty,
    this.initialData,
    this.isEdit = false,
  });

  final PropertyModel? initialProperty;
  final Map<String, dynamic>? initialData;
  final bool isEdit;

  static Route<dynamic> route(RouteSettings settings) {
    PropertyModel? property;
    Map<String, dynamic>? details;
    var isEdit = false;

    final args = settings.arguments;
    if (args is PropertyModel) {
      property = args;
      isEdit = true;
    } else if (args is Map<String, dynamic>) {
      property = args['property'] as PropertyModel?;
      details =
          (args['details'] ?? args['propertyDetails'] ?? args['data'])
              as Map<String, dynamic>?;
      isEdit = args['isEdit'] as bool? ?? (property != null || details != null);
    }

    if (!isEdit && property == null && details == null) {
      Constant.addProperty.clear();
    }

    return CupertinoPageRoute<dynamic>(
      builder: (context) {
        return AddPropertyScreen(
          initialProperty: property,
          initialData: details,
          isEdit: isEdit,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PropertyWizardCubit>(
          create: (context) {
            final cubit = PropertyWizardCubit();
            if (initialProperty != null) {
              cubit.initFromProperty(initialProperty!);
              if (initialData != null) {
                cubit.initFromMap(initialData!);
              }
            } else if (initialData != null) {
              cubit.initFromMap(initialData!);
            } else if (Constant.addProperty['category'] != null &&
                Constant.addProperty['category'] is Category) {
              cubit.data.selectedCategory =
                  Constant.addProperty['category'] as Category;
            }

            if ((cubit.data.selectedCategory?.parameterTypes == null ||
                    cubit.data.selectedCategory!.parameterTypes!.isEmpty) &&
                Constant.addProperty['category'] != null &&
                Constant.addProperty['category'] is Category) {
              final constCat = Constant.addProperty['category'] as Category;
              if (cubit.data.selectedCategory == null) {
                cubit.data.selectedCategory = constCat;
              } else {
                cubit.data.selectedCategory!.parameterTypes =
                    constCat.parameterTypes;
              }
            }
            return cubit;
          },
        ),
        BlocProvider<CreatePropertyCubit>(
          create: (_) => CreatePropertyCubit(),
        ),
        BlocProvider<GenerateAiContentCubit>(
          create: (_) => GenerateAiContentCubit(),
        ),
      ],
      child: _AddPropertyContent(
        initialProperty: initialProperty,
        isEdit: isEdit,
      ),
    );
  }
}

class _AddPropertyContent extends StatefulWidget {
  const _AddPropertyContent({
    this.initialProperty,
    this.isEdit = false,
  });

  final PropertyModel? initialProperty;
  final bool isEdit;

  @override
  State<_AddPropertyContent> createState() => _AddPropertyContentState();
}

class _AddPropertyContentState extends State<_AddPropertyContent> {
  int _currentStep = 0; // 0 = Stepper Hub / Overview, 1..7 = Steps
  bool _isSubmitting = false;
  bool _isSavingDraft = false;

  void _goToStep(int step) {
    if (step < 0) {
      Navigator.maybePop(context);
      return;
    }
    if (step > 7) return;
    setState(() => _currentStep = step);
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      _goToStep(0);
    } else {
      Navigator.maybePop(context);
    }
  }

  /// A draft already saved on the server must go through update_post_property
  /// instead of post_property, otherwise a duplicate property is created.
  bool _isExistingDraft(PropertyWizardCubit cubit) {
    final data = cubit.data;
    return data.propertyId != null &&
        (data.isDraftProperty || data.requestStatus.toLowerCase() == 'draft');
  }

  Future<void> _handleSaveDraft() async {
    final cubit = context.read<PropertyWizardCubit>();
    final data = cubit.data;

    if (data.selectedCategory == null) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectCategory'.translate(context),
        type: MessageType.error,
      );
      _goToStep(1);
      return;
    }

    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    final primaryTitle = data.titles[defaultCode] ?? '';
    if (primaryTitle.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillMainTitle'.translate(context),
        type: MessageType.error,
      );
      _goToStep(2);
      return;
    }

    setState(() => _isSavingDraft = true);
    final params = cubit.buildParameters(isDraft: true);
    await context.read<CreatePropertyCubit>().create(
      parameters: params,
      isUpdate: _isExistingDraft(cubit),
    );
  }

  Future<void> _handleSubmit() async {
    final cubit = context.read<PropertyWizardCubit>();
    final data = cubit.data;

    if (data.selectedCategory == null) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectCategory'.translate(context),
        type: MessageType.error,
      );
      _goToStep(1);
      return;
    }

    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    final primaryTitle = data.titles[defaultCode] ?? '';
    if (primaryTitle.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillMainTitle'.translate(context),
        type: MessageType.error,
      );
      _goToStep(2);
      return;
    }

    if (data.price.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseEnterValidPrice'.translate(context),
        type: MessageType.error,
      );
      _goToStep(2);
      return;
    }

    if (data.countryId == null && data.selectedCountryName.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectCountry'.translate(context),
        type: MessageType.error,
      );
      _goToStep(2);
      return;
    }

    if (data.titleImage == null && data.titleImageUrl.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'uploadImgMsgLbl'.translate(context),
        type: MessageType.error,
      );
      _goToStep(3);
      return;
    }

    if (data.city.trim().isEmpty ||
        data.latitude.trim().isEmpty ||
        data.longitude.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectLocation'.translate(context),
        type: MessageType.error,
      );
      _goToStep(6);
      return;
    }

    setState(() => _isSubmitting = true);
    final params = cubit.buildParameters();
    await context.read<CreatePropertyCubit>().create(
      parameters: params,
      isUpdate: _isExistingDraft(cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreatePropertyCubit, CreatePropertyState>(
      listener: (context, state) {
        if (state is CreatePropertyInProgress) {
          // Handled by local flags
        } else {
          setState(() {
            _isSubmitting = false;
            _isSavingDraft = false;
          });
        }

        if (state is CreatePropertyFailure) {
          HelperUtils.showSnackBarMessage(
            context,
            state.errorMessage,
            type: MessageType.error,
          );
        }

        if (state is CreatePropertySuccess) {
          final isDraft =
              state.propertyModel?.requestStatus?.toLowerCase() == 'draft';
          if (_isSavingDraft || isDraft) {
            HelperUtils.showSnackBarMessage(
              context,
              'propertyAddedAsDraft'.translate(context),
              type: MessageType.success,
            );
            unawaited(HelperUtils.loadMyProperties(context));
            Navigator.pop(context);
          } else if (widget.isEdit) {
            HelperUtils.showSnackBarMessage(
              context,
              'propertyUpdated'.translate(context),
              type: MessageType.success,
            );
            unawaited(HelperUtils.loadMyProperties(context));
            Navigator.pop(context);
          } else {
            if (state.propertyModel != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (context) =>
                      PropertyAddSuccess(model: state.propertyModel!),
                ),
              );
            } else {
              HelperUtils.showSnackBarMessage(
                context,
                'propertyAdded'.translate(context),
                type: MessageType.success,
              );
              Navigator.pop(context);
            }
          }
        }
      },
      child: PopScope(
        canPop: _currentStep == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _onBackPressed();
        },
        child: _buildCurrentStepView(),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    final cubit = context.watch<PropertyWizardCubit>();
    final isDraft =
        cubit.data.isDraftProperty ||
        cubit.data.requestStatus.toLowerCase() == 'draft';
    final isEdit = cubit.data.isEdit;
    final saveDraftCallback = (isEdit && !isDraft) ? null : _handleSaveDraft;

    switch (_currentStep) {
      case 0:
        return _buildStep0Overview();
      case 1:
        return Step1CategoriesScreen(
          onNext: () => _goToStep(2),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 2:
        return Step2PropertyDetailsScreen(
          onNext: () => _goToStep(3),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 3:
        return Step3ImagesVideoScreen(
          onNext: () => _goToStep(4),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 4:
        return Step4FacilitiesScreen(
          onNext: () => _goToStep(5),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 5:
        return Step5OutdoorFacilitiesScreen(
          onNext: () => _goToStep(6),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 6:
        return Step6LocationScreen(
          onNext: () => _goToStep(7),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 7:
        return Step7SeoScreen(
          onSubmit: _handleSubmit,
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSubmitting: _isSubmitting,
          isSavingDraft: _isSavingDraft,
        );
      default:
        return _buildStep0Overview();
    }
  }

  // ==========================================
  // SCREEN 1: Step 0 - Stepper Hub / Overview
  // ==========================================
  Widget _buildStep0Overview() {
    final cubit = context.watch<PropertyWizardCubit>();

    final stepsData = [
      {
        'num': 1,
        'title': 'selectCategory'.translate(context),
        'sub': 'typeOfProperty'.translate(context),
      },
      {
        'num': 2,
        'title': 'propertyDetails'.translate(context),
        'sub': 'price'.translate(context),
      },
      {
        'num': 3,
        'title': 'uploadPictures'.translate(context),
        'sub': 'videoPreview'.translate(context),
      },
      {
        'num': 4,
        'title': 'facilities'.translate(context),
        'sub': 'facilities'.translate(context),
      },
      {
        'num': 5,
        'title': 'outdoorFacilities'.translate(context),
        'sub': 'chooseNearbyPlaces'.translate(context),
      },
      {
        'num': 6,
        'title': 'location'.translate(context),
        'sub': 'addressLbl'.translate(context),
      },
      {
        'num': 7,
        'title': 'seoSettings'.translate(context),
        'sub': 'metaKeywords'.translate(context),
      },
    ];

    // Find the first uncompleted step (Active Step)
    var activeStep = 1;
    for (var i = 1; i <= 7; i++) {
      if (!cubit.isStepCompleted(i)) {
        activeStep = i;
        break;
      }
    }

    final primaryTextColor = context.color.textColorDark;
    final secondaryTextColor = context.color.textLightColor;
    final uncompletedBorderColor = context.color.borderColor;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: const CustomAppBar(
        isTransparent: true,
        showShadow: false,
        title: '',
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48.rh(context),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.color.tertiaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                for (var i = 1; i <= 7; i++) {
                  if (!cubit.isStepCompleted(i)) {
                    _goToStep(i);
                    return;
                  }
                }
                _goToStep(1);
              },
              child: CustomText(
                widget.isEdit
                    ? 'resume'.translate(context)
                    : 'getStarted'.translate(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.color.buttonColor,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: Constant.scrollPhysics,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                widget.isEdit
                    ? 'updateProperty'.translate(context)
                    : 'addProperty'.translate(context),
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: primaryTextColor,
              ),
              const SizedBox(height: 8),
              CustomText(
                'completeEachStepToPublishListing'.translate(context),
                fontSize: 14,
                color: secondaryTextColor,
              ),
              const SizedBox(height: 24),
              ...stepsData.map((step) {
                final stepNum = step['num']! as int;
                final isCompleted = cubit.isStepCompleted(stepNum);
                final isActive = !isCompleted && stepNum == activeStep;

                return GestureDetector(
                  onTap: () => _goToStep(stepNum),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Circle Indicator (46x46)
                        Container(
                          width: 46.rw(context),
                          height: 46.rw(context),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? context.color.tertiaryColor
                                : isActive
                                ? context.color.tertiaryColor.withValues(
                                    alpha: 0.12,
                                  )
                                : Colors.transparent,
                            border: (!isCompleted && !isActive)
                                ? Border.all(
                                    color: uncompletedBorderColor,
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 22,
                                    color: context.color.buttonColor,
                                  )
                                : CustomText(
                                    '$stepNum',
                                    fontSize: 17,
                                    fontWeight: isActive
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: primaryTextColor,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        // Title & Subtitle column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                step['title']?.toString() ?? '',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 0.15,
                                color: primaryTextColor,
                              ),
                              const SizedBox(height: 3),
                              CustomText(
                                step['sub']?.toString() ?? '',
                                fontSize: 13.5,
                                color: secondaryTextColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
