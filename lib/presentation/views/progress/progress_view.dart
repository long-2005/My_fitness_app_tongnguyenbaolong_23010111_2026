import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/data/models/bmi_record.dart';
import 'package:flutter_application_1/data/models/workout_session_record.dart';
import 'package:flutter_application_1/data/repositories/bmi_repository.dart';
import 'package:flutter_application_1/data/repositories/workout_repository.dart';
import 'package:flutter_application_1/l10n/app_strings.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  static const _accent = Color(0xFFE16D6D);

  final _bmiService = BmiService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final s = AppStrings.of(context);

    if (widget.embedded) {
      if (user == null) {
        return _buildSignInPrompt(s);
      }
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkoutStatsSection(user, s),
            const SizedBox(height: 20),
            _buildWeightChart(s),
            const SizedBox(height: 20),
            _buildCalorieChart(user, s),
            const SizedBox(height: 20),
            _buildWorkoutHistory(s),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Text(
              s.progressTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                fontSize: 20,
              ),
            ),
          ),
          if (user == null)
            SliverFillRemaining(
              child: _buildSignInPrompt(s),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWorkoutStatsSection(user, s),
                  const SizedBox(height: 20),
                  _buildWeightChart(s),
                  const SizedBox(height: 20),
                  _buildCalorieChart(user, s),
                  const SizedBox(height: 20),
                  _buildWorkoutHistory(s),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sign-in prompt ─────────────────────────────────────────

  Widget _buildSignInPrompt(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded, color: _accent, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              s.signInToSeeProgress,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Workout Stats (streak + total sessions) ─────────────────

  Widget _buildWorkoutStatsSection(User user, AppStrings s) {
    final stream = WorkoutService.instance.getSessionsStream();
    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<List<WorkoutSessionRecord>>(
      stream: stream,
      builder: (context, snap) {
        final sessions = snap.data ?? [];
        final totalSessions = sessions.length;
        final streak = _calculateStreak(sessions);
        final thisWeekSessions =
            sessions.where((s) => s.completedAt.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            )).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: _accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  s.workoutHistory,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    color: _accent,
                    value: '$streak',
                    unit: s.daysLabel,
                    label: s.workoutStreak,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFFFF9F43),
                    value: '$totalSessions',
                    unit: s.sessionsLabel,
                    label: s.totalSessions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF64B5F6),
                    value: '$thisWeekSessions',
                    unit: s.sessionsLabel,
                    label: s.thisWeek,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins',
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ── Weight / BMI Chart ──────────────────────────────────────

  Widget _buildWeightChart(AppStrings s) {
    final stream = _bmiService.getRecordsStream();
    if (stream == null) {
      return _buildChartCard(
        title: s.weightProgress,
        icon: Icons.monitor_weight_rounded,
        color: const Color(0xFF64B5F6),
        child: _buildNoDataPlaceholder(s.noProgressData),
      );
    }

    return StreamBuilder<List<BmiRecord>>(
      stream: stream,
      builder: (context, snap) {
        final records = (snap.data ?? []).reversed.toList();

        return _buildChartCard(
          title: s.weightProgress,
          icon: Icons.monitor_weight_rounded,
          color: const Color(0xFF64B5F6),
          child: records.length < 2
              ? _buildNoDataPlaceholder(s.noProgressData)
              : Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: CustomPaint(
                        painter: _LineChartPainter(
                          values: records.map((r) => r.weight).toList(),
                          color: const Color(0xFF64B5F6),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChartLegendRow(records),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildChartLegendRow(List<BmiRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();
    final first = records.first;
    final last = records.last;
    final delta = last.weight - first.weight;
    final isGain = delta > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _legendItem('Start', '${first.weight} kg', Colors.white54),
        _legendItem(
          'Change',
          '${isGain ? '+' : ''}${delta.toStringAsFixed(1)} kg',
          isGain ? const Color(0xFFFF9F43) : Colors.greenAccent,
        ),
        _legendItem('Latest', '${last.weight} kg', const Color(0xFF64B5F6)),
      ],
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  // ── Calorie Chart (last 7 days) ─────────────────────────────

  Widget _buildCalorieChart(User user, AppStrings s) {
    return _buildChartCard(
      title: s.calorieWeek,
      icon: Icons.local_fire_department_rounded,
      color: _accent,
      child: _CalorieBarChart(uid: user.uid),
    );
  }

  // ── Workout History List ────────────────────────────────────

  Widget _buildWorkoutHistory(AppStrings s) {
    final stream = WorkoutService.instance.getSessionsStream();
    if (stream == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: _accent, size: 22),
            const SizedBox(width: 8),
            Text(
              s.workoutHistory,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<WorkoutSessionRecord>>(
          stream: stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _accent),
                ),
              );
            }
            final sessions = snap.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.fitness_center_outlined,
                      color: Colors.white24,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.noWorkoutHistory,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: sessions
                  .take(10)
                  .map((r) => _buildSessionCard(r))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(WorkoutSessionRecord record) {
    final date = record.completedAt;
    final dateStr =
        '${_p(date.day)}/${_p(date.month)}/${date.year}  ${_p(date.hour)}:${_p(date.minute)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E0D0D), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: _accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.dayName.isEmpty ? 'Workout' : '${record.dayName} Workout',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.exercises.length} exercises',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                record.formattedDuration,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildNoDataPlaceholder(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
      ),
    );
  }

  int _calculateStreak(List<WorkoutSessionRecord> sessions) {
    if (sessions.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 365; i++) {
      final dateStr =
          '${checkDate.year}-${_p(checkDate.month)}-${_p(checkDate.day)}';
      final hasSession = sessions.any((s) {
        final d = s.completedAt;
        return '${d.year}-${_p(d.month)}-${_p(d.day)}' == dateStr;
      });
      if (hasSession) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}

// ── Calorie Bar Chart (7 days) ──────────────────────────────

class _CalorieBarChart extends StatelessWidget {
  const _CalorieBarChart({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meal_entries')
          .where(
            'logged_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .snapshots(),
      builder: (context, snap) {
        // Group calories by day index (0 = 6 days ago, 6 = today)
        final dailyCalories = List<double>.filled(7, 0);
        for (final doc in snap.data?.docs ?? []) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['logged_at'];
          if (ts == null) continue;
          final date = (ts as Timestamp).toDate();
          final diff = DateTime(now.year, now.month, now.day)
              .difference(DateTime(date.year, date.month, date.day))
              .inDays;
          if (diff >= 0 && diff < 7) {
            dailyCalories[6 - diff] +=
                (data['calories'] as num?)?.toDouble() ?? 0;
          }
        }

        final maxCal =
            dailyCalories.reduce(math.max).clamp(100.0, double.infinity);

        final labels = List.generate(7, (i) {
          final d = start.add(Duration(days: i));
          return _dayLabel(d.weekday);
        });

        return Column(
          children: [
            SizedBox(
              height: 140,
              child: CustomPaint(
                painter: _BarChartPainter(
                  values: dailyCalories,
                  maxValue: maxCal,
                  color: const Color(0xFFE16D6D),
                  todayIndex: 6,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: labels
                  .map(
                    (l) => Text(
                      l,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  String _dayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(weekday - 1) % 7];
  }
}

// ── Custom Painters ─────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = (maxVal - minVal).clamp(0.5, double.infinity);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height -
          ((values[i] - minVal) / range) * size.height * 0.85 -
          size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots at each point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF0F0F0F)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height -
          ((values[i] - minVal) / range) * size.height * 0.85 -
          size.height * 0.05;
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.values != values;
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.maxValue,
    required this.color,
    required this.todayIndex,
  });
  final List<double> values;
  final double maxValue;
  final Color color;
  final int todayIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = values.length;
    final barWidth = size.width / barCount * 0.55;
    final gap = size.width / barCount;
    const topPadding = 10.0;
    const bottomPadding = 8.0;
    final availHeight = size.height - topPadding - bottomPadding;

    // Grid line
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - bottomPadding),
      Offset(size.width, size.height - bottomPadding),
      gridPaint,
    );

    for (int i = 0; i < barCount; i++) {
      final barHeight = values[i] / maxValue * availHeight;
      final left = gap * i + (gap - barWidth) / 2;
      final top = size.height - bottomPadding - barHeight;

      final isToday = i == todayIndex;
      final barColor = isToday ? color : color.withValues(alpha: 0.35);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      canvas.drawRRect(rect, Paint()..color = barColor);

      // Value label above bar
      if (values[i] > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: values[i] >= 1000
                ? '${(values[i] / 1000).toStringAsFixed(1)}k'
                : values[i].toStringAsFixed(0),
            style: TextStyle(
              color: isToday ? color : color.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(left + barWidth / 2 - tp.width / 2, top - tp.height - 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.values != values;
}
