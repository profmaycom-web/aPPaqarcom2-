import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectFloorPlanItem {
  ProjectFloorPlanItem({
    this.id,
    this.title = '',
    this.imageFile,
    this.imageUrl = '',
  });

  int? id;
  String title;
  File? imageFile;
  String imageUrl;
}

class ProjectWizardData {
  // Edit mode metadata
  bool isEdit = false;
  int? projectId;
  ProjectModel? originalProject;
  String requestStatus = '';
  bool isDraftProject = false;

  // Step 1: Categories
  Category? selectedCategory;

  // Step 2: Project Details
  List<LanguagesModel> languages = [];
  int selectedLanguageIndex = 0;
  Map<String, String> titles = {}; // code -> title
  Map<String, String> descriptions = {}; // code -> description
  String slugId = '';
  bool isPromoted = false;
  String projectType = 'upcoming'; // 'upcoming' or 'under_construction'
  bool isPremium = false;

  // Step 3: Images & Video & Documents
  File? titleImage;
  String titleImageUrl = '';
  List<File> galleryImages = [];
  List<Map<String, dynamic>> galleryImageUrls = []; // [{'id': 1, 'image': url}]
  List<int> removedGalleryImageIds = [];
  int videoType = 1; // 0 = Custom, 1 = YouTube, 2 = Vimeo
  String videoUrl = '';
  File? customVideoFile;
  String customVideoUrl = '';
  bool removeVideo = false;
  List<PlatformFile> projectDocuments = [];
  List<Document> existingDocuments = [];
  List<int> removedDocumentIds = [];

  // Step 4: Location
  String city = '';
  String state = '';
  String country = '';
  String countryId = '';
  CountryModel? selectedCountry;
  String address = '';
  String clientAddress = '';
  String latitude = '';
  String longitude = '';

  // Step 5: Floor Details
  List<ProjectFloorPlanItem> floorPlans = [];
  List<int> removedPlanIds = [];

  // Step 6: SEO Settings
  String metaTitle = '';
  String metaDescription = '';
  List<String> keywords = [];
  File? ogImage;
  String ogImageUrl = '';
}

abstract class ProjectWizardState {}

class ProjectWizardInitial extends ProjectWizardState {}

class ProjectWizardUpdated extends ProjectWizardState {
  ProjectWizardUpdated(this.data);
  final ProjectWizardData data;
}

class ProjectWizardCubit extends Cubit<ProjectWizardState> {
  ProjectWizardCubit() : super(ProjectWizardInitial()) {
    _initDefaults();
  }

  final ProjectWizardData data = ProjectWizardData();

  void _initDefaults() {
    data.languages = List<LanguagesModel>.from(AppSettings.languages);
    if (data.languages.isEmpty) {
      data.languages = [
        LanguagesModel(id: '1', code: 'en', name: 'English'),
      ];
    }
    _applyHeaderCountryAsDefault();
  }

  /// Start a new project in the country selected in the header, so the
  /// listing country matches what the user is browsing.
  void _applyHeaderCountryAsDefault() {
    final headerCountryId = HiveUtils.getSelectedCountryId() ?? '';
    final headerCountryName = HiveUtils.getSelectedCountryName() ?? '';
    if (headerCountryName.toLowerCase() == 'all') return;
    if (headerCountryId.isEmpty && headerCountryName.isEmpty) return;

    data.countryId = headerCountryId;
    data.country = headerCountryName;
  }

