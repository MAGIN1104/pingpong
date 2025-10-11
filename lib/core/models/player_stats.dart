import 'package:equatable/equatable.dart';

class PlayerStats extends Equatable {
  final String playerName;
  final int totalGames;
  final int wins;
  final int losses;
  final int totalPoints;
  final int totalPointsConceded;
  final int longestWinStreak;
  final int currentWinStreak;
  final DateTime? lastPlayed;
  final Map<int, int> winsByModality; // modalidad -> victorias
  final List<String> achievements;

  const PlayerStats({
    required this.playerName,
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalPoints = 0,
    this.totalPointsConceded = 0,
    this.longestWinStreak = 0,
    this.currentWinStreak = 0,
    this.lastPlayed,
    this.winsByModality = const {},
    this.achievements = const [],
  });

  // Calcular win rate
  double get winRate {
    if (totalGames == 0) return 0.0;
    return (wins / totalGames) * 100;
  }

  // Calcular promedio de puntos por juego
  double get averagePointsPerGame {
    if (totalGames == 0) return 0.0;
    return totalPoints / totalGames;
  }

  // Calcular promedio de puntos concedidos por juego
  double get averagePointsConcededPerGame {
    if (totalGames == 0) return 0.0;
    return totalPointsConceded / totalGames;
  }

  // Copiar con nuevos valores
  PlayerStats copyWith({
    String? playerName,
    int? totalGames,
    int? wins,
    int? losses,
    int? totalPoints,
    int? totalPointsConceded,
    int? longestWinStreak,
    int? currentWinStreak,
    DateTime? lastPlayed,
    Map<int, int>? winsByModality,
    List<String>? achievements,
  }) {
    return PlayerStats(
      playerName: playerName ?? this.playerName,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      totalPoints: totalPoints ?? this.totalPoints,
      totalPointsConceded: totalPointsConceded ?? this.totalPointsConceded,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      winsByModality: winsByModality ?? this.winsByModality,
      achievements: achievements ?? this.achievements,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'totalPoints': totalPoints,
      'totalPointsConceded': totalPointsConceded,
      'longestWinStreak': longestWinStreak,
      'currentWinStreak': currentWinStreak,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'winsByModality': winsByModality,
      'achievements': achievements,
    };
  }

  // Crear desde JSON
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerName: json['playerName'] as String,
      totalGames: json['totalGames'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      totalPointsConceded: json['totalPointsConceded'] as int? ?? 0,
      longestWinStreak: json['longestWinStreak'] as int? ?? 0,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      lastPlayed:
          json['lastPlayed'] != null
              ? DateTime.parse(json['lastPlayed'] as String)
              : null,
      winsByModality:
          (json['winsByModality'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(int.parse(key), value as int),
          ) ??
          {},
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    playerName,
    totalGames,
    wins,
    losses,
    totalPoints,
    totalPointsConceded,
    longestWinStreak,
    currentWinStreak,
    lastPlayed,
    winsByModality,
    achievements,
  ];
}
