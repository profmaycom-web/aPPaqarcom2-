import 'package:ebroker/data/cubits/fetch_properties_by_cities_cubit.dart';
import 'package:ebroker/data/model/city_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/city_card.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_grid.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:material_ui/material_ui.dart';

class CityPropertiesSection extends StatelessWidget {
  const CityPropertiesSection({
    required this.title,
    required this.cities,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<City> cities;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child:
          BlocBuilder<
            FetchPropertiesByCitiesCubit,
            FetchPropertiesByCitiesState
          >(
            builder: (context, state) {
              if (state is! FetchPropertiesByCitiesSuccess) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  if (state.isWithImage)
                    _ImageHeader(
                      title: title,
                      cities: cities,
                      isWithImage: state.isWithImage,
                    )
                  else
                    TitleHeader(
                      title: title,
                      enableShowAll: cities.length > 1,
                      onSeeAll: () async {
                        await Navigator.pushNamed(
                          context,
                          Routes.cityListScreen,
                          arguments: {
                            'title': title,
                            'isWithImage': state.isWithImage,
                          },
                        );
                      },
                    ),
                  if (state.isWithImage)
                    CustomImageGrid(cities: cities)
                  else
                    SizedBox(
                      height: 126.rh(context),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _sidePadding,
                        ),
                        separatorBuilder: (context, index) =>
                            SizedBox(width: 8.rw(context)),
                        itemCount: cities.length,
                        physics: Constant.scrollPhysics,
                        scrollDirection: .horizontal,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          return CityCard(
                            city: city,
                            name: city.name,
                            count: city.count,
                            isWithImage: false,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({
    required this.title,
    required this.cities,
    required this.isWithImage,
  });

  final String title;
  final List<City> cities;
  final bool isWithImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: cities.length > 1
            ? () async {
                await Navigator.pushNamed(
                  context,
                  Routes.cityListScreen,
                  arguments: {
                    'title': title,
                    'isWithImage': isWithImage,
                  },
                );
              }
            : null,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              width: context.screenWidth,
              height: 120.rh(context),
              child: CustomImage(
                width: double.infinity,
                height: 120.rh(context),
                imageUrl: AppIcons.citySectionTitleImage,
                fit: .fitWidth,
              ),
            ),
            Container(
              width: context.screenWidth,
              height: 120.rh(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: 18,
              start: 18,
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3.rw(context),
                        height: 20.rh(context),
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.rw(context)),
                      CustomText(
                        title.firstUpperCase(),
                        color: Colors.white,
                        fontWeight: .w700,
                        fontSize: context.font.md,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.rh(context)),
                  CustomText(
                    '${cities.length.clamp(0, 10)}${cities.length > 10 ? '+' : ''} ${'cities'.translate(context)}',
                    color: Colors.white,
                    fontWeight: .w600,
                    fontSize: context.font.xs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
