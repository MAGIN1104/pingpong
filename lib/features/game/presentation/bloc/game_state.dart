import 'package:equatable/equatable.dart';
import '../../domain/entities/game.dart';

class GameState extends Equatable {
  final Game game;
  final bool showMatchPoint;
  final int lastMatchPointShown;
  final List<Game> gameHistory;

  const GameState({
    required this.game,
    this.showMatchPoint = false,
    this.lastMatchPointShown = -1,
    this.gameHistory = const [],
  });

  GameState copyWith({
    Game? game,
    bool? showMatchPoint,
    int? lastMatchPointShown,
    List<Game>? gameHistory,
  }) {
    return GameState(
      game: game ?? this.game,
      showMatchPoint: showMatchPoint ?? this.showMatchPoint,
      lastMatchPointShown: lastMatchPointShown ?? this.lastMatchPointShown,
      gameHistory: gameHistory ?? this.gameHistory,
    );
  }

  @override
  List<Object?> get props => [
    game,
    showMatchPoint,
    lastMatchPointShown,
    gameHistory,
  ];
}
