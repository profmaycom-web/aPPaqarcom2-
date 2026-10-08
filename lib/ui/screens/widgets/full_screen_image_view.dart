import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:ebroker/app/app.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FullScreenImageView extends StatefulWidget {
  const FullScreenImageView({
    required this.provider,
    this.imageUrl,
    super.key,
    this.showDownloadButton,
    this.onTapDownload,
  });
  final ImageProvider provider;
  final String? imageUrl;
  final bool? showDownloadButton;
  final VoidCallback? onTapDownload;

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  String? get imageUrl {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return widget.imageUrl;
    }
    final provider = widget.provider;
    if (provider is NetworkImage) {
      return provider.url;
    }
    if (provider is CachedNetworkImageProvider) {
      return provider.url;
    }
    return null;
  }

  String getExtentionOfFile() {
    final name = getFileName();
    if (name.contains('.')) {
      return name.split('.').last;
    }
    return '';
  }

  String getFileName() {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      final name = url.split('/').last.split('?').first;
      if (name.isNotEmpty) return name;
    }
    return 'image.png';
  }

  Future<void> downloadFile() async {
    try {
      final downloadPath = await getDownloadPath();
      final url = imageUrl;
      if (url == null || url.isEmpty || !url.startsWith('http')) {
        return;
      }

      await Dio().download(
        url,
        '${downloadPath!}/${getFileName()}',
        onReceiveProgress: (count, total) async {
          final percentage = count / total;

          if (percentage == 1) {
            HelperUtils.showSnackBarMessage(
              context,
              'fileSavedIn',
              type: MessageType.success,
            );

            await OpenFilex.open('$downloadPath/${getFileName()}');
          }
          setState(() {});
        },
      );
    } on Exception catch (_) {
      HelperUtils.showSnackBarMessage(
        context,
        'errorFileSave',
        type: MessageType.error,
      );
    }
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } on Exception catch (_) {
      HelperUtils.showSnackBarMessage(
        context,
        'fileNotSaved',
        type: MessageType.error,
      );
    }
    return directory?.path;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl;
    final isNetworkUrl = resolvedUrl != null && resolvedUrl.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          actions: [
            if ((widget.showDownloadButton ?? false) && isNetworkUrl)
              IconButton(
                onPressed: () async {
                  await downloadFile();
                  widget.onTapDownload?.call();
                },
                icon: const Icon(Icons.download),
              ),
          ],
        ),
        backgroundColor: context.color.secondaryColor,
        body: InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: GestureDetector(
                onTap: () {},
                child: resolvedUrl != null && resolvedUrl.isNotEmpty
                    ? CustomImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.contain,
                      )
                    : Image(
                        image: widget.provider,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: context.color.tertiaryColor.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomImage(
                              imageUrl: appSettings.placeholderLogo!,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;

                          return FittedBox(
                            fit: BoxFit.none,
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: UiUtils.progress(),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension S on NetworkImage {
  String getURL() {
    return url;
  }
}
