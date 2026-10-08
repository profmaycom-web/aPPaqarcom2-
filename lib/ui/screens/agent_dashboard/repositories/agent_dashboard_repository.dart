import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/data/model/data_output.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_active_packages_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_category_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_listings_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_most_viewed_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_summary_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_follower_model.dart';
import 'package:ebroker/utils/api.dart';

class AgentDashboardRepository {
  Future<AgentDashboardSummaryModel> fetchSummary() async {
    final response = await Api.get(url: Api.agentDashboardSummary);
    return AgentDashboardSummaryModel.fromJson(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<AgentDashboardListingsModel> fetchListings({
    required String type,
    required String range,
  }) async {
    final response = await Api.get(
      url: Api.agentDashboardListings,
      queryParameters: {'type': type, 'range': range},
    );
    return AgentDashboardListingsModel.fromJson(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<List<AgentDashboardCategoryModel>> fetchMostViewedCategories({
    required String range,
  }) async {
    final response = await Api.get(
      url: Api.agentDashboardMostViewedCategory,
      queryParameters: {'range': range},
    );
    return (response['data'] as List? ?? [])
        .map(
          (e) => AgentDashboardCategoryModel.fromJson(
            e as Map<String, dynamic>? ?? {},
          ),
        )
        .toList();
  }

  Future<List<AgentDashboardMostViewedModel>> fetchMostViewedListings({
    required String type,
    required String range,
  }) async {
    final response = await Api.get(
      url: Api.agentDashboardMostViewedListing,
      queryParameters: {'type': type, 'range': range},
    );
    return (response['data'] as List? ?? [])
        .map(
          (e) => AgentDashboardMostViewedModel.fromJson(
            e as Map<String, dynamic>? ?? {},
          ),
        )
        .toList();
  }

  Future<List<AgentDashboardActivePackageModel>> fetchActivePackages() async {
    final response = await Api.get(url: Api.agentDashboardActivePackages);
    return (response['data'] as List? ?? [])
        .map(
          (e) => AgentDashboardActivePackageModel.fromJson(
            e as Map<String, dynamic>? ?? {},
          ),
        )
        .toList();
  }

  Future<DataOutput<AgentFollowerModel>> fetchFollowers({
    required int offset,
    int? limit,
  }) async {
    final response = await Api.get(
      url: Api.agentDashboardFollowers,
      queryParameters: {
        Api.offset: offset,
        Api.limit: limit ?? AppConfig.apiDataLoadLimit,
      },
    );
    final modelList = (response['data'] as List? ?? [])
        .map<AgentFollowerModel>(
          (e) => AgentFollowerModel.fromJson(Map.from(e as Map? ?? {})),
        )
        .toList();
    final rawTotal = int.tryParse(
      response['total']?.toString() ??
          response['meta']?['total']?.toString() ??
          '',
    );
    final total = rawTotal ?? modelList.length;
    return DataOutput(
      total: total,
      modelList: modelList,
    );
  }
}
