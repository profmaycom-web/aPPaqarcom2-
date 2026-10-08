import 'package:ebroker/data/cubits/property/fetch_curated_properties_cubit.dart';
import 'package:ebroker/data/cubits/property/fetch_premium_properties_cubit.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/view_all.dart';

Future<void> handleSeeAllTap<
  C extends StateStreamable<S>,
  S,
  I,
  P,
  Success extends PropertySuccessStateWireframe,
  F extends PropertyErrorStateWireframe
>({
  required BuildContext context,
  required String title,
  required Future<void> Function({bool forceRefresh}) fetchData,
  FilterApply? lockedFilter,
  FilterApply? initialFilter,
  bool showFilterButton = true,
}) async {
  final stateMap = StateMap<I, P, Success, F>();

  await ViewAllScreen<C, S>(
    title: title.translate(context),
    map: stateMap,
    lockedFilter: lockedFilter,
    initialFilter: initialFilter,
    showFilterButton: showFilterButton,
  ).open(context);

  await fetchData(forceRefresh: true);
}

Future<void> onTapCuratedPropertiesSeeAll(BuildContext context, String title) {
  // Lock in the admin_curated flag — user cannot remove it.
  final lockedFilter = FilterApply()
    ..addOrUpdate(
      const FlagsFilter(
        promoted: false,
        premium: false,
        adminCurated: true,
      ),
    );

  return handleSeeAllTap<
    FetchCuratedPropertiesCubit,
    FetchCuratedPropertiesState,
    FetchCuratedPropertiesInitial,
    FetchCuratedPropertiesInProgress,
    FetchCuratedPropertiesSuccess,
    FetchCuratedPropertiesFailure
  >(
    context: context,
    title: title,
    lockedFilter: lockedFilter,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchCuratedPropertiesCubit>()
        .fetch(forceRefresh: forceRefresh),
  );
}

Future<void> onTapPromotedSeeAll(BuildContext context, String title) {
  // Lock in the promoted flag — user cannot remove it.
  final lockedFilter = FilterApply()
    ..addOrUpdate(const FlagsFilter(promoted: true, premium: false));

  return handleSeeAllTap<
    FetchPromotedPropertiesCubit,
    FetchPromotedPropertiesState,
    FetchPromotedPropertiesInitial,
    FetchPromotedPropertiesInProgress,
    FetchPromotedPropertiesSuccess,
    FetchPromotedPropertiesFailure
  >(
    context: context,
    title: title,
    lockedFilter: lockedFilter,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchPromotedPropertiesCubit>()
        .fetch(forceRefresh: forceRefresh),
  );
}

Future<void> onTapPremiumSeeAll(BuildContext context, String title) {
  // Lock in the premium flag — user cannot remove it.
  final lockedFilter = FilterApply()
    ..addOrUpdate(const FlagsFilter(promoted: false, premium: true));

  return handleSeeAllTap<
    FetchPremiumPropertiesCubit,
    FetchPremiumPropertiesState,
    FetchPremiumPropertiesInitial,
    FetchPremiumPropertiesInProgress,
    FetchPremiumPropertiesSuccess,
    FetchPremiumPropertiesFailure
  >(
    context: context,
    title: title,
    lockedFilter: lockedFilter,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchPremiumPropertiesCubit>()
        .fetch(forceRefresh: forceRefresh),
  );
}

Future<void> onTapNearByPropertiesAll(BuildContext context, String title) {
  return handleSeeAllTap<
    FetchNearbyPropertiesCubit,
    FetchNearbyPropertiesState,
    FetchNearbyPropertiesInitial,
    FetchNearbyPropertiesInProgress,
    FetchNearbyPropertiesSuccess,
    FetchNearbyPropertiesFailure
  >(
    context: context,
    title: title,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchNearbyPropertiesCubit>()
        .fetch(forceRefresh: forceRefresh),
  );
}

Future<void> onTapMostLikedAll(BuildContext context, String title) {
  return handleSeeAllTap<
    FetchMostLikedPropertiesCubit,
    FetchMostLikedPropertiesState,
    FetchMostLikedPropertiesInitial,
    FetchMostLikedPropertiesInProgress,
    FetchMostLikedPropertiesSuccess,
    FetchMostLikedPropertiesFailure
  >(
    context: context,
    title: title,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchMostLikedPropertiesCubit>()
        .fetch(forceRefresh: forceRefresh),
  );
}

Future<void> onTapMostViewedSeeAll(BuildContext context, String title) {
  return handleSeeAllTap<
    FetchMostViewedPropertiesCubit,
    FetchMostViewedPropertiesState,
    FetchMostViewedPropertiesInitial,
    FetchMostViewedPropertiesInProgress,
    FetchMostViewedPropertiesSuccess,
    FetchMostViewedPropertiesFailure
  >(
    context: context,
    title: title,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchMostViewedPropertiesCubit>()
        .fetch(forceRefresh: forceRefresh),
  );
}

Future<void> onTapPersonalizedSeeAll(BuildContext context, String title) {
  return handleSeeAllTap<
    FetchPersonalizedPropertyList,
    FetchPersonalizedPropertyListState,
    FetchPersonalizedPropertyInitial,
    FetchPersonalizedPropertyInProgress,
    FetchPersonalizedPropertySuccess,
    FetchPersonalizedPropertyFail
  >(
    context: context,
    title: title,
    showFilterButton: false,
    fetchData: ({forceRefresh = false}) => context
        .read<FetchPersonalizedPropertyList>()
        .fetch(loadWithoutDelay: true, forceRefresh: forceRefresh),
  );
}
