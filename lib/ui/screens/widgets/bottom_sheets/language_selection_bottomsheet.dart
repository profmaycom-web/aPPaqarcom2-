import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class LanguageSelectionBottomSheet extends StatefulWidget {
  const LanguageSelectionBottomSheet({super.key});

  @override
  State<LanguageSelectionBottomSheet> createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  bool _syncingLanguage = false;
  List<dynamic>? _languages;
  final ValueNotifier<String?> _loadingLanguageCode = ValueNotifier<String?>(
    null,
  );

  @override
  void initState() {
    super.initState();
    final list =
        context.read<FetchSystemSettingsCubit>().getSetting(
              SystemSetting.languageType,
            )
            as List?;
    if (list != null && list.isNotEmpty) {
      _languages = list;
    } else if (AppSettings.languages.isNotEmpty) {
      _languages = AppSettings.languages.map((e) => e.toMap()).toList();
    }
  }

  @override
  void dispose() {
    _loadingLanguageCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_languages == null || _languages!.isEmpty) {
      final list =
          context.watch<FetchSystemSettingsCubit>().getSetting(
                SystemSetting.languageType,
              )
              as List?;
      if (list != null && list.isNotEmpty) {
        _languages = list;
      } else if (AppSettings.languages.isNotEmpty) {
        _languages = AppSettings.languages.map((e) => e.toMap()).toList();
      }
    }

    final languageState = context.watch<LanguageCubit>().state;
    final currentLanguageLoader = languageState as LanguageLoader;

    return MultiBlocListener(
      listeners: [
        BlocListener<FetchLanguageCubit, FetchLanguageState>(
          listener: (context, state) async {
            if (state is FetchLanguageFailure) {
              _loadingLanguageCode.value = null;
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: .error,
              );
            }
            if (state is FetchLanguageSuccess) {
              final map = state.toMap();
              final data = map['file_name'];
              map['data'] = data;

              map.remove('file_name');
              await HiveUtils.storeLanguage(map);
              context.read<LanguageCubit>().emitLanguageLoader(
                code: state.code,
                isRtl: state.isRTL,
              );

              _syncingLanguage = true;
              await context.read<UpdateLanguageCubit>().updateLanguage(
                languageCode: state.code,
              );
            }
          },
        ),
        BlocListener<UpdateLanguageCubit, UpdateLanguageState>(
          listener: (context, state) async {
            if (state is UpdateLanguageFailure) {
              _loadingLanguageCode.value = null;
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: .error,
              );
              if (_syncingLanguage) {
                _syncingLanguage = false;
                if (mounted) Navigator.pop(context);
              }
            } else if (state is UpdateLanguageSuccess ||
                state is UpdateLanguageSkipped) {
              _loadingLanguageCode.value = null;
              if (_syncingLanguage) {
                LanguageChangeHelper.refreshAppData(context);
                _syncingLanguage = false;
                if (mounted) Navigator.pop(context);
              }
            }
          },
        ),
      ],
      child: CustomBottomSheet(
        title: 'chooseLanguage'.translate(context),
        child: _languages == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: UiUtils.progress(
                    normalProgressColor: context.color.tertiaryColor,
                  ),
                ),
              )
            : ValueListenableBuilder<String?>(
                valueListenable: _loadingLanguageCode,
                builder: (context, loadingLanguageCode, child) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _languages!.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final lang = _languages![index];
                      final isSelected =
                          currentLanguageLoader.languageCode == lang['code'];
                      final itemColor = isSelected
                          ? context.color.tertiaryColor
                          : context.color.textLightColor.withValues(
                              alpha: 0.03,
                            );

                      return GestureDetector(
                        onTap: loadingLanguageCode != null
                            ? null
                            : () async {
                                final selectedCode =
                                    lang['code']?.toString() ?? '';
                                if (selectedCode ==
                                    currentLanguageLoader.languageCode) {
                                  Navigator.pop(context);
                                  return;
                                }
                                _loadingLanguageCode.value = selectedCode;
                                await context
                                    .read<FetchLanguageCubit>()
                                    .getLanguage(
                                      selectedCode,
                                    );
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 48.rh(context),
                          alignment: AlignmentDirectional.centerStart,
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                lang['name']?.toString() ?? '',
                                fontWeight: FontWeight.bold,
                                fontSize: context.font.md,
                                color: isSelected
                                    ? context.color.buttonColor
                                    : context.color.textColorDark,
                              ),
                              if (lang['code']?.toString() ==
                                  loadingLanguageCode)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isSelected
                                        ? context.color.buttonColor
                                        : context.color.tertiaryColor,
                                  ),
                                )
                              else if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: context.color.buttonColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
