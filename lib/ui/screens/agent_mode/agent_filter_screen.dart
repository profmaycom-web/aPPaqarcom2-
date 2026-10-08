import 'package:ebroker/data/cubits/agents/fetch_agent_filter_options_cubit.dart';
import 'package:ebroker/data/model/agent/agent_filter_options_model.dart';
import 'package:ebroker/data/model/agent/agent_list_filter.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

/// Full-screen editor for [AgentListFilter]. Every option list (property
/// types, service areas, languages) comes from `GET /agent-filter-options`.
/// Pops the new filter on apply; clear all pops an empty filter (keeping the
/// app bar search text) so the list is refetched without filters.
class AgentFilterScreen extends StatefulWidget {
  const AgentFilterScreen({required this.initial, super.key});

  final AgentListFilter initial;

  static Future<AgentListFilter?> open(
    BuildContext context, {
    required AgentListFilter initial,
  }) {
    return Navigator.push<AgentListFilter>(
      context,
      CupertinoPageRoute(
        builder: (_) => AgentFilterScreen(initial: initial),
      ),
    );
  }

  @override
  State<AgentFilterScreen> createState() => _AgentFilterScreenState();
}

/// Options of one `agent-filter-options` field shown on the screen: seeded
/// from the combined (offset/limit) call, then searched / paged via `field=`
/// calls. Clearing the search restores the seed locally, without a request.
class _FieldOptions<T> {
  _FieldOptions(this.field, this.parse);

  final String field;
  final T Function(dynamic) parse;
  final TextEditingController input = TextEditingController();
  AgentFilterOptionPage<T> seed = AgentFilterOptionPage<T>();
  List<T> items = [];
  int total = 0;
  String query = '';
  bool loading = false;
  bool isSearchMode = false;
  Timer? debounce;
  int requestId = 0;

  bool get hasMore => items.length < total;

  void applySeed(AgentFilterOptionPage<T> page) {
    seed = page;
    if (!isSearchMode) reset();
  }

  void reset() {
    debounce?.cancel();
    requestId++;
    query = '';
    isSearchMode = false;
    loading = false;
    items = List.of(seed.options);
    total = seed.total;
  }

  void dispose() {
    debounce?.cancel();
    input.dispose();
  }
}

class _AgentFilterScreenState extends State<AgentFilterScreen> {
  final AgentsRepository _repository = AgentsRepository();
  late Set<String> _serviceAreas;
  late Set<String> _languages;
  late bool _isVerified;
  late int _experience;

  /// 0 = sell, 1 = rent, null = any.
  int? _propertyType;

  /// Multi-select: user can select one or more categories.
  final Map<int, AgentFilterCategoryOption> _selectedCategories = {};

