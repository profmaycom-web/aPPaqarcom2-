import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/category/fetch_category_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/widgets/step_bottom_bar.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class Step1CategoriesScreen extends StatefulWidget {
  const Step1CategoriesScreen({
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
  State<Step1CategoriesScreen> createState() => _Step1CategoriesScreenState();
}

class _Step1CategoriesScreenState extends State<Step1CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    final catCubit = context.read<FetchCategoryCubit>();
    if (catCubit.state is! FetchCategorySuccess) {
      unawaited(catCubit.fetchCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PropertyWizardCubit>();
    final selectedCategory = cubit.data.selectedCategory;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'selectCategory'.translate(context),
        onTapBackButton: widget.onBack,
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              '1/7',
              fontSize: context.font.md,
              fontWeight: .w600,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
      bottomNavigationBar: StepBottomBar(
        onNext: () {
          if (cubit.data.selectedCategory == null) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseSelectCategory'.translate(context),
              type: MessageType.error,
            );
            return;
          }
          widget.onNext();
        },
        onSaveDraft: widget.onSaveDraft,
        isSavingDraft: widget.isSavingDraft,
      ),
      body: SafeArea(
        child: BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
          builder: (context, state) {
            if (state is FetchCategoryInProgress) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (state is FetchCategoryFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      state.errorMessage,
                      color: context.color.textColorDark,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.rh(context)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.color.tertiaryColor,
                      ),
                      onPressed: () =>
                          context.read<FetchCategoryCubit>().fetchCategories(),
                      child: CustomText(
                        'retry'.translate(context),
                        color: context.color.buttonColor,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is FetchCategorySuccess) {
              final categories = state.categories;
              if (categories.isEmpty) {
                return Center(
                  child: CustomText(
                    'noCategoryFound'.translate(context),
                    fontSize: context.font.md,
                    color: context.color.textColorDark,
                  ),
                );
              }

              return SingleChildScrollView(
                physics: Constant.scrollPhysics,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        height: 85.rh(context),
                      ),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory?.id == cat.id;

                    return GestureDetector(
                      onTap: () {
                        cubit.data.selectedCategory = cat;
                        cubit.notifyState();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.color.tertiaryColor
                              : context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? context.color.tertiaryColor
                                : context.color.borderColor.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 28.rw(context),
                              height: 28.rh(context),
                              child: CustomImage(
                                imageUrl: cat.image ?? '',
                                color: isSelected
                                    ? context.color.buttonColor
                                    : context.color.textColorDark,
                              ),
                            ),
                            SizedBox(height: 6.rh(context)),
                            CustomText(
                              cat.translatedName ?? cat.category ?? '',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? context.color.buttonColor
                                  : context.color.textColorDark,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
