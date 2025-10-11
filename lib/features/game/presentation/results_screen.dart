import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> partidas;
  final Future<void> Function()? onClear;
  const ResultsScreen({super.key, required this.partidas, this.onClear});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _showDetailedView = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final victoriasPorJugador = <String, int>{};
    final derrotasPorJugador = <String, int>{};
    final puntosFavor = <String, int>{};
    final puntosContra = <String, int>{};
    final jugados = <String, int>{};
    for (final p in widget.partidas) {
      final p1 = p["p1"];
      final p2 = p["p2"];
      final s1 = p["s1"] as int;
      final s2 = p["s2"] as int;
      final ganador = s1 > s2 ? p1 : p2;
      final perdedor = s1 > s2 ? p2 : p1;
      victoriasPorJugador[ganador] = (victoriasPorJugador[ganador] ?? 0) + 1;
      derrotasPorJugador[perdedor] = (derrotasPorJugador[perdedor] ?? 0) + 1;
      puntosFavor[p1] = (puntosFavor[p1] ?? 0) + s1;
      puntosFavor[p2] = (puntosFavor[p2] ?? 0) + s2;
      puntosContra[p1] = (puntosContra[p1] ?? 0) + s2;
      puntosContra[p2] = (puntosContra[p2] ?? 0) + s1;
      jugados[p1] = (jugados[p1] ?? 0) + 1;
      jugados[p2] = (jugados[p2] ?? 0) + 1;
    }
    final jugadores =
        <String>{}
          ..addAll(victoriasPorJugador.keys)
          ..addAll(derrotasPorJugador.keys)
          ..addAll(jugados.keys);
    final ranking =
        jugadores.map((j) {
          final jug = jugados[j] ?? 0;
          final vic = victoriasPorJugador[j] ?? 0;
          final der = derrotasPorJugador[j] ?? 0;
          final fav = puntosFavor[j] ?? 0;
          final con = puntosContra[j] ?? 0;
          final dif = fav - con;
          final winRate =
              jug > 0 ? (vic / jug * 100).toStringAsFixed(1) : '0.0';
          return {
            'jugador': j,
            'jugados': jug,
            'victorias': vic,
            'derrotas': der,
            'favor': fav,
            'contra': con,
            'diferencia': dif,
            'winrate': winRate,
          };
        }).toList();
    ranking.sort(
      (a, b) => (b['victorias'] as int).compareTo(a['victorias'] as int),
    );
    final mejorJugador = ranking.isNotEmpty ? ranking.first : null;

    Widget winnerCard =
        mejorJugador == null
            ? const SizedBox.shrink()
            : Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mejor jugador',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mejorJugador['jugador'].toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mejorJugador['victorias']} victorias • ${mejorJugador['winrate']}% win rate',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

    Widget rankingTable = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Ranking de Jugadores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (ranking.length > 3)
                  TextButton(
                    onPressed:
                        () => setState(
                          () => _showDetailedView = !_showDetailedView,
                        ),
                    child: Text(
                      _showDetailedView ? 'Ver menos' : 'Ver más',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...ranking.take(_showDetailedView ? ranking.length : 3).map((r) {
            final isWinner =
                mejorJugador != null && r['jugador'] == mejorJugador['jugador'];
            return Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isWinner
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isWinner
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Posición
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          isWinner
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${ranking.indexOf(r) + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isWinner ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre
                  Expanded(
                    child: Row(
                      children: [
                        if (isWinner)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.emoji_events,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                          ),
                        Text(
                          r['jugador'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isWinner ? FontWeight.w500 : FontWeight.w400,
                            color:
                                isWinner
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estadísticas compactas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${r['victorias']}V - ${r['derrotas']}D',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${r['winrate']}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (!_showDetailedView && ranking.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '+${ranking.length - 3} más',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );

    Widget recentMatches =
        widget.partidas.isEmpty
            ? Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 48,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay partidas guardadas',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
            : Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Partidas Recientes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (widget.partidas.length > 5)
                          TextButton(
                            onPressed:
                                () => setState(
                                  () => _showDetailedView = !_showDetailedView,
                                ),
                            child: Text(
                              _showDetailedView ? 'Ver menos' : 'Ver todas',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...widget.partidas
                      .take(_showDetailedView ? widget.partidas.length : 5)
                      .map((partida) => _buildMatchCard(partida, colorScheme)),
                  if (!_showDetailedView && widget.partidas.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '+${widget.partidas.length - 5} más',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          if (widget.onClear != null)
            IconButton(
              onPressed: () async {
                await widget.onClear!();
                if (mounted) Navigator.of(context).pop();
              },
              icon: Icon(Icons.delete_forever, color: colorScheme.error),
              tooltip: 'Limpiar resultados',
            ),
        ],
      ),
      body:
          widget.partidas.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 64,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay partidas guardadas',
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Juega algunas partidas para ver los resultados aquí',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.outline.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    winnerCard,
                    const SizedBox(height: 8),
                    rankingTable,
                    const SizedBox(height: 8),
                    recentMatches,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildMatchCard(
    Map<String, dynamic> partida,
    ColorScheme colorScheme,
  ) {
    final s1 = partida["s1"];
    final s2 = partida["s2"];
    final p1 = partida["p1"];
    final p2 = partida["p2"];
    final ganador = s1 > s2 ? p1 : p2;
    final diferencia = (s1 - s2).abs();

    final fecha =
        (partida["fecha"] is String
                ? DateTime.parse(partida["fecha"])
                : partida["fecha"])
            as DateTime;

    final now = DateTime.now();
    final diff = now.difference(fecha);
    String fechaTexto;
    if (diff.inDays > 0) {
      fechaTexto = '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      fechaTexto = '${diff.inHours}h';
    } else {
      fechaTexto = '${diff.inMinutes}m';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Resultado del partido
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$s1-$s2',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Jugadores
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        ganador == p1 ? FontWeight.w500 : FontWeight.w400,
                    color:
                        ganador == p1
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                  ),
                ),
                Text(
                  'vs $p2',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ],
            ),
          ),
          // Ganador
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ganador,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(
                '+$diferencia • $fechaTexto',
                style: TextStyle(fontSize: 10, color: colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
