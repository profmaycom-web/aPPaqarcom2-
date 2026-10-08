import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class Step5FloorDetailsScreen extends StatefulWidget {
  const Step5FloorDetailsScreen({
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
  State<Step5FloorDetailsScreen> createState() =>
      _Step5FloorDetailsScreenState();
}

class _Step5FloorDetailsScreenState extends State<Step5FloorDetailsScreen> {
  final List<TextEditingController> _titleControllers = [];

  @override
  void initState() {
    super.initState();
    final data = context.read<ProjectWizardCubit>().data;
    if (data.floorPlans.isEmpty) {
      data.floorPlans.add(ProjectFloorPlanItem(title: 'Ground Floor'));
    }
    _syncControllersFromData(data);
  }

  void _syncControllersFromData(ProjectWizardData data) {
    for (final c in _titleControllers) {
      c.dispose();
    }
    _titleControllers.clear();
    for (final plan in data.floorPlans) {
      _titleControllers.add(TextEditingController(text: plan.title));
    }
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
    for (final c in _titleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncToCubit() {
    final cubit = _wizardCubit;
    for (
      var i = 0;
      i < _titleControllers.length && i < cubit.data.floorPlans.length;
      i++
    ) {
      cubit.data.floorPlans[i].title = _titleControllers[i].text;
    }
  }

  Future<void> _pickFloorImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        final cubit = context.read<ProjectWizardCubit>();
        cubit.data.floorPlans[index]
          ..imageFile = File(picked.path)
          ..imageUrl = '';
      });
    }
  }

  void _addNewFloor() {
    final cubit = context.read<ProjectWizardCubit>();
    _syncToCubit();
    setState(() {
      cubit.addFloorPlan();
      _titleControllers.add(TextEditingController());
    });
  }

  void _removeFloor(int index) {
    final cubit = context.read<ProjectWizardCubit>();
    _syncToCubit();
    setState(() {
      cubit.removeFloorPlan(index);
      if (index < _titleControllers.length) {
        _titleControllers[index].dispose();
        _titleControllers.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProjectWizardCubit>();
    final data = cubit.data;

    final primaryTextColor = context.color.textColorDark;
    final borderColor = context.color.borderColor;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'floorDetails'.translate(context),
        onTapBackButton: () {
          _syncToCubit();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '5/6',
              fontSize: context.font.md,
              fontWeight: .w600,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
      bottomNavigationBar: StepBottomBar(
        onNext: () {
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
        child: SingleChildScrollView(
          physics: Constant.scrollPhysics,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(data.floorPlans.length, (index) {
                final plan = data.floorPlans[index];
                final controller = index < _titleControllers.length
                    ? _titleControllers[index]
                    : TextEditingController(text: plan.title);

                final hasImage =
                    plan.imageFile != null || plan.imageUrl.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            'Floor Title'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                          if (data.floorPlans.length > 1)
                            GestureDetector(
                              onTap: () => _removeFloor(index),
                              child: CustomImage(
                                imageUrl: AppIcons.bin,
                                width: 18.rw(context),
                                height: 18.rh(context),
                                color: context.color.error,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.rh(context)),
                      CustomTextFormField(
                        controller: controller,
                        action: TextInputAction.next,
                        hintText: 'Floor Title'.translate(context),
                        borderRadius: 6,
                        borderColor: borderColor,
                        fillColor: context.color.primaryColor,
                        onChange: (val) => plan.title = val?.toString() ?? '',
                      ),
                      SizedBox(height: 14.rh(context)),
                      if (hasImage)
                        Stack(
                          children: [
                            Container(
                              height: 160.rh(context),
                              width: double.infinity,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: plan.imageFile != null
                                  ? Image.file(
                                      plan.imageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      plan.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            PositionedDirectional(
                              top: 8,
                              end: 8,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickFloorImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: context.color.textColorDark
                                            .withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CustomImage(
                                        imageUrl: AppIcons.edit,
                                        width: 18.rw(context),
                                        height: 18.rh(context),
                                        color: context.color.buttonColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.rw(context)),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        plan
                                          ..imageFile = null
                                          ..imageUrl = '';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: context.color.textColorDark
                                            .withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CustomImage(
                                        imageUrl: AppIcons.closeCircle,
                                        width: 18.rw(context),
                                        height: 18.rh(context),
                                        color: context.color.buttonColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () => _pickFloorImage(index),
                          child: DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              radius: const Radius.circular(4),
                              color: context.color.textLightColor,
                              dashPattern: const [4, 3],
                            ),
                            child: Container(
                              height: 48.rh(context),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.color.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: CustomText(
                                'pickFloorMap'.translate(context),
                                fontSize: 14,
                                color: context.color.textLightColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 6.rh(context)),
              SizedBox(
                width: double.infinity,
                height: 48.rh(context),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: context.color.tertiaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _addNewFloor,
                  child: CustomText(
                    'addFloor'.translate(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.color.tertiaryColor,
                  ),
                ),
              ),
              SizedBox(height: 24.rh(context)),
            ],
          ),
        ),
      ),
    );
  }
}
