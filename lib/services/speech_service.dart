import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Mikrofon iznini kontrol et ve al
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Speech-to-Text servisini başlat
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      return false;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          print('Speech-to-Text hatası: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          print('Speech-to-Text durumu: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      print('Speech-to-Text başlatma hatası: $e');
      return false;
    }
  }

  /// Dinlemeyi başlat
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'tr_TR',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Speech-to-Text başlatılamadı');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: false,
      );
    } catch (e) {
      print('Dinleme başlatma hatası: $e');
      _isListening = false;
      rethrow;
    }
  }

  /// Dinlemeyi durdur
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Dinlemeyi iptal et
  Future<void> cancel() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
    }
  }

  /// Kullanılabilir dilleri getir
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final locales = await _speechToText.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  /// Servisi temizle
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    _isListening = false;
  }
}

