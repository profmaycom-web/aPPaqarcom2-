import 'package:dio/dio.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/widgets/download_doc.dart';
import 'package:material_ui/material_ui.dart';

/// Option shown inside a radio/checkbox/dropdown group.
class AppFormOption {
  const AppFormOption({required this.value, this.translatedValue});

  final String value;
  final String? translatedValue;

  String get label => translatedValue ?? value;
}

/// Document picked/selected for a `file` type form field.
class AgentDocuments {
  AgentDocuments({
    required this.name,
    this.file,
    this.id,
    this.isExisting = false,
  });

  final String name;
  final String? file;
  final int? id;
  final bool isExisting;
}

Map<String, dynamic> prepareDocumentForFormField(
  int fieldId,
  AgentDocuments? document,
) {
  if (document != null) {
    if (document.isExisting) {
      return {'id': fieldId.toString(), 'value': document.name};
    } else if (document.file != null) {
      return {
        'id': fieldId.toString(),
        'value': MultipartFile.fromFileSync(
          document.file!,
          filename: document.name,
        ),
      };
    }
  }
  return {};
}

/// Whether a form field should use the numeric keyboard: `number` fields, and
/// text fields whose name is a mobile/phone number.
bool isNumericAgentFormField(String fieldName, String fieldType) {
  if (fieldType == 'number') return true;
  final lower = fieldName.toLowerCase();
  return lower.contains('mobile') || lower.contains('phone');
}

/// Field title with the trailing required (*) marker.
class AgentFormFieldTitle extends StatelessWidget {
  const AgentFormFieldTitle(this.title, {this.isRequired = true, super.key});

  final String title;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomText(
          title,
          fontSize: context.font.sm,
          fontWeight: .w500,
        ),
        if (isRequired) ...[
          SizedBox(width: 4.rw(context)),
          HelperUtils.requiredSymbol(context),
        ],
      ],
    );
  }
}

/// Single-select radio group, styled like become_agent_form_screen.
class AgentRadioGroupFormField extends StatelessWidget {
  const AgentRadioGroupFormField({
    required this.title,
    required this.options,
    required this.onChanged,
    this.initialValue,
    this.fieldKey,
    this.isRequired = true,
    super.key,
  });

