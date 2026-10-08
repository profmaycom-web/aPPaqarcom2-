import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/data/cubits/agents/update_agent_profile_cubit.dart';
import 'package:ebroker/data/model/agent/social_media_link_model.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/image_cropper.dart';
import 'package:ebroker/ui/screens/widgets/phone_field.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class EditAgentProfileScreen extends StatefulWidget {
  const EditAgentProfileScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => UpdateAgentProfileCubit()),
        ],
        child: const EditAgentProfileScreen(),
      ),
    );
  }

  @override
  State<EditAgentProfileScreen> createState() => _EditAgentProfileScreenState();
}

class _EditAgentProfileScreenState extends State<EditAgentProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final Map<int, TextEditingController> _socialControllers = {};
  final Map<int, String> _initialSocialUrls = {};
  List<SocialMediaLinkModel> _socialMediaLinks = [];

  // Business tab controllers
  final TextEditingController _serviceAreaInputController =
      TextEditingController();
  final TextEditingController _languageInputController =
      TextEditingController();
  List<String> _serviceAreasChips = [];
  List<String> _languagesChips = [];
  final TextEditingController _experienceController = TextEditingController();
  String? _startTime;
  String? _endTime;

  int _selectedTab = 0; // 0 for Personal, 1 for Business
  bool _isSocialMediaEnabled = true;

  File? _profilePhoto;
  File? _agentBanner;
  String? _currentProfileUrl;
  String? _currentBannerUrl;
  String? selectedCountryCode = HiveUtils.getUserDetails().countryCode ?? '';

  @override
  void initState() {
    super.initState();
    final cached = HiveUtils.getAgentProfileData();
    if (cached != null) {
      _populateFields(cached);
    }
    final currentCubitState = context.read<AgentProfileCubit>().state;
    if (currentCubitState is AgentProfileSuccess) {
      _populateFields(currentCubitState.agentProfile);
    }
    unawaited(context.read<AgentProfileCubit>().fetchAgentProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _aboutMeController.dispose();
    for (final controller in _socialControllers.values) {
      controller.dispose();
    }
    _serviceAreaInputController.dispose();
    _languageInputController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _populateFields(AgentProfileModel profile) {
    if (profile.agentName?.isNotEmpty ?? false) {
      _nameController.text = profile.agentName!;
    }
    if (profile.agentEmail?.isNotEmpty ?? false) {
      _emailController.text = profile.agentEmail!;
    }
    if (profile.agentMobile?.isNotEmpty ?? false) {
      _mobileController.text = profile.agentMobile!;
    }
    if (profile.agentAddress?.isNotEmpty ?? false) {
      _addressController.text = profile.agentAddress!;
    }
    if (profile.aboutMe?.isNotEmpty ?? false) {
      _aboutMeController.text = profile.aboutMe!;
    }
    if (profile.socialMediaLinks.isNotEmpty) {
      _socialMediaLinks = profile.socialMediaLinks;
      for (final link in _socialMediaLinks) {
        final initialUrl = link.url ?? '';
        _initialSocialUrls[link.id] = initialUrl;
        _socialControllers[link.id] = TextEditingController(text: initialUrl);
      }
      if (_socialMediaLinks.any((e) => (e.url ?? '').isNotEmpty)) {
        _isSocialMediaEnabled = true;
      }
    }
    final areasStr = profile.serviceAreas?.trim() ?? '';
    if (areasStr.isNotEmpty) {
      _serviceAreasChips = areasStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final langsStr = profile.languages?.trim() ?? '';
    if (langsStr.isNotEmpty) {
      _languagesChips = langsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (profile.experience?.isNotEmpty ?? false) {
      _experienceController.text = profile.experience!;
    }
    if (profile.startTime?.isNotEmpty ?? false) {
      _startTime = profile.startTime;
    }
    if (profile.endTime?.isNotEmpty ?? false) {
      _endTime = profile.endTime;
    }
    if (profile.agentProfilePhoto?.isNotEmpty ?? false) {
      _currentProfileUrl = profile.agentProfilePhoto;
    }
    if (profile.agentBanner?.isNotEmpty ?? false) {
      _currentBannerUrl = profile.agentBanner;
    }
    setState(() {});
  }

  void _capturePendingChips() {
    if (_serviceAreaInputController.text.trim().isNotEmpty) {
      _addServiceAreaChip(_serviceAreaInputController.text.trim());
      _serviceAreaInputController.clear();
    }
    if (_languageInputController.text.trim().isNotEmpty) {
      _addLanguageChip(_languageInputController.text.trim());
      _languageInputController.clear();
    }
  }

  void _addServiceAreaChip(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final parts =
        trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    setState(() {
      for (final part in parts) {
        if (!_serviceAreasChips.contains(part)) {
          _serviceAreasChips.add(part);
        }
      }
    });
  }

  void _removeServiceAreaChip(int index) {
    setState(() {
      _serviceAreasChips.removeAt(index);
    });
  }

  void _addLanguageChip(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final parts =
        trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    setState(() {
      for (final part in parts) {
        if (!_languagesChips.contains(part)) {
          _languagesChips.add(part);
        }
      }
    });
  }

  void _removeLanguageChip(int index) {
    setState(() {
      _languagesChips.removeAt(index);
    });
  }

  Future<void> _submit() async {
    // Automatically capture any typed text still in input controllers
    if (_serviceAreaInputController.text.trim().isNotEmpty) {
      _addServiceAreaChip(_serviceAreaInputController.text.trim());
      _serviceAreaInputController.clear();
    }
    if (_languageInputController.text.trim().isNotEmpty) {
      _addLanguageChip(_languageInputController.text.trim());
      _languageInputController.clear();
    }

    // If user is on Business tab but Personal tab has empty required fields, switch to Personal tab
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      setState(() {
        _selectedTab = 0;
      });
      _formKey.currentState?.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final checkInternet = await HelperUtils.checkInternet();
    if (!checkInternet) {
      HelperUtils.showSnackBarMessage(context, 'lblchecknetwork', type: .error);
      return;
    }
    if (selectedCountryCode == null || selectedCountryCode == '') {
      setState(() {
        _selectedTab = 0;
      });
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectCountry'.translate(context),
        type: .error,
      );
      return;
    }

    final changedSocialLinks = <Map<String, dynamic>>[];
    if (_isSocialMediaEnabled) {
      for (final link in _socialMediaLinks) {
        final currentText = _socialControllers[link.id]?.text.trim() ?? '';
        final initialText = _initialSocialUrls[link.id]?.trim() ?? '';
        if (currentText != initialText) {
          changedSocialLinks.add({
            'id': link.id,
            'url': currentText.isEmpty ? null : currentText,
          });
        }
      }
    } else {
      for (final link in _socialMediaLinks) {
        final initialText = _initialSocialUrls[link.id]?.trim() ?? '';
        if (initialText.isNotEmpty) {
          changedSocialLinks.add({
            'id': link.id,
            'url': null,
          });
        }
      }
    }

    await context.read<UpdateAgentProfileCubit>().updateProfile(
      agentName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      countryCode: selectedCountryCode,
      address: _addressController.text.trim(),
      aboutMe: _aboutMeController.text.trim(),
      socialMediaLinks:
          changedSocialLinks.isNotEmpty ? changedSocialLinks : null,
      serviceAreas: _serviceAreasChips.join(','),
      languages: _languagesChips.join(','),
      experience: _experienceController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      profilePhoto: _profilePhoto,
      agentBanner: _agentBanner,
    );
  }

  Future<void> _showPicker({required bool isBanner}) async {
    final currentFile = isBanner ? _agentBanner : _profilePhoto;
    await CustomBottomSheet.show<void>(
      context: context,
      showDragHandle: false,
      borderRadius: 18,
      padding: .all(16.rw(context)),
      child: Column(
        mainAxisSize: .min,
        spacing: 8.rh(context),
        children: [
          _customTile(
            AppIcons.gallery,
            'gallery'.translate(context),
            () async {
              await _pickImage(ImageSource.gallery, isBanner: isBanner);
              Navigator.of(context).pop();
            },
          ),
          _customTile(
            AppIcons.eye,
            'camera'.translate(context),
            () async {
              await _pickImage(ImageSource.camera, isBanner: isBanner);
              Navigator.of(context).pop();
            },
          ),
          if (currentFile != null)
            _customTile(
              AppIcons.closeCircle,
              'lblremove'.translate(context),
              () {
                if (isBanner) {
                  _agentBanner = null;
                } else {
                  _profilePhoto = null;
                }
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _customTile(
    String icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 32.rh(context),
        child: Row(
          spacing: 8.rw(context),
          children: [
            CustomImage(
              imageUrl: icon,
              fit: .contain,
              height: 24,
              color: context.color.textColorDark,
            ),
            CustomText(
              title,
              color: context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource imageSource, {
    required bool isBanner,
  }) async {
    CropImage.context = context;
    final pickedFile = await ImagePicker().pickImage(source: imageSource);
    File? result;
    if (pickedFile != null) {
      final croppedFile = await CropImage.crop(
        filePath: pickedFile.path,
        aspectRatio: isBanner
            ? const CropAspectRatio(ratioX: 78, ratioY: 43)
            : const CropAspectRatio(ratioX: 1, ratioY: 1),
        lockAspectRatio: !isBanner,
      );
      if (croppedFile != null) {
        result = File(croppedFile.path);
      }
    }
    if (isBanner) {
      _agentBanner = result;
    } else {
      _profilePhoto = result;
    }
    setState(() {});
  }

  Widget _getProfileImage() {
    if (_profilePhoto != null) {
      return Image.file(_profilePhoto!, fit: BoxFit.cover);
    }
    if ((_currentProfileUrl ?? '').isNotEmpty) {
      return CustomImage(imageUrl: _currentProfileUrl!);
    }
    return CustomImage(
      imageUrl: AppIcons.defaultPersonLogo,
      color: context.color.tertiaryColor,
      fit: BoxFit.contain,
    );
  }

  Widget _getBannerImage() {
    if (_agentBanner != null) {
      return Image.file(_agentBanner!, fit: BoxFit.cover);
    }
    if ((_currentBannerUrl ?? '').isNotEmpty) {
      return CustomImage(imageUrl: _currentBannerUrl ?? '');
    }
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: context.color.tertiaryColor,
        size: 40.rh(context),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final bannerHeight = 175.rh(context);
    final avatarSize = 96.rw(context);
    final avatarOverlap = avatarSize / 2;
    final totalHeaderHeight = bannerHeight + avatarOverlap + 16.rh(context);

    return SizedBox(
      height: totalHeaderHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner Image Container
          Positioned(
            top: 0,
            left: 16.rw(context),
            right: 16.rw(context),
            height: bannerHeight,
            child: GestureDetector(
              onTap: () => unawaited(_showPicker(isBanner: true)),
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.rw(context)),
                  border: Border.all(
                    color: context.color.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13.rw(context)),
                  child: _getBannerImage(),
                ),
              ),
            ),
          ),
          // "Change" pill button on top right of banner
          PositionedDirectional(
            top: 12.rh(context),
            end: 28.rw(context),
            child: GestureDetector(
              onTap: () => unawaited(_showPicker(isBanner: true)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.rw(context),
                  vertical: 6.rh(context),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.rw(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.edit,
                      height: 13.rh(context),
                      fit: BoxFit.contain,
                      color: const Color(0xFF2D3134),
                    ),
                    SizedBox(width: 5.rw(context)),
                    CustomText(
                      'change'.translate(context),
                      fontSize: context.font.xs,
                      color: const Color(0xFF2D3134),
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Avatar overlapping bottom of the banner
          Positioned(
            top: bannerHeight - avatarOverlap,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: avatarSize,
                    width: avatarSize,
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      borderRadius: BorderRadius.circular(18.rw(context)),
                      border: Border.all(
                        color: context.color.tertiaryColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.rw(context)),
                      child: _getProfileImage(),
                    ),
                  ),
                  // Small circular teal edit button
                  Positioned(
                    bottom: -10.rh(context),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => unawaited(_showPicker(isBanner: false)),
                        child: Container(
                          height: 28.rh(context),
                          width: 28.rw(context),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.color.tertiaryColor,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomImage(
                              imageUrl: AppIcons.edit,
                              height: 12.rh(context),
                              fit: BoxFit.contain,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.rw(context)),
      padding: EdgeInsets.all(4.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(10.rw(context)),
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _capturePendingChips();
                setState(() {
                  _selectedTab = 0;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.rh(context)),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF333333)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.rw(context)),
                ),
                child: Center(
                  child: CustomText(
                    'personal'.translate(context),
                    color: _selectedTab == 0
                        ? Colors.white
                        : context.color.textColorDark,
                    fontWeight: FontWeight.w600,
                    fontSize: context.font.sm,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _capturePendingChips();
                setState(() {
                  _selectedTab = 1;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.rh(context)),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF333333)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.rw(context)),
                ),
                child: Center(
                  child: CustomText(
                    'business'.translate(context),
                    color: _selectedTab == 1
                        ? Colors.white
                        : context.color.textColorDark,
                    fontWeight: FontWeight.w600,
                    fontSize: context.font.sm,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required List<Widget> children,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.rw(context)),
      padding: EdgeInsets.all(16.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(14.rw(context)),
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCardTextField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    String? hintText,
    CustomTextFieldValidator? validator,
    bool? readOnly,
    int? maxLine,
    TextInputType? keyboard,
    Widget? prefix,
    Widget? suffix,
    List<TextInputFormatter>? formatters,
    TextDirection? textDirection,
    dynamic Function(dynamic value)? onChange,
    int? maxLength,
    bool hasActiveBorder = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg =
        isDark ? context.color.primaryColor : const Color(0xFFF7F8FA);
    final fieldBorder = hasActiveBorder
        ? context.color.tertiaryColor
        : (isDark ? context.color.borderColor : const Color(0xFFEEEEEE));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
          color: context.color.textColorDark,
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          hintText: hintText?.translate(context),
          maxLength: maxLength,
          textDirection: textDirection,
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          maxLine: maxLine,
          keyboard: keyboard,
          fillColor: fieldBg,
          borderColor: fieldBorder,
          borderRadius: 8.rw(context),
          onChange: onChange,
          prefix: prefix,
          suffix: suffix,
          formaters: formatters,
        ),
      ],
    );
  }

  Widget _buildCardChipsField({
    required String title,
    required String hintText,
    required List<String> chips,
    required TextEditingController inputController,
    required void Function(String val) onAdd,
    required void Function(int index) onRemove,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg =
        isDark ? context.color.primaryColor : const Color(0xFFF7F8FA);
    final fieldBorder =
        isDark ? context.color.borderColor : const Color(0xFFEEEEEE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
          color: context.color.textColorDark,
        ),
        SizedBox(height: 8.rh(context)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.rw(context)),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(8.rw(context)),
            border: Border.all(color: fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chips.isNotEmpty) ...[
                Wrap(
                  spacing: 8.rw(context),
                  runSpacing: 8.rh(context),
                  children: List.generate(chips.length, (index) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.rw(context),
                        vertical: 6.rh(context),
                      ),
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(20.rw(context)),
                        border: Border.all(
                          color: context.color.tertiaryColor
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            chips[index],
                            fontSize: context.font.xs,
                            fontWeight: FontWeight.w500,
                            color: context.color.textColorDark,
                          ),
                          SizedBox(width: 6.rw(context)),
                          GestureDetector(
                            onTap: () => onRemove(index),
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              Icons.close,
                              size: 14.rh(context),
                              color: context.color.textColorDark
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                SizedBox(height: 10.rh(context)),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      decoration: InputDecoration(
                        hintText: hintText.translate(context),
                        hintStyle: TextStyle(
                          fontSize: context.font.xs,
                          color: context.color.textLightColor,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      style: TextStyle(
                        fontSize: context.font.sm,
                        color: context.color.textColorDark,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (val) {
                        if (val.contains(',')) {
                          onAdd(val);
                          inputController.clear();
                        }
                      },
                      onSubmitted: (val) {
                        onAdd(val);
                        inputController.clear();
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
                      onAdd(inputController.text);
                      inputController.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg =
        isDark ? context.color.primaryColor : const Color(0xFFF7F8FA);
    final fieldBorder =
        isDark ? context.color.borderColor : const Color(0xFFEEEEEE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'workingHoursOptional'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
          color: context.color.textColorDark,
        ),
        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _startTime = pickedTime.format(context);
                    });
                  }
                },
                child: Container(
                  height: 48.rh(context),
                  padding: EdgeInsets.symmetric(horizontal: 14.rw(context)),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(8.rw(context)),
                    border: Border.all(color: fieldBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          _startTime ?? 'startTime'.translate(context),
                          fontSize: context.font.sm,
                          color: _startTime != null
                              ? context.color.textColorDark
                              : context.color.textColorDark.withValues(alpha: 0.5),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color:
                            context.color.textColorDark.withValues(alpha: 0.6),
                        size: 22.rh(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _endTime = pickedTime.format(context);
                    });
                  }
                },
                child: Container(
                  height: 48.rh(context),
                  padding: EdgeInsets.symmetric(horizontal: 14.rw(context)),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(8.rw(context)),
                    border: Border.all(color: fieldBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          _endTime ?? 'endTime'.translate(context),
                          fontSize: context.font.sm,
                          color: _endTime != null
                              ? context.color.textColorDark
                              : context.color.textColorDark.withValues(alpha: 0.5),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color:
                            context.color.textColorDark.withValues(alpha: 0.6),
                        size: 22.rh(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalTab(bool isEmailLogin, bool isPhoneLogin) {
    return _buildCardContainer(
      children: [
        _buildCardTextField(
          context,
          title: 'fullName',
          hintText: 'Enter your full name',
          controller: _nameController,
          validator: CustomTextFieldValidator.nullCheck,
        ),
        SizedBox(height: 14.rh(context)),
        _buildCardTextField(
          context,
          title: 'email',
          hintText: 'Enter your email',
          controller: _emailController,
          readOnly: isEmailLogin,
          validator: CustomTextFieldValidator.email,
        ),
        SizedBox(height: 14.rh(context)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'mobile'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w600,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 8.rh(context)),
            PhoneField(
              controller: _mobileController,
              enabled: !isPhoneLogin,
              initialCountryCode: selectedCountryCode,
              validator: AppSettings.isDemoModeOn
                  ? CustomTextFieldValidator.nullCheck
                  : CustomTextFieldValidator.phoneNumber,
              onCountryChanged: (value) {
                setState(() {
                  selectedCountryCode = value;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 14.rh(context)),
        _buildCardTextField(
          context,
          title: 'addressLbl',
          hintText: 'Enter your address',
          controller: _addressController,
          validator: CustomTextFieldValidator.nullCheck,
        ),
        SizedBox(height: 14.rh(context)),
        _buildCardTextField(
          context,
          title: 'aboutMe',
          hintText: 'Tell us about yourself',
          controller: _aboutMeController,
          validator: CustomTextFieldValidator.nullCheck,
          maxLine: 4,
          keyboard: TextInputType.multiline,
        ),
      ],
    );
  }

  Widget _buildBusinessTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardContainer(
          children: [
            _buildCardChipsField(
              title: 'serviceAreas',
              hintText: 'enterLocations',
              chips: _serviceAreasChips,
              inputController: _serviceAreaInputController,
              onAdd: _addServiceAreaChip,
              onRemove: _removeServiceAreaChip,
            ),
            SizedBox(height: 14.rh(context)),
            _buildCardChipsField(
              title: 'languagesSpoken',
              hintText: 'enterLanguages',
              chips: _languagesChips,
              inputController: _languageInputController,
              onAdd: _addLanguageChip,
              onRemove: _removeLanguageChip,
            ),
            SizedBox(height: 14.rh(context)),
            _buildCardTextField(
              context,
              title: 'yearsOfExperience',
              hintText: 'enterExperienceYear',
              controller: _experienceController,
              keyboard: TextInputType.number,
            ),
            SizedBox(height: 14.rh(context)),
            _buildWorkingHoursPicker(),
          ],
        ),
        SizedBox(height: 16.rh(context)),
        _buildCardContainer(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    'socialMediaDetailsOptional'.translate(context),
                    fontSize: context.font.sm,
                    fontWeight: FontWeight.w600,
                    color: context.color.textColorDark,
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: UiSwitch(
                    value: _isSocialMediaEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isSocialMediaEnabled = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_isSocialMediaEnabled && _socialMediaLinks.isNotEmpty) ...[
              ..._socialMediaLinks.map((link) {
                final controller = _socialControllers[link.id] ??=
                    TextEditingController(text: link.url ?? '');
                return Padding(
                  padding: EdgeInsets.only(top: 14.rh(context)),
                  child: _buildCardTextField(
                    context,
                    title: link.name,
                    hintText: 'https://...',
                    controller: controller,
                    validator: CustomTextFieldValidator.link,
                  ),
                );
              }),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(UpdateAgentProfileState updateState) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.rw(context),
        12.rh(context),
        16.rw(context),
        16.rh(context) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: UiUtils.buildButton(
              context,
              onPressed: () => Navigator.of(context).pop(),
              buttonTitle: 'discard'.translate(context),
              height: 48.rh(context),
              radius: 8.rw(context),
              fontSize: context.font.md,
              showElevation: false,
              buttonColor: context.color.secondaryColor,
              textColor: context.color.textColorDark,
              border: BorderSide(
                color: context.color.textColorDark.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
          ),
          SizedBox(width: 14.rw(context)),
          Expanded(
            child: UiUtils.buildButton(
              context,
              onPressed: () => unawaited(_submit()),
              buttonTitle: 'save'.translate(context),
              height: 48.rh(context),
              radius: 8.rw(context),
              fontSize: context.font.md,
              showElevation: false,
              isInProgress: updateState is UpdateAgentProfileInProgress,
              progressWidth: 22,
              progressHeight: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      itemBuilder: (context, index) => index == 0
          ? Shimmer.fromColors(
              period: const Duration(milliseconds: 1000),
              baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
              highlightColor:
                  Theme.of(context).colorScheme.shimmerHighlightColor,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.shimmerContentColor,
                  shape: .circle,
                ),
              ),
            )
          : CustomShimmer(height: 50.rh(context)),
      separatorBuilder: (context, index) =>
          SizedBox(height: index == 0 ? 24 : 16),
      itemCount: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmailLogin =
        HiveUtils.getUserLoginType() == LoginType.google ||
        HiveUtils.getUserLoginType() == LoginType.apple ||
        HiveUtils.getUserLoginType() == LoginType.email;
    final isPhoneLogin = HiveUtils.getUserLoginType() == LoginType.phone;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocConsumer<UpdateAgentProfileCubit, UpdateAgentProfileState>(
        listener: (context, state) async {
          if (state is UpdateAgentProfileSuccess) {
            HelperUtils.showSnackBarMessage(
              context,
              'profileupdated',
              type: .success,
            );

            dynamic serverData = state.response['data'];
            if (serverData is List && serverData.isNotEmpty) {
              serverData = serverData.first;
            }
            var newProfilePhotoUrl = _currentProfileUrl;
            var newBannerUrl = _currentBannerUrl;
            if (serverData is Map) {
              final sMap = Map<String, dynamic>.from(serverData);
              if (sMap['customer_data'] is Map) {
                sMap.addAll(
                  Map<String, dynamic>.from(sMap['customer_data'] as Map),
                );
              }
              if (sMap['agent_profile'] is Map) {
                sMap.addAll(
                  Map<String, dynamic>.from(sMap['agent_profile'] as Map),
                );
              }
              newProfilePhotoUrl = sMap['agent_profile_photo']?.toString() ??
                  sMap['profile']?.toString() ??
                  newProfilePhotoUrl;
              newBannerUrl = sMap['agent_banner']?.toString() ??
                  sMap['banner']?.toString() ??
                  newBannerUrl;
            }

            final currentCached = HiveUtils.getAgentProfileData();
            final updatedProfile = (currentCached ?? AgentProfileModel())
                .copyWith(
                  agentName: _nameController.text.trim(),
                  agentEmail: _emailController.text.trim(),
                  agentMobile: _mobileController.text.trim(),
                  agentAddress: _addressController.text.trim(),
                  aboutMe: _aboutMeController.text.trim(),
                  serviceAreas: _serviceAreasChips.join(','),
                  languages: _languagesChips.join(','),
                  experience: _experienceController.text.trim(),
                  startTime: _startTime,
                  endTime: _endTime,
                  socialMediaLinks: _socialMediaLinks,
                  agentProfilePhoto: newProfilePhotoUrl,
                  agentBanner: newBannerUrl,
                );
            context.read<AgentProfileCubit>().setAgentProfile(updatedProfile);
            unawaited(context.read<AgentProfileCubit>().fetchAgentProfile());
            if (context.mounted) {
              Navigator.pop(context);
            }
          } else if (state is UpdateAgentProfileFailure) {
            HelperUtils.showSnackBarMessage(
              context,
              state.errorMessage,
              type: .error,
            );
          }
        },
        builder: (context, updateState) {
          return Scaffold(
            backgroundColor: context.color.primaryColor,
            appBar: CustomAppBar(
              title: 'editProfile'.translate(context),
              backgroundColor: context.color.primaryColor,
              showShadow: false,
            ),
            bottomNavigationBar: _buildBottomActionBar(updateState),
            body: BlocConsumer<AgentProfileCubit, AgentProfileState>(
              listener: (context, state) {
                if (state is AgentProfileSuccess) {
                  _populateFields(state.agentProfile);
                }
              },
              builder: (context, state) {
                if (state is AgentProfileInProgress) return _buildShimmer();
                if (state is AgentProfileFailure) {
                  return SomethingWentWrong(
                    errorMessage: state.errorMessage,
                  );
                }

                return SingleChildScrollView(
                  physics: Constant.scrollPhysics,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        SizedBox(height: 16.rh(context)),
                        _buildTabBar(),
                        SizedBox(height: 16.rh(context)),
                        if (_selectedTab == 0)
                          _buildPersonalTab(isEmailLogin, isPhoneLogin)
                        else
                          _buildBusinessTab(),
                        SizedBox(height: 24.rh(context)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
