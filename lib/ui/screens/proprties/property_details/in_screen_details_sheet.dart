import 'package:ebroker/ui/screens/project/view/project_details_screen.dart';
import 'package:ebroker/ui/screens/proprties/property_details/property_details_screen.dart';
import 'package:ebroker/ui/screens/proprties/property_details/property_sheet_controller.dart';
import 'package:material_ui/material_ui.dart';

class InScreenDetailsSheet extends StatefulWidget {
  const InScreenDetailsSheet({super.key});

  @override
  State<InScreenDetailsSheet> createState() => _InScreenDetailsSheetState();
}

class _InScreenDetailsSheetState extends State<InScreenDetailsSheet> {
  PropertySheetData? _activeData;

  @override
  void initState() {
    super.initState();
    _activeData = PropertySheetController.currentSheet.value;
    PropertySheetController.currentSheet.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    PropertySheetController.currentSheet.removeListener(_onSheetChanged);
    super.dispose();
  }

  void _onSheetChanged() {
    setState(() {
      _activeData = PropertySheetController.currentSheet.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeData == null) {
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        PropertySheetController.hide();
      },
      child: Stack(
        children: [
          if (_activeData!.type == SheetItemType.property &&
              _activeData!.property != null)
            PropertyDetails.buildWithProviders(
              key: ValueKey('sheet-property-${_activeData!.property!.id}'),
              property: _activeData!.property!,
              fromMyProperty: _activeData!.fromMyProperty,
              fromSuccess: _activeData!.fromSuccess,
              fromCompleteEnquiry: _activeData!.fromCompleteEnquiry,
              fromAgentDetails: _activeData!.fromAgentDetails,
              heroTag: _activeData!.heroTag,
              onClose: PropertySheetController.hide,
            )
          else if (_activeData!.type == SheetItemType.project &&
              _activeData!.project != null)
            ProjectDetailsScreen.buildWithProviders(
              key: ValueKey('sheet-project-${_activeData!.project!.id}'),
              project: _activeData!.project!,
              heroTag: _activeData!.heroTag,
              fromAgentDetails: _activeData!.fromAgentDetails,
              onClose: PropertySheetController.hide,
            ),
        ],
      ),
    );
  }
}
