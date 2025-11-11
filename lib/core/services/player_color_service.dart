import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerColorService {
  static final PlayerColorService _instance = PlayerColorService._internal();
  factory PlayerColorService() => _instance;
  PlayerColorService._internal();

  static const String _colorsKey = 'player_colors';
  final Map<String, int> _playerColors = {};

  // Paleta de colores disponibles
  static List<Color> getDefaultPalette(ColorScheme colorScheme) {
    return [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceContainerHigh,
      colorScheme.surfaceContainerHighest,
    ];
  }

  // Inicializar el servicio
  Future<void> init() async {
    try {
      await _loadColors();
    } catch (e) {
      // Ignorar errores de inicialización - no crítico
      print('⚠️ Error inicializando PlayerColorService: $e');
    }
  }

  // Cargar colores guardados
  Future<void> _loadColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? colorsJson = prefs.getString(_colorsKey);

      if (colorsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(colorsJson);
        _playerColors.clear();
        decoded.forEach((key, value) {
          _playerColors[key] = value as int;
        });
      }
    } catch (e) {
      // Ignorar errores de carga
    }
  }

  // Guardar colores
  Future<void> _saveColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorsKey, jsonEncode(_playerColors));
    } catch (e) {
      // Ignorar errores de guardado
    }
  }

  // Obtener el índice de color para un jugador
  int getColorIndex(String playerName, ColorScheme colorScheme) {
    // Si el jugador ya tiene un color asignado, usarlo
    if (_playerColors.containsKey(playerName)) {
      final savedIndex = _playerColors[playerName]!;
      final palette = getDefaultPalette(colorScheme);
      // Validar que el índice sea válido
      if (savedIndex >= 0 && savedIndex < palette.length) {
        return savedIndex;
      }
    }
    // Si no tiene color, asignar uno basado en el hash del nombre
    // Esto asegura que el mismo nombre siempre tenga el mismo color
    final hash = playerName.hashCode;
    final palette = getDefaultPalette(colorScheme);
    final index = hash.abs() % palette.length;
    _playerColors[playerName] = index;
    // Guardar de forma asíncrona sin bloquear
    _saveColors().catchError((e) => print('⚠️ Error guardando colores: $e'));
    return index;
  }

  // Obtener el color directamente
  Color getColor(String playerName, ColorScheme colorScheme) {
    // Si el servicio no está inicializado, usar hash del nombre directamente
    if (_playerColors.isEmpty) {
      final hash = playerName.hashCode;
      final palette = getDefaultPalette(colorScheme);
      final index = hash.abs() % palette.length;
      return palette[index];
    }
    final index = getColorIndex(playerName, colorScheme);
    final palette = getDefaultPalette(colorScheme);
    return palette[index];
  }

  // Actualizar el nombre de un jugador (mantener el color)
  Future<void> updatePlayerName(String oldName, String newName) async {
    if (oldName == newName) return;

    // Si el jugador viejo tenía un color, transferirlo al nuevo nombre
    if (_playerColors.containsKey(oldName)) {
      final colorIndex = _playerColors[oldName]!;
      _playerColors[newName] = colorIndex;
      _playerColors.remove(oldName);
      await _saveColors();
    }
  }

  // Asignar un color específico a un jugador
  Future<void> setColorIndex(String playerName, int colorIndex) async {
    _playerColors[playerName] = colorIndex;
    await _saveColors();
  }

  // Limpiar colores de jugadores que ya no existen
  Future<void> cleanupColors(List<String> existingPlayerNames) async {
    final namesToRemove =
        _playerColors.keys
            .where((name) => !existingPlayerNames.contains(name))
            .toList();

    for (final name in namesToRemove) {
      _playerColors.remove(name);
    }

    if (namesToRemove.isNotEmpty) {
      await _saveColors();
    }
  }
}