  void initFromProject(ProjectModel proj) {
    data.isEdit = true;
    data.projectId = proj.id;
    data.originalProject = proj;
    data.requestStatus = proj.requestStatus ?? '';
    data.isDraftProject = (proj.requestStatus?.toLowerCase() == 'draft');

    // Step 1: Category
    if (proj.category != null) {
      data.selectedCategory = Category(
        id: proj.category?.id,
        category: proj.category?.category,
        image: proj.category?.image,
      );
    }

    // Step 2: Project Details
    data.slugId = proj.slugId ?? '';
    data.projectType = (proj.type?.isNotEmpty ?? false)
        ? proj.type!
        : 'upcoming';
    data.isPromoted = proj.isPromoted ?? false;
    data.isPremium = proj.isPremium ?? false;

    // Multi-language titles / descriptions
    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    data.titles[defaultCode] = proj.title ?? '';
    data.descriptions[defaultCode] = proj.description ?? '';

    if (proj.translations != null) {
      for (final t in proj.translations!) {
        for (final l in data.languages) {
          if (l.id == t.languageId || l.code == t.languageId) {
            if (l.code != null) {
              if (t.key == 'title') {
                data.titles[l.code!] = t.value ?? '';
              } else if (t.key == 'description') {
                data.descriptions[l.code!] = t.value ?? '';
              }
            }
          }
        }
      }
    }

    // Step 3: Images & Media & Documents
    data.titleImageUrl = proj.image ?? '';
    if (proj.gallaryImages != null) {
      for (final img in proj.gallaryImages!) {
        data.galleryImageUrls.add({
          'id': img.id,
          'image': img.imageUrl,
        });
      }
    }
    data.videoType = proj.videoType ?? 1;
    data.videoUrl = proj.videoLink ?? '';
    if (data.videoType == 0) {
      data.customVideoUrl = proj.videoLink ?? '';
    }
    if (proj.documents != null) {
      data.existingDocuments = List<Document>.from(proj.documents!);
    }

    // Step 4: Location
    data.city = proj.city ?? '';
    data.state = proj.state ?? '';
    data.country = proj.country ?? '';
    data.countryId = proj.countryId?.toString() ?? '';
    data.address = proj.location ?? '';
    data.latitude = proj.latitude ?? '';
    data.longitude = proj.longitude ?? '';

    // Step 5: Floor Plans
    if (proj.plans != null && proj.plans!.isNotEmpty) {
      for (final plan in proj.plans!) {
        data.floorPlans.add(
          ProjectFloorPlanItem(
            id: plan.id,
            title: plan.title ?? '',
            imageUrl: plan.document ?? '',
          ),
        );
      }
    }

    // Step 6: SEO
    data.metaTitle = proj.metaTitle ?? '';
    data.metaDescription = proj.metaDescription ?? '';
    if (proj.metaKeywords != null && proj.metaKeywords!.isNotEmpty) {
      data.keywords = proj.metaKeywords!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    data.ogImageUrl = proj.metaImage ?? '';

    emit(ProjectWizardUpdated(data));
  }

  void initFromMap(Map<String, dynamic> map) {
    if (map['project'] is ProjectModel) {
      initFromProject(map['project'] as ProjectModel);
      return;
    }

    data.isEdit = map['is_edit'] == true || map['isEdit'] == true;
    if (map['id'] != null) {
      data.projectId = int.tryParse(map['id'].toString());
    }

    if (map['category_id'] != null) {
      data.selectedCategory = Category(
        id: int.tryParse(map['category_id'].toString()),
        category: map['category_name']?.toString() ?? '',
      );
    }

    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    if (map['title'] != null) {
      data.titles[defaultCode] = map['title'].toString();
    }
    if (map['description'] != null) {
      data.descriptions[defaultCode] = map['description'].toString();
    }
    data.slugId = map['slug_id']?.toString() ?? '';
    data.projectType = map['type']?.toString() ?? 'upcoming';
    data.city = map['city']?.toString() ?? '';
    data.state = map['state']?.toString() ?? '';
    data.country = map['country']?.toString() ?? '';
    data.address = map['location']?.toString() ?? '';
    data.latitude = map['latitude']?.toString() ?? '';
    data.longitude = map['longitude']?.toString() ?? '';
    data.metaTitle = map['meta_title']?.toString() ?? '';
    data.metaDescription = map['meta_description']?.toString() ?? '';

    emit(ProjectWizardUpdated(data));
  }

  void reset() {
    final languages = data.languages;
    data
      ..isEdit = false
      ..projectId = null
      ..originalProject = null
      ..requestStatus = ''
      ..isDraftProject = false
      ..selectedCategory = null
      ..languages = languages
      ..selectedLanguageIndex = 0
      ..titles = {}
      ..descriptions = {}
      ..slugId = ''
      ..isPromoted = false
      ..projectType = 'upcoming'
      ..isPremium = false
      ..titleImage = null
      ..titleImageUrl = ''
      ..galleryImages = []
      ..galleryImageUrls = []
      ..removedGalleryImageIds = []
      ..videoType = 1
      ..videoUrl = ''
      ..customVideoFile = null
      ..customVideoUrl = ''
      ..removeVideo = false
      ..projectDocuments = []
      ..existingDocuments = []
      ..removedDocumentIds = []
      ..city = ''
      ..state = ''
      ..country = ''
      ..countryId = ''
      ..selectedCountry = null
      ..address = ''
      ..clientAddress = ''
      ..latitude = ''
      ..longitude = ''
      ..floorPlans = []
      ..removedPlanIds = []
      ..metaTitle = ''
      ..metaDescription = ''
      ..keywords = []
      ..ogImage = null
      ..ogImageUrl = '';

    _applyHeaderCountryAsDefault();
    emit(ProjectWizardUpdated(data));
  }

  void setCountry(CountryModel country) {
    final isCountryChanged = (data.countryId.isNotEmpty &&
            data.countryId != country.id?.toString()) ||
        (data.country.isNotEmpty &&
            data.country.toLowerCase() != (country.name ?? '').toLowerCase());

    if (isCountryChanged) {
      data.city = '';
      data.state = '';
      data.latitude = '';
      data.longitude = '';
      data.address = '';
      data.clientAddress = '';
    }

    data.selectedCountry = country;
    data.country = country.name ?? '';
    data.countryId = country.id?.toString() ?? '';
    emit(ProjectWizardUpdated(data));
  }

  bool isStepCompleted(int step) {
    switch (step) {
      case 1:
        return data.selectedCategory != null;
      case 2:
        final defaultCode = data.languages.isNotEmpty
            ? (data.languages.first.code ?? 'en')
            : 'en';
        final countryLangCode = data.selectedCountry?.primaryLanguageCode;
        final countryTitle = countryLangCode != null
            ? (data.titles[countryLangCode] ?? '')
            : '';
        final primaryTitle = data.titles[defaultCode] ?? '';
        final isTitleFilled =
            (countryLangCode != null && countryLangCode.isNotEmpty)
            ? countryTitle.trim().isNotEmpty && primaryTitle.trim().isNotEmpty
            : primaryTitle.trim().isNotEmpty;
        return isTitleFilled;
      case 3:
        return data.titleImage != null || data.titleImageUrl.isNotEmpty;
      case 4:
        return data.city.trim().isNotEmpty &&
            data.latitude.trim().isNotEmpty &&
            data.longitude.trim().isNotEmpty;
      case 5:
        return data.floorPlans.isNotEmpty;
      case 6:
        return data.metaTitle.trim().isNotEmpty ||
            data.metaDescription.trim().isNotEmpty ||
            data.keywords.isNotEmpty ||
            data.ogImage != null ||
            data.ogImageUrl.isNotEmpty;
      default:
        return false;
    }
  }

  void addFloorPlan() {
    data.floorPlans.add(ProjectFloorPlanItem());
    emit(ProjectWizardUpdated(data));
  }

  void removeFloorPlan(int index) {
    if (index >= 0 && index < data.floorPlans.length) {
      final item = data.floorPlans[index];
      if (item.id != null) {
        data.removedPlanIds.add(item.id!);
      }
      data.floorPlans.removeAt(index);
      emit(ProjectWizardUpdated(data));
    }
  }

  void notifyDataChanged() {
    emit(ProjectWizardUpdated(data));
  }

  Map<String, dynamic> buildParameters({bool isDraft = false}) {
    final params = <String, dynamic>{};

    // Category
    if (data.selectedCategory?.id != null) {
      params['category_id'] = data.selectedCategory!.id;
    }

    // Step 2: Details
    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    final primaryTitle = data.titles[defaultCode] ?? '';
    params['title'] = primaryTitle;
    params['description'] = data.descriptions[defaultCode] ?? '';
    params['slug_id'] = data.slugId.trim().isNotEmpty
        ? data.slugId.trim()
        : primaryTitle
              .toLowerCase()
              .replaceAll(RegExp('[^a-zA-Z0-9]+'), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '');
    params['type'] = data.projectType;
    params['is_promoted'] = data.isPromoted ? 1 : 0;
    if (AppSettings.showPremiumToggle) {
      params['is_premium'] = data.isPremium ? 1 : 0;
    }

    // Multi-language translations
    for (var i = 0; i < data.languages.length; i++) {
      final lang = data.languages[i];
      final code = lang.code ?? 'en';
      final titleVal = data.titles[code] ?? '';
      final descVal = data.descriptions[code] ?? '';

      if (titleVal.trim().isNotEmpty) {
        params['translations[$i][title][language_id]'] = lang.id;
        params['translations[$i][title][value]'] = titleVal.trim();
      }
      if (descVal.trim().isNotEmpty) {
        params['translations[$i][description][language_id]'] = lang.id;
        params['translations[$i][description][value]'] = descVal.trim();
      }
    }

    // Step 3: Images & Media
    if (data.titleImage != null) {
      params['image'] = MultipartFile.fromFileSync(data.titleImage!.path);
    }

    for (var i = 0; i < data.galleryImages.length; i++) {
      params['gallery_images[$i]'] = MultipartFile.fromFileSync(
        data.galleryImages[i].path,
      );
    }

    if (data.removedGalleryImageIds.isNotEmpty) {
      params['remove_gallery_images'] = data.removedGalleryImageIds.join(',');
    }

    // Video
    if (data.videoType == 0) {
      if (data.customVideoFile != null) {
        params['video_type'] = 0;
        params['custom_video'] = MultipartFile.fromFileSync(
          data.customVideoFile!.path,
        );
      }
    } else if (data.videoUrl.trim().isNotEmpty) {
      params['video_type'] = data.videoType;
      params['video_link'] = data.videoUrl.trim();
    }

    if (data.removeVideo) {
      params['remove_video'] = 1;
    }

    // Documents
    for (var i = 0; i < data.projectDocuments.length; i++) {
      final docPath = data.projectDocuments[i].path;
      if (docPath != null) {
        params['documents[$i]'] = MultipartFile.fromFileSync(docPath);
      }
    }

    if (data.removedDocumentIds.isNotEmpty) {
      params['remove_documents'] = data.removedDocumentIds.join(',');
    }

    // Step 4: Location
    params['city'] = data.city;
    params['state'] = data.state;
    params['country'] = data.country;
    if (data.countryId.isNotEmpty) {
      params['country_id'] = data.countryId;
    }
    params['location'] = data.address;
    if (data.clientAddress.isNotEmpty) {
      params['client_address'] = data.clientAddress;
    }
    params['latitude'] = data.latitude;
    params['longitude'] = data.longitude;

    // Step 5: Floor Plans
    // Skip new plans without an image (e.g. the untouched default
    // "Ground Floor" placeholder) so no empty floor is created.
    final plansToSend = data.floorPlans
        .where((plan) => plan.id != null || plan.imageFile != null)
        .toList();
    for (var i = 0; i < plansToSend.length; i++) {
      final plan = plansToSend[i];
      if (plan.id != null) {
        params['plans[$i][id]'] = plan.id;
      }
      params['plans[$i][title]'] = plan.title;
      if (plan.imageFile != null) {
        params['plans[$i][document]'] = MultipartFile.fromFileSync(
          plan.imageFile!.path,
        );
      }
    }

    if (data.removedPlanIds.isNotEmpty) {
      params['remove_plans'] = data.removedPlanIds.join(',');
    }

    // Step 6: SEO Settings
    params['meta_title'] = data.metaTitle;
    params['meta_description'] = data.metaDescription;
    params['meta_keywords'] = data.keywords.join(',');
    if (data.ogImage != null) {
      params['meta_image'] = MultipartFile.fromFileSync(data.ogImage!.path);
    }

    // Status / Mode
    params['is_draft'] = isDraft;

    if (data.isEdit) {
      params['action_type'] = '0';
      if (data.projectId != null) {
        params['id'] = data.projectId;
      }
    } else {
      params['action_type'] = '1';
    }

    return params;
  }
}
