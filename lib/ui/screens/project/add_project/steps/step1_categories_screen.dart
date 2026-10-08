import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/category/fetch_category_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/widgets/step_bottom_bar.dart';
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
    final cubit = context.watch<ProjectWizardCubit>();
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
              '1/6',
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
                    color: context.color.textColorDark,
                  ),
                );
              }

              return GridView.builder(
                physics: Constant.scrollPhysics,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      height: 85.rh(context),
                    ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory?.id == category.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        cubit.data.selectedCategory = category;
                        Constant.addProperty['category'] = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.color.tertiaryColor
                            : context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? context.color.tertiaryColor
                              : context.color.borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: context.color.tertiaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28.rw(context),
                            height: 28.rh(context),
                            child: CustomImage(
                              imageUrl: category.image ?? '',
                              color: isSelected
                                  ? context.color.buttonColor
                                  : context.color.textColorDark,
                            ),
                          ),
                          SizedBox(height: 6.rh(context)),
                          CustomText(
                            category.translatedName ?? category.category ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? context.color.buttonColor
                                : context.color.textColorDark,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
