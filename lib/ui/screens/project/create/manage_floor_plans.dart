import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class ManageFloorPlansScreen extends StatefulWidget {
  const ManageFloorPlansScreen({required this.floorPlans, super.key});
  final List<Map<String, dynamic>>? floorPlans;

  static CupertinoPageRoute<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return ManageFloorPlansScreen(
          floorPlans: (arguments?['floorPlan'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      },
    );
  }

  @override
  CloudState<ManageFloorPlansScreen> createState() =>
      _ManageFloorPlansScreenState();
}

class _ManageFloorPlansScreenState extends CloudState<ManageFloorPlansScreen> {
  List<FloorPlan> floorPlans = [];
  List<int> removePlanId = [];

  final GlobalKey<FormState> _formKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    final initialFloorsList = <Map<String, dynamic>>[];
    if (widget.floorPlans != null && widget.floorPlans!.isNotEmpty) {
      widget.floorPlans?.forEach((value) {
        final planKey = value['id'] is int
            ? ValueKey(value['id'])
            : value['id'] is ValueKey?
            ? value['id'] as ValueKey
            : ValueKey(value['id'].toString());
        final imageVal =
            (value['image'] is String
                    ? UrlValue(value['image']?.toString() ?? '')
                    : value['image'] is UrlValue
                    ? value['image'] as UrlValue
                    : value['image'] is FileValue
                    ? value['image'] as FileValue
                    : UrlValue(''))
                as ImagePickerValue<dynamic>;

        initialFloorsList.add({
          'title': value['title']?.toString() ?? '',
          'id': planKey,
          'image': imageVal,
        });

        final floorPlan = FloorPlan(
          planKey: planKey,
          title: value['title']?.toString() ?? '',
          imagePickerValue: imageVal,
          onClose: (e) {
            removeFromListWhere(
              listKey: 'floorsList',
              whereKey: 'id',
              equals: e,
            );
            if (e is ValueKey) {
              final val = e.value;
              if (val is int) {
                removePlanId.add(val);
              } else if (val != null) {
                final parsed = int.tryParse(val.toString());
                if (parsed != null) {
                  removePlanId.add(parsed);
                }
              }
            }
            floorPlans.removeWhere((element) => element.planKey == e);
            setState(() {});
          },
        );
        floorPlans.add(floorPlan);
      });
    } else {
      final planKey = GlobalKey();
      final floorPlan = FloorPlan(
        planKey: planKey,
        key: UniqueKey(),
        onClose: (key) {
          removeFromListWhere(
            listKey: 'floorsList',
            whereKey: 'id',
            equals: key,
          );
          if (key is ValueKey) {
            final val = key.value;
            if (val is int) {
              removePlanId.add(val);
            } else if (val != null) {
              final parsed = int.tryParse(val.toString());
              if (parsed != null) {
                removePlanId.add(parsed);
              }
            }
          }
          floorPlans.removeWhere((element) => element.planKey == key);
          setState(() {});
        },
      );
      floorPlans.add(floorPlan);
    }
    setCloudData('floorsList', initialFloorsList);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        clearGroup('floors');
        clearGroup('floorsList');
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: 'floorPlans'.translate(context),
        ),
        bottomNavigationBar: BottomAppBar(
          color: context.color.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: context.color.tertiaryColor,
              onPressed: () {
                final floors = getCloudData('floorsList') as List<Map>?;

                Navigator.pop(context, {
                  'floorPlans': floors,
                  'removed': removePlanId,
                });
              },
              height: 50,
              child: CustomText(
                'continue'.translate(context),
                color: context.color.secondaryColor,
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: SizedBox(
              width: context.screenWidth,
              child: Column(
                children: [
                  ...floorPlans,
                  MaterialButton(
                    color: context.color.tertiaryColor,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final floorPlan = FloorPlan(
                          planKey: GlobalKey(),
                          key: UniqueKey(),
                          onClose: (e) {
                            removeFromListWhere(
                              listKey: 'floorsList',
                              whereKey: 'id',
                              equals: e,
                            );
                            if (e is ValueKey) {
                              final val = e.value;
                              if (val is int) {
                                removePlanId.add(val);
                              } else if (val != null) {
                                final parsed = int.tryParse(val.toString());
                                if (parsed != null) {
                                  removePlanId.add(parsed);
                                }
                              }
                            }
                            floorPlans.removeWhere(
                              (element) => element.planKey == e,
                            );
                            setState(() {});
                          },
                        );
                        floorPlans.add(floorPlan);
                        setState(() {});
                      }
                    },
                    elevation: 0,
                    minWidth: context.screenWidth * 0.45,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      'Add'.translate(context),
                      color: context.color.buttonColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FloorPlan extends StatefulWidget {
  const FloorPlan({
    required this.planKey,
    required this.onClose,
    super.key,
    this.title,
    this.imagePickerValue,
  });
  final Key planKey;
  final String? title;
  final ImagePickerValue<dynamic>? imagePickerValue;
  final dynamic Function(Key e) onClose;

  @override
  CloudState<FloorPlan> createState() {
    return FloorPlanState();
  }
}

class FloorPlanState extends CloudState<FloorPlan> {
  ImagePickerValue<dynamic>? imagePickerValue;

  late final TextEditingController floorTitle = TextEditingController(
    text: widget.title,
  );

  @override
  void initState() {
    super.initState();
    imagePickerValue = widget.imagePickerValue;
  }

  @override
  void dispose() {
    floorTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              CustomText('Floor Title'.translate(context)),
              const Spacer(),
              IconButton(
                onPressed: () {
                  widget.onClose.call(widget.planKey);
                },
                icon: Icon(
                  Icons.close,
                  size: 16.rw(context),
                  color: context.color.textColorDark,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          CustomTextFormField(
            controller: floorTitle,
            autovalidate: AutovalidateMode.onUserInteraction,
            validator: CustomTextFieldValidator.nullCheck,
            onChange: (value) {
              appendToListWhere(
                listKey: 'floorsList',
                whereKey: 'id',
                equals: widget.planKey,
                add: {
                  'title': value,
                  'id': widget.planKey,
                  'image': imagePickerValue,
                },
              );
            },
            hintText: 'Title'.translate(context),
          ),
          SizedBox(height: 10.rh(context)),
          AdaptiveImagePickerWidget(
            multiImage: false,
            isRequired: true,
            value: imagePickerValue,
            title: 'pickFloorMap'.translate(context),
            onSelect: (selected) {
              if (selected is FileValue) {
                imagePickerValue = selected;
              }
              appendToListWhere(
                listKey: 'floorsList',
                whereKey: 'id',
                equals: widget.planKey,
                add: {
                  'title': floorTitle.text,
                  'id': widget.planKey,
                  'image': imagePickerValue,
                },
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
