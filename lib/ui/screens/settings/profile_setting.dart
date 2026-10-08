import 'package:ebroker/exports/main_export.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key, this.title, this.param, this.content});
  final String? title;
  final String? param;

  /// Pre-loaded HTML content. When provided, skips the API fetch entirely.
  final String? content;

  @override
  ProfileSettingsState createState() => ProfileSettingsState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => ProfileSettings(
        title: arguments?['title'] as String?,
        param: arguments?['param'] as String?,
        content: arguments?['content'] as String?,
      ),
    );
  }
}

class ProfileSettingsState extends State<ProfileSettings> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      if (!mounted) return;
      if (widget.content != null) {
        context.read<ProfileSettingCubit>().emitPreloaded(widget.content!);
        return;
      }
      await context.read<ProfileSettingCubit>().fetchProfileSetting(
        widget.param!,
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryColor,
      appBar: CustomAppBar(
        title: widget.title ?? '',
      ),
      body: BlocBuilder<ProfileSettingCubit, ProfileSettingState>(
        builder: (context, state) {
          if (state is ProfileSettingFetchProgress) {
            return Center(
              child: UiUtils.progress(
                normalProgressColor: context.color.tertiaryColor,
              ),
            );
          } else if (state is ProfileSettingFetchSuccess) {
            return contentWidget(state, context);
          } else if (state is ProfileSettingFetchFailure) {
            if (state.errmsg is NoInternetConnectionError) {
              return NoInternet(
                onRetry: () async {
                  if (widget.content != null) {
                    context.read<ProfileSettingCubit>().emitPreloaded(
                      widget.content!,
                    );
                    return;
                  }
                  await context.read<ProfileSettingCubit>().fetchProfileSetting(
                    widget.param!,
                    forceRefresh: true,
                  );
                },
              );
            }

            return Center(
              child: SomethingWentWrong(
                errorMessage: state.errmsg?.toString() ?? '',
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

Widget contentWidget(ProfileSettingFetchSuccess state, BuildContext context) {
  return SingleChildScrollView(
    physics: Constant.scrollPhysics,
    padding: .symmetric(horizontal: 20.rw(context), vertical: 16.rh(context)),
    child: HtmlWidget(
      state.data,
      onTapUrl: (url) async {
        final result = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        return result;
      },
      customWidgetBuilder: (element) {
        // fwfh does not render form inputs. Draw checkboxes manually so
        // permission tables (read/update/etc.) show their state.
        if (element.localName == 'input' &&
            element.attributes['type'] == 'checkbox') {
          final checked = element.attributes.containsKey('checked');
          return Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: checked
                ? context.color.tertiaryColor
                : context.color.textColorDark.withValues(alpha: 0.4),
          );
        }
        return null;
      },
      textStyle: TextStyle(color: context.color.textColorDark),
    ),
  );
}
