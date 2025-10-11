import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _isEnabled = true;
  double _volume = 0.5;

  // Inicializar el servicio
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('sound_enabled') ?? true;
    _volume = prefs.getDouble('sound_volume') ?? 0.5;

    // Todos los sonidos desactivados para evitar errores
  }

  // Pre-cargar un sonido
  Future<void> _preloadSound(String key, String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setVolume(_volume);
      await player.setSource(AssetSource(assetPath));
      _players[key] = player;
    } catch (e) {
      print('🔇 Failed to preload sound $key: $e');
      // No agregar el player si falla la precarga
    }
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

    // Actualizar volumen de todos los players
    for (var player in _players.values) {
      player.setVolume(volume);
    }
  }

  bool get isEnabled => _isEnabled;
  double get volume => _volume;

  // Reproducir sonido
  Future<void> play(String soundKey) async {
    if (!_isEnabled) return;

    try {
      final player = _players[soundKey];
      if (player != null) {
        await player.stop();
        await player.seek(Duration.zero);
        await player.resume();
      } else {
        // Si no está pre-cargado, crear uno nuevo
        final newPlayer = AudioPlayer();
        await newPlayer.setVolume(_volume);
        await newPlayer.setSource(AssetSource('$soundKey.mp3'));
        await newPlayer.resume();
      }
    } catch (e) {
      // Ignorar errores de reproducción - no deben bloquear la app
      print('🔇 Sound error (ignored): $e');
    }
  }

  // Reproducir victoria (DESACTIVADO)
  Future<void> playWin() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir match point (DESACTIVADO)
  Future<void> playMatchPoint() async {
    // Sonido desactivado para evitar errores
  }

  // Reproducir finisher (DESACTIVADO)
  Future<void> playFinisher() async {
    // Sonido desactivado para evitar errores
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

  // Liberar recursos
  void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
