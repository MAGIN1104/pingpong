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

  // Variables para fase de grupos
  int _numberOfGroups = 2;
  int _playersAdvancingPerGroup = 2;
  int _currentStep = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    // Pre-seleccionar todos los jugadores disponibles
    _selectedPlayers = List.from(widget.availablePlayers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
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
      numberOfGroups:
          _selectedType == TournamentType.groupStage ? _numberOfGroups : null,
      playersPerGroup:
          _selectedType == TournamentType.groupStage
              ? (_selectedPlayers.length / _numberOfGroups).ceil()
              : null,
      playersAdvancingPerGroup:
          _selectedType == TournamentType.groupStage
              ? _playersAdvancingPerGroup
              : null,
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleSpacing: 0,
        title: Text(
          'Configurar Torneo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: colorScheme.surface,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              _buildConfigurationStepper(colorScheme, textTheme),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    _selectedPlayers.length < 2
                        ? Container(
                          key: const ValueKey('warning'),
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Selecciona al menos dos participantes para comenzar.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    _selectedPlayers.length >= 2 ? _createTournament : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor:
                      _selectedPlayers.length >= 2
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                  foregroundColor:
                      _selectedPlayers.length >= 2
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.45),
                  shadowColor: Colors.transparent,
                ),
                icon: Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color:
                      _selectedPlayers.length >= 2
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                label: Text(
                  'Iniciar Torneo',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        const SizedBox(height: 8),
        _buildTypeCard(
          TournamentType.groupStage,
          'Fase de Grupos',
          'Grupos + Eliminación directa (Cuartos, Semifinales, Final)',
          Icons.sports_esports,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildConfigurationStepper(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final bool showGroupStep = _selectedType == TournamentType.groupStage;
    final List<_ConfigurationStep> steps = [
      _ConfigurationStep(
        title: 'Nombre de la partida',
        helper: 'Define un nombre para identificar rápidamente la partida.',
        icon: Icons.emoji_events,
        color: colorScheme.primary,
        builder:
            () => _buildStepContainer(
              colorScheme,
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ej: Torneo de Campeones',
                  prefixIcon: const Icon(Icons.edit_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
              ),
            ),
      ),
      _ConfigurationStep(
        title: 'Tipo de torneo',
        helper: 'Elige la modalidad que se adapta mejor a tu evento.',
        icon: Icons.account_tree,
        color: colorScheme.secondary,
        builder:
            () => _buildStepContainer(
              colorScheme,
              _buildTournamentTypeSelector(colorScheme),
            ),
      ),
      _ConfigurationStep(
        title: 'Puntos para ganar',
        helper: 'Selecciona la cantidad de puntos necesaria por partido.',
        icon: Icons.sports_score,
        color: const Color(0xFFEE6C4D),
        builder:
            () => _buildStepContainer(
              colorScheme,
              _buildPointsSelector(colorScheme),
            ),
      ),
      _ConfigurationStep(
        title: 'Participantes',
        helper: 'Añade o elimina jugadores antes de iniciar el torneo.',
        icon: Icons.group,
        color: colorScheme.primary,
        builder: () => _buildPlayersSelector(colorScheme),
      ),
    ];

    if (showGroupStep) {
      steps.add(
        _ConfigurationStep(
          title: 'Configuración de grupos',
          helper: 'Ajusta cómo se formarán los grupos y cuántos avanzan.',
          icon: Icons.group_work,
          color: colorScheme.tertiary,
          builder: () => _buildGroupConfiguration(colorScheme),
        ),
      );
    }

    steps.add(
      _ConfigurationStep(
        title: 'Resumen del torneo',
        helper: 'Revisa la configuración final antes de iniciar.',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF1B9AAA),
        builder:
            () => _buildStepContainer(
              colorScheme,
              _buildTournamentInfo(colorScheme),
            ),
      ),
    );

    final int maxStepIndex = steps.length - 1;
    final int clampedStep =
        steps.isEmpty ? 0 : _currentStep.clamp(0, maxStepIndex);
    if (clampedStep != _currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentStep = clampedStep;
        });
      });
    }

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepTile(
            colorScheme,
            textTheme,
            step: steps[i],
            index: i,
            isActive: i == clampedStep,
            isCompleted: i < clampedStep,
          ),
          if (i < steps.length - 1)
            _buildStepConnector(colorScheme, isCompleted: i < clampedStep),
        ],
        const SizedBox(height: 16),
        _buildStepControls(colorScheme, steps.length),
      ],
    );
  }

  Widget _buildStepContainer(ColorScheme colorScheme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }

  Widget _buildStepControls(ColorScheme colorScheme, int totalSteps) {
    final bool isFirst = _currentStep == 0;
    final bool isLast = _currentStep >= totalSteps - 1;
    final bool canCreateTournament = _selectedPlayers.length >= 2;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                isFirst
                    ? null
                    : () {
                      setState(() {
                        _currentStep = max(0, _currentStep - 1);
                      });
                    },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed:
                isLast
                    ? (canCreateTournament ? _createTournament : null)
                    : () {
                      setState(() {
                        _currentStep = min(totalSteps - 1, _currentStep + 1);
                      });
                    },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(
              isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(isLast ? 'Finalizar' : 'Continuar'),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTile(
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required _ConfigurationStep step,
    required int index,
    required bool isActive,
    required bool isCompleted,
  }) {
    final Color indicatorBorder =
        isActive || isCompleted ? step.color : colorScheme.outlineVariant;
    final Color indicatorBackground =
        isActive || isCompleted
            ? step.color
            : colorScheme.surfaceContainerHighest;
    final Color indicatorIconColor =
        isActive || isCompleted ? colorScheme.onPrimary : indicatorBorder;
    final Color titleColor = isActive ? step.color : colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _currentStep = index;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: indicatorBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: indicatorBorder, width: 2),
                  ),
                  child: Center(
                    child:
                        isCompleted
                            ? Icon(
                              Icons.check,
                              size: 18,
                              color: indicatorIconColor,
                            )
                            : Icon(
                              step.icon,
                              size: 18,
                              color: indicatorIconColor,
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (step.helper != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          step.helper!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child:
              isActive
                  ? Padding(
                    key: ValueKey('step-$index-active'),
                    padding: const EdgeInsets.only(
                      left: 44,
                      top: 12,
                      bottom: 4,
                    ),
                    child: step.builder(),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStepConnector(
    ColorScheme colorScheme, {
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 2,
        height: 28,
        decoration: BoxDecoration(
          color:
              isCompleted
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildGroupConfiguration(ColorScheme colorScheme) {
    final playersPerGroup = (_selectedPlayers.length / _numberOfGroups).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número de grupos
          Text(
            'Número de Grupos',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int groups = 2; groups <= 4; groups++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$groups'),
                      selected: _numberOfGroups == groups,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _numberOfGroups = groups;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Jugadores por grupo
          Text(
            'Jugadores por Grupo',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$playersPerGroup jugadores por grupo',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Clasificados por grupo
          Text(
            'Clasificados por Grupo',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (
                int advancing = 1;
                advancing <= playersPerGroup.clamp(1, 3);
                advancing++
              )
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$advancing'),
                      selected: _playersAdvancingPerGroup == advancing,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _playersAdvancingPerGroup = advancing;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Información del torneo de grupos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Información del Torneo',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Fase de Grupos: ${_numberOfGroups} grupos de $playersPerGroup jugadores\n'
                  '• Cada jugador juega contra todos en su grupo\n'
                  '• Los mejores $_playersAdvancingPerGroup de cada grupo pasan a eliminación\n'
                  '• Fase Final: ${_numberOfGroups * _playersAdvancingPerGroup} jugadores en eliminación directa',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
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
    final textTheme = Theme.of(context).textTheme;
    final filteredPlayers =
        _searchTerm.isEmpty
            ? widget.availablePlayers
            : widget.availablePlayers
                .where((p) => p.name.toUpperCase().contains(_searchTerm))
                .toList();
    final accentPalette = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      const Color(0xFFEAF4FF),
      const Color(0xFFFFF0F5),
      const Color(0xFFE8FFF7),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seleccionados: ${_selectedPlayers.length}/${widget.availablePlayers.length}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed:
                    _selectedPlayers.length == widget.availablePlayers.length
                        ? null
                        : () {
                          setState(() {
                            _selectedPlayers = List<Player>.from(
                              widget.availablePlayers,
                            );
                          });
                        },
                icon: const Icon(Icons.select_all_rounded, size: 18),
                label: const Text('Todos'),
              ),
              TextButton.icon(
                onPressed:
                    _selectedPlayers.isEmpty
                        ? null
                        : () {
                          setState(() {
                            _selectedPlayers.clear();
                          });
                        },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Ninguno'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar participante',
              hintText: 'Ej: ANA PÉREZ',
              prefixIcon: Icon(Icons.search, color: colorScheme.outline),
              suffixIcon:
                  _searchTerm.isNotEmpty
                      ? IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value.trim().toUpperCase();
              });
            },
          ),
          const SizedBox(height: 16),
          if (filteredPlayers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 36,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchTerm.isEmpty
                        ? 'No hay participantes disponibles'
                        : 'Sin coincidencias para "$_searchTerm"',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final entry in filteredPlayers.asMap().entries)
                      _buildColoredChip(
                        player: entry.value,
                        paletteColor:
                            accentPalette[entry.key % accentPalette.length],
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                  ],
                ),
                if (_selectedPlayers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Participantes en el torneo',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedPlayers
                            .map(
                              (player) => Chip(
                                backgroundColor: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                label: Text(
                                  player.name,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                deleteIconColor: colorScheme.primary,
                                onDeleted: () {
                                  setState(() {
                                    _selectedPlayers.removeWhere(
                                      (p) => p.name == player.name,
                                    );
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildColoredChip({
    required Player player,
    required Color paletteColor,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final bool isSelected = _selectedPlayers.any((p) => p.name == player.name);
    final Color selectedColor = colorScheme.primary;
    final Color unselectedColor = colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.9);
    final Color borderColor =
        isSelected
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.6);
    final Color textColor =
        isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurface.withValues(alpha: 0.8);
    final Color checkColor = colorScheme.onPrimary;

    return FilterChip(
      label: Text(
        player.name,
        style: textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      side: BorderSide(color: borderColor, width: 1.6),
      selectedColor: selectedColor,
      backgroundColor: unselectedColor,
      showCheckmark: true,
      checkmarkColor: checkColor,
      onSelected: (_) {
        setState(() {
          if (isSelected) {
            _selectedPlayers.removeWhere((p) => p.name == player.name);
          } else {
            _selectedPlayers.add(player);
          }
        });
      },
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

    if (n <= 1) {
      return 0;
    }

    switch (_selectedType) {
      case TournamentType.singleElimination:
        return n - 1; // n-1 partidos en eliminación simple
      case TournamentType.doubleElimination:
        return (n - 1) * 2; // Aproximadamente el doble
      case TournamentType.roundRobin:
        return (n * (n - 1)) ~/ 2; // Combinaciones de n elementos de 2 en 2
      case TournamentType.groupStage:
        if (_numberOfGroups <= 0) return 0;
        final playersPerGroup = (n / _numberOfGroups).ceil();
        final groupMatches =
            _numberOfGroups * ((playersPerGroup * (playersPerGroup - 1)) ~/ 2);
        final eliminationMatches = max(
          (_numberOfGroups * _playersAdvancingPerGroup) - 1,
          0,
        );
        return max(groupMatches + eliminationMatches, 0);
    }
  }

  int _calculateRounds() {
    int players = _selectedPlayers.length;
    if (players <= 1) {
      return 0;
    }
    int rounds = 0;
    while (players > 1) {
      players = (players / 2).ceil();
      rounds++;
    }
    return rounds;
  }
}

class _ConfigurationStep {
  const _ConfigurationStep({
    required this.title,
    required this.icon,
    required this.color,
    required this.builder,
    this.helper,
  });

  final String title;
  final String? helper;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
}
