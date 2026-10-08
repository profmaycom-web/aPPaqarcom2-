import 'dart:io';

import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/data/model/translation_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PropertyWizardData {
  // Edit mode metadata
  bool isEdit = false;
  int? propertyId;
  PropertyModel? originalProperty;
  String requestStatus = '';
  bool isDraftProperty = false;

  // Step 1: Categories
  Category? selectedCategory;

  // Step 2: Property Details
  List<LanguagesModel> languages = [];
  int selectedLanguageIndex = 0;
  Map<String, String> titles = {}; // code -> title
  Map<String, String> descriptions = {}; // code -> description
  String slugId = '';
  String price = '';
  bool isPremium = false;
  int propertyForType = 0; // 0 = Sell, 1 = For Rent
  String selectedRentDuration = 'Monthly';
  CountryModel? selectedCountry;
  int? countryId;
  String selectedCountryName = '';
  int? currencyId;
  String currencyCode = '';
  String currencySymbol = '';

  // Step 3: Images & Media & Documents
  File? titleImage;
  String titleImageUrl = '';
  List<File> galleryImages = [];
  List<String> galleryImageUrls = [];
  List<dynamic> removedGalleryImageIds = [];
  File? v360Image;
  String v360ImageUrl = '';
  int videoType = 1; // 0 = Custom, 1 = YouTube, 2 = Vimeo
  String videoUrl = '';
  File? customVideoFile;
  List<PlatformFile> propertyDocuments = [];
  List<PropertyDocuments> existingDocuments = [];
  List<int> removedDocumentIds = [];

  // Step 4: Facilities
  String bedrooms = '';
  String bathrooms = '';
  String balconies = '';
  String builtUpArea = '';
  String carpetArea = '';
  String selectedFurnishing = 'Furnished';
  String selectedConstructionStatus = 'Ready to Move';
  Map<int, dynamic> customDynamicParameters = {};

  // Step 5: Outdoor Facilities
  Set<int> selectedOutdoorFacilityIds = {};
  Map<int, String> outdoorDistances = {};

  // Step 6: Location
  String city = '';
  String state = '';
  String country = '';
  String address = '';
  String clientAddress = '';
  String latitude = '';
  String longitude = '';

  // Step 7: SEO Settings
  String metaTitle = '';
  String metaDescription = '';
  List<String> keywords = [];
  File? ogImage;
  String ogImageUrl = '';
}

abstract class PropertyWizardState {}

class PropertyWizardInitial extends PropertyWizardState {}

class PropertyWizardUpdated extends PropertyWizardState {
  PropertyWizardUpdated(this.data);
  final PropertyWizardData data;
}

class PropertyWizardCubit extends Cubit<PropertyWizardState> {
  PropertyWizardCubit() : super(PropertyWizardInitial()) {
    _initDefaults();
  }

  final PropertyWizardData data = PropertyWizardData();

  void _initDefaults() {
    data.languages = List<LanguagesModel>.from(AppSettings.languages);
    if (data.languages.isEmpty) {
      data.languages = [
        LanguagesModel(id: '1', code: 'en', name: 'English'),
      ];
    }
    _applyHeaderCountryAsDefault();
  }

  /// Start a new listing in the country selected in the header, so
  /// "List in Country" matches what the user is browsing.
  void _applyHeaderCountryAsDefault() {
    final headerCountryId = HiveUtils.getSelectedCountryId() ?? '';
    final headerCountryName = HiveUtils.getSelectedCountryName() ?? '';
    if (headerCountryName.toLowerCase() == 'all') return;

    final parsedId = int.tryParse(headerCountryId);
    if (parsedId == null && headerCountryName.isEmpty) return;

    data.countryId = parsedId;
    data.selectedCountryName = headerCountryName;
    data.country = headerCountryName;
  }

  void setCountry(CountryModel? country) {
    final isCountryChanged =
        (country == null && data.countryId != null) ||
        (country != null &&
            (data.countryId != country.id ||
                data.selectedCountryName.toLowerCase() !=
                    (country.name ?? '').toLowerCase()));

    if (isCountryChanged) {
      data.city = '';
      data.state = '';
      data.address = '';
      data.clientAddress = '';
      data.latitude = '';
      data.longitude = '';
    }

    if (country == null) {
      data.selectedCountry = null;
      data.countryId = null;
      data.selectedCountryName = '';
      data.country = '';
      data.currencyId = null;
      data.currencyCode = '';
      data.currencySymbol = '';
    } else {
      data.selectedCountry = country;
      data.countryId = country.id;
      data.selectedCountryName = country.name ?? '';
      data.country = country.name ?? '';
      data.currencyId = country.currencyId;
      data.currencyCode = country.currencyCode ?? '';
      data.currencySymbol = country.currencySymbol ?? '';
    }
    notifyState();
  }

