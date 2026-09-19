import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      _tts.setStartHandler(() {
        _isPlaying = true;
      });

      _tts.setCompletionHandler(() {
        _isPlaying = false;
      });

      _tts.setErrorHandler((msg) {
        _isPlaying = false;
      });
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      if (_isPlaying) {
        await stop();
      }
      await _tts.speak(text);
      _isPlaying = true;
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isPlaying = false;
    } catch (_) {}
  }
}
