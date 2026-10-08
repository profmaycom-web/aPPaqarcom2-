import 'dart:math' as math;

import 'package:ebroker/data/cubits/agents/fetch_watermark_settings_cubit.dart';
import 'package:ebroker/data/cubits/agents/update_watermark_settings_cubit.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/watermark_settings_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// Two-step watermark settings screen:
///  Step 1 – Upload watermark image
///  Step 2 – Live preview + configure all settings + save
class WatermarkSettingsScreen extends StatefulWidget {
  const WatermarkSettingsScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              final cubit = FetchWatermarkSettingsCubit();
              unawaited(cubit.fetch());
              return cubit;
            },
          ),
          BlocProvider(create: (_) => UpdateWatermarkSettingsCubit()),
        ],
        child: const WatermarkSettingsScreen(),
      ),
    );
  }

  @override
  State<WatermarkSettingsScreen> createState() =>
      _WatermarkSettingsScreenState();
}

class _WatermarkSettingsScreenState extends State<WatermarkSettingsScreen> {
  // ── Step ──────────────────────────────────────────────────────────────────
  int _step = 0; // 0 = upload, 1 = configure

  // ── Form state ────────────────────────────────────────────────────────────
  bool _enabled = true;
  double _opacity = 40;
  double _size = 42;
  String _style = 'single';
  String _position = 'center';
  double _rotation = 0;
  File? _newImageFile;
  String? _existingImageUrl;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  static const int _maxFileSizeMb = 3;

  static const _styleOptions = ['single', 'tile'];
  static const _positionOptions = [
    'center',
    'top-left',
    'top-right',
    'bottom-left',
    'bottom-right',
  ];

  // ── Populate from API ─────────────────────────────────────────────────────
  void _populate(WatermarkSettingsModel m) {
    _enabled = m.watermarkEnabled;
    _opacity = m.watermarkOpacity.clamp(1, 100);
    _size = m.watermarkSize.clamp(1, 100);
    _style = _styleOptions.contains(m.watermarkStyle)
        ? m.watermarkStyle
        : 'single';
    _position = _positionOptions.contains(m.watermarkPosition)
        ? m.watermarkPosition
        : 'center';
    _rotation = m.watermarkRotation.clamp(0, 360);
    _existingImageUrl = m.watermarkImage;
    _newImageFile = null;
    // If there is already an image configured, jump straight to step 2
    if ((m.watermarkImage ?? '').isNotEmpty) _step = 1;
  }

  bool get _hasImage =>
      _newImageFile != null || (_existingImageUrl ?? '').isNotEmpty;

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      final bytes = await picked.length();
      if (bytes > _maxFileSizeMb * 1024 * 1024) {
        HelperUtils.showSnackBarMessage(
          context,
          type: .error,
          '${'fileSizeExceedsLimit'.translate(context)} $_maxFileSizeMb MB',
        );
        return;
      }
      setState(() {
        _newImageFile = File(picked.path);
        _enabled = true; // Auto-enable watermark when a new image is selected
        // Auto-advance to step 2 after picking
        _step = 1;
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_checkPackageCubit.state is CheckPackageInProgress) {
      return;
    }

    final packageAvailable = await _checkPackageCubit.checkAvailability(
      packageType: PackageType.agentWatermark,
    );

    if (_checkPackageCubit.state is CheckPackageFail) {
      if (context.mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          (_checkPackageCubit.state as CheckPackageFail).error,
          type: .error,
        );
      }
      return;
    }

