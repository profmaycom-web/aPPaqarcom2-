import 'dart:async';

import 'package:ebroker/commons/utils/property_project_add_button_tap.dart';
import 'package:ebroker/data/cubits/favorite/add_to_favorite_cubit.dart';
import 'package:ebroker/data/cubits/project/fetch_my_projects_cubit.dart';
import 'package:ebroker/data/cubits/property/fetch_my_properties_cubit.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:ebroker/ui/screens/home/widgets/project_card_horizontal.dart';
import 'package:ebroker/ui/screens/home/widgets/property_horizontal_card.dart';
import 'package:ebroker/ui/screens/proprties/add_propery_screens/select_type_of_property.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:ebroker/ui/screens/widgets/errors/no_data_found.dart';
import 'package:ebroker/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

int propertyScreenCurrentPage = 0;
ValueNotifier<Map<String, dynamic>> emptyCheckNotifier = ValueNotifier({
  'isSellEmpty': false,
  'isRentEmpty': false,
});

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => MyListingsScreenState();
}

enum FilterType { status, propertyType }

class MyListingsScreenState extends State<MyListingsScreen>
    with TickerProviderStateMixin {
  // Properties state
  int offset = 0;
  int total = 0;
  bool isSellEmpty = false;
  bool isRentEmpty = false;
  final controller = ScrollController();
  String selectedType = '';
  String selectedStatus = '';
  late String tempSelectedType;
  late String tempSelectedStatus;

  // Projects state
  final _projectScrollController = ScrollController();
  String _projectSelectedType = '';
  String _projectSelectedStatus = '';
  late String _projectTempType;
  late String _projectTempStatus;

  // Tab state
  int _selectedTab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    tempSelectedType = selectedType;
    tempSelectedStatus = selectedStatus;
    _projectTempType = _projectSelectedType;
    _projectTempStatus = _projectSelectedStatus;
    _tabController = TabController(length: 2, vsync: this);

    if (context.read<FetchMyPropertiesCubit>().state
        is! FetchMyPropertiesSuccess) {
      unawaited(fetchMyProperties());
    }

    if (context.read<FetchMyProjectsCubit>().state is FetchMyProjectsInitial) {
      unawaited(
        context.read<FetchMyProjectsCubit>().fetchMyProjects(),
      );
    }

    addScrollListener();
    _addProjectScrollListener();
  }

  @override
  void dispose() {
    controller.dispose();
    _projectScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _isNumericStatus(String status) => status == '1' || status == '0';

  void addScrollListener() {
    controller.addListener(() async {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        if (context.read<FetchMyPropertiesCubit>().hasMoreData()) {
          final isNumeric = _isNumericStatus(selectedStatus);
          await context.read<FetchMyPropertiesCubit>().fetchMoreProperties(
            type: selectedType.toLowerCase(),
            requestStatus: isNumeric ? '' : selectedStatus.toLowerCase(),
            status: isNumeric ? selectedStatus : '',
          );
        }
      }
    });
  }

  void _addProjectScrollListener() {
    _projectScrollController.addListener(() async {
      if (_projectScrollController.position.pixels ==
          _projectScrollController.position.maxScrollExtent) {
        if (context.read<FetchMyProjectsCubit>().hasMoreData()) {
          await context.read<FetchMyProjectsCubit>().fetchMoreMyProjects(
            type: _projectSelectedType.toLowerCase(),
            status: _projectSelectedStatus.toLowerCase(),
          );
        }
      }
    });
  }

  Future<void> fetchMyProperties() async {
    final isNumeric = _isNumericStatus(selectedStatus);
    await HelperUtils.loadMyProperties(
      context,
      type: MyPropertyListingType.fromValue(selectedType.toLowerCase()),
      requestStatus: isNumeric
          ? MyPropertyRequestStatus.none
          : MyPropertyRequestStatus.fromValue(
              selectedStatus.toLowerCase(),
            ),
      status: isNumeric
          ? MyPropertyRequestStatus.fromValue(selectedStatus)
          : MyPropertyRequestStatus.none,
    );
  }

  Future<void> _fetchMyProjects() async {
    await context.read<FetchMyProjectsCubit>().fetchMyProjects(
      type: _projectSelectedType.toLowerCase(),
      status: _projectSelectedStatus.toLowerCase(),
    );
  }

  String statusText(String text) {
    if (text == '1') {
      return 'active'.translate(context);
    } else if (text == '0') {
      return 'inactive'.translate(context);
    } else if (text == 'rejected') {
      return 'rejected'.translate(context);
    } else if (text == 'pending') {
      return 'pending'.translate(context);
    } else if (text == 'expired') {
      return 'expired'.translate(context);
    } else if (text == 'draft') {
      return 'draft'.translate(context);
    }
    return '';
  }

  Color statusColor(String text) {
    if (text == '1') {
      return Colors.green;
    } else if (text == '0') {
      return Colors.orangeAccent;
    } else if (text == 'rejected') {
      return Colors.redAccent;
    } else if (text == 'pending') {
      return Colors.blue;
    } else if (text == 'expired') {
      return Colors.grey;
    } else if (text == 'draft') {
      return Colors.amber;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: 'myListings'.translate(context),
          isFromHome: true,
          showBackButton: false,
          actions: [
            GestureDetector(
              onTap: showFilters,
              child: Container(
                height: 40.rh(context),
                width: 40.rw(context),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.color.borderColor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.all(4.rw(context)),
                child: CustomImage(
                  imageUrl: AppIcons.filter,
                  color: context.color.textColorDark,
                  width: 24.rw(context),
                  height: 24.rh(context),
                ),
              ),
            ),
          ],
        ),
        body: CustomRefreshIndicator(
          onRefresh: () async {
            if (_selectedTab == 0) {
              await fetchMyProperties();
            } else {
              await _fetchMyProjects();
            }
          },
          child: Column(
            children: [
              _buildTabToggle(),
              Expanded(
                child: _selectedTab == 0
                    ? _buildPropertiesBody()
                    : _buildProjectsBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return CustomTabBar(
      tabController: _tabController,
      tabBackgroundColor: context.color.tertiaryColor,
      tabs: [
        Tab(text: 'properties'.translate(context)),
        Tab(text: 'myProjects'.translate(context)),
      ],
      isScrollable: false,
      onTap: (index) => setState(() => _selectedTab = index),
    );
  }

  Widget _buildPropertiesBody() {
    return BlocBuilder<FetchMyPropertiesCubit, FetchMyPropertiesState>(
      builder: (context, state) {
        if (state is FetchMyPropertiesInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              unawaited(fetchMyProperties());
            }
          });
          return UiUtils.buildHorizontalShimmer(context);
        }
        if (state is FetchMyPropertiesInProgress) {
          return UiUtils.buildHorizontalShimmer(context);
        }
        if (state is FetchMyPropertiesFailure) {
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            width: MediaQuery.sizeOf(context).width,
            child: Center(
              child: SomethingWentWrong(
                errorMessage: state.errorMessage,
              ),
            ),
          );
        }
        if (state is FetchMyPropertiesSuccess && state.myProperty.isEmpty) {
          return SingleChildScrollView(
            padding: .only(bottom: 24.rh(context)),
            child: NoDataFound(
              title: 'noPropertyAdded'.translate(context),
              description: 'noPropertyAddedDescription'.translate(context),
              onTapRetry: fetchMyProperties,
              showMainButton: true,
              mainButtonTitle: 'ddPropertyLbl'.translate(context),
              onTapMainButton: _navigateToAddProperty,
            ),
          );
        }
        if (state is FetchMyPropertiesSuccess && state.myProperty.isNotEmpty) {
          if (ResponsiveHelper.isLargeTablet(context) ||
              ResponsiveHelper.isTablet(context)) {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 130.rh(context),
              ),
              physics: Constant.scrollPhysics,
              controller: controller,
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 16,
              ),
              itemCount:
                  state.myProperty.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.myProperty.length) {
                  if (state.isLoadingMore) {
                    return Center(
                      child: UiUtils.progress(
                        height: 30.rh(context),
                        width: 30.rw(context),
                      ),
                    );
                  }
                  return const SizedBox();
                }
                final property = state.myProperty[index];
                final status = property.requestStatus.toString() == 'approved'
                    ? property.status.toString()
                    : property.requestStatus.toString();
                return BlocProvider(
                  create: (context) => AddToFavoriteCubitCubit(),
                  child: PropertyHorizontalCard(
                    property: property,
                    showLikeButton: false,
                    statusButton: StatusButton(
                      lable: statusText(status),
                      color: statusColor(status).withValues(alpha: 0.2),
                      textColor: statusColor(status),
                    ),
                  ),
                );
              },
            );
          } else {
            return ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(height: 8.rh(context)),
              physics: Constant.scrollPhysics,
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                16.rw(context),
                0,
                16.rw(context),
                32.rh(context),
              ),
              itemCount:
                  state.myProperty.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.myProperty.length) {
                  if (state.isLoadingMore) {
                    return Center(
                      child: UiUtils.progress(
                        height: 30.rh(context),
                        width: 30.rw(context),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final property = state.myProperty[index];
                final status = property.requestStatus.toString() == 'approved'
                    ? property.status.toString()
                    : property.requestStatus.toString();
                return BlocProvider(
                  create: (context) => AddToFavoriteCubitCubit(),
                  child: PropertyHorizontalCard(
                    property: property,
                    showLikeButton: false,
                    statusButton: StatusButton(
                      lable: statusText(status),
                      color: statusColor(status).withValues(alpha: 0.2),
                      textColor: statusColor(status),
                    ),
                  ),
                );
              },
            );
          }
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
        if (state is FetchMyProjectsInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              unawaited(_fetchMyProjects());
            }
          });
          return UiUtils.buildHorizontalShimmer(context);
        }
        if (state is FetchMyProjectsInProgress) {
          return UiUtils.buildHorizontalShimmer(context);
        }
        if (state is FetchMyProjectsFail) {
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            width: MediaQuery.sizeOf(context).width,
            child: Center(
              child: SomethingWentWrong(
                errorMessage: state.error.toString(),
              ),
            ),
          );
        }
        if (state is FetchMyProjectsSuccess) {
          if (state.projects.isEmpty) {
            return SingleChildScrollView(
              padding: .only(bottom: 24.rh(context)),
              child: NoDataFound(
                title: 'noProjectAdded'.translate(context),
                description: 'noProjectAddedDescription'.translate(context),
                showMainButton: true,
                mainButtonTitle: 'addProject'.translate(context),
                onTapMainButton: _navigateToAddProject,
                onTapRetry: _fetchMyProjects,
              ),
            );
          }
          return ListView.separated(
            separatorBuilder: (context, index) =>
                SizedBox(height: 8.rh(context)),
            physics: Constant.scrollPhysics,
            controller: _projectScrollController,
            padding: EdgeInsets.fromLTRB(
              16.rw(context),
              0,
              16.rw(context),
              32.rh(context),
            ),
            itemCount: state.projects.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.projects.length) {
                if (state.isLoadingMore) {
                  return Center(
                    child: UiUtils.progress(
                      height: 30.rh(context),
                      width: 30.rw(context),
                    ),
                  );
                }
                return const SizedBox();
              }
              final project = state.projects[index];
              final requestStatus = project.requestStatus == 'approved'
                  ? project.status.toString()
                  : project.requestStatus.toString();
              return ProjectHorizontalCard(
                project: project,
                isRejected: project.requestStatus == 'rejected',
                statusButton: StatusButton(
                  lable: statusText(requestStatus),
                  color: statusColor(requestStatus).withValues(alpha: 0.2),
                  textColor: statusColor(requestStatus),
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

  Future<void> showFilters() async {
    if (_selectedTab == 0) {
      await _showPropertyFilters();
    } else {
      await _showProjectFilters();
    }
  }

  Future<void> _showPropertyFilters() async {
    tempSelectedType = selectedType;
    tempSelectedStatus = selectedStatus;
    await CustomBottomSheet.show<dynamic>(
      context: context,
      title: 'filterTitle'.translate(context),
      borderRadius: 8,
      padding: .symmetric(horizontal: 16.rw(context)),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'status'.translate(context),
                color: context.color.inverseSurface,
                fontWeight: FontWeight.bold,
                fontSize: context.font.md,
              ),
              SizedBox(height: 8.rh(context)),
              Wrap(
                runSpacing: 8,
                children: [
                  buildFilterCheckbox(
                    'all'.translate(context),
                    tempSelectedStatus,
                    '',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'approved'.translate(context),
                    tempSelectedStatus,
                    'approved',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'active'.translate(context),
                    tempSelectedStatus,
                    '1',
                    FilterType.status,
                    setModalState,
                  ),

                  buildFilterCheckbox(
                    'rejected'.translate(context),
                    tempSelectedStatus,
                    'rejected',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'pending'.translate(context),
                    tempSelectedStatus,
                    'pending',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'expired'.translate(context),
                    tempSelectedStatus,
                    'expired',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'draft'.translate(context),
                    tempSelectedStatus,
                    'draft',
                    FilterType.status,
                    setModalState,
                  ),
                ],
              ),
              SizedBox(height: 16.rh(context)),
              CustomText(
                'type'.translate(context),
                color: context.color.inverseSurface,
                fontWeight: FontWeight.bold,
                fontSize: context.font.md,
              ),
              SizedBox(height: 8.rh(context)),
              Wrap(
                runSpacing: 8,
                children: [
                  buildFilterCheckbox(
                    'all'.translate(context),
                    tempSelectedType,
                    '',
                    FilterType.propertyType,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'sell'.translate(context),
                    tempSelectedType,
                    'sell',
                    FilterType.propertyType,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'rent'.translate(context),
                    tempSelectedType,
                    'rent',
                    FilterType.propertyType,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'sold'.translate(context),
                    tempSelectedType,
                    'sold',
                    FilterType.propertyType,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'rented'.translate(context),
                    tempSelectedType,
                    'rented',
                    FilterType.propertyType,
                    setModalState,
                  ),
                ],
              ),
              SizedBox(height: 16.rh(context)),
              UiUtils.buildButton(
                context,
                onPressed: () async {
                  setState(() {
                    selectedType = tempSelectedType;
                    selectedStatus = tempSelectedStatus;
                  });
                  Navigator.pop(context);
                  await fetchMyProperties();
                },
                height: 48.rh(context),
                buttonTitle: 'applyFilter'.translate(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showProjectFilters() async {
    _projectTempType = _projectSelectedType;
    _projectTempStatus = _projectSelectedStatus;
    await CustomBottomSheet.show<dynamic>(
      context: context,
      title: 'filterTitle'.translate(context),
      borderRadius: 8,
      padding: .symmetric(horizontal: 16.rw(context)),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'status'.translate(context),
                color: context.color.inverseSurface,
                fontWeight: FontWeight.bold,
                fontSize: context.font.md,
              ),
              SizedBox(height: 8.rh(context)),
              Wrap(
                runSpacing: 8,
                children: [
                  buildFilterCheckbox(
                    'all'.translate(context),
                    _projectTempStatus,
                    '',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'approved'.translate(context),
                    _projectTempStatus,
                    'approved',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'rejected'.translate(context),
                    _projectTempStatus,
                    'rejected',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'pending'.translate(context),
                    _projectTempStatus,
                    'pending',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'expired'.translate(context),
                    _projectTempStatus,
                    'expired',
                    FilterType.status,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'draft'.translate(context),
                    _projectTempStatus,
                    'draft',
                    FilterType.status,
                    setModalState,
                  ),
                ],
              ),
              SizedBox(height: 16.rh(context)),
              CustomText(
                'type'.translate(context),
                color: context.color.inverseSurface,
                fontWeight: FontWeight.bold,
                fontSize: context.font.md,
              ),
              SizedBox(height: 8.rh(context)),
              Wrap(
                runSpacing: 8,
                children: [
                  buildFilterCheckbox(
                    'all'.translate(context),
                    _projectTempType,
                    '',
                    FilterType.propertyType,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'upcoming'.translate(context),
                    _projectTempType,
                    'upcoming',
                    FilterType.propertyType,
                    setModalState,
                  ),
                  buildFilterCheckbox(
                    'under_construction'.translate(context),
                    _projectTempType,
                    'under_construction',
                    FilterType.propertyType,
                    setModalState,
                  ),
                ],
              ),
              SizedBox(height: 16.rh(context)),
              UiUtils.buildButton(
                context,
                onPressed: () async {
                  setState(() {
                    _projectSelectedType = _projectTempType;
                    _projectSelectedStatus = _projectTempStatus;
                  });
                  Navigator.pop(context);
                  await _fetchMyProjects();
                },
                height: 48.rh(context),
                buttonTitle: 'applyFilter'.translate(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _navigateToAddProperty() async {
    await handleAddPropertyOrProjectTap(context, PropertyAddType.property);
  }

  Future<void> _navigateToAddProject() async {
    await handleAddPropertyOrProjectTap(context, PropertyAddType.project);
  }

  Widget buildFilterCheckbox(
    String title,
    String currentValue,
    String optionValue,
    FilterType filterType,
    StateSetter setModalState,
  ) {
    final isSelected = currentValue.toLowerCase() == optionValue.toLowerCase();

    return GestureDetector(
      onTap: () {
        setModalState(() {
          switch (filterType) {
            case FilterType.status:
              if (_selectedTab == 0) {
                tempSelectedStatus = optionValue.toLowerCase();
              } else {
                _projectTempStatus = optionValue.toLowerCase();
              }
            case FilterType.propertyType:
              if (_selectedTab == 0) {
                tempSelectedType = optionValue.toLowerCase();
              } else {
                _projectTempType = optionValue.toLowerCase();
              }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsetsDirectional.only(end: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? context.color.tertiaryColor
                : context.color.borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? context.color.tertiaryColor
              : context.color.primaryColor,
        ),
        child: CustomText(
          title,
          color: isSelected
              ? context.color.buttonColor
              : context.color.inverseSurface,
          fontWeight: isSelected ? .bold : .w600,
        ),
      ),
    );
  }
}