  final _serviceAreaOptions = _FieldOptions<String>(
    'service_areas',
    AgentFilterOptionsModel.parseString,
  );
  final _languageOptions = _FieldOptions<String>(
    'languages',
    AgentFilterOptionsModel.parseString,
  );
  final _categoryOptions = _FieldOptions<AgentFilterCategoryOption>(
    'property_categories',
    AgentFilterOptionsModel.parseCategory,
  );

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _serviceAreas = f.serviceArea.toSet();
    _languages = f.language.toSet();
    _experience = f.minExperience ?? 0;
    _isVerified = f.isVerified;
    _propertyType = f.propertyType;
    for (final id in f.categoryIds) {
      _selectedCategories[id] = AgentFilterCategoryOption(
        id: id,
        name: f.categoryNames[id] ?? '',
      );
    }
    final legacyCategoryId = f.categoryId;
    if (legacyCategoryId != null &&
        !_selectedCategories.containsKey(legacyCategoryId)) {
      _selectedCategories[legacyCategoryId] = AgentFilterCategoryOption(
        id: legacyCategoryId,
        name: f.categoryName ?? '',
      );
    }
    final cubit = context.read<FetchAgentFilterOptionsCubit>();
    // Show the last options right away, then refetch so lists and totals
    // are live on every open.
    _seed(cubit.state);
    unawaited(cubit.fetchOptions());
  }

  @override
  void dispose() {
    _serviceAreaOptions.dispose();
    _languageOptions.dispose();
    _categoryOptions.dispose();
    super.dispose();
  }

  void _seed(FetchAgentFilterOptionsState state) {
    if (state is! FetchAgentFilterOptionsSuccess) return;
    _serviceAreaOptions.applySeed(state.options.serviceAreas);
    _languageOptions.applySeed(state.options.languages);
    _categoryOptions.applySeed(state.options.propertyCategories);
    for (final cat in state.options.propertyCategories.options) {
      if (_selectedCategories.containsKey(cat.id)) {
        _selectedCategories[cat.id] = cat;
      }
    }
  }

  /// Fetches the first page for the current query, or the next page when
  /// [more] is set. Stale responses (older request ids) are dropped.
  Future<void> _load<T>(_FieldOptions<T> f, {bool more = false}) async {
    final id = ++f.requestId;
    setState(() => f.loading = true);
    try {
      final page = await _repository.fetchAgentFilterFieldOptions<T>(
        field: f.field,
        parse: f.parse,
        search: f.query,
        offset: more ? f.items.length : 0,
      );
      if (!mounted || id != f.requestId) return;
      setState(() {
        f
          ..items = more ? [...f.items, ...page.options] : page.options
          ..total = page.total
          ..isSearchMode = true;
        if (f == _categoryOptions) {
          for (final cat in page.options) {
            final category = cat as AgentFilterCategoryOption;
            if (_selectedCategories.containsKey(category.id)) {
              _selectedCategories[category.id] = category;
            }
          }
        }
      });
    } on ApiException catch (_) {
      // Keep whatever options are already shown.
    } finally {
      if (mounted && id == f.requestId) setState(() => f.loading = false);
    }
  }

  void _onSearchChanged<T>(_FieldOptions<T> f, String value) {
    f.debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(f.reset);
      return;
    }
    setState(() {});
    f.debounce = Timer(const Duration(milliseconds: 400), () {
      f.query = query;
      unawaited(_load(f));
    });
  }

  void _clearSearch<T>(_FieldOptions<T> f) {
    f.input.clear();
    setState(f.reset);
  }

  void _apply() {
    Navigator.pop(
      context,
      AgentListFilter(
        search: widget.initial.search,
        serviceArea: _serviceAreas.toList(),
        language: _languages.toList(),
        isVerified: _isVerified,
        minExperience: _experience > 0 ? _experience : null,
        propertyType: _propertyType,
        categoryIds: _selectedCategories.keys.toList(),
        categoryNames: {
          for (final entry in _selectedCategories.entries)
            entry.key: entry.value.name,
        },
      ),
    );
  }

  /// Drops every filter and refetches the list; the app bar search stays.
  void _clear() {
    Navigator.pop(context, AgentListFilter(search: widget.initial.search));
  }

  String _withCount(String key, int count) =>
      key.translate(context).replaceAll('{count}', count.toString());

  /// Category image from the app's category list, matched by id; the
  /// filter-options API returns only id and name.
  String? _categoryImage(int id) {
    final state = context.watch<FetchCategoryCubit>().state;
    if (state is! FetchCategorySuccess) return null;
    for (final c in state.categories) {
      if (c.id == id) return c.image;
    }
    return null;
  }

  Widget _label(String key) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.rh(context)),
      child: CustomText(
        key.translate(context),
        fontSize: context.font.sm,
        fontWeight: FontWeight.w500,
        color: context.color.textColorDark,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = context.color.tertiaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.rw(context),
          vertical: 5.rh(context),
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : context.color.textLightColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomText(
          label,
          fontSize: context.font.sm,
          color: selected ? Colors.white : context.color.textColorDark,
        ),
      ),
    );
  }

  Widget _moreChip<T>(_FieldOptions<T> f) {
    final accent = context.color.tertiaryColor;
    return GestureDetector(
      onTap: () => unawaited(_load(f, more: true)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.rw(context),
          vertical: 5.rh(context),
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomText(
          _withCount('moreCount', f.total - f.items.length),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  /// Search box + selectable chips for one string option field. Selected
  /// chips come first (they may not be in the loaded page), then the rest of
  /// the loaded options, then a "+N more" chip while more remain.
  Widget _stringPicker({
    required String titleKey,
    required _FieldOptions<String> options,
    required String hintKey,
    required Set<String> selected,
  }) {
    final visible = [
      ...selected,
      ...options.items.where((o) => !selected.contains(o)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(titleKey),
        CustomTextFormField(
          controller: options.input,
          hintText: _withCount(hintKey, options.total),
          borderColor: context.color.borderColor,
          fillColor: context.color.textLightColor.withValues(alpha: 0.08),
          action: TextInputAction.search,
          onChange: (value) => _onSearchChanged(options, value.toString()),
          suffix: options.input.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.color.textColorDark,
                    size: 20,
                  ),
                  onPressed: () => _clearSearch(options),
                ),
        ),
        if (options.loading)
          Padding(
            padding: EdgeInsets.only(top: 10.rh(context)),
            child: Center(child: UiUtils.progress(width: 20, height: 20)),
          ),
        if (visible.isNotEmpty || options.hasMore) ...[
          SizedBox(height: 10.rh(context)),
          Wrap(
            spacing: 8.rw(context),
            runSpacing: 8.rh(context),
            children: [
              for (final o in visible)
                _chip(
                  label: o,
                  selected: selected.contains(o),
                  onTap: () => setState(
                    () => selected.contains(o)
                        ? selected.remove(o)
                        : selected.add(o),
                  ),
                ),
              if (options.hasMore && !options.loading) _moreChip(options),
            ],
          ),
        ],
      ],
    );
  }

  Widget _categoryChip(AgentFilterCategoryOption option) {
    final selected = _selectedCategories.containsKey(option.id);
    final accent = context.color.tertiaryColor;
    final image = _categoryImage(option.id);
    final iconColor = selected ? accent : context.color.textLightColor;
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedCategories.remove(option.id);
        } else {
          _selectedCategories[option.id] = option;
        }
      }),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8.rw(context),
          vertical: 4.rh(context),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.2)
                : context.color.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null && image.isNotEmpty)
              CustomImage(
                imageUrl: image,
                width: 18.rw(context),
                height: 18.rh(context),
                color: iconColor,
              )
            else
              Icon(Icons.home_outlined, size: 18, color: iconColor),
            SizedBox(width: 8.rw(context)),
            CustomText(
              option.name,
              fontSize: context.font.sm,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? accent : context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }

  /// All / Sell / Rent toggle; "All" (null) means no property type filter.
  Widget _propertyTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('propertyType'),
        Wrap(
          spacing: 8.rw(context),
          runSpacing: 8.rh(context),
          children: [
            for (final (value, key) in [
              (null, 'all'),
              (0, 'sell'),
              (1, 'rent'),
            ])
              _chip(
                label: key.translate(context),
                selected: _propertyType == value,
                onTap: () => setState(() => _propertyType = value),
              ),
          ],
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }

  /// App categories, used when the filter-options API returns none.
  List<AgentFilterCategoryOption> _appCategories() {
    final state = context.watch<FetchCategoryCubit>().state;
    if (state is! FetchCategorySuccess) return [];
    return [
      for (final c in state.categories)
        if (c.id != null)
          AgentFilterCategoryOption(id: c.id!, name: c.category ?? ''),
    ];
  }

  Widget _propertyCategories() {
    final options = _categoryOptions;
    final useFallback = options.items.isEmpty && !options.isSearchMode;
    final items = useFallback ? _appCategories() : options.items;
    final itemIds = items.map((o) => o.id).toSet();
    final externalSelected = _selectedCategories.values.where(
      (c) => !itemIds.contains(c.id),
    );
    final visible = [
      ...externalSelected,
      ...items,
    ];
    final hasMore = !useFallback && options.hasMore;
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('propertyCategories'),
        SizedBox(
          height: 32.rh(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: Constant.scrollPhysics,
            itemCount: visible.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, _) => SizedBox(width: 8.rw(context)),
            itemBuilder: (context, index) {
              if (index == visible.length) {
                return options.loading
                    ? Center(child: UiUtils.progress(width: 20, height: 20))
                    : Center(child: _moreChip(options));
              }
              return _categoryChip(visible[index]);
            },
          ),
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? context.color.textLightColor
              : context.color.textColorDark,
        ),
      ),
    );
  }

  Widget _experienceStepper() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.rw(context),
        vertical: 6.rh(context),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              'experienceInYears'.translate(context),
              fontSize: context.font.sm,
              color: context.color.textColorDark,
            ),
          ),
          _stepButton(
            Icons.remove,
            _experience > 0 ? () => setState(() => _experience--) : null,
          ),
          SizedBox(
            width: 32.rw(context),
            child: CustomText(
              '$_experience',
              textAlign: TextAlign.center,
              color: context.color.textColorDark,
            ),
          ),
          _stepButton(Icons.add, () => setState(() => _experience++)),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return BottomAppBar(
      height: 72.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: context.color.primaryColor,
      child: Row(
        children: [
          Expanded(
            child: UiUtils.buildButton(
              context,
              onPressed: _clear,
              buttonColor: context.color.secondaryColor,
              showElevation: false,
              textColor: context.color.tertiaryColor,
              border: BorderSide(color: context.color.tertiaryColor),
              buttonTitle: 'clearAll'.translate(context),
            ),
          ),
          SizedBox(width: 16.rw(context)),
          Expanded(
            child: UiUtils.buildButton(
              context,
              onPressed: _apply,
              buttonColor: context.color.tertiaryColor,
              textColor: context.color.buttonColor,
              buttonTitle: 'apply'.translate(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      FetchAgentFilterOptionsCubit,
      FetchAgentFilterOptionsState
    >(
      listener: (context, state) => setState(() => _seed(state)),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: CustomAppBar(title: 'filterTitle'.translate(context)),
          bottomNavigationBar: _bottomBar(),
          body: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _propertyCategories(),
                _propertyTypes(),
                _card(
                  children: [
                    _stringPicker(
                      titleKey: 'serviceAreas',
                      options: _serviceAreaOptions,
                      hintKey: 'searchServiceAreasHint',
                      selected: _serviceAreas,
                    ),
                    SizedBox(height: 16.rh(context)),
                    _stringPicker(
                      titleKey: 'languagesSpoken',
                      options: _languageOptions,
                      hintKey: 'searchLanguagesHint',
                      selected: _languages,
                    ),
                    SizedBox(height: 16.rh(context)),
                    _experienceStepper(),
                  ],
                ),
                SizedBox(height: 16.rh(context)),
                _card(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 22,
                          color: context.color.textColorDark,
                        ),
                        SizedBox(width: 12.rw(context)),
                        Expanded(
                          child: CustomText(
                            'verifiedAgentsOnly'.translate(context),
                            color: context.color.textColorDark,
                          ),
                        ),
                        UiSwitch(
                          value: _isVerified,
                          onChanged: (v) => setState(() => _isVerified = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
