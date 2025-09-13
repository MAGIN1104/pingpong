import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameStarted extends GameEvent {
  final List<String> participants;
  final int pointsToWin;

  const GameStarted({required this.participants, required this.pointsToWin});

  @override
  List<Object> get props => [participants, pointsToWin];
}

class PlayerScored extends GameEvent {
  final bool isPlayer1;
  const PlayerScored({required this.isPlayer1});

  @override
  List<Object> get props => [isPlayer1];
}

class ScoreDecremented extends GameEvent {
  final bool isPlayer1;
  const ScoreDecremented({required this.isPlayer1});

  @override
  List<Object> get props => [isPlayer1];
}

class GameReset extends GameEvent {}

class WarmupStarted extends GameEvent {
  final int seconds;
  const WarmupStarted({required this.seconds});

  @override
  List<Object> get props => [seconds];
}

class WarmupCancelled extends GameEvent {}

class WarmupTicked extends GameEvent {}

class ServerChanged extends GameEvent {
  final String newServer;
  const ServerChanged({required this.newServer});

  @override
  List<Object> get props => [newServer];
}

class PlayerChanged extends GameEvent {
  final bool isPlayer1;
  final String newPlayer;

  const PlayerChanged({required this.isPlayer1, required this.newPlayer});

  @override
  List<Object> get props => [isPlayer1, newPlayer];
}
