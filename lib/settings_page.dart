import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _transcriptionInterval = 10.0;
  double _similarityThreshold = 0.2;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _transcriptionInterval = prefs.getDouble('transcription_interval') ?? 10.0;
      _similarityThreshold = prefs.getDouble('similarity_threshold') ?? 0.2;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('transcription_interval', _transcriptionInterval);
    await prefs.setDouble('similarity_threshold', _similarityThreshold);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved! Restart session to apply.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Color(0xFFFFF8E1)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transcription Interval (seconds)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _transcriptionInterval,
                      min: 5,
                      max: 30,
                      divisions: 5,
                      onChanged: (value) => setState(() => _transcriptionInterval = value),
                    ),
                    Text('${_transcriptionInterval.toInt()}s', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Similarity Threshold (for highlighting)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _similarityThreshold,
                      min: 0.1,
                      max: 0.5,
                      divisions: 4,
                      onChanged: (value) => setState(() => _similarityThreshold = value),
                    ),
                    Text('${(_similarityThreshold * 100).toInt()}%', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}