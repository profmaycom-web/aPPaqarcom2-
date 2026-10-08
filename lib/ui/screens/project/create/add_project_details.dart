import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/translation_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/generate_with_ai_button.dart';
import 'package:ebroker/ui/screens/widgets/video_selector.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class AddProjectDetails extends StatefulWidget {
  const AddProjectDetails({super.key, this.editData});

  final Map<dynamic, dynamic>? editData;

  static CupertinoPageRoute<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => ManageProjectCubit(),
          child: AddProjectDetails(
            editData: settings.arguments as Map?,
          ),
        );
      },
    );
  }

  @override
  CloudState<AddProjectDetails> createState() => _AddProjectDetailsState();
}

class _AddProjectDetailsState extends CloudState<AddProjectDetails>
    with TickerProviderStateMixin {
  late bool isEdit = widget.editData != null;
  String slug = '';
  String metaTitle = '';
  String metaDescription = '';
  String metaKeywords = '';
  String metaImageUrl = '';
  ImagePickerValue<dynamic>? metaImage;

  late ProjectModel? project = widget.editData?['project'] as ProjectModel?;

  // Multi-language support variables
  late TabController _tabController;
  List<Translations> translatedFields = [];
  final translationMap = <String, dynamic>{};
  List<LanguagesModel> languages = AppSettings.languages;

  late final List<TextEditingController> _titleControllers;
  late final List<TextEditingController> _descriptionControllers;
  late final TextEditingController _slugController = TextEditingController(
    text: project?.slugId ?? '',
  );
  late final TextEditingController _youtubeVideoLinkController =
      TextEditingController();
  late final TextEditingController _vimeoVideoLinkController =
      TextEditingController();
  String selectedLocation = '';
  PlaceModel? suggestion;
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isGeneratingDescription = false;
  int? _generatingDescriptionIndex;

  /// VIDEO TYPE: 0=custom, 1=youtube, 2=vimeo
  int selectedVideoType = 1;
  File? _selectedVideoFile;

  List<Document<dynamic>> documentFiles = [];
  List<int> removedDocumentId = [];
  List<int> removedGalleryImageId = [];

  late final TextEditingController _cityNameController = TextEditingController(
    text: project?.city,
  );

  late final TextEditingController _stateNameController = TextEditingController(
    text: project?.state,
  );

  late final TextEditingController _countryNameController =
      TextEditingController(text: project?.country);

  late final TextEditingController _addressController = TextEditingController(
    text: project?.location,
  );

  // final TextEditingController _main=TextEditingController();
  double? latitude;
  double? longitude;
  Map<dynamic, dynamic>? floorPlans = {};
  List<Map<dynamic, dynamic>> floorPlansRawData = [];
  ImagePickerValue<dynamic>? titleImage;
  ImagePickerValue<dynamic>? galleryImages;
  String projectType = 'upcoming';
  List<int> removedPlansId = [];
  bool isPrivateProperty = false;
  bool _removeVideo = false;

  /// Remote URL of an already-uploaded custom video (edit mode, video_type == 0).
  String _existingCustomVideoUrl = '';

  String generateSlug(String input) {
    return input
        .replaceAll(' ', '-')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w-]'), '');
  }

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for languages
    _tabController = TabController(length: languages.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.editData?['translations'] != null &&
        widget.editData?['translations'] is List) {
      final wid = widget.editData?['translations'] as List<Translations>? ?? [];
      translatedFields = wid;
    }

    // Initialize title controllers for each language
    _titleControllers = List.generate(languages.length, (index) {
      final langId = languages[index].id;
      final titleTranslation = translatedFields.firstWhere(
        (element) => element.languageId == langId && element.key == 'title',
        orElse: Translations.new,
      );
      return TextEditingController(
        text:
            (titleTranslation.value == null || titleTranslation.value!.isEmpty)
            ? (index == 0 ? (project?.title ?? '') : '')
            : titleTranslation.value!,
      );
    });

    // Initialize description controllers for each language
    _descriptionControllers = List.generate(languages.length, (index) {
      final langId = languages[index].id;
      final descTranslation = translatedFields.firstWhere(
        (element) =>
            element.languageId == langId && element.key == 'description',
        orElse: Translations.new,
      );
      return TextEditingController(
        text: (descTranslation.value == null || descTranslation.value!.isEmpty)
            ? (index == 0 ? (project?.description ?? '') : '')
            : descTranslation.value!,
      );
    });

    //add documents in edit mode
    _titleControllers.first.addListener(() {
      setState(() {
        if (project?.slugId != null && project?.slugId != '') {
          _slugController.text = project?.slugId ?? '';
        }
        _slugController.text = generateSlug(_titleControllers.first.text);
      });
    });
    metaTitle = widget.editData?['meta_title']?.toString() ?? '';
    metaDescription = widget.editData?['meta_description']?.toString() ?? '';
    metaKeywords = widget.editData?['meta_keywords']?.toString() ?? '';
    metaImageUrl = widget.editData?['meta_image']?.toString() ?? '';
    final list = project?.documents?.map((document) {
      return UrlDocument(document.name!, document.id!);
    }).toList();

    if (list != null) {
      documentFiles = List<Document<dynamic>>.from(list as List<Document>);
    }
    projectType = project?.type ?? 'upcoming';

    if (widget.editData != null) {
      isPrivateProperty = widget.editData?['is_premium'] as bool? ?? false;
    }

    // Restore video type from edit data
    if (project != null) {
      final videoType = widget.editData?['video_type'];
      if (videoType != null) {
        selectedVideoType = int.tryParse(videoType.toString()) ?? 1;
      }

      // Restore video link to the appropriate controller
      final videoLink = project?.videoLink ?? '';
      if (selectedVideoType == 1) {
        _youtubeVideoLinkController.text = videoLink;
      } else if (selectedVideoType == 2) {
        _vimeoVideoLinkController.text = videoLink;
      } else if (selectedVideoType == 0) {
        _existingCustomVideoUrl = videoLink;
      }
    }

    if (project != null && project?.image != '') {
      titleImage = UrlValue(project!.image!);
    }

    if (project != null && project!.gallaryImages!.isNotEmpty) {
      galleryImages = MultiValue(
        project!.gallaryImages!
            .map(
              (e) => UrlValue(e.imageUrl, {
                'id': e.id,
              }),
            )
            .toList(),
      );
    }

    ///add plans in edit mode
    project?.plans?.forEach((plan) {
      floorPlansRawData.add({
        'title': plan.title,
        'id': plan.id,
        'image': plan.document,
      });
    });

    setState(() {});
  }

  Map<String, dynamic> projectDetails = {};
  Map<String, dynamic> toTranslationMap(List<Translations> translatedFields) {
    translationMap.clear();

    for (var i = 0; i < languages.length; i++) {
      final langId = languages[i].id;

      final titleField = translatedFields.firstWhere(
        (t) => t.languageId == langId && t.key == 'title',
        orElse: Translations.new,
      );

      final descField = translatedFields.firstWhere(
        (t) => t.languageId == langId && t.key == 'description',
        orElse: Translations.new,
      );

      final titleValue = titleField.value?.trim() ?? '';
      final descValue = descField.value?.trim() ?? '';

      if (titleValue.isNotEmpty) {
        translationMap.addAll({
          'translations[$i][title][translation_id]': titleField.id ?? '',
          'translations[$i][title][language_id]': langId,
          'translations[$i][title][value]': titleValue,
        });
      }

      if (descValue.isNotEmpty) {
        translationMap.addAll({
          'translations[$i][description][translation_id]': descField.id ?? '',
          'translations[$i][description][language_id]': langId,
          'translations[$i][description][value]': descValue,
        });
      }
    }

    return translationMap;
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _titleControllers) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers) {
      controller.dispose();
    }
    _youtubeVideoLinkController.dispose();
    _vimeoVideoLinkController.dispose();
    super.dispose();
  }

  Future<void> _generateProjectDescription({required int index}) async {
    // Validate title is not empty
    if (_titleControllers[index].text.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillMainTitle',
        type: .error,
      );
      return;
    }

    final languageId = (languages[index].id is int)
        ? languages[index].id! as int
        : int.tryParse(languages[index].id.toString()) ?? 0;

    await context.read<GenerateAiContentCubit>().generateDescription(
      entityType: EntityType.project,
      languageId: languageId,
      entityId: project?.id?.toString(),
      context: <String, dynamic>{
        'title': _titleControllers[index].text,
        'location': _addressController.text,
        'city': _cityNameController.text,
        'state': _stateNameController.text,
        'country': _countryNameController.text,
        'category_id': projectDetails['category_id'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GenerateAiContentCubit, GenerateAiContentState>(
      listener: (context, state) {
        if (state is GenerateDescriptionSuccess) {
          if (state.languageId != null) {
            final index = languages.indexWhere(
              (lang) =>
                  (lang.id is int
                      ? lang.id! as int
                      : int.tryParse(lang.id.toString()) ?? 0) ==
                  state.languageId,
            );
            if (index >= 0 && index < _descriptionControllers.length) {
              _descriptionControllers[index].text =
                  state.description.description;
            }
          }
          _isGeneratingDescription = false;
          _generatingDescriptionIndex = null;
          setState(() {});
        } else if (state is GenerateDescriptionFailure) {
          _isGeneratingDescription = false;
          _generatingDescriptionIndex = null;
          HelperUtils.showSnackBarMessage(
            context,
            state.error,
            type: .error,
          );
          setState(() {});
        } else if (state is GenerateDescriptionInProgress) {
          final index = languages.indexWhere(
            (lang) =>
                (lang.id is int
                    ? lang.id! as int
                    : int.tryParse(lang.id.toString()) ?? 0) ==
                state.languageId,
          );
          _isGeneratingDescription = true;
          _generatingDescriptionIndex = index >= 0 ? index : null;
          setState(() {});
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.pop(context);
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: context.color.backgroundColor,
            appBar: CustomAppBar(
              title: 'projectDetails'.translate(context),
            ),
            bottomNavigationBar: UiUtils.buildButton(
              context,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_titleControllers.first.text.trim().isEmpty ||
                      _descriptionControllers.first.text.trim().isEmpty) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      'pleaseFillMainTitleAndDescription',
                      type: .error,
                    );
                    return;
                  }

                  // Update translation fields
                  for (var i = 0; i < languages.length; i++) {
                    final langId = languages[i].id;

                    final titleIndex = translatedFields.indexWhere(
                      (t) => t.languageId == langId && t.key == 'title',
                    );

                    if (titleIndex != -1) {
                      translatedFields[titleIndex].value = _titleControllers[i]
                          .text
                          .trim();
                    } else {
                      translatedFields.add(
                        Translations(
                          languageId: langId,
                          key: 'title',
                          value: _titleControllers[i].text.trim(),
                        ),
                      );
                    }

                    final descIndex = translatedFields.indexWhere(
                      (t) => t.languageId == langId && t.key == 'description',
                    );

                    if (descIndex != -1) {
                      translatedFields[descIndex].value =
                          _descriptionControllers[i].text.trim();
                    } else {
                      translatedFields.add(
                        Translations(
                          languageId: langId,
                          key: 'description',
                          value: _descriptionControllers[i].text.trim(),
                        ),
                      );
                    }
                  }

                  toTranslationMap(translatedFields);

                  Map<dynamic, dynamic> documents;
                  documents = {};
                  try {
                    documents = documentFiles.fold({}, (pr, el) {
                      if (el is FileDocument) {
                        pr.addAll({
                          'documents[${pr.length}]': MultipartFile.fromFileSync(
                            el.value.path,
                          ),
                        });
                      }
                      return pr;
                    });
                  } on Exception catch (_) {}

                  projectDetails = {
                    'title': _titleControllers.first.text.trim(),
                    'slug_id': _slugController.text,
                    'description': _descriptionControllers.first.text.trim(),
                    'latitude': latitude,
                    'longitude': longitude,
                    'city': _cityNameController.text,
                    'state': _stateNameController.text,
                    'country': _countryNameController.text,
                    'location': _addressController.text,
                    if (AppSettings.showDirectVideoUpload) ...{
                      if ((selectedVideoType == 0 &&
                              (_selectedVideoFile != null ||
                                  _existingCustomVideoUrl.isNotEmpty)) &&
                          _selectedVideoFile != null) ...{
                        'video_type': selectedVideoType,
                        'custom_video': await MultipartFile.fromFile(
                          _selectedVideoFile!.path,
                        ),
                      },
                      if (selectedVideoType == 1 &&
                          _youtubeVideoLinkController.text.isNotEmpty) ...{
                        'video_type': selectedVideoType,
                        'video_link': _youtubeVideoLinkController.text,
                      },
                      if (selectedVideoType == 2 &&
                          _vimeoVideoLinkController.text.isNotEmpty) ...{
                        'video_type': selectedVideoType,
                        'video_link': _vimeoVideoLinkController.text,
                      },
                    } else ...{
                      if (selectedVideoType == 1 &&
                          _youtubeVideoLinkController.text.isNotEmpty) ...{
                        'video_type': selectedVideoType,
                        'video_link': _youtubeVideoLinkController.text,
                      },
                      if (selectedVideoType == 2 &&
                          _vimeoVideoLinkController.text.isNotEmpty) ...{
                        'video_type': selectedVideoType,
                        'video_link': _vimeoVideoLinkController.text,
                      },
                    },
                    if (titleImage != null &&
                        titleImage is! UrlValue &&
                        titleImage?.value != '')
                      'image': titleImage,
                    'gallery_images': galleryImages,
                    ...documents.cast<String, dynamic>(),
                    'is_edit': isEdit,
                    'project': project,
                    'type': projectType,
                    'remove_gallery_images': removedGalleryImageId.join(','),
                    'remove_documents': removedDocumentId.join(','),
                    'remove_plans': removedPlansId.join(','),
                    'meta_title': metaTitle,
                    'meta_description': metaDescription,
                    'meta_keywords': metaKeywords,
                    'meta_image': metaImage,
                    'meta_image_url': metaImageUrl,
                    if (_removeVideo &&
                        _youtubeVideoLinkController.text.isEmpty &&
                        _vimeoVideoLinkController.text.isEmpty &&
                        _selectedVideoFile == null)
                      'remove_video': 1,
                    ...translationMap,

                    ////If there is data it will add into it
                    for (final entry
                        in (widget.editData?.cast<String, dynamic>() ?? {})
                            .entries)
                      if (!const {
                        'video_type',
                        'video_link',
                        'custom_video',
                      }.contains(entry.key))
                        entry.key: entry.value,
                    if (AppSettings.showPremiumToggle)
                      'is_premium': isPrivateProperty ? 1 : 0,
                  };
                  addCloudData(
                    'add_project_details',
                    projectDetails,
                  );
                  //this will create Map from List<Map>

                  floorPlansRawData.removeWhere(
                    (element) =>
                        element['image'] is String ||
                        element['image'] is UrlValue,
                  );

                  final fold = <String, dynamic>{};
                  for (var i = 0; i < floorPlansRawData.length; i++) {
                    final element = floorPlansRawData[i];
                    fold.addAll({
                      'plans[$i][id]': (element['id'] is ValueKey)
                          ? (element['id'] as ValueKey).value
                          : element['id'] ?? '',
                      'plans[$i][document]': element['image'],
                      'plans[$i][title]': element['title'],
                    });
                  }

                  addCloudData('floor_plans', fold);
                  await Navigator.pushNamed(
                    context,
                    Routes.projectMetaDataScreens,
                    arguments: {
                      'isEdit': isEdit,
                    },
                  );
                }
              },
              height: 48.rh(context),
              outerPadding: const EdgeInsets.all(16),
              buttonTitle: 'continue'.translate(context),
            ),
            body: SingleChildScrollView(
              physics: Constant.scrollPhysics,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      buildLanguageSelector(context, _tabController, languages),
                      SizedBox(height: 8.rh(context)),
                      buildTitleAndDescriptionFields(
                        index: _tabController.index,
                        requiredSymbol: HelperUtils.requiredSymbol(context),
                      ),
                      if (_tabController.index == 0) ...[
                        SizedBox(height: 8.rh(context)),
                        CustomText('slugIdLbl'.translate(context)),
                        SizedBox(height: 8.rh(context)),
                        CustomTextFormField(
                          controller: _slugController,
                          validator: CustomTextFieldValidator.slugId,
                          action: .next,
                          hintText: 'slugIdOptional'.translate(context),
                        ),
                        SizedBox(height: 8.rh(context)),
                        projectTypeField(context),
                        SizedBox(height: 8.rh(context)),
                        if (AppSettings.showPremiumToggle) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  'isPrivateProperty'.translate(context),
                                ),
                              ),
                              UiSwitch(
                                value: isPrivateProperty,
                                onChanged: (value) {
                                  isPrivateProperty = value;
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8.rh(context)),
                        ],
                        buildLocationChooseHeader(),
                        SizedBox(height: 8.rh(context)),
                        buildProjectLocationTextFields(),
                        SizedBox(height: 8.rh(context)),
                        CustomText(
                          '',
                          isRichText: true,
                          textSpan: TextSpan(
                            style: TextStyle(
                              color: context.color.textColorDark,
                            ),
                            children: [
                              TextSpan(
                                text: 'uploadMainPicture'.translate(context),
                              ),
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.rh(context)),
                        AdaptiveImagePickerWidget(
                          isRequired: true,
                          multiImage: false,
                          allowedSizeBytes: 3000000,
                          value: titleImage,
                          title: 'addMainPicture'.translate(context),
                          onSelect: (selected) {
                            if (selected is FileValue || selected is UrlValue) {
                              titleImage = selected;
                              setState(() {});
                            } else if (selected == null) {
                              titleImage = null;
                              setState(() {});
                            }
                          },
                        ),
                        SizedBox(height: 8.rh(context)),
                        CustomText('uploadOtherImages'.translate(context)),
                        SizedBox(height: 8.rh(context)),
                        AdaptiveImagePickerWidget(
                          title: 'addOtherPicture'.translate(context),
                          onRemove: (value) {
                            dynamic realValue = value;
                            if (realValue is IdentifyValue) {
                              realValue = realValue.value;
                            }
                            if (realValue is UrlValue &&
                                realValue.metaData != null) {
                              removedGalleryImageId.add(
                                realValue.metaData['id'] as int,
                              );
                            }
                          },
                          multiImage: true,
                          value: galleryImages,
                          onSelect: (selected) {
                            if (selected is MultiValue) {
                              galleryImages = selected;
                              setState(() {});
                            }
                          },
                        ),
                        SizedBox(height: 8.rh(context)),

                        VideoSelector(
                          selectedVideoType: selectedVideoType,
                          onValueChanged: (value) {
                            selectedVideoType = value;
                            setState(() {});
                          },
                          youtubeController: _youtubeVideoLinkController,
                          vimeoController: _vimeoVideoLinkController,
                          selectedVideoFile: _selectedVideoFile,
                          existingCustomVideoUrl: _existingCustomVideoUrl,
                          onFileSelected: (file) {
                            // New file replaces the existing remote video
                            _selectedVideoFile = file;
                            if (file != null) _existingCustomVideoUrl = '';
                            setState(() {});
                          },
                          onRemoveVideo: () {
                            _removeVideo = true;
                            _existingCustomVideoUrl = '';
                            setState(() {});
                          },
                        ),
                        SizedBox(height: 8.rh(context)),

                        SizedBox(height: 8.rh(context)),
                        CustomText('projectDocuments'.translate(context)),
                        SizedBox(height: 8.rh(context)),
                        buildDocumentPicker(context),
                        ...documentList(),
                        SizedBox(height: 8.rh(context)),
                        Row(
                          children: [
                            Column(
                              children: [
                                CustomText(
                                  'floorPlans'.translate(context),
                                ),
                                CustomText(
                                  '${floorPlansRawData.length}',
                                  fontWeight: .bold,
                                ),
                              ],
                            ),
                            const Spacer(),
                            MaterialButton(
                              elevation: 0,
                              color: context.color.tertiaryColor.withValues(
                                alpha: 0.1,
                              ),
                              onPressed: () async {
                                final data =
                                    await Navigator.pushNamed(
                                          context,
                                          Routes.manageFloorPlansScreen,
                                          arguments: {
                                            'floorPlan': floorPlansRawData,
                                          },
                                        )
                                        as Map?;
                                if (data != null) {
                                  floorPlansRawData =
                                      (data['floorPlans'] as List? ?? [])
                                          .map(
                                            (e) => Map<dynamic, dynamic>.from(
                                              e as Map,
                                            ),
                                          )
                                          .toList();

                                  final newRemoved = List<int>.from(
                                    data['removed'] as List? ?? [],
                                  );
                                  for (final id in newRemoved) {
                                    if (!removedPlansId.contains(id)) {
                                      removedPlansId.add(id);
                                    }
                                  }
                                }
                                setState(() {});
                              },
                              child: CustomText('manage'.translate(context)),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.rh(context)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget projectTypeField(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          'projectStatus'.translate(context),
          color: context.color.textColorDark,
        ),
        SizedBox(height: 8.rh(context)),
        DropdownMenu(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(
              context.color.secondaryColor,
            ),
            visualDensity: VisualDensity.comfortable,
          ),
          textStyle: TextStyle(
            color: context.color.textColorDark,
          ),
          width: MediaQuery.of(context).size.width * 0.9,
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(
              color: context.color.textColorDark.withValues(alpha: 0.7),
              fontSize: context.font.md,
            ),
            filled: true,
            fillColor: context.color.secondaryColor,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: context.color.tertiaryColor,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          initialSelection: 'upcoming',
          onSelected: (value) {
            projectType = value!;
            setState(() {});
          },
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: 'upcoming',
              label: 'upcoming'.translate(context),
            ),
            DropdownMenuEntry(
              value: 'under_construction',
              label: 'under_construction'.translate(context),
            ),
          ],
        ),
      ],
    );
  }

  Column buildProjectLocationTextFields() {
    return Column(
      children: [
        CustomTextFormField(
          action: .next,
          controller: _cityNameController,
          isReadOnly: false,
          validator: CustomTextFieldValidator.nullCheck,
          hintText: 'city'.translate(context),
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          action: .next,
          controller: _stateNameController,
          isReadOnly: false,
          validator: CustomTextFieldValidator.nullCheck,
          hintText: 'state'.translate(context),
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          action: .next,
          controller: _countryNameController,
          isReadOnly: false,
          validator: CustomTextFieldValidator.nullCheck,
          hintText: 'country'.translate(context),
          onChange: (val) {
            _cityNameController.clear();
            _stateNameController.clear();
            _addressController.clear();
            latitude = null;
            longitude = null;
          },
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          action: .next,
          controller: _addressController,
          hintText: 'addressLbl'.translate(context),
          maxLine: 12,
          validator: CustomTextFieldValidator.nullCheck,
          minLine: 4,
        ),
      ],
    );
  }

  SizedBox buildLocationChooseHeader() {
    return SizedBox(
      height: 35.rh(context),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          CustomText(
            '',
            isRichText: true,
            textSpan: TextSpan(
              style: TextStyle(
                color: context.color.textColorDark,
              ),
              children: [
                TextSpan(
                  text: 'projectLocation'.translate(context),
                  style: TextStyle(
                    color: context.color.textColorDark,
                  ),
                ),
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          // const Spacer(),
          ChooseLocationFormField(
            initialValue: project != null || _isLocationChosen(),
            validator: (value) {
              if (project != null || _isLocationChosen()) return null;

              if (value ?? false) {
                return null;
              } else {
                return 'pleaseSelectLocation'.translate(context);
              }
            },
            build: (state) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError ? Colors.red : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: GestureDetector(
                  onTap: () async {
                    await _onTapChooseLocation.call(state);
                  },
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      CustomImage(
                        imageUrl: AppIcons.location,
                        color: context.color.textLightColor,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      CustomText(
                        'chooseLocation'.translate(context),
                        fontSize: context.font.sm,
                        color: context.color.tertiaryColor,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      const CustomText(
                        ' *',
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isLocationChosen() {
    return _cityNameController.text.isNotEmpty &&
        _stateNameController.text.isNotEmpty &&
        _countryNameController.text.isNotEmpty &&
        latitude != null &&
        longitude != null;
  }

  Future<void> _onTapChooseLocation(FormFieldState<dynamic> state) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();

      final countries = context.read<FetchCountriesCubit>().countries;
      CountryModel? matchedCountry;
      try {
        matchedCountry = countries.firstWhere(
          (c) =>
              c.name?.toLowerCase() ==
              _countryNameController.text.trim().toLowerCase(),
        );
      } on Exception catch (_) {
        if (countries.isNotEmpty) {
          matchedCountry = countries.first;
        }
      }

      final placeMark =
          await Navigator.pushNamed(
                context,
                Routes.chooseLocaitonMap,
                arguments: {
                  if (matchedCountry?.id != null)
                    'country_id': matchedCountry!.id.toString(),
                  'country_name': _countryNameController.text.trim().isNotEmpty
                      ? _countryNameController.text.trim()
                      : matchedCountry?.name ?? '',
                  'from': 'addProject',
                },
              )
              as Map?;
      final latlng = placeMark?['latlng'] as LatLng?;
      final place = placeMark?['place'] as Placemark?;

      if (latlng != null && place != null) {
        latitude = latlng.latitude;
        longitude = latlng.longitude;

        _cityNameController.text =
            place.locality ?? placeMark?['city']?.toString() ?? '';
        _countryNameController.text =
            place.country ?? placeMark?['country']?.toString() ?? '';
        _stateNameController.text =
            place.administrativeArea ?? placeMark?['state']?.toString() ?? '';
        final addressResult = placeMark?['address']?.toString();
        if (addressResult != null && addressResult.trim().isNotEmpty) {
          _addressController.text = addressResult.trim();
        } else if (place.street != null && place.street!.trim().isNotEmpty) {
          _addressController.text = place.street!.trim();
        } else {
          _addressController.text = [
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((s) => s != null && s.trim().isNotEmpty).join(', ');
        }

        state.didChange(true);
      } else {
        // state.didChange(false);
      }
    } on Exception catch (_) {}
  }

  List<Widget> documentList() {
    return documentFiles.map((document) {
      var fileName = '';
      if (document is FileDocument) {
        fileName = document.value.path.split('/').last;
      } else {
        fileName = document.value.toString().split('/').last;
      }

      return Material(
        type: MaterialType.transparency,
        child: ListTile(
          title: CustomText(
            fileName,
            maxLines: 2,
          ),
          dense: true,
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (document is UrlDocument) {
                removedDocumentId.add(document.id);
              }
              documentFiles.remove(document);
              setState(() {});
            },
          ),
        ),
      );
    }).toList();
  }

  Widget buildDocumentPicker(BuildContext context) {
    return Row(
      children: [
        DottedBorder(
          options: RectDottedBorderOptions(
            color: context.color.textLightColor,
          ),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: IconButton(
                onPressed: () async {
                  final files = await AppFilePicker.pickFiles(
                    allowedExtensions: ['pdf', 'doc', 'docx'],
                  );
                  if (files != null) {
                    final list = List<Document<dynamic>>.from(
                      files.map((e) {
                        return FileDocument(File(e.path!));
                      }).toList(),
                    );
                    documentFiles.addAll(list);
                  }

                  setState(() {});
                },
                icon: Icon(
                  Icons.upload,
                  color: context.color.textLightColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.rw(context)),
        Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .spaceBetween,
          children: [
            CustomText('UploadDocs'.translate(context)),
            SizedBox(height: 4.rh(context)),
            CustomText(documentFiles.length.toString()),
          ],
        ),
      ],
    );
  }

  Widget buildLanguageSelector(
    BuildContext context,
    TabController tabController,
    List<LanguagesModel> languages,
  ) {
    return Center(
      child: CustomTabBar(
        onTap: (value) => setState(() {
          FocusScope.of(context).unfocus();
        }),
        tabController: tabController,
        isScrollable: !(languages.length <= 2),
        tabs: languages
            .map(
              (lang) => SizedBox(
                width: 85.rw(context),
                child: Tab(
                  text: lang.name ?? '',
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget buildTitleAndDescriptionFields({
    required int index,
    required Widget requiredSymbol,
  }) {
    return Column(
      children: [
        Row(
          children: [
            CustomText(
              '${'projectName'.translate(context)} (${languages[index].name})',
            ),
            SizedBox(width: 3.rw(context)),
            if (index == 0) requiredSymbol,
          ],
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        CustomTextFormField(
          controller: _titleControllers[index],
          validator: index == 0 ? CustomTextFieldValidator.nullCheck : null,
          action: .next,
          hintText: 'projectName'.translate(context),
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  CustomText(
                    '${'descriptionLbl'.translate(context)} (${languages[index].name})',
                  ),
                  SizedBox(width: 3.rw(context)),
                  if (index == 0) requiredSymbol,
                ],
              ),
            ),
            if (_titleControllers[index].text.isNotEmpty)
              GenerateWithAiButton(
                onTap: () => _generateProjectDescription(index: index),
                isLoading:
                    _isGeneratingDescription &&
                    _generatingDescriptionIndex == index,
              ),
          ],
        ),
        SizedBox(
          height: 8.rh(context),
        ),
        if (_isGeneratingDescription && _generatingDescriptionIndex == index)
          Shimmer.fromColors(
            period: const Duration(milliseconds: 1000),
            baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
            highlightColor: Theme.of(
              context,
            ).colorScheme.shimmerHighlightColor,
            child: CustomTextFormField(
              action: .next,
              controller: _descriptionControllers[index],
              validator: index == 0 ? CustomTextFieldValidator.nullCheck : null,
              hintText: 'generating'.translate(context),
              maxLine: 12,
              minLine: 6,
            ),
          )
        else
          CustomTextFormField(
            action: .next,
            keyboard: .text,
            controller: _descriptionControllers[index],
            validator: index == 0 ? CustomTextFieldValidator.nullCheck : null,
            hintText: 'writeSomething'.translate(context),
            maxLine: 12,
            minLine: 6,
          ),
      ],
    );
  }
}

abstract class Document<T> {
  abstract final T value;
}

class FileDocument extends Document<dynamic> {
  FileDocument(this.value);

  @override
  final File value;
}

class UrlDocument extends Document<dynamic> {
  UrlDocument(this.value, this.id);

  @override
  final String value;
  final int id;
}
