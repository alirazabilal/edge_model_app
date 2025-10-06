import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import 'result_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final record = AudioRecorder();
  bool isRecording = false;
  String transcription = '';

  DynamicLibrary? whisperLib;
  late Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
  whisperTranscribe;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);

    try {
      whisperLib = DynamicLibrary.open('libwhisper.so');
      whisperTranscribe = whisperLib!.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
              Pointer<Utf8>)>('whisper_transcribe');
    } catch (e) {
      setState(() {
        transcription = 'Error loading libwhisper.so: $e';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    copyAssetsToDocuments();
  }

  Future<void> copyAssetsToDocuments() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/ggml-tarteel-whisper-q4.bin';
      if (!await File(modelPath).exists()) {
        final data = await DefaultAssetBundle.of(context)
            .load('assets/ggml-tarteel-whisper-q4.bin');
        final bytes = data.buffer.asUint8List();
        await File(modelPath).writeAsBytes(bytes);
      }
    } catch (e) {
      setState(() {
        transcription = 'Error copying model: $e';
      });
    }
  }

  Future<String> getFilePath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  Future<void> startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        setState(() => isRecording = true);
        final wavPath = await getFilePath('recording.wav');
        await record.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: wavPath,
        );
      } else {
        setState(() {
          transcription = 'Microphone permission not granted';
        });
      }
    } catch (e) {
      setState(() {
        isRecording = false;
        transcription = 'Error starting recording: $e';
      });
    }
  }

  Future<void> stopRecording() async {
    try {
      setState(() => isRecording = false);
      final wavPath = await record.stop();
      if (wavPath != null) {
        final modelPath = await getFilePath('ggml-tarteel-whisper-q4.bin');
        final modelPathPtr = modelPath.toNativeUtf8();
        final wavPathPtr = wavPath.toNativeUtf8();
        final langPtr = 'ar'.toNativeUtf8();
        try {
          final resultPtr =
          whisperTranscribe(modelPathPtr, wavPathPtr, langPtr);
          final result = resultPtr.toDartString();
          malloc.free(resultPtr);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                result: result.isEmpty ? 'No transcription generated' : result,
              ),
            ),
          );
        } catch (e) {
          setState(() {
            transcription = 'Error during transcription: $e';
          });
        }
        malloc.free(modelPathPtr);
        malloc.free(wavPathPtr);
        malloc.free(langPtr);
      } else {
        setState(() {
          transcription = 'No recording file generated';
        });
      }
    } catch (e) {
      setState(() {
        transcription = 'Error stopping recording: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "🎙️ Voice Recorder",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isRecording)
                          ScaleTransition(
                            scale: Tween(begin: 1.0, end: 1.3)
                                .animate(CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            )),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent.withOpacity(0.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.6),
                                    blurRadius: 40,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Icon(
                          isRecording ? Icons.mic : Icons.mic_none,
                          size: 120,
                          color: isRecording ? Colors.redAccent : Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transcription.isEmpty
                        ? "Tap the mic to start speaking..."
                        : transcription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: isRecording ? stopRecording : startRecording,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 45, vertical: 20),
                    backgroundColor:
                    isRecording ? Colors.redAccent : Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 12,
                    shadowColor: Colors.black54,
                  ),
                  icon: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: Text(
                    isRecording ? "Stop Recording" : "Start Recording",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (!isRecording && transcription.isNotEmpty)
                  const Text(
                    "Tap mic again to re-record",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
