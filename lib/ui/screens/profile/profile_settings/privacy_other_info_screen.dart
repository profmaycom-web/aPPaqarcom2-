import 'package:ebroker/data/model/custom_page_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/profile_tile.dart';
import 'package:material_ui/material_ui.dart';

class PrivacyOtherInfoScreen extends StatefulWidget {
  const PrivacyOtherInfoScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const PrivacyOtherInfoScreen(),
    );
  }

  @override
  State<PrivacyOtherInfoScreen> createState() => _PrivacyOtherInfoScreenState();
}

class _PrivacyOtherInfoScreenState extends State<PrivacyOtherInfoScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<FetchCustomPagesCubit>().state
        is! FetchCustomPagesSuccess) {
      unawaited(context.read<FetchCustomPagesCubit>().fetchCustomPages());
    }
  }

  Widget _divider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Container(height: 1, color: context.color.borderColor),
  );

  @override
  Widget build(BuildContext context) {
    final chevronTrailing = Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: context.color.textColorDark.withValues(alpha: 0.3),
    );

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'privacyOtherInfo'.translate(context),
      ),
      body: BlocBuilder<FetchCustomPagesCubit, FetchCustomPagesState>(
        builder: (context, state) {
          if (state is FetchCustomPagesInProgress) {
            return SingleChildScrollView(
              physics: Constant.scrollPhysics,
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.color.borderColor),
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(5, (index) {
                    return Column(
                      children: [
                        if (index > 0) _divider(context),
                        CustomShimmer(
                          height: 20.rh(context),
                          width: double.infinity,
                          borderRadius: 4,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          }

          final customPages = state is FetchCustomPagesSuccess
              ? state.pages
              : <CustomPageModel>[];

          return SingleChildScrollView(
            physics: Constant.scrollPhysics,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Privacy Policy
                  ProfileTile(
                    title: 'privacyPolicy'.translate(context),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.profileSettings,
                        arguments: {
                          'title': 'privacyPolicy'.translate(context),
                          'param': Api.privacyPolicy,
                        },
                      );
                    },
                    trailing: chevronTrailing,
                  ),
                  _divider(context),

                  // 2. Terms & Conditions
                  ProfileTile(
                    title: 'termsConditions'.translate(context),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.profileSettings,
                        arguments: {
                          'title': 'termsConditions'.translate(context),
                          'param': Api.termsAndConditions,
                        },
                      );
                    },
                    trailing: chevronTrailing,
                  ),

                  // 3. Dynamic Custom Pages from API
                  if (customPages.isNotEmpty) ...[
                    ...customPages.map((page) {
                      return Column(
                        children: [
                          _divider(context),
                          ProfileTile(
                            title: page.displayTitle,
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                Routes.profileSettings,
                                arguments: {
                                  'title': page.displayTitle,
                                  'content': page.displayContent,
                                },
                              );
                            },
                            trailing: chevronTrailing,
                          ),
                        ],
                      );
                    }),
                  ],
                  _divider(context),

                  // 4. About Us
                  ProfileTile(
                    title: 'aboutUs'.translate(context),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.profileSettings,
                        arguments: {
                          'title': 'aboutUs'.translate(context),
                          'param': Api.aboutApp,
                        },
                      );
                    },
                    trailing: chevronTrailing,
                  ),
                  _divider(context),

                  // FAQs
                  if (RoleScope.of(context) != ActiveRole.agent) ...[
                    ProfileTile(
                      title: 'faqScreen'.translate(context),
                      onTap: () async {
                        await Navigator.pushNamed(context, Routes.faqsScreen);
                      },
                      trailing: chevronTrailing,
                    ),
                    _divider(context),
                  ],

                  // 5. Contact Us
                  ProfileTile(
                    title: 'contactUs'.translate(context),
                    onTap: () async {
                      await Navigator.pushNamed(context, Routes.contactUs);
                    },
                    trailing: chevronTrailing,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
