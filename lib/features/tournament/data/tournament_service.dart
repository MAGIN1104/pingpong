import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/tournament.dart';
import '../../game/domain/entities/player.dart';

class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  static const String _tournamentKey = 'current_tournament';
  static const String _tournamentsHistoryKey = 'tournaments_history';

  Tournament? _currentTournament;

  // Inicializar el servicio
  Future<void> init() async {
    await loadCurrentTournament();
  }

  // Obtener el torneo actual
  Tournament? get currentTournament => _currentTournament;

  // Crear un nuevo torneo
  Tournament createTournament({
    required String name,
    required List<Player> players,
    required TournamentType type,
    required int pointsToWin,
    int? numberOfGroups,
    int? playersPerGroup,
    int? playersAdvancingPerGroup,
  }) {
    // Validar mínimo de jugadores
    if (players.length < 2) {
      throw Exception('Se necesitan al menos 2 jugadores para crear un torneo');
    }

    final tournamentId = 'tournament_${DateTime.now().millisecondsSinceEpoch}';

    // Generar partidos según el tipo de torneo
    List<TournamentMatch> matches;
    switch (type) {
      case TournamentType.singleElimination:
        matches = _generateSingleEliminationMatches(players, tournamentId);
        break;
      case TournamentType.doubleElimination:
        matches = _generateDoubleEliminationMatches(players, tournamentId);
        break;
      case TournamentType.roundRobin:
        matches = _generateRoundRobinMatches(players, tournamentId);
        break;
      case TournamentType.groupStage:
        matches = _generateGroupStageMatches(
          players,
          tournamentId,
          numberOfGroups: numberOfGroups,
          playersPerGroup: playersPerGroup,
          playersAdvancingPerGroup: playersAdvancingPerGroup,
        );
        break;
    }

    final tournament = Tournament(
      id: tournamentId,
      name: name,
      players: players,
      type: type,
      pointsToWin: pointsToWin,
      matches: matches,
      createdAt: DateTime.now(),
      numberOfGroups: numberOfGroups,
      playersPerGroup: playersPerGroup,
      playersAdvancingPerGroup: playersAdvancingPerGroup,
    );

    _currentTournament = tournament;

    // Procesar byes automáticamente después de crear el torneo
    if (type == TournamentType.singleElimination) {
      final matches = List<TournamentMatch>.from(tournament.matches);
      _processByeMatches(matches);
      _fixTournamentStructure(matches);

      // Verificar si hay problemas y regenerar si es necesario
      if (!_isTournamentStructureValid(matches)) {
        print(
          '📊 Tournament Creation: Invalid structure detected, regenerating...',
        );
        final regeneratedMatches = _generateSingleEliminationMatches(
          players,
          tournamentId,
        );
        _currentTournament = tournament.copyWith(matches: regeneratedMatches);
        _processByeMatches(regeneratedMatches);
        _fixTournamentStructure(regeneratedMatches);
        _currentTournament = _currentTournament!.copyWith(
          matches: regeneratedMatches,
        );
      } else {
        _currentTournament = tournament.copyWith(matches: matches);
      }
    }

    saveTournament(_currentTournament!);

    return _currentTournament!;
  }

  // Generar partidos para eliminación simple
  List<TournamentMatch> _generateSingleEliminationMatches(
    List<Player> players,
    String tournamentId,
  ) {
    final List<TournamentMatch> matches = [];
    final shuffledPlayers = List<Player>.from(players)..shuffle();

    print('📊 Tournament Generation: Starting with ${players.length} players');

    // Validar mínimo de jugadores
    if (players.length < 2) {
      print(
        '📊 Tournament Generation: ERROR - Need at least 2 players for tournament',
      );
      return matches;
    }

    int matchCounter = 0;

    // Calcular el número total de rondas necesarias
    final totalRounds = (log(players.length) / log(2)).ceil();
    print('📊 Tournament Generation: Total rounds needed: $totalRounds');

    // Primera ronda - manejar byes correctamente
    final firstRoundMatches = (players.length / 2).ceil();
    print(
      '📊 Tournament Generation: First round needs $firstRoundMatches matches',
    );

    for (int i = 0; i < firstRoundMatches; i++) {
      final player1Index = i * 2;
      final player2Index = player1Index + 1;

      if (player2Index < shuffledPlayers.length) {
        // Partido normal
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_match_$matchCounter',
            player1: shuffledPlayers[player1Index],
            player2: shuffledPlayers[player2Index],
            round: 1,
            matchNumber: matchCounter,
            status: MatchStatus.pending,
          ),
        );
        print(
          '📊 Tournament Generation: Match $matchCounter: ${shuffledPlayers[player1Index].name} vs ${shuffledPlayers[player2Index].name}',
        );
      } else {
        // Bye - jugador pasa directo a la siguiente ronda
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_match_$matchCounter',
            player1: shuffledPlayers[player1Index],
            player2: null,
            round: 1,
            matchNumber: matchCounter,
            status: MatchStatus.completed,
            winner: shuffledPlayers[player1Index],
          ),
        );
        print(
          '📊 Tournament Generation: Match $matchCounter: BYE for ${shuffledPlayers[player1Index].name}',
        );
      }
      matchCounter++;
    }

    // Generar partidos para todas las rondas posteriores
    for (int round = 2; round <= totalRounds; round++) {
      final playersInThisRound = (players.length / (1 << (round - 1))).ceil();
      final matchesInThisRound = (playersInThisRound / 2).ceil();

      print(
        '📊 Tournament Generation: Round $round needs $matchesInThisRound matches',
      );

      for (int i = 0; i < matchesInThisRound; i++) {
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_match_$matchCounter',
            round: round,
            matchNumber: matchCounter,
            status: MatchStatus.pending,
          ),
        );
        matchCounter++;
      }
    }

    print(
      '📊 Tournament Generation: Generated ${matches.length} total matches',
    );
    return matches;
  }

  // Generar partidos para doble eliminación
  List<TournamentMatch> _generateDoubleEliminationMatches(
    List<Player> players,
    String tournamentId,
  ) {
    // Similar a simple eliminación pero con bracket de perdedores
    final matches = _generateSingleEliminationMatches(players, tournamentId);
    // TODO: Agregar bracket de perdedores
    return matches;
  }

  // Generar partidos para round robin (todos contra todos)
  List<TournamentMatch> _generateRoundRobinMatches(
    List<Player> players,
    String tournamentId,
  ) {
    final List<TournamentMatch> matches = [];
    int matchCounter = 0;
    int round = 1;

    // Generar todos los enfrentamientos posibles
    for (int i = 0; i < players.length; i++) {
      for (int j = i + 1; j < players.length; j++) {
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_match_$matchCounter',
            player1: players[i],
            player2: players[j],
            round: round,
            matchNumber: matchCounter,
            status: MatchStatus.pending,
          ),
        );
        matchCounter++;

        // Cada jugador juega una vez por ronda
        if ((matchCounter % (players.length / 2)).ceil() == 0) {
          round++;
        }
      }
    }

    return matches;
  }

  // Generar partidos para fase de grupos + eliminación
  List<TournamentMatch> _generateGroupStageMatches(
    List<Player> players,
    String tournamentId, {
    int? numberOfGroups,
    int? playersPerGroup,
    int? playersAdvancingPerGroup,
  }) {
    final List<TournamentMatch> matches = [];
    final shuffledPlayers = List<Player>.from(players)..shuffle();

    print('📊 Group Stage Generation: Starting with ${players.length} players');

    // Configuración por defecto para grupos
    final resolvedGroups = (numberOfGroups ?? 2).clamp(1, players.length);
    final resolvedPlayersPerGroup = (playersPerGroup ??
            (players.length / resolvedGroups).ceil())
        .clamp(1, players.length);
    final resolvedAdvancingPerGroup = (playersAdvancingPerGroup ?? 2).clamp(
      1,
      resolvedPlayersPerGroup,
    );

    print(
      '📊 Group Stage Generation: $resolvedGroups groups, '
      '$resolvedPlayersPerGroup players per group, '
      '$resolvedAdvancingPerGroup advancing',
    );

    int matchCounter = 0;

    // Dividir jugadores en grupos
    final groups = <String, List<Player>>{};
    int cursor = 0;
    for (int i = 0; i < resolvedGroups; i++) {
      final groupId = String.fromCharCode(65 + i); // A, B, C, etc.
      final remaining = shuffledPlayers.length - cursor;
      final take = min(resolvedPlayersPerGroup, remaining);
      if (take <= 0) {
        groups[groupId] = [];
        continue;
      }
      groups[groupId] = shuffledPlayers.sublist(cursor, cursor + take);
      cursor += take;
      print(
        '📊 Group Stage Generation: Group $groupId: ${groups[groupId]!.map((p) => p.name).join(", ")}',
      );
    }

    // Generar partidos para cada grupo (Round Robin)
    for (final groupEntry in groups.entries) {
      final groupId = groupEntry.key;
      final groupPlayers = groupEntry.value;

      print('📊 Group Stage Generation: Generating matches for group $groupId');

      // Generar todos los enfrentamientos en el grupo
      for (int i = 0; i < groupPlayers.length; i++) {
        for (int j = i + 1; j < groupPlayers.length; j++) {
          matches.add(
            TournamentMatch(
              id: '${tournamentId}_group_${groupId}_match_$matchCounter',
              player1: groupPlayers[i],
              player2: groupPlayers[j],
              round: 1, // Todos los partidos de grupos son ronda 1
              matchNumber: matchCounter,
              status: MatchStatus.pending,
              groupId: groupId,
              isGroupStage: true,
            ),
          );
          print(
            '📊 Group Stage Generation: Group $groupId Match $matchCounter: ${groupPlayers[i].name} vs ${groupPlayers[j].name}',
          );
          matchCounter++;
        }
      }
    }

    print(
      '📊 Group Stage Generation: Generated ${matches.length} group stage matches',
    );
    return matches;
  }

  // Actualizar resultado de un partido
  Future<void> updateMatchResult({
    required String matchId,
    required Player winner,
    required int score1,
    required int score2,
  }) async {
    if (_currentTournament == null) return;

    final matches = List<TournamentMatch>.from(_currentTournament!.matches);
    final matchIndex = matches.indexWhere((m) => m.id == matchId);

    if (matchIndex == -1) return;

    final match = matches[matchIndex];
    matches[matchIndex] = match.copyWith(
      score1: score1,
      score2: score2,
      status: MatchStatus.completed,
      winner: winner,
    );

    // Avanzar ganador según el tipo de torneo
    if (_currentTournament!.type == TournamentType.singleElimination) {
      await _advanceWinnerToNextRound(matches, matchIndex, winner);
    } else if (_currentTournament!.type == TournamentType.groupStage) {
      // Verificar si es un partido de fase de grupos o de eliminación
      if (match.isGroupStage == true) {
        _processGroupStageMatch(matches, matchIndex, winner);
      } else {
        // Es un partido de eliminación, avanzar ganador a la siguiente ronda
        await _advanceWinnerToNextRound(matches, matchIndex, winner);
      }
      // Limpiar partidos duplicados después de procesar
      _cleanupDuplicateEliminationMatches(matches);
    }

    // Procesar automáticamente los byes ANTES de verificar si está completo
    if (_currentTournament!.type == TournamentType.singleElimination) {
      _processByeMatches(matches);
    } else if (_currentTournament!.type == TournamentType.groupStage) {
      // Para torneos de fase de grupos, procesar byes solo en partidos de eliminación
      _processEliminationByes(matches);
    }

    // Corregir problemas de estructura del torneo
    if (_currentTournament!.type == TournamentType.singleElimination) {
      _fixTournamentStructure(matches);
    }

    // Limpiar partidos que no se pueden completar
    if (_currentTournament!.type == TournamentType.singleElimination) {
      _cleanupInvalidMatches(matches);
    }

    // Verificar si el torneo está completo - SOLO partidos válidos
    final validMatches =
        matches.where((m) => m.player1 != null && m.player2 != null).toList();

    final allValidMatchesCompleted = validMatches.every(
      (m) => m.status == MatchStatus.completed,
    );

    Player? tournamentWinner;

    print(
      '📊 Tournament: Checking completion. Valid matches: ${validMatches.length}/${matches.length}',
    );
    print(
      '📊 Tournament: All valid matches completed: $allValidMatchesCompleted',
    );
    print('📊 Tournament: Total matches: ${matches.length}');
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      print(
        '📊 Tournament: Match $i (Round ${match.round}): ${match.player1?.name ?? "TBD"} vs ${match.player2?.name ?? "TBD"} - Status: ${match.status} - Winner: ${match.winner?.name ?? "None"}',
      );
    }

    if (allValidMatchesCompleted) {
      tournamentWinner = _determineTournamentWinner(validMatches);
      print('📊 Tournament: Winner determined: ${tournamentWinner?.name}');

      // Verificación adicional: asegurar que hay un ganador
      if (tournamentWinner == null) {
        print(
          '📊 Tournament: WARNING - Tournament completed but no winner found!',
        );
        // Buscar el partido de la ronda más alta con ganador
        final finalMatches =
            validMatches.where((m) => m.winner != null).toList();
        if (finalMatches.isNotEmpty) {
          final highestRoundMatch = finalMatches.reduce(
            (a, b) => a.round > b.round ? a : b,
          );
          tournamentWinner = highestRoundMatch.winner;
          print(
            '📊 Tournament: Fallback winner from highest round: ${tournamentWinner?.name}',
          );
        }
      }
    }

    _currentTournament = _currentTournament!.copyWith(
      matches: matches,
      winner: tournamentWinner,
      completedAt: allValidMatchesCompleted ? DateTime.now() : null,
    );

    await saveTournament(_currentTournament!);
    print('📊 Tournament: Saved with ${matches.length} matches');

    // Debug adicional: verificar partidos de la final
    final finalMatches =
        matches
            .where(
              (m) =>
                  m.round ==
                  matches.map((m) => m.round).reduce((a, b) => a > b ? a : b),
            )
            .toList();
    for (final match in finalMatches) {
      print(
        '📊 Tournament: Final match ${match.id} - Player1: ${match.player1?.name ?? "null"}, Player2: ${match.player2?.name ?? "null"}',
      );
    }
  }

  // Procesar partidos con bye que necesitan avanzar automáticamente
  void _processByeMatches(List<TournamentMatch> matches) {
    print('📊 Process Byes: Processing bye matches...');

    // Buscar partidos completados con winner que aún no han avanzado
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];

      // Si el partido está completado con un ganador
      if (match.status == MatchStatus.completed && match.winner != null) {
        print(
          '📊 Process Byes: Found completed match with winner: ${match.winner!.name} in round ${match.round}',
        );

        // Verificar si el ganador ya avanzó a la siguiente ronda
        final nextRound = match.round + 1;
        final hasAdvanced = matches.any(
          (m) =>
              m.round == nextRound &&
              (m.player1?.name == match.winner!.name ||
                  m.player2?.name == match.winner!.name),
        );

        print(
          '📊 Process Byes: Has ${match.winner!.name} advanced to round $nextRound? $hasAdvanced',
        );

        // Si no ha avanzado, avanzarlo ahora
        if (!hasAdvanced &&
            _currentTournament!.type == TournamentType.singleElimination) {
          print(
            '📊 Process Byes: Advancing ${match.winner!.name} to round $nextRound',
          );
          _advanceWinnerToNextRound(matches, i, match.winner!);
        }
      }
    }

    // Verificar si hay partidos que necesitan ser procesados múltiples veces
    // Esto es importante para asegurar que todos los byes se procesen correctamente
    bool hasChanges = true;
    int iterations = 0;
    while (hasChanges && iterations < 10) {
      // Prevenir loops infinitos
      hasChanges = false;
      iterations++;

      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];

        if (match.status == MatchStatus.completed && match.winner != null) {
          final nextRound = match.round + 1;
          final hasAdvanced = matches.any(
            (m) =>
                m.round == nextRound &&
                (m.player1?.name == match.winner!.name ||
                    m.player2?.name == match.winner!.name),
          );

          if (!hasAdvanced) {
            _advanceWinnerToNextRound(matches, i, match.winner!);
            hasChanges = true;
          }
        }
      }
    }

    if (iterations >= 10) {
      print(
        '📊 Process Byes: WARNING - Reached maximum iterations, stopping processing',
      );
    }
  }

  // Procesar byes en partidos de eliminación para torneos de fase de grupos
  void _processEliminationByes(List<TournamentMatch> matches) {
    print(
      '📊 Process Elimination Byes: Processing bye matches in elimination phase...',
    );

    // Solo procesar partidos de eliminación
    final eliminationMatches =
        matches.where((m) => m.isGroupStage == false).toList();

    for (int i = 0; i < eliminationMatches.length; i++) {
      final match = eliminationMatches[i];
      final matchIndex = matches.indexWhere((m) => m.id == match.id);

      // Si el partido está completado con un ganador
      if (match.status == MatchStatus.completed && match.winner != null) {
        final nextRound = match.round + 1;
        final hasAdvanced = eliminationMatches.any(
          (m) =>
              m.round == nextRound &&
              (m.player1?.name == match.winner!.name ||
                  m.player2?.name == match.winner!.name),
        );

        print(
          '📊 Process Elimination Byes: Has ${match.winner!.name} advanced to round $nextRound? $hasAdvanced',
        );

        // Si no ha avanzado, avanzarlo ahora
        if (!hasAdvanced) {
          print(
            '📊 Process Elimination Byes: Advancing ${match.winner!.name} to round $nextRound',
          );
          _advanceWinnerToNextRound(matches, matchIndex, match.winner!);
        }
      }
    }

    // Verificar si hay partidos que necesitan ser procesados múltiples veces
    bool hasChanges = true;
    int iterations = 0;
    while (hasChanges && iterations < 10) {
      hasChanges = false;
      iterations++;

      for (int i = 0; i < eliminationMatches.length; i++) {
        final match = eliminationMatches[i];
        final matchIndex = matches.indexWhere((m) => m.id == match.id);

        if (match.status == MatchStatus.completed && match.winner != null) {
          final nextRound = match.round + 1;
          final hasAdvanced = eliminationMatches.any(
            (m) =>
                m.round == nextRound &&
                (m.player1?.name == match.winner!.name ||
                    m.player2?.name == match.winner!.name),
          );

          if (!hasAdvanced) {
            _advanceWinnerToNextRound(matches, matchIndex, match.winner!);
            hasChanges = true;
          }
        }
      }
    }

    if (iterations >= 10) {
      print(
        '📊 Process Elimination Byes: WARNING - Reached maximum iterations, stopping processing',
      );
    }
  }

  // Procesar partido de fase de grupos
  void _processGroupStageMatch(
    List<TournamentMatch> matches,
    int currentMatchIndex,
    Player winner,
  ) {
    final currentMatch = matches[currentMatchIndex];

    print(
      '📊 Group Stage: Processing match result for ${winner.name} in group ${currentMatch.groupId}',
    );

    // Verificar si la fase de grupos está completa Y si aún no se han generado partidos de eliminación
    if (_isGroupStageComplete(matches) &&
        !_currentTournament!.groupStageCompleted!) {
      print(
        '📊 Group Stage: Group stage completed, generating elimination matches...',
      );
      _generateEliminationMatches(matches);
      _currentTournament = _currentTournament!.copyWith(
        matches: matches,
        groupStageCompleted: true,
      );
    }
  }

  // Verificar si la fase de grupos está completa
  bool _isGroupStageComplete(List<TournamentMatch> matches) {
    final groupMatches = matches.where((m) => m.isGroupStage == true).toList();
    final completedGroupMatches =
        groupMatches.where((m) => m.status == MatchStatus.completed).toList();

    print(
      '📊 Group Stage: Checking completion - ${completedGroupMatches.length}/${groupMatches.length} matches completed',
    );

    return completedGroupMatches.length == groupMatches.length;
  }

  // Generar partidos de eliminación después de completar fase de grupos
  void _generateEliminationMatches(List<TournamentMatch> matches) {
    final tournamentId = _currentTournament!.id;
    print('📊 Elimination Generation: Generating elimination matches...');

    // Verificar si ya existen partidos de eliminación
    final existingEliminationMatches =
        matches.where((m) => m.isGroupStage == false).toList();
    if (existingEliminationMatches.isNotEmpty) {
      print(
        '📊 Elimination Generation: Elimination matches already exist (${existingEliminationMatches.length} matches), skipping generation',
      );
      return;
    }

    // Obtener clasificados de cada grupo
    final qualifiedPlayers = _getQualifiedPlayers(matches);

    if (qualifiedPlayers.isEmpty) {
      print('📊 Elimination Generation: No qualified players found');
      return;
    }

    print(
      '📊 Elimination Generation: Qualified players: ${qualifiedPlayers.map((p) => p.name).join(", ")}',
    );

    // Generar partidos de eliminación
    int matchCounter = matches.length;

    // Para la primera ronda, asignar jugadores directamente
    final firstRoundMatches = (qualifiedPlayers.length / 2).ceil();

    print(
      '📊 Elimination Generation: First round needs $firstRoundMatches matches',
    );

    // Crear partidos de primera ronda con jugadores asignados
    for (int i = 0; i < firstRoundMatches; i++) {
      final player1Index = i * 2;
      final player2Index = (i * 2) + 1;

      Player? player1 =
          player1Index < qualifiedPlayers.length
              ? qualifiedPlayers[player1Index]
              : null;
      Player? player2 =
          player2Index < qualifiedPlayers.length
              ? qualifiedPlayers[player2Index]
              : null;

      matches.add(
        TournamentMatch(
          id: '${tournamentId}_elimination_round_1_match_$matchCounter',
          player1: player1,
          player2: player2,
          round: 1,
          matchNumber: matchCounter,
          status: MatchStatus.pending,
          groupId: 'elimination',
          isGroupStage: false,
        ),
      );

      print(
        '📊 Elimination Generation: First round match $matchCounter: ${player1?.name ?? "Bye"} vs ${player2?.name ?? "Bye"}',
      );
      matchCounter++;
    }

    // Generar partidos de rondas posteriores (sin jugadores asignados inicialmente)
    final totalRounds = (log(qualifiedPlayers.length) / log(2)).ceil();

    for (int round = 2; round <= totalRounds; round++) {
      final playersInThisRound =
          (qualifiedPlayers.length / (1 << (round - 1))).ceil();
      final matchesInThisRound = (playersInThisRound / 2).ceil();

      print(
        '📊 Elimination Generation: Round $round needs $matchesInThisRound matches',
      );

      for (int i = 0; i < matchesInThisRound; i++) {
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_elimination_round_${round}_match_$matchCounter',
            round: round,
            matchNumber: matchCounter,
            status: MatchStatus.pending,
            groupId: 'elimination',
            isGroupStage: false,
          ),
        );
        matchCounter++;
      }
    }

    // Actualizar el torneo con los nuevos partidos
    _currentTournament = _currentTournament!.copyWith(matches: matches);

    print(
      '📊 Elimination Generation: Generated ${matchCounter - matches.length} elimination matches total',
    );
  }

  // Limpiar partidos de eliminación duplicados
  void _cleanupDuplicateEliminationMatches(List<TournamentMatch> matches) {
    print('📊 Cleanup: Checking for duplicate elimination matches...');

    // Agrupar partidos de eliminación por ronda
    final eliminationMatches =
        matches.where((m) => m.isGroupStage == false).toList();
    final rounds = <int, List<TournamentMatch>>{};

    for (final match in eliminationMatches) {
      rounds.putIfAbsent(match.round, () => []).add(match);
    }

    // Verificar si hay duplicados en cada ronda
    for (final roundEntry in rounds.entries) {
      final round = roundEntry.key;
      final roundMatches = roundEntry.value;

      // Calcular cuántos partidos debería haber en esta ronda
      final qualifiedPlayers = _getQualifiedPlayers(
        matches.where((m) => m.isGroupStage == true).toList(),
      );
      final expectedMatches =
          round == 1
              ? (qualifiedPlayers.length / 2).ceil()
              : ((qualifiedPlayers.length / (1 << (round - 1))).ceil() / 2)
                  .ceil();

      print(
        '📊 Cleanup: Round $round has ${roundMatches.length} matches, expected $expectedMatches',
      );

      // Si hay más partidos de los esperados, eliminar los duplicados
      if (roundMatches.length > expectedMatches) {
        print(
          '📊 Cleanup: Removing ${roundMatches.length - expectedMatches} duplicate matches from round $round',
        );

        // Remover los partidos duplicados (mantener solo los primeros N esperados)
        final matchesToRemove = roundMatches.skip(expectedMatches).toList();

        // Remover los partidos duplicados de la lista principal
        for (final matchToRemove in matchesToRemove) {
          matches.removeWhere((m) => m.id == matchToRemove.id);
        }
      }
    }
  }

  // Obtener jugadores clasificados de cada grupo
  List<Player> _getQualifiedPlayers(List<TournamentMatch> matches) {
    final playersAdvancingPerGroup =
        _currentTournament!.playersAdvancingPerGroup ?? 2;

    // Agrupar partidos por grupo
    final groupMatches = <String, List<TournamentMatch>>{};
    for (final match in matches) {
      if (match.isGroupStage == true && match.groupId != null) {
        groupMatches.putIfAbsent(match.groupId!, () => []).add(match);
      }
    }

    final qualifiedPlayers = <Player>[];

    // Calcular clasificación para cada grupo
    for (final groupEntry in groupMatches.entries) {
      final groupId = groupEntry.key;
      final groupMatchesList = groupEntry.value;

      print('📊 Group Standings: Calculating standings for group $groupId');

      final groupStandings = _calculateGroupStandings(groupMatchesList);

      // Tomar los mejores N jugadores del grupo
      final topPlayers = groupStandings.take(playersAdvancingPerGroup).toList();

      print(
        '📊 Group Standings: Group $groupId qualified players: ${topPlayers.map((p) => p.name).join(", ")}',
      );

      qualifiedPlayers.addAll(topPlayers);
    }

    return qualifiedPlayers;
  }

  // Calcular tabla de posiciones de un grupo
  List<Player> _calculateGroupStandings(List<TournamentMatch> groupMatches) {
    final playerStats = <String, Map<String, dynamic>>{};

    // Inicializar estadísticas de cada jugador
    final allPlayers = <Player>{};
    for (final match in groupMatches) {
      if (match.player1 != null) allPlayers.add(match.player1!);
      if (match.player2 != null) allPlayers.add(match.player2!);
    }

    for (final player in allPlayers) {
      playerStats[player.name] = {
        'player': player,
        'wins': 0,
        'losses': 0,
        'matchesPlayed': 0,
      };
    }

    // Procesar resultados de partidos
    for (final match in groupMatches) {
      if (match.status == MatchStatus.completed && match.winner != null) {
        final winner = match.winner!;
        final loser =
            match.player1?.name == winner.name
                ? match.player2!
                : match.player1!;

        playerStats[winner.name]!['wins']++;
        playerStats[winner.name]!['matchesPlayed']++;

        playerStats[loser.name]!['losses']++;
        playerStats[loser.name]!['matchesPlayed']++;
      }
    }

    // Ordenar por victorias (descendente)
    final sortedPlayers =
        playerStats.values.toList()..sort((a, b) {
          final winsA = a['wins'] as int;
          final winsB = b['wins'] as int;

          if (winsA != winsB) {
            return winsB.compareTo(winsA); // Más victorias primero
          }

          // En caso de empate, menos derrotas primero
          final lossesA = a['losses'] as int;
          final lossesB = b['losses'] as int;
          return lossesA.compareTo(lossesB);
        });

    return sortedPlayers.map((stats) => stats['player'] as Player).toList();
  }

  // Verificar si la estructura del torneo es válida
  bool _isTournamentStructureValid(List<TournamentMatch> matches) {
    print('📊 Structure Validation: Checking tournament structure...');

    // Verificar que no hay partidos con un solo jugador en rondas > 1
    for (final match in matches) {
      if (match.status == MatchStatus.pending && match.round > 1) {
        if ((match.player1 != null && match.player2 == null) ||
            (match.player1 == null && match.player2 != null)) {
          print('📊 Structure Validation: Invalid match found: ${match.id}');
          return false;
        }
      }
    }

    // Verificar que todos los partidos completados tienen ganador
    for (final match in matches) {
      if (match.status == MatchStatus.completed && match.winner == null) {
        print(
          '📊 Structure Validation: Completed match without winner: ${match.id}',
        );
        return false;
      }
    }

    // Verificar que la final tiene ambos jugadores asignados
    final finalMatches =
        matches
            .where(
              (m) =>
                  m.round ==
                  matches.map((m) => m.round).reduce((a, b) => a > b ? a : b),
            )
            .toList();
    for (final match in finalMatches) {
      if (match.status == MatchStatus.pending &&
          (match.player1 == null || match.player2 == null)) {
        print(
          '📊 Structure Validation: Final match has missing opponent: ${match.id}',
        );
        return false;
      }
    }

    print('📊 Structure Validation: Tournament structure is valid');
    return true;
  }

  // Limpiar partidos que no se pueden completar
  void _cleanupInvalidMatches(List<TournamentMatch> matches) {
    print('📊 Cleanup: Cleaning up invalid matches...');

    // Buscar partidos que tienen solo un jugador y no pueden recibir más
    final invalidMatches = <TournamentMatch>[];

    for (final match in matches) {
      if (match.status == MatchStatus.pending) {
        // Si tiene un solo jugador y no es ronda 1 (bye), es inválido
        if ((match.player1 != null && match.player2 == null) ||
            (match.player1 == null && match.player2 != null)) {
          if (match.round > 1) {
            // Este partido no debería existir en rondas > 1
            print(
              '📊 Cleanup: Found invalid match ${match.id} in round ${match.round}',
            );
            invalidMatches.add(match);
          }
        }
      }
    }

    // Eliminar partidos inválidos
    for (final invalidMatch in invalidMatches) {
      matches.removeWhere((m) => m.id == invalidMatch.id);
      print('📊 Cleanup: Removed invalid match ${invalidMatch.id}');
    }

    if (invalidMatches.isNotEmpty) {
      print('📊 Cleanup: Removed ${invalidMatches.length} invalid matches');
    }
  }

  // Corregir problemas de estructura del torneo
  void _fixTournamentStructure(List<TournamentMatch> matches) {
    print('📊 Fix Structure: Fixing tournament structure issues...');

    // Procesar todos los byes pendientes
    _processByeMatches(matches);

    // Verificar y corregir partidos de la final
    final maxRound = matches
        .map((m) => m.round)
        .reduce((a, b) => a > b ? a : b);
    final finalMatches = matches.where((m) => m.round == maxRound).toList();

    for (final match in finalMatches) {
      if (match.status == MatchStatus.pending &&
          (match.player1 == null || match.player2 == null)) {
        print(
          '📊 Fix Structure: Found final match with missing opponent: ${match.id}',
        );

        // Buscar ganadores de la ronda anterior que no han avanzado
        final previousRound = maxRound - 1;
        final previousRoundMatches =
            matches
                .where(
                  (m) =>
                      m.round == previousRound &&
                      m.status == MatchStatus.completed &&
                      m.winner != null,
                )
                .toList();

        for (final prevMatch in previousRoundMatches) {
          final hasAdvanced = matches.any(
            (m) =>
                m.round == maxRound &&
                (m.player1?.name == prevMatch.winner!.name ||
                    m.player2?.name == prevMatch.winner!.name),
          );

          if (!hasAdvanced) {
            print(
              '📊 Fix Structure: Advancing ${prevMatch.winner!.name} to final',
            );
            final matchIndex = matches.indexWhere((m) => m.id == prevMatch.id);
            if (matchIndex != -1) {
              _advanceWinnerToNextRound(matches, matchIndex, prevMatch.winner!);
            }
          }
        }
      }
    }

    // Verificar que todos los partidos de la final tengan ambos jugadores
    for (final match in finalMatches) {
      if (match.status == MatchStatus.pending &&
          (match.player1 == null || match.player2 == null)) {
        print(
          '📊 Fix Structure: WARNING - Final match still has missing opponent after fix attempt',
        );
      }
    }

    print('📊 Fix Structure: Structure fixing completed');
  }

  // Avanzar ganador a la siguiente ronda
  Future<void> _advanceWinnerToNextRound(
    List<TournamentMatch> matches,
    int currentMatchIndex,
    Player winner,
  ) async {
    final currentMatch = matches[currentMatchIndex];
    final nextRound = currentMatch.round + 1;

    print(
      '📊 Advance Winner: ${winner.name} from round ${currentMatch.round} to round $nextRound',
    );

    // Encontrar todos los partidos de la siguiente ronda
    // Para torneos de fase de grupos, solo buscar partidos de eliminación
    var nextRoundMatches =
        matches
            .where(
              (m) =>
                  m.round == nextRound &&
                  (_currentTournament!.type != TournamentType.groupStage ||
                      m.isGroupStage == false),
            )
            .toList();

    // Si no hay partidos en la siguiente ronda, crear uno dinámicamente
    if (nextRoundMatches.isEmpty) {
      print(
        '📊 Advance Winner: No matches in round $nextRound, creating new match',
      );
      final newMatchId = '${_currentTournament!.id}_match_${matches.length}';
      final newMatch = TournamentMatch(
        id: newMatchId,
        round: nextRound,
        matchNumber: matches.length,
        status: MatchStatus.pending,
        groupId:
            _currentTournament!.type == TournamentType.groupStage
                ? 'elimination'
                : null,
        isGroupStage:
            _currentTournament!.type == TournamentType.groupStage
                ? false
                : null,
      );
      matches.add(newMatch);
      nextRoundMatches = [newMatch];
      print(
        '📊 Advance Winner: Created new match $newMatchId for round $nextRound',
      );
    }

    // Calcular la posición correcta en el bracket basado en la ronda actual
    final currentRoundMatches =
        matches.where((m) => m.round == currentMatch.round).toList();
    final currentMatchInRound = currentRoundMatches.indexWhere(
      (m) => m.id == currentMatch.id,
    );

    if (currentMatchInRound == -1) {
      print(
        '📊 Advance Winner: Current match not found in round ${currentMatch.round} matches',
      );
      return;
    }

    // Calcular qué partido de la siguiente ronda debe recibir este ganador
    // En un bracket de eliminación, cada partido de la ronda actual alimenta a un partido específico de la siguiente ronda
    final targetMatchIndex = (currentMatchInRound / 2).floor();

    if (targetMatchIndex >= nextRoundMatches.length) {
      print(
        '📊 Advance Winner: ERROR - Target match index $targetMatchIndex is out of bounds for next round matches (${nextRoundMatches.length})',
      );
      return;
    }

    final targetMatch = nextRoundMatches[targetMatchIndex];
    final targetMatchIndexInAll = matches.indexWhere(
      (m) => m.id == targetMatch.id,
    );

    if (targetMatchIndexInAll != -1) {
      // Determinar si este ganador debe ir a player1 o player2 basado en su posición en la ronda actual
      final isFirstPlayer = (currentMatchInRound % 2) == 0;

      if (isFirstPlayer) {
        // Este ganador viene del primer partido de la pareja, va a player1
        if (matches[targetMatchIndexInAll].player1 == null) {
          matches[targetMatchIndexInAll] = matches[targetMatchIndexInAll]
              .copyWith(player1: winner);
          print(
            '📊 Advance Winner: ${winner.name} assigned to player1 in match ${targetMatch.id}',
          );
        } else {
          print(
            '📊 Advance Winner: WARNING - Player1 already assigned in match ${targetMatch.id}, assigning to player2',
          );
          matches[targetMatchIndexInAll] = matches[targetMatchIndexInAll]
              .copyWith(player2: winner);
        }
      } else {
        // Este ganador viene del segundo partido de la pareja, va a player2
        if (matches[targetMatchIndexInAll].player2 == null) {
          matches[targetMatchIndexInAll] = matches[targetMatchIndexInAll]
              .copyWith(player2: winner);
          print(
            '📊 Advance Winner: ${winner.name} assigned to player2 in match ${targetMatch.id}',
          );
        } else {
          print(
            '📊 Advance Winner: WARNING - Player2 already assigned in match ${targetMatch.id}, assigning to player1',
          );
          matches[targetMatchIndexInAll] = matches[targetMatchIndexInAll]
              .copyWith(player1: winner);
        }
      }
    } else {
      print(
        '📊 Advance Winner: ERROR - Target match not found in matches list',
      );
    }

    // Actualizar el torneo actual con los cambios
    if (_currentTournament != null) {
      _currentTournament = _currentTournament!.copyWith(matches: matches);
      await saveTournament(_currentTournament!);
      print(
        '📊 Advance Winner: Tournament updated with ${matches.length} matches',
      );

      // Debug: verificar que el partido se actualizó correctamente
      final updatedMatch = _currentTournament!.matches.firstWhere(
        (m) => m.id == targetMatch.id,
        orElse:
            () => TournamentMatch(
              id: '',
              round: 0,
              matchNumber: 0,
              status: MatchStatus.pending,
            ),
      );
      if (updatedMatch.id.isNotEmpty) {
        print(
          '📊 Advance Winner: Final match state - Player1: ${updatedMatch.player1?.name ?? "null"}, Player2: ${updatedMatch.player2?.name ?? "null"}',
        );
      }
    }
  }

  // Determinar ganador del torneo
  Player? _determineTournamentWinner(List<TournamentMatch> matches) {
    print('📊 Determine Winner: Tournament type: ${_currentTournament!.type}');

    if (_currentTournament!.type == TournamentType.roundRobin) {
      // En round robin, contar victorias
      final Map<String, int> wins = {};
      for (var match in matches) {
        if (match.winner != null) {
          wins[match.winner!.name] = (wins[match.winner!.name] ?? 0) + 1;
        }
      }

      print('📊 Determine Winner: Round robin wins: $wins');
      if (wins.isEmpty) return null;

      final maxWins = wins.values.reduce(max);
      final winnersWithMaxWins =
          wins.entries.where((e) => e.value == maxWins).toList();

      // Si hay empate, no hay ganador único
      if (winnersWithMaxWins.length > 1) {
        print('📊 Determine Winner: Tie in round robin - no single winner');
        return null;
      }

      final winnerName = winnersWithMaxWins.first.key;
      return _currentTournament!.players.firstWhere(
        (p) => p.name == winnerName,
      );
    } else {
      // En eliminación, el ganador es el del último partido completado
      final completedMatches =
          matches
              .where(
                (m) => m.status == MatchStatus.completed && m.winner != null,
              )
              .toList();
      print(
        '📊 Determine Winner: Completed matches with winners: ${completedMatches.length}',
      );

      if (completedMatches.isEmpty) {
        print('📊 Determine Winner: No completed matches with winners found');
        return null;
      }

      // Buscar el partido de la ronda más alta (final)
      final finalMatch = completedMatches.reduce(
        (a, b) => a.round > b.round ? a : b,
      );
      print(
        '📊 Determine Winner: Final match: ${finalMatch.player1?.name} vs ${finalMatch.player2?.name}, Winner: ${finalMatch.winner?.name}, Round: ${finalMatch.round}',
      );

      // Verificar que el ganador esté en la ronda más alta posible
      final maxRound = matches.map((m) => m.round).reduce(max);
      if (finalMatch.round == maxRound) {
        print(
          '📊 Determine Winner: Final match is in the highest round (${finalMatch.round}) - valid winner',
        );
        return finalMatch.winner;
      } else {
        print(
          '📊 Determine Winner: WARNING - Final match is not in the highest round (${finalMatch.round} vs ${maxRound})',
        );
        return finalMatch.winner; // Aún así devolver el ganador
      }
    }
  }

  // Guardar torneo
  Future<void> saveTournament(Tournament tournament) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tournamentKey, jsonEncode(tournament.toJson()));

      // También guardar en historial
      await _addToHistory(tournament);

      print(
        '📊 Tournament: Successfully saved tournament with ${tournament.matches.length} matches',
      );
    } catch (e) {
      print('📊 Tournament: Error saving tournament: $e');
    }
  }

  // Agregar al historial
  Future<void> _addToHistory(Tournament tournament) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_tournamentsHistoryKey);

      List<Map<String, dynamic>> history = [];
      if (historyJson != null) {
        history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      }

      // Agregar solo si está completo
      if (tournament.isCompleted) {
        history.insert(0, tournament.toJson());

        // Mantener solo los últimos 20
        if (history.length > 20) {
          history = history.take(20).toList();
        }

        await prefs.setString(_tournamentsHistoryKey, jsonEncode(history));
      }
    } catch (e) {
      // Ignorar errores
    }
  }

  // Cargar torneo actual
  Future<void> loadCurrentTournament() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tournamentJson = prefs.getString(_tournamentKey);

      if (tournamentJson != null) {
        final decoded = jsonDecode(tournamentJson);
        _currentTournament = Tournament.fromJson(decoded);
        print(
          '📊 Tournament: Loaded tournament with ${_currentTournament!.matches.length} matches',
        );

        // Si está completo, agregarlo al historial pero mantenerlo para mostrar resultado
        if (_currentTournament!.isCompleted) {
          await _addToHistory(_currentTournament!);
          // No limpiar inmediatamente - mantener para mostrar resultado final
        }
      }
    } catch (e) {
      print('📊 Tournament: Error loading tournament: $e');
      _currentTournament = null;
    }
  }

  // Forzar recarga del torneo desde almacenamiento
  Future<void> forceReloadTournament() async {
    await loadCurrentTournament();
    print('📊 Tournament: Force reloaded tournament');
  }

  // Obtener historial de torneos
  Future<List<Tournament>> getTournamentsHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_tournamentsHistoryKey);

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        return decoded
            .map((t) => Tournament.fromJson(t as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Ignorar errores
    }
    return [];
  }

  // Cancelar torneo actual
  Future<void> cancelTournament() async {
    _currentTournament = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tournamentKey);
  }

  // Limpiar torneo completado (llamar cuando el usuario navegue de vuelta)
  Future<void> clearCompletedTournament() async {
    if (_currentTournament != null && _currentTournament!.isCompleted) {
      _currentTournament = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tournamentKey);
      } catch (e) {
        // Ignorar errores
      }
    }
  }

  // Obtener siguiente partido disponible
  TournamentMatch? getNextMatch() {
    if (_currentTournament == null) return null;

    try {
      // Buscar partidos que tienen ambos jugadores asignados
      final validMatches =
          _currentTournament!.matches
              .where(
                (m) =>
                    m.status == MatchStatus.pending &&
                    m.player1 != null &&
                    m.player2 != null,
              )
              .toList();

      if (validMatches.isNotEmpty) {
        return validMatches.first;
      }

      // Si no hay partidos válidos, verificar si hay partidos con un solo jugador que necesitan limpieza
      final invalidMatches =
          _currentTournament!.matches
              .where(
                (m) =>
                    m.status == MatchStatus.pending &&
                    ((m.player1 != null && m.player2 == null) ||
                        (m.player1 == null && m.player2 != null)) &&
                    m.round > 1,
              )
              .toList();

      if (invalidMatches.isNotEmpty) {
        print(
          '📊 GetNextMatch: Found ${invalidMatches.length} invalid matches, cleaning up...',
        );
        // Limpiar partidos inválidos
        final matches = List<TournamentMatch>.from(_currentTournament!.matches);
        _cleanupInvalidMatches(matches);
        _currentTournament = _currentTournament!.copyWith(matches: matches);
        saveTournament(_currentTournament!);

        // Intentar encontrar un partido válido después de la limpieza
        final validMatchesAfterCleanup =
            _currentTournament!.matches
                .where(
                  (m) =>
                      m.status == MatchStatus.pending &&
                      m.player1 != null &&
                      m.player2 != null,
                )
                .toList();

        if (validMatchesAfterCleanup.isNotEmpty) {
          return validMatchesAfterCleanup.first;
        }
      }

      return null;
    } catch (e) {
      print('📊 GetNextMatch: Error finding next match: $e');
      return null;
    }
  }

  // Obtener partidos de una ronda específica
  List<TournamentMatch> getMatchesByRound(int round) {
    if (_currentTournament == null) {
      print('📊 Service: No current tournament');
      return [];
    }
    final matches =
        _currentTournament!.matches.where((m) => m.round == round).toList();
    print('📊 Service: Round $round has ${matches.length} matches');
    return matches;
  }

  // Obtener número total de rondas
  int getTotalRounds() {
    if (_currentTournament == null) {
      print('📊 Service: No current tournament for total rounds');
      return 0;
    }
    final totalRounds = _currentTournament!.matches
        .map((m) => m.round)
        .reduce(max);
    print('📊 Service: Total rounds calculated: $totalRounds');
    return totalRounds;
  }

  // Verificar si el torneo está en un estado válido
  bool isTournamentValid() {
    if (_currentTournament == null) return false;

    final matches = _currentTournament!.matches;
    if (matches.isEmpty) return false;

    print('📊 Tournament Validation: Starting validation...');

    // Verificar que todos los partidos completados tengan ganador
    final completedMatches = matches.where(
      (m) => m.status == MatchStatus.completed,
    );
    for (final match in completedMatches) {
      if (match.winner == null) {
        print(
          '📊 Tournament Validation: ERROR - Match ${match.id} is completed but has no winner',
        );
        return false;
      }
    }

    // Verificar que no hay partidos con un solo jugador asignado (excepto byes en primera ronda)
    final pendingMatches = matches.where(
      (m) => m.status == MatchStatus.pending,
    );
    for (final match in pendingMatches) {
      if ((match.player1 != null && match.player2 == null) ||
          (match.player1 == null && match.player2 != null)) {
        // Esto está bien para byes en la primera ronda
        if (match.round == 1) {
          print(
            '📊 Tournament Validation: Match ${match.id} is a bye in round 1 - OK',
          );
          continue;
        }
        print(
          '📊 Tournament Validation: ERROR - Match ${match.id} in round ${match.round} has only one player assigned',
        );
        return false;
      }
    }

    // Verificar que el número de partidos por ronda es correcto
    final totalRounds = getTotalRounds();
    for (int round = 1; round <= totalRounds; round++) {
      final roundMatches = getMatchesByRound(round);
      final expectedMatches = _getExpectedMatchesForRound(round);

      if (roundMatches.length != expectedMatches) {
        print(
          '📊 Tournament Validation: WARNING - Round $round has ${roundMatches.length} matches, expected $expectedMatches',
        );
      }
    }

    print('📊 Tournament Validation: Tournament is valid');
    return true;
  }

  // Calcular el número esperado de partidos para una ronda
  int _getExpectedMatchesForRound(int round) {
    if (_currentTournament == null) return 0;

    int players = _currentTournament!.players.length;

    // Para cada ronda, el número de partidos es la mitad de los jugadores que avanzan
    for (int r = 1; r < round; r++) {
      players = (players / 2).ceil();
    }

    return (players / 2).ceil();
  }

  // Método de debugging para probar casos extremos
  void debugTournamentStructure() {
    if (_currentTournament == null) {
      print('📊 DEBUG: No current tournament');
      return;
    }

    print('📊 DEBUG: Tournament Structure Analysis');
    print('📊 DEBUG: Players: ${_currentTournament!.players.length}');
    print('📊 DEBUG: Type: ${_currentTournament!.type}');
    print('📊 DEBUG: Total matches: ${_currentTournament!.matches.length}');

    final totalRounds = getTotalRounds();
    print('📊 DEBUG: Total rounds: $totalRounds');

    for (int round = 1; round <= totalRounds; round++) {
      final roundMatches = getMatchesByRound(round);
      print('📊 DEBUG: Round $round: ${roundMatches.length} matches');

      for (int i = 0; i < roundMatches.length; i++) {
        final match = roundMatches[i];
        print(
          '📊 DEBUG:   Match $i: ${match.player1?.name ?? "TBD"} vs ${match.player2?.name ?? "TBD"} - Status: ${match.status} - Winner: ${match.winner?.name ?? "None"}',
        );
      }
    }

    // Verificar validez
    final isValid = isTournamentValid();
    print('📊 DEBUG: Tournament is valid: $isValid');

    // Verificar siguiente partido
    final nextMatch = getNextMatch();
    if (nextMatch != null) {
      print(
        '📊 DEBUG: Next match: ${nextMatch.player1?.name} vs ${nextMatch.player2?.name} (Round ${nextMatch.round})',
      );
    } else {
      print('📊 DEBUG: No next match available');
    }

    // Verificar si está completo
    print('📊 DEBUG: Tournament completed: ${_currentTournament!.isCompleted}');
    if (_currentTournament!.isCompleted) {
      print('📊 DEBUG: Winner: ${_currentTournament!.winner?.name ?? "None"}');
    }

    // Verificar problemas específicos
    final finalMatches =
        _currentTournament!.matches
            .where((m) => m.round == totalRounds)
            .toList();
    for (final match in finalMatches) {
      if (match.status == MatchStatus.pending &&
          (match.player1 == null || match.player2 == null)) {
        print(
          '📊 DEBUG: WARNING - Final match has missing opponent: ${match.id}',
        );
      }
    }
  }

  // Función para forzar la corrección de la estructura del torneo
  void forceFixTournamentStructure() {
    if (_currentTournament == null) {
      print('📊 Force Fix: No current tournament');
      return;
    }

    print('📊 Force Fix: Forcing tournament structure fix...');
    final matches = List<TournamentMatch>.from(_currentTournament!.matches);

    // Aplicar todas las correcciones
    _processByeMatches(matches);
    _fixTournamentStructure(matches);
    _cleanupInvalidMatches(matches);

    // Actualizar el torneo
    _currentTournament = _currentTournament!.copyWith(matches: matches);
    saveTournament(_currentTournament!);

    print('📊 Force Fix: Tournament structure fixed');
  }

  // Función para probar el torneo con diferentes cantidades de jugadores
  void testTournamentWithPlayerCount(int playerCount) {
    print('📊 Test: Testing tournament with $playerCount players');

    // Crear jugadores de prueba
    final testPlayers = List.generate(
      playerCount,
      (index) => Player(name: 'Player${index + 1}'),
    );

    try {
      // Crear torneo de prueba
      final testTournament = createTournament(
        name: 'Test Tournament $playerCount Players',
        players: testPlayers,
        type: TournamentType.singleElimination,
        pointsToWin: 11,
      );

      print(
        '📊 Test: Tournament created successfully with ${testTournament.matches.length} matches',
      );

      // Verificar estructura
      final isValid = isTournamentValid();
      print('📊 Test: Tournament is valid: $isValid');

      // Debug estructura
      debugTournamentStructure();
    } catch (e) {
      print(
        '📊 Test: ERROR - Failed to create tournament with $playerCount players: $e',
      );
    }
  }
}
