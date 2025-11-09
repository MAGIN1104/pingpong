import 'package:equatable/equatable.dart';
import '../../../game/domain/entities/player.dart';

enum TournamentType {
  singleElimination, // Eliminación simple
  doubleElimination, // Doble eliminación
  roundRobin, // Todos contra todos
  groupStage, // Fase de grupos + eliminación
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

  // Propiedades específicas para fase de grupos
  final int? numberOfGroups;
  final int? playersPerGroup;
  final int? playersAdvancingPerGroup;
  final bool? groupStageCompleted;

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
    this.numberOfGroups,
    this.playersPerGroup,
    this.playersAdvancingPerGroup,
    this.groupStageCompleted = false,
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
    final playableMatches =
        matches.where((m) => m.player1 != null && m.player2 != null).toList();
    if (playableMatches.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    final completed =
        playableMatches.where((m) => m.status == MatchStatus.completed).length;
    return completed / playableMatches.length;
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
    int? numberOfGroups,
    int? playersPerGroup,
    int? playersAdvancingPerGroup,
    bool? groupStageCompleted,
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
      numberOfGroups: numberOfGroups ?? this.numberOfGroups,
      playersPerGroup: playersPerGroup ?? this.playersPerGroup,
      playersAdvancingPerGroup:
          playersAdvancingPerGroup ?? this.playersAdvancingPerGroup,
      groupStageCompleted: groupStageCompleted ?? this.groupStageCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((p) => {'name': p.name}).toList(),
      'type': type.name,
      'pointsToWin': pointsToWin,
      'matches': matches.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'winner': winner != null ? {'name': winner!.name} : null,
      'isActive': isActive,
      'numberOfGroups': numberOfGroups,
      'playersPerGroup': playersPerGroup,
      'playersAdvancingPerGroup': playersAdvancingPerGroup,
      'groupStageCompleted': groupStageCompleted,
    };
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      players:
          (json['players'] as List)
              .map(
                (p) =>
                    Player(name: (p as Map<String, dynamic>)['name'] as String),
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
                name:
                    (json['winner'] as Map<String, dynamic>)['name'] as String,
              )
              : null,
      isActive: json['isActive'] as bool? ?? true,
      numberOfGroups: json['numberOfGroups'] as int?,
      playersPerGroup: json['playersPerGroup'] as int?,
      playersAdvancingPerGroup: json['playersAdvancingPerGroup'] as int?,
      groupStageCompleted: json['groupStageCompleted'] as bool? ?? false,
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
    numberOfGroups,
    playersPerGroup,
    playersAdvancingPerGroup,
    groupStageCompleted,
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

  // Propiedades para fase de grupos
  final String? groupId; // ID del grupo (ej: "A", "B", "elimination")
  final bool?
  isGroupStage; // true si es fase de grupos, false si es eliminación

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
    this.groupId,
    this.isGroupStage,
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
    String? groupId,
    bool? isGroupStage,
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
      groupId: groupId ?? this.groupId,
      isGroupStage: isGroupStage ?? this.isGroupStage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1': player1 != null ? {'name': player1!.name} : null,
      'player2': player2 != null ? {'name': player2!.name} : null,
      'score1': score1,
      'score2': score2,
      'status': status.name,
      'round': round,
      'matchNumber': matchNumber,
      'winner': winner != null ? {'name': winner!.name} : null,
      'nextMatchId': nextMatchId,
      'groupId': groupId,
      'isGroupStage': isGroupStage,
    };
  }

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      player1:
          json['player1'] != null
              ? Player(
                name:
                    (json['player1'] as Map<String, dynamic>)['name'] as String,
              )
              : null,
      player2:
          json['player2'] != null
              ? Player(
                name:
                    (json['player2'] as Map<String, dynamic>)['name'] as String,
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
                name:
                    (json['winner'] as Map<String, dynamic>)['name'] as String,
              )
              : null,
      nextMatchId: json['nextMatchId'] as String?,
      groupId: json['groupId'] as String?,
      isGroupStage: json['isGroupStage'] as bool?,
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
    groupId,
    isGroupStage,
  ];
}
