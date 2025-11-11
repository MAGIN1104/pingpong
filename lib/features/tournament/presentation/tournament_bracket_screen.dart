import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/entities/tournament.dart';
import '../data/tournament_service.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/domain/entities/player.dart';
import '../../setup/presentation/setup_screen.dart';

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
  bool _hasShownChampionDialog = false;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _hasShownChampionDialog = false;

    // Forzar orientación vertical para evitar problemas de rotación
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Widget _buildOverviewSection(ColorScheme colorScheme, TextTheme textTheme) {
    final completedMatches =
        _tournament.matches
            .where((m) => m.status == MatchStatus.completed)
            .length;
    final totalMatches = _tournament.matches.length;
    final pendingMatches =
        _tournament.matches
            .where((m) => m.status == MatchStatus.pending)
            .length;
    final progress =
        totalMatches == 0 ? 0.0 : (completedMatches / totalMatches);
    final nextMatch = _getNextMatch();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header compacto
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tournament.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildOverviewPill(
                            colorScheme,
                            icon: Icons.emoji_events_rounded,
                            label: _localizedTournamentType(),
                          ),
                          _buildOverviewPill(
                            colorScheme,
                            icon: Icons.sports_score_rounded,
                            label: '${_tournament.pointsToWin} pts',
                          ),
                          _buildOverviewPill(
                            colorScheme,
                            icon: Icons.people_alt_rounded,
                            label: '${_tournament.players.length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (nextMatch != null)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Continuar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _playMatch(nextMatch),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Métricas compactas
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    colorScheme,
                    textTheme,
                    label: 'Completados',
                    value: '$completedMatches',
                    icon: Icons.check_circle_rounded,
                    accent: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    colorScheme,
                    textTheme,
                    label: 'Pendientes',
                    value: '$pendingMatches',
                    icon: Icons.pending_actions_rounded,
                    accent: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    colorScheme,
                    textTheme,
                    label: 'Total',
                    value: '$totalMatches',
                    icon: Icons.bar_chart_rounded,
                    accent: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progreso compacto
            Row(
              children: [
                Text(
                  'Progreso',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewPill(
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const Spacer(),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
      await _tournamentService.forceReloadTournament();

      // Actualizar el estado local
      if (_tournamentService.currentTournament != null) {
        final updatedTournament = _tournamentService.currentTournament!;
        final wasCompleted = _tournament.isCompleted;

        setState(() {
          _tournament = updatedTournament;
          // Si el torneo se acaba de completar, resetear el flag del diálogo
          if (updatedTournament.isCompleted &&
              updatedTournament.winner != null &&
              !wasCompleted) {
            _hasShownChampionDialog = false;
          } else if (!updatedTournament.isCompleted) {
            _hasShownChampionDialog = false;
          }
        });
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

    // Establecer orientación landscape ANTES de navegar
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Esperar un frame para asegurar que la orientación se aplique
    await Future.delayed(const Duration(milliseconds: 50));

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

      // Verificar si el torneo está completo después de actualizar
      if (mounted) {
        final updatedTournament = _tournamentService.currentTournament;
        if (updatedTournament != null) {
          setState(() {
            _tournament = updatedTournament;
            // Si el torneo está completo, resetear el flag del diálogo para mostrarlo
            if (updatedTournament.isCompleted &&
                updatedTournament.winner != null) {
              _hasShownChampionDialog = false;
            }
          });

          // Si el torneo está completo, mostrar el diálogo del ganador
          if (updatedTournament.isCompleted &&
              updatedTournament.winner != null) {
            // Esperar un momento para que el estado se actualice
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              _maybeShowChampionDialog(
                Theme.of(context).colorScheme,
                Theme.of(context).textTheme,
              );
            }
          }
        }

        // Mostrar notificación de progreso
        final pendingMatches =
            _tournament.matches
                .where(
                  (m) =>
                      m.status == MatchStatus.pending &&
                      m.player1 != null &&
                      m.player2 != null,
                )
                .length;

        final isCompleted =
            _tournament.isCompleted && _tournament.winner != null;
        final message =
            isCompleted
                ? '🏆 ¡Torneo completado!'
                : pendingMatches > 0
                ? '✅ $winnerName avanza • Quedan $pendingMatches partidos'
                : '✅ $winnerName avanza';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                isCompleted
                    ? Colors.amber.shade700
                    : pendingMatches > 0
                    ? Colors.green
                    : Colors.blue,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action:
                !isCompleted && pendingMatches > 0
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

  Widget _buildBracketView(ColorScheme colorScheme, TextTheme textTheme) {
    return Stack(
      children: [
        // Vista principal
        if (_showDetailedView)
          _buildDetailedView(colorScheme)
        else
          _buildSmartView(colorScheme, textTheme),

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

  Widget _buildSmartView(ColorScheme colorScheme, TextTheme textTheme) {
    final nextMatch = _getNextMatch();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Partido actual destacado
        if (nextMatch != null) ...[
          _buildCurrentMatchCard(nextMatch, colorScheme, textTheme),
          const SizedBox(height: 12),
        ],

        // Próximos partidos
        _buildUpcomingMatches(colorScheme),
      ],
    );
  }

  Widget _buildDetailedView(ColorScheme colorScheme) {
    if (_tournament.type == TournamentType.roundRobin)
      return _buildRoundRobinView(colorScheme);
    else if (_tournament.type == TournamentType.groupStage)
      return _buildGroupStageView(colorScheme);
    else
      return _buildEliminationBracketView(colorScheme);
  }

  Widget _buildRoundRobinView(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    // Agrupar partidos por ronda
    final rounds = <int, List<TournamentMatch>>{};
    for (final match in _tournament.matches) {
      rounds.putIfAbsent(match.round, () => []).add(match);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 80),
      children: [
        // Información de participantes compacta
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participantes',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    _tournament.players.map((player) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              player.name,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        // Partidos por ronda
        ...rounds.entries.map((roundEntry) {
          final round = roundEntry.key;
          final roundMatches = roundEntry.value;
          final completedInRound =
              roundMatches
                  .where((m) => m.status == MatchStatus.completed)
                  .length;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.roundabout_right_rounded,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ronda $round',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedInRound/${roundMatches.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...roundMatches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildMatchCard(match, colorScheme),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGroupStageView(ColorScheme colorScheme) {
    // Separar partidos de grupos y eliminación
    final groupMatches =
        _tournament.matches.where((m) => m.isGroupStage == true).toList();
    final eliminationMatches =
        _tournament.matches.where((m) => m.isGroupStage == false).toList();

    print(
      '📊 Group Stage View: ${groupMatches.length} group matches, ${eliminationMatches.length} elimination matches',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 80),
      children: [
        // Fase de Grupos
        if (groupMatches.isNotEmpty) ...[
          _buildGroupStageSection(groupMatches, colorScheme),
          const SizedBox(height: 16),
          _buildGroupStandings(groupMatches, colorScheme),
          const SizedBox(height: 24),
        ],

        // Fase de Eliminación (si existe)
        if (eliminationMatches.isNotEmpty) ...[
          _buildEliminationSection(eliminationMatches, colorScheme),
        ],
      ],
    );
  }

  Widget _buildGroupStageSection(
    List<TournamentMatch> groupMatches,
    ColorScheme colorScheme,
  ) {
    final textTheme = Theme.of(context).textTheme;
    // Agrupar partidos por grupo
    final groups = <String, List<TournamentMatch>>{};
    for (final match in groupMatches) {
      if (match.groupId != null) {
        groups.putIfAbsent(match.groupId!, () => []).add(match);
      }
    }

    // Obtener participantes por grupo
    final playersByGroup = <String, List<Player>>{};
    for (final groupEntry in groups.entries) {
      final groupId = groupEntry.key;
      final players = <Player>{};
      for (final match in groupEntry.value) {
        if (match.player1 != null) players.add(match.player1!);
        if (match.player2 != null) players.add(match.player2!);
      }
      playersByGroup[groupId] = players.toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.group_work_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'FASE DE GRUPOS',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar cada grupo
        ...groups.entries.map((groupEntry) {
          final groupId = groupEntry.key;
          final groupMatches = groupEntry.value;
          final completedInGroup =
              groupMatches
                  .where((m) => m.status == MatchStatus.completed)
                  .length;
          final groupPlayers = playersByGroup[groupId] ?? [];
          final progress =
              groupMatches.isEmpty
                  ? 0.0
                  : completedInGroup / groupMatches.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del grupo compacto
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'GRUPO $groupId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$completedInGroup/${groupMatches.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Participantes compactos
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            groupPlayers.map((player) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      player.name,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 8),
                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Partidos del grupo
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partidos:',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...groupMatches.map(
                        (match) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildMatchCard(match, colorScheme),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEliminationSection(
    List<TournamentMatch> eliminationMatches,
    ColorScheme colorScheme,
  ) {
    // Agrupar por ronda y ordenar
    final rounds = <int, List<TournamentMatch>>{};
    for (final match in eliminationMatches) {
      rounds.putIfAbsent(match.round, () => []).add(match);
    }
    final sortedRounds = rounds.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: colorScheme.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'FASE DE ELIMINACIÓN',
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar cada ronda
        ...sortedRounds.map((round) {
          final roundMatches = rounds[round] ?? [];
          final completedInRound =
              roundMatches
                  .where((m) => m.status == MatchStatus.completed)
                  .length;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de la ronda compacto
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getRoundName(round, sortedRounds.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedInRound/${roundMatches.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Partidos de la ronda
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children:
                        roundMatches.map((match) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildMatchCard(match, colorScheme),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGroupStandings(
    List<TournamentMatch> groupMatches,
    ColorScheme colorScheme,
  ) {
    // Agrupar partidos por grupo
    final groups = <String, List<TournamentMatch>>{};
    for (final match in groupMatches) {
      if (match.groupId != null) {
        groups.putIfAbsent(match.groupId!, () => []).add(match);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.table_chart, color: colorScheme.onSurface, size: 18),
              const SizedBox(width: 8),
              Text(
                'TABLA DE POSICIONES',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mostrar tabla de cada grupo
        ...groups.entries.map((groupEntry) {
          final groupId = groupEntry.key;
          final groupMatches = groupEntry.value;
          final standings = _calculateGroupStandings(groupMatches);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del grupo
              Text(
                'GRUPO $groupId',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Tabla de posiciones
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Encabezados
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Posición
                          SizedBox(
                            width: 32,
                            child: Text(
                              'Pos',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                          // Jugador
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Jugador',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                          // Victorias
                          SizedBox(
                            width: 32,
                            child: Text(
                              'V',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Derrotas
                          SizedBox(
                            width: 32,
                            child: Text(
                              'D',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Puntos
                          SizedBox(
                            width: 36,
                            child: Text(
                              'Pts',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filas de jugadores
                    ...standings.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      final stats = _getPlayerStats(player, groupMatches);
                      final isQualified =
                          index < (_tournament.playersAdvancingPerGroup ?? 2);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              isQualified
                                  ? LinearGradient(
                                    colors: [
                                      colorScheme.primaryContainer.withValues(
                                        alpha: 0.4,
                                      ),
                                      colorScheme.primaryContainer.withValues(
                                        alpha: 0.2,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : LinearGradient(
                                    colors: [
                                      Colors.white,
                                      colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(
                                alpha: 0.05,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Posición
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${index + 1}°',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color:
                                      isQualified
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withValues(
                                            alpha: 0.8,
                                          ),
                                ),
                              ),
                            ),

                            // Nombre con indicador de posición
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  // Indicador de posición
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color:
                                          isQualified
                                              ? colorScheme.primary.withValues(
                                                alpha: 0.1,
                                              )
                                              : colorScheme
                                                  .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            isQualified
                                                ? colorScheme.primary
                                                    .withValues(alpha: 0.3)
                                                : colorScheme.outline
                                                    .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color:
                                              isQualified
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface
                                                      .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: TextStyle(
                                        fontWeight:
                                            isQualified
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                        fontSize: 13,
                                        color:
                                            isQualified
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Victorias
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${stats['wins']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Derrotas
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${stats['losses']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Puntos (victorias * 3)
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${stats['wins'] * 3}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Map<String, dynamic> _getPlayerStats(
    Player player,
    List<TournamentMatch> groupMatches,
  ) {
    int wins = 0;
    int losses = 0;

    for (final match in groupMatches) {
      if (match.status == MatchStatus.completed && match.winner != null) {
        if (match.winner!.name == player.name) {
          wins++;
        } else if ((match.player1?.name == player.name ||
            match.player2?.name == player.name)) {
          losses++;
        }
      }
    }

    return {'wins': wins, 'losses': losses, 'matchesPlayed': wins + losses};
  }

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

  Widget _buildEliminationBracketView(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final totalRounds = _tournamentService.getTotalRounds();
    print('📊 Bracket: Total rounds: $totalRounds');
    print('📊 Bracket: Total matches: ${_tournament.matches.length}');

    // Obtener todos los jugadores participantes
    final allPlayers = <Player>{};
    for (final player in _tournament.players) {
      allPlayers.add(player);
    }
    for (final match in _tournament.matches) {
      if (match.player1 != null) allPlayers.add(match.player1!);
      if (match.player2 != null) allPlayers.add(match.player2!);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 80),
      children: [
        // Información de participantes compacta
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Participantes',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    allPlayers.toList().map((player) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              player.name,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        // Rondas de eliminación
        ...List.generate(totalRounds, (roundIndex) {
          final round = roundIndex + 1;
          final roundMatches = _tournamentService.getMatchesByRound(round);
          final completedInRound =
              roundMatches
                  .where((m) => m.status == MatchStatus.completed)
                  .length;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de la ronda compacto
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getRoundName(round, totalRounds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedInRound/${roundMatches.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Partidos de la ronda
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children:
                        roundMatches.map((match) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildMatchCard(match, colorScheme),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getRoundName(int round, int totalRounds) {
    if (round == totalRounds) return 'FINAL';
    if (round == totalRounds - 1) return 'SEMIFINAL';
    if (round == totalRounds - 2) return 'CUARTOS';
    return 'RONDA $round';
  }

  Widget _buildMatchCard(TournamentMatch match, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final canPlay =
        match.status == MatchStatus.pending &&
        match.player1 != null &&
        match.player2 != null;

    final isNextMatch = _getNextMatch()?.id == match.id;
    final isCompleted = match.status == MatchStatus.completed;
    final needsPlayers = match.player1 == null || match.player2 == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color:
            isNextMatch
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : isCompleted
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                : colorScheme.surface,
        border: Border.all(
          color:
              isNextMatch
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : isCompleted
                  ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                  : colorScheme.outlineVariant.withValues(alpha: 0.15),
          width: isNextMatch ? 2 : 1,
        ),
        boxShadow: [
          if (isNextMatch)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPlay ? () => _playMatch(match) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header compacto
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isNextMatch
                                ? colorScheme.primary
                                : isCompleted
                                ? colorScheme.secondaryContainer
                                : needsPlayers
                                ? colorScheme.errorContainer
                                : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNextMatch
                                ? Icons.play_arrow_rounded
                                : isCompleted
                                ? Icons.check_circle_rounded
                                : needsPlayers
                                ? Icons.pending_rounded
                                : Icons.schedule_rounded,
                            size: 12,
                            color:
                                isNextMatch
                                    ? Colors.white
                                    : isCompleted
                                    ? colorScheme.onSecondaryContainer
                                    : needsPlayers
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNextMatch
                                ? 'PRÓXIMO'
                                : isCompleted
                                ? 'COMPLETADO'
                                : needsPlayers
                                ? 'ESPERANDO'
                                : 'PENDIENTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color:
                                  isNextMatch
                                      ? Colors.white
                                      : isCompleted
                                      ? colorScheme.onSecondaryContainer
                                      : needsPlayers
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (match.groupId != null)
                      Text(
                        match.groupId == 'elimination'
                            ? 'Eliminación'
                            : 'G${match.groupId}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      )
                    else if (match.round > 0)
                      Text(
                        'R${match.round}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Jugadores compactos
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'vs',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Por definir',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color:
            isWinner
                ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isWinner
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: isWinner ? 2 : 1,
        ),
        boxShadow: [
          if (isWinner)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                    color:
                        isWinner ? colorScheme.primary : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (score != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$score pts',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isWinner) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.emoji_events_rounded,
              color: colorScheme.primary,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  TournamentMatch? _getNextMatch() {
    return _tournamentService.getNextMatch();
  }

  Widget _buildCurrentMatchCard(
    TournamentMatch match,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final canPlay =
        match.status == MatchStatus.pending &&
        match.player1 != null &&
        match.player2 != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partido Actual',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (match.groupId != null || match.round > 0)
                      Text(
                        match.groupId != null
                            ? 'Grupo ${match.groupId}'
                            : 'Ronda ${match.round}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (canPlay)
                FilledButton.icon(
                  onPressed: () => _playMatch(match),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Jugar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'VS',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
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
    final textTheme = Theme.of(context).textTheme;
    final upcomingMatches =
        _tournament.matches
            .where(
              (m) =>
                  m.status == MatchStatus.pending &&
                  m.player1 != null &&
                  m.player2 != null &&
                  m.id != _getNextMatch()?.id,
            )
            .take(2)
            .toList();

    if (upcomingMatches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upcoming_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Próximos',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...upcomingMatches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            return Container(
              margin: EdgeInsets.only(
                bottom: index < upcomingMatches.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${match.player1?.name ?? 'TBD'} vs ${match.player2?.name ?? 'TBD'}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
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
    final textTheme = Theme.of(context).textTheme;

    if (_tournament.isCompleted && _tournament.winner == null) {
      return _buildTieScreen(colorScheme);
    }

    _maybeShowChampionDialog(colorScheme, textTheme);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 16,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tournament.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${_localizedTournamentType()} • ${_tournament.pointsToWin} pts',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refreshTournament,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _showCancelDialog(context),
            tooltip: 'Cancelar torneo',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildOverviewSection(colorScheme, textTheme),
            Expanded(child: _buildBracketView(colorScheme, textTheme)),
          ],
        ),
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

  String _localizedTournamentType() {
    switch (_tournament.type) {
      case TournamentType.singleElimination:
        return 'Eliminación simple';
      case TournamentType.doubleElimination:
        return 'Doble eliminación';
      case TournamentType.roundRobin:
        return 'Todos contra todos';
      case TournamentType.groupStage:
        return 'Fase de grupos';
    }
  }

  void _maybeShowChampionDialog(ColorScheme colorScheme, TextTheme textTheme) {
    if (!_tournament.isCompleted ||
        _tournament.winner == null ||
        _hasShownChampionDialog) {
      return;
    }

    _hasShownChampionDialog = true;

    final winnerName = _tournament.winner!.name;
    final completedMatches = _tournament.matches.where(
      (m) => m.status == MatchStatus.completed,
    );
    TournamentMatch? finalMatch;
    if (completedMatches.isNotEmpty) {
      finalMatch = completedMatches.reduce((a, b) {
        if (a.round != b.round) {
          return a.round > b.round ? a : b;
        }
        return a.matchNumber >= b.matchNumber ? a : b;
      });
    }

    String? opponentName;
    int? winnerScore;
    int? opponentScore;
    if (finalMatch != null) {
      final player1Name = finalMatch.player1?.name;
      final player2Name = finalMatch.player2?.name;
      if (player1Name != null && player2Name != null) {
        final winnerIsP1 = player1Name == winnerName;
        opponentName = winnerIsP1 ? player2Name : player1Name;
        winnerScore = winnerIsP1 ? finalMatch.score1 : finalMatch.score2;
        opponentScore = winnerIsP1 ? finalMatch.score2 : finalMatch.score1;
      }
    }

    final highlightPointsLabel =
        winnerScore != null
            ? '$winnerScore puntos'
            : '${_tournament.pointsToWin} pts a ganar';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Container(
                          color: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: 48,
                                color: colorScheme.onPrimary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'VICTORIA',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.onPrimary
                                      .withValues(alpha: 0.2),
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed:
                                    () => Navigator.of(dialogContext).pop(),
                                child: const Text('Continuar torneo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Container(
                          color: colorScheme.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.primaryContainer,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '¡GANADOR!',
                                              style: textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: colorScheme.primary,
                                                    letterSpacing: 0.5,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        winnerName.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        highlightPointsLabel,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (opponentName != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          opponentName,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${opponentScore ?? '-'} puntos',
                                          style: textTheme.labelMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () async {
                                        Navigator.of(dialogContext).pop();
                                        await _tournamentService
                                            .clearCompletedTournament();
                                        if (!mounted) return;
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) => const SetupScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Nueva partida'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        textStyle: textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogContext).pop(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Ver resultados'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    });
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.03),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Indicador de posición
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.2),
                              colorScheme.primary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${wins.entries.toList().indexOf(entry) + 1}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: colorScheme.onSurface,
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
