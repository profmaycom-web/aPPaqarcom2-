import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/profile_tile.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/update_tile.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Visibility { all, user, agent }

class _Item {
  const _Item({
    required this.titleKey,
    required this.icon,
    required this.onTap,
    this.visibility = _Visibility.all,
  });

  final String titleKey;
  final String icon;
  final VoidCallback onTap;
  final _Visibility visibility;

  bool isVisibleFor(ActiveRole role) => switch (visibility) {
    _Visibility.all => true,
    _Visibility.user => role != ActiveRole.agent,
    _Visibility.agent => role != ActiveRole.user,
  };
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    required this.isGuest,
    required this.onShareApp,
    required this.onRateUs,
    required this.onDeleteAccount,
    required this.onLogout,
    super.key,
  });

  final bool isGuest;
  final VoidCallback onShareApp;
  final VoidCallback onRateUs;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  List<_Item> _buildItems(BuildContext context) => [
    _Item(
      titleKey: 'favorites',
      icon: AppIcons.heartFilled,
      visibility: _Visibility.user,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(context, Routes.favoritesScreen);
          },
        );
      },
    ),
    _Item(
      titleKey: 'followings',
      icon: AppIcons.following,
      visibility: _Visibility.user,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(
              context,
              Routes.agentListScreen,
              arguments: {
                'title': 'followings'.translate(context),
                'isFollowings': true,
              },
            );
          },
        );
      },
    ),

    if (!isGuest)
      _Item(
        titleKey: 'watermarkSettings',
        icon: AppIcons.watermark,
        visibility: _Visibility.agent,
        onTap: () async {
          await Navigator.pushNamed(context, Routes.watermarkSettings);
        },
      ),
    _Item(
      titleKey: 'myStories',
      icon: AppIcons.gallery,
      visibility: _Visibility.agent,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.myStories);
      },
    ),
    _Item(
      titleKey: 'myAds',
      icon: AppIcons.promoted,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(context, Routes.myAdvertisment);
          },
        );
      },
    ),
    _Item(
      titleKey: 'myAppointments',
      icon: AppIcons.appointment,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(context, Routes.myAppointmentsScreen);
          },
        );
      },
    ),
    _Item(
      titleKey: 'configurations',
      icon: AppIcons.configuration,
      visibility: _Visibility.agent,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.appointmentConfiguration);
      },
    ),
    _Item(
      titleKey: 'subscription',
      icon: AppIcons.subscription,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(
              context,
              Routes.subscriptionPackageListRoute,
            );
          },
        );
      },
    ),

    _Item(
      titleKey: 'areaConvertor',
      visibility: _Visibility.user,
      icon: AppIcons.areaConvertor,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.areaConvertorScreen);
      },
    ),

    _Item(
      titleKey: 'shareApp',
      icon: AppIcons.shareApp,
      onTap: onShareApp,
    ),
    _Item(
      titleKey: 'rateUs',
      icon: AppIcons.rateUs,
      onTap: onRateUs,
    ),
    _Item(
      titleKey: 'preferencesSettings',
      icon: AppIcons.configuration,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.preferencesSettings);
      },
    ),
    _Item(
      titleKey: 'privacyOtherInfo',
      icon: AppIcons.info,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.privacyOtherInfo);
      },
    ),
    if (!isGuest)
      _Item(
        titleKey: 'logout',
        visibility: .user,
        icon: AppIcons.logout,
        onTap: onLogout,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.color.borderColor),
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Builder(
        builder: (context) {
          final role = RoleScope.of(context);
          final items = _buildItems(
            context,
          ).where((item) => item.isVisibleFor(role)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) _divider(context),
                ProfileTile(
                  title: items[i].titleKey.translate(context),
                  svgImagePath: items[i].icon,
                  onTap: items[i].onTap,
                  trailing: items[i].titleKey == 'preferencesSettings'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              (context.watch<LanguageCubit>().state
                                      as LanguageLoader)
                                  .languageCode
                                  .toString()
                                  .toUpperCase(),
                              color: context.color.textColorDark.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: context.font.sm,
                            ),
                            SizedBox(width: 8.rw(context)),
                            CustomImage(
                              imageUrl: AppIcons.arrowRight,
                              matchTextDirection: true,
                              height: 16,
                              fit: .contain,
                              color: context.color.textLightColor,
                            ),
                          ],
                        )
                      : (items[i].titleKey == 'privacyOtherInfo'
                            ? CustomImage(
                                imageUrl: AppIcons.arrowRight,
                                matchTextDirection: true,
                                height: 16,
                                fit: .contain,
                                color: context.color.textLightColor,
                              )
                            : null),
                ),
              ],
              if (Constant.isUpdateAvailable) ...[
                _divider(context),
                UpdateTile(
                  title: 'update'.translate(context),
                  newVersion: Constant.newVersionNumber,
                  isUpdateAvailable: Constant.isUpdateAvailable,
                  svgImagePath: AppIcons.update,
                  onTap: () async {
                    if (Platform.isIOS) {
                      await launchUrl(Uri.parse(AppSettings.appstoreURLios));
                    } else if (Platform.isAndroid) {
                      await launchUrl(
                        Uri.parse(AppSettings.playstoreURLAndroid),
                      );
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Widget _divider(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Container(height: 1, color: context.color.borderColor),
);
