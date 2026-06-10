import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_application_1/data/models/workout_exercise.dart';
import 'package:flutter_application_1/data/models/workout_session_record.dart';
import 'package:flutter_application_1/data/repositories/workout_repository.dart';

enum _Phase { intro, exercising, resting, done }

class WorkoutSessionView extends StatefulWidget {
  const WorkoutSessionView({
    super.key,
    required this.exercises,
    required this.dayName,
  });

  final List<WorkoutExercise> exercises;
  final String dayName;

  @override
  State<WorkoutSessionView> createState() => _WorkoutSessionViewState();
}

class _WorkoutSessionViewState extends State<WorkoutSessionView> {
  static const _accent = Color(0xFFE16D6D);
  static const _accentDeep = Color(0xFF8D1A1A);

  _Phase _phase = _Phase.intro;
  int _exerciseIndex = 0;
  int _currentSet = 1;
  int _setsCompleted = 0;

  int _holdCountdown = 0;
  int _holdTotal = 1;
  int _restCountdown = 60;
  int _restTotal = 60;

  Timer? _timer;
  VoidCallback? _afterRest;
  DateTime? _sessionStartTime;

  WorkoutExercise get _ex => widget.exercises[_exerciseIndex];
  bool get _isLastSet => _currentSet >= _ex.sets;
  bool get _isLastExercise => _exerciseIndex >= widget.exercises.length - 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Timer helpers ──────────────────────────────────────────

