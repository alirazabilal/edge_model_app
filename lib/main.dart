// main.dart
import 'package:flutter/material.dart';

// Your existing auth UIs:
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

// ===== Recording / Transcription deps =====
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Recitation Checker',
      theme: ThemeData(primarySwatch: Colors.green),
      // Start on Login
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/recording': (_) => const RecordingScreen(),
      },
    );
  }
}

/// Simple wrapper page that hosts the recorder/transcriber widget.
class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Whisper Transcription')),
      body: TranscriptionWidget(),
    );
  }
}

// =============== Transcription implementation ===============

class TranscriptionWidget extends StatefulWidget {
  const TranscriptionWidget({super.key});
  @override
  State<TranscriptionWidget> createState() => _TranscriptionWidgetState();
}

class _TranscriptionWidgetState extends State<TranscriptionWidget> {
  final record = AudioRecorder();
  String transcription = '';
  bool isRecording = false;

  DynamicLibrary? whisperLib;
  late Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
  whisperTranscribe;

  @override
  void initState() {
    super.initState();
    // Load libwhisper.so from jniLibs
    try {
      whisperLib = DynamicLibrary.open('libwhisper.so');
      whisperTranscribe = whisperLib!.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
              Pointer<Utf8>)>('whisper_transcribe');
    } catch (e) {
      setState(() => transcription = 'Error loading libwhisper.so: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _copyModelToDocuments();
  }

  Future<void> _copyModelToDocuments() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelPath = '${dir.path}/ggml-tarteel-whisper-q4.bin';
      if (!await File(modelPath).exists()) {
        final data = await DefaultAssetBundle.of(context)
            .load('assets/ggml-tarteel-whisper-q4.bin');
        await File(modelPath).writeAsBytes(
          data.buffer.asUint8List(),
          flush: true,
        );
      }
    } catch (e) {
      setState(() => transcription = 'Error copying model: $e');
    }
  }

  Future<String> _pathInDocs(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$filename';
  }

  Future<void> _startRecording() async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        setState(() => transcription = 'Microphone permission not granted');
        return;
      }
      setState(() => isRecording = true);
      final wavPath = await _pathInDocs('recording.wav');
      await record.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: wavPath,
      );
    } catch (e) {
      setState(() {
        isRecording = false;
        transcription = 'Error starting recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() => isRecording = false);
      final wavPath = await record.stop();
      if (wavPath == null) {
        setState(() => transcription = 'No recording file generated');
        return;
      }

      final modelPath = await _pathInDocs('ggml-tarteel-whisper-q4.bin');
      final modelPtr = modelPath.toNativeUtf8();
      final wavPtr = wavPath.toNativeUtf8();
      final langPtr = 'ar'.toNativeUtf8();

      try {
        final resPtr = whisperTranscribe(modelPtr, wavPtr, langPtr);
        final res = resPtr.toDartString();
        setState(() => transcription = res.isEmpty ? 'No transcription generated' : res);
        malloc.free(resPtr); // Only valid if the native side allocated with malloc
      } catch (e) {
        setState(() => transcription = 'Error during transcription: $e');
      } finally {
        malloc.free(modelPtr);
        malloc.free(wavPtr);
        malloc.free(langPtr);
      }
    } catch (e) {
      setState(() => transcription = 'Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(transcription.isEmpty ? 'No transcription yet' : transcription),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isRecording ? _stopRecording : _startRecording,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}















































//
// import 'dart:ffi';
// import 'dart:io';
// import 'package:ffi/ffi.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Whisper Transcription')),
//         body: const TranscriptionWidget(),
//       ),
//     );
//   }
// }
//
// // ignore: library_private_types_in_public_api
// class TranscriptionWidget extends StatefulWidget {
//   const TranscriptionWidget({super.key});
//
//   @override
//   _TranscriptionWidgetState createState() => _TranscriptionWidgetState();
// }
//
// class _TranscriptionWidgetState extends State<TranscriptionWidget> {
//   final record = AudioRecorder();
//   String transcription = '';
//   bool isRecording = false;
//   DynamicLibrary? whisperLib;
//   late Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) whisperTranscribe;
//
//   @override
//   void initState() {
//     super.initState();
//     // Load libwhisper.so
//     try {
//       whisperLib = DynamicLibrary.open('libwhisper.so');
//       whisperTranscribe = whisperLib!.lookupFunction<
//           Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
//           Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>('whisper_transcribe');
//     } catch (e) {
//       setState(() => transcription = 'Error loading libwhisper.so: $e');
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     copyAssetsToDocuments();
//   }
//
//   // ignore: use_build_context_synchronously
//   Future<void> copyAssetsToDocuments() async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final modelPath = '${directory.path}/ggml-tarteel-whisper-q4.bin';
//       if (!await File(modelPath).exists()) {
//         final data = await DefaultAssetBundle.of(context).load('assets/ggml-tarteel-whisper-q4.bin');
//         final bytes = data.buffer.asUint8List();
//         await File(modelPath).writeAsBytes(bytes);
//       }
//     } catch (e) {
//       setState(() => transcription = 'Error copying model: $e');
//     }
//   }
//
//   Future<String> getFilePath(String filename) async {
//     final directory = await getApplicationDocumentsDirectory();
//     return '${directory.path}/$filename';
//   }
//
//   Future<void> startRecording() async {
//     try {
//       if (await Permission.microphone.request().isGranted) {
//         setState(() => isRecording = true);
//         final wavPath = await getFilePath('recording.wav');
//         await record.start(
//           const RecordConfig(
//             encoder: AudioEncoder.wav,
//             sampleRate: 16000,
//             numChannels: 1,
//           ),
//           path: wavPath,
//         );
//       } else {
//         setState(() => transcription = 'Microphone permission not granted');
//       }
//     } catch (e) {
//       setState(() {
//         isRecording = false;
//         transcription = 'Error starting recording: $e';
//       });
//     }
//   }
//
//   Future<void> stopRecording() async {
//     try {
//       setState(() => isRecording = false);
//       final wavPath = await record.stop();
//       if (wavPath != null) {
//         final modelPath = await getFilePath('ggml-tarteel-whisper-q4.bin');
//         final modelPathPtr = modelPath.toNativeUtf8();
//         final wavPathPtr = wavPath.toNativeUtf8();
//         final langPtr = 'ar'.toNativeUtf8();
//         try {
//           final resultPtr = whisperTranscribe(modelPathPtr, wavPathPtr, langPtr);
//           final result = resultPtr.toDartString();
//           setState(() => transcription = result.isEmpty ? 'No transcription generated' : result);
//           malloc.free(resultPtr);
//         } catch (e) {
//           setState(() => transcription = 'Error during transcription: $e');
//         }
//         malloc.free(modelPathPtr);
//         malloc.free(wavPathPtr);
//         malloc.free(langPtr);
//       } else {
//         setState(() => transcription = 'No recording file generated');
//       }
//     } catch (e) {
//       setState(() => transcription = 'Error stopping recording: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(transcription.isEmpty ? 'No transcription yet' : transcription),
//           ElevatedButton(
//             onPressed: isRecording ? stopRecording : startRecording,
//             child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
//           ),
//         ],
//       ),
//     );
//   }
// }