    if (!packageAvailable) {
      await UiUtils.showBlurredDialoge(
        context,
        dialog: const BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.agentWatermark,
          isAcceptContainesPush: true,
        ),
      );
      return;
    }
    await context.read<UpdateWatermarkSettingsCubit>().update(
      watermarkEnabled: _enabled,
      watermarkOpacity: _opacity,
      watermarkSize: _size,
      watermarkStyle: _style,
      watermarkPosition: _position,
      watermarkRotation: _rotation,
      watermarkImage: _newImageFile,
    );
  }

  // ── Label helpers ─────────────────────────────────────────────────────────
  String _positionLabel(String value) => switch (value) {
    'center' => 'wmPositionCenter'.translate(context),
    'top-left' => 'wmPositionTopLeft'.translate(context),
    'top-right' => 'wmPositionTopRight'.translate(context),
    'bottom-left' => 'wmPositionBottomLeft'.translate(context),
    'bottom-right' => 'wmPositionBottomRight'.translate(context),
    _ => value,
  };

  String _styleLabel(String value) => switch (value) {
    'single' => 'wmStyleSingle'.translate(context),
    'tile' => 'wmStyleTile'.translate(context),
    _ => value,
  };

  // ── Build ─────────────────────────────────────────────────────────────────
  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      FetchWatermarkSettingsCubit,
      FetchWatermarkSettingsState
    >(
      listener: (context, state) {
        if (state is FetchWatermarkSettingsSuccess) {
          setState(() => _populate(state.settings));
        }
      },
      builder: (context, fetchState) {
        return BlocConsumer<
          UpdateWatermarkSettingsCubit,
          UpdateWatermarkSettingsState
        >(
          listener: (context, updateState) {
            if (updateState is UpdateWatermarkSettingsSuccess) {
              HelperUtils.showSnackBarMessage(
                context,
                'wmSavedSuccess'.translate(context),
                type: .success,
              );
              Navigator.pop(context);
            } else if (updateState is UpdateWatermarkSettingsFailure) {
              HelperUtils.showSnackBarMessage(
                context,
                updateState.errorMessage,
                type: MessageType.error,
              );
            }
          },
          builder: (context, updateState) {
            final isUpdating = updateState is UpdateWatermarkSettingsInProgress;

            return Scaffold(
              backgroundColor: context.color.primaryColor,
              appBar: CustomAppBar(
                title: 'watermarkSettings'.translate(context),
              ),
              body: Builder(
                builder: (context) {
                  if (fetchState is FetchWatermarkSettingsInProgress) {
                    return _buildShimmer(context);
                  }
                  if (fetchState is FetchWatermarkSettingsFailure) {
                    return _buildError(context, fetchState.errorMessage);
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _buildStep1(context)
                        : _buildStep2(context),
                  );
                },
              ),
              bottomNavigationBar: fetchState is FetchWatermarkSettingsSuccess
                  ? _buildBottomNavigationBar(context, isUpdating)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget? _buildBottomNavigationBar(BuildContext context, bool isUpdating) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          border: Border(
            top: BorderSide(
              color: context.color.borderColor,
              width: 0.5,
            ),
          ),
        ),
        child: _step == 0
            ? UiUtils.buildButton(
                context,
                onPressed: () => setState(() => _step = 1),
                height: 48.rh(context),
                fontSize: context.font.md,
                buttonTitle: 'next'.translate(context),
                disabled: !_hasImage,
              )
            : Row(
                children: [
                  Expanded(
                    child: UiUtils.buildButton(
                      context,
                      height: 48.rh(context),
                      fontSize: context.font.md,
                      onPressed: () => setState(() => _step = 0),
                      textColor: context.color.tertiaryColor,
                      buttonColor: context.color.secondaryColor,
                      border: BorderSide(color: context.color.tertiaryColor),
                      buttonTitle: 'wmWatermarkImage'.translate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<CheckPackageCubit, CheckPackageState>(
                      bloc: _checkPackageCubit,
                      builder: (context, checkPackageState) {
                        return UiUtils.buildButton(
                          context,
                          height: 48.rh(context),
                          fontSize: context.font.md,
                          onPressed: () => unawaited(_submit()),
                          isInProgress:
                              isUpdating ||
                              checkPackageState is CheckPackageInProgress,
                          buttonTitle: 'submitBtnLbl'.translate(context),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 1 – Upload
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      physics: Constant.scrollPhysics,
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.rw(context)),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.rw(context)),
              border: Border.all(
                color: context.color.tertiaryColor.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: context.color.tertiaryColor,
                  size: 18,
                ),
                SizedBox(width: 8.rw(context)),
                Expanded(
                  child: CustomText(
                    'wmUploadHint'.translate(context),
                    fontSize: context.font.xs,
                    color: context.color.textColorDark.withValues(alpha: 0.7),
                    maxLines: 4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.rh(context)),
          Row(
            spacing: 4.rw(context),
            mainAxisAlignment: .spaceBetween,
            children: [
              CustomText(
                'wmWatermarkImage'.translate(context),
                fontSize: context.font.sm,
                fontWeight: FontWeight.w600,
              ),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: .all(4.rw(context)),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    border: Border.all(
                      color: context.color.textLightColor,
                    ),
                    borderRadius: .circular(4.rw(context)),
                  ),
                  child: CustomImage(
                    imageUrl: AppIcons.edit,
                    height: 16.rh(context),
                    fit: .contain,
                    color: context.color.textColorDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.rh(context)),

          // Upload zone
          if (_hasImage)
            if (_newImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.rw(context)),
                child: Image.file(
                  _newImageFile!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8.rw(context)),
                child: CustomImage(
                  imageUrl: _existingImageUrl!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: context.color.tertiaryColor,
                      ),
                    ),
                    SizedBox(height: 16.rh(context)),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: context.font.sm,
                          color: context.color.textColorDark.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        children: [
                          TextSpan(
                            text: 'wmDropOrBrowsePrefix'.translate(
                              context,
                            ),
                          ),
                          TextSpan(
                            text: 'wmBrowse'.translate(context),
                            style: TextStyle(
                              color: context.color.tertiaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.rh(context)),
                    CustomText(
                      'wmUploadFormats'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textColorDark.withValues(
                        alpha: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.rh(context)),
                    CustomText(
                      'wmMaxFileSize'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textColorDark.withValues(
                        alpha: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 2 – Configure + Preview
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2(BuildContext context) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Preview card (Sticky) ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            16.rw(context),
            16.rh(context),
            16.rw(context),
            0,
          ),
          child: _buildPreviewCard(context),
        ),
        SizedBox(height: 16.rh(context)),

        // ── Settings (Scrollable) ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            padding: EdgeInsets.fromLTRB(
              16.rw(context),
              0,
              16.rw(context),
              32.rh(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Enable toggle ───────────────────────────────────────────
                _buildCard(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'wmEnableWatermark'.translate(context),
                              fontWeight: FontWeight.w600,
                              fontSize: context.font.sm,
                            ),
                            SizedBox(height: 2.rh(context)),
                            CustomText(
                              'wmEnableSubtitle'.translate(context),
                              fontSize: context.font.xs,
                              color: context.color.textColorDark.withValues(
                                alpha: 0.55,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.rw(context)),
                      UiSwitch(
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.rh(context)),

                // ── Adjustments ─────────────────────────────────────────────
                _buildSlidersCard(context),
                SizedBox(height: 14.rh(context)),

                // ── Style ───────────────────────────────────────────────────
                _buildLabeledField(
                  context,
                  label: 'wmStyle'.translate(context),
                  child: _buildDropdown(
                    context,
                    value: _style,
                    items: _styleOptions,
                    labelBuilder: _styleLabel,
                    onChanged: (v) => setState(() => _style = v),
                  ),
                ),
                SizedBox(height: 14.rh(context)),

                // ── Position ────────────────────────────────────────────────
                // Position only applies to single-placement watermarks;
                // when style is 'tile' the watermark fills the entire image
                // so the position field is hidden.
                if (_style != 'tile') ...[
                  _buildLabeledField(
                    context,
                    label: 'wmPosition'.translate(context),
                    child: _buildDropdown(
                      context,
                      value: _position,
                      items: _positionOptions,
                      labelBuilder: _positionLabel,
                      onChanged: (v) => setState(() => _position = v),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Live Preview ──────────────────────────────────────────────────────────
  Widget _buildPreviewCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'wmPreview'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: 8.rh(context)),
        Container(
          width: double.infinity,
          height: 220.rh(context),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.color.borderColor),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Preview Image
              CustomImage(
                imageUrl: AppSettings.loginBackground,
                width: double.infinity,
                height: double.infinity,
              ),

              // Grid lines to mimic a property photo
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(context.color.borderColor),
                ),
              ),
              // Watermark overlay
              if (_enabled && _hasImage)
                Positioned.fill(
                  child: _WatermarkOverlay(
                    imageFile: _newImageFile,
                    imageUrl: _existingImageUrl,
                    opacity: _opacity / 100,
                    size: _size / 100,
                    position: _position,
                    rotation: _rotation,
                    style: _style,
                  ),
                ),
              // Disabled badge
              if (!_enabled)
                Positioned(
                  top: 8.rh(context),
                  right: 8.rw(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.rw(context),
                      vertical: 4.rh(context),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8.rw(context)),
                    ),
                    child: CustomText(
                      'wmDisabledBadge'.translate(context),
                      fontSize: context.font.xs,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12.rw(context)),
        border: Border.all(color: context.color.borderColor),
      ),
      child: child,
    );
  }

  Widget _buildLabeledField(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: 8.rh(context)),
        child,
      ],
    );
  }

  Widget _buildSlidersCard(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Opacity ─────────────────────────────────────────────────
          _buildCompactSlider(
            context,
            label: '${'wmOpacity'.translate(context)} (${_opacity.round()}%)',
            value: _opacity,
            min: 1,
            max: 100,
            onChanged: (v) => setState(() => _opacity = v),
          ),
          SizedBox(height: 12.rh(context)),

          // ── Size ────────────────────────────────────────────────────
          _buildCompactSlider(
            context,
            label: '${'wmSize'.translate(context)} (${_size.round()}%)',
            value: _size,
            min: 1,
            max: 100,
            onChanged: (v) => setState(() => _size = v),
          ),
          SizedBox(height: 12.rh(context)),

          // ── Rotation ────────────────────────────────────────────────
          _buildCompactSlider(
            context,
            label: '${'wmRotation'.translate(context)} (${_rotation.round()}°)',
            value: _rotation,
            min: 0,
            max: 360,
            onChanged: (v) => setState(() => _rotation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: context.font.xs,
          fontWeight: FontWeight.w600,
          color: context.color.textColorDark.withValues(alpha: 0.8),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: context.color.tertiaryColor,
            inactiveTrackColor: context.color.tertiaryColor.withValues(
              alpha: 0.15,
            ),
            thumbColor: context.color.tertiaryColor,
            overlayColor: context.color.tertiaryColor.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String value,
    required List<String> items,
    required String Function(String) labelBuilder,
    required void Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.color.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.color.textColorDark.withValues(alpha: 0.6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.rw(context),
            vertical: 4.rh(context),
          ),
          borderRadius: BorderRadius.circular(12.rw(context)),
          dropdownColor: context.color.secondaryColor,
          style: TextStyle(
            color: context.color.textColorDark,
            fontSize: context.font.sm,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (v) => onChanged(v!),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── Loading / error ───────────────────────────────────────────────────────
  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        children: [
          CustomShimmer(height: 52.rh(context)),
          SizedBox(height: 16.rh(context)),
          CustomShimmer(height: 200.rh(context)),
          SizedBox(height: 16.rh(context)),
          CustomShimmer(height: 52.rh(context)),
          SizedBox(height: 16.rh(context)),
          CustomShimmer(height: 52.rh(context)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.all(24.rw(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            message,
            textAlign: TextAlign.center,
            color: context.color.textColorDark.withValues(alpha: 0.6),
          ),
          SizedBox(height: 12.rh(context)),
          TextButton(
            onPressed: () =>
                context.read<FetchWatermarkSettingsCubit>().fetch(),
            child: CustomText(
              'retry'.translate(context),
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Watermark overlay widget (live preview)
// ─────────────────────────────────────────────────────────────────────────────
class _WatermarkOverlay extends StatelessWidget {
  const _WatermarkOverlay({
    required this.opacity,
    required this.size,
    required this.position,
    required this.rotation,
    required this.style,
    this.imageFile,
    this.imageUrl,
  });

  final double opacity;
  final double size;
  final String position;
  final double rotation;
  final String style;
  final File? imageFile;
  final String? imageUrl;

  Alignment _toAlignment() => switch (position) {
    'top-left' => Alignment.topLeft,
    'top-right' => Alignment.topRight,
    'bottom-left' => Alignment.bottomLeft,
    'bottom-right' => Alignment.bottomRight,
    _ => Alignment.center,
  };

  @override
  Widget build(BuildContext context) {
    Widget buildWatermarkImage() => imageFile != null
        ? Image.file(
            imageFile!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image_outlined,
              color: context.color.textColorDark.withValues(alpha: 0.3),
            ),
          )
        : (imageUrl != null && imageUrl!.isNotEmpty)
        ? CustomImage(imageUrl: imageUrl!)
        : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (style == 'tile') {
          final wmSize = constraints.maxWidth * size * 0.35;
          return Opacity(
            opacity: opacity,
            child: TileWatermark(
              wmSize: wmSize,
              rotation: rotation,
              imageBuilder: buildWatermarkImage,
            ),
          );
        }

        // Single or Center
        final alignment = style == 'center' ? Alignment.center : _toAlignment();
        final wmSize = constraints.maxWidth * size * 0.5;

        return Padding(
          padding: EdgeInsets.all(12.rw(context)),
          child: Align(
            alignment: alignment,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: rotation * math.pi / 180,
                child: SizedBox(
                  width: wmSize,
                  height: wmSize,
                  child: buildWatermarkImage(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders the watermark image in a tiled grid pattern.
class TileWatermark extends StatelessWidget {
  const TileWatermark({
    required this.wmSize,
    required this.rotation,
    required this.imageBuilder,
    super.key,
  });

  final double wmSize;
  final double rotation;
  final Widget Function() imageBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = (constraints.maxWidth / (wmSize + 16)).ceil() + 1;
        final rows = (constraints.maxHeight / (wmSize + 16)).ceil() + 1;
        return Stack(
          children: [
            for (int r = 0; r < rows; r++)
              for (int c = 0; c < cols; c++)
                Positioned(
                  left: c * (wmSize + 16) - wmSize / 2,
                  top: r * (wmSize + 16) - wmSize / 2,
                  width: wmSize,
                  height: wmSize,
                  child: Transform.rotate(
                    angle: rotation * math.pi / 180,
                    child: imageBuilder(),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Light grid lines painted on the preview background.
class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const cols = 8;
    const rows = 5;

    final colWidth = size.width / cols;
    final rowHeight = size.height / rows;

    for (var i = 1; i < cols; i++) {
      final x = colWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var j = 1; j < rows; j++) {
      final y = rowHeight * j;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
