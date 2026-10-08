import 'dart:async';
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/data/repositories/category_repository.dart';
import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_file_picker.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class Step4FacilitiesScreen extends StatefulWidget {
  const Step4FacilitiesScreen({
    required this.onNext,
    required this.onBack,
    this.onSaveDraft,
    super.key,
    this.isSavingDraft = false,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSaveDraft;
  final bool isSavingDraft;

  @override
  State<Step4FacilitiesScreen> createState() => _Step4FacilitiesScreenState();
}

class _Step4FacilitiesScreenState extends State<Step4FacilitiesScreen> {
  final Map<int, TextEditingController> _dynamicControllers = {};
  final Map<int, dynamic> _dynamicValues = {};

  bool _isLoading = false;
  final List<Map<String, dynamic>> _backendParameters = [];

  @override
  void initState() {
    super.initState();
    final data = context.read<PropertyWizardCubit>().data;
    _initParameters(data);
  }

  void _initParameters(PropertyWizardData data) {
    final cat = data.selectedCategory;
    final catParams = cat?.parameterTypes;

    if (catParams != null && catParams.isNotEmpty) {
      _parseBackendParameters(catParams, data);
    } else if (cat?.id != null) {
      unawaited(_fetchCategoryParameters(cat!.id!, data));
    }
  }

  void _parseBackendParameters(
    List<dynamic> catParams,
    PropertyWizardData data,
  ) {
    _backendParameters.clear();
    for (final element in catParams) {
      final Map<String, dynamic> mapData;
      if (element is Map) {
        mapData = Map<String, dynamic>.from(element);
      } else if (element is Parameter) {
        mapData = element.toMap();
      } else {
        continue;
      }

      final dynamic rawId = mapData['id'] ?? mapData['parameter_id'];
      final fieldId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');

      if (fieldId != null) {
        // Pre-fill value from cubit or fallback to named fields or default backend value
        dynamic initialVal = data.customDynamicParameters[fieldId];
        if (initialVal == null || initialVal.toString().trim().isEmpty) {
          final name = (mapData['name'] ?? mapData['translated_name'] ?? '')
              .toString()
              .toLowerCase();
          if (name.contains('bedroom')) {
            initialVal = data.bedrooms;
          } else if (name.contains('bathroom')) {
            initialVal = data.bathrooms;
          } else if (name.contains('balcon')) {
            initialVal = data.balconies;
          } else if (name.contains('built')) {
            initialVal = data.builtUpArea;
          } else if (name.contains('carpet')) {
            initialVal = data.carpetArea;
          } else if (name.contains('furnish')) {
            initialVal = data.selectedFurnishing;
          } else if (name.contains('construct')) {
            initialVal = data.selectedConstructionStatus;
          }
        }
        if (initialVal == null || initialVal.toString().trim().isEmpty) {
          final rawVal =
              mapData['value'] ??
              (mapData['pivot'] is Map ? mapData['pivot']['value'] : null) ??
              mapData['parameter_value'] ??
              mapData['paramaeter_value'];
          initialVal = rawVal?.toString() ?? '';
        }

        // For radio/dropdown default to first option if none set
        final type = (mapData['type_of_parameter'] ?? '')
            .toString()
            .toLowerCase();
        if ((type == 'radiobutton' || type == 'dropdown') &&
            (initialVal == null || initialVal.toString().isEmpty)) {
          final options = _extractOptions(mapData);
          if (options.isNotEmpty) {
            initialVal = options.first;
          }
        }

        _dynamicValues[fieldId] = initialVal;
        if (_dynamicControllers.containsKey(fieldId)) {
          _dynamicControllers[fieldId]!.text = initialVal?.toString() ?? '';
        } else {
          _dynamicControllers[fieldId] = TextEditingController(
            text: initialVal?.toString() ?? '',
          );
        }
        data.customDynamicParameters[fieldId] = initialVal;
      }
      _backendParameters.add(mapData);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchCategoryParameters(
    int catId,
    PropertyWizardData data,
  ) async {
    setState(() => _isLoading = true);
    try {
      final result = await CategoryRepository().fetchCategories(
        offset: 0,
        id: catId,
      );
      if (result.modelList.isNotEmpty) {
        final updatedCat = result.modelList.firstWhere(
          (c) => c.id == catId,
          orElse: () => result.modelList.first,
        );
        if (updatedCat.parameterTypes != null &&
            updatedCat.parameterTypes!.isNotEmpty) {
          data.selectedCategory?.parameterTypes = updatedCat.parameterTypes;
          _parseBackendParameters(updatedCat.parameterTypes!, data);
        }
      }
    } on Exception catch (_) {
      // Ignore API failure
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  late PropertyWizardCubit _wizardCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wizardCubit = context.read<PropertyWizardCubit>();
  }

  @override
  void dispose() {
    _syncToCubit();
    for (final c in _dynamicControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncToCubit() {
    final cubit = _wizardCubit;
    for (final entry in _dynamicValues.entries) {
      cubit.data.customDynamicParameters[entry.key] = entry.value;
    }
    for (final entry in _dynamicControllers.entries) {
      final text = entry.value.text.trim();
      cubit.data.customDynamicParameters[entry.key] = text;
    }
    for (final param in _backendParameters) {
      final rawId = param['id'] ?? param['parameter_id'];
      final fieldId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');
      if (fieldId != null) {
        final val =
            cubit.data.customDynamicParameters[fieldId]?.toString() ?? '';
        final name = (param['name'] ?? param['translated_name'] ?? '')
            .toString()
            .toLowerCase();
        if (name.contains('bedroom')) {
          cubit.data.bedrooms = val;
        } else if (name.contains('bathroom')) {
          cubit.data.bathrooms = val;
        } else if (name.contains('balcon')) {
          cubit.data.balconies = val;
        } else if (name.contains('built')) {
          cubit.data.builtUpArea = val;
        } else if (name.contains('carpet')) {
          cubit.data.carpetArea = val;
        } else if (name.contains('furnish')) {
          cubit.data.selectedFurnishing = val.isNotEmpty ? val : 'Furnished';
        } else if (name.contains('construct')) {
          cubit.data.selectedConstructionStatus = val.isNotEmpty
              ? val
              : 'Ready to Move';
        }
      }
    }
  }

  bool _validateRequired() {
    _syncToCubit();
    final data = context.read<PropertyWizardCubit>().data;

    for (final param in _backendParameters) {
      final isRequired =
          param['is_required'] == 1 || param['is_required'] == '1';
      if (isRequired) {
        final rawId = param['id'];
        final fieldId = rawId is int
            ? rawId
            : int.tryParse(rawId?.toString() ?? '');
        if (fieldId != null) {
          final val = data.customDynamicParameters[fieldId];
          if (val == null || val.toString().trim().isEmpty) {
            final title =
                param['translated_name']?.toString() ??
                param['name']?.toString() ??
                'Facility';
            HelperUtils.showSnackBarMessage(
              context,
              'Please provide $title',
              type: MessageType.error,
            );
            return false;
          }
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PropertyWizardCubit>();
    final data = cubit.data;

    final borderColor = context.color.borderColor;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'facilities'.translate(context),
        onTapBackButton: () {
          _syncToCubit();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '4/7',
              fontSize: context.font.md,
              fontWeight: .w600,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
      bottomNavigationBar: StepBottomBar(
        nextButtonText: 'Next',
        onNext: () {
          if (!_validateRequired()) return;
          _syncToCubit();
          widget.onNext();
        },
        onSaveDraft: widget.onSaveDraft != null
            ? () {
                _syncToCubit();
                widget.onSaveDraft!();
              }
            : null,
        isSavingDraft: widget.isSavingDraft,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                physics: Constant.scrollPhysics,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_backendParameters.isNotEmpty)
                      ..._buildDynamicBackendParameters(data, borderColor)
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: CustomText(
                            'No facilities required for this category.',
                            fontSize: 14,
                            color: context.color.textColorDark.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ==========================================
  // RENDER DYNAMIC BACKEND PARAMETERS
  // ==========================================
  List<Widget> _buildDynamicBackendParameters(
    PropertyWizardData data,
    Color borderColor,
  ) {
    final widgets = <Widget>[];

    for (final param in _backendParameters) {
      final rawId = param['id'];
      final fieldId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');
      if (fieldId == null) continue;

      final title =
          param['translated_name']?.toString() ??
          param['name']?.toString() ??
          '';
      final imageUrl = param['image']?.toString() ?? '';
      final isRequired =
          param['is_required'] == 1 || param['is_required'] == '1';
      final type = (param['type_of_parameter'] ?? '').toString().toLowerCase();

      // 1. Radio / Dropdown Options -> Pill Chips
      if (type == 'radiobutton' || type == 'dropdown') {
        final options = _extractOptions(param);
        final currentValue =
            _dynamicValues[fieldId]?.toString() ??
            (options.isNotEmpty ? options.first : '');

        widgets
          ..add(
            _buildFieldHeader(
              title: title,
              imageUrl: imageUrl,
              fallbackIcon: _getIconForName(title),
              isRequired: isRequired,
            ),
          )
          ..add(const SizedBox(height: 8))
          ..add(
            _buildPillChipSelector(
              options: options,
              selectedValue: currentValue,
              borderColor: borderColor,
              onSelect: (val) {
                setState(() {
                  _dynamicValues[fieldId] = val;
                  data.customDynamicParameters[fieldId] = val;
                });
              },
            ),
          )
          ..add(const SizedBox(height: 18));
      }
      // 2. Checkbox Options -> Multi-select Pill Chips
      else if (type == 'checkbox') {
        final options = _extractOptions(param);
        final currentSelected = _extractSelectedCheckboxes(
          _dynamicValues[fieldId],
        );

        widgets
          ..add(
            _buildFieldHeader(
              title: title,
              imageUrl: imageUrl,
              fallbackIcon: _getIconForName(title),
              isRequired: isRequired,
            ),
          )
          ..add(const SizedBox(height: 8))
          ..add(
            _buildMultiSelectPillChips(
              options: options,
              selectedValues: currentSelected,
              borderColor: borderColor,
              onToggle: (val) {
                setState(() {
                  if (currentSelected.contains(val)) {
                    currentSelected.remove(val);
                  } else {
                    currentSelected.add(val);
                  }
                  final joined = currentSelected.join(',');
                  _dynamicValues[fieldId] = joined;
                  data.customDynamicParameters[fieldId] = joined;
                });
              },
            ),
          )
          ..add(const SizedBox(height: 18));
      }
      // 3. File / Image parameter
      else if (type == 'file') {
        final currentFile = _dynamicValues[fieldId];

        widgets
          ..add(
            _buildFieldHeader(
              title: title,
              imageUrl: imageUrl,
              fallbackIcon: Icons.attach_file,
              isRequired: isRequired,
            ),
          )
          ..add(const SizedBox(height: 8))
          ..add(
            _buildFileUploadBox(
              fieldId: fieldId,
              currentValue: currentFile,
              borderColor: borderColor,
            ),
          )
          ..add(const SizedBox(height: 18));
      }
      // 4. Numeric / Textbox parameter
      else {
        final ctrl = _dynamicControllers.putIfAbsent(
          fieldId,
          () => TextEditingController(
            text: _dynamicValues[fieldId]?.toString() ?? '',
          ),
        );
        if (ctrl.text.isEmpty &&
            _dynamicValues[fieldId] != null &&
            _dynamicValues[fieldId].toString().isNotEmpty) {
          ctrl.text = _dynamicValues[fieldId].toString();
        }
        final isNumber = type == 'number';
        final hint = isNumber
            ? 'addNumerical'.translate(context)
            : 'writeSomething'.translate(context);

        widgets
          ..add(
            _buildFieldHeader(
              title: title,
              imageUrl: imageUrl,
              fallbackIcon: _getIconForName(title),
              isRequired: isRequired,
            ),
          )
          ..add(const SizedBox(height: 8))
          ..add(
            CustomTextFormField(
              controller: ctrl,
              keyboard: isNumber ? TextInputType.number : TextInputType.text,
              action: TextInputAction.next,
              hintText: hint,
              borderRadius: 6,
              borderColor: borderColor,
              fillColor: context.color.secondaryColor,
              onChange: (val) {
                final stringVal = val?.toString() ?? '';
                _dynamicValues[fieldId] = stringVal;
                data.customDynamicParameters[fieldId] = stringVal;
                final name = title.toLowerCase();
                if (name.contains('bedroom')) {
                  data.bedrooms = stringVal;
                } else if (name.contains('bathroom')) {
                  data.bathrooms = stringVal;
                } else if (name.contains('balcon')) {
                  data.balconies = stringVal;
                } else if (name.contains('built')) {
                  data.builtUpArea = stringVal;
                } else if (name.contains('carpet')) {
                  data.carpetArea = stringVal;
                }
              },
            ),
          )
          ..add(const SizedBox(height: 18));
      }
    }

    return widgets;
  }

  // ==========================================
  // WIDGET HELPERS
  // ==========================================

  Widget _buildFieldHeader({
    required String title,
    required String imageUrl,
    required IconData fallbackIcon,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32.rw(context),
          height: 32.rf(context),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.color.tertiaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: imageUrl.isNotEmpty
              ? CustomImage(
                  imageUrl: imageUrl,
                  color: context.color.tertiaryColor,
                  fit: BoxFit.contain,
                )
              : Icon(
                  fallbackIcon,
                  size: 18,
                  color: context.color.tertiaryColor,
                ),
        ),
        SizedBox(width: 10.rw(context)),
        CustomText(
          title,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.color.textColorDark,
        ),
        if (isRequired)
          CustomText(
            ' *',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.color.error,
          ),
      ],
    );
  }

  Widget _buildPillChipSelector({
    required List<String> options,
    required String selectedValue,
    required Color borderColor,
    required ValueChanged<String> onSelect,
  }) {
    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((option) {
            final isSelected =
                selectedValue.trim().toLowerCase() ==
                option.trim().toLowerCase();

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.color.tertiaryColor.withValues(alpha: 0.12)
                        : context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? context.color.tertiaryColor.withValues(alpha: 0.4)
                          : borderColor,
                    ),
                  ),
                  child: CustomText(
                    option,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? context.color.tertiaryColor
                        : context.color.textColorDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMultiSelectPillChips({
    required List<String> options,
    required List<String> selectedValues,
    required Color borderColor,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValues.any(
          (s) => s.trim().toLowerCase() == option.trim().toLowerCase(),
        );

        return GestureDetector(
          onTap: () => onToggle(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.color.tertiaryColor.withValues(alpha: 0.12)
                  : context.color.secondaryColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? context.color.tertiaryColor.withValues(alpha: 0.4)
                    : borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: isSelected
                      ? context.color.tertiaryColor
                      : context.color.textLightColor,
                ),
                SizedBox(width: 6.rw(context)),
                CustomText(
                  option,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? context.color.tertiaryColor
                      : context.color.textColorDark,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileUploadBox({
    required int fieldId,
    required dynamic currentValue,
    required Color borderColor,
  }) {
    final fileName = currentValue is File
        ? currentValue.path.split('/').last
        : (currentValue is String ? currentValue : '');

    return GestureDetector(
      onTap: () async {
        final result = await AppFilePicker.pickFile(
          allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg', 'docx'],
        );
        if (result?.path != null) {
          final file = File(result!.path!);
          setState(() {
            _dynamicValues[fieldId] = file;
            context
                    .read<PropertyWizardCubit>()
                    .data
                    .customDynamicParameters[fieldId] =
                file;
          });
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            CustomImage(
              imageUrl: AppIcons.paperClip,
              color: context.color.tertiaryColor,
              width: 20.rw(context),
              height: 20.rh(context),
            ),
            SizedBox(width: 8.rw(context)),
            Expanded(
              child: CustomText(
                fileName.isNotEmpty ? fileName : 'Choose file...',
                fontSize: 13,
                color: fileName.isNotEmpty
                    ? context.color.textColorDark
                    : context.color.textLightColor,
                maxLines: 1,
              ),
            ),
            if (fileName.isNotEmpty)
              IconButton(
                icon: CustomImage(
                  imageUrl: AppIcons.closeCircle,
                  color: context.color.textColorDark,
                  width: 16.rw(context),
                  height: 16.rh(context),
                ),
                onPressed: () {
                  setState(() {
                    _dynamicValues.remove(fieldId);
                    context
                        .read<PropertyWizardCubit>()
                        .data
                        .customDynamicParameters
                        .remove(fieldId);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  List<String> _extractOptions(Map<String, dynamic> param) {
    if (param['translated_option_value'] is List) {
      final list = param['translated_option_value'] as List;
      return list
          .map((e) {
            if (e is Map) {
              return (e['translated'] ?? e['value'] ?? '').toString();
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (param['type_values'] is List) {
      return (param['type_values'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (param['type_values'] is String) {
      return (param['type_values'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> _extractSelectedCheckboxes(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      return val
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  IconData _getIconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('bedroom')) {
      return Icons.king_bed_outlined;
    }
    if (n.contains('bathroom')) {
      return Icons.bathtub_outlined;
    }
    if (n.contains('balcon')) {
      return Icons.balcony_outlined;
    }
    if (n.contains('carpet')) {
      return Icons.crop_free_outlined;
    }
    if (n.contains('built') || n.contains('area')) {
      return Icons.aspect_ratio_outlined;
    }
    if (n.contains('furnish')) {
      return Icons.chair_outlined;
    }
    if (n.contains('construct')) {
      return Icons.home_work_outlined;
    }
    if (n.contains('park')) {
      return Icons.local_parking_outlined;
    }
    if (n.contains('floor')) {
      return Icons.layers_outlined;
    }
    if (n.contains('pool')) {
      return Icons.pool_outlined;
    }
    return Icons.tune;
  }
}
