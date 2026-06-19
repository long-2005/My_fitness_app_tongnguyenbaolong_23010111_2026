import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/data/repositories/workout_repository.dart';
import 'package:flutter_application_1/data/models/calisthenics_exercise.dart';
import 'package:flutter_application_1/data/models/planned_exercise.dart';
import 'package:flutter_application_1/data/models/workout_exercise.dart';
import 'package:flutter_application_1/presentation/views/workout/workout_session_view.dart';

class ScheduleView extends StatefulWidget {
  final bool isSelected;
  const ScheduleView({super.key, this.isSelected = false});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  static const _accent = Color(0xFFE16D6D);

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && oldWidget.isSelected) {
      _clearExerciseSearch();
    }
  }
  static const _navSelected = Color.fromARGB(255, 133, 20, 20);
  static const _surface = Color.fromARGB(16, 218, 218, 218);
  static const _svgAsset = 'assets/image/new1.svg';
  static const _cardShadow = [
    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
  ];

  static const List<_MuscleOption> _muscles = [
    _MuscleOption('chest', 'Chest', Icons.accessibility_new_rounded),
    _MuscleOption('lats', 'Lats', Icons.expand_rounded),
    _MuscleOption('back_shoulder', 'Rear shoulder', Icons.rotate_left_rounded),
    _MuscleOption(
      'font_shoulder',
      'Front shoulder',
      Icons.rotate_right_rounded,
    ),
    _MuscleOption('biceps', 'Biceps', Icons.fitness_center_rounded),
    _MuscleOption('triceps', 'Triceps', Icons.fitness_center_rounded),
    _MuscleOption('forearms', 'Forearms', Icons.back_hand_rounded),
    _MuscleOption('abs', 'Abs', Icons.grid_view_rounded),
    _MuscleOption('lowerabs', 'Lower abs', Icons.grid_3x3_rounded),
    _MuscleOption('obliques', 'Obliques', Icons.view_week_rounded),
    _MuscleOption('serratus', 'Serratus', Icons.blur_linear_rounded),
    _MuscleOption('traps', 'Traps', Icons.change_history_rounded),
    _MuscleOption('back_trap', 'Back trap', Icons.change_history_rounded),
    _MuscleOption('lower_back', 'Lower back', Icons.airline_seat_recline_extra),
    _MuscleOption('glutes', 'Glutes', Icons.circle_rounded),
    _MuscleOption('quads', 'Quads', Icons.directions_run_rounded),
    _MuscleOption('hamstrings', 'Hamstrings', Icons.directions_run_rounded),
    _MuscleOption('adductors', 'Adductors', Icons.merge_type_rounded),
    _MuscleOption('calves', 'Calves', Icons.directions_walk_rounded),
  ];

  static const Map<String, List<String>> _svgGroupAliases = {
    'abs': ['abs', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    'lowerabs': ['lowerabs', '7_2'],
    'forearms': ['forearms', 'forearms_2'],
    'calves': [
      'calves',
      'calves_2',
      '1_3',
      'Vector_414',
      'Vector_415',
      'Vector_416',
      'Vector_417',
      'Vector_418',
    ],
  };

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<int> _weekDisplayOrder = [6, 0, 1, 2, 3, 4, 5];
  static const List<String> _weekDisplayLabels = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  final Map<int, Map<String, PlannedExercise>> _weeklyPlan = {
    for (var index = 0; index < _days.length; index++)
      index: <String, PlannedExercise>{},
  };

  int _selectedDay = DateTime.now().weekday - 1;
  final TextEditingController _searchController = TextEditingController();
  List<CalisthenicsExercise> _exercises = [];
  List<CalisthenicsExercise> _searchResults = const [];
  String _query = '';
  String? _muscleFilter;
  bool _hasSearched = false;
  String? _rawSvg;

  // ── Performance caches ─────────────────────────────────────
  // Recomputed only when _weeklyPlan or _exercises change
  Map<String, int> _cachedFrequency = {};
  // Cached painted SVG; now stores a Future since it's computed asynchronously
  Future<String>? _cachedPaintedSvgFuture;
  String _svgCacheKey = '';
  // Fast exercise lookup
  Map<String, CalisthenicsExercise> _exerciseById = {};

  // ── Search debounce & display limit ───────────────────────
  Timer? _debounce;
  static const int _pageSize = 30; // số kết quả hiển thị tối đa mỗi lần
  int _displayLimit = _pageSize;   // tăng dần khi nhấn "Show more"

  @override
  void initState() {
    super.initState();
    _loadSvg();
    _loadExercises();
    _loadWeeklyPlan();
    // Debounced listener: cập nhật kết quả 300ms sau khi người dùng ngừng gõ.
    // Không gọi setState ngay lập tức → keyboard không bị lag.
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final searchQuery = _searchController.text.trim().toLowerCase();
      // Chỉ rebuild phần search results, không ảnh hưởng SVG cache
      setState(() {
        _query = searchQuery;
        _displayLimit = _pageSize;
        _hasSearched = searchQuery.isNotEmpty || _muscleFilter != null;
        _searchResults = _hasSearched ? _filteredExercises : const [];
      });
    });
  }

  void _submitExerciseSearch([String? query]) {
    _debounce?.cancel();
    final searchQuery = (query ?? _searchController.text).trim().toLowerCase();
    setState(() {
      _query = searchQuery;
      _displayLimit = _pageSize;
      _hasSearched = searchQuery.isNotEmpty || _muscleFilter != null;
      _searchResults = _hasSearched ? _filteredExercises : const [];
    });
  }

  void _clearExerciseSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _displayLimit = _pageSize;
      _searchResults = const [];
      _hasSearched = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSvg() async {
    final svg = await rootBundle.loadString(_svgAsset);
    if (!mounted) return;
    setState(() {
      _rawSvg = svg;
    });
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await WorkoutService.instance.getExercises();
      if (!mounted) return;
      setState(() {
        _exercises = List.of(exercises);
        _exerciseById = {for (final e in _exercises) e.id: e};
        _invalidateSvgCache();
      });
    } catch (e, stack) {
      print("DEBUG: Error loading exercises: $e");
      print(stack);
    }
  }

  Future<void> _loadWeeklyPlan() async {
    final plan = await WorkoutService.instance.loadWeeklyPlan();
    _replaceWeeklyPlan(plan);
  }

  void _replaceWeeklyPlan(Map<int, Map<String, PlannedExercise>> plan) {
    if (!mounted) return;
    setState(() {
      _weeklyPlan
        ..clear()
        ..addAll(plan);
      _invalidateSvgCache();
    });
  }

  Future<void> _saveWeeklyPlan() async {
    await WorkoutService.instance.saveWeeklyPlan(_weeklyPlan);
  }

  @override
  Widget build(BuildContext context) {
    final frequency = _getFrequency();
    final activeMuscles = frequency.values
        .where((frequencyCount) => frequencyCount > 0)
        .length;
    final totalSessions = _weeklyPlan.values
        .where((muscles) => muscles.isNotEmpty)
        .length;

    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: _accent,
        onRefresh: () async {
          WorkoutService.instance.clearExerciseCache();
          await _loadExercises();
          await _loadWeeklyPlan();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 20,
              title: const Text(
                'Training Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Reset week',
                  onPressed: _clearWeek,
                  icon: const Icon(Icons.restart_alt_rounded, color: _accent),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade900,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList.list(
                children: [
                  _buildSummary(activeMuscles, totalSessions),
                  const SizedBox(height: 16),
                  _buildMuscleMap(frequency),
                  const SizedBox(height: 16),
                  _buildDaySelector(),
                  const SizedBox(height: 12),
                  _buildDayScheduleBoard(),
                  const SizedBox(height: 16),
                  _buildScheduleBuilder(),
                  const SizedBox(height: 16),
                  _buildWeeklyBreakdown(frequency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(int activeMuscles, int totalSessions) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            title: 'Sessions',
            value: '$totalSessions',
            unit: 'days/week',
            icon: Icons.calendar_month_rounded,
            color: _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            title: 'Muscles',
            value: '$activeMuscles',
            unit: 'groups hit',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF9F43),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleMap(Map<String, int> frequency) {
    final svg = _rawSvg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.whatshot_rounded, color: _accent, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Weekly muscle heat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1545 / 1018,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: svg == null
                    ? const CircularProgressIndicator(color: _accent)
                    : FutureBuilder<String>(
                        future: _getCachedPaintedSvgFuture(svg, frequency),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator(color: _accent);
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Icon(Icons.error_outline_rounded, color: Colors.white54);
                          }
                          return RepaintBoundary(
                            child: SvgPicture.string(
                              snapshot.data!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _legendItem('0', const Color(0xFF6D6D6D)),
              _legendItem('1', _heatColor(1)),
              _legendItem('2', _heatColor(2)),
              _legendItem('3', _heatColor(3)),
              _legendItem('4+', _heatColor(4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: List.generate(_weekDisplayOrder.length, (position) {
          final dayIndex = _weekDisplayOrder[position];
          final selected = _selectedDay == dayIndex;
          final count = _weeklyPlan[dayIndex]?.length ?? 0;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedDay = dayIndex),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _weekDisplayLabels[position],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? _accent : Colors.transparent,
                      border: Border.all(
                        color: selected ? _accent : Colors.white54,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 14,
                          )
                        : count > 0
                        ? Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleBuilder() {
    final selectedExerciseIds = _weeklyPlan[_selectedDay]?.keys.toSet() ?? <String>{};
    final selectedExercises = _exercises
        .where((exercise) => selectedExerciseIds.contains(exercise.id))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(hasShadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: _accent, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create workout plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose exercises for ${_days[_selectedDay]}. Muscle heat updates from the selected exercises.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildMuscleFilters(),
          const SizedBox(height: 16),
          if (selectedExercises.isNotEmpty) ...[
            _buildSelectedExercises(selectedExercises),
            const SizedBox(height: 16),
          ],
          if (_exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: _accent)),
            )
          else if (!_hasSearched)
            Text(
              'Nhập tên bài hoặc dùng bộ lọc để tìm bài tập.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            )
          else if (_searchResults.isEmpty)
            Text(
              'Không tìm thấy bài tập phù hợp.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            )
          else
            _buildSearchResultsList(selectedExerciseIds),
        ],
      ),
    );
  }

  /// Render danh sách kết quả tìm kiếm theo kiểu lazy:
  /// - Chỉ build tối đa [_displayLimit] tile một lúc
  /// - Nút "Show more" để tải thêm 30 kết quả tiếp theo
  Widget _buildSearchResultsList(Set<String> selectedExerciseIds) {
    final visible = _searchResults.take(_displayLimit).toList();
    final hasMore = _searchResults.length > _displayLimit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lazy ListView — chỉ build widget nào đang nằm trong viewport
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final exercise = visible[index];
            return _exerciseTile(
              exercise,
              selectedExerciseIds.contains(exercise.id),
            );
          },
        ),
        // Đếm tổng + nút xem thêm
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            children: [
              Text(
                'Hiển thị ${visible.length}/${_searchResults.length} bài tập',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              if (hasMore)
                TextButton.icon(
                  onPressed: () => setState(() => _displayLimit += _pageSize),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text(
                    'Xem thêm',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: _accent),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Bảng lịch tập của ngày đang chọn, hiển thị ngay dưới day selector.
  Widget _buildDayScheduleBoard() {
    final dayPlan = _weeklyPlan[_selectedDay] ?? {};

    if (dayPlan.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_note_rounded,
              color: Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'No workout planned for ${_days[_selectedDay]}.',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    // Build danh sách bài tập trong ngày — use cached _exerciseById
    final items = dayPlan.entries
        .map((e) => (plan: e.value, exercise: _exerciseById[e.key]))
        .where((pair) => pair.exercise != null)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A0D0D), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_days[_selectedDay]} workout plan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${items.length} exercise${items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (pair) => _scheduleBoardTile(pair.exercise!, pair.plan),
          ),
        ],
      ),
    );
  }

  Widget _scheduleBoardTile(
    CalisthenicsExercise exercise,
    PlannedExercise plan,
  ) {
    final muscles = exercise.primaryMuscles
        .map(_muscleLabel)
        .where((l) => l.isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise, plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: _accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (muscles.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      muscles,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${plan.sets} sets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '× ${plan.reps} reps',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet chi tiết bài tập
  void _showExerciseDetail(
    CalisthenicsExercise exercise,
    PlannedExercise plan,
  ) {
    final primaryLabels = exercise.primaryMuscles.map(_muscleLabel).join(', ');
    final secondaryLabels =
        exercise.secondaryMuscles.map(_muscleLabel).join(', ');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF161616),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: _accent, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise.name,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w800, fontFamily: 'Poppins',
                              ),
                            ),
                            Text('${exercise.level} \u2022 ${exercise.equipment}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Chips: Sets, Reps or Hold, Rest
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      _detailChip(Icons.repeat_rounded, '${plan.sets} Sets', _accent),
                      if (plan.isHold)
                        _detailChip(Icons.timer_outlined, '${plan.holdSeconds}s hold', const Color(0xFFFF9F43))
                      else
                        _detailChip(Icons.loop_rounded, '${plan.reps} Reps', const Color(0xFFFF9F43)),
                      _detailChip(Icons.hourglass_top_rounded, '${plan.restSeconds}s rest', const Color(0xFF64B5F6)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (primaryLabels.isNotEmpty) ...[
                    _detailSection('Primary muscles', primaryLabels, Icons.flash_on_rounded, _accent),
                    const SizedBox(height: 12),
                  ],
                  if (secondaryLabels.isNotEmpty) ...[
                    _detailSection('Secondary muscles', secondaryLabels, Icons.blur_circular_rounded, const Color(0xFF64B5F6)),
                    const SizedBox(height: 20),
                  ],
                  // Start workout — navigates to WorkoutSessionView with full day plan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchWorkoutSession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navSelected,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Start Workout',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build WorkoutExercise list from the current day plan and navigate.
  void _launchWorkoutSession() {
    final dayPlan = _weeklyPlan[_selectedDay] ?? {};
    final exerciseById = {for (final e in _exercises) e.id: e};

    final workoutList = dayPlan.entries
        .map((entry) {
          final ex = exerciseById[entry.key];
          if (ex == null) return null;
          final plan = entry.value;
          return WorkoutExercise(
            id: ex.id,
            name: ex.name,
            level: ex.level,
            equipment: ex.equipment,
            primaryMuscles: ex.primaryMuscles,
            secondaryMuscles: ex.secondaryMuscles,
            sets: plan.sets,
            reps: plan.reps,
            isHold: plan.isHold,
            holdSeconds: plan.holdSeconds,
            restSeconds: plan.restSeconds,
          );
        })
        .whereType<WorkoutExercise>()
        .toList();

    if (workoutList.isEmpty || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutSessionView(
          exercises: workoutList,
          dayName: _days[_selectedDay],
        ),
      ),
    );
  }


  Widget _detailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search calisthenics exercises',
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontFamily: 'Poppins',
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: _accent),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMuscleFilterButton(),
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearExerciseSearch,
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              IconButton(
                tooltip: 'Search',
                onPressed: _submitExerciseSearch,
                icon: const Icon(Icons.search_rounded, color: _accent),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
      onSubmitted: _submitExerciseSearch,
    );
  }

  Widget _buildMuscleFilters() {
    final selectedLabel = _muscleFilter == null
        ? 'All'
        : _muscleLabel(_muscleFilter!);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Filter: $selectedLabel',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleFilterButton() {
    final selectedLabel = _muscleFilter == null
        ? 'All'
        : _muscleLabel(_muscleFilter!);

    return PopupMenuButton<String?>(
      tooltip: 'Choose muscle filter',
      initialValue: _muscleFilter,
      onSelected: (muscleId) {
        setState(() {
          _muscleFilter = muscleId;
        });
        _submitExerciseSearch();
      },
      color: const Color(0xFF1E1E1E),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: _filterMenuItem('All', _muscleFilter == null),
        ),
        ..._muscles.map(
          (muscle) => PopupMenuItem<String?>(
            value: muscle.id,
            child: _filterMenuItem(muscle.label, _muscleFilter == muscle.id),
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.42)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, color: _accent, size: 18),
            const SizedBox(width: 6),
            Text(
              selectedLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterMenuItem(String label, bool selected) {
    return Row(
      children: [
        Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: selected ? _accent : Colors.white54,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedExercises(List<CalisthenicsExercise> exercises) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected exercises',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final exercise in exercises) ...[
                InputChip(
                  label: Text(
                    '${exercise.name} - ${_plannedLabel(exercise.id)}',
                  ),
                  onPressed: () => _editPlannedExercise(exercise.id),
                  onDeleted: () => _removeExercise(exercise.id),
                  deleteIconColor: Colors.white70,
                  backgroundColor: _navSelected,
                  side: const BorderSide(color: _accent),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile(CalisthenicsExercise exercise, bool selected) {
    final muscleLabels = exercise.primaryMuscles
        .map(_muscleLabel)
        .where((label) => label.isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? _navSelected.withValues(alpha: 0.45) : Colors.black26,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? _accent : Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: selected ? 0.24 : 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            selected ? Icons.check_rounded : Icons.add_rounded,
            color: selected ? Colors.white : _accent,
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${exercise.level} - $muscleLabels',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        trailing: IconButton(
          tooltip: selected ? 'Modify sets and reps' : 'Add to day',
          onPressed: () => selected
              ? _editPlannedExercise(exercise.id)
              : _addExercise(exercise.id),
          icon: Icon(
            selected ? Icons.edit_rounded : Icons.add_circle_rounded,
            color: selected ? Colors.white : _accent,
          ),
        ),
        onTap: () => selected
            ? _editPlannedExercise(exercise.id)
            : _addExercise(exercise.id),
      ),
    );
  }

  Widget _buildWeeklyBreakdown(Map<String, int> frequency) {
    final active =
        _muscles.where((muscle) => (frequency[muscle.id] ?? 0) > 0).toList()
          ..sort(
            (a, b) => (frequency[b.id] ?? 0).compareTo(frequency[a.id] ?? 0),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(hasShadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          if (active.isEmpty)
            Text(
              'No muscle groups selected yet.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            )
          else
            for (final muscle in active)
              _frequencyRow(muscle, frequency[muscle.id] ?? 0),
        ],
      ),
    );
  }

  Widget _frequencyRow(_MuscleOption muscle, int count) {
    final color = _heatColor(count);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(muscle.icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              muscle.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            count >= 4 ? '4+ times' : '$count time${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(hasShadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title - $unit',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white12),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  String _plannedLabel(String exerciseId) {
    final planned = _weeklyPlan[_selectedDay]?[exerciseId];
    if (planned == null) return '3 x 10';
    if (planned.isHold) return '${planned.sets} x ${planned.holdSeconds}s';
    return '${planned.sets} x ${planned.reps}';
  }

  Future<void> _addExercise(String exerciseId) async {
    setState(() {
      final exercises =
          _weeklyPlan[_selectedDay] ?? <String, PlannedExercise>{};
      exercises[exerciseId] = PlannedExercise(exerciseId: exerciseId);
      _weeklyPlan[_selectedDay] = exercises;
      _invalidateSvgCache();
    });
    await _saveWeeklyPlan();
  }

  Future<void> _removeExercise(String exerciseId) async {
    setState(() {
      _weeklyPlan[_selectedDay]?.remove(exerciseId);
      _invalidateSvgCache();
    });
    await _saveWeeklyPlan();
  }

  Future<void> _editPlannedExercise(String exerciseId) async {
    final current =
        _weeklyPlan[_selectedDay]?[exerciseId] ??
        PlannedExercise(exerciseId: exerciseId);
    final setsCtrl = TextEditingController(text: '${current.sets}');
    final repsCtrl = TextEditingController(text: '${current.reps}');
    final holdCtrl = TextEditingController(text: '${current.holdSeconds}');
    final restCtrl = TextEditingController(text: '${current.restSeconds}');

    final result = await showDialog<PlannedExercise>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            bool isHold = current.isHold;
            return AlertDialog(
              backgroundColor: const Color(0xFF171717),
              title: const Text(
                'Configure exercise',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hold toggle
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Hold exercise (seconds)',
                            style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
                        ),
                        Switch(
                          value: isHold,
                          activeThumbColor: _accent,
                          onChanged: (v) => setDlg(() => isHold = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Sets row
                    Row(
                      children: [
                        Expanded(child: _numberField('Sets', setsCtrl)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isHold
                              ? _numberField('Hold (s)', holdCtrl)
                              : _numberField('Reps', repsCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rest between sets
                    _numberField('Rest between sets (s)', restCtrl),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _accent),
                  onPressed: () {
                    final sets = (int.tryParse(setsCtrl.text) ?? current.sets).clamp(1, 99);
                    final reps = (int.tryParse(repsCtrl.text) ?? current.reps).clamp(1, 999);
                    final hold = (int.tryParse(holdCtrl.text) ?? current.holdSeconds).clamp(5, 600);
                    final rest = (int.tryParse(restCtrl.text) ?? current.restSeconds).clamp(0, 600);
                    Navigator.pop(ctx, PlannedExercise(
                      exerciseId: exerciseId,
                      sets: sets,
                      reps: reps,
                      isHold: isHold,
                      holdSeconds: hold,
                      restSeconds: rest,
                    ));
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    setsCtrl.dispose();
    repsCtrl.dispose();
    holdCtrl.dispose();
    restCtrl.dispose();

    if (result == null || !mounted) return;
    setState(() {
      final exercises = _weeklyPlan[_selectedDay] ?? <String, PlannedExercise>{};
      exercises[exerciseId] = result;
      _weeklyPlan[_selectedDay] = exercises;
    });
    await _saveWeeklyPlan();
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _accent),
        ),
      ),
    );
  }

  Future<void> _clearWeek() async {
    setState(() {
      for (final entry in _weeklyPlan.entries) {
        entry.value.clear();
      }
      _invalidateSvgCache();
    });
    await _saveWeeklyPlan();
  }

  // ── Performance cache helpers ───────────────────────────────

  /// Clears all caches; call whenever _weeklyPlan or _exercises changes.
  void _invalidateSvgCache() {
    _cachedFrequency = {};
    _svgCacheKey = '';
    _cachedPaintedSvgFuture = null;
  }

  /// Returns cached muscle frequency map, rebuilding only when invalidated.
  Map<String, int> _getFrequency() {
    if (_cachedFrequency.isNotEmpty) return _cachedFrequency;
    final frequency = {for (final muscle in _muscles) muscle.id: 0};
    for (final plannedExercises in _weeklyPlan.values) {
      final musclesForDay = <String>{};
      for (final planned in plannedExercises.values) {
        final exercise = _exerciseById[planned.exerciseId];
        if (exercise == null) continue;
        musclesForDay.addAll(exercise.primaryMuscles);
        musclesForDay.addAll(exercise.secondaryMuscles);
      }
      for (final muscle in musclesForDay) {
        if (frequency.containsKey(muscle)) {
          frequency[muscle] = (frequency[muscle] ?? 0) + 1;
        }
      }
    }
    _cachedFrequency = frequency;
    return frequency;
  }

  /// Returns a Future resolving to the painted SVG, repainting asynchronously via isolate only when frequency has changed.
  Future<String> _getCachedPaintedSvgFuture(String rawSvg, Map<String, int> frequency) {
    final key = frequency.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    
    if (_svgCacheKey == key && _cachedPaintedSvgFuture != null) {
      return _cachedPaintedSvgFuture!;
    }
    
    _svgCacheKey = key;
    // Offload the heavy Regex parsing and string replacement to an isolate
    _cachedPaintedSvgFuture = compute(
      _paintSvgIsolate,
      _PaintIsolateData(svg: rawSvg, frequency: frequency),
    );
    
    return _cachedPaintedSvgFuture!;
  }
  List<CalisthenicsExercise> get _filteredExercises {
    return _exercises.where((exercise) {
      final matchesQuery =
          _query.isEmpty ||
          exercise.name.toLowerCase().contains(_query) ||
          exercise.level.toLowerCase().contains(_query) ||
          exercise.equipment.toLowerCase().contains(_query);
      final matchesMuscle =
          _muscleFilter == null || exercise.allMuscles.contains(_muscleFilter);
      return matchesQuery && matchesMuscle;
    }).toList();
  }

  String _muscleLabel(String id) {
    for (final muscle in _muscles) {
      if (muscle.id == id) return muscle.label;
    }
    return id;
  }

  Color _heatColor(int count) {
    if (count <= 0) return const Color(0xFF6D6D6D);
    if (count == 1) return const Color.fromARGB(255, 248, 103, 103);
    if (count == 2) return const Color.fromARGB(255, 244, 91, 60);
    if (count == 3) return const Color.fromARGB(210, 240, 36, 36);
    return const Color.fromARGB(255, 245, 19, 19);
  }

  BoxDecoration _cardDecoration({bool hasShadow = true}) => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white10),
    boxShadow: hasShadow ? _cardShadow : null,
  );
}

// ── Background Isolate helpers ──────────────────────────────────────────────

class _PaintIsolateData {
  const _PaintIsolateData({required this.svg, required this.frequency});
  final String svg;
  final Map<String, int> frequency;
}

String _paintSvgIsolate(_PaintIsolateData data) {
  var painted = data.svg;
  final targetCounts = <String, int>{};

  for (final muscle in _ScheduleViewState._muscles) {
    final count = data.frequency[muscle.id] ?? 0;
    if (count <= 0) continue;

    final svgGroups = _ScheduleViewState._svgGroupAliases[muscle.id] ?? [muscle.id];
    for (final groupId in svgGroups) {
      final previous = targetCounts[groupId] ?? 0;
      if (count > previous) targetCounts[groupId] = count;
    }
  }

  for (final entry in targetCounts.entries) {
    final groupId = entry.key;
    final color = _hexColorIsolate(_heatColorIsolate(entry.value));
    final opacity = '1'; // heatOpacity logic is constant '1'
    painted = _paintSvgGroupByIdIsolate(painted, groupId, color, opacity);

    final pathPattern = RegExp(
      '(<path\\s+[^>]*id="${RegExp.escape(groupId)}"[^>]*/>)',
    );

    painted = painted.replaceAllMapped(pathPattern, (match) {
      return _paintSvgColorIsolate(match.group(1) ?? '', color, opacity);
    });
  }

  return painted;
}

String _paintSvgGroupByIdIsolate(String svg, String groupId, String color, String opacity) {
  final startPattern = RegExp('<g\\s+id="${RegExp.escape(groupId)}"[^>]*>');
  var searchFrom = 0;
  var painted = svg;

  while (true) {
    final match = startPattern.firstMatch(painted.substring(searchFrom));
    if (match == null) return painted;

    final start = searchFrom + match.start;
    final openEnd = searchFrom + match.end;
    var depth = 1;
    var cursor = openEnd;

    while (depth > 0) {
      final nextOpen = painted.indexOf('<g', cursor);
      final nextClose = painted.indexOf('</g>', cursor);
      if (nextClose == -1) return painted;

      if (nextOpen != -1 && nextOpen < nextClose) {
        depth++;
        cursor = nextOpen + 2;
      } else {
        depth--;
        cursor = nextClose + 4;
      }
    }

    final original = painted.substring(start, cursor);
    final colored = _paintSvgColorIsolate(original, color, opacity);
    painted = painted.replaceRange(start, cursor, colored);
    searchFrom = start + colored.length;
  }
}

String _paintSvgColorIsolate(String svg, String color, String opacity) {
  return svg
      .replaceAll(
        RegExp('fill="#[0-9A-Fa-f]{6}"'),
        'fill="$color" fill-opacity="$opacity"',
      )
      .replaceAll(
        RegExp('stroke="#[0-9A-Fa-f]{6}"'),
        'stroke="$color" stroke-opacity="$opacity"',
      );
}

Color _heatColorIsolate(int count) {
  if (count <= 0) return const Color(0xFF6D6D6D);
  if (count == 1) return const Color.fromARGB(255, 248, 103, 103);
  if (count == 2) return const Color.fromARGB(255, 244, 91, 60);
  if (count == 3) return const Color.fromARGB(210, 240, 36, 36);
  return const Color.fromARGB(255, 245, 19, 19);
}

String _hexColorIsolate(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
class _MuscleOption {
  const _MuscleOption(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}