  final String title;
  final List<AppFormOption> options;
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final Key? fieldKey;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: fieldKey,
      initialValue: initialValue,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$title ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: .start,
          children: [
            AgentFormFieldTitle(title, isRequired: isRequired),
            SizedBox(height: 4.rh(context)),
            ...options.map(
              (option) => RadioGroup<String>(
                groupValue: state.value,
                onChanged: (value) {
                  state.didChange(value);
                  onChanged(value);
                },
                child: Material(
                  color: Colors.transparent,
                  child: RadioListTile(
                    radioScaleFactor: 1.1,
                    dense: true,
                    activeColor: context.color.tertiaryColor,
                    controlAffinity: .trailing,
                    title: CustomText(
                      option.label,
                      fontSize: context.font.sm,
                      color: state.hasError
                          ? context.color.error
                          : context.color.textLightColor,
                    ),
                    value: option.value,
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, start: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }
}

/// Multi-select checkbox group.
class AgentCheckboxGroupFormField extends StatelessWidget {
  const AgentCheckboxGroupFormField({
    required this.title,
    required this.options,
    required this.onChanged,
    this.initialValues = const [],
    this.fieldKey,
    this.isRequired = true,
    super.key,
  });

  final String title;
  final List<AppFormOption> options;
  final List<String> initialValues;
  final ValueChanged<List<String>> onChanged;
  final Key? fieldKey;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      key: fieldKey,
      initialValue: initialValues,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$title ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: .start,
          children: [
            AgentFormFieldTitle(title, isRequired: isRequired),
            SizedBox(height: 4.rh(context)),
            ...options.map(
              (option) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError
                        ? context.color.error
                        : context.color.borderColor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Material(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                  clipBehavior: Clip.antiAlias,
                  child: CheckboxListTile(
                    dense: true,
                    activeColor: context.color.tertiaryColor,
                    title: CustomText(
                      option.label,
                      fontSize: context.font.sm,
                      fontWeight: .w400,
                      color: context.color.textLightColor,
                    ),
                    value: state.value!.contains(option.value),
                    onChanged: (checked) {
                      final newValue = List<String>.from(state.value!);
                      if (checked!) {
                        newValue.add(option.value);
                      } else {
                        newValue.remove(option.value);
                      }
                      state.didChange(newValue);
                      onChanged(newValue);
                    },
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }
}

/// Dropdown select field.
class AgentDropdownFormField extends StatelessWidget {
  const AgentDropdownFormField({
    required this.title,
    required this.options,
    required this.onChanged,
    this.initialValue,
    this.fieldKey,
    this.isRequired = true,
    super.key,
  });

  final String title;
  final List<AppFormOption> options;
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final Key? fieldKey;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return FormField<String>(
      key: fieldKey,
      initialValue: initialValue ?? options.first.value,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$title ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: .start,
          children: [
            AgentFormFieldTitle(title, isRequired: isRequired),
            SizedBox(height: 4.rh(context)),
            DropdownButtonHideUnderline(
              child: Container(
                width: context.screenWidth,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError
                        ? context.color.error
                        : context.color.borderColor,
                  ),
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<String>(
                  isDense: true,
                  icon: Icon(Icons.keyboard_arrow_down, size: 24.rh(context)),
                  padding: const EdgeInsets.all(4),
                  borderRadius: BorderRadius.circular(4),
                  elevation: 1,
                  dropdownColor: context.color.secondaryColor,
                  isExpanded: true,
                  value: state.value,
                  items: options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.value,
                      child: CustomText(
                        option.label,
                        fontSize: context.font.xs,
                        color: context.color.textLightColor,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    state.didChange(value);
                    onChanged(value);
                  },
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }
}

/// Text / number / textarea field.
class AgentTextFormField extends StatelessWidget {
  const AgentTextFormField({
    required this.title,
    required this.controller,
    required this.onChange,
    this.isNumber = false,
    this.isMultiline = false,
    this.isRequired = true,
    this.validator,
    super.key,
  });

  final String title;
  final TextEditingController controller;
  final dynamic Function(dynamic value) onChange;
  final bool isNumber;
  final bool isMultiline;
  final bool isRequired;
  final CustomTextFieldValidator? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        AgentFormFieldTitle(title, isRequired: isRequired),
        SizedBox(height: 4.rh(context)),
        CustomTextFormField(
          hintText: '${'enter'.translate(context)} $title',
          controller: controller,
          action: isMultiline ? .newline : .next,
          validator: isRequired
              ? (validator ?? CustomTextFieldValidator.nullCheck)
              : validator,
          onChange: onChange,
          keyboard: isMultiline
              ? TextInputType.multiline
              : isNumber
              ? TextInputType.number
              : TextInputType.text,
          formaters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          maxLine: isMultiline ? 25 : null,
          minLine: isMultiline ? 5 : null,
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }
}

/// Chips form field for freeform tags like "Service Areas", "Languages Spoken".
class AgentChipsFormField extends StatefulWidget {
  const AgentChipsFormField({
    required this.title,
    required this.onChanged,
    this.initialValues = const [],
    this.isRequired = true,
    this.hintText,
    super.key,
  });

  final String title;
  final List<String> initialValues;
  final ValueChanged<List<String>> onChanged;
  final bool isRequired;
  final String? hintText;

  @override
  State<AgentChipsFormField> createState() => _AgentChipsFormFieldState();
}

class _AgentChipsFormFieldState extends State<AgentChipsFormField> {
  late final List<String> _chips;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chips = List<String>.from(widget.initialValues);
  }

  @override
  void didUpdateWidget(covariant AgentChipsFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValues.length != oldWidget.initialValues.length ||
        !widget.initialValues.every(
          (e) => oldWidget.initialValues.contains(e),
        )) {
      _chips = List<String>.from(widget.initialValues);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addChip(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final parts = trimmed
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    setState(() {
      for (final part in parts) {
        if (!_chips.contains(part)) {
          _chips.add(part);
        }
      }
      _inputController.clear();
    });
    widget.onChanged(_chips);
  }

  void _removeChip(int index) {
    setState(() {
      _chips.removeAt(index);
    });
    widget.onChanged(_chips);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: _chips,
      validator: (val) {
        if (widget.isRequired && _chips.isEmpty) {
          return '${widget.title} ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentFormFieldTitle(widget.title, isRequired: widget.isRequired),
            SizedBox(height: 6.rh(context)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.hasError
                      ? context.color.error
                      : context.color.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_chips.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_chips.length, (index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.color.tertiaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.color.tertiaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                _chips[index],
                                fontSize: context.font.xs,
                                fontWeight: FontWeight.w500,
                                color: context.color.textColorDark,
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _removeChip(index);
                                  state.didChange(_chips);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: context.color.textColorDark.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 8.rh(context)),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText:
                                widget.hintText ??
                                '${'enter'.translate(context)} ${widget.title}',
                            hintStyle: TextStyle(
                              fontSize: context.font.xs,
                              color: context.color.textLightColor,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: context.font.sm,
                            color: context.color.textColorDark,
                          ),
                          onSubmitted: (value) {
                            _addChip(value);
                            state.didChange(_chips);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle,
                          color: context.color.tertiaryColor,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _addChip(_inputController.text);
                          state.didChange(_chips);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }
}

/// Time picker form field for "Working Hours Start", "Working Hours End".
/// Formats value as "HH:MM" (24-hour clock).
class AgentTimeFormField extends StatelessWidget {
  const AgentTimeFormField({
    required this.title,
    required this.initialValue,
    required this.onChanged,
    this.isRequired = false,
    super.key,
  });

  final String title;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('time_${title}_$initialValue'),
      initialValue: initialValue,
      validator: (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return '$title ${'isRequired'.translate(context)}';
        }
        if (val != null && val.trim().isNotEmpty) {
          final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
          if (!timeRegex.hasMatch(val.trim())) {
            return 'Invalid time format, expected HH:MM';
          }
        }
        return null;
      },
      builder: (state) {
        final displayTime = state.value ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentFormFieldTitle(title, isRequired: isRequired),
            SizedBox(height: 4.rh(context)),
            GestureDetector(
              onTap: () async {
                var initial = const TimeOfDay(hour: 9, minute: 0);
                if (displayTime.isNotEmpty && displayTime.contains(':')) {
                  final parts = displayTime.split(':');
                  final h = int.tryParse(parts[0]);
                  final m = int.tryParse(parts[1]);
                  if (h != null && m != null) {
                    initial = TimeOfDay(hour: h, minute: m);
                  }
                }
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  state.didChange(formatted);
                  onChanged(formatted);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: state.hasError
                        ? context.color.error
                        : context.color.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: context.color.textLightColor,
                    ),
                    SizedBox(width: 10.rw(context)),
                    Expanded(
                      child: CustomText(
                        displayTime.isNotEmpty
                            ? displayTime
                            : '${'select'.translate(context)} $title (HH:MM)',
                        fontSize: context.font.sm,
                        color: displayTime.isNotEmpty
                            ? context.color.textColorDark
                            : context.color.textLightColor,
                      ),
                    ),
                    if (displayTime.isNotEmpty && !isRequired)
                      GestureDetector(
                        onTap: () {
                          state.didChange('');
                          onChanged('');
                        },
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: context.color.textLightColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }
}

/// Social Link form field for dynamic social media platforms.
/// Never required. Validates URL format if provided.
class AgentSocialLinkFormField extends StatelessWidget {
  const AgentSocialLinkFormField({
    required this.title,
    required this.controller,
    required this.onChange,
    this.iconUrl,
    super.key,
  });

  final String title;
  final TextEditingController controller;
  final ValueChanged<String> onChange;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (iconUrl != null && iconUrl!.isNotEmpty) ...[
              Container(
                width: 22.rw(context),
                height: 22.rh(context),
                margin: EdgeInsetsDirectional.only(end: 8.rw(context)),
                child: CustomImage(
                  imageUrl: iconUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            CustomText(
              title,
              fontSize: context.font.sm,
              fontWeight: .w500,
            ),
          ],
        ),
        SizedBox(height: 4.rh(context)),
        CustomTextFormField(
          hintText: 'https://...',
          controller: controller,
          action: TextInputAction.next,
          keyboard: TextInputType.url,
          onChange: (value) => onChange(value?.toString() ?? ''),
          validator: CustomTextFieldValidator.link,
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }
}

/// Upload picker for `file` type form fields, shared across agent/user
/// verification forms. Behavioural differences between screens are exposed
/// via flags instead of duplicating the widget.
class AgentDocumentPickerField extends StatefulWidget {
  const AgentDocumentPickerField({
    required this.onDocumentSelected,
    this.label,
    this.initialDocument,
    this.showExistingFileName = false,
    this.showDownloadLink = false,
    this.allowedExtensions = const [
      'pdf',
      'doc',
      'docx',
      'jpg',
      'jpeg',
      'png',
      'webp',
    ],
    super.key,
  });

  /// Defaults to `UploadDocs`.
  final String? label;
  final AgentDocuments? initialDocument;
  final void Function(AgentDocuments?) onDocumentSelected;

  /// When true, an existing document shows its file name instead of the
  /// generic "existingDocument" translation.
  final bool showExistingFileName;
  final bool showDownloadLink;
  final List<String> allowedExtensions;

  @override
  State<AgentDocumentPickerField> createState() =>
      _AgentDocumentPickerFieldState();
}

class _AgentDocumentPickerFieldState extends State<AgentDocumentPickerField> {
  AgentDocuments? selectedDocument;

  @override
  void initState() {
    super.initState();
    selectedDocument = widget.initialDocument;
  }

  @override
  void didUpdateWidget(covariant AgentDocumentPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Prefilled values can arrive after the first build (e.g. re-registering).
    if (widget.initialDocument != oldWidget.initialDocument &&
        widget.initialDocument != null) {
      selectedDocument = widget.initialDocument;
    }
  }

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

  bool _isImage(String path) {
    final clean = path.split('?').first.toLowerCase();
    return _imageExtensions.contains(clean.split('.').last);
  }

  /// Image provider for previewing the selected document, or null when the
  /// document is not an image (pdf/doc) or has no usable source.
  ImageProvider? get _previewProvider {
    final doc = selectedDocument;
    if (doc == null) return null;
    final localPath = doc.file;
    if (localPath != null && localPath.isNotEmpty) {
      return _isImage(localPath) ? FileImage(File(localPath)) : null;
    }
    final url = doc.name.trim();
    if (doc.isExisting && url.startsWith('http') && _isImage(url)) {
      return CachedNetworkImageProvider(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewProvider;
    return Column(
      crossAxisAlignment: .start,
      children: [
        GestureDetector(
          onTap: _pickDocument,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: context.color.textLightColor,
                  radius: const Radius.circular(4),
                ),
                child: SizedBox(
                  width: 48.rh(context),
                  height: 48.rw(context),
                  child: preview == null
                      ? Center(
                          child: Icon(
                            Icons.upload,
                            color: context.color.textLightColor,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => UiUtils.showFullScreenImage(
                            context,
                            provider: preview,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image(
                              image: preview,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  Icons.upload,
                                  color: context.color.textLightColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(widget.label ?? 'UploadDocs'.translate(context)),
                    SizedBox(height: 4.rh(context)),
                    CustomText(
                      _subtitle(context),
                      color: context.color.textLightColor,
                      fontSize: context.font.xs,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.showDownloadLink && selectedDocument?.isExisting == true)
          Padding(
            padding: EdgeInsets.only(top: 8.rh(context)),
            child: DownloadableDocuments(url: selectedDocument!.name),
          ),
      ],
    );
  }

  String _subtitle(BuildContext context) {
    if (selectedDocument == null) return 'noFileSelected'.translate(context);
    if (selectedDocument!.isExisting) {
      return widget.showExistingFileName
          ? selectedDocument!.name
          : 'existingDocument'.translate(context);
    }
    return 'oneFileSelected'.translate(context);
  }

  Future<void> _pickDocument() async {
    try {
      final file = await AppFilePicker.pickFile(
        allowedExtensions: widget.allowedExtensions,
      );
      if (file != null) {
        setState(() {
          selectedDocument = AgentDocuments(name: file.name, file: file.path);
        });
        widget.onDocumentSelected(selectedDocument);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
