import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/category.dart' as c;
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/generate_with_ai_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class ProjectMetaDetails extends StatefulWidget {
  const ProjectMetaDetails({super.key, this.isEdit = false});

  final bool isEdit;
  static CupertinoPageRoute<dynamic> route(RouteSettings settings) {
    final args = settings.arguments as Map? ?? {};
    return CupertinoPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => ManageProjectCubit(),
          child: ProjectMetaDetails(isEdit: args['isEdit'] as bool? ?? false),
        );
      },
    );
  }

  @override
  CloudState<ProjectMetaDetails> createState() => _ProjectMetaDetailsState();
}

class _ProjectMetaDetailsState extends CloudState<ProjectMetaDetails> {
  late Map<String, dynamic> projectDetails = Map<String, dynamic>.from(
    getCloudData('add_project_details') as Map? ?? {},
  );
  late ProjectModel? project = projectDetails['project'] is Map
      ? ProjectModel.fromMap(projectDetails['project'] as Map<String, dynamic>)
      : projectDetails['project'] as ProjectModel? ?? ProjectModel();
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final TextEditingController _metaTitleController = TextEditingController(
    text: project?.metaTitle ?? projectDetails['meta_title']?.toString(),
  );
  late final TextEditingController _metaDescriptionController =
      TextEditingController(
        text:
            project?.metaDescription ??
            projectDetails['meta_description']?.toString(),
      );
  late final TextEditingController
  _metaKeywordsController = TextEditingController(
    text: project?.metaKeywords ?? projectDetails['meta_keywords']?.toString(),
  );
  late String metaImageUrl =
      project?.metaImage ?? projectDetails['meta_image_url']?.toString() ?? '';

  late ImagePickerValue<dynamic>? metaImage =
      (projectDetails['meta_image'] is File)
      ? IdentifyValue(projectDetails['meta_image'] as File).value
            as ImagePickerValue?
      : (projectDetails['meta_image'] is ImagePickerValue)
      ? projectDetails['meta_image'] as ImagePickerValue?
      : (metaImageUrl != '')
      ? UrlValue(metaImageUrl)
      : null;