  void initFromProperty(PropertyModel prop) {
    data.isEdit = true;
    data.propertyId = prop.id;
    data.originalProperty = prop;
    data.requestStatus = prop.requestStatus ?? '';
    data.isDraftProperty = (prop.requestStatus?.toLowerCase() == 'draft');

    // Step 1: Category
    List<dynamic>? parameterTypes;
    if (Constant.addProperty['category'] is Category &&
        (Constant.addProperty['category'] as Category).id ==
            prop.category?.id &&
        (Constant.addProperty['category'] as Category).parameterTypes != null &&
        (Constant.addProperty['category'] as Category)
            .parameterTypes!
            .isNotEmpty) {
      parameterTypes =
          (Constant.addProperty['category'] as Category).parameterTypes;
    } else {
      parameterTypes = prop.parameters?.map((p) => p.toMap()).toList();
    }

    data.selectedCategory = Category(
      id: prop.category?.id,
      category: prop.category?.category,
      image: prop.category?.image,
      parameterTypes: parameterTypes,
    );

    // Step 2: Property Details
    data.propertyForType =
        (prop.propertyType?.toLowerCase() == 'rent' || prop.propertyType == '1')
        ? 1
        : 0;
    data.price = prop.price?.toString() ?? '';
    data.selectedRentDuration = prop.rentduration ?? 'Monthly';
    data.slugId = prop.slugId ?? '';
    data.isPremium = prop.isPremium ?? false;
    data.countryId = prop.countryId;
    data.selectedCountryName = prop.country ?? '';
    data.currencyId = prop.currencyId;
    data.currencyCode = prop.currencyCode ?? '';
    data.currencySymbol = prop.currencySymbol ?? '';

    // Multi-language titles / descriptions
    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    data.titles[defaultCode] = prop.title ?? '';
    data.descriptions[defaultCode] = prop.description ?? '';

    // If translations available in prop
    if (prop.translations != null) {
      for (final t in prop.translations!) {
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

    // Step 3: Media
    data.titleImageUrl = prop.titleImage ?? '';
    data.v360ImageUrl = prop.threeDImage ?? '';
    data.videoUrl = prop.video ?? '';
    if (prop.allPropData is Map) {
      data.videoType =
          int.tryParse(prop.allPropData['video_type']?.toString() ?? '1') ?? 1;
      data.ogImageUrl = prop.allPropData['meta_image']?.toString() ?? '';
      data.metaTitle = prop.allPropData['meta_title']?.toString() ?? '';
      data.metaDescription =
          prop.allPropData['meta_description']?.toString() ?? '';
      if (prop.allPropData['meta_keywords'] != null) {
        final kwStr = prop.allPropData['meta_keywords'].toString();
        data.keywords = kwStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    for (final g in prop.gallery ?? <Gallery>[]) {
      if (g.image.isNotEmpty) {
        data.galleryImageUrls.add(g.image);
      }
    }

    if (prop.documents != null) {
      data.existingDocuments = List<PropertyDocuments>.from(prop.documents!);
    }

    // Step 4: Facilities from parameters
    if (prop.parameters != null) {
      for (final p in prop.parameters!) {
        final name = (p.name ?? '').toLowerCase();
        final idStr = p.id?.toString() ?? '';
        final val = p.value?.toString() ?? '';

        if (name.contains('bedroom') || idStr == 'bedrooms') {
          data.bedrooms = val;
        } else if (name.contains('bathroom') || idStr == 'bathrooms') {
          data.bathrooms = val;
        } else if (name.contains('balcon') || idStr == 'balconies') {
          data.balconies = val;
        } else if (name.contains('built') || idStr == 'built_up_area') {
          data.builtUpArea = val;
        } else if (name.contains('carpet') || idStr == 'carpet_area') {
          data.carpetArea = val;
        } else if (name.contains('furnish') || idStr == 'furnishing') {
          data.selectedFurnishing = val.isNotEmpty ? val : 'Furnished';
        } else if (name.contains('construct') ||
            idStr == 'construction_status') {
          data.selectedConstructionStatus = val.isNotEmpty
              ? val
              : 'Ready to Move';
        }
        if (p.id != null) {
          data.customDynamicParameters[p.id!] = p.value ?? val;
        }
      }
    }

    // Step 5: Outdoor Facilities
    if (prop.assignedOutdoorFacility != null) {
      for (final f in prop.assignedOutdoorFacility!) {
        final fId = int.tryParse(f.facilityId ?? '');
        if (fId != null) {
          data.selectedOutdoorFacilityIds.add(fId);
          data.outdoorDistances[fId] = f.distance ?? '0';
        }
      }
    }

    // Step 6: Location
    data.city = prop.city ?? '';
    data.state = prop.state ?? '';
    data.country = prop.country ?? '';
    data.address = prop.address ?? '';
    data.clientAddress = prop.clientAddress ?? '';
    data.latitude = prop.latitude ?? '';
    data.longitude = prop.longitude ?? '';

    notifyState();
  }

  void initFromMap(Map<String, dynamic> map) {
    data.isEdit = true;
    data.propertyId = map['id'] != null
        ? int.tryParse(map['id'].toString())
        : null;
    data.requestStatus = map['request_status']?.toString() ?? '';
    data.isDraftProperty = (data.requestStatus.toLowerCase() == 'draft');

    // Step 1: Category
    if (map['category'] is Category) {
      data.selectedCategory = map['category'] as Category;
    } else if (map['category'] is Map) {
      data.selectedCategory = Category.fromJson(
        Map<String, dynamic>.from(map['category'] as Map),
      );
    } else if (map['catId'] != null) {
      data.selectedCategory = Category(
        id: int.tryParse(map['catId'].toString()),
      );
    }

    if ((data.selectedCategory?.parameterTypes == null ||
            data.selectedCategory!.parameterTypes!.isEmpty) &&
        Constant.addProperty['category'] is Category) {
      final constCat = Constant.addProperty['category'] as Category;
      if (constCat.id == data.selectedCategory?.id ||
          data.selectedCategory?.id == null) {
        data.selectedCategory = constCat;
      } else {
        data.selectedCategory!.parameterTypes = constCat.parameterTypes;
      }
    }

    // Step 2: Property Details
    final propType = map['propType']?.toString().toLowerCase() ?? '';
    data.propertyForType = (propType == 'rent' || propType == '1') ? 1 : 0;
    data.price = map['price']?.toString() ?? '';
    data.selectedRentDuration = map['rentduration']?.toString() ?? 'Monthly';
    data.slugId = map['slug_id']?.toString() ?? '';
    data.isPremium =
        map['is_premium'] == true ||
        map['is_premium'] == '1' ||
        map['is_premium'] == 1;
    data.countryId = map['country_id'] != null
        ? int.tryParse(map['country_id'].toString())
        : null;
    data.selectedCountryName = map['country']?.toString() ?? '';
    data.currencyId = map['currency_id'] != null
        ? int.tryParse(map['currency_id'].toString())
        : null;
    data.currencyCode = map['property_currency'] is Map
        ? map['property_currency']['code']?.toString() ?? ''
        : map['currency_code']?.toString() ?? '';
    data.currencySymbol = map['property_currency'] is Map
        ? map['property_currency']['symbol']?.toString() ?? ''
        : map['currency_symbol']?.toString() ?? '';

    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    data.titles[defaultCode] =
        map['name']?.toString() ?? map['title']?.toString() ?? '';
    data.descriptions[defaultCode] =
        map['desc']?.toString() ?? map['description']?.toString() ?? '';

    if (map['translations'] is List) {
      for (final t in map['translations'] as List) {
        if (t is Translations) {
          for (final l in data.languages) {
            if (l.id == t.languageId || l.code == t.languageId) {
              if (l.code != null && t.value != null) {
                if (t.key == 'title') {
                  data.titles[l.code!] = t.value.toString();
                } else if (t.key == 'description') {
                  data.descriptions[l.code!] = t.value.toString();
                }
              }
            }
          }
        }
      }
    }

    // Step 3: Media
    data.titleImageUrl =
        map['titleImage']?.toString() ?? map['title_image']?.toString() ?? '';
    data.v360ImageUrl = map['three_d_image']?.toString() ?? '';
    data.videoUrl =
        map['video_link']?.toString() ?? map['video']?.toString() ?? '';

    if (map['images'] is List) {
      data.galleryImageUrls = (map['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (map['gallary_with_id'] is List) {
      for (final g in map['gallary_with_id'] as List) {
        if (g is Gallery && g.image.isNotEmpty) {
          data.galleryImageUrls.add(g.image);
        }
      }
    }

    if (map['documents'] is List) {
      data.existingDocuments = (map['documents'] as List)
          .whereType<PropertyDocuments>()
          .toList();
    }

    // Step 4: Facilities
    final rawParams = map['parms'] ?? map['parameters'];
    if ((data.selectedCategory?.parameterTypes == null ||
            data.selectedCategory!.parameterTypes!.isEmpty) &&
        rawParams is List &&
        rawParams.isNotEmpty) {
      data.selectedCategory?.parameterTypes = rawParams.map((e) {
        if (e is Parameter) {
          return e.toMap();
        } else if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return e;
      }).toList();
    }

    if (rawParams is List) {
      for (final p in rawParams) {
        if (p is Parameter) {
          final name = (p.name ?? '').toLowerCase();
          final idStr = p.id?.toString().toLowerCase() ?? '';
          final val = p.value?.toString() ?? '';
          if (name.contains('bedroom') || idStr.contains('bedroom')) {
            data.bedrooms = val;
          } else if (name.contains('bathroom') || idStr.contains('bathroom')) {
            data.bathrooms = val;
          } else if (name.contains('balcon') || idStr.contains('balcon')) {
            data.balconies = val;
          } else if (name.contains('built') || idStr.contains('built')) {
            data.builtUpArea = val;
          } else if (name.contains('carpet') || idStr.contains('carpet')) {
            data.carpetArea = val;
          } else if (name.contains('furnish') || idStr.contains('furnish')) {
            data.selectedFurnishing = val.isNotEmpty ? val : 'Furnished';
          } else if (name.contains('construct') ||
              idStr.contains('construct')) {
            data.selectedConstructionStatus = val.isNotEmpty
                ? val
                : 'Ready to Move';
          }
          if (p.id != null) {
            data.customDynamicParameters[p.id!] = p.value ?? val;
          }
        } else if (p is Map) {
          final rawId = p['id'] ?? p['parameter_id'];
          final id =
              rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
          final rawVal = p['value'] ??
              (p['pivot'] is Map ? p['pivot']['value'] : null) ??
              p['parameter_value'] ??
              p['paramaeter_value'];
          final val = rawVal?.toString() ?? '';
          final name = (p['name'] ?? p['translated_name'] ?? '')
              .toString()
              .toLowerCase();

          if (name.contains('bedroom')) {
            data.bedrooms = val;
          } else if (name.contains('bathroom')) {
            data.bathrooms = val;
          } else if (name.contains('balcon')) {
            data.balconies = val;
          } else if (name.contains('built')) {
            data.builtUpArea = val;
          } else if (name.contains('carpet')) {
            data.carpetArea = val;
          } else if (name.contains('furnish')) {
            data.selectedFurnishing = val.isNotEmpty ? val : 'Furnished';
          } else if (name.contains('construct')) {
            data.selectedConstructionStatus = val.isNotEmpty
                ? val
                : 'Ready to Move';
          }

          if (id != null) {
            data.customDynamicParameters[id] = rawVal ?? val;
          }
        }
      }
    }

    // Step 5: Outdoor facilities
    if (map['assign_facilities'] is List) {
      for (final f in map['assign_facilities'] as List) {
        if (f is AssignedOutdoorFacility) {
          final fId = int.tryParse(f.facilityId ?? '');
          if (fId != null) {
            data.selectedOutdoorFacilityIds.add(fId);
            data.outdoorDistances[fId] = f.distance ?? '0';
          }
        } else if (f is Map) {
          final fId = int.tryParse(f['facility_id']?.toString() ?? '');
          if (fId != null) {
            data.selectedOutdoorFacilityIds.add(fId);
            data.outdoorDistances[fId] = f['distance']?.toString() ?? '0';
          }
        }
      }
    }

    // Step 6: Location
    data.city = map['city']?.toString() ?? '';
    data.state = map['state']?.toString() ?? '';
    data.country = map['country']?.toString() ?? '';
    data.address = map['address']?.toString() ?? '';
    data.clientAddress = map['client_address']?.toString() ?? '';
    data.latitude = map['latitude']?.toString() ?? '';
    data.longitude = map['longitude']?.toString() ?? '';

    // Step 7: SEO
    if (map['allPropData'] is Map) {
      final allData = map['allPropData'] as Map;
      data.videoType =
          int.tryParse(allData['video_type']?.toString() ?? '1') ?? 1;
      data.ogImageUrl = allData['meta_image']?.toString() ?? '';
      data.metaTitle = allData['meta_title']?.toString() ?? '';
      data.metaDescription = allData['meta_description']?.toString() ?? '';
      if (allData['meta_keywords'] != null) {
        final kwStr = allData['meta_keywords'].toString();
        data.keywords = kwStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    notifyState();
  }

  void notifyState() {
    emit(PropertyWizardUpdated(data));
  }

  void reset() {
    final fresh = PropertyWizardData();
    data.isEdit = fresh.isEdit;
    data.propertyId = fresh.propertyId;
    data.originalProperty = fresh.originalProperty;
    data.requestStatus = fresh.requestStatus;
    data.isDraftProperty = fresh.isDraftProperty;
    data.selectedCategory = fresh.selectedCategory;
    data.titles.clear();
    data.descriptions.clear();
    data.slugId = fresh.slugId;
    data.price = fresh.price;
    data.isPremium = fresh.isPremium;
    data.propertyForType = fresh.propertyForType;
    data.selectedRentDuration = fresh.selectedRentDuration;
    data.selectedCountry = fresh.selectedCountry;
    data.countryId = fresh.countryId;
    data.selectedCountryName = fresh.selectedCountryName;
    data.currencyId = fresh.currencyId;
    data.currencyCode = fresh.currencyCode;
    data.currencySymbol = fresh.currencySymbol;
    data.titleImage = null;
    data.titleImageUrl = '';
    data.galleryImages.clear();
    data.galleryImageUrls.clear();
    data.removedGalleryImageIds.clear();
    data.v360Image = null;
    data.v360ImageUrl = '';
    data.videoType = 1;
    data.videoUrl = '';
    data.customVideoFile = null;
    data.propertyDocuments.clear();
    data.existingDocuments.clear();
    data.removedDocumentIds.clear();
    data.bedrooms = '';
    data.bathrooms = '';
    data.balconies = '';
    data.builtUpArea = '';
    data.carpetArea = '';
    data.selectedFurnishing = 'Furnished';
    data.selectedConstructionStatus = 'Ready to Move';
    data.customDynamicParameters.clear();
    data.selectedOutdoorFacilityIds.clear();
    data.outdoorDistances.clear();
    data.city = '';
    data.state = '';
    data.country = '';
    data.address = '';
    data.clientAddress = '';
    data.latitude = '';
    data.longitude = '';
    data.metaTitle = '';
    data.metaDescription = '';
    data.keywords = [];
    data.ogImage = null;
    data.ogImageUrl = '';
    _initDefaults();
    notifyState();
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
        return isTitleFilled && data.price.trim().isNotEmpty;
      case 3:
        return data.titleImage != null || data.titleImageUrl.isNotEmpty;
      case 4:
        return data.customDynamicParameters.values.any(
          (v) => v != null && v.toString().trim().isNotEmpty,
        );
      case 5:
        return data.selectedOutdoorFacilityIds.isNotEmpty;
      case 6:
        return data.city.trim().isNotEmpty &&
            data.latitude.trim().isNotEmpty &&
            data.longitude.trim().isNotEmpty;
      case 7:
        return data.metaTitle.trim().isNotEmpty ||
            data.metaDescription.trim().isNotEmpty ||
            data.ogImage != null ||
            data.ogImageUrl.isNotEmpty;
      default:
        return false;
    }
  }

  Map<String, dynamic> buildParameters({bool isDraft = false}) {
    final defaultCode = data.languages.isNotEmpty
        ? (data.languages.first.code ?? 'en')
        : 'en';
    final primaryTitle = data.titles[defaultCode] ?? '';
    final primaryDesc = data.descriptions[defaultCode] ?? '';

    final parameters = <String, dynamic>{
      'category_id': data.selectedCategory?.id,
      'property_type': data.propertyForType.toString(),
      'price': data.price.trim(),
      'title': primaryTitle.trim(),
      'description': primaryDesc.trim(),
      'is_premium': data.isPremium ? '1' : '0',
      'slug_id': data.slugId.trim().isNotEmpty
          ? data.slugId.trim()
          : primaryTitle
                .toLowerCase()
                .replaceAll(RegExp('[^a-zA-Z0-9]+'), '-')
                .replaceAll(RegExp(r'^-+|-+$'), ''),
      'city': data.city.trim(),
      'state': data.state.trim(),
      'country': data.country.trim(),
      'address': data.address.trim(),
      'client_address': data.clientAddress.trim(),
      'latitude': data.latitude.trim(),
      'longitude': data.longitude.trim(),
      'meta_title': data.metaTitle.trim(),
      'meta_description': data.metaDescription.trim(),
      'meta_keywords': data.keywords.join(','),
    };

    final userId = HiveUtils.getUserId();
    if (userId != null && userId.isNotEmpty) {
      parameters['userid'] = userId;
    }

    if (data.countryId != null) {
      parameters['country_id'] = data.countryId;
    }
    if (data.currencyId != null) {
      parameters['currency_id'] = data.currencyId;
    }

    parameters['is_draft'] = isDraft;

    if (data.propertyForType == 1) {
      parameters['rentduration'] = data.selectedRentDuration;
    }

    // Multi-language translations
    var translationIndex = 0;
    for (final lang in data.languages) {
      if (lang.code != null && lang.id != null) {
        final title = data.titles[lang.code]?.trim() ?? '';
        final desc = data.descriptions[lang.code]?.trim() ?? '';
        if (title.isNotEmpty || desc.isNotEmpty) {
          parameters['translations[$translationIndex][title][translation_id]'] =
              '';
          parameters['translations[$translationIndex][title][language_id]'] =
              lang.id;
          parameters['translations[$translationIndex][title][value]'] = title;

          parameters['translations[$translationIndex][description][translation_id]'] =
              '';
          parameters['translations[$translationIndex][description][language_id]'] =
              lang.id;
          parameters['translations[$translationIndex][description][value]'] =
              desc;
          translationIndex++;
        }
      }
    }

    // Step 3 Media
    if (data.titleImage != null) {
      parameters['title_image'] = data.titleImage;
    }

    if (data.galleryImages.isNotEmpty) {
      parameters['gallery_images'] = data.galleryImages;
    }
    if (data.removedGalleryImageIds.isNotEmpty) {
      parameters['remove_gallery_images'] = data.removedGalleryImageIds.join(
        ',',
      );
    }

    if (data.v360Image != null) {
      parameters['three_d_image'] = data.v360Image;
    }

    if (data.videoType == 0) {
      if (data.customVideoFile != null) {
        parameters['video_type'] = 0;
        parameters['custom_video'] = data.customVideoFile;
      }
    } else if (data.videoUrl.trim().isNotEmpty) {
      parameters['video_type'] = data.videoType;
      parameters['video_link'] = data.videoUrl.trim();
    }

    if (data.propertyDocuments.isNotEmpty) {
      final docFiles = data.propertyDocuments
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
      if (docFiles.isNotEmpty) {
        parameters['documents'] = docFiles;
      }
    }
    if (data.removedDocumentIds.isNotEmpty) {
      parameters['remove_documents'] = data.removedDocumentIds.join(',');
    }

    // Step 7 OG Image
    if (data.ogImage != null) {
      parameters['meta_image'] = data.ogImage;
    }

    // Step 4 Facilities / Custom parameters
    var paramIndex = 0;
    data.customDynamicParameters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        parameters['parameters[$paramIndex][parameter_id]'] = key;
        parameters['parameters[$paramIndex][value]'] = value;
        paramIndex++;
      }
    });

    // Step 5 Outdoor Facilities
    var facilityIndex = 0;
    for (final fId in data.selectedOutdoorFacilityIds) {
      parameters['facilities[$facilityIndex][facility_id]'] = fId;
      final distance = data.outdoorDistances[fId]?.trim() ?? '';
      parameters['facilities[$facilityIndex][distance]'] = distance.isNotEmpty
          ? distance
          : '0';
      facilityIndex++;
    }

    if (data.isEdit && data.propertyId != null) {
      parameters['id'] = data.propertyId;
      parameters['action_type'] = '0';
    } else {
      parameters['action_type'] = '1';
    }

    return parameters;
  }
}
