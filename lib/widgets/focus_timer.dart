import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_detox_master/supabase/focus_service.dart';
import 'package:digital_detox_master/providers/voice_coach_provider.dart';

/// A modern Pomodoro-style timer with focus/break cycles.
///
/// Features:
/// - Start/Pause/Reset controls
/// - Configurable durations
/// - Auto-advance through 4 cycles then long break
/// - Minimal, elegant visuals aligned with app theme
class FocusTimer extends StatefulWidget {
  final Duration focusDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;

  const FocusTimer({super.key, this.focusDuration = const Duration(minutes: 25), this.shortBreakDuration = const Duration(minutes: 5), this.longBreakDuration = const Duration(minutes: 15)});

  @override
  State<FocusTimer> createState() => _FocusTimerState();
}

enum _TimerPhase { focus, shortBreak, longBreak }

class _FocusTimerState extends State<FocusTimer> {
  late Duration _remaining;
  late _TimerPhase _phase;
  Timer? _timer;
  bool _running = false;
  int _completedFocusSessions = 0;

  int _cycleCount = 0; // after 4 focus sessions, trigger long break
  Timer? _midpointTimer;
    // Supabase focus session tracking
    String? _activeSessionId;
    DateTime? _activeSessionStart;

  @override
  void initState() {
    super.initState();
    _phase = _TimerPhase.focus;
    _remaining = widget.focusDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _midpointTimer?.cancel();
    super.dispose();
  }

  Duration get _phaseTotal => _phase == _TimerPhase.focus
      ? widget.focusDuration
      : _phase == _TimerPhase.shortBreak
          ? widget.shortBreakDuration
          : widget.longBreakDuration;

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    // Voice: announce phase start
    final vc = context.read<VoiceCoachProvider>();
    if (_phase == _TimerPhase.focus) {
      // Only speak if enabled; provider guards inside
      unawaited(vc.onFocusStart());
      // Begin a Supabase focus session when a focus phase starts
      _activeSessionStart = DateTime.now();
      _beginSupabaseFocusSession();
    } else if (_phase == _TimerPhase.shortBreak) {
      unawaited(vc.onBreakStart());
    } else {
      unawaited(vc.onLongBreakStart());
    }

    // Schedule midpoint check-in
    _midpointTimer?.cancel();
    final mid = Duration(seconds: (_remaining.inSeconds ~/ 2).clamp(1, _remaining.inSeconds));
    _midpointTimer = Timer(mid, () {
      if (!mounted) return;
      if (_running) {
        unawaited(vc.onMidpointCheckIn());
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          _running = false;
          _advancePhase();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    _midpointTimer?.cancel();
    setState(() {
      _running = false;
      _phase = _TimerPhase.focus;
      _remaining = widget.focusDuration;
      _cycleCount = 0;
      _activeSessionId = null;
      _activeSessionStart = null;
    });
  }

  void _advancePhase() {
    if (_phase == _TimerPhase.focus) {
      _completedFocusSessions++;
      _cycleCount++;
      // Voice: focus session complete
      unawaited(context.read<VoiceCoachProvider>().onSessionComplete());
      // Complete Supabase focus session if present
      _completeSupabaseFocusSession();
      if (_cycleCount >= 4) {
        _phase = _TimerPhase.longBreak;
        _cycleCount = 0;
        _remaining = widget.longBreakDuration;
      } else {
        _phase = _TimerPhase.shortBreak;
        _remaining = widget.shortBreakDuration;
      }
    } else {
      _phase = _TimerPhase.focus;
      _remaining = widget.focusDuration;
    }
  }

  String _phaseLabel(BuildContext context) {
    switch (_phase) {
      case _TimerPhase.focus:
        return 'Focus';
      case _TimerPhase.shortBreak:
        return 'Break';
      case _TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  Future<void> _beginSupabaseFocusSession() async {
    try {
      final id = await FocusService.startSession(
        plannedDurationMinutes: widget.focusDuration.inMinutes,
        sessionType: 'pomodoro',
        startTime: _activeSessionStart,
      );
      if (!mounted) return;
      setState(() => _activeSessionId = id);
    } catch (e) {
      // Best-effort only
    }
  }

  Future<void> _completeSupabaseFocusSession() async {
    try {
      // No-op if not started
      if (_activeSessionId == null || _activeSessionStart == null) return;
      await FocusService.completeSession(
        sessionId: _activeSessionId!,
        startTime: _activeSessionStart!,
      );
    } catch (e) {
      // ignore
    } finally {
      _activeSessionId = null;
      _activeSessionStart = null;
    }
  }

  double _progress() {
    final total = _phaseTotal.inSeconds;
    if (total == 0) return 0;
    return (_phaseTotal.inSeconds - _remaining.inSeconds) / total;
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _progress();
    final color = _phase == _TimerPhase.focus
        ? theme.colorScheme.primary
        : _phase == _TimerPhase.shortBreak
            ? theme.colorScheme.tertiary
            : theme.colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(_phaseLabel(context), style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_format(_remaining), style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Sessions: $_completedFocusSessions', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _running ? _pause : _start,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow, color: theme.colorScheme.onPrimary),
              label: Text(_running ? 'Pause' : 'Start'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DurationChips(
          focus: widget.focusDuration,
          shortBreak: widget.shortBreakDuration,
          longBreak: widget.longBreakDuration,
          onSelect: (phase, duration) {
            _timer?.cancel();
            setState(() {
              _running = false;
              _phase = phase;
              _remaining = duration;
            });
          },
        ),
      ],
    );
  }
}

class _DurationChips extends StatelessWidget {
  final Duration focus;
  final Duration shortBreak;
  final Duration longBreak;
  final void Function(_TimerPhase phase, Duration duration) onSelect;

  const _DurationChips({required this.focus, required this.shortBreak, required this.longBreak, required this.onSelect});

  String _minLabel(Duration d) => d.inMinutes.toString() + 'm';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('Focus ' + _minLabel(focus)),
          selected: false,
          onSelected: (_) => onSelect(_TimerPhase.focus, focus),
          labelStyle: theme.textTheme.labelLarge,
        ),
        ChoiceChip(
          label: Text('Break ' + _minLabel(shortBreak)),
          selected: false,
          onSelected: (_) => onSelect(_TimerPhase.shortBreak, shortBreak),
          labelStyle: theme.textTheme.labelLarge,
        ),
        ChoiceChip(
          label: Text('Long ' + _minLabel(longBreak)),
          selected: false,
          onSelected: (_) => onSelect(_TimerPhase.longBreak, longBreak),
          labelStyle: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}