  bool _isGeneratingMeta = false;
  bool _isSavingDraft = false;
  bool _isSubmitting = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  String _resolveButtonTitle(BuildContext context) {
    return 'continue'.translate(context);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GenerateAiContentCubit, GenerateAiContentState>(
      listener: (context, state) {
        if (state is GenerateMetaSuccess) {
          _metaTitleController.text = state.meta.metaTitle;
          _metaDescriptionController.text = state.meta.metaDescription;
          _metaKeywordsController.text = state.meta.metaKeywords;
          _isGeneratingMeta = false;
          setState(() {});
        } else if (state is GenerateMetaFailure) {
          _isGeneratingMeta = false;
          HelperUtils.showSnackBarMessage(
            context,
            state.error,
            type: .error,
          );
          setState(() {});
        } else if (state is GenerateMetaInProgress) {
          _isGeneratingMeta = true;
          setState(() {});
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          appBar: CustomAppBar(
            title: 'addProjectMeta'.translate(context),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!widget.isEdit) ...[
                  Expanded(
                    child: UiUtils.buildButton(
                      context,
                      height: 48.rh(context),
                      buttonColor: context.color.textColorDark,
                      textColor: context.color.buttonColor,
                      isInProgress:
                          context.watch<ManageProjectCubit>().state
                              is ManageProjectInProgress &&
                          _isSavingDraft,
                      disabled:
                          context.watch<ManageProjectCubit>().state
                              is ManageProjectInProgress &&
                          _isSubmitting,
                      onPressed: () async {
                        final cubitState = context
                            .read<ManageProjectCubit>()
                            .state;
                        if (cubitState is ManageProjectInProgress) {
                          return;
                        }

                        final data = <String, dynamic>{};
                        final metaDetails = <String, dynamic>{
                          'meta_title': _metaTitleController.text,
                          'meta_description': _metaDescriptionController.text,
                          'meta_keywords': _metaKeywordsController.text,
                        };
                        final metaImageData =
                            metaImage?.value != metaImageUrl &&
                                metaImage?.value != '' &&
                                metaImage != null
                            ? <String, dynamic>{
                                'meta_image': metaImage,
                              }
                            : null;
                        data
                          ..addAll(projectDetails)
                          ..addAll(metaDetails)
                          ..addAll(metaImageData ?? {})
                          ..addAll(
                            Map<String, dynamic>.from(
                              getCloudData('floor_plans') as Map? ?? {},
                            ),
                          );

                        if (!projectDetails.containsKey('category_id')) {
                          data.addAll({
                            'category_id':
                                (Constant.addProperty['category'] as c.Category)
                                    .id,
                          });
                        }

                        data.remove('project');
                        data['is_draft'] = true;

                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSavingDraft = true;
                            _isSubmitting = false;
                          });
                          await context.read<ManageProjectCubit>().manage(
                            type: ManageProjectType.create,
                            data: data,
                          );
                        }
                      },
                      buttonTitle: 'saveDraft'.translate(context),
                    ),
                  ),
                  SizedBox(width: 8.rw(context)),
                ],
                Expanded(
                  child: BlocBuilder<CheckPackageCubit, CheckPackageState>(
                    bloc: _checkPackageCubit,
                    builder: (context, checkPackageState) {
                      return UiUtils.buildButton(
                        context,
                        height: 48.rh(context),
                        isInProgress:
                            (context.watch<ManageProjectCubit>().state
                                    is ManageProjectInProgress &&
                                _isSubmitting) ||
                            checkPackageState is CheckPackageInProgress,
                        disabled:
                            context.watch<ManageProjectCubit>().state
                                is ManageProjectInProgress &&
                            _isSavingDraft,
                        onPressed: () async {
                          if (_checkPackageCubit.state
                              is CheckPackageInProgress) {
                            return;
                          }

                          final isPackageAvailable = await _checkPackageCubit
                              .checkAvailability(
                                packageType: PackageType.projectList,
                              );

                          if (_checkPackageCubit.state is CheckPackageFail) {
                            if (context.mounted) {
                              HelperUtils.showSnackBarMessage(
                                context,
                                (_checkPackageCubit.state as CheckPackageFail)
                                    .error,
                                type: .error,
                              );
                            }
                            return;
                          }

                          if (!isPackageAvailable) {
                            await UiUtils.showBlurredDialoge(
                              context,
                              dialog: const BlurredSubscriptionDialogBox(
                                packageType:
                                    SubscriptionPackageType.projectList,
                                isAcceptContainesPush: true,
                              ),
                            );
                            return;
                          }

                          final cubitState = context
                              .read<ManageProjectCubit>()
                              .state;
                          if (cubitState is ManageProjectInProgress) {
                            return;
                          }

                          final data = <String, dynamic>{};
                          final metaDetails = <String, dynamic>{
                            'meta_title': _metaTitleController.text,
                            'meta_description': _metaDescriptionController.text,
                            'meta_keywords': _metaKeywordsController.text,
                          };
                          final metaImageData =
                              metaImage?.value != metaImageUrl &&
                                  metaImage?.value != '' &&
                                  metaImage != null
                              ? <String, dynamic>{
                                  'meta_image': metaImage,
                                }
                              : null;
                          data
                            ..addAll(projectDetails)
                            ..addAll(metaDetails)
                            ..addAll(metaImageData ?? {})
                            ..addAll(
                              Map<String, dynamic>.from(
                                getCloudData('floor_plans') as Map? ?? {},
                              ),
                            );

                          if (!projectDetails.containsKey('category_id')) {
                            data.addAll({
                              'category_id':
                                  (Constant.addProperty['category']
                                          as c.Category)
                                      .id,
                            });
                          }

                          data
                            ..remove('project')
                            ..remove('is_draft');
                          if (widget.isEdit) {
                            data['action_type'] = '0';
                          } else {
                            data['action_type'] = '1';
                          }
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isSavingDraft = false;
                              _isSubmitting = true;
                            });
                            await context.read<ManageProjectCubit>().manage(
                              type: widget.isEdit
                                  ? ManageProjectType.update
                                  : ManageProjectType.create,
                              data: data,
                            );
                          }
                        },
                        buttonTitle: _resolveButtonTitle(context),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          body: BlocListener<ManageProjectCubit, ManageProjectState>(
            listener: (context, state) async {
              if (state is ManageProjectInSuccess ||
                  state is ManageProjectInFail) {
                setState(() {
                  _isSavingDraft = false;
                  _isSubmitting = false;
                });
              }
              if (state is ManageProjectInSuccess) {
                final isDraft =
                    state.project.requestStatus?.toLowerCase() == 'draft';
                HelperUtils.showSnackBarMessage(
                  context,
                  widget.isEdit
                      ? 'projectUpdatedSuccessfully'
                      : isDraft
                      ? 'projectAddedAsDraft'
                      : 'projectAddedSuccessfully',
                  type: .success,
                );
                Navigator.popUntil(context, (route) => route.isFirst);
                if (!widget.isEdit) {
                  CloudState.cloudData['add_project_details'] = null;
                }
                context.read<FetchMyProjectsCubit>().update(state.project);
              }
              if (state is ManageProjectInFail) {
                HelperUtils.showSnackBarMessage(
                  context,
                  state.error,
                  type: .error,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText('metaDetails'.translate(context)),
                        ),
                        if (_metaTitleController.text.isNotEmpty)
                          GenerateWithAiButton(
                            onTap: _generateProjectMeta,
                            isLoading: _isGeneratingMeta,
                          ),
                      ],
                    ),
                    height(),
                    if (_isGeneratingMeta)
                      Shimmer.fromColors(
                        period: const Duration(milliseconds: 1000),
                        baseColor: Theme.of(
                          context,
                        ).colorScheme.shimmerBaseColor,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.shimmerHighlightColor,
                        child: CustomTextFormField(
                          controller: _metaTitleController,
                          hintText: 'generating'.translate(context),
                        ),
                      )
                    else
                      CustomTextFormField(
                        controller: _metaTitleController,
                        hintText: 'metaTitle'.translate(context),
                      ),
                    height(8),
                    if (_isGeneratingMeta)
                      Shimmer.fromColors(
                        period: const Duration(milliseconds: 1000),
                        baseColor: Theme.of(
                          context,
                        ).colorScheme.shimmerBaseColor,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.shimmerHighlightColor,
                        child: CustomTextFormField(
                          controller: _metaKeywordsController,
                          hintText: 'generating'.translate(context),
                        ),
                      )
                    else
                      CustomTextFormField(
                        controller: _metaKeywordsController,
                        hintText: 'metaKeywords'.translate(context),
                      ),
                    height(8),
                    if (_isGeneratingMeta)
                      Shimmer.fromColors(
                        period: const Duration(milliseconds: 1000),
                        baseColor: Theme.of(
                          context,
                        ).colorScheme.shimmerBaseColor,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.shimmerHighlightColor,
                        child: CustomTextFormField(
                          controller: _metaDescriptionController,
                          hintText: 'generating'.translate(context),
                          minLine: 5,
                          maxLine: 12,
                        ),
                      )
                    else
                      CustomTextFormField(
                        controller: _metaDescriptionController,
                        hintText: 'metaDescription'.translate(context),
                        minLine: 5,
                        maxLine: 12,
                      ),
                    height(8),
                    AdaptiveImagePickerWidget(
                      isRequired: false,
                      title: 'addMetaImage'.translate(context),
                      multiImage: false,
                      value: project?.metaImage != null ? metaImage : null,
                      onSelect: (selected) {
                        if (selected is FileValue || selected == null) {
                          metaImage = selected;
                          setState(() {});
                        }
                      },
                      onRemove: (value) {
                        if (value is UrlValue) {
                          metaImage = UrlValue('');
                        }
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget height([double? h]) {
    return SizedBox(
      height: h?.rh(context) ?? 15.rh(context),
    );
  }

  Future<void> _generateProjectMeta() async {
    // Validate title is not empty
    final title = projectDetails['title']?.toString() ?? '';
    if (title.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillMetaTitle',
        type: .error,
      );
      return;
    }

    await context.read<GenerateAiContentCubit>().generateMeta(
      entityType: EntityType.project,
      entityId: project?.id?.toString(),
      context: <String, dynamic>{
        'title': title,
        'location': projectDetails['location'],
        'city': projectDetails['city'],
        'state': projectDetails['state'],
        'country': projectDetails['country'],
        'category_id': projectDetails['category_id'],
      },
    );
  }
}
