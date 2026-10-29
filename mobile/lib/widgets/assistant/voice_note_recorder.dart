import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../l10n/app_localizations.dart';
import '../../services/log_service.dart';
import '../../theme/sure_tokens.dart';
import '../ledger/ledger.dart';

/// Hold: recording lasts while the mic is pressed. Tap: one tap starts, the
/// next one sends.
enum VoiceNoteMode { hold, tap }

enum VoiceNoteStart { started, denied, failed }

class VoiceNoteClip {
  const VoiceNoteClip({required this.bytes, required this.durationMs});

  final Uint8List bytes;
  final int durationMs;
}

/// Records 16 kHz mono WAV voice notes to a temp file, capped at
/// [maxDuration]. Finished clips go to [onClip]; clips under [minDuration]
/// are dropped and reported through [onTooShort].
class VoiceNoteRecorder extends ChangeNotifier {
  VoiceNoteRecorder({
    required this.onClip,
    required this.onTooShort,
    AudioRecorder? recorder,
  }) : _recorder = recorder ?? AudioRecorder();

  static const maxDuration = Duration(minutes: 2);
  static const minDuration = Duration(milliseconds: 700);

  static const _config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  );

  final void Function(VoiceNoteClip clip) onClip;
  final VoidCallback onTooShort;
  final AudioRecorder _recorder;

  VoiceNoteMode? _mode;
  DateTime? _startedAt;
  String? _path;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _cancelArmed = false;

  /// Bumped whenever a recording ends, so a start still awaiting permission or
  /// the platform recorder knows it was released in the meantime.
  int _session = 0;

  /// Starting or recording.
  bool get isActive => _mode != null;
  bool get isRecording => _startedAt != null;
  VoiceNoteMode? get mode => _mode;
  Duration get elapsed => _elapsed;

  /// Hold mode: the finger slid away, so releasing discards the clip.
  bool get cancelArmed => _cancelArmed;

  set cancelArmed(bool value) {
    if (value == _cancelArmed || _mode != VoiceNoteMode.hold) return;
    _cancelArmed = value;
    notifyListeners();
  }

  Future<VoiceNoteStart> start(VoiceNoteMode mode) async {
    if (_mode != null) return VoiceNoteStart.started;
    final session = _session;
    _mode = mode;
    notifyListeners();

    try {
      if (!await _recorder.hasPermission()) {
        if (session == _session) _reset();
        return VoiceNoteStart.denied;
      }
      if (session != _session) return VoiceNoteStart.started;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(_config, path: path);
      if (session != _session) {
        await _recorder.cancel();
        return VoiceNoteStart.started;
      }

      _path = path;
      _startedAt = DateTime.now();
      _ticker =
          Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
      notifyListeners();
      return VoiceNoteStart.started;
    } catch (e) {
      LogService.instance
          .warning('VoiceNoteRecorder', 'start failed: ${e.runtimeType}');
      if (session == _session) _reset();
      return VoiceNoteStart.failed;
    }
  }

  void _tick() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _elapsed = DateTime.now().difference(startedAt);
    if (_elapsed >= maxDuration) {
      unawaited(finish());
    } else {
      notifyListeners();
    }
  }

  /// Stops and delivers the clip (or reports it as too short).
  Future<void> finish() async {
    if (_mode == null) return;
    final startedAt = _startedAt;
    final path = _path;
    _reset();

    final duration = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
    if (startedAt == null || duration < minDuration) {
      if (startedAt != null) await _safely(_recorder.cancel);
      onTooShort();
      return;
    }

    try {
      final stoppedPath = await _recorder.stop() ?? path;
      if (stoppedPath == null) return;
      final file = File(stoppedPath);
      final bytes = await file.readAsBytes();
      unawaited(file.delete().then((_) {}, onError: (_) {}));
      final capped = duration > maxDuration ? maxDuration : duration;
      onClip(VoiceNoteClip(bytes: bytes, durationMs: capped.inMilliseconds));
    } catch (e) {
      LogService.instance
          .warning('VoiceNoteRecorder', 'stop failed: ${e.runtimeType}');
    }
  }

  /// Discards the current recording.
  Future<void> cancel() async {
    if (_mode == null) return;
    final wasRecording = _startedAt != null;
    _reset();
    if (wasRecording) await _safely(_recorder.cancel);
  }

  Future<void> _safely(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {}
  }

  void _reset() {
    _session++;
    _ticker?.cancel();
    _ticker = null;
    _mode = null;
    _startedAt = null;
    _path = null;
    _elapsed = Duration.zero;
    _cancelArmed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_startedAt != null) unawaited(_safely(_recorder.cancel));
    unawaited(_recorder.dispose());
    super.dispose();
  }
}

