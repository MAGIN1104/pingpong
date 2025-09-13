import 'package:equatable/equatable.dart';

class Game extends Equatable {
  final String player1;
  final String player2;
  final int score1;
  final int score2;
  final String currentServer;
  final int remainingServes;
  final int pointsToWin;
  final bool isWarmingUp;
  final int warmupTimeRemaining;
  final DateTime? timestamp;

  const Game({
    required this.player1,
    required this.player2,
    this.score1 = 0,
    this.score2 = 0,
    required this.currentServer,
    this.remainingServes = 2,
    required this.pointsToWin,
    this.isWarmingUp = false,
    this.warmupTimeRemaining = 0,
    this.timestamp,
  });

  bool get isExtendedMode =>
      score1 >= pointsToWin - 1 && score2 >= pointsToWin - 1;

  bool get hasWinner {
    if (isExtendedMode) {
      return (score1 >= pointsToWin && score1 - score2 >= 2) ||
          (score2 >= pointsToWin && score2 - score1 >= 2);
    }
    return score1 == pointsToWin || score2 == pointsToWin;
  }

  String? get winner {
    if (!hasWinner) return null;
    return score1 > score2 ? player1 : player2;
  }

  Game copyWith({
    String? player1,
    String? player2,
    int? score1,
    int? score2,
    String? currentServer,
    int? remainingServes,
    int? pointsToWin,
    bool? isWarmingUp,
    int? warmupTimeRemaining,
    DateTime? timestamp,
  }) {
    return Game(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      currentServer: currentServer ?? this.currentServer,
      remainingServes: remainingServes ?? this.remainingServes,
      pointsToWin: pointsToWin ?? this.pointsToWin,
      isWarmingUp: isWarmingUp ?? this.isWarmingUp,
      warmupTimeRemaining: warmupTimeRemaining ?? this.warmupTimeRemaining,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    player1,
    player2,
    score1,
    score2,
    currentServer,
    remainingServes,
    pointsToWin,
    isWarmingUp,
    warmupTimeRemaining,
    timestamp,
  ];
}
