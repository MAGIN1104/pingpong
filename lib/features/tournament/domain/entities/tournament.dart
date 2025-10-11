import 'package:equatable/equatable.dart';
import '../../../game/domain/entities/player.dart';

enum TournamentType {
  singleElimination, // Eliminación simple
  doubleElimination, // Doble eliminación
  roundRobin, // Todos contra todos
}

enum MatchStatus {
  pending, // Por jugar
  inProgress, // En progreso
  completed, // Completado
}

class Tournament extends Equatable {
  final String id;
  final String name;
  final List<Player> players;
  final TournamentType type;
  final int pointsToWin;
  final List<TournamentMatch> matches;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Player? winner;
  final bool isActive;

  const Tournament({
    required this.id,
    required this.name,
    required this.players,
    required this.type,
    required this.pointsToWin,
    required this.matches,
    required this.createdAt,
    this.completedAt,
    this.winner,
    this.isActive = true,
  });

  // Obtener el round actual
  int get currentRound {
    if (matches.isEmpty) return 0;
    final completedMatches =
        matches.where((m) => m.status == MatchStatus.completed).length;
    return (completedMatches / _matchesPerRound).ceil();
  }

  int get _matchesPerRound {
    if (type == TournamentType.roundRobin) {
      return players.length - 1;
    }
    return (players.length / 2).ceil();
  }

  // Obtener progreso del torneo (0.0 - 1.0)
  double get progress {
    if (matches.isEmpty) return 0.0;
    final completed =
        matches.where((m) => m.status == MatchStatus.completed).length;
    return completed / matches.length;
  }

  // Verificar si el torneo está completo
  bool get isCompleted => winner != null || completedAt != null;

  Tournament copyWith({
    String? id,
    String? name,
    List<Player>? players,
    TournamentType? type,
    int? pointsToWin,
    List<TournamentMatch>? matches,
    DateTime? createdAt,
    DateTime? completedAt,
    Player? winner,
    bool? isActive,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? this.players,
      type: type ?? this.type,
      pointsToWin: pointsToWin ?? this.pointsToWin,
      matches: matches ?? this.matches,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      winner: winner ?? this.winner,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players':
          players.map((p) => {'name': p.name, 'avatarId': p.avatarId}).toList(),
      'type': type.name,
      'pointsToWin': pointsToWin,
      'matches': matches.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'winner':
          winner != null
              ? {'name': winner!.name, 'avatarId': winner!.avatarId}
              : null,
      'isActive': isActive,
    };
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      players:
          (json['players'] as List)
              .map(
                (p) => Player(
                  name: p['name'] as String,
                  avatarId: p['avatarId'] as String,
                ),
              )
              .toList(),
      type: TournamentType.values.firstWhere((t) => t.name == json['type']),
      pointsToWin: json['pointsToWin'] as int,
      matches:
          (json['matches'] as List)
              .map((m) => TournamentMatch.fromJson(m as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      winner:
          json['winner'] != null
              ? Player(
                name: json['winner']['name'] as String,
                avatarId: json['winner']['avatarId'] as String,
              )
              : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    players,
    type,
    pointsToWin,
    matches,
    createdAt,
    completedAt,
    winner,
    isActive,
  ];
}

class TournamentMatch extends Equatable {
  final String id;
  final Player? player1;
  final Player? player2;
  final int? score1;
  final int? score2;
  final MatchStatus status;
  final int round;
  final int matchNumber;
  final Player? winner;
  final String? nextMatchId; // ID del siguiente partido si gana

  const TournamentMatch({
    required this.id,
    this.player1,
    this.player2,
    this.score1,
    this.score2,
    this.status = MatchStatus.pending,
    required this.round,
    required this.matchNumber,
    this.winner,
    this.nextMatchId,
  });

  TournamentMatch copyWith({
    String? id,
    Player? player1,
    Player? player2,
    int? score1,
    int? score2,
    MatchStatus? status,
    int? round,
    int? matchNumber,
    Player? winner,
    String? nextMatchId,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      status: status ?? this.status,
      round: round ?? this.round,
      matchNumber: matchNumber ?? this.matchNumber,
      winner: winner ?? this.winner,
      nextMatchId: nextMatchId ?? this.nextMatchId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1':
          player1 != null
              ? {'name': player1!.name, 'avatarId': player1!.avatarId}
              : null,
      'player2':
          player2 != null
              ? {'name': player2!.name, 'avatarId': player2!.avatarId}
              : null,
      'score1': score1,
      'score2': score2,
      'status': status.name,
      'round': round,
      'matchNumber': matchNumber,
      'winner':
          winner != null
              ? {'name': winner!.name, 'avatarId': winner!.avatarId}
              : null,
      'nextMatchId': nextMatchId,
    };
  }

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      player1:
          json['player1'] != null
              ? Player(
                name: json['player1']['name'] as String,
                avatarId: json['player1']['avatarId'] as String,
              )
              : null,
      player2:
          json['player2'] != null
              ? Player(
                name: json['player2']['name'] as String,
                avatarId: json['player2']['avatarId'] as String,
              )
              : null,
      score1: json['score1'] as int?,
      score2: json['score2'] as int?,
      status: MatchStatus.values.firstWhere((s) => s.name == json['status']),
      round: json['round'] as int,
      matchNumber: json['matchNumber'] as int,
      winner:
          json['winner'] != null
              ? Player(
                name: json['winner']['name'] as String,
                avatarId: json['winner']['avatarId'] as String,
              )
              : null,
      nextMatchId: json['nextMatchId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    player1,
    player2,
    score1,
    score2,
    status,
    round,
    matchNumber,
    winner,
    nextMatchId,
  ];
}


