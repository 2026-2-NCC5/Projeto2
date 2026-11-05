import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlaybackState { stopped, playing, paused }

/// Serviço de Acessibilidade Text-to-Speech (TTS) do ASA Connect+
///
/// Permite que estudantes escutem em voz alta as respostas da IA do ASA
/// e orientações acadêmicas em português do Brasil (pt-BR).
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  String? _currentMessageId;
  bool _isInitialized = false;

  TtsPlaybackState get playbackState => _playbackState;
  bool get isSpeaking => _playbackState == TtsPlaybackState.playing;
  String? get currentMessageId => _currentMessageId;

  TtsService() {
    _initTts();
  }

  /// Inicializa o mecanismo TTS com configurações de voz pt-BR
  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage("pt-BR");
      // Velocidade moderada para dicção clara de orientações acadêmicas
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _playbackState = TtsPlaybackState.playing;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _playbackState = TtsPlaybackState.stopped;
        _currentMessageId = null;
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        _playbackState = TtsPlaybackState.stopped;
        _currentMessageId = null;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        debugPrint('TtsService error: $msg');
        _playbackState = TtsPlaybackState.stopped;
        _currentMessageId = null;
        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar TtsService: $e');
    }
  }

  /// Limpa formatação Markdown para que o sintetizador vocal pronuncie
  /// o texto com naturalidade, sem soletrar asteriscos, cerquilhas ou URLs.
  static String cleanMarkdownForSpeech(String markdown) {
    if (markdown.isEmpty) return '';

    String cleaned = markdown;

    // 1. Remover blocos de código ```...```
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // 2. Remover códigos inline `código`
    cleaned = cleaned.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');

    // 3. Converter links Markdown [Texto](url) para apenas Texto
    cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1) ?? '');

    // 4. Substituir URLs diretas (http/https), preservando pontuação de fim de frase
    cleaned = cleaned.replaceAllMapped(RegExp(r'https?:\/\/[^\s]+'), (m) {
      final url = m.group(0) ?? '';
      if (url.endsWith('.') || url.endsWith(',') || url.endsWith(';') || url.endsWith(':')) {
        return 'link institucional${url[url.length - 1]}';
      }
      return 'link institucional';
    });

    // 5. Remover cabeçalhos (# Título, ## Subtítulo, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // 6. Remover negrito e itálico (**texto**, *texto*, __texto__, _texto_)
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');

    // 7. Remover marcadores de listas (*, -, +, •) e números de lista (1. 2.)
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*+•]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 8. Remover linhas de tabelas markdown (| e ---)
    cleaned = cleaned.replaceAll(RegExp(r'\|'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-:\s|]{3,}\s*$', multiLine: true), '');

    // 9. Remover citações (> texto)
    cleaned = cleaned.replaceAll(RegExp(r'^\s*>\s+', multiLine: true), '');

    // 10. Normalizar espaços múltiplos e quebras de linha
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{2,}'), '\n');

    return cleaned.trim();
  }

  /// Inicia ou alterna a leitura vocal de uma mensagem específica.
  /// Se a mensagem atual já estiver tocando, ela é pausada/parada.
  Future<void> toggleSpeak({
    required String messageId,
    required String content,
  }) async {
    if (_currentMessageId == messageId && isSpeaking) {
      await stop();
      return;
    }

    await stop();

    final textToSpeak = cleanMarkdownForSpeech(content);
    if (textToSpeak.isEmpty) return;

    _currentMessageId = messageId;
    _playbackState = TtsPlaybackState.playing;
    notifyListeners();

    try {
      await _initTts();
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('Erro ao reproduzir áudio: $e');
      _playbackState = TtsPlaybackState.stopped;
      _currentMessageId = null;
      notifyListeners();
    }
  }

  /// Interrompe qualquer reprodução de áudio em andamento.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _playbackState = TtsPlaybackState.stopped;
    _currentMessageId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
