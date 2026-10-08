import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

/// Country picker that allows more than one country, used where a country is
/// only a preference (personalized feed) and not the app-wide country.
///
/// Unlike the single-select country sheet, this never changes the selected
/// country of the app.
class CountryMultiSelectionBottomSheet extends StatefulWidget {
  const CountryMultiSelectionBottomSheet({
    this.initialSelectedIds = const [],
    super.key,
  });

  final List<int> initialSelectedIds;

  /// Returns the picked countries, or null when the sheet is dismissed.
  /// An empty list means "all countries".
  static Future<List<CountryModel>?> show(
    BuildContext context, {
    List<int> initialSelectedIds = const [],
  }) {
    return showModalBottomSheet<List<CountryModel>?>(
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
      builder: (context) => CountryMultiSelectionBottomSheet(
        initialSelectedIds: initialSelectedIds,
      ),
    );
  }

  @override
  State<CountryMultiSelectionBottomSheet> createState() =>
      _CountryMultiSelectionBottomSheetState();
}

class _CountryMultiSelectionBottomSheetState
    extends State<CountryMultiSelectionBottomSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late final Set<int> _selectedIds = widget.initialSelectedIds.toSet();

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

  void _toggle(CountryModel country) {
    final id = country.id;
    if (id == null) return;
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    });
  }

  void _apply(List<CountryModel> allCountries) {
    final selected = allCountries
        .where((c) => c.id != null && _selectedIds.contains(c.id))
        .toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: filteredCountries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected =
                          country.id != null &&
                          _selectedIds.contains(country.id);

                      return GestureDetector(
                        onTap: () => _toggle(country),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 48.rh(context),
                          alignment: AlignmentDirectional.centerStart,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.color.tertiaryColor
                                : context.color.textLightColor.withValues(
                                    alpha: 0.03,
                                  ),
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
                              Icon(
                                isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: isSelected
                                    ? context.color.buttonColor
                                    : context.color.textLightColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.rh(context)),
                Row(
                  children: [
                    Expanded(
                      child: UiUtils.buildButton(
                        context,
                        height: 44.rh(context),
                        showElevation: false,
                        buttonColor: context.color.primaryColor,
                        textColor: context.color.tertiaryColor,
                        border: BorderSide(color: context.color.tertiaryColor),
                        buttonTitle: 'allCountries'.translate(context),
                        onPressed: () {
                          setState(_selectedIds.clear);
                          Navigator.pop(context, <CountryModel>[]);
                        },
                      ),
                    ),
                    SizedBox(width: 12.rw(context)),
                    Expanded(
                      child: UiUtils.buildButton(
                        context,
                        height: 44.rh(context),
                        showElevation: false,
                        buttonTitle: 'apply'.translate(context),
                        onPressed: () => _apply(allCountries),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
