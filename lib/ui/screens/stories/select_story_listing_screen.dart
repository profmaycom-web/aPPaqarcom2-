import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/project_type_label.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:material_ui/material_ui.dart';

class StorySourceEntity {
  const StorySourceEntity({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.image,
    required this.galleryImages,
    this.address = '',
    this.propertyType = '',
  });

  final String entityType; // 'property' | 'project'
  final int entityId;
  final String title;
  final String image;
  final List<String> galleryImages;
  final String address;
  final String propertyType;
}

List<String> _propertyGalleryImages(PropertyModel property) {
  final gallery = property.gallery ?? [];
  return [
    for (final item in gallery)
      if (item.isVideo != true) item.imageUrl,
  ];
}

List<String> _projectGalleryImages(ProjectModel project) {
  final gallery = project.gallaryImages ?? [];
  return [
    for (final item in gallery)
      if (!item.isVideo) item.imageUrl,
  ];
}

class SelectStoryListingScreen extends StatefulWidget {
  const SelectStoryListingScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SelectStoryListingScreen(),
    );
  }

  @override
  State<SelectStoryListingScreen> createState() =>
      _SelectStoryListingScreenState();
}

class _SelectStoryListingScreenState extends State<SelectStoryListingScreen>
    with TickerProviderStateMixin {
  final _propertyScrollController = ScrollController();
  final _projectScrollController = ScrollController();
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (context.read<FetchMyPropertiesCubit>().state
        is! FetchMyPropertiesSuccess) {
      unawaited(
        HelperUtils.loadMyProperties(
          context,
          type: MyPropertyListingType.all,
          requestStatus: MyPropertyRequestStatus.all,
          status: MyPropertyRequestStatus.active,
        ),
      );
    }
    if (context.read<FetchMyProjectsCubit>().state is FetchMyProjectsInitial) {
      unawaited(
        context.read<FetchMyProjectsCubit>().fetchMyProjects(
          type: 'all',
          status: 'all',
        ),
      );
    }

    _propertyScrollController.addListener(() {
      if (_propertyScrollController.position.pixels ==
          _propertyScrollController.position.maxScrollExtent) {
        if (context.read<FetchMyPropertiesCubit>().hasMoreData()) {
          unawaited(
            context.read<FetchMyPropertiesCubit>().fetchMoreProperties(
              type: 'all',
              requestStatus: 'all',
              status: '1',
            ),
          );
        }
      }
    });
    _projectScrollController.addListener(() {
      if (_projectScrollController.position.pixels ==
          _projectScrollController.position.maxScrollExtent) {
        if (context.read<FetchMyProjectsCubit>().hasMoreData()) {
          unawaited(
            context.read<FetchMyProjectsCubit>().fetchMoreMyProjects(
              type: 'all',
              status: 'all',
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _propertyScrollController.dispose();
    _projectScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(title: 'selectListing'.translate(context)),
      body: Column(
        children: [
          CustomTabBar(
            tabController: _tabController,
            isScrollable: false,
            tabs: [
              Tab(text: 'properties'.translate(context)),
              Tab(text: 'myProjects'.translate(context)),
            ],
            onTap: (index) => setState(() => _selectedTab = index),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildPropertiesBody()
                : _buildProjectsBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesBody() {
    return BlocBuilder<FetchMyPropertiesCubit, FetchMyPropertiesState>(
      builder: (context, state) {
        if (state is FetchMyPropertiesInitial ||
            state is FetchMyPropertiesInProgress) {
          return UiUtils.buildHorizontalShimmer(context);
        }
        if (state is FetchMyPropertiesFailure) {
          return Center(
            child: SomethingWentWrong(errorMessage: state.errorMessage),
          );
        }
        if (state is FetchMyPropertiesSuccess) {
          if (state.myProperty.isEmpty) {
            return SingleChildScrollView(
              child: NoDataFound(
                title: 'noListingsToAttachStory'.translate(context),
                description: '',
                showMainButton: false,
                onTapRetry: () {},
              ),
            );
          }
          return ListView.separated(
            controller: _propertyScrollController,
            physics: Constant.scrollPhysics,
            padding: EdgeInsets.fromLTRB(
              16.rw(context),
              16.rh(context),
              16.rw(context),
              32.rh(context),
            ),
            separatorBuilder: (context, index) =>
                SizedBox(height: 8.rh(context)),
            itemCount: state.myProperty.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.myProperty.length) {
                return Center(
                  child: UiUtils.progress(
                    height: 30.rh(context),
                    width: 30.rw(context),
                  ),
                );
              }
              final property = state.myProperty[index];
              return _SelectablePropertyTile(
                property: property,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.addStory,
                  arguments: {
                    'entity': StorySourceEntity(
                      entityType: 'property',
                      entityId: property.id ?? 0,
                      title: property.title ?? '',
                      image: property.titleImage ?? '',
                      galleryImages: _propertyGalleryImages(property),
                      address: property.address ?? '',
                      propertyType: property.propertyType ?? '',
                    ),
                  },
                ),
              );
            },
          );
        }
        return SomethingWentWrong(
          errorMessage: 'somethingWentWrong'.translate(context),
        );
      },
    );
  }

  Widget _buildProjectsBody() {
    return BlocBuilder<FetchMyProjectsCubit, FetchMyProjectsState>(
      builder: (context, state) {
        if (state is FetchMyProjectsInitial ||
            state is FetchMyProjectsInProgress) {
          return UiUtils.buildHorizontalShimmer(context);
        }
        if (state is FetchMyProjectsFail) {
          return Center(
            child: SomethingWentWrong(errorMessage: state.error.toString()),
          );
        }
        if (state is FetchMyProjectsSuccess) {
          if (state.projects.isEmpty) {
            return SingleChildScrollView(
              child: NoDataFound(
                title: 'noListingsToAttachStory'.translate(context),
                description: '',
                showMainButton: false,
                onTapRetry: () {},
              ),
            );
          }
          return ListView.separated(
            controller: _projectScrollController,
            physics: Constant.scrollPhysics,
            padding: EdgeInsets.fromLTRB(
              16.rw(context),
              16.rh(context),
              16.rw(context),
              32.rh(context),
            ),
            separatorBuilder: (context, index) =>
                SizedBox(height: 8.rh(context)),
            itemCount: state.projects.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.projects.length) {
                return Center(
                  child: UiUtils.progress(
                    height: 30.rh(context),
                    width: 30.rw(context),
                  ),
                );
              }
              final project = state.projects[index];
              return _SelectableProjectTile(
                project: project,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.addStory,
                  arguments: {
                    'entity': StorySourceEntity(
                      entityType: 'project',
                      entityId: project.id ?? 0,
                      title: project.title ?? '',
                      image: project.image ?? '',
                      galleryImages: _projectGalleryImages(project),
                    ),
                  },
                ),
              );
            },
          );
        }
        return SomethingWentWrong(
          errorMessage: 'somethingWentWrong'.translate(context),
        );
      },
    );
  }
}

class _SelectablePropertyTile extends StatelessWidget {
  const _SelectablePropertyTile({required this.property, required this.onTap});

  final PropertyModel property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.rw(context)),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.borderColor),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomImage(
                    imageUrl: property.titleImage ?? '',
                    width: 56.rw(context),
                    height: 56.rh(context),
                  ),
                ),
                if (property.isPremium == true ||
                    property.allPropData?['is_premium'] == true)
                  PositionedDirectional(
                    start: 4.rw(context),
                    top: 4.rh(context),
                    child: CustomImage(
                      imageUrl: AppIcons.premium,
                      height: 16.rh(context),
                      width: 16.rw(context),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      CustomImage(
                        imageUrl: property.category?.image ?? '',
                        color: context.color.textLightColor,
                        width: 16.rw(context),
                        height: 16.rh(context),
                      ),
                      SizedBox(width: 4.rw(context)),
                      Expanded(
                        child: CustomText(
                          property.category?.translatedName ??
                              property.category?.category ??
                              '',
                          maxLines: 1,
                          fontSize: context.font.xxs,
                          color: context.color.textLightColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.rh(context)),
                  CustomText(
                    property.translatedTitle ?? property.title ?? '',
                    maxLines: 1,
                    fontSize: context.font.sm,
                    color: context.color.textColorDark,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.rw(context)),
            SellRentLabel(propertyType: property.propertyType.toString()),
          ],
        ),
      ),
    );
  }
}

