import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> partidas;
  final Future<void> Function()? onClear;
  const ResultsScreen({super.key, required this.partidas, this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final victoriasPorJugador = <String, int>{};
    final derrotasPorJugador = <String, int>{};
    final puntosFavor = <String, int>{};
    final puntosContra = <String, int>{};
    final jugados = <String, int>{};
    for (final p in partidas) {
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
            : Card(
              color: colorScheme.primaryContainer,
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 340;
                    final nameFont = isSmall ? 18.0 : 24.0;
                    final infoFont = isSmall ? 13.0 : 16.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: colorScheme.primary,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mejor jugador',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                mejorJugador['jugador'].toString(),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: nameFont,
                                ),
                              ),
                              Text(
                                '${mejorJugador['victorias']} victorias  |  ${mejorJugador['winrate']}% win rate',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: infoFont,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );

    Widget rankingTable = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Jugador')),
          DataColumn(label: Text('Partidos')),
          DataColumn(label: Text('Victorias')),
          DataColumn(label: Text('Derrotas')),
          DataColumn(label: Text('Favor')),
          DataColumn(label: Text('Contra')),
          DataColumn(label: Text('Dif.')),
          DataColumn(label: Text('Win %')),
        ],
        rows: [
          for (final r in ranking)
            DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (mejorJugador != null &&
                    r['jugador'] == mejorJugador['jugador']) {
                  return colorScheme.secondaryContainer;
                }
                return null;
              }),
              cells: [
                DataCell(
                  Row(
                    children: [
                      if (mejorJugador != null &&
                          r['jugador'] == mejorJugador['jugador'])
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.emoji_events,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      Text(r['jugador'].toString()),
                    ],
                  ),
                ),
                DataCell(Text('${r['jugados']}')),
                DataCell(Text('${r['victorias']}')),
                DataCell(Text('${r['derrotas']}')),
                DataCell(Text('${r['favor']}')),
                DataCell(Text('${r['contra']}')),
                DataCell(Text('${r['diferencia']}')),
                DataCell(Text('${r['winrate']}%')),
              ],
            ),
        ],
      ),
    );

    Widget tableSectionWrapped =
        partidas.isEmpty
            ? const Center(child: Text('No hay partidas guardadas'))
            : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 600, minHeight: 220),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Jugador 1')),
                      DataColumn(label: Text('Score 1')),
                      DataColumn(label: Text('Score 2')),
                      DataColumn(label: Text('Jugador 2')),
                      DataColumn(label: Text('Ganador')),
                      DataColumn(label: Text('Diferencia')),
                      DataColumn(label: Text('Fecha')),
                    ],
                    rows: [
                      for (int i = 0; i < partidas.length; i++)
                        _buildDataRow(partidas[i], i),
                    ],
                  ),
                ),
              ),
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados'),
            actions: [
              if (onClear != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Limpiar resultados'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await onClear!();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child:
                isLandscape
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 2,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                winnerCard,
                                const SizedBox(height: 16),
                                rankingTable,
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Flexible(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: tableSectionWrapped,
                          ),
                        ),
                      ],
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          winnerCard,
                          const SizedBox(height: 16),
                          rankingTable,
                          const SizedBox(height: 16),
                          tableSectionWrapped,
                        ],
                      ),
                    ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> p, int index) {
    final s1 = p["s1"];
    final s2 = p["s2"];
    final p1 = p["p1"];
    final p2 = p["p2"];
    final ganador = s1 > s2 ? p1 : p2;
    final fecha = (p["fecha"] is String
            ? DateTime.parse(p["fecha"])
            : p["fecha"])
        .toString()
        .substring(0, 16);
    final diferencia = ((s1 - s2).abs()).toInt();
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(p1)),
        DataCell(Text('$s1')),
        DataCell(Text('$s2')),
        DataCell(Text(p2)),
        DataCell(
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.blue, size: 18),
              const SizedBox(width: 4),
              Text(
                ganador,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DataCell(Text('$diferencia')),
        DataCell(Text(fecha)),
      ],
    );
  }
}
