import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_file_picker.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class Step3ImagesVideoScreen extends StatefulWidget {
  const Step3ImagesVideoScreen({
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
  State<Step3ImagesVideoScreen> createState() => _Step3ImagesVideoScreenState();
}

class _Step3ImagesVideoScreenState extends State<Step3ImagesVideoScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _videoUrlController;
  late final TabController _videoTabController;

  @override
  void initState() {
    super.initState();
    final data = context.read<ProjectWizardCubit>().data;
    _videoUrlController = TextEditingController(text: data.videoUrl);

    final initialIndex = data.videoType == 1
        ? 0
        : (data.videoType == 2 ? 1 : 2);

    _videoTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _videoTabController.addListener(() {
      if (_videoTabController.indexIsChanging) {
        _syncToCubit();
        setState(() {
          if (_videoTabController.index == 0) {
            data.videoType = 1;
          } else if (_videoTabController.index == 1) {
            data.videoType = 2;
          } else {
            data.videoType = 0;
          }
        });
      }
    });
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
    _videoTabController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _syncToCubit() {
    final cubit = _wizardCubit;
    if (cubit.data.videoType != 0) {
      cubit.data.videoUrl = _videoUrlController.text;
    }
  }

  Future<void> _pickTitleImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        context.read<ProjectWizardCubit>().data
          ..titleImage = File(pickedFile.path)
          ..titleImageUrl = '';
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final data = context.read<ProjectWizardCubit>().data;
        for (final xFile in pickedFiles) {
          if (data.galleryImages.length + data.galleryImageUrls.length < 15) {
            data.galleryImages.add(File(xFile.path));
          }
        }
      });
    }
  }

  Future<void> _pickCustomVideo() async {
    // NOTE: extension filters are only valid with FileType.custom; passing them
    // with FileType.video makes the picker throw and never open.
    final result = await AppFilePicker.pickFile(
      allowedExtensions: ['mp4', 'mkv', 'mov'],
    );
    if (result?.path != null) {
      setState(() {
        context.read<ProjectWizardCubit>().data
          ..customVideoFile = File(result!.path!)
          ..customVideoUrl = ''
          ..videoUrl = ''
          ..removeVideo = false;
      });
    }
  }

  Future<void> _pickDocument() async {
    final file = await AppFilePicker.pickFile(
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (file != null && file.path != null) {
      setState(() {
        context.read<ProjectWizardCubit>().data.projectDocuments.add(file);
      });
    }
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
        title: 'imagesAndVideo'.translate(context),
        onTapBackButton: () {
          _syncToCubit();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '3/6',
              fontSize: context.font.md,
              fontWeight: .w600,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
      bottomNavigationBar: StepBottomBar(
        onNext: () {
          if (data.titleImage == null && data.titleImageUrl.isEmpty) {
            HelperUtils.showSnackBarMessage(
              context,
              'uploadImgMsgLbl'.translate(context),
              type: MessageType.error,
            );
            return;
          }
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
              // ==========================================
              // 1. Title Image (Max 3MB)
              // ==========================================
              Row(
                children: [
                  CustomText(
                    'Title Image (Max 3MB)',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                  ),
                  CustomText(
                    ' *',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.color.error,
                  ),
                ],
              ),
              SizedBox(height: 4.rh(context)),
              if (data.titleImage == null && data.titleImageUrl.isEmpty)
                _buildDottedBox(
                  text: 'addMainPicture'.translate(context),
                  onTap: _pickTitleImage,
                  borderColor: borderColor,
                )
              else
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickTitleImage,
                      child: Container(
                        height: 120.rh(context),
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: data.titleImage != null
                            ? Image.file(data.titleImage!, fit: BoxFit.cover)
                            : Image.network(
                                data.titleImageUrl,
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
                              ..titleImage = null
                              ..titleImageUrl = '';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.color.textColorDark.withValues(
                              alpha: 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CustomImage(
                            imageUrl: AppIcons.closeCircle,
                            width: 16.rw(context),
                            height: 16.rh(context),
                            color: context.color.buttonColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 18.rh(context)),
              // ==========================================
              // 2. Other Images (Max 5 images)
              // ==========================================
              CustomText(
                'Other Images (Max 5 images)',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
              SizedBox(height: 4.rh(context)),
              _buildDottedBox(
                text: 'addOtherPicture'.translate(context),
                onTap: _pickGalleryImages,
                borderColor: borderColor,
              ),
              if (data.galleryImages.isNotEmpty ||
                  data.galleryImageUrls.isNotEmpty) ...[
                SizedBox(height: 12.rh(context)),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...data.galleryImageUrls.map((imgMap) {
                      return Stack(
                        children: [
                          Container(
                            width: 75.rw(context),
                            height: 75.rw(context),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: Image.network(
                              imgMap['image']?.toString() ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                          PositionedDirectional(
                            top: 4,
                            end: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  final id = imgMap['id'];
                                  if (id is int) {
                                    data.removedGalleryImageIds.add(id);
                                  }
                                  data.galleryImageUrls.remove(imgMap);
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
                                  width: 14,
                                  height: 14,
                                  color: context.color.buttonColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    ...data.galleryImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 75.rw(context),
                            height: 75.rw(context),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: Image.file(
                              entry.value,
                              fit: BoxFit.cover,
                            ),
                          ),
                          PositionedDirectional(
                            top: 4,
                            end: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  data.galleryImages.removeAt(entry.key);
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
                                  width: 14.rw(context),
                                  height: 14.rh(context),
                                  color: context.color.buttonColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
              SizedBox(height: 18.rh(context)),
              // ==========================================
              // 3. Video Preview (CustomTabBar)
              // ==========================================
              CustomText(
                'videoPreview'.translate(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
              SizedBox(height: 8.rw(context)),
              _buildVideoTypeSelector(data),
              SizedBox(height: 10.rh(context)),
              if (data.videoType != 0)
                CustomTextFormField(
                  controller: _videoUrlController,
                  action: TextInputAction.next,
                  hintText: 'videoLink'.translate(context),
                  borderRadius: 6,
                  borderColor: borderColor,
                  fillColor: context.color.secondaryColor,
                  onChange: (val) => data.videoUrl = val?.toString() ?? '',
                )
              else ...[
                if (data.customVideoFile == null && data.customVideoUrl.isEmpty)
                  _buildDottedBox(
                    text: 'uploadVideo'.translate(context),
                    onTap: _pickCustomVideo,
                    borderColor: borderColor,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        CustomImage(
                          imageUrl: AppIcons.videoCall,
                          width: 22.rw(context),
                          height: 22.rh(context),
                          color: context.color.tertiaryColor,
                        ),
                        SizedBox(width: 10.rw(context)),
                        Expanded(
                          child: CustomText(
                            data.customVideoFile != null
                                ? data.customVideoFile!.path.split('/').last
                                : 'videoPreview'.translate(context),
                            fontSize: 13,
                            color: primaryTextColor,
                            maxLines: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              data
                                ..customVideoFile = null
                                ..customVideoUrl = ''
                                ..removeVideo = true;
                            });
                          },
                          child: CustomImage(
                            imageUrl: AppIcons.closeCircle,
                            width: 18.rw(context),
                            height: 18.rh(context),
                            color: context.color.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              SizedBox(height: 18.rh(context)),

              // ==========================================
              // 4. Project Documents
              // ==========================================
              CustomText(
                'projectDocuments'.translate(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
              SizedBox(height: 4.rh(context)),
              _buildDottedBox(
                text: 'UploadDocs'.translate(context),
                onTap: _pickDocument,
                borderColor: borderColor,
              ),
              if (data.existingDocuments.isNotEmpty ||
                  data.projectDocuments.isNotEmpty) ...[
                SizedBox(height: 10.rh(context)),
                ...data.existingDocuments.map((doc) {
                  return _buildDocumentItem(
                    name: doc.name ?? 'Document',
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onDelete: () {
                      setState(() {
                        if (doc.id != null) {
                          data.removedDocumentIds.add(doc.id!);
                        }
                        data.existingDocuments.remove(doc);
                      });
                    },
                  );
                }),
                ...data.projectDocuments.asMap().entries.map((entry) {
                  return _buildDocumentItem(
                    name: entry.value.name,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    onDelete: () {
                      setState(() {
                        data.projectDocuments.removeAt(entry.key);
                      });
                    },
                  );
                }),
              ],
              SizedBox(height: 24.rh(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDottedBox({
    required String text,
    required VoidCallback onTap,
    required Color borderColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(4),
          color: context.color.textLightColor,
          dashPattern: const [4, 3],
        ),
        child: Container(
          height: 120.rh(context),
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
            text,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.color.textLightColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem({
    required String name,
    required Color borderColor,
    required Color primaryTextColor,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              name,
              fontSize: 13,
              color: primaryTextColor,
              maxLines: 1,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: CustomImage(
              imageUrl: AppIcons.closeCircle,
              width: 16.rw(context),
              height: 16.rh(context),
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTypeSelector(ProjectWizardData data) {
    return CustomTabBar(
      tabController: _videoTabController,
      margin: EdgeInsets.zero,
      isScrollable: false,
      tabBackgroundColor: context.color.tertiaryColor,
      onTap: (index) {
        _syncToCubit();
        setState(() {
          if (index == 0) {
            data
              ..videoType = 1
              ..videoUrl = _videoUrlController.text;
          } else if (index == 1) {
            data
              ..videoType = 2
              ..videoUrl = _videoUrlController.text;
          } else {
            data.videoType = 0;
          }
        });
      },
      tabs: [
        Tab(
          text: 'youtube'.translate(context).isNotEmpty
              ? 'youtube'.translate(context)
              : 'Youtube',
        ),
        Tab(
          text: 'vimeo'.translate(context).isNotEmpty
              ? 'vimeo'.translate(context)
              : 'Vimeo',
        ),
        Tab(
          text: 'custom'.translate(context).isNotEmpty
              ? 'custom'.translate(context)
              : 'Custom',
        ),
      ],
    );
  }
}
