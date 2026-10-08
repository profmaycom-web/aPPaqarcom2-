import 'package:dio/dio.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailsWidget extends StatelessWidget {
  const ContactDetailsWidget({
    required this.url,
    required this.name,
    required this.email,
    required this.number,
    super.key,
  });

  final String url;
  final String name;
  final String email;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.rh(context)),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4.rh(context)),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'contactUS'.translate(context),
            fontWeight: .bold,
            fontSize: context.font.md,
          ),
          SizedBox(height: 15.rh(context)),
          Row(
            children: [
              Container(
                width: 70.rw(context),
                height: 70.rh(context),
                clipBehavior: .antiAlias,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10.rh(context)),
                ),
                child: CustomImage(
                  imageUrl: url,
                  showFullScreenImage: true,
                ),
              ),
              SizedBox(width: 10.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(
                      name,
                      maxLines: 1,
                      fontWeight: .bold,
                      fontSize: context.font.md,
                    ),
                    CustomText(
                      email,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: .end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.color.borderColor),
                      borderRadius: BorderRadius.circular(10.rh(context)),
                      color: context.color.secondaryColor,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await launchUrl(Uri.parse('mailto:$email'));
                      },
                      icon: Icon(
                        Icons.email,
                        color: context.color.tertiaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.rw(context)),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.color.borderColor),
                      borderRadius: BorderRadius.circular(10.rh(context)),
                      color: context.color.secondaryColor,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await launchUrl(Uri.parse('tel:+$number'));
                      },
                      icon: Icon(
                        Icons.call,
                        color: context.color.tertiaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DownloadableDocument extends StatefulWidget {
  const DownloadableDocument({
    required this.url,
    super.key,
  });

  final String url;

  @override
  State<DownloadableDocument> createState() => _DownloadableDocumentState();
}

class _DownloadableDocumentState extends State<DownloadableDocument> {
  bool downloaded = false;
  Dio dio = Dio();
  ValueNotifier<double> percentage = ValueNotifier(0);

  Future<String?>? path() async {
    final downloadPath = await HelperUtils.getDownloadPath();
    return downloadPath;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.url.split('/').last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              name,
              color: context.color.textColorDark,
              fontSize: context.font.sm,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder(
            valueListenable: percentage,
            builder: (context, value, child) {
              if (value != 0.0 && value != 1.0) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.color.textColorDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 2,
                        color: context.color.tertiaryColor,
                      ),
                    ),
                  ),
                );
              }
              if (downloaded) {
                return GestureDetector(
                  onTap: () async {
                    final downloadPath = await path();
                    await OpenFilex.open('$downloadPath/$name');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.color.textColorDark.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CustomImage(
                        imageUrl: AppIcons.arrowRight,
                        color: context.color.textColorDark,
                        width: 18,
                        height: 18,
                        matchTextDirection: true,
                      ),
                    ),
                  ),
                );
              }
              return GestureDetector(
                onTap: () async {
                  final downloadPath = await path();
                  await dio.download(
                    widget.url,
                    '$downloadPath/$name',
                    onReceiveProgress: (count, total) async {
                      percentage.value = count / total;
                      if (percentage.value == 1.0) {
                        downloaded = true;
                        setState(() {});
                        await OpenFilex.open('$downloadPath/$name');
                      }
                    },
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.color.textColorDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: CustomImage(
                      imageUrl: AppIcons.documentDownload,
                      color: context.color.textColorDark,
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CustomFloorPlanTile extends StatefulWidget {
  const CustomFloorPlanTile({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  State<CustomFloorPlanTile> createState() => _CustomFloorPlanTileState();
}

class _CustomFloorPlanTileState extends State<CustomFloorPlanTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          dense: true,
          title: CustomText(
            widget.title,
            color: context.color.textColorDark,
            fontSize: context.font.sm,
            fontWeight: FontWeight.w400,
          ),
          trailing: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.color.textColorDark.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                isExpanded ? Icons.remove : Icons.add,
                color: context.color.textColorDark,
                size: 20,
              ),
            ),
          ),
          onExpansionChanged: (value) {
            setState(() {
              isExpanded = value;
            });
          },
          children: widget.children,
        ),
      ),
    );
  }
}
