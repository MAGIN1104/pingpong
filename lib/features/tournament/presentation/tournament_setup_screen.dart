import 'dart:math';
import 'package:flutter/material.dart';
import '../data/tournament_service.dart';
import '../domain/entities/tournament.dart';
import '../../game/domain/entities/player.dart';
import 'tournament_bracket_screen.dart';

class TournamentSetupScreen extends StatefulWidget {
  final List<Player> availablePlayers;

  const TournamentSetupScreen({super.key, required this.availablePlayers});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  final _tournamentService = TournamentService();
  final _nameController = TextEditingController(text: 'Torneo de Ping Pong');

  List<Player> _selectedPlayers = [];
  TournamentType _selectedType = TournamentType.singleElimination;
  int _pointsToWin = 11;

  @override
  void initState() {
    super.initState();
    // Pre-seleccionar todos los jugadores disponibles
    _selectedPlayers = List.from(widget.availablePlayers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createTournament() {
    if (_selectedPlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesitan al menos 2 jugadores para un torneo'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validar que no hay nombres duplicados
    final playerNames = _selectedPlayers.map((p) => p.name).toList();
    final uniqueNames = playerNames.toSet();
    if (playerNames.length != uniqueNames.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden tener jugadores con el mismo nombre'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tournament = _tournamentService.createTournament(
      name: _nameController.text.trim(),
      players: _selectedPlayers,
      type: _selectedType,
      pointsToWin: _pointsToWin,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentBracketScreen(tournament: tournament),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Torneo'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nombre del torneo
          _buildSectionTitle('Nombre del Torneo', Icons.emoji_events),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ej: Torneo de Campeones',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tipo de torneo
          _buildSectionTitle('Tipo de Torneo', Icons.account_tree),
          const SizedBox(height: 12),
          _buildTournamentTypeSelector(colorScheme),

          const SizedBox(height: 24),

          // Puntos para ganar
          _buildSectionTitle('Puntos para Ganar', Icons.sports_score),
          const SizedBox(height: 12),
          _buildPointsSelector(colorScheme),

          const SizedBox(height: 24),

          // Selección de jugadores
          _buildSectionTitle(
            'Participantes (${_selectedPlayers.length}/${widget.availablePlayers.length})',
            Icons.group,
          ),
          const SizedBox(height: 12),
          _buildPlayersSelector(colorScheme),

          const SizedBox(height: 24),

          // Información del torneo
          _buildTournamentInfo(colorScheme),

          const SizedBox(height: 24),

          // Botón de iniciar
          FilledButton.icon(
            onPressed: _selectedPlayers.length >= 2 ? _createTournament : null,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('Iniciar Torneo', style: TextStyle(fontSize: 18)),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTournamentTypeSelector(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildTypeCard(
          TournamentType.singleElimination,
          'Eliminación Simple',
          'El perdedor queda eliminado inmediatamente',
          Icons.emoji_events,
          colorScheme,
        ),
        const SizedBox(height: 8),
        _buildTypeCard(
          TournamentType.roundRobin,
          'Todos contra Todos',
          'Cada jugador enfrenta a todos los demás',
          Icons.group_work,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    TournamentType type,
    String title,
    String description,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          [7, 11, 21].map((points) {
            final isSelected = _pointsToWin == points;
            return ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  '$points puntos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _pointsToWin = points),
              selectedColor: colorScheme.primaryContainer,
              backgroundColor: colorScheme.surfaceContainerHighest,
            );
          }).toList(),
    );
  }

  Widget _buildPlayersSelector(ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.availablePlayers.length,
        itemBuilder: (context, index) {
          final player = widget.availablePlayers[index];
          final isSelected = _selectedPlayers.any((p) => p.name == player.name);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  // Verificar que no existe otro jugador con el mismo nombre
                  if (!_selectedPlayers.any((p) => p.name == player.name)) {
                    _selectedPlayers.add(player);
                  }
                } else {
                  _selectedPlayers.removeWhere((p) => p.name == player.name);
                }
              });
            },
            title: Text(player.name),
            secondary: Icon(
              Icons.person,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentInfo(ColorScheme colorScheme) {
    final totalMatches = _calculateTotalMatches();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            'Información del Torneo',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Participantes', '${_selectedPlayers.length}'),
          _buildInfoRow('Total de partidos', '$totalMatches'),
          _buildInfoRow('Puntos por partido', '$_pointsToWin'),
          if (_selectedType == TournamentType.singleElimination) ...[
            _buildInfoRow('Rondas estimadas', '${_calculateRounds()}'),
            if (_selectedPlayers.length.isOdd)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Con ${_selectedPlayers.length} jugadores, algunos tendrán pase directo en la 1ª ronda',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  int _calculateTotalMatches() {
    final n = _selectedPlayers.length;

    switch (_selectedType) {
      case TournamentType.singleElimination:
        return n - 1; // n-1 partidos en eliminación simple
      case TournamentType.doubleElimination:
        return (n - 1) * 2; // Aproximadamente el doble
      case TournamentType.roundRobin:
        return (n * (n - 1)) ~/ 2; // Combinaciones de n elementos de 2 en 2
    }
  }

  int _calculateRounds() {
    final n = _selectedPlayers.length;
    return (log(n) / log(2)).ceil();
  }
}
