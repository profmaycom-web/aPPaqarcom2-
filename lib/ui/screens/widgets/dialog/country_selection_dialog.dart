import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class CountrySelectionDialog extends StatefulWidget {
  const CountrySelectionDialog({super.key});

  @override
  State<CountrySelectionDialog> createState() => _CountrySelectionDialogState();
}

class _CountrySelectionDialogState extends State<CountrySelectionDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    final selectedCountryName = HiveUtils.getSelectedCountryName() ?? '';
    final selectedCountryId =
        HiveUtils.getSelectedCountryId() ?? AppSettings.currentCountryId;

    return Dialog(
      backgroundColor: context.color.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.color.borderColor),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20.rw(context),
        vertical: 24.rh(context),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 420.rw(context),
        ),
        padding: EdgeInsets.all(16.rw(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    'selectCountry'.translate(context),
                    fontSize: context.font.lg,
                    fontWeight: FontWeight.w700,
                    color: context.color.textColorDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.color.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: context.color.textColorDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.rh(context)),
            // Body with FetchCountriesCubit
            Flexible(
              child: BlocBuilder<FetchCountriesCubit, FetchCountriesState>(
                builder: (context, state) {
                  final allCountries = state is FetchCountriesSuccess
                      ? state.countries
                      : context.read<FetchCountriesCubit>().countries;

                  if (state is FetchCountriesInProgress &&
                      allCountries.isEmpty) {
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
                              borderRadius: 8,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is FetchCountriesFailure) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
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
                                context
                                    .read<FetchCountriesCubit>()
                                    .fetchCountries(forceRefresh: true),
                              );
                            },
                            child: CustomText('retry'.translate(context)),
                          ),
                        ],
                      ),
                    );
                  }

                  if (allCountries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
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
                                (selectedCountryId.isNotEmpty &&
                                    country.id?.toString() ==
                                        selectedCountryId) ||
                                (selectedCountryName.isNotEmpty &&
                                    country.name?.toLowerCase() ==
                                        selectedCountryName.toLowerCase());

                            final itemColor = isSelected
                                ? context.color.tertiaryColor
                                : context.color.textLightColor.withValues(
                                    alpha: 0.04,
                                  );

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context, country);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 48.rh(context),
                                alignment: AlignmentDirectional.centerStart,
                                decoration: BoxDecoration(
                                  color: itemColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? context.color.tertiaryColor
                                        : context.color.borderColor.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: CustomText(
                                        country.name ?? '',
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: context.font.md,
                                        color: isSelected
                                            ? context.color.buttonColor
                                            : context.color.textColorDark,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
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
          ],
        ),
      ),
    );
  }
}
