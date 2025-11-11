import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isEnabled = true;
  double _volume = 0.5;

  // Inicializar el servicio
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('sound_enabled') ?? true;
    _volume = prefs.getDouble('sound_volume') ?? 0.5;
    // No precargamos para evitar problemas con rutas - se cargarán bajo demanda
  }

  // Habilitar/Deshabilitar sonido
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  // Cambiar volumen
  Future<void> setVolume(double volume) async {
    _volume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', volume);
  }

  bool get isEnabled => _isEnabled;
  double get volume => _volume;

  // Reproducir sonido
  Future<void> play(String soundKey) async {
    if (!_isEnabled) return;

    try {
      // Crear un nuevo player para cada reproducción para evitar problemas de estado
      final player = AudioPlayer();
      await player.setVolume(_volume);
      // AssetSource usa la ruta relativa desde la carpeta assets (sin el prefijo assets/)
      await player.play(AssetSource('$soundKey.mp3'));
      // El player se liberará automáticamente cuando termine de reproducir
    } catch (e) {
      // Ignorar errores de reproducción - no deben bloquear la app
      print('🔇 Sound error (ignored): $e');
    }
  }

  // Reproducir victoria
  Future<void> playWin() async {
    if (!_isEnabled) return;

    try {
      await play('win');
    } catch (e) {
      print('🔇 Error playing win sound (ignored): $e');
    }
  }

  // Reproducir match point
  Future<void> playMatchPoint() async {
    if (!_isEnabled) return;

    try {
      await play('matchpoint');
    } catch (e) {
      print('🔇 Error playing matchpoint sound (ignored): $e');
    }
  }

  // Reproducir finisher
  Future<void> playFinisher() async {
    if (!_isEnabled) return;

    try {
      await play('finisher');
    } catch (e) {
      print('🔇 Error playing finisher sound (ignored): $e');
    }
  }

  // Reproducir incremento de score (DESACTIVADO)
  Future<void> playScoreUp() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir decremento de score (DESACTIVADO)
  Future<void> playScoreDown() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir cambio de saque (DESACTIVADO)
  Future<void> playServeChange() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir inicio de juego (DESACTIVADO)
  Future<void> playGameStart() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir inicio de calentamiento (DESACTIVADO)
  Future<void> playWarmupStart() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir click (DESACTIVADO)
  Future<void> playClick() async {
    // Sonido desactivado para evitar errores
  }

  // Liberar recursos (no necesario ya que creamos players temporales)
  void dispose() {
    // Los players se liberan automáticamente cuando terminan de reproducir
  }
}
