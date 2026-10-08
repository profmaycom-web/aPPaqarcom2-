import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/model/user_model.dart';
import 'package:ebroker/exports/main_export.dart';

Future<void> handleAddPropertyOrProjectTap(
  BuildContext context,
  PropertyAddType type,
) async {
  final isAgent = RoleScope.of(context) == ActiveRole.agent;
  final hasInternet = await HelperUtils.checkInternet();
  final user = HiveUtils.getUserDetails();
  var agent = HiveUtils.getAgentProfileData();
  final verificationStatus = isAgent
      ? user.agentVerificationStatus
      : user.userVerificationStatus;

  if (!hasInternet) {
    return HelperUtils.showSnackBarMessage(
      context,
      'noInternet',
      type: MessageType.error,
    );
  }
  await GuestChecker.check(
    onNotGuest: () async {
      try {
        var isProfileCompleted = isAgent
            ? _isAgentProfileCompleted(agent, user)
            : _isUserProfileCompleted(user);

        // Cached agent profile can be stale or partially filled, so refresh it
        // from the server before asking the agent to complete the profile.
        if (!isProfileCompleted && isAgent) {
          unawaited(Widgets.showLoader(context));
          await context.read<AgentProfileCubit>().fetchAgentProfile();
          Widgets.hideLoader(context);
          if (!context.mounted) return;
          agent = HiveUtils.getAgentProfileData();
          isProfileCompleted = _isAgentProfileCompleted(
            agent,
            HiveUtils.getUserDetails(),
          );
        }

        if (!isProfileCompleted) {
          if (isAgent) {
            _logMissingAgentFields(agent, HiveUtils.getUserDetails());
          }
          await _showCompleteProfileDialog(
            context,
            isAgent: isAgent,
            agent: agent,
          );
        } else if ((ActiveRoleManager.isAgent
                ? AppSettings.isVerificationRequiredForAgent
                : AppSettings.isVerificationRequiredForUser) &&
            verificationStatus != 'approved') {
          await _showVerificationRequiredDialog(context);
        } else {
          await _navigateToAddScreen(context, type);
        }
      } on Exception catch (e) {
        HelperUtils.showSnackBarMessage(
          context,
          e.toString(),
          type: MessageType.error,
        );
      }
    },
  );
}

bool _hasValue(String? value) =>
    value != null && value.trim().isNotEmpty && value.trim() != 'null';

bool _isUserProfileCompleted(UserModel user) =>
    _hasValue(user.email) &&
    _hasValue(user.mobile) &&
    _hasValue(user.name) &&
    _hasValue(user.address) &&
    _hasValue(user.profile);

// Required fields match the user profile rule: name, email, mobile, address
// and photo. About me, social media and business details are optional.
// Agent fields fall back to the user profile, since the agent profile API
// does not always return every field the agent has already filled in.
bool _isAgentProfileCompleted(AgentProfileModel? agent, UserModel user) {
  String? pick(String? agentValue, String? userValue) =>
      _hasValue(agentValue) ? agentValue : userValue;

  return _hasValue(pick(agent?.agentName, user.name)) &&
      _hasValue(pick(agent?.agentEmail, user.email)) &&
      _hasValue(pick(agent?.agentMobile, user.mobile)) &&
      _hasValue(pick(agent?.agentAddress, user.address)) &&
      _hasValue(pick(agent?.agentProfilePhoto, user.profile));
}

void _logMissingAgentFields(AgentProfileModel? agent, UserModel user) {
  final fields = {
    'name': [agent?.agentName, user.name],
    'email': [agent?.agentEmail, user.email],
    'mobile': [agent?.agentMobile, user.mobile],
    'address': [agent?.agentAddress, user.address],
    'profilePhoto': [agent?.agentProfilePhoto, user.profile],
  };
  final missing = fields.entries
      .where((e) => !e.value.any(_hasValue))
      .map((e) => e.key)
      .toList();
  debugPrint('Agent profile incomplete, missing: $missing');
}

Future<void> _showCompleteProfileDialog(
  BuildContext context, {
  required bool isAgent,
  required AgentProfileModel? agent,
}) async {
  final user = HiveUtils.getUserDetails();
  await UiUtils.showBlurredDialoge(
    context,
    dialog: BlurredDialogBox(
      title: 'completeProfile'.translate(context),
      isAcceptContainesPush: true,
      svgImagePath: AppIcons.logoutIllustration,
      onAccept: () async {
        final route = RoleScope.of(context) == ActiveRole.agent
            ? Routes.editAgentProfile
            : Routes.editProfile;
        await Navigator.popAndPushNamed(
          context,
          route,
          arguments: {'from': 'profile'},
        );
      },

      content: isAgent
          ? (agent?.agentProfilePhoto == null ||
                        (agent?.agentProfilePhoto?.isEmpty ?? true)) &&
                    (agent?.agentName?.isNotEmpty ?? false) &&
                    (agent?.agentEmail?.isNotEmpty ?? false) &&
                    (agent?.agentAddress?.isNotEmpty ?? false)
                ? CustomText(
                    'uploadProfilePicture'.translate(context),
                    textAlign: .center,
                  )
                : CustomText(
                    'completeProfileFirst'.translate(context),
                    textAlign: .center,
                  )
          : user.profile == '' &&
                (user.name != '' && user.email != '' && user.address != '')
          ? CustomText(
              'uploadProfilePicture'.translate(context),
              textAlign: .center,
            )
          : CustomText(
              'completeProfileFirst'.translate(context),
              textAlign: .center,
            ),
    ),
  );
}

Future<void> _showVerificationRequiredDialog(BuildContext context) async {
  await UiUtils.showBlurredDialoge(
    context,
    dialog: BlurredDialogBox(
      content: CustomText(
        'completeAgentVerificationToContinue'.translate(context),
      ),
      title: 'agentVerificationRequired'.translate(context),
      isAcceptContainesPush: true,
      onAccept: () async {
        await Navigator.popAndPushNamed(context, Routes.userVerificationForm);
      },
    ),
  );
}

Future<void> _navigateToAddScreen(
  BuildContext context,
  PropertyAddType propertyAddType,
) async {
  if (propertyAddType == .project) {
    await context.read<ManageProjectCubit>().clear();
  }
  if (propertyAddType == .property) {
    await context.read<CreatePropertyCubit>().clear();
  }
  if (context.read<FetchCategoryCubit>().state is! FetchCategorySuccess) {
    await context.read<FetchCategoryCubit>().fetchCategories(
      loadWithoutDelay: true,
      forceRefresh: false,
    );
  }
  Widgets.hideLoder(context);

  if (propertyAddType == PropertyAddType.property) {
    await Navigator.pushNamed(
      context,
      Routes.addPropertyScreenRoute,
      arguments: {'type': propertyAddType},
    );
  } else {
    await Navigator.pushNamed(
      context,
      Routes.addProjectScreenRoute,
      arguments: {'type': propertyAddType},
    );
  }

  Widgets.hideLoder(context);
}