  void _startHoldTimer() {
    _timer?.cancel();
    _holdTotal = _ex.holdSeconds;
    _holdCountdown = _ex.holdSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _holdCountdown--);
      if (_holdCountdown <= 0) {
        _timer?.cancel();
        _onSetDone();
      }
    });
  }

  void _startRest(VoidCallback after) {
    _timer?.cancel();
    _afterRest = after;
    _restTotal = _ex.restSeconds;
    _restCountdown = _ex.restSeconds;
    setState(() => _phase = _Phase.resting);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _restCountdown--);
      if (_restCountdown <= 0) {
        _timer?.cancel();
        _fireAfterRest();
      }
    });
  }

  void _fireAfterRest() {
    final cb = _afterRest;
    _afterRest = null;
    cb?.call();
  }

  // ── Actions ────────────────────────────────────────────────

  void _startWorkout() {
    setState(() {
      _exerciseIndex = 0;
      _currentSet = 1;
      _setsCompleted = 0;
      _phase = _Phase.exercising;
      _sessionStartTime = DateTime.now();
    });
    if (_ex.isHold) _startHoldTimer();
  }

  void _onSetDone() {
    _timer?.cancel();
    setState(() => _setsCompleted++);

    if (_isLastSet) {
      if (_isLastExercise) {
        _finishWorkout();
      } else {
        _startRest(() {
          setState(() {
            _exerciseIndex++;
            _currentSet = 1;
            _phase = _Phase.exercising;
          });
          if (_ex.isHold) _startHoldTimer();
        });
      }
    } else {
      _startRest(() {
        setState(() {
          _currentSet++;
          _phase = _Phase.exercising;
        });
        if (_ex.isHold) _startHoldTimer();
      });
    }
  }

  void _skipRest() {
    _timer?.cancel();
    _fireAfterRest();
  }

  void _adjustRest(int delta) {
    setState(() => _restCountdown = (_restCountdown + delta).clamp(1, 600));
  }

  void _skipExercise() {
    _timer?.cancel();
    _afterRest = null;
    if (_isLastExercise) {
      _finishWorkout();
    } else {
      setState(() {
        _exerciseIndex++;
        _currentSet = 1;
        _phase = _Phase.exercising;
      });
      if (_ex.isHold) _startHoldTimer();
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    final now = DateTime.now();
    final start = _sessionStartTime ?? now;
    final durationSecs = now.difference(start).inSeconds;
    setState(() => _phase = _Phase.done);

    // Lưu buổi tập vào Firestore (fire-and-forget)
    final record = WorkoutSessionRecord(
      id: '',
      dayName: widget.dayName,
      exercises: widget.exercises
          .map(
            (e) => SessionExercise(
              name: e.name,
              sets: e.sets,
              reps: e.reps,
              isHold: e.isHold,
              holdSeconds: e.holdSeconds,
              primaryMuscles: e.primaryMuscles,
            ),
          )
          .toList(),
      totalSets: _setsCompleted,
      durationSeconds: durationSecs,
      completedAt: now,
    );
    WorkoutService.instance.saveSession(record);
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_phase) {
          _Phase.intro => _buildIntro(),
          _Phase.exercising => _buildExercising(),
          _Phase.resting => _buildResting(),
          _Phase.done => _buildDone(),
        },
      ),
    );
  }

  // ── Intro ──────────────────────────────────────────────────

  Widget _buildIntro() {
    return SafeArea(
      key: const ValueKey('intro'),
      child: Column(
        children: [
          _buildTopBar(widget.dayName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A0D0D), Color(0xFF1A1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: _accent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.exercises.length} exercises',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                          ),
                          Text(
                            '${widget.exercises.fold(0, (s, e) => s + e.sets)} sets total',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ex = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}', style: const TextStyle(color: _accent, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
                        ),
                        Text(
                          ex.isHold ? '${ex.sets}×${ex.holdSeconds}s' : '${ex.sets}×${ex.reps}',
                          style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _bigButton('Start Workout', Icons.play_arrow_rounded, _startWorkout),
          ),
        ],
      ),
    );
  }

  // ── Exercising ─────────────────────────────────────────────

  Widget _buildExercising() {
    return SafeArea(
      key: const ValueKey('exercising'),
      child: Column(
        children: [
          _buildTopBar(_ex.name),
          // Progress bar
          LinearProgressIndicator(
            value: (_exerciseIndex + (_currentSet - 1) / _ex.sets) / widget.exercises.length,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(_accent),
            minHeight: 3,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Set indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Set $_currentSet / ${_ex.sets}',
                        style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Exercise name
                    Text(
                      _ex.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_ex.level} • ${_ex.primaryMuscles.take(2).join(', ')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 40),
                    // Hold countdown OR reps display
                    if (_ex.isHold)
                      _buildCircleTimer(_holdCountdown, _holdTotal, _accent)
                    else
                      Column(
                        children: [
                          Text(
                            '× ${_ex.reps}',
                            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
                          ),
                          Text('reps', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontFamily: 'Poppins')),
                        ],
                      ),
                    const SizedBox(height: 40),
                    if (!_ex.isHold)
                      _bigButton('Done Set', Icons.check_rounded, _onSetDone),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _skipExercise,
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white54),
                      label: const Text('Skip exercise', style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resting ────────────────────────────────────────────────

  Widget _buildResting() {
    final next = _isLastSet && !_isLastExercise
        ? widget.exercises[_exerciseIndex + 1].name
        : null;

    return SafeArea(
      key: const ValueKey('resting'),
      child: Column(
        children: [
          _buildTopBar('Rest'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (next != null) ...[
                      Text('Next up', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text(next,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 32),
                    ],
                    _buildCircleTimer(_restCountdown, _restTotal, const Color(0xFF64B5F6)),
                    const SizedBox(height: 40),
                    // Three-button row
                    Row(
                      children: [
                        Expanded(child: _adjustButton('-30s', () => _adjustRest(-30))),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _bigButton('Skip Rest', Icons.fast_forward_rounded, _skipRest, color: const Color(0xFF64B5F6)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _adjustButton('+30s', () => _adjustRest(30))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _skipExercise,
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white38),
                      label: const Text('Skip exercise', style: TextStyle(color: Colors.white38, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Done ───────────────────────────────────────────────────

  Widget _buildDone() {
    return SafeArea(
      key: const ValueKey('done'),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF521313), _accentDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 30)],
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              const Text('Workout Complete!',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Text(
                '$_setsCompleted sets across ${widget.exercises.length} exercises',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 40),
              _bigButton('Finish', Icons.check_circle_rounded, () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────

  Widget _buildTopBar(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      color: const Color(0xFF0F0F0F),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCircleTimer(int seconds, int total, Color color) {
    final progress = total > 0 ? seconds / total : 0.0;
    return SizedBox(
      width: 180, height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(180, 180),
            painter: _ArcPainter(progress: progress.clamp(0.0, 1.0), color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$seconds',
                style: TextStyle(color: color, fontSize: 52, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
              ),
              Text('seconds', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13, fontFamily: 'Poppins')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigButton(String label, IconData icon, VoidCallback onTap, {Color? color}) {
    final c = color ?? _accent;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color == null ? _accentDeep : c.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: color != null ? BorderSide(color: c) : null,
        ),
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
      ),
    );
  }

  Widget _adjustButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
    );
  }
}

// ── Arc painter ────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke);

    // Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress || old.color != color;
}
