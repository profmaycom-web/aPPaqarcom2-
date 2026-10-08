import 'package:ebroker/data/cubits/fetch_home_page_data_cubit.dart';
import 'package:ebroker/data/cubits/fetch_home_sections_data_cubit.dart';
import 'package:ebroker/data/cubits/fetch_other_sections_cubit.dart';
import 'package:ebroker/data/cubits/fetch_project_sections_cubit.dart';
import 'package:ebroker/data/cubits/fetch_property_sections_cubit.dart';
import 'package:ebroker/exports/main_export.dart';

/// Orchestrates homepage section API calls and injects their results into
/// `FetchHomePageDataCubit` (which acts as an aggregated view-model).
class HomeSections {
  static final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(
    false,
  );
  static bool get isLoading => isLoadingNotifier.value;
  static Future<void> fetchAllHomeSections(
    BuildContext context, {
    bool forceRefresh = false,
    bool isSilent = false,
  }) async {
    final home = context.read<FetchHomePageDataCubit>();
    final sectionsCubit = context.read<FetchHomeSectionsDataCubit>();
    final propertyCubit = context.read<FetchPropertySectionsCubit>();
    final projectCubit = context.read<FetchProjectSectionsCubit>();
    final otherCubit = context.read<FetchOtherSectionsCubit>();

    final futures = <Future<void>>[];
    if (!isSilent) {
      isLoadingNotifier.value = true;
    }

    if (forceRefresh || sectionsCubit.state is! FetchHomeSectionsDataSuccess) {
      futures.add(
        sectionsCubit
            .fetch(forceRefresh: forceRefresh, isSilent: isSilent)
            .then((_) {
              final s = sectionsCubit.state;
              if (s is FetchHomeSectionsDataSuccess) {
                home.setSectionsOrder(s.data);
              }
            }),
      );
    }
    if (forceRefresh || propertyCubit.state is! FetchPropertySectionsSuccess) {
      futures.add(
        propertyCubit
            .fetch(forceRefresh: forceRefresh, isSilent: isSilent)
            .then((_) {
              final s = propertyCubit.state;
              if (s is FetchPropertySectionsSuccess) {
                home.setPropertySections(s.data);
              }
            }),
      );
    }
    if (forceRefresh || projectCubit.state is! FetchProjectSectionsSuccess) {
      futures.add(
        projectCubit.fetch(forceRefresh: forceRefresh, isSilent: isSilent).then(
          (_) {
            final s = projectCubit.state;
            if (s is FetchProjectSectionsSuccess) {
              home.setProjectSections(s.data);
            }
          },
        ),
      );
    }
    if (forceRefresh || otherCubit.state is! FetchOtherSectionsSuccess) {
      futures.add(
        otherCubit.fetch(forceRefresh: forceRefresh, isSilent: isSilent).then((
          _,
        ) {
          final s = otherCubit.state;
          if (s is FetchOtherSectionsSuccess) {
            home.setOtherSections(s.data);
          }
        }),
      );
    }
    if (futures.isEmpty) {
      if (!isSilent) {
        isLoadingNotifier.value = false;
      }
      return;
    }
    try {
      await Future.wait(futures);
    } finally {
      if (!isSilent) {
        isLoadingNotifier.value = false;
      }
    }
  }
}