class _SelectableProjectTile extends StatelessWidget {
  const _SelectableProjectTile({required this.project, required this.onTap});

  final ProjectModel project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.rw(context)),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.borderColor),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomImage(
                    imageUrl: project.image ?? '',
                    width: 56.rw(context),
                    height: 56.rh(context),
                  ),
                ),
                if (project.isPremium ?? false)
                  PositionedDirectional(
                    start: 4.rw(context),
                    top: 4.rh(context),
                    child: CustomImage(
                      imageUrl: AppIcons.premium,
                      height: 16.rh(context),
                      width: 16.rw(context),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      CustomImage(
                        imageUrl: project.category?.image ?? '',
                        color: context.color.textLightColor,
                        width: 16.rw(context),
                        height: 16.rh(context),
                      ),
                      SizedBox(width: 4.rw(context)),
                      Expanded(
                        child: CustomText(
                          project.category?.translatedName ??
                              project.category?.category ??
                              '',
                          maxLines: 1,
                          fontSize: context.font.xxs,
                          color: context.color.textLightColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.rh(context)),
                  CustomText(
                    project.translatedTitle ?? project.title ?? '',
                    maxLines: 1,
                    fontSize: context.font.sm,
                    color: context.color.textColorDark,
                  ),
                ],
              ),
            ),
            if ((project.type ?? '').isNotEmpty) ...[
              SizedBox(width: 8.rw(context)),
              ProjectTypeLabel(projectType: project.type!),
            ],
          ],
        ),
      ),
    );
  }
}
