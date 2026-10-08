import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:flutter/foundation.dart';

enum SheetItemType { property, project }

class PropertySheetData {
  const PropertySheetData.property({
    required this.property,
    this.fromMyProperty = false,
    this.fromSuccess = false,
    this.fromCompleteEnquiry = false,
    this.fromAgentDetails = false,
    this.heroTag,
  }) : type = SheetItemType.property,
       project = null;

  const PropertySheetData.project({
    required this.project,
    this.heroTag,
    this.fromAgentDetails = false,
  }) : type = SheetItemType.project,
       property = null,
       fromMyProperty = false,
       fromSuccess = false,
       fromCompleteEnquiry = false;

  final SheetItemType type;
  final PropertyModel? property;
  final ProjectModel? project;
  final bool fromMyProperty;
  final bool fromSuccess;
  final bool fromCompleteEnquiry;
  final bool fromAgentDetails;
  final String? heroTag;
}

class PropertySheetController {
  PropertySheetController._();

  static final ValueNotifier<PropertySheetData?> currentSheet =
      ValueNotifier<PropertySheetData?>(null);

  static bool get isShowing => currentSheet.value != null;

  static void showProperty({
    required PropertyModel property,
    bool fromMyProperty = false,
    bool fromSuccess = false,
    bool fromCompleteEnquiry = false,
    bool fromAgentDetails = false,
    String? heroTag,
  }) {
    currentSheet.value = PropertySheetData.property(
      property: property,
      fromMyProperty: fromMyProperty,
      fromSuccess: fromSuccess,
      fromCompleteEnquiry: fromCompleteEnquiry,
      fromAgentDetails: fromAgentDetails,
      heroTag: heroTag,
    );
  }

  static void showProject({
    required ProjectModel project,
    String? heroTag,
    bool fromAgentDetails = false,
  }) {
    currentSheet.value = PropertySheetData.project(
      project: project,
      heroTag: heroTag,
      fromAgentDetails: fromAgentDetails,
    );
  }

  static void hide() {
    currentSheet.value = null;
  }
}
