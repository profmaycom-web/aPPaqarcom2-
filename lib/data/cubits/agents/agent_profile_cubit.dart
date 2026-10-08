import 'dart:async';

import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/repositories/agent_profile_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentProfileState {}

class AgentProfileInitial extends AgentProfileState {}

class AgentProfileInProgress extends AgentProfileState {}

class AgentProfileSuccess extends AgentProfileState {
  AgentProfileSuccess(this.agentProfile);
  final AgentProfileModel agentProfile;
}

class AgentProfileFailure extends AgentProfileState {
  AgentProfileFailure(this.errorMessage);
  final String errorMessage;
}

class AgentProfileCubit extends Cubit<AgentProfileState> {
  AgentProfileCubit() : super(_initialStateFromCache());

  final AgentProfileRepository _repository = AgentProfileRepository();

  static AgentProfileState _initialStateFromCache() {
    final cached = HiveUtils.getAgentProfileData();
    if (cached == null) return AgentProfileInitial();
    return AgentProfileSuccess(cached);
  }

  void setAgentProfile(AgentProfileModel profile) {
    unawaited(HiveUtils.setAgentProfileData(profile.toMap()));
    emit(AgentProfileSuccess(profile));
  }

  Future<void> fetchAgentProfile() async {
    try {
      final profile = await _repository.getAgentProfile();
      final hasData = (profile.agentName?.isNotEmpty ?? false) ||
          (profile.agentEmail?.isNotEmpty ?? false) ||
          (profile.serviceAreas?.isNotEmpty ?? false) ||
          (profile.languages?.isNotEmpty ?? false) ||
          (profile.experience?.isNotEmpty ?? false) ||
          (profile.startTime?.isNotEmpty ?? false);
      if (hasData) {
        final cached = HiveUtils.getAgentProfileData();
        final mergedProfile = (cached != null)
            ? profile.copyWith(
                serviceAreas: (profile.serviceAreas?.isNotEmpty ?? false)
                    ? profile.serviceAreas
                    : cached.serviceAreas,
                languages: (profile.languages?.isNotEmpty ?? false)
                    ? profile.languages
                    : cached.languages,
                experience: (profile.experience?.isNotEmpty ?? false)
                    ? profile.experience
                    : cached.experience,
                startTime: (profile.startTime?.isNotEmpty ?? false)
                    ? profile.startTime
                    : cached.startTime,
                endTime: (profile.endTime?.isNotEmpty ?? false)
                    ? profile.endTime
                    : cached.endTime,
                aboutMe: (profile.aboutMe?.isNotEmpty ?? false)
                    ? profile.aboutMe
                    : cached.aboutMe,
                agentAddress: (profile.agentAddress?.isNotEmpty ?? false)
                    ? profile.agentAddress
                    : cached.agentAddress,
                socialMediaLinks: profile.socialMediaLinks.isNotEmpty
                    ? profile.socialMediaLinks
                    : cached.socialMediaLinks,
              )
            : profile;

        await HiveUtils.setAgentProfileData(mergedProfile.toMap());
        emit(AgentProfileSuccess(mergedProfile));
      } else {
        final cached = HiveUtils.getAgentProfileData();
        if (cached != null) {
          emit(AgentProfileSuccess(cached));
        } else {
          emit(AgentProfileSuccess(profile));
        }
      }
    } on ApiException catch (e) {
      emit(AgentProfileFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentProfileFailure(e.toString()));
    }
  }

  Future<void> reset() async {
    await HiveUtils.clearAgentProfileData();
    emit(AgentProfileInitial());
  }
}
