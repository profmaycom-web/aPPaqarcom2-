import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/add_propery_screens/custom_fields/custom_field.dart';
import 'package:http_parser/http_parser.dart' as h;
import 'package:material_ui/material_ui.dart';
import 'package:mime/mime.dart';

class SetProeprtyParametersScreen extends StatefulWidget {
  const SetProeprtyParametersScreen({
    required this.propertyDetails,
    required this.isUpdate,
    super.key,
  });

  final Map<dynamic, dynamic> propertyDetails;
  final bool isUpdate;

  static Route<dynamic> route(RouteSettings settings) {
    final argument = settings.arguments as Map<dynamic, dynamic>?;

    return CupertinoPageRoute(
      builder: (context) {
        return SetProeprtyParametersScreen(
          propertyDetails: argument?['details'] as Map<dynamic, dynamic>? ?? {},
          isUpdate: argument?['isUpdate'] as bool,
        );
      },
    );
  }

  @override
  State<SetProeprtyParametersScreen> createState() =>
      _SetProeprtyParametersScreenState();
}

class _SetProeprtyParametersScreenState
    extends State<SetProeprtyParametersScreen>
    with AutomaticKeepAliveClientMixin {
  List<ValueNotifier<dynamic>> disposableFields = [];
  bool newCustomFields = true;
  final GlobalKey<FormState> _formKey = GlobalKey();
  List<dynamic> galleryImage = [];
  File? titleImage;
  File? t360degImage;
  ImagePickerValue<dynamic>? metaImage;
  Map<String, dynamic>? apiParameters;
  List<RenderCustomFields> paramaeterUI = [];
  bool paramIsRequired = false;

  @override
  void initState() {
    super.initState();
    apiParameters = Map.from(widget.propertyDetails);
    galleryImage = apiParameters!['gallery_images'] as List;
    titleImage = apiParameters!['title_image'] as File?;
    t360degImage = apiParameters!['three_d_image'] as File?;
    metaImage = apiParameters!['meta_image'] is File
        ? IdentifyValue(apiParameters!['meta_image'] as File).value
              as ImagePickerValue?
        : apiParameters!['meta_image'] as ImagePickerValue?;
    Future.delayed(
      Duration.zero,
      () {
        paramaeterUI =
            (Constant.addProperty['category']?.parameterTypes as List? ?? [])
                .mapIndexed((index, element) {
                  var data = element;

                  if (element is! Map) {
                    data = (element as Parameter).toMap();
                  }

                  // Pre-fill from apiParameters
                  final fieldId = data['id'].toString();
                  for (final key in apiParameters!.keys) {
                    if (key.contains('parameter_id') &&
                        apiParameters![key].toString() == fieldId) {
                      final indexPart = key.split('[')[1].split(']')[0];
                      final valueKey = 'parameters[$indexPart][value]';
                      if (apiParameters!.containsKey(valueKey)) {
                        data['value'] = apiParameters![valueKey];
                      }
                    }
                  }

                  return RenderCustomFields(
                    isRequired: data['is_required'] == 1,
                    index: index,
                    field:
                        KRegisteredFields().get(
                          data['type_of_parameter'].toString(),
                        ) ??
                        BlankField(),
                    data: data as Map<String, dynamic>,
                  );
                })
                .toList();

        setState(() {});
      },
    );
  }

  ///This will convert {0:Demo} to it's required format here we have assigned Parameter id : value, before.

  List<RenderCustomFields> buildFields() {
    if (Constant.addProperty['category'] == null) {
      return [
        RenderCustomFields(
          isRequired: false,
          field: BlankField(),
          data: const {},
          index: 0,
        ),
      ];
    }

    ///Loop parameters
    return paramaeterUI;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: widget.isUpdate
            ? 'updateProperty'.translate(context)
            : 'ddPropertyLbl'.translate(context),
        actions: [
          CustomText(
            '3/4',
            fontSize: context.font.sm,
            fontWeight: .w500,
            color: context.color.textColorDark,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: UiUtils.buildButton(
          context,
          height: 48.rh(context),
          onPressed: () async {
            final parameterValues = paramaeterUI.fold<Map<String, dynamic>>(
              {},
              (previousValue, element) {
                final value = element.getValue();
                if (value != null && value.toString().isNotEmpty) {
                  previousValue.addAll({
                    'parameters[${previousValue.length ~/ 2}][parameter_id]':
                        element.getId(),
                    'parameters[${previousValue.length ~/ 2}][value]': value,
                  });
                }
                return previousValue;
              },
            );
            apiParameters?.addAll(Map.from(parameterValues));

            // Check if all required parameters are filled

            for (final element in paramaeterUI) {
              if (element.isRequired) {
                if (element.data['image'] == '' ||
                    element.data['image'] == null ||
                    element.getValue() == null ||
                    element.getValue().toString().trim().isEmpty ||
                    element.getValue() == '') {
                  HelperUtils.showSnackBarMessage(
                    context,
                    'pleaseFillRequiredFields',
                    type: .error,
                  );
                  return;
                }
              }
            }
            final gallery = <MultipartFile>[];
            await Future.forEach(
              galleryImage,
              (item) async {
                final multipartFile = await MultipartFile.fromFile(
                  (item?.path ?? '').toString(),
                );
                if (!multipartFile.isFinalized) {
                  gallery.add(multipartFile);
                }
              },
            );
            apiParameters!['gallery_images'] = gallery;

            if (titleImage != null) {
              final bytes = await File(titleImage!.path).readAsBytes();
              apiParameters!['title_image'] = MultipartFile.fromBytes(
                bytes,
                filename: titleImage!.path.split('/').last,
                contentType: h.MediaType(
                  'image',
                  'jpeg',
                ), // or determine dynamically
              );
            }
            if (t360degImage != null) {
              final mimeType = lookupMimeType(t360degImage!.path);
              final extension = mimeType!.split('/');
              apiParameters!['three_d_image'] = await MultipartFile.fromFile(
                t360degImage?.path ?? '',
                contentType: h.MediaType('image', extension[1]),
                filename: t360degImage?.path.split('/').last,
              );
            }

            if (metaImage != null && metaImage is FileValue) {
              final mimeType = lookupMimeType(
                metaImage!.value.path?.toString() ?? '',
              );
              final extension = mimeType!.split('/');
              apiParameters!['meta_image'] = await MultipartFile.fromFile(
                metaImage?.value.path?.toString() ?? '',
                contentType: h.MediaType('image', extension[1]),
                filename: metaImage?.value.path.split('/').last?.toString(),
              );
            } else if (metaImage != null && metaImage is UrlValue) {
              apiParameters!['meta_image'] = (metaImage! as UrlValue).value;
            }

            apiParameters?['isUpdate'] = widget.isUpdate;
            await Navigator.pushNamed(
              context,
              Routes.selectOutdoorFacility,
              arguments: apiParameters,
            );
          },
          buttonTitle: 'continue'.translate(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText('addvalues'.translate(context)),
                  SizedBox(height: 16.rh(context)),
                  ...buildFields(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
