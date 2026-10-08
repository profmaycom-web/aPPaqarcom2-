import 'dart:async';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class Step6SeoScreen extends StatefulWidget {
  const Step6SeoScreen({
    required this.onSubmit,
    required this.onBack,
    this.onSaveDraft,
    super.key,
    this.isSubmitting = false,
    this.isSavingDraft = false,
  });

  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback? onSaveDraft;
  final bool isSubmitting;
  final bool isSavingDraft;

  @override
  State<Step6SeoScreen> createState() => _Step6SeoScreenState();
}

class _Step6SeoScreenState extends State<Step6SeoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _metaTitleController;
  late final TextEditingController _metaDescController;
  final TextEditingController _keywordInputController = TextEditingController();
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void initState() {
    super.initState();
    final data = context.read<ProjectWizardCubit>().data;
    _metaTitleController = TextEditingController(text: data.metaTitle);
    _metaDescController = TextEditingController(text: data.metaDescription);
  }

  late ProjectWizardCubit _wizardCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wizardCubit = context.read<ProjectWizardCubit>();
  }

  @override
  void dispose() {
    _syncToCubit();
    unawaited(_checkPackageCubit.close());
    _metaTitleController.dispose();
    _metaDescController.dispose();
    _keywordInputController.dispose();
    super.dispose();
  }

  void _syncToCubit() {
    _wizardCubit.data
      ..metaTitle = _metaTitleController.text
      ..metaDescription = _metaDescController.text;
  }

  void _addKeyword(String text) {
    final trimmed = text.trim();
    final data = context.read<ProjectWizardCubit>().data;
    if (trimmed.isNotEmpty && !data.keywords.contains(trimmed)) {
      setState(() {
        data.keywords.add(trimmed);
        _keywordInputController.clear();
      });
    }
  }

  Future<void> _onSubmitPressed() async {
    if (_checkPackageCubit.state is CheckPackageInProgress) return;

    _syncToCubit();

    final isPackageAvailable = await _checkPackageCubit.checkAvailability(
      packageType: PackageType.projectList,
    );

    if (!mounted) return;

    if (_checkPackageCubit.state is CheckPackageFail) {
      HelperUtils.showSnackBarMessage(
        context,
        (_checkPackageCubit.state as CheckPackageFail).error,
        type: MessageType.error,
      );
      return;
    }

    if (!isPackageAvailable) {
      final paymentResult = await UiUtils.showBlurredDialoge(
        context,
        dialog: const BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.projectList,
          isAcceptContainesPush: true,
        ),
      );
      // Continue with the submission once pay-as-you-go payment succeeds.
      if (paymentResult == true && mounted) widget.onSubmit();
      return;
    }

    widget.onSubmit();
  }

  Future<void> _pickOgImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        context.read<ProjectWizardCubit>().data
          ..ogImage = File(pickedFile.path)
          ..ogImageUrl = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProjectWizardCubit>();
    final data = cubit.data;

    final primaryTextColor = context.color.textColorDark;
    final secondaryTextColor = context.color.textLightColor;
    final borderColor = context.color.borderColor;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'seoSettings'.translate(context),
        onTapBackButton: () {
          _syncToCubit();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '6/6',
              fontSize: context.font.md,
              fontWeight: .w600,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CheckPackageCubit, CheckPackageState>(
        bloc: _checkPackageCubit,
        builder: (context, checkPackageState) {
          return StepBottomBar(
            nextButtonText:
                (cubit.data.isEdit &&
                    !cubit.data.isDraftProject &&
                    cubit.data.requestStatus.toLowerCase() != 'draft')
                ? 'update'.translate(context)
                : 'submitBtnLbl'.translate(context),
            isFinalStep: true,
            isSubmitting:
                widget.isSubmitting ||
                checkPackageState is CheckPackageInProgress,
            isSavingDraft: widget.isSavingDraft,
            onNext: _onSubmitPressed,
            onSaveDraft: widget.onSaveDraft != null
                ? () {
                    _syncToCubit();
                    widget.onSaveDraft!();
                  }
                : null,
          );
        },
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. Meta Title
                // ==========================================
                CustomText(
                  'metaTitle'.translate(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
                SizedBox(height: 8.rh(context)),
                CustomTextFormField(
                  controller: _metaTitleController,
                  action: TextInputAction.next,
                  hintText: 'metaTitle'.translate(context),
                  borderRadius: 6,
                  borderColor: borderColor,
                  fillColor: context.color.secondaryColor,
                  onChange: (val) => data.metaTitle = val?.toString() ?? '',
                ),
                SizedBox(height: 18.rh(context)),

                // ==========================================
                // 2. Meta Description
                // ==========================================
                CustomText(
                  'metaDescription'.translate(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
                SizedBox(height: 8.rh(context)),
                CustomTextFormField(
                  controller: _metaDescController,
                  action: TextInputAction.newline,
                  minLine: 4,
                  maxLine: 6,
                  hintText: 'metaDescription'.translate(context),
                  borderRadius: 6,
                  borderColor: borderColor,
                  fillColor: context.color.secondaryColor,
                  onChange: (val) =>
                      data.metaDescription = val?.toString() ?? '',
                ),
                SizedBox(height: 18.rh(context)),

                // ==========================================
                // 3. Keywords
                // ==========================================
                CustomText(
                  'metaKeywords'.translate(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
                SizedBox(height: 8.rh(context)),
                Container(
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _keywordInputController,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'metaKeywords'.translate(context),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _addKeyword,
                  ),
                ),
                if (data.keywords.isNotEmpty) ...[
                  SizedBox(height: 10.rh(context)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.keywords.map((kw) {
                      return Chip(
                        label: CustomText(
                          kw,
                          fontSize: 12.5,
                          color: primaryTextColor,
                        ),
                        backgroundColor: context.color.secondaryColor,
                        deleteIcon: CustomImage(
                          imageUrl: AppIcons.closeCircle,
                          width: 14.rw(context),
                          height: 14.rh(context),
                          color: primaryTextColor,
                        ),
                        onDeleted: () {
                          setState(() {
                            data.keywords.remove(kw);
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: borderColor),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 18.rh(context)),

                // ==========================================
                // 4. OG Image (Max 5MB)
                // ==========================================
                CustomText(
                  'addMetaImage'.translate(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
                SizedBox(height: 4.rh(context)),
                if (data.ogImage == null && data.ogImageUrl.isEmpty)
                  GestureDetector(
                    onTap: _pickOgImage,
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        radius: const Radius.circular(4),
                        color: context.color.textLightColor,
                        dashPattern: const [4, 3],
                      ),
                      child: Container(
                        height: 72.rh(context),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          'addMetaImage'.translate(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickOgImage,
                        child: Container(
                          height: 90.rh(context),
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: data.ogImage != null
                              ? Image.file(data.ogImage!, fit: BoxFit.cover)
                              : Image.network(
                                  data.ogImageUrl,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              data
                                ..ogImage = null
                                ..ogImageUrl = '';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: context.color.textColorDark.withValues(
                                alpha: 0.6,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CustomImage(
                              imageUrl: AppIcons.closeCircle,
                              color: context.color.buttonColor,
                              width: 18.rw(context),
                              height: 18.rh(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 24.rh(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
