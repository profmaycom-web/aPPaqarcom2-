import 'package:dio/dio.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

class ListingGalleryPickerSheet {
  /// Shows a single unified grid combining the listing's title image (if
  /// any) with all of its gallery images, so the user can pick any one of
  /// them for the story.
  static Future<File?> show(
    BuildContext context, {
    required String? titleImage,
    required List<String> galleryImages,
  }) {
    final images = <String>[
      if (titleImage != null && titleImage.isNotEmpty) titleImage,
      for (final url in galleryImages)
        if (url != titleImage) url,
    ];
    return CustomBottomSheet.show<File>(
      context: context,
      title: 'selectStoryImage'.translate(context),
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: 500.rh(context)),
      child: _ListingGalleryPickerBody(imageUrls: images),
    );
  }
}

class _ListingGalleryPickerBody extends StatefulWidget {
  const _ListingGalleryPickerBody({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ListingGalleryPickerBody> createState() =>
      _ListingGalleryPickerBodyState();
}

class _ListingGalleryPickerBodyState extends State<_ListingGalleryPickerBody> {
  int? _downloadingIndex;

  Future<void> _onTapImage(int index) async {
    if (_downloadingIndex != null) return;
    setState(() => _downloadingIndex = index);
    try {
      final url = widget.imageUrls[index];
      final tempDir = await getTemporaryDirectory();
      final ext = url.split('.').last.split('?').first;
      final targetPath =
          '${tempDir.path}/story_gallery_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Dio().download(url, targetPath);
      final file = File(targetPath);
      if (!file.existsSync()) {
        throw Exception(
          'Downloaded gallery image not found at "$targetPath"',
        );
      }
      if (!mounted) return;
      Navigator.pop(context, file);
    } on Exception {
      if (!mounted) return;
      HelperUtils.showSnackBarMessage(
        context,
        'galleryImageDownloadFailed',
        type: .error,
      );
      setState(() => _downloadingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: 150.rh(context),
        child: Center(
          child: CustomText('noGalleryImagesFound'.translate(context)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(4.rw(context)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        final isDownloading = _downloadingIndex == index;
        return GestureDetector(
          onTap: () => unawaited(_onTapImage(index)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomImage(
                  imageUrl: widget.imageUrls[index],
                ),
              ),
              if (isDownloading)
                const ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
