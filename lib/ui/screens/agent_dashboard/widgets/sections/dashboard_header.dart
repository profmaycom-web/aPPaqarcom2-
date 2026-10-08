import 'package:ebroker/exports/main_export.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<UserDetailsCubit>().state.user?.name ?? '';

    return Padding(
      padding: EdgeInsets.all(16.rw(context)),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                CustomText(
                  'hello'.translate(context),
                  fontSize: context.font.md,
                  fontWeight: .w500,
                  color: context.color.textColorDark,
                ),
                SizedBox(height: 4.rh(context)),
                CustomText(
                  userName,
                  fontSize: 24,
                  fontWeight: .w700,
                  color: context.color.tertiaryColor,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.notificationPage),
            child: Container(
              width: 40.rw(context),
              height: 40.rh(context),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(6.rw(context)),
                border: Border.all(color: context.color.borderColor),
              ),
              child: Center(
                child: CustomImage(
                  imageUrl: AppIcons.notification,
                  width: 20.rw(context),
                  height: 20.rh(context),
                  color: context.color.textColorDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
