import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/widgets/agent_profile.dart';

class PropertyAgentGallerySection extends StatelessWidget {
  const PropertyAgentGallerySection({
    required this.property,
    this.gallery = const [],
    this.onScheduleAppointment,
    this.popAgentOnTap = false,
    super.key,
  });

  final PropertyModel property;
  final List<Gallery> gallery;
  final Future<void> Function()? onScheduleAppointment;
  final bool popAgentOnTap;

  @override
  Widget build(BuildContext context) {
    final isAddedByMe = property.addedBy.toString() == HiveUtils.getUserId();

    if (isAddedByMe) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 142.rh(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14.rw(context),
        vertical: 12.rh(context),
      ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8.rw(context)),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: AgentProfileWidget(
        addedBy: property.addedBy ?? '',
        name: property.customerName ?? '',
        email: property.customerEmail ?? '',
        profileImage: property.customerProfile ?? '',
        isUserVerified: property.isUserVerified ?? false,
        isAgentVerified: property.isAgentVerified ?? false,
        isAgent: property.isAgent ?? false,
        propertiesCount: property.propertiesCount ?? '',
        projectsCount: property.projectsCount ?? '',
        followersCount:
            (property.agentProfile?.totalFollowers?.isNotEmpty ?? false)
            ? property.agentProfile!.totalFollowers!
            : (property.followersCount?.isNotEmpty ?? false)
            ? property.followersCount!
            : (property.customerName != null &&
                  property.allPropData is Map)
            ? (property.allPropData['follower_count']?.toString() ??
                  property.allPropData['followers_count']?.toString() ??
                  property.allPropData['total_followers']?.toString())
            : null,
        isFollowing: property.isFollowing ?? false,
        canScheduleAppointment:
            (property.isAppointmentAvailable ?? false) &&
            (property.roleContext == 'agent' ||
             property.isAgent == true ||
             property.isAdmin == true),
        onScheduleAppointment: onScheduleAppointment,
        isAdmin: property.isAdmin ?? false,
        agentProfile: property.agentProfile,
        roleContext: property.roleContext,
        popOnTap: popAgentOnTap,
      ),
    );
  }
}
