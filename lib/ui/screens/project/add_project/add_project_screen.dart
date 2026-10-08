import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/ai/generate_ai_content_cubit.dart';
import 'package:ebroker/data/cubits/project/fetch_my_projects_cubit.dart';
import 'package:ebroker/data/cubits/project/manage_project_cubit.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/steps/step1_categories_screen.dart';
import 'package:ebroker/ui/screens/project/add_project/steps/step2_project_details_screen.dart';
import 'package:ebroker/ui/screens/project/add_project/steps/step3_images_video_screen.dart';
import 'package:ebroker/ui/screens/project/add_project/steps/step4_location_screen.dart';
import 'package:ebroker/ui/screens/project/add_project/steps/step5_floor_details_screen.dart';
import 'package:ebroker/ui/screens/project/add_project/steps/step6_seo_screen.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class AddProjectScreen extends StatelessWidget {
  const AddProjectScreen({
    super.key,
    this.initialProject,
    this.initialData,
    this.isEdit = false,
  });

  final ProjectModel? initialProject;
  final Map<String, dynamic>? initialData;
  final bool isEdit;

  static Route<dynamic> route(RouteSettings settings) {
    ProjectModel? project;
    Map<String, dynamic>? details;
    var isEdit = false;

    final args = settings.arguments;
    if (args is ProjectModel) {
      project = args;
      isEdit = true;
    } else if (args is Map<String, dynamic>) {
      project = args['project'] as ProjectModel?;
      details =
          (args['details'] ?? args['projectDetails'] ?? args['data'])
              as Map<String, dynamic>? ??
          args;
      isEdit =
          args['isEdit'] as bool? ??
          (project != null || args['is_edit'] == true);
    } else if (args is Map) {
      details = Map<String, dynamic>.from(args);
      project = details['project'] as ProjectModel?;
      isEdit =
          details['isEdit'] as bool? ??
          (project != null || details['is_edit'] == true);
    }

    if (!isEdit && project == null && details == null) {
      Constant.addProperty.clear();
    }

    return CupertinoPageRoute<dynamic>(
      builder: (context) {
        return AddProjectScreen(
          initialProject: project,
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
        BlocProvider<ProjectWizardCubit>(
          create: (context) {
            final cubit = ProjectWizardCubit();
            if (initialProject != null) {
              cubit.initFromProject(initialProject!);
            } else if (initialData != null) {
              cubit.initFromMap(initialData!);
            } else if (Constant.addProperty['category'] != null &&
                Constant.addProperty['category'] is Category) {
              cubit.data.selectedCategory =
                  Constant.addProperty['category'] as Category;
            }
            return cubit;
          },
        ),
        BlocProvider<ManageProjectCubit>(
          create: (_) => ManageProjectCubit(),
        ),
        BlocProvider<GenerateAiContentCubit>(
          create: (_) => GenerateAiContentCubit(),
        ),
      ],
      child: _AddProjectContent(
        initialProject: initialProject,
        isEdit: isEdit,
      ),
    );
  }
}

class _AddProjectContent extends StatefulWidget {
  const _AddProjectContent({
    this.initialProject,
    this.isEdit = false,
  });

  final ProjectModel? initialProject;
  final bool isEdit;

  @override
  State<_AddProjectContent> createState() => _AddProjectContentState();
}

class _AddProjectContentState extends State<_AddProjectContent> {
  int _currentStep = 0; // 0 = Stepper Hub / Overview, 1..6 = Steps
  bool _isSubmitting = false;
  bool _isSavingDraft = false;

