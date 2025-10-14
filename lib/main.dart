import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'memorization_page.dart'; // Your existing MemorizationPage
import 'home_page.dart'; // Enhanced Home
import 'settings_page.dart'; // Settings
import 'progress_page.dart'; // Progress
import 'about_page.dart'; // About
import 'login_screen.dart'; // Login Screen
import 'register_screen.dart'; // Register Screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Memorization Aid',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: Colors.white.withOpacity(0.9),
        ),
        fontFamily: 'Amiri',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );

          case '/register':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );

          case '/main-home':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MainHomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );

          case '/enhanced-home':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                  child: child,
                );
              },
            );

          case '/memorization':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MemorizationPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                  child: child,
                );
              },
            );

          case '/progress':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ProgressPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );

          case '/settings':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(animation),
                  child: child,
                );
              },
            );

          case '/about':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AboutPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );

          default:
            return null;
        }
      },
    );
  }
}

// Wrapper for your old UI: Preserves exact old Scaffold + TranscriptionWidget, adds Drawer & gradient
class MainHomePage extends StatelessWidget {
  const MainHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Whisper Transcription'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'Quran Memorization Aid',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Enhanced Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/enhanced-home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Memorization'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/memorization');
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Progress'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/progress');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Color(0xFFFFF8E1)],
          ),
        ),
        child: const TranscriptionWidget(),
      ),
    );
  }
}

// Your EXACT old TranscriptionWidget (unchanged)
class TranscriptionWidget extends StatefulWidget {
  const TranscriptionWidget({super.key});

  @override
  _TranscriptionWidgetState createState() => _TranscriptionWidgetState();
}

class _TranscriptionWidgetState extends State<TranscriptionWidget> {
  final record = AudioRecorder();
  String transcription = '';
  bool isRecording = false;
  DynamicLibrary? whisperLib;
  late Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) whisperTranscribe;

  @override
  void initState() {
    super.initState();
    try {
      whisperLib = DynamicLibrary.open('libwhisper.so');
      whisperTranscribe = whisperLib!.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>('whisper_transcribe');
    } catch (e) {
      setState(() => transcription = 'Error loading libwhisper.so: $e');
    }
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
        final data = await DefaultAssetBundle.of(context).load('assets/ggml-tarteel-whisper-q4.bin');
        final bytes = data.buffer.asUint8List();
        await File(modelPath).writeAsBytes(bytes);
      }
    } catch (e) {
      setState(() => transcription = 'Error copying model: $e');
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
        setState(() => transcription = 'Microphone permission not granted');
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
          final resultPtr = whisperTranscribe(modelPathPtr, wavPathPtr, langPtr);
          final result = resultPtr.toDartString();
          setState(() => transcription = result.isEmpty ? 'No transcription generated' : result);
          malloc.free(resultPtr);
        } catch (e) {
          setState(() => transcription = 'Error during transcription: $e');
        }
        malloc.free(modelPathPtr);
        malloc.free(wavPathPtr);
        malloc.free(langPtr);
      } else {
        setState(() => transcription = 'No recording file generated');
      }
    } catch (e) {
      setState(() => transcription = 'Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                transcription.isEmpty ? 'No transcription yet' : transcription,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: isRecording ? stopRecording : startRecording,
            child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/memorization'),
            child: const Text('Open Memorization Page'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/enhanced-home'),
                icon: const Icon(Icons.home),
                label: const Text('Enhanced Home'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/progress'),
                icon: const Icon(Icons.trending_up),
                label: const Text('Progress'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/about'),
                icon: const Icon(Icons.info),
                label: const Text('About'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
