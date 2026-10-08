import 'dart:developer';
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/ui/screens/widgets/panaroma_image_view.dart';
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
import 'package:ebroker/utils/ui_utils.dart';
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
  late final TextEditingController _youtubeController;
  late final TextEditingController _vimeoController;
  late final TabController _videoTabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final data = context.read<PropertyWizardCubit>().data;
    _youtubeController = TextEditingController(
      text: data.videoType == 1 ? data.videoUrl : '',
    );
    _vimeoController = TextEditingController(
      text: data.videoType == 2 ? data.videoUrl : '',
    );
    final initialIndex = data.videoType == 1
        ? 0
        : (data.videoType == 2 ? 1 : 2);
    _videoTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
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
    _videoTabController.dispose();
    _youtubeController.dispose();
    _vimeoController.dispose();
    super.dispose();
  }

  void _syncToCubit() {
    final cubit = _wizardCubit;
    if (cubit.data.videoType == 1) {
      cubit.data.videoUrl = _youtubeController.text;
    } else if (cubit.data.videoType == 2) {
      cubit.data.videoUrl = _vimeoController.text;
    }
  }

  Future<void> _pickTitleImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          context.read<PropertyWizardCubit>().data
            ..titleImage = File(pickedFile.path)
            ..titleImageUrl = '';
        });
      }
    } on Exception catch (e) {
      log('Error picking title image: $e');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          final data = context.read<PropertyWizardCubit>().data;
          for (final xFile in pickedFiles) {
            if (data.galleryImages.length + data.galleryImageUrls.length < 15) {
              data.galleryImages.add(File(xFile.path));
            }
          }
        });
      }
    } on Exception catch (e) {
      log('Error picking gallery images: $e');
    }
  }

  Future<void> _pick360Image() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          context.read<PropertyWizardCubit>().data
            ..v360Image = File(pickedFile.path)
            ..v360ImageUrl = '';
        });
      }
    } on Exception catch (e) {
      log('Error picking 360 image: $e');
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
        context.read<PropertyWizardCubit>().data.customVideoFile = File(
          result!.path!,
        );
      });
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final files = await AppFilePicker.pickFiles(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );
      if (files != null) {
        setState(() {
          context.read<PropertyWizardCubit>().data.propertyDocuments.addAll(
            files,
          );
        });
      }
    } on Exception catch (e) {
      log('Error picking documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PropertyWizardCubit>();
    final data = cubit.data;

    final borderColor = context.color.borderColor;
    final primaryTextColor = context.color.textColorDark;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'uploadPictures'.translate(context),
        onTapBackButton: () {
          _syncToCubit();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '3/7',
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
          _syncToCubit();
          if (data.titleImage == null && data.titleImageUrl.isEmpty) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleasePickTitleImage'.translate(context),
              type: MessageType.error,
            );
            return;
          }
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. Title Image (Max 3MB)
              // ==========================================
              Row(
                children: [
                  CustomText(
                    'uploadPictures'.translate(context),
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
                  SizedBox(width: 4.rh(context)),
                  CustomText(
                    'maxSize'.translate(context),
                    fontStyle: FontStyle.italic,
                    fontSize: context.font.xs,
                    color: context.color.textLightColor,
                  ),
                ],
              ),
              SizedBox(height: 8.rh(context)),
              if (data.titleImage == null && data.titleImageUrl.isEmpty)
                _buildDottedBox(
                  text: 'addMainPicture'.translate(context),
                  height: 120.rh(context),
                  onTap: _pickTitleImage,
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (data.titleImage != null) {
                              await UiUtils.showFullScreenImage(
                                context,
                                provider: FileImage(data.titleImage!),
                              );
                            } else if (data.titleImageUrl.isNotEmpty) {
                              await UiUtils.showFullScreenImage(
                                context,
                                provider: NetworkImage(data.titleImageUrl),
                              );
                            }
                          },
                          child: Container(
                            width: 100.rw(context),
                            height: 100.rw(context),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: data.titleImage != null
                                ? Image.file(
                                    data.titleImage!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    data.titleImageUrl,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        closeButton(context, () {
                          setState(() {
                            data
                              ..titleImage = null
                              ..titleImageUrl = '';
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              SizedBox(height: 18.rh(context)),

              // ==========================================
              // 2. Other Pictures (Max 5 images)
              // ==========================================
              CustomText(
                'otherPictures'.translate(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
              SizedBox(height: 8.rh(context)),
              if (data.galleryImages.isEmpty && data.galleryImageUrls.isEmpty)
                _buildDottedBox(
                  text: 'addOtherPicture'.translate(context),
                  height: 120.rh(context),
                  onTap: _pickGalleryImages,
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...data.galleryImageUrls.map((url) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await UiUtils.showFullScreenImage(
                                context,
                                provider: NetworkImage(url),
                              );
                            },
                            child: Container(
                              width: 100.rw(context),
                              height: 100.rw(context),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          ),
                          closeButton(context, () {
                            setState(() {
                              data
                                ..removedGalleryImageIds.add(url)
                                ..galleryImageUrls.remove(url);
                            });
                          }),
                        ],
                      );
                    }),
                    ...data.galleryImages.map((file) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await UiUtils.showFullScreenImage(
                                context,
                                provider: FileImage(file),
                              );
                            },
                            child: Container(
                              width: 100.rw(context),
                              height: 100.rw(context),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                          ),
                          closeButton(context, () {
                            setState(() {
                              data.galleryImages.remove(file);
                            });
                          }),
                        ],
                      );
                    }),
                    if (data.galleryImages.length +
                            data.galleryImageUrls.length <
                        15)
                      _buildUploadPhotoCard(
                        context,
                        onTap: _pickGalleryImages,
                      ),
                  ],
                ),
              const SizedBox(height: 18),

              // ==========================================
              // 3. 360 Degree Picture
              // ==========================================
              if (data.v360Image == null && data.v360ImageUrl.isEmpty)
                _buildDottedBox(
                  text: 'add360degPicture'.translate(context),
                  height: 48.rh(context),
                  onTap: _pick360Image,
                )
              else
                Stack(
                  children: [
                    Container(
                      width: 100.rw(context),
                      height: 100.rh(context),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor),
                      ),
                      child: data.v360Image != null
                          ? Image.file(data.v360Image!, fit: BoxFit.cover)
                          : Image.network(
                              data.v360ImageUrl,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () async {
                          final path = data.v360Image != null
                              ? data.v360Image!.path
                              : data.v360ImageUrl;
                          await Navigator.push(
                            context,
                            CupertinoPageRoute<dynamic>(
                              builder: (context) {
                                return PanaromaImageScreen(
                                  imageUrl: path,
                                  isFileImage: data.v360Image != null,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          width: 100.rw(context),
                          height: 100.rh(context),
                          decoration: BoxDecoration(
                            color: context.color.tertiaryColor.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 28.rh(context),
                                  width: 28.rw(context),
                                  child: CustomImage(
                                    imageUrl: AppIcons.v360Degree,
                                    color: Colors.white,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 4.rh(context)),
                                CustomText(
                                  'view'.translate(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.font.xs,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            data
                              ..v360Image = null
                              ..v360ImageUrl = '';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.color.textColorDark.withValues(
                              alpha: 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CustomImage(
                            imageUrl: AppIcons.closeCircle,
                            height: 14.rh(context),
                            width: 14.rw(context),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 18.rh(context)),

              // ==========================================
              // 4. Video Preview (Youtube / Vimeo / Custom)
              // ==========================================
              CustomText(
                'videoPreview'.translate(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
              SizedBox(height: 8.rh(context)),
              _buildVideoTypeSelector(data),
              SizedBox(height: 10.rh(context)),
              _buildVideoInputContent(data, borderColor),
              SizedBox(height: 18.rh(context)),

              // ==========================================
              // 5. Property Documents
              // ==========================================
              CustomText(
                'propertyDocuments'.translate(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
              SizedBox(height: 8.rh(context)),
              _buildDottedBox(
                text:
                    (data.existingDocuments.isNotEmpty ||
                        data.propertyDocuments.isNotEmpty)
                    ? '${'UploadDocs'.translate(context)} ${data.existingDocuments.length + data.propertyDocuments.length}'
                    : 'UploadDocs'.translate(context),
                height: 120.rh(context),
                onTap: _pickDocuments,
              ),

              // Document list
              if (data.existingDocuments.isNotEmpty ||
                  data.propertyDocuments.isNotEmpty) ...[
                SizedBox(height: 10.rh(context)),
                ...data.existingDocuments.map((doc) {
                  return _buildDocumentCard(
                    fileName: doc.name.isNotEmpty
                        ? doc.name
                        : 'Property_Document.pdf',
                    borderColor: borderColor,
                    onDelete: () {
                      if (doc.id != null) {
                        setState(() {
                          data.existingDocuments.remove(doc);
                          data.removedDocumentIds.add(doc.id!);
                        });
                      }
                    },
                  );
                }),
                ...data.propertyDocuments.map((file) {
                  return _buildDocumentCard(
                    fileName: file.name,
                    borderColor: borderColor,
                    onDelete: () {
                      setState(() {
                        data.propertyDocuments.remove(file);
                      });
                    },
                  );
                }),
              ],
              SizedBox(height: 20.rh(context)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DOTTED UPLOAD BOX WIDGET
  // ==========================================
  Widget _buildDottedBox({
    required String text,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: context.color.textLightColor,
          radius: const Radius.circular(4),
        ),
        child: Container(
          height: height,
          width: double.infinity,
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

  // ==========================================
  // VIDEO TYPE SELECTOR TABS
  // ==========================================
  Widget _buildVideoTypeSelector(PropertyWizardData data) {
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
              ..videoUrl = _youtubeController.text;
          } else if (index == 1) {
            data
              ..videoType = 2
              ..videoUrl = _vimeoController.text;
          } else {
            data.videoType = 0;
          }
        });
      },
      tabs: [
        Tab(text: 'youtube'.translate(context)),
        Tab(text: 'vimeo'.translate(context)),
        Tab(text: 'custom'.translate(context)),
      ],
    );
  }

  // ==========================================
  // VIDEO INPUT CONTENT
  // ==========================================
  Widget _buildVideoInputContent(PropertyWizardData data, Color borderColor) {
    if (data.videoType == 1) {
      return CustomTextFormField(
        controller: _youtubeController,
        hintText: 'https://youtube.com/watch?v=...',
        borderRadius: 6,
        borderColor: borderColor,
        fillColor: context.color.secondaryColor,
        onChange: (val) => data.videoUrl = val?.toString() ?? '',
      );
    }
    if (data.videoType == 2) {
      return CustomTextFormField(
        controller: _vimeoController,
        hintText: 'https://vimeo.com/...',
        borderRadius: 6,
        borderColor: borderColor,
        fillColor: context.color.secondaryColor,
        onChange: (val) => data.videoUrl = val?.toString() ?? '',
      );
    }

    // Custom video file
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.customVideoFile == null)
          _buildDottedBox(
            text: 'uploadCustomVideo'.translate(context),
            height: 48.rh(context),
            onTap: _pickCustomVideo,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: context.color.tertiaryColor,
                ),
                SizedBox(width: 10.rw(context)),
                Expanded(
                  child: CustomText(
                    data.customVideoFile!.path.split('/').last,
                    fontSize: 13,
                    color: context.color.textColorDark,
                    maxLines: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      data.customVideoFile = null;
                    });
                  },
                  child: CustomImage(
                    imageUrl: AppIcons.closeCircle,
                    height: 18.rh(context),
                    color: errorMessageColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // DOCUMENT ITEM CARD
  // ==========================================
  Widget _buildDocumentCard({
    required String fileName,
    required Color borderColor,
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
              fileName,
              fontSize: 13,
              color: context.color.textColorDark,
              maxLines: 1,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: CustomImage(
              imageUrl: AppIcons.closeCircle,
              height: 18.rh(context),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UPLOAD PHOTO CARD (100x100 DOTTED BOX)
  // ==========================================
  Widget _buildUploadPhotoCard(
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 100.rw(context),
        height: 100.rw(context),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: context.color.textLightColor,
            radius: const Radius.circular(8),
          ),
          child: Center(
            child: CustomText(
              'uploadPhoto'.translate(context),
              textAlign: TextAlign.center,
              fontSize: 12,
              color: context.color.textColorDark,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CLOSE / REMOVE BUTTON
  // ==========================================
  Widget closeButton(BuildContext context, VoidCallback onTap) {
    return PositionedDirectional(
      top: 6,
      end: 6,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.color.primaryColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(4),
          child: CustomImage(
            imageUrl: AppIcons.closeCircle,
            height: 16.rh(context),
            color: errorMessageColor,
          ),
        ),
      ),
    );
  }
}