String _clock(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Composer mic: long-press records while held (slide away to cancel), a tap
/// starts and a second tap sends.
class VoiceNoteMicButton extends StatelessWidget {
  const VoiceNoteMicButton({
    super.key,
    required this.recorder,
    required this.enabled,
  });

  final VoiceNoteRecorder recorder;
  final bool enabled;

  static const _cancelDistance = 64.0;

  Future<void> _start(BuildContext context, VoiceNoteMode mode) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final result = await recorder.start(mode);
    if (result == VoiceNoteStart.started) return;
    messenger.showSnackBar(SnackBar(
      content: Text(result == VoiceNoteStart.denied
          ? l.assistantMicPermissionDenied
          : l.assistantMicFailed),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final active = recorder.isActive;
    final usable = enabled || active;

    return Semantics(
      button: true,
      enabled: usable,
      label: l.assistantMicTooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: l.assistantMicTooltip,
        child: GestureDetector(
          key: const ValueKey('assistant-mic'),
          behavior: HitTestBehavior.opaque,
          onTap: !usable
              ? null
              : () {
                  if (!active) {
                    _start(context, VoiceNoteMode.tap);
                  } else if (recorder.mode == VoiceNoteMode.tap) {
                    recorder.finish();
                  }
                },
          // Keep the long-press callbacks set while recording: swapping them
          // to null mid-press drops the recognizer and the release is lost.
          onLongPressStart: !usable
              ? null
              : (_) {
                  if (!recorder.isActive) _start(context, VoiceNoteMode.hold);
                },
          onLongPressMoveUpdate: (details) => recorder.cancelArmed =
              details.offsetFromOrigin.distance > _cancelDistance,
          onLongPressEnd: (_) {
            if (recorder.mode != VoiceNoteMode.hold) return;
            recorder.cancelArmed ? recorder.cancel() : recorder.finish();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active ? c.danger : (usable ? c.ink : c.track),
              borderRadius: BorderRadius.circular(SureTokens.radiusMd),
            ),
            child: Icon(
              active && recorder.mode == VoiceNoteMode.tap
                  ? Icons.stop
                  : Icons.mic_none,
              color: usable ? c.onInk : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Replaces the text field while recording: timer, hint and (tap mode) a
/// cancel button.
class VoiceNoteRecordingBar extends StatelessWidget {
  const VoiceNoteRecordingBar({super.key, required this.recorder});

  final VoiceNoteRecorder recorder;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final elapsed = _clock(recorder.elapsed);
    final limit = _clock(VoiceNoteRecorder.maxDuration);
    final hint = recorder.mode == VoiceNoteMode.tap
        ? l.assistantRecordingTap
        : (recorder.cancelArmed
            ? l.assistantRecordingReleaseToCancel
            : l.assistantRecordingHold);

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: c.paper,
        border: Border.all(color: c.danger),
        borderRadius: BorderRadius.circular(SureTokens.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: l.assistantRecordingLabel(elapsed, limit),
            excludeSemantics: true,
            child: Text('$elapsed / $limit',
                style: LedgerText.figures(size: 14, color: c.ink)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LedgerText.body(
                size: 13,
                color: recorder.cancelArmed ? c.danger : c.muted,
              ),
            ),
          ),
          if (recorder.mode == VoiceNoteMode.tap)
            IconButton(
              key: const ValueKey('assistant-recording-cancel'),
              tooltip: l.assistantRecordingCancel,
              onPressed: recorder.cancel,
              icon: Icon(Icons.close, color: c.ink),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
