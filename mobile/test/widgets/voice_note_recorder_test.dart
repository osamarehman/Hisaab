import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:sure_mobile/widgets/assistant/voice_note_recorder.dart';

/// Writes a fake WAV on start; cancel does not delete it, so the recorder's
/// own cleanup is what the tests observe.
class _FakeRecorder extends Fake implements AudioRecorder {
  String? path;
  RecordConfig? config;
  bool cancelled = false;

  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    this.config = config;
    this.path = path;
    await File(path).writeAsBytes([82, 73, 70, 70]);
  }

  @override
  Future<String?> stop() async => path;

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late _FakeRecorder fake;
  final clips = <VoiceNoteClip>[];
  var tooShort = 0;

  VoiceNoteRecorder build() => VoiceNoteRecorder(
        onClip: clips.add,
        onTooShort: () => tooShort++,
        recorder: fake,
        tempDirectory: () async => dir,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('voice_note_test');
    fake = _FakeRecorder();
    clips.clear();
    tooShort = 0;
  });

  tearDown(() => dir.delete(recursive: true));

  test('records 16 kHz mono WAV, delivers the clip and deletes the file',
      () async {
    final recorder = build();
    expect(await recorder.start(VoiceNoteMode.tap), VoiceNoteStart.started);
    expect(recorder.isRecording, isTrue);
    expect(fake.config!.encoder, AudioEncoder.wav);
    expect(fake.config!.sampleRate, 16000);
    expect(fake.config!.numChannels, 1);

    await Future<void>.delayed(const Duration(milliseconds: 800));
    await recorder.finish();

    expect(clips.single.bytes, [82, 73, 70, 70]);
    expect(clips.single.durationMs, greaterThanOrEqualTo(700));
    expect(File(fake.path!).existsSync(), isFalse);
    expect(recorder.isActive, isFalse);
    recorder.dispose();
  });

  test('too-short clip is dropped and its file deleted', () async {
    final recorder = build();
    await recorder.start(VoiceNoteMode.hold);
    await recorder.finish();

    expect(clips, isEmpty);
    expect(tooShort, 1);
    expect(fake.cancelled, isTrue);
    expect(File(fake.path!).existsSync(), isFalse);
    recorder.dispose();
  });

  test('going to the background while recording discards the clip', () async {
    final recorder = build();
    await recorder.start(VoiceNoteMode.tap);
    expect(recorder.isRecording, isTrue);

    recorder.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(recorder.isActive, isFalse);
    expect(fake.cancelled, isTrue);
    expect(clips, isEmpty);
    expect(File(fake.path!).existsSync(), isFalse);
    recorder.dispose();
  });
}
