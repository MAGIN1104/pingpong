import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  static const String _statsKey = 'player_statistics';
  final Map<String, PlayerStats> _stats = {};

  // Inicializar el servicio
  Future<void> init() async {
    await _loadStats();
  }

  // Cargar estadísticas
  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? statsJson = prefs.getString(_statsKey);

      if (statsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(statsJson);
        _stats.clear();
        decoded.forEach((key, value) {
          _stats[key] = PlayerStats.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      // Ignorar errores de carga
    }
  }

  // Guardar estadísticas
  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> encoded = {};
      _stats.forEach((key, value) {
        encoded[key] = value.toJson();
      });
      await prefs.setString(_statsKey, jsonEncode(encoded));
    } catch (e) {
      // Ignorar errores de guardado
    }
  }

  // Obtener estadísticas de un jugador
  PlayerStats getPlayerStats(String playerName) {
    return _stats[playerName] ?? PlayerStats(playerName: playerName);
  }

  // Obtener todas las estadísticas
  List<PlayerStats> getAllStats() {
    return _stats.values.toList()..sort((a, b) => b.wins.compareTo(a.wins));
  }

  // Registrar un juego
  Future<void> recordGame({
    required String winnerName,
    required String loserName,
    required int winnerScore,
    required int loserScore,
    required int modality,
  }) async {
    // Actualizar estadísticas del ganador
    final winnerStats = getPlayerStats(winnerName);
    final newWinStreak = winnerStats.currentWinStreak + 1;

    _stats[winnerName] = winnerStats.copyWith(
      totalGames: winnerStats.totalGames + 1,
      wins: winnerStats.wins + 1,
      totalPoints: winnerStats.totalPoints + winnerScore,
      totalPointsConceded: winnerStats.totalPointsConceded + loserScore,
      currentWinStreak: newWinStreak,
      longestWinStreak:
          newWinStreak > winnerStats.longestWinStreak
              ? newWinStreak
              : winnerStats.longestWinStreak,
      lastPlayed: DateTime.now(),
      winsByModality: {
        ...winnerStats.winsByModality,
        modality: (winnerStats.winsByModality[modality] ?? 0) + 1,
      },
    );

    // Actualizar estadísticas del perdedor
    final loserStats = getPlayerStats(loserName);
    _stats[loserName] = loserStats.copyWith(
      totalGames: loserStats.totalGames + 1,
      losses: loserStats.losses + 1,
      totalPoints: loserStats.totalPoints + loserScore,
      totalPointsConceded: loserStats.totalPointsConceded + winnerScore,
      currentWinStreak: 0,
      lastPlayed: DateTime.now(),
    );

    // Verificar y otorgar logros
    await _checkAndGrantAchievements(
      winnerName,
      loserName,
      winnerScore,
      loserScore,
    );

    await _saveStats();
  }

  // Verificar y otorgar logros
  Future<void> _checkAndGrantAchievements(
    String winnerName,
    String loserName,
    int winnerScore,
    int loserScore,
  ) async {
    final winnerStats = _stats[winnerName]!;
    final achievements = List<String>.from(winnerStats.achievements);

    // Primera victoria
    if (winnerStats.wins == 1 && !achievements.contains('first_win')) {
      achievements.add('first_win');
    }

    // 10 victorias
    if (winnerStats.wins == 10 && !achievements.contains('10_wins')) {
      achievements.add('10_wins');
    }

    // 50 victorias
    if (winnerStats.wins == 50 && !achievements.contains('50_wins')) {
      achievements.add('50_wins');
    }

    // 100 victorias
    if (winnerStats.wins == 100 && !achievements.contains('100_wins')) {
      achievements.add('100_wins');
    }

    // Racha de 5 victorias
    if (winnerStats.currentWinStreak == 5 &&
        !achievements.contains('5_streak')) {
      achievements.add('5_streak');
    }

    // Racha de 10 victorias
    if (winnerStats.currentWinStreak == 10 &&
        !achievements.contains('10_streak')) {
      achievements.add('10_streak');
    }

    // Victoria perfecta (sin conceder puntos)
    if (loserScore == 0 && !achievements.contains('perfect_game')) {
      achievements.add('perfect_game');
    }

    // Comeback (ganar desde 5+ puntos abajo)
    if (loserScore >= winnerScore - 5 &&
        winnerScore >= 10 &&
        !achievements.contains('comeback_king')) {
      achievements.add('comeback_king');
    }

    // Win rate > 70% con al menos 20 juegos
    if (winnerStats.totalGames >= 20 &&
        winnerStats.winRate >= 70 &&
        !achievements.contains('champion')) {
      achievements.add('champion');
    }

    _stats[winnerName] = winnerStats.copyWith(achievements: achievements);
  }

  // Obtener logros de un jugador
  List<Achievement> getPlayerAchievements(String playerName) {
    final stats = getPlayerStats(playerName);
    return stats.achievements
        .map(
          (id) => _achievementsList.firstWhere(
            (a) => a.id == id,
            orElse:
                () => Achievement(
                  id: id,
                  title: 'Logro Desconocido',
                  description: '',
                  icon: '🏆',
                ),
          ),
        )
        .toList();
  }

  // Resetear estadísticas de un jugador
  Future<void> resetPlayerStats(String playerName) async {
    _stats.remove(playerName);
    await _saveStats();
  }

  // Resetear todas las estadísticas
  Future<void> resetAllStats() async {
    _stats.clear();
    await _saveStats();
  }
}

// Modelo de logro
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Lista de logros disponibles
const List<Achievement> _achievementsList = [
  Achievement(
    id: 'first_win',
    title: 'Primera Victoria',
    description: 'Gana tu primera partida',
    icon: '🎉',
  ),
  Achievement(
    id: '10_wins',
    title: 'Veterano',
    description: 'Gana 10 partidas',
    icon: '🏅',
  ),
  Achievement(
    id: '50_wins',
    title: 'Experto',
    description: 'Gana 50 partidas',
    icon: '🏆',
  ),
  Achievement(
    id: '100_wins',
    title: 'Maestro',
    description: 'Gana 100 partidas',
    icon: '👑',
  ),
  Achievement(
    id: '5_streak',
    title: 'Racha Imparable',
    description: 'Gana 5 partidas consecutivas',
    icon: '🔥',
  ),
  Achievement(
    id: '10_streak',
    title: 'Leyenda',
    description: 'Gana 10 partidas consecutivas',
    icon: '⚡',
  ),
  Achievement(
    id: 'perfect_game',
    title: 'Perfección',
    description: 'Gana sin conceder puntos',
    icon: '💎',
  ),
  Achievement(
    id: 'comeback_king',
    title: 'Rey del Comeback',
    description: 'Gana desde 5+ puntos abajo',
    icon: '💪',
  ),
  Achievement(
    id: 'champion',
    title: 'Campeón',
    description: '70% de victorias en 20+ partidas',
    icon: '🏆',
  ),
];


