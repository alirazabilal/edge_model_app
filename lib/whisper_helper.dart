import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class WhisperHelper {
  final _record = AudioRecorder();
  DynamicLibrary? _whisperLib;
  late Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
      _whisperTranscribe;

  WhisperHelper() {
    try {
      _whisperLib = DynamicLibrary.open('libwhisper.so');
      _whisperTranscribe = _whisperLib!.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>(
        'whisper_transcribe',
      );
    } catch (e) {
      print("❌ Error loading libwhisper.so: $e");
    }
  }

  Future<void> copyModelIfNeeded() async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/ggml-tarteel-whisper-q4.bin';
    if (!await File(modelPath).exists()) {
      final data = await rootBundle
          .load('assets/ggml-tarteel-whisper-q4.bin'); // ensure in pubspec.yaml
      final bytes = data.buffer.asUint8List();
      await File(modelPath).writeAsBytes(bytes);
      print("✅ Model copied to $modelPath");
    }
  }

  Future<String> _getFilePath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$filename';
  }

  /// ✅ Start recording
  Future<void> startRecording() async {
    final wavPath = await _getFilePath('recording.wav');
    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: wavPath,
    );
    print("🎙️ Recording started...");
  }

  /// ✅ Stop recording and transcribe
  Future<String?> stopAndTranscribe() async {
    final wavPath = await _record.stop();
    if (wavPath == null) return null;

    final modelPath = await _getFilePath('ggml-tarteel-whisper-q4.bin');
    final modelPathPtr = modelPath.toNativeUtf8();
    final wavPathPtr = wavPath.toNativeUtf8();
    final langPtr = 'ar'.toNativeUtf8();

    String? result;
    try {
      final resultPtr = _whisperTranscribe(modelPathPtr, wavPathPtr, langPtr);
      result = resultPtr.toDartString();
      malloc.free(resultPtr);
      print("✅ Transcription complete");
    } catch (e) {
      print("❌ Transcription error: $e");
    }

    malloc.free(modelPathPtr);
    malloc.free(wavPathPtr);
    malloc.free(langPtr);
    return result;
  }
}