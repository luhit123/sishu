import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/app_language.dart';

/// Service for voice features using ElevenLabs TTS and Speech-to-Text
class VoiceService {
  static VoiceService? _instance;
  static const String _elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';

  // ElevenLabs voice IDs for different languages/voices
  // Using multilingual v2 model which supports many languages
  static const String _defaultVoiceId = 'EXAVITQu4vr4xnSDxMaL'; // Sarah - warm female voice
  static const String _maleVoiceId = 'pNInz6obpgDQGcFmaJgB'; // Adam - male voice

  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechInitialized = false;

  factory VoiceService() {
    _instance ??= VoiceService._internal();
    return _instance!;
  }

  VoiceService._internal();

  // ============================================================================
  // API KEY MANAGEMENT
  // ============================================================================

  String? get _apiKey => dotenv.env['ELEVENLABS_API_KEY'];

  bool get hasApiKey {
    final key = _apiKey;
    return key != null &&
           key.isNotEmpty &&
           key != 'your_elevenlabs_api_key_here';
  }

  // ============================================================================
  // TEXT-TO-SPEECH (ElevenLabs)
  // ============================================================================

  /// Convert text to speech and play it
  Future<void> speak(String text, {AppLanguage language = AppLanguage.english}) async {
    if (!hasApiKey) {
      throw VoiceException('ElevenLabs API key not configured');
    }

    try {
      // Use multilingual v2 model for non-English
      final modelId = language == AppLanguage.english
          ? 'eleven_monolingual_v1'
          : 'eleven_multilingual_v2';

      final response = await http.post(
        Uri.parse('$_elevenLabsBaseUrl/text-to-speech/$_defaultVoiceId'),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': _apiKey!,
        },
        body: jsonEncode({
          'text': text,
          'model_id': modelId,
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
            'style': 0.5,
            'use_speaker_boost': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        // Save audio to temp file and play
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/mona_speech_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await audioFile.writeAsBytes(response.bodyBytes);

        await _audioPlayer.setFilePath(audioFile.path);
        await _audioPlayer.play();
      } else {
        final error = jsonDecode(response.body);
        throw VoiceException(error['detail']?['message'] ?? 'TTS failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is VoiceException) rethrow;
      throw VoiceException('Voice error: ${e.toString()}');
    }
  }

  /// Stop any currently playing audio
  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
  }

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer.playing;

  /// Stream of playing state
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  // ============================================================================
  // SPEECH-TO-TEXT
  // ============================================================================

  /// Initialize speech recognition
  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;
    _speechInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    return _speechInitialized;
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String) onResult,
    AppLanguage language = AppLanguage.english,
  }) async {
    if (!_speechInitialized) {
      final initialized = await initializeSpeech();
      if (!initialized) {
        throw VoiceException('Speech recognition not available');
      }
    }

    // Map AppLanguage to locale code
    final localeId = _getLocaleId(language);

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      listenMode: ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_speechInitialized) await initializeSpeech();
    return _speechToText.locales();
  }

  String _getLocaleId(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'en_IN'; // Indian English
      case AppLanguage.hindi:
        return 'hi_IN';
      case AppLanguage.tamil:
        return 'ta_IN';
      case AppLanguage.telugu:
        return 'te_IN';
      case AppLanguage.bengali:
        return 'bn_IN';
      case AppLanguage.marathi:
        return 'mr_IN';
      case AppLanguage.gujarati:
        return 'gu_IN';
      case AppLanguage.kannada:
        return 'kn_IN';
      case AppLanguage.malayalam:
        return 'ml_IN';
      case AppLanguage.punjabi:
        return 'pa_IN';
      case AppLanguage.odia:
        return 'or_IN';
      case AppLanguage.assamese:
        return 'as_IN';
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _speechToText.stop();
  }
}

/// Custom exception for voice errors
class VoiceException implements Exception {
  final String message;
  VoiceException(this.message);

  @override
  String toString() => message;
}
