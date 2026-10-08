import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/advertisement/fetch_ad_banners_cubit.dart';
import 'package:ebroker/data/cubits/fetch_home_page_data_cubit.dart';
import 'package:ebroker/data/cubits/fetch_home_sections_data_cubit.dart';
import 'package:ebroker/data/cubits/fetch_other_sections_cubit.dart';
import 'package:ebroker/data/cubits/fetch_project_sections_cubit.dart';
import 'package:ebroker/data/cubits/fetch_properties_by_cities_cubit.dart';
import 'package:ebroker/data/cubits/fetch_property_sections_cubit.dart';
import 'package:ebroker/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:ebroker/data/model/home_page_data_model.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/home_sections.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:ebroker/ui/screens/home/widgets/home_location_widget.dart';
import 'package:ebroker/ui/screens/home/widgets/home_search.dart';
import 'package:ebroker/ui/screens/home/widgets/home_shimmers.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/agents_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/all_properties_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/articles_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/categories_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/city_properties_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/curated_projects_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/curated_properties_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/featured_projects_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/featured_properties_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/most_liked_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/most_viewed_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/nearby_properties_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/personalized_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/premium_projects_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/premium_properties_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/projects_section.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/slider_section.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:ebroker/utils/hive_keys.dart';
import 'package:ebroker/utils/network/network_availability.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.from});
  final String? from;

  @override
  HomeScreenState createState() => HomeScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => HomeScreen(from: arguments['from'] as String),
    );
  }
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;

  bool isAlreadyShowingLocationDialog = false;
  bool? _appliedHomeLocationFlag;

  final ScrollController _scrollController = ScrollController();
  late final Box<dynamic> _userDetailsBox;
  late final VoidCallback _countryListener;
  String? _lastSelectedCountryId;
  String? _lastSelectedCountryName;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchHomeScreenAPIs());

    if (!GuestChecker.value) {
      unawaited(context.read<GetApiKeysCubit>().fetch());
    }

    unawaited(initializeSettings());
    _scrollController.addListener(pageScrollListener);

    ActiveRoleManager.notifier.addListener(_onActiveRoleChanged);

    _userDetailsBox = Hive.box(HiveKeys.userDetailsBox);
    _lastSelectedCountryId = HiveUtils.getSelectedCountryId();
    _lastSelectedCountryName = HiveUtils.getSelectedCountryName();

    _countryListener = () {
      final currentCountryId = HiveUtils.getSelectedCountryId();
      final currentCountryName = HiveUtils.getSelectedCountryName();

      if (currentCountryId != _lastSelectedCountryId ||
          currentCountryName != _lastSelectedCountryName) {
        _lastSelectedCountryId = currentCountryId;
        _lastSelectedCountryName = currentCountryName;

        // A country switch already refreshes the whole app once through
        // LanguageChangeHelper; refreshing here too would double every call.
        if (mounted &&
            !ActiveRoleManager.isAgent &&
            !LanguageChangeHelper.isApplyingCountryChange) {
          unawaited(_refreshHomeScreenAPIs());
        }
      }
    };

    _userDetailsBox
        .listenable(keys: ['selected_country_id', 'selected_country_name'])
        .addListener(_countryListener);
  }

  @override
  void dispose() {
    _userDetailsBox
        .listenable(keys: ['selected_country_id', 'selected_country_name'])
        .removeListener(_countryListener);
    ActiveRoleManager.notifier.removeListener(_onActiveRoleChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onActiveRoleChanged() {
    if (!mounted) return;
    if (ActiveRoleManager.notifier.value == ActiveRole.user) {
      unawaited(_fetchHomeScreenAPIs());
    }
  }

  Future<void> _fetchHomeScreenAPIs() async {
    if (ActiveRoleManager.isAgent) return;

    await HomeSections.fetchAllHomeSections(context);
    if (!mounted) return;
    if (context.read<FetchPropertiesByCitiesCubit>().state
        is! FetchPropertiesByCitiesSuccess) {
      await context.read<FetchPropertiesByCitiesCubit>().fetch();
    }
    if (!mounted) return;
    if (context.read<HomePageInfinityScrollCubit>().state
        is! HomePageInfinityScrollSuccess) {
      await context.read<HomePageInfinityScrollCubit>().fetch();
    }
    if (!mounted) return;
    if (context.read<FetchAdBannersCubit>().state is! FetchAdBannersSuccess) {
      await context.read<FetchAdBannersCubit>().fetch(page: 'homepage');
    }
  }

  Future<void> _refreshHomeScreenAPIs({bool forceRefresh = true}) async {
    if (ActiveRoleManager.isAgent) return;
    await CheckInternet.check(
      onInternet: () async {
        if (!mounted) return;
        await HomeSections.fetchAllHomeSections(
          context,
          forceRefresh: forceRefresh,
        );
        if (!mounted) return;
        await context.read<FetchPropertiesByCitiesCubit>().fetch();
        if (!mounted) return;
        await context.read<HomePageInfinityScrollCubit>().fetch();
        if (!mounted) return;
        await context.read<FetchAdBannersCubit>().fetch(page: 'homepage');
      },
    );
  }

  Future<void> initializeSettings() async {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();

    if (!const bool.fromEnvironment('force-disable-demo-mode')) {
      AppSettings.isDemoModeOn =
          settingsCubit.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
  }

  Future<void> pageScrollListener() async {
    if (_scrollController.isEndReached()) {
      if (mounted) {
        if (context.read<HomePageInfinityScrollCubit>().hasMoreData()) {
          await context.read<HomePageInfinityScrollCubit>().fetchMore();
        }
      }
    }
  }

  Future<void> _onTapChangeLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final placeMark =
        await Navigator.pushNamed(
              context,
              Routes.chooseLocaitonMap,
              arguments: {'from': 'home_location'},
            )
            as Map?;
    try {
      final latlng = placeMark?['latlng'] as LatLng;
      final place = placeMark?['place'] as Placemark;
      final radius = placeMark?['radius'] as String? ?? '';

      await HiveUtils.setHomeLocation(
        city: place.locality ?? '',
        state: place.administrativeArea ?? '',
        latitude: latlng.latitude.toString(),
        longitude: latlng.longitude.toString(),
        country: place.country ?? '',
        placeId: place.postalCode ?? '',
        radius: radius,
      );

      if (mounted && !ActiveRoleManager.isAgent) {
        await HomeSections.fetchAllHomeSections(context, forceRefresh: true);
        await context.read<FetchNearbyPropertiesCubit>().fetch();
        await context.read<FetchPropertiesByCitiesCubit>().fetch();
        await context.read<HomePageInfinityScrollCubit>().fetch();
      }
    } on Exception catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _refreshHomeScreenAPIs();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: context.color.primaryColor,
        showBackButton: false,
        showShadow: false,
        titleWidget: const HomeLocationWidget(),
        actions: [
          GestureDetector(
            onTap: () async {
              await GuestChecker.check(
                onNotGuest: () async {
                  await Navigator.pushNamed(context, Routes.notificationPage);
                },
              );
            },
            child: Container(
              width: 40.rw(context),
              height: 40.rh(context),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(6.rw(context)),
                border: Border.all(color: context.color.borderColor),
              ),
              child: Center(
                child: CustomImage(
                  imageUrl: AppIcons.notification,
                  width: 20.rw(context),
                  height: 20.rh(context),
                  color: context.color.textColorDark,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: context.color.primaryColor,
      body: CustomRefreshIndicator(
        onRefresh: _onRefresh,
        child: Builder(
          builder: (context) {
            return BlocBuilder<
              FetchSystemSettingsCubit,
              FetchSystemSettingsState
            >(
              builder: (context, state) {
                return BlocListener<
                  FetchPropertiesByCitiesCubit,
                  FetchPropertiesByCitiesState
                >(
                  listener: (context, cityState) {
                    if (cityState is FetchPropertiesByCitiesSuccess) {
                      context.read<FetchHomePageDataCubit>().setCities(
                        cityState.cities,
                      );
                    }
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: Constant.scrollPhysics,
                    clipBehavior: .none,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                        ),
                      ),
                      const SliverToBoxAdapter(child: HomeSearchField()),
                      _HomeSections(
                        getAppliedHomeLocationFlag: () =>
                            _appliedHomeLocationFlag,
                        onAppliedHomeLocationFlagChanged: (value) {
                          _appliedHomeLocationFlag = value;
                        },
                        showNoDataAtLocation: () =>
                            showNoDataAtLocation(context),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 8.rh(context)),
                      ),
                      SliverToBoxAdapter(
                        child:
                            BlocBuilder<
                              FetchAdBannersCubit,
                              FetchAdBannersState
                            >(
                              builder: (context, adBannerState) {
                                if (adBannerState is FetchAdBannersSuccess &&
                                    adBannerState.banners.isNotEmpty) {
                                  return const BannerAdWidget();
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 8.rh(context)),
                      ),
                      const AllPropertiesSection(),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: 30 + MediaQuery.of(context).padding.top,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> showNoDataAtLocation(BuildContext context) {
    if (HiveUtils.isGuest() || HiveUtils.getHomeCityName() == null) {
      return Future.value();
    }

    if (isAlreadyShowingLocationDialog) return Future.value();
    isAlreadyShowingLocationDialog = true;
    return UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'noDataFound'.translate(context),
        titleColor: context.color.tertiaryColor,
        titleWeight: .w600,
        showAcceptButton: false,
        showCancleButton: false,
        svgImagePath: AppIcons.noDataFound,
        content: Column(
          mainAxisSize: .min,
          children: [
            CustomText(
              'noDataFoundAtThisLocation'.translate(context),
              fontSize: context.font.md,
              color: context.color.textColorDark,
              textAlign: .center,
              fontWeight: .w500,
            ),
            SizedBox(height: 8.rh(context)),
            UiUtils.buildButton(
              context,
              buttonTitle: 'changeLocation'.translate(context),
              height: 42.rh(context),
              onPressed: () async {
                isAlreadyShowingLocationDialog = false;
                Navigator.pop(context);
                await _onTapChangeLocation();
              },
              border: BorderSide(color: context.color.borderColor),
              showElevation: false,
              buttonColor: context.color.primaryColor,
              textColor: context.color.tertiaryColor,
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: 8.rh(context)),
            UiUtils.buildButton(
              context,
              buttonTitle: 'continue'.translate(context),
              height: 42.rh(context),
              showElevation: false,
              onPressed: () {
                isAlreadyShowingLocationDialog = false;
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSections extends StatelessWidget {
  const _HomeSections({
    required this.getAppliedHomeLocationFlag,
    required this.onAppliedHomeLocationFlagChanged,
    required this.showNoDataAtLocation,
  });

  final bool? Function() getAppliedHomeLocationFlag;
  final ValueChanged<bool> onAppliedHomeLocationFlagChanged;
  final Future<void> Function() showNoDataAtLocation;

  @override
  Widget build(BuildContext context) {
    final sectionsState = context.watch<FetchHomeSectionsDataCubit>().state;
    final isSliderEnabled =
        sectionsState is FetchHomeSectionsDataSuccess &&
        sectionsState.data.sliderSection;

    return BlocConsumer<FetchHomePageDataCubit, FetchHomePageDataState>(
      listener: (context, state) async {
        if (state is FetchHomePageDataSuccess) {
          final locationDataAvailable =
              state.homePageDataModel.homePageLocationDataAvailable ?? true;
          if (getAppliedHomeLocationFlag() != locationDataAvailable) {
            onAppliedHomeLocationFlagChanged(locationDataAvailable);

            if (!locationDataAvailable &&
                AppSettings.homePageLocationAlertStatus) {
              await showNoDataAtLocation();
            }
          }
        }
      },
      builder: (context, state) {
        if (state is FetchHomePageDataFailure) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: kBottomNavigationBarHeight),
              child: SomethingWentWrong(
                errorMessage: state.errorMessage,
              ),
            ),
          );
        }
        if (state is! FetchHomePageDataSuccess) {
          return const SliverToBoxAdapter();
        }

        final home = state.homePageDataModel;
        final propertySectionsState = context
            .watch<FetchPropertySectionsCubit>()
            .state;
        final projectSectionsState = context
            .watch<FetchProjectSectionsCubit>()
            .state;
        final otherSectionsState = context
            .watch<FetchOtherSectionsCubit>()
            .state;

        final sliderItems = home.sliderSection ?? const [];
        final showSliderShimmer =
            sliderItems.isEmpty &&
            (otherSectionsState is FetchOtherSectionsLoading ||
                otherSectionsState is FetchOtherSectionsInitial);

        return SliverMainAxisGroup(
          slivers: <Widget>[
            if (showSliderShimmer)
              SliverToBoxAdapter(
                child: CustomShimmer(
                  height: 170,
                  width: context.screenWidth,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              )
            else if (isSliderEnabled)
              SliderSection(banners: sliderItems),

            ...(home.originalSections ?? const <HomePageSection>[])
                .mapIndexed<Widget>((index, section) {
                  final sectionTitle =
                      home.originalSections?[index].translatedTitle ??
                      home.originalSections?[index].title;
                  return _buildSection(
                    context: context,
                    section: section,
                    home: home,
                    sectionTitle: sectionTitle,
                    propertySectionsState: propertySectionsState,
                    projectSectionsState: projectSectionsState,
                    otherSectionsState: otherSectionsState,
                  );
                }),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required HomePageSection section,
    required HomePageDataModel home,
    required String? sectionTitle,
    required FetchPropertySectionsState propertySectionsState,
    required FetchProjectSectionsState projectSectionsState,
    required FetchOtherSectionsState otherSectionsState,
  }) {
    switch (section.type) {
      case 'premium_properties_section':
        final items = home.premiumProperties ?? const [];
        if (items.isEmpty &&
            (propertySectionsState is FetchPropertySectionsLoading ||
                propertySectionsState is FetchPropertySectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 284, cardWidth: 220),
          );
        }
        return PremiumPropertiesSection(
          title: sectionTitle ?? 'premiumProperties'.translate(context),
          premiumProperties: items,
        );
      case 'categories_section':
        final items = home.categoriesSection ?? const [];
        if (items.isEmpty &&
            (otherSectionsState is FetchOtherSectionsLoading ||
                otherSectionsState is FetchOtherSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 48, cardWidth: 84),
          );
        }
        return CategoriesSection(
          categories: items,
          title: sectionTitle ?? 'categories'.translate(context),
        );
      case 'featured_properties_section':
        final items = home.featuredSection ?? const [];
        if (items.isEmpty &&
            (propertySectionsState is FetchPropertySectionsLoading ||
                propertySectionsState is FetchPropertySectionsInitial)) {
          return const SliverToBoxAdapter(child: PromotedPropertiesShimmer());
        }
        return FeaturedPropertiesSection(
          title: sectionTitle ?? 'promotedProperties'.translate(context),
          featuredProperties: items,
        );
      case 'most_liked_properties_section':
        final items = home.mostLikedProperties ?? const [];
        if (items.isEmpty &&
            (propertySectionsState is FetchPropertySectionsLoading ||
                propertySectionsState is FetchPropertySectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 284, cardWidth: 160),
          );
        }
        return MostLikedSection(
          title: sectionTitle ?? 'mostLikedProperties'.translate(context),
          mostLikedProperties: items,
        );
      case 'most_viewed_properties_section':
        final items = home.mostViewedProperties ?? const [];
        if (items.isEmpty &&
            (propertySectionsState is FetchPropertySectionsLoading ||
                propertySectionsState is FetchPropertySectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 284, cardWidth: 160),
          );
        }
        return MostViewedSection(
          title: sectionTitle ?? 'mostViewed'.translate(context),
          mostViewedProperties: items,
        );
      case 'projects_section':
        final items = home.projectSection ?? const [];
        if (items.isEmpty &&
            (projectSectionsState is FetchProjectSectionsLoading ||
                projectSectionsState is FetchProjectSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 278),
          );
        }
        return ProjectsSection(
          title: sectionTitle ?? 'Project section'.translate(context),
          projectSection: items,
        );
      case 'agents_list_section':
        final items = home.agentsList ?? const [];
        if (items.isEmpty &&
            (otherSectionsState is FetchOtherSectionsLoading ||
                otherSectionsState is FetchOtherSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 258, cardWidth: 220),
          );
        }
        return AgentsSection(
          title: sectionTitle ?? 'agents'.translate(context),
          agents: items,
        );
      case 'articles_section':
        final items = home.articleSection ?? const [];
        if (items.isEmpty &&
            (otherSectionsState is FetchOtherSectionsLoading ||
                otherSectionsState is FetchOtherSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 245, cardWidth: 210),
          );
        }
        return ArticlesSection(
          title: sectionTitle ?? 'articles'.translate(context),
          articles: items,
        );
      case 'nearby_properties_section':
        final items = home.nearByProperties ?? const [];
        if (items.isEmpty &&
            (propertySectionsState is FetchPropertySectionsLoading ||
                propertySectionsState is FetchPropertySectionsInitial)) {
          return const SliverToBoxAdapter(child: NearbyPropertiesShimmer());
        }
        return NearbyPropertiesSection(
          title:
              sectionTitle ??
              '${"nearByProperties".translate(context)} (${HiveUtils.getUserCityName()})',
          nearByProperties: items,
        );
      case 'featured_projects_section':
        final items = home.featuredProjectSection ?? const [];
        if (items.isEmpty &&
            (projectSectionsState is FetchProjectSectionsLoading ||
                projectSectionsState is FetchProjectSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 278),
          );
        }
        return FeaturedProjectsSection(
          title: sectionTitle ?? 'featuredProjects'.translate(context),
          projectSection: items,
        );
      case 'premium_projects_section':
        final items = home.premiumProjectSection ?? const [];
        if (items.isEmpty &&
            (projectSectionsState is FetchProjectSectionsLoading ||
                projectSectionsState is FetchProjectSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 278),
          );
        }
        return PremiumProjectsSection(
          title: sectionTitle ?? 'premiumProjects'.translate(context),
          projectSection: items,
        );
      case 'user_recommendations_section':
        final items = home.personalizedProperties ?? const [];
        if (items.isEmpty &&
            (otherSectionsState is FetchOtherSectionsLoading ||
                otherSectionsState is FetchOtherSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 284, cardWidth: 220),
          );
        }
        return PersonalizedSection(
          title: sectionTitle ?? 'personalizedFeed'.translate(context),
          personalizedProperties: items,
        );
      case 'curated_properties_section':
        final items = home.curatedProperties ?? const [];
        if (items.isEmpty &&
            (propertySectionsState is FetchPropertySectionsLoading ||
                propertySectionsState is FetchPropertySectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 284, cardWidth: 220),
          );
        }
        return CuratedPropertiesSection(
          title: sectionTitle ?? 'curatedProperties'.translate(context),
          curatedProperties: items,
        );
      case 'curated_projects_section':
        final items = home.curatedProjects ?? const [];
        if (items.isEmpty &&
            (projectSectionsState is FetchProjectSectionsLoading ||
                projectSectionsState is FetchProjectSectionsInitial)) {
          return const SliverToBoxAdapter(
            child: HorizontalCardsShimmer(height: 278),
          );
        }
        return CuratedProjectsSection(
          title: sectionTitle ?? 'curatedProjects'.translate(context),
          projectSection: items,
        );
      case 'properties_by_cities_section':
        return CityPropertiesSection(
          title: sectionTitle ?? 'popularCities'.translate(context),
          cities: home.propertiesByCities ?? const [],
        );
      default:
        return const SliverToBoxAdapter();
    }
  }
}
