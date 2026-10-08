import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/outdoorfacility/fetch_outdoor_facility_list.dart';
import 'package:ebroker/data/model/outdoor_facility.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class Step5OutdoorFacilitiesScreen extends StatefulWidget {
  const Step5OutdoorFacilitiesScreen({
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
  State<Step5OutdoorFacilitiesScreen> createState() =>
      _Step5OutdoorFacilitiesScreenState();
}

class _Step5OutdoorFacilitiesScreenState
    extends State<Step5OutdoorFacilitiesScreen> {
  final Map<int, TextEditingController> _distanceControllers = {};
  final PageController _pageController = PageController();
  int _selectedPage = 0;
  static const int _itemsPerPage = 9;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<FetchOutdoorFacilityListCubit>().fetchIfFailed());

    final data = context.read<PropertyWizardCubit>().data;
    for (final fId in data.selectedOutdoorFacilityIds) {
      _distanceControllers[fId] = TextEditingController(
        text: data.outdoorDistances[fId] ?? '',
      );
    }
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
    _pageController.dispose();
    for (final c in _distanceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncToCubit() {
    final cubit = _wizardCubit;
    for (final entry in _distanceControllers.entries) {
      cubit.data.outdoorDistances[entry.key] = entry.value.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PropertyWizardCubit>();
    final data = cubit.data;

    final borderColor = context.color.borderColor;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'outdoorFacilities'.translate(context),
        onTapBackButton: () {
          _syncToCubit();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '5/7',
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
        child:
            BlocBuilder<
              FetchOutdoorFacilityListCubit,
              FetchOutdoorFacilityListState
            >(
              builder: (context, state) {
                if (state is FetchOutdoorFacilityListInProgress) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (state is FetchOutdoorFacilityListFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          'Failed to load outdoor facilities',
                          color: context.color.textColorDark,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context
                              .read<FetchOutdoorFacilityListCubit>()
                              .fetch(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final facilities = context
                    .read<FetchOutdoorFacilityListCubit>()
                    .getList();

                final totalPages = (facilities.length / _itemsPerPage).ceil();

                return SingleChildScrollView(
                  physics: Constant.scrollPhysics,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // 1. SELECT PLACES TITLE
                      // ==========================================
                      CustomText(
                        'selectPlaces'.translate(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.color.textColorDark,
                      ),
                      const SizedBox(height: 12),

                      // ==========================================
                      // 2. 9-ITEM GRID WITH SCROLLABLE PAGEVIEW
                      // ==========================================
                      if (facilities.isNotEmpty) ...[
                        SizedBox(
                          height: 285.rh(context),
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: totalPages,
                            onPageChanged: (page) {
                              setState(() => _selectedPage = page);
                            },
                            itemBuilder: (context, pageIndex) {
                              final startIndex = pageIndex * _itemsPerPage;
                              final endIndex =
                                  (startIndex + _itemsPerPage) >
                                      facilities.length
                                  ? facilities.length
                                  : (startIndex + _itemsPerPage);

                              final pageFacilities = facilities.sublist(
                                startIndex,
                                endIndex,
                              );

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      height: 85.rh(context),
                                    ),
                                itemCount: pageFacilities.length,
                                itemBuilder: (context, index) {
                                  final f = pageFacilities[index];
                                  final isSelected = data
                                      .selectedOutdoorFacilityIds
                                      .contains(f.id);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          data.selectedOutdoorFacilityIds
                                              .remove(f.id);
                                          _distanceControllers[f.id]?.dispose();
                                          _distanceControllers.remove(f.id);
                                          data.outdoorDistances.remove(f.id);
                                        } else if (f.id != null) {
                                          data.selectedOutdoorFacilityIds.add(
                                            f.id!,
                                          );
                                          final ctrl = TextEditingController(
                                            text:
                                                data.outdoorDistances[f.id!] ??
                                                '',
                                          );
                                          _distanceControllers[f.id!] = ctrl;
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? context.color.tertiaryColor
                                            : context.color.secondaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? context.color.tertiaryColor
                                              : borderColor,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CustomImage(
                                              imageUrl: f.image ?? '',
                                              color: isSelected
                                                  ? context.color.buttonColor
                                                  : context.color.textColorDark,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: CustomText(
                                              f.name ?? '',
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? context.color.buttonColor
                                                  : context.color.textColorDark,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // ==========================================
                        // 3. PAGE INDICATOR (DOTS)
                        // ==========================================
                        if (totalPages > 1) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(totalPages, (index) {
                              final isSelected = _selectedPage == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: isSelected ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.color.tertiaryColor
                                      : context.color.textColorDark.withValues(
                                          alpha: 0.25,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],

                      // ==========================================
                      // 4. SELECTED ITEMS SECTION
                      // ==========================================
                      if (data.selectedOutdoorFacilityIds.isNotEmpty) ...[
                        SizedBox(height: 24.rh(context)),
                        CustomText(
                          'selectedItems'.translate(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.color.textColorDark,
                        ),
                        SizedBox(height: 12.rh(context)),
                        ...facilities
                            .where(
                              (f) => data.selectedOutdoorFacilityIds.contains(
                                f.id,
                              ),
                            )
                            .map((f) {
                              final ctrl = _distanceControllers.putIfAbsent(
                                f.id!,
                                () => TextEditingController(
                                  text: data.outdoorDistances[f.id!] ?? '',
                                ),
                              );

                              return _buildSelectedItemRow(
                                facility: f,
                                controller: ctrl,
                                borderColor: borderColor,
                                data: data,
                              );
                            }),
                      ],
                      SizedBox(height: 20.rh(context)),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  // ==========================================
  // SELECTED ITEM DISTANCE ROW WIDGET
  // ==========================================
  Widget _buildSelectedItemRow({
    required OutdoorFacility facility,
    required TextEditingController controller,
    required Color borderColor,
    required PropertyWizardData data,
  }) {
    final distanceSuffix = AppSettings.distanceOption.isNotEmpty
        ? AppSettings.distanceOption.translate(context).toUpperCase()
        : 'KM';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Light-teal Icon Container
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomImage(
                imageUrl: facility.image ?? '',
                color: context.color.tertiaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Facility Name
          Expanded(
            child: CustomText(
              facility.name ?? '',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.color.textColorDark,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 12),

          // Distance Input Field Container
          SizedBox(
            width: 140,
            child: CustomTextFormField(
              controller: controller,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              hintText: '00',
              borderRadius: 8,
              borderColor: borderColor,
              fillColor: context.color.secondaryColor,
              formaters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              suffix: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: CustomText(
                  distanceSuffix,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.color.textLightColor,
                ),
              ),
              onChange: (val) {
                if (facility.id != null) {
                  data.outdoorDistances[facility.id!] = val?.toString() ?? '';
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
