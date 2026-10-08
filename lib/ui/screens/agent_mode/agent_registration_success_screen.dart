import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/auth/get_user_data_cubit.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class AgentRegistrationSuccessScreen extends StatelessWidget {
  const AgentRegistrationSuccessScreen({required this.from, super.key});

  final String from;

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => AgentRegistrationSuccessScreen(
        from: routeSettings.arguments as String? ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress =
        context.read<GetUserDataCubit>().state is GetUserDataInProgress;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: 'agentRegistration'.translate(context),
          showBackButton: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                CustomImage(
                  imageUrl: AppIcons.becomeAgentReview,
                  fit: .contain,
                  width: 280.rw(context),
                ),
                SizedBox(height: 32.rh(context)),
                CustomText(
                  from == 'becomeAgent'
                      ? 'registeredSuccessfully'.translate(context)
                      : 'agentVerificationRegisteredSuccess'.translate(context),
                  fontSize: context.font.xxl,
                  fontWeight: .w700,
                  color: context.color.tertiaryColor,
                  textAlign: .center,
                ),
                SizedBox(height: 12.rh(context)),
                CustomText(
                  from == 'becomeAgent'
                      ? 'agentRegistrationSuccessMessage'.translate(context)
                      : 'agentVerificationRegisteredSuccessDescription'
                            .translate(
                              context,
                            ),
                  fontSize: context.font.sm,
                  color: context.color.textLightColor,
                  textAlign: .center,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: UiUtils.buildButton(
            context,
            buttonTitle: 'backToHome'.translate(context),
            textColor: context.color.buttonColor,
            isInProgress: isInProgress,
            onPressed: () async {
              await context.read<GetUserDataCubit>().getUserData();
              await Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.main,
                (route) => false,
                arguments: {'from': 'becomeAgent'},
              );
            },
          ),
        ),
      ),
    );
  }
}
