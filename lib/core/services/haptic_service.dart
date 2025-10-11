import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;
  bool? _hasVibrator;

  // Inicializar el servicio
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('haptic_enabled') ?? true;
    _hasVibrator = await Vibration.hasVibrator();
  }

  // Habilitar/Deshabilitar haptic
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', enabled);
  }

  bool get isEnabled => _isEnabled;

  // Vibración ligera (tap, click)
  Future<void> light() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      await Vibration.vibrate(duration: 10);
    } catch (e) {
      // Ignorar errores de vibración
    }
  }

  // Vibración media (selección, cambio)
  Future<void> medium() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      // Ignorar errores de vibración
    }
  }

  // Vibración fuerte (éxito, logro)
  Future<void> heavy() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      await Vibration.vibrate(duration: 40);
    } catch (e) {
      // Ignorar errores de vibración
    }
  }

  // Vibración de éxito (doble tap)
  Future<void> success() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      await Vibration.vibrate(duration: 20);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      // Ignorar errores de vibración
    }
  }

  // Vibración de error
  Future<void> error() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      await Vibration.vibrate(duration: 50);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 50);
    } catch (e) {
      // Ignorar errores de vibración
    }
  }

  // Vibración de victoria (triple tap)
  Future<void> victory() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      for (int i = 0; i < 3; i++) {
        await Vibration.vibrate(duration: 30);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Ignorar errores de vibración
    }
  }

  // Vibración de match point (patrón especial)
  Future<void> matchPoint() async {
    if (!_isEnabled || _hasVibrator != true) return;
    try {
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 200);
    } catch (e) {
      // Ignorar errores de vibración
    }
  }
}