  void _goToStep(int step) {
    if (step < 0) {
      Navigator.maybePop(context);
      return;
    }
    if (step > 6) return;
    setState(() => _currentStep = step);
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      _goToStep(0);
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _handleSaveDraft() async {
    final cubit = context.read<ProjectWizardCubit>();
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
    await context.read<ManageProjectCubit>().manage(
      type: data.isEdit ? ManageProjectType.update : ManageProjectType.create,
      data: params,
    );
  }

  Future<void> _handleSubmit() async {
    final cubit = context.read<ProjectWizardCubit>();
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

    if (data.countryId.trim().isEmpty &&
        (data.selectedCountry?.name ?? data.country).trim().isEmpty) {
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

    if (data.city.trim().isEmpty || data.address.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectLocation'.translate(context),
        type: MessageType.error,
      );
      _goToStep(4);
      return;
    }

    setState(() => _isSubmitting = true);
    final params = cubit.buildParameters();
    await context.read<ManageProjectCubit>().manage(
      type: data.isEdit ? ManageProjectType.update : ManageProjectType.create,
      data: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageProjectCubit, ManageProjectState>(
      listener: (context, state) {
        if (state is ManageProjectInFail) {
          setState(() {
            _isSubmitting = false;
            _isSavingDraft = false;
          });
          HelperUtils.showSnackBarMessage(
            context,
            state.error,
            type: MessageType.error,
          );
        }

        if (state is ManageProjectInSuccess) {
          final isDraft = state.project.requestStatus?.toLowerCase() == 'draft';
          final wasSavingDraft = _isSavingDraft;
          setState(() {
            _isSubmitting = false;
            _isSavingDraft = false;
          });
          context.read<FetchMyProjectsCubit>().update(state.project);
          if (wasSavingDraft || isDraft) {
            HelperUtils.showSnackBarMessage(
              context,
              'projectAddedAsDraft'.translate(context),
              type: MessageType.success,
            );
            Navigator.pop(context);
          } else {
            HelperUtils.showSnackBarMessage(
              context,
              widget.isEdit
                  ? 'projectUpdatedSuccessfully'.translate(context)
                  : 'projectAddedSuccessfully'.translate(context),
              type: MessageType.success,
            );
            Navigator.pop(context);
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
    final cubit = context.watch<ProjectWizardCubit>();
    final isDraft =
        cubit.data.isDraftProject ||
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
        return Step2ProjectDetailsScreen(
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
        return Step4LocationScreen(
          onNext: () => _goToStep(5),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 5:
        return Step5FloorDetailsScreen(
          onNext: () => _goToStep(6),
          onBack: _onBackPressed,
          onSaveDraft: saveDraftCallback,
          isSavingDraft: _isSavingDraft,
        );
      case 6:
        return Step6SeoScreen(
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
    final cubit = context.watch<ProjectWizardCubit>();

    final stepsData = [
      {
        'num': 1,
        'title': 'categories'.translate(context),
        'sub': 'categories'.translate(context),
      },
      {
        'num': 2,
        'title': 'projectDetails'.translate(context),
        'sub': 'descriptionLbl'.translate(context),
      },
      {
        'num': 3,
        'title': 'uploadOtherImages'.translate(context),
        'sub': 'videoPreview'.translate(context),
      },
      {
        'num': 4,
        'title': 'location'.translate(context),
        'sub': 'addressLbl'.translate(context),
      },
      {
        'num': 5,
        'title': 'floorPlans'.translate(context),
        'sub': 'floorPlans'.translate(context),
      },
      {
        'num': 6,
        'title': 'seoSettings'.translate(context),
        'sub': 'metaKeywords'.translate(context),
      },
    ];

    // Find the first uncompleted step (Active Step)
    var activeStep = 1;
    for (var i = 1; i <= 6; i++) {
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
                for (var i = 1; i <= 6; i++) {
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
                    ? 'updateProject'.translate(context)
                    : 'addProject'.translate(context),
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: primaryTextColor,
              ),
              SizedBox(height: 8.rh(context)),
              CustomText(
                'completeEachStepToPublishProject'.translate(context),
                fontSize: 14,
                color: secondaryTextColor,
              ),
              SizedBox(height: 24.rh(context)),
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
                                    width: 1.2.rw(context),
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
                        SizedBox(width: 18.rw(context)),
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
                              SizedBox(height: 3.rh(context)),
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
              SizedBox(height: 20.rh(context)),
            ],
          ),
        ),
      ),
    );
  }
}
