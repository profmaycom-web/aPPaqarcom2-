import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/chat/helpers/open_chat_screen.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyContactButtons extends StatelessWidget {
  const PropertyContactButtons({
    required this.property,
    super.key,
  });
  final PropertyModel property;

  String? _propertyPhoneNumber(BuildContext context) {
    final direct =
        property.agentProfile?.agentMobile ?? property.customerNumber;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    if (property.isAdmin == true || property.roleContext == 'admin') {
      final companyData = context.read<FetchSystemSettingsCubit>().companyData;
      final tel1 = companyData?.companyTel1?.trim();
      final tel2 = companyData?.companyTel2?.trim();
      if (tel1 != null && tel1.isNotEmpty) return tel1;
      if (tel2 != null && tel2.isNotEmpty) return tel2;
    }
    return null;
  }

  bool _canShowWhatsapp(BuildContext context) => WhatsappHelper.canShow(
    _propertyPhoneNumber(context),
    property.agentProfile?.agentCountryCode,
  );

  @override
  Widget build(BuildContext context) {
    final canShowWhatsapp = _canShowWhatsapp(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.12),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      height: 72.rh(context),
      child: Row(
        spacing: 12.rw(context),
        children: <Widget>[
          if (canShowWhatsapp) ...[
            _buildIconButton(
              context,
              AppIcons.callFilled,
              onPressed: () => _onTapCall(context),
            ),
            _buildIconButton(
              context,
              AppIcons.chatActive,
              onPressed: () => _onTapChat(context),
            ),
            Expanded(child: _buildWhatsappButton(context)),
          ] else ...[
            _buildButton(
              context,
              'call',
              AppIcons.callFilled,
              onPressed: () => _onTapCall(context),
            ),
            _buildButton(
              context,
              'chat',
              AppIcons.chatActive,
              onPressed: () => _onTapChat(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    String icon, {
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48.rh(context),
        width: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.tertiaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomImage(
          imageUrl: icon,
          height: 24.rh(context),
          fit: .contain,
          color: context.color.tertiaryColor,
        ),
      ),
    );
  }

  Widget _buildWhatsappButton(BuildContext context) {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      buttonTitle: 'whatsapp'.translate(context),
      height: 48.rh(context),
      onPressed: () => _onTapWhatsapp(context),
      prefixWidget: CustomImage(
        imageUrl: AppIcons.whatsapp,
        height: 24.rh(context),
        fit: .contain,
        color: context.color.buttonColor,
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String title,
    String icon, {
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: UiUtils.buildButton(
        context,
        fontSize: context.font.md,
        buttonTitle: title.translate(context),
        padding: const EdgeInsets.all(2),
        height: 48.rh(context),
        onPressed: onPressed,
        prefixWidget: Container(
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: CustomImage(
            imageUrl: icon,
            width: 18.rw(context),
            height: 18.rh(context),
            color: context.color.buttonColor,
          ),
        ),
      ),
    );
  }

  Future<void> _onTapCall(BuildContext context) async {
    final contactNumber = _propertyPhoneNumber(context);
    if (contactNumber == null || contactNumber.isEmpty) return;

    final cleanPhone = contactNumber.replaceAll(RegExp('[^0-9]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _onTapWhatsapp(BuildContext context) async {
    final mobile = _propertyPhoneNumber(context);
    final countryCode = property.agentProfile?.agentCountryCode ?? '';
    if (mobile == null || mobile.trim().isEmpty) return;
    await WhatsappHelper.open(mobile, countryCode);
  }

  Future<void> _onTapChat(BuildContext context) async {
    await openChatScreen(
      context,
      chatScreen: ChatScreenNew(
        profilePicture: property.customerProfile ?? '',
        userName: property.customerName ?? '',
        propertyImage: property.titleImage ?? '',
        proeprtyTitle: property.title ?? '',
        userId: property.addedBy.toString(),
        from: 'property',
        propertyId: property.id.toString(),
        isBlockedByMe: property.isBlockedByMe ?? false,
        isBlockedByUser: property.isBlockedByUser ?? false,
        isAgent: property.isAgent ?? false,
        isAgentVerified: property.isAgentVerified ?? false,
        isUserVerified: property.isUserVerified ?? false,
        isAdmin: property.isAdmin ?? false,
        phoneNumber: _propertyPhoneNumber(context),
        propertySlugId: property.slugId,
        receiverRoleContext: property.isAdmin == true
            ? 'admin'
            : ((property.isAgent ?? false) ? 'agent' : 'user'),
        isAppointmentAvailable:
            property.isAppointmentAvailable ?? false,
      ),
    );
  }
}
