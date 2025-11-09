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
        setState(() {
          _tournament = _tournamentService.currentTournament!;
          if (!_tournament.isCompleted) {
            _hasShownChampionDialog = false;
          }
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

  Widget _buildTournamentHeader(ColorScheme colorScheme, TextTheme textTheme) {
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del torneo',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStatCard(
                  label: 'Jugadores',
                  value: '${_tournament.players.length}',
                  icon: Icons.people_alt_rounded,
                  background: colorScheme.primaryContainer,
                  foreground: colorScheme.onPrimaryContainer,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderStatCard(
                  label: 'Completados',
                  value: '$completedMatches/$totalMatches',
                  icon: Icons.check_circle_rounded,
                  background: colorScheme.secondaryContainer,
                  foreground: colorScheme.onSecondaryContainer,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderStatCard(
                  label: 'Por jugar',
                  value: '$pendingMatches',
                  icon: Icons.playlist_add_check_rounded,
                  background: colorScheme.tertiaryContainer,
                  foreground: colorScheme.onTertiaryContainer,
                  textTheme: textTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color background,
    required Color foreground,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: foreground.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: foreground),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: foreground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme, TextTheme textTheme) {
    final progressPercent = (_tournament.progress * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso del torneo',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$progressPercent%',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _tournament.progress,
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
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
          textTheme,
          completedMatches,
          totalMatches,
          pendingMatches,
        ),

        const SizedBox(height: 16),

        // Partido actual destacado
        if (nextMatch != null) ...[
          _buildCurrentMatchCard(nextMatch, colorScheme, textTheme),
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
    else if (_tournament.type == TournamentType.groupStage)
      return _buildGroupStageView(colorScheme);
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
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.group_work, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'FASE DE GRUPOS',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mostrar cada grupo
        ...groups.entries.map((groupEntry) {
          final groupId = groupEntry.key;
          final groupMatches = groupEntry.value;
          final completedInGroup =
              groupMatches
                  .where((m) => m.status == MatchStatus.completed)
                  .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del grupo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'GRUPO $groupId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedInGroup/${groupMatches.length}',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Partidos del grupo
              ...groupMatches.map(
                (match) => _buildMatchCard(match, colorScheme),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEliminationSection(
    List<TournamentMatch> eliminationMatches,
    ColorScheme colorScheme,
  ) {
    // Agrupar por ronda
    final rounds = <int, List<TournamentMatch>>{};
    for (final match in eliminationMatches) {
      rounds.putIfAbsent(match.round, () => []).add(match);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'FASE DE ELIMINACIÓN',
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mostrar cada ronda
        ...rounds.entries.map((roundEntry) {
          final round = roundEntry.key;
          final roundMatches = roundEntry.value;
          final completedInRound =
              roundMatches
                  .where((m) => m.status == MatchStatus.completed)
                  .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la ronda
              Row(
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
                      _getRoundName(round, rounds.keys.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedInRound/${roundMatches.length}',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Partidos de la ronda
              ...roundMatches.map(
                (match) => _buildMatchCard(match, colorScheme),
              ),
              const SizedBox(height: 16),
            ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient:
            isNextMatch
                ? LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : LinearGradient(
                  colors: [
                    Colors.white,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        boxShadow: [
          BoxShadow(
            color:
                isNextMatch
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: isNextMatch ? 20 : 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              isNextMatch
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.outline.withValues(alpha: 0.1),
          width: isNextMatch ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPlay ? () => _playMatch(match) : null,
          borderRadius: BorderRadius.circular(20),
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'SIGUIENTE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      match.status == MatchStatus.completed ? 'VS' : 'vs',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize:
                            match.status == MatchStatus.completed ? 13 : 16,
                        color:
                            match.status == MatchStatus.completed
                                ? colorScheme.onSurface.withValues(alpha: 0.6)
                                : colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (canPlay && !isNextMatch) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient:
            isWinner
                ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : LinearGradient(
                  colors: [
                    Colors.white,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isWinner
                  ? colorScheme.primary.withValues(alpha: 0.8)
                  : colorScheme.outline.withValues(alpha: 0.1),
          width: isWinner ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isWinner
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: isWinner ? 12 : 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre y score en línea horizontal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.w500 : FontWeight.w400,
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
                    '$score puntos',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Icono de ganador más elegante
          if (isWinner)
            Container(
              padding: const EdgeInsets.all(6),
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
              child: Icon(
                Icons.emoji_events_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  TournamentMatch? _getNextMatch() {
    return _tournamentService.getNextMatch();
  }

  Widget _buildQuickTournamentInfo(
    ColorScheme colorScheme,
    TextTheme textTheme,
    int completed,
    int total,
    int pending,
  ) {
    final progress = total > 0 ? (completed / total) : 0.0;
    final estimatedTime = _calculateEstimatedTime(pending);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.95),
            colorScheme.secondaryContainer.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso del torneo',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estimatedTime.isEmpty
                          ? 'En curso'
                          : 'Est. $estimatedTime restantes',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.onPrimaryContainer.withValues(
                alpha: 0.12,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _buildQuickStat(
                label: 'Completados',
                value: '$completed/$total',
                icon: Icons.check_circle,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _buildQuickStat(
                label: 'Pendientes',
                value: '$pending',
                icon: Icons.sports_tennis,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              if (estimatedTime.isNotEmpty)
                _buildQuickStat(
                  label: 'Tiempo est.',
                  value: estimatedTime,
                  icon: Icons.access_time_filled,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMatchCard(
    TournamentMatch match,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Partido Actual',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Indicador de posición
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.2),
                                    colorScheme.primary.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${playerWins.entries.toList().indexOf(entry) + 1}',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.onSurface,
                                ),
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
        toolbarHeight: 92,
        titleSpacing: 20,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tournament.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_localizedTournamentType()} • ${_tournament.pointsToWin} pts',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTournament,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              _tournamentService.debugTournamentStructure();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Información de debug enviada a la consola'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Debug del torneo',
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
          _buildTournamentHeader(colorScheme, textTheme),
          _buildProgressBar(colorScheme, textTheme),
          Expanded(child: _buildBracketView(colorScheme, textTheme)),
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

  String _winnerInitials() {
    final name = _tournament.winner?.name.trim();
    if (name == null || name.isEmpty) return '🏓';
    final parts =
        name
            .split(RegExp(r'\s+'))
            .where((segment) => segment.isNotEmpty)
            .toList();
    if (parts.isEmpty) return name[0].toUpperCase();
    final buffer = StringBuffer();
    for (final segment in parts.take(2)) {
      if (segment.isNotEmpty) {
        buffer.write(segment[0].toUpperCase());
      }
    }
    return buffer.isEmpty ? name[0].toUpperCase() : buffer.toString();
  }

  void _maybeShowChampionDialog(ColorScheme colorScheme, TextTheme textTheme) {
    if (!_tournament.isCompleted ||
        _tournament.winner == null ||
        _hasShownChampionDialog) {
      return;
    }

    _hasShownChampionDialog = true;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 44,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '¡GANADOR!',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          width: 1.6,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _winnerInitials(),
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tournament.winner!.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _tournamentService.clearCompletedTournament();
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const SetupScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Nueva partida'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Ver resultados'),
                    ),
                  ],
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
