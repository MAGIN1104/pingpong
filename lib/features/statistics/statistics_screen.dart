import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/statistics_service.dart';
import '../../core/models/player_stats.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _statsService = StatisticsService();
  List<PlayerStats> _allStats = [];
  PlayerStats? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _allStats = _statsService.getAllStats();
      if (_allStats.isNotEmpty) {
        _selectedPlayer = _allStats.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _allStats.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildStatsContent(colorScheme),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 80, color: colorScheme.outline),
          const SizedBox(height: 24),
          Text(
            'No hay estadísticas disponibles',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'Juega algunas partidas para ver tus estadísticas aquí',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(ColorScheme colorScheme) {
    return Column(
      children: [
        // Selector de jugador
        _buildPlayerSelector(colorScheme),

        // Estadísticas detalladas
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(colorScheme),
                const SizedBox(height: 24),
                _buildWinRateChart(colorScheme),
                const SizedBox(height: 24),
                _buildModalityStats(colorScheme),
                const SizedBox(height: 24),
                _buildAchievements(colorScheme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar Jugador',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          DropdownButton<PlayerStats>(
            value: _selectedPlayer,
            isExpanded: true,
            items:
                _allStats
                    .map(
                      (stats) => DropdownMenuItem(
                        value: stats,
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stats.playerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${stats.wins}V - ${stats.losses}D',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPlayer = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(ColorScheme colorScheme) {
    if (_selectedPlayer == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colorScheme,
                'Victorias',
                '${_selectedPlayer!.wins}',
                Icons.emoji_events,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colorScheme,
                'Derrotas',
                '${_selectedPlayer!.losses}',
                Icons.close_rounded,
                colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colorScheme,
                'Win Rate',
                '${_selectedPlayer!.winRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colorScheme,
                'Racha',
                '${_selectedPlayer!.currentWinStreak}',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildWinRateChart(ColorScheme colorScheme) {
    if (_selectedPlayer == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución de Resultados',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  color: colorScheme.primary,
                  value: _selectedPlayer!.wins.toDouble(),
                  title: '${_selectedPlayer!.wins}',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: colorScheme.error,
                  value: _selectedPlayer!.losses.toDouble(),
                  title: '${_selectedPlayer!.losses}',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(colorScheme.primary, 'Victorias'),
            const SizedBox(width: 24),
            _buildLegendItem(colorScheme.error, 'Derrotas'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildModalityStats(ColorScheme colorScheme) {
    if (_selectedPlayer == null || _selectedPlayer!.winsByModality.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Victorias por Modalidad',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ..._selectedPlayer!.winsByModality.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '${entry.key} puntos',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${entry.value} victorias',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAchievements(ColorScheme colorScheme) {
    if (_selectedPlayer == null) return const SizedBox.shrink();

    final achievements = _statsService.getPlayerAchievements(
      _selectedPlayer!.playerName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logros Desbloqueados',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        achievements.isEmpty
            ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Aún no has desbloqueado logros.\n¡Sigue jugando!',
                  style: TextStyle(color: colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            : Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  achievements.map((achievement) {
                    return Container(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.secondaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            achievement.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
      ],
    );
  }
}
