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
  }) {
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
    }

    final tournament = Tournament(
      id: tournamentId,
      name: name,
      players: players,
      type: type,
      pointsToWin: pointsToWin,
      matches: matches,
      createdAt: DateTime.now(),
    );

    _currentTournament = tournament;
    saveTournament(tournament);

    return tournament;
  }

  // Generar partidos para eliminación simple
  List<TournamentMatch> _generateSingleEliminationMatches(
    List<Player> players,
    String tournamentId,
  ) {
    final List<TournamentMatch> matches = [];
    final shuffledPlayers = List<Player>.from(players)..shuffle();

    // Calcular número de rondas necesarias (log2 de jugadores)
    final totalRounds = (log(players.length) / log(2)).ceil();

    int matchCounter = 0;

    // Primera ronda
    for (int i = 0; i < shuffledPlayers.length; i += 2) {
      if (i + 1 < shuffledPlayers.length) {
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_match_$matchCounter',
            player1: shuffledPlayers[i],
            player2: shuffledPlayers[i + 1],
            round: 1,
            matchNumber: matchCounter,
            status: MatchStatus.pending,
          ),
        );
        matchCounter++;
      } else {
        // Si hay número impar, el último pasa directo
        matches.add(
          TournamentMatch(
            id: '${tournamentId}_match_$matchCounter',
            player1: shuffledPlayers[i],
            player2: null,
            round: 1,
            matchNumber: matchCounter,
            status: MatchStatus.completed,
            winner: shuffledPlayers[i],
          ),
        );
        matchCounter++;
      }
    }

    // Rondas siguientes (placeholders)
    int playersInRound = (shuffledPlayers.length / 2).ceil();
    for (int round = 2; round <= totalRounds; round++) {
      playersInRound = (playersInRound / 2).ceil();
      for (int i = 0; i < playersInRound; i++) {
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

    // Si es eliminación simple, avanzar ganador al siguiente partido
    if (_currentTournament!.type == TournamentType.singleElimination) {
      _advanceWinnerToNextRound(matches, matchIndex, winner);
    }

    // Procesar automáticamente los byes ANTES de verificar si está completo
    _processByeMatches(matches);

    // Verificar si el torneo está completo
    final allCompleted = matches.every(
      (m) => m.status == MatchStatus.completed,
    );
    Player? tournamentWinner;

    print('📊 Tournament: Checking completion. All completed: $allCompleted');
    print('📊 Tournament: Total matches: ${matches.length}');
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      print(
        '📊 Tournament: Match $i: ${match.player1?.name} vs ${match.player2?.name} - Status: ${match.status} - Winner: ${match.winner?.name}',
      );
    }

    if (allCompleted) {
      tournamentWinner = _determineTournamentWinner(matches);
      print('📊 Tournament: Winner determined: ${tournamentWinner?.name}');
    }

    _currentTournament = _currentTournament!.copyWith(
      matches: matches,
      winner: tournamentWinner,
      completedAt: allCompleted ? DateTime.now() : null,
    );

    await saveTournament(_currentTournament!);
  }

  // Procesar partidos con bye que necesitan avanzar automáticamente
  void _processByeMatches(List<TournamentMatch> matches) {
    // Buscar partidos completados con winner que aún no han avanzado
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];

      // Si el partido está completado con un ganador
      if (match.status == MatchStatus.completed && match.winner != null) {
        // Verificar si el ganador ya avanzó a la siguiente ronda
        final nextRound = match.round + 1;
        final hasAdvanced = matches.any(
          (m) =>
              m.round == nextRound &&
              (m.player1?.name == match.winner!.name ||
                  m.player2?.name == match.winner!.name),
        );

        // Si no ha avanzado, avanzarlo ahora
        if (!hasAdvanced &&
            _currentTournament!.type == TournamentType.singleElimination) {
          _advanceWinnerToNextRound(matches, i, match.winner!);
        }
      }
    }
  }

  // Avanzar ganador a la siguiente ronda
  void _advanceWinnerToNextRound(
    List<TournamentMatch> matches,
    int currentMatchIndex,
    Player winner,
  ) {
    final currentMatch = matches[currentMatchIndex];
    final nextRound = currentMatch.round + 1;

    // Calcular la posición en el bracket (0 o 1 en la siguiente ronda)
    final currentPosition = currentMatchIndex % 2;
    final nextMatchPosition = currentPosition ~/ 2;

    // Encontrar el partido específico en la siguiente ronda
    final nextRoundMatches =
        matches
            .where(
              (m) => m.round == nextRound && m.status == MatchStatus.pending,
            )
            .toList();

    if (nextRoundMatches.length > nextMatchPosition) {
      final nextMatch = nextRoundMatches[nextMatchPosition];
      final nextMatchIndex = matches.indexWhere((m) => m.id == nextMatch.id);

      // Asignar según la posición en el partido actual
      if (currentPosition == 0) {
        // Jugador de la izquierda va a player1
        if (nextMatch.player1 == null) {
          matches[nextMatchIndex] = nextMatch.copyWith(player1: winner);
        }
      } else {
        // Jugador de la derecha va a player2
        if (nextMatch.player2 == null) {
          matches[nextMatchIndex] = nextMatch.copyWith(player2: winner);
        }
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
          matches.where((m) => m.status == MatchStatus.completed).toList();
      print(
        '📊 Determine Winner: Completed matches: ${completedMatches.length}',
      );

      if (completedMatches.isEmpty) {
        print('📊 Determine Winner: No completed matches found');
        return null;
      }

      // Buscar el partido de la ronda más alta (final)
      final finalMatch = completedMatches.reduce(
        (a, b) => a.round > b.round ? a : b,
      );
      print(
        '📊 Determine Winner: Final match: ${finalMatch.player1?.name} vs ${finalMatch.player2?.name}, Winner: ${finalMatch.winner?.name}, Round: ${finalMatch.round}',
      );

      return finalMatch.winner;
    }
  }

  // Guardar torneo
  Future<void> saveTournament(Tournament tournament) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tournamentKey, jsonEncode(tournament.toJson()));

      // También guardar en historial
      await _addToHistory(tournament);
    } catch (e) {
      // Ignorar errores
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

        // Si está completo, agregarlo al historial pero mantenerlo para mostrar resultado
        if (_currentTournament!.isCompleted) {
          await _addToHistory(_currentTournament!);
          // No limpiar inmediatamente - mantener para mostrar resultado final
        }
      }
    } catch (e) {
      _currentTournament = null;
    }
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
      return _currentTournament!.matches.firstWhere(
        (m) =>
            m.status == MatchStatus.pending &&
            m.player1 != null &&
            m.player2 != null,
      );
    } catch (e) {
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
}
