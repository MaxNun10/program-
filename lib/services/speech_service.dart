import 'package:audioplayers/audioplayers.dart';

class SpeechService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> speak(String text, {String languageCode = 'en'}) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final safeText = trimmedText.length > 180
        ? trimmedText.substring(0, 180)
        : trimmedText;
    final uri = Uri.https('translate.google.com', '/translate_tts', {
      'ie': 'UTF-8',
      'client': 'tw-ob',
      'tl': languageCode,
      'q': safeText,
    });

    await _player.stop();
    await _player.play(UrlSource(uri.toString()));
  }

  static Future<void> stop() => _player.stop();
}
