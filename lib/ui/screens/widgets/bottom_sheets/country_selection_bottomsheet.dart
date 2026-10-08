import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class CountrySelectionBottomSheet extends StatefulWidget {
  const CountrySelectionBottomSheet({
    this.showAllOption = true,
    super.key,
  });

  final bool showAllOption;

  static Future<CountryModel?> show(
    BuildContext context, {
    bool showAllOption = true,
  }) {
    return showModalBottomSheet<CountryModel?>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      backgroundColor: context.color.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => CountrySelectionBottomSheet(
        showAllOption: showAllOption,
      ),
    );
  }

  @override
  State<CountrySelectionBottomSheet> createState() =>
      _CountrySelectionBottomSheetState();
}

class _CountrySelectionBottomSheetState
    extends State<CountrySelectionBottomSheet> {
  String _searchQuery = '';
  bool _isApplying = false;
  final TextEditingController _searchController = TextEditingController();

  /// Applies the selection through a single entry point so the country change
  /// triggers exactly one app refresh, and blocks the sheet meanwhile so a
  /// second tap can't fire another round of requests.
  Future<void> _onCountrySelected(CountryModel country) async {
    if (_isApplying) return;
    setState(() => _isApplying = true);
    try {
      await LanguageChangeHelper.applyCountrySelection(context, country);
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
        Navigator.pop(context, country);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(context.read<FetchCountriesCubit>().fetchCountries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isApplying,
      child: Stack(
        children: [
          _buildSheet(context),
          if (_isApplying) _buildApplyingOverlay(context),
        ],
      ),
    );
  }

  Widget _buildApplyingOverlay(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: context.color.secondaryColor.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UiUtils.progress(),
              SizedBox(height: 12.rh(context)),
              CustomText(
                'loading'.translate(context),
                color: context.color.textColorDark,
                fontSize: context.font.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final selectedCountryName = HiveUtils.getSelectedCountryName() ?? '';
    final selectedCountryId =
        HiveUtils.getSelectedCountryId() ?? AppSettings.currentCountryId;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: CustomBottomSheet(
        title: 'pleaseSelectCountry'.translate(context),
        child: BlocBuilder<FetchCountriesCubit, FetchCountriesState>(
          builder: (context, state) {
            final allCountries = state is FetchCountriesSuccess
                ? state.countries
                : context.read<FetchCountriesCubit>().countries;

            if (state is FetchCountriesInProgress && allCountries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CustomShimmer(
                        height: 48.rh(context),
                        borderRadius: 4,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (state is FetchCountriesFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        state.errorMessage,
                        color: context.color.textColorDark,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          unawaited(
                            context.read<FetchCountriesCubit>().fetchCountries(
                              forceRefresh: true,
                            ),
                          );
                        },
                        child: CustomText('retry'.translate(context)),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (allCountries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CustomText('noCountryFound'.translate(context)),
                ),
              );
            }

            final filteredCountries = _searchQuery.isEmpty
                ? allCountries
                : allCountries
                      .where(
                        (c) => (c.name ?? '').toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

            final showAllOption =
                widget.showAllOption &&
                (_searchQuery.isEmpty ||
                    'all'.contains(_searchQuery.toLowerCase()) ||
                    'all countries'.contains(_searchQuery.toLowerCase()) ||
                    'allCountries'
                        .translate(context)
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()));

            final isAllSelected =
                selectedCountryId.isEmpty ||
                selectedCountryName.isEmpty ||
                selectedCountryName.toLowerCase() == 'all';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allCountries.length > 5) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomTextFormField(
                      controller: _searchController,
                      hintText: 'search'.translate(context),
                      prefix: Icon(
                        Icons.search,
                        color: context.color.textColorDark.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      onChange: (val) {
                        setState(() {
                          _searchQuery = val?.toString().trim() ?? '';
                        });
                      },
                    ),
                  ),
                ],
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        filteredCountries.length + (showAllOption ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (showAllOption && index == 0) {
                        final isSelected = isAllSelected;
                        final itemColor = isSelected
                            ? context.color.tertiaryColor
                            : context.color.textLightColor.withValues(
                                alpha: 0.03,
                              );

                        return GestureDetector(
                          onTap: () async {
                            await _onCountrySelected(
                              const CountryModel(name: 'all'),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 48.rh(context),
                            alignment: AlignmentDirectional.centerStart,
                            decoration: BoxDecoration(
                              color: itemColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    'allCountries'.translate(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.font.md,
                                    color: isSelected
                                        ? context.color.buttonColor
                                        : context.color.textColorDark,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: context.color.buttonColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      final country =
                          filteredCountries[showAllOption ? index - 1 : index];
                      final isSelected =
                          !isAllSelected &&
                          ((selectedCountryId.isNotEmpty &&
                                  country.id?.toString() ==
                                      selectedCountryId) ||
                              (selectedCountryName.isNotEmpty &&
                                  country.name?.toLowerCase() ==
                                      selectedCountryName.toLowerCase()));

                      final itemColor = isSelected
                          ? context.color.tertiaryColor
                          : context.color.textLightColor.withValues(
                              alpha: 0.03,
                            );

                      return GestureDetector(
                        onTap: () async {
                          await _onCountrySelected(country);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 48.rh(context),
                          alignment: AlignmentDirectional.centerStart,
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: CustomText(
                                  country.name ?? '',
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.font.md,
                                  color: isSelected
                                      ? context.color.buttonColor
                                      : context.color.textColorDark,
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: context.color.buttonColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
