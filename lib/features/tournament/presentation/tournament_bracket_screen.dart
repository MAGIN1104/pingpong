import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/entities/tournament.dart';
import '../data/tournament_service.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/domain/entities/player.dart';
import '../../../core/utils/avatar_helper.dart';

class TournamentBracketScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentBracketScreen({super.key, required this.tournament});

  @override
  State<TournamentBracketScreen> createState() =>
      _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  final _tournamentService = TournamentService();
  late Tournament _tournament;
  bool _showDetailedView = false;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;

    // Permitir todas las orientaciones
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Limpiar torneo completado cuando se sale de la pantalla
    if (_tournament.isCompleted) {
      _tournamentService.clearCompletedTournament();
    }
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _refreshTournament() async {
    try {
      // Recargar el torneo desde el almacenamiento
      await _tournamentService.loadCurrentTournament();

      // Actualizar el estado local
      if (_tournamentService.currentTournament != null) {
        setState(() {
          _tournament = _tournamentService.currentTournament!;
        });

        // Mostrar confirmación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Torneo actualizado'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Si no hay torneo, volver al inicio
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el torneo'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playMatch(TournamentMatch match) async {
    if (match.player1 == null || match.player2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este partido aún no tiene jugadores asignados'),
        ),
      );
      return;
    }

    // Navegar a la pantalla de juego en modo torneo
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => GameScreen(
              participantes: [match.player1!.name, match.player2!.name],
              modalidad: _tournament.pointsToWin,
              isTournamentMode: true,
              tournamentMatchId: match.id,
            ),
      ),
    );

    // Si hay resultado, actualizar el partido en el torneo
    if (result != null && mounted) {
      print('📊 Bracket: Resultado recibido: $result');

      final winnerName = result['winner'] as String;
      final score1 = result['score1'] as int;
      final score2 = result['score2'] as int;

      print('📊 Bracket: Ganador: $winnerName, Score: $score1-$score2');

      // Determinar el ganador como Player
      final winner =
          match.player1!.name == winnerName ? match.player1! : match.player2!;

      print('📊 Bracket: Actualizando partido ${match.id}');

      // Actualizar el resultado en el servicio
      await _tournamentService.updateMatchResult(
        matchId: match.id,
        winner: winner,
        score1: score1,
        score2: score2,
      );

      print('📊 Bracket: Partido actualizado correctamente');

      // Refrescar torneo después de actualizar
      await _refreshTournament();

      // Mostrar notificación de progreso
      if (mounted) {
        final pendingMatches =
            _tournament.matches
                .where(
                  (m) =>
                      m.status == MatchStatus.pending &&
                      m.player1 != null &&
                      m.player2 != null,
                )
                .length;

        final message =
            pendingMatches > 0
                ? '✅ $winnerName avanza • Quedan $pendingMatches partidos'
                : '🏆 ¡Torneo completado! Ver campeón arriba';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                pendingMatches > 0 ? Colors.green : Colors.amber.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action:
                pendingMatches > 0
                    ? SnackBarAction(
                      label: 'SIGUIENTE',
                      textColor: Colors.white,
                      onPressed: () {
                        final nextMatch = _getNextMatch();
                        if (nextMatch != null) {
                          _playMatch(nextMatch);
                        }
                      },
                    )
                    : null,
          ),
        );
      }
    }
  }

  Widget _buildTournamentHeader(ColorScheme colorScheme) {
    final completedMatches =
        _tournament.matches
            .where((m) => m.status == MatchStatus.completed)
            .length;
    final totalMatches = _tournament.matches.length;
    final pendingMatches =
        _tournament.matches
            .where((m) => m.status == MatchStatus.pending)
            .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat(
            'Jugadores',
            '${_tournament.players.length}',
            Icons.people,
          ),
          _buildHeaderStat(
            'Completados',
            '$completedMatches/$totalMatches',
            Icons.check_circle_outline,
          ),
          _buildHeaderStat('Por Jugar', '$pendingMatches', Icons.sports_tennis),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del Torneo',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
              Text(
                '${(_tournament.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _tournament.progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketView(ColorScheme colorScheme) {
    return Stack(
      children: [
        // Vista principal
        if (_showDetailedView)
          _buildDetailedView(colorScheme)
        else
          _buildSmartView(colorScheme),

        // Toggle de vista en la esquina superior derecha
        Positioned(
          top: 8,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed:
                  () => setState(() => _showDetailedView = !_showDetailedView),
              icon: Icon(
                _showDetailedView ? Icons.view_list : Icons.dashboard,
                color: colorScheme.primary,
                size: 20,
              ),
              tooltip: _showDetailedView ? 'Vista compacta' : 'Vista detallada',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartView(ColorScheme colorScheme) {
    final nextMatch = _getNextMatch();
    final completedMatches =
        _tournament.matches
            .where((m) => m.status == MatchStatus.completed)
            .length;
    final totalMatches = _tournament.matches.length;
    final pendingMatches =
        _tournament.matches
            .where((m) => m.status == MatchStatus.pending)
            .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        60,
        16,
        80,
      ), // Espacio para toggle y FAB
      children: [
        // Información rápida del torneo
        _buildQuickTournamentInfo(
          colorScheme,
          completedMatches,
          totalMatches,
          pendingMatches,
        ),

        const SizedBox(height: 16),

        // Partido actual destacado
        if (nextMatch != null) ...[
          _buildCurrentMatchCard(nextMatch, colorScheme),
          const SizedBox(height: 16),
        ],

        // Próximos partidos (máximo 2)
        _buildUpcomingMatches(colorScheme),

        // Estadísticas de jugadores
        _buildPlayerStats(colorScheme),
      ],
    );
  }

  Widget _buildDetailedView(ColorScheme colorScheme) {
    if (_tournament.type == TournamentType.roundRobin)
      return _buildRoundRobinView(colorScheme);
    else
      return _buildEliminationBracketView(colorScheme);
  }

  Widget _buildRoundRobinView(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        60,
        16,
        80,
      ), // Espacio para toggle y FAB
      itemCount: _tournament.matches.length,
      itemBuilder: (context, index) {
        final match = _tournament.matches[index];
        return _buildMatchCard(match, colorScheme);
      },
    );
  }

  Widget _buildEliminationBracketView(ColorScheme colorScheme) {
    final totalRounds = _tournamentService.getTotalRounds();
    print('📊 Bracket: Total rounds: $totalRounds');
    print('📊 Bracket: Total matches: ${_tournament.matches.length}');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        60,
        16,
        80,
      ), // Espacio para toggle y FAB
      itemCount: totalRounds,
      itemBuilder: (context, roundIndex) {
        final round = roundIndex + 1;
        final roundMatches = _tournamentService.getMatchesByRound(round);
        print('📊 Bracket: Round $round has ${roundMatches.length} matches');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getRoundName(round, totalRounds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${roundMatches.where((m) => m.status == MatchStatus.completed).length}/${roundMatches.length}',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            ...roundMatches.map((match) => _buildMatchCard(match, colorScheme)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getRoundName(int round, int totalRounds) {
    if (round == totalRounds) return 'FINAL';
    if (round == totalRounds - 1) return 'SEMIFINAL';
    if (round == totalRounds - 2) return 'CUARTOS';
    return 'RONDA $round';
  }

  Widget _buildMatchCard(TournamentMatch match, ColorScheme colorScheme) {
    final canPlay =
        match.status == MatchStatus.pending &&
        match.player1 != null &&
        match.player2 != null;

    final isNextMatch = _getNextMatch()?.id == match.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation:
          match.status == MatchStatus.completed ? 1 : (isNextMatch ? 6 : 2),
      child: InkWell(
        onTap: canPlay ? () => _playMatch(match) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  match.status == MatchStatus.completed
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : isNextMatch
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
              width:
                  match.status == MatchStatus.completed
                      ? 1
                      : (isNextMatch ? 3 : 2),
            ),
            color:
                match.status == MatchStatus.completed
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : isNextMatch
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
            boxShadow:
                isNextMatch
                    ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              // Player 1
              Expanded(
                child: _buildPlayerInfo(
                  match.player1,
                  match.score1,
                  match.winner == match.player1,
                  colorScheme,
                ),
              ),

              // VS o resultado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Badge "SIGUIENTE" si es el próximo partido
                    if (isNextMatch) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SIGUIENTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      match.status == MatchStatus.completed ? 'VS' : 'vs',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize:
                            match.status == MatchStatus.completed ? 12 : 16,
                        color:
                            match.status == MatchStatus.completed
                                ? colorScheme.outline
                                : colorScheme.primary,
                      ),
                    ),
                    if (canPlay) ...[
                      const SizedBox(height: 4),
                      Icon(
                        Icons.play_circle_filled,
                        color:
                            isNextMatch
                                ? colorScheme.primary
                                : colorScheme.primary.withValues(alpha: 0.7),
                        size: isNextMatch ? 28 : 20,
                      ),
                    ],
                  ],
                ),
              ),

              // Player 2
              Expanded(
                child: _buildPlayerInfo(
                  match.player2,
                  match.score2,
                  match.winner == match.player2,
                  colorScheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(
    Player? player,
    int? score,
    bool isWinner,
    ColorScheme colorScheme,
  ) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Por definir',
            style: TextStyle(
              color: colorScheme.outline,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isWinner
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isWinner
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          AvatarHelper.buildAvatarWidget(
            avatarId: player.avatarId,
            size: 28,
            showBorder: true,
            borderColor: isWinner ? colorScheme.primary : null,
          ),
          const SizedBox(width: 6),
          // Nombre y score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (score != null)
                  Text(
                    '$score pts',
                    style: TextStyle(fontSize: 10, color: colorScheme.outline),
                  ),
              ],
            ),
          ),
          // Icono de ganador
          if (isWinner)
            Icon(Icons.emoji_events, color: colorScheme.primary, size: 18),
        ],
      ),
    );
  }

  TournamentMatch? _getNextMatch() {
    return _tournamentService.getNextMatch();
  }

  Widget _buildQuickTournamentInfo(
    ColorScheme colorScheme,
    int completed,
    int total,
    int pending,
  ) {
    final progress = total > 0 ? (completed / total) : 0.0;
    final estimatedTime = _calculateEstimatedTime(pending);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: colorScheme.primary.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progreso del Torneo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surface.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickStat(
                'Completados',
                '$completed/$total',
                Icons.check_circle,
                colorScheme,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                'Pendientes',
                '$pending',
                Icons.sports_tennis,
                colorScheme,
              ),
              if (estimatedTime.isNotEmpty) ...[
                const SizedBox(width: 16),
                _buildQuickStat(
                  'Tiempo est.',
                  estimatedTime,
                  Icons.access_time,
                  colorScheme,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onPrimaryContainer),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentMatchCard(
    TournamentMatch match,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Partido Actual',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPlayerInfo(
                  match.player1,
                  match.score1,
                  match.winner == match.player1,
                  colorScheme,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.sports_tennis,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPlayerInfo(
                  match.player2,
                  match.score2,
                  match.winner == match.player2,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatches(ColorScheme colorScheme) {
    final upcomingMatches =
        _tournament.matches
            .where(
              (m) =>
                  m.status == MatchStatus.pending &&
                  m.id != _getNextMatch()?.id,
            )
            .take(2)
            .toList();

    if (upcomingMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos Partidos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...upcomingMatches.map(
          (match) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.player1?.name ?? 'Por definir',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  ' vs ',
                  style: TextStyle(fontSize: 11, color: colorScheme.outline),
                ),
                Expanded(
                  child: Text(
                    match.player2?.name ?? 'Por definir',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerStats(ColorScheme colorScheme) {
    final playerWins = <String, int>{};
    for (var match in _tournament.matches) {
      if (match.winner != null) {
        playerWins[match.winner!.name] =
            (playerWins[match.winner!.name] ?? 0) + 1;
      }
    }

    if (playerWins.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Victorias por Jugador',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                (playerWins.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(3)
                    .map((entry) {
                      final player = _tournament.players.firstWhere(
                        (p) => p.name == entry.key,
                        orElse:
                            () => Player(name: entry.key, avatarId: 'default'),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            AvatarHelper.buildAvatarWidget(
                              avatarId: player.avatarId,
                              size: 20,
                              showBorder: true,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
          ),
        ),
      ],
    );
  }

  String _calculateEstimatedTime(int pendingMatches) {
    if (pendingMatches <= 0) return '';

    // Estimación: 5 minutos por partido en promedio
    final totalMinutes = pendingMatches * 5;
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Cancelar Torneo?'),
            content: const Text(
              'Se perderá todo el progreso del torneo. Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Sí, Cancelar'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _tournamentService.cancelTournament();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mostrar pantalla de ganador si el torneo está completo
    if (_tournament.isCompleted) {
      if (_tournament.winner != null) {
        return _buildWinnerScreen(colorScheme);
      } else {
        return _buildTieScreen(colorScheme);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTournament,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(context),
            tooltip: 'Cancelar torneo',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTournamentHeader(colorScheme),
          _buildProgressBar(colorScheme),
          Expanded(child: _buildBracketView(colorScheme)),
        ],
      ),
      floatingActionButton:
          _getNextMatch() != null
              ? FloatingActionButton.extended(
                onPressed: () => _playMatch(_getNextMatch()!),
                icon: const Icon(Icons.sports_tennis, color: Colors.white),
                label: const Text(
                  'Siguiente Partido',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              )
              : null,
    );
  }

  Widget _buildWinnerScreen(ColorScheme colorScheme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneo Completado', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 80, color: colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  'CAMPEÓN',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                AvatarHelper.buildAvatarWidget(
                  avatarId: _tournament.winner!.avatarId,
                  size: 70,
                  showBorder: true,
                ),
                const SizedBox(height: 16),
                Text(
                  _tournament.winner!.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home, size: 20),
                  label: const Text(
                    'Volver al Inicio',
                    style: TextStyle(fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTieScreen(ColorScheme colorScheme) {
    // Calcular estadísticas de victorias
    final Map<String, int> wins = {};
    for (var match in _tournament.matches) {
      if (match.winner != null) {
        wins[match.winner!.name] = (wins[match.winner!.name] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneo Completado'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, size: 60, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                'EMPATE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Todos los jugadores tienen ${wins.values.first} victoria${wins.values.first != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Resultados:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Mostrar estadísticas de cada jugador
              ...wins.entries.map((entry) {
                final player = _tournament.players.firstWhere(
                  (p) => p.name == entry.key,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      AvatarHelper.buildAvatarWidget(
                        avatarId: player.avatarId,
                        size: 32,
                        showBorder: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.value} victoria${entry.value != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.home, size: 18),
                label: const Text(
                  'Volver al Inicio',
                  style: TextStyle(fontSize: 14),
                ),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
