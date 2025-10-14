import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'whisper_helper.dart';
import 'package:string_similarity/string_similarity.dart'; // ✅ similarity package
import 'package:shared_preferences/shared_preferences.dart'; // For settings

class MemorizationPage extends StatefulWidget {
  const MemorizationPage({super.key});

  @override
  State<MemorizationPage> createState() => _MemorizationPageState();
}

class _MemorizationPageState extends State<MemorizationPage> {
  List<String> ayahs = [];
  int currentPage = 0;
  final int ayahsPerPage = 5;
  final whisper = WhisperHelper();
  String? result;
  bool isProcessing = false;
  bool isRecording = false;
  bool _isTranscribing = false;
  Timer? _transcriptionTimer;
  List<String> readWords = []; // Track recently transcribed words for highlighting
  double _transcriptionInterval = 10.0;
  double _similarityThreshold = 0.2;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    loadAyahs();
    whisper.copyModelIfNeeded();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _transcriptionInterval = prefs.getDouble('transcription_interval') ?? 10.0;
      _similarityThreshold = prefs.getDouble('similarity_threshold') ?? 0.2;
    });
  }

  Future<void> loadAyahs() async {
    final csvData = await rootBundle.loadString('assets/quran_csv.csv');
    final lines = const LineSplitter().convert(csvData);
    setState(() {
      ayahs = lines.skip(1).toList(); // skip header
    });
  }

  Future<void> startRecording() async {
    setState(() {
      isRecording = true;
      if (result == null) result = "🎙️ Recording...";
    });
    await whisper.startRecording();
    _transcriptionTimer = Timer.periodic(Duration(seconds: _transcriptionInterval.toInt()), (timer) async {
      if (isRecording && !_isTranscribing) {
        await _autoTranscribe();
      }
    });
  }

  Future<void> _autoTranscribe() async {
    if (_isTranscribing) return;
    _isTranscribing = true;

    setState(() {
      isProcessing = true;
    });

    final transcription = await whisper.stopAndTranscribe();
    await processTranscription(transcription);

    if (isRecording) {
      await whisper.startRecording(); // Restart recording for the next interval
    }

    if (mounted) {
      setState(() {
        isProcessing = false;
        _isTranscribing = false;
      });
    }
  }

  Future<void> stopRecordingAndTranscribe() async {
    _transcriptionTimer?.cancel();
    _transcriptionTimer = null;
    setState(() {
      isRecording = false;
      isProcessing = true;
    });

    final transcription = await whisper.stopAndTranscribe();
    await processTranscription(transcription);

    if (mounted) {
      setState(() {
        isProcessing = false;
        _isTranscribing = false;
      });
    }
  }

  Future<void> processTranscription(String? transcription) async {
    if (transcription == null || transcription.isEmpty) {
      if (mounted && result != null) {
        setState(() {
          result = result! + "\n⚠️ No transcription in this interval.";
        });
      }
      return;
    }

    // Add transcribed words to readWords (split by spaces, limit to last 50 to avoid memory issues)
    final transcribedWords = transcription.split(RegExp(r'\s+'));
    setState(() {
      readWords.addAll(transcribedWords);
      if (readWords.length > 50) {
        readWords = readWords.sublist(readWords.length - 50);
      }
    });

    // Compare with ALL ayahs to find the best match
    String closestAyah = '';
    int bestIndex = -1;
    double bestScore = -1.0;

    for (int i = 0; i < ayahs.length; i++) {
      double similarity = transcription.similarityTo(ayahs[i]);
      if (similarity > bestScore) {
        bestScore = similarity;
        closestAyah = ayahs[i];
        bestIndex = i;
      }
    }

    String newResult = "";
    if (bestIndex != -1 && bestScore > _similarityThreshold) { // Use dynamic threshold
      final totalPages = (ayahs.length / ayahsPerPage).ceil();
      int targetPage = bestIndex ~/ ayahsPerPage;
      targetPage = targetPage.clamp(0, totalPages - 1); // Ensure valid page

      if (targetPage != currentPage) {
        if (mounted) {
          setState(() {
            currentPage = targetPage;
          });
        }
        newResult = "\n\n➡️ Navigated to Page ${targetPage + 1}! (Match: ${(bestScore * 100).toStringAsFixed(0)}%)";
      } else {
        newResult = "\n\n✅ On correct page! (Match: ${(bestScore * 100).toStringAsFixed(0)}%)";
      }
    } else {
      newResult = "\n\n❌ No strong match found.";
    }

    // Append to result without overriding the entire history
    if (mounted) {
      setState(() {
        result = (result ?? "") + "\n🗣️ [$transcription] $closestAyah$newResult";
        // Optional: Limit history length to prevent overflow
        final lines = result!.split('\n');
        if (lines.length > 20) {
          result = lines.sublist(lines.length - 20).join('\n');
        }
      });
    }

    // Brief snackbar for non-blocking feedback
    if (mounted && newResult.contains('Navigated')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigated to matching page!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Trigger rebuild for highlighting
    if (mounted) setState(() {});
  }

  // Helper to check if a word should be highlighted (similarity > dynamic threshold to any read word)
  bool _shouldHighlight(String word) {
    for (String readWord in readWords) {
      if (word.similarityTo(readWord) > _similarityThreshold) {
        return true;
      }
    }
    return false;
  }

  // Helper to build RichText for an ayah with highlighting
  Widget _buildHighlightedAyah(String ayah) {
    final words = ayah.split(RegExp(r'\s+'));
    final spans = <TextSpan>[];
    for (String word in words) {
      final trimmedWord = word.trim();
      if (trimmedWord.isEmpty) continue;
      final isHighlighted = _shouldHighlight(trimmedWord);
      spans.add(TextSpan(
        text: '$trimmedWord ',
        style: TextStyle(
          fontSize: 24,
          fontFamily: 'Amiri',
          color: isHighlighted ? Colors.green : Colors.black, // ✅ Explicit black for non-highlighted
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 24,
          fontFamily: 'Amiri',
          color: Colors.black, // ✅ Ensure parent style is black as fallback
        ),
        children: spans,
      ),
      textAlign: TextAlign.right,
    );
  }

  @override
  void dispose() {
    _transcriptionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (ayahs.length / ayahsPerPage).ceil();
    final start = currentPage * ayahsPerPage;
    final end = (start + ayahsPerPage > ayahs.length)
        ? ayahs.length
        : start + ayahsPerPage;
    final currentAyahs = ayahs.sublist(start, end);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Memorization'),
        automaticallyImplyLeading: true, // Back button
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Color(0xFFFFF8E1)],
          ),
        ),
        child: ayahs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentAyahs.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.all(10),
                          color: Colors.grey[50], // ✅ Light background for better contrast
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: _buildHighlightedAyah(currentAyahs[index]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Transcribing...'),
                        ],
                      ),
                    )
                  else if (isRecording)
                    ElevatedButton.icon(
                      onPressed: stopRecordingAndTranscribe,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: startRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Recording'),
                    ),
                  const SizedBox(height: 15),
                  if (result != null && result!.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            result!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 0
                            ? () => setState(() => currentPage--)
                            : null,
                        child: const Text('Previous'),
                      ),
                      Text('Page ${currentPage + 1} of $totalPages'),
                      ElevatedButton(
                        onPressed: currentPage < totalPages - 1
                            ? () => setState(() => currentPage++)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
      ),
    );
  }
}