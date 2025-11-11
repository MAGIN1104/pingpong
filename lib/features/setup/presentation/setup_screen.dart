import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../../core/services/player_color_service.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/domain/entities/player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../statistics/statistics_screen.dart';
import '../../settings/settings_screen.dart';
import '../../tournament/presentation/tournament_setup_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<Player> participantes = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int modalidad = 11;
  String _searchTerm = '';

  // Constantes de seguridad
  static const int _maxParticipantes = 20;
  static const int _maxNombreLength = 20;
  static const int _minNombreLength = 2;
  static final RegExp _nombreRegex = RegExp(r'^[A-ZÁÉÍÓÚÑÜ\s]+$');

  final _colorService = PlayerColorService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _colorService.init();
    _loadParticipantes();

    // Optimizar listener para evitar rebuilds innecesarios
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Solo hacer setState si realmente cambió algo visual
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadParticipantes();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _loadParticipantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('participantes');
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        final List<Player> loadedParticipantes = [];

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            // Nuevo formato con avatar
            final name = item['name'] as String?;
            if (name != null && _isValidNombre(name)) {
              loadedParticipantes.add(Player(name: name));
            }
          } else if (item is String && _isValidNombre(item)) {
            // Formato anterior (solo nombre) - compatibilidad hacia atrás
            loadedParticipantes.add(Player.fromString(item));
          }
        }

        // Solo hacer setState si hay cambios reales
        if (mounted && !_listEquals(participantes, loadedParticipantes)) {
          setState(() {
            participantes.clear();
            participantes.addAll(loadedParticipantes);
          });
        }
      }
    } catch (e) {
      await _clearCorruptedData();
    }
  }

  Future<void> _clearCorruptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('participantes');
    } catch (e) {
      // Ignorar errores de limpieza
    }
  }

  Future<void> _saveParticipantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitizedData =
          participantes
              .where((p) => _isValidNombre(p.name))
              .take(_maxParticipantes)
              .map((p) => {'name': p.name})
              .toList();
      await prefs.setString('participantes', jsonEncode(sanitizedData));
    } catch (e) {
      // Manejar errores de guardado silenciosamente
    }
  }

  bool _isValidNombre(String nombre) {
    if (nombre.isEmpty ||
        nombre.length < _minNombreLength ||
        nombre.length > _maxNombreLength) {
      return false;
    }

    // Verificar que solo contenga caracteres válidos
    if (!_nombreRegex.hasMatch(nombre)) {
      return false;
    }

    // Verificar que no sea solo espacios
    if (nombre.trim().isEmpty) {
      return false;
    }

    // Verificar que no contenga palabras prohibidas o patrones sospechosos
    final lowerNombre = nombre.toLowerCase();
    final palabrasProhibidas = [
      'admin',
      'administrator',
      'root',
      'system',
      'null',
      'undefined',
      'script',
      'javascript',
      'html',
      'css',
      'sql',
      'select',
      'insert',
      'update',
      'delete',
      'drop',
      'create',
      'alter',
      'exec',
      'execute',
    ];

    for (final palabra in palabrasProhibidas) {
      if (lowerNombre.contains(palabra)) {
        return false;
      }
    }

    return true;
  }

  String _sanitizeNombre(String nombre) {
    // Remover caracteres no válidos y espacios extra
    String sanitized = nombre.trim();

    // Reemplazar múltiples espacios con uno solo
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Limitar longitud
    if (sanitized.length > _maxNombreLength) {
      sanitized = sanitized.substring(0, _maxNombreLength);
    }

    return sanitized;
  }

  void _addParticipante() {
    final nombre = _sanitizeNombre(_controller.text.trim().toUpperCase());

    if (!_isValidNombre(nombre)) {
      _showErrorSnackBar(
        'Nombre inválido. Debe tener entre $_minNombreLength y $_maxNombreLength caracteres válidos.',
      );
      return;
    }

    if (participantes.length >= _maxParticipantes) {
      _showErrorSnackBar('Máximo $_maxParticipantes participantes permitidos.');
      return;
    }

    if (participantes.any((p) => p.name == nombre)) {
      _showErrorSnackBar('Este participante ya existe.');
      return;
    }

    setState(() {
      participantes.add(Player.fromString(nombre));
      _controller.clear();
    });
    _saveParticipantes();
  }

  void _removeParticipante(String nombre) {
    setState(() {
      participantes.removeWhere((p) => p.name == nombre);
    });
    _saveParticipantes();
  }

  Future<void> _editParticipante(Player player) async {
    final TextEditingController editController = TextEditingController(
      text: player.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            title: Text(
              'Editar Nombre',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            content: SizedBox(
              width: 280,
              child: TextField(
                controller: editController,
                autofocus: true,
                maxLength: _maxNombreLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(fontSize: 14),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  hintText: 'Ej: JUAN PÉREZ',
                  hintStyle: const TextStyle(fontSize: 14),
                  isDense: true,
                ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(_maxNombreLength),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-ZÁÉÍÓÚÑÜ\s]')),
                ],
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty && _isValidNombre(value.trim())) {
                    Navigator.of(context).pop(value.trim());
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
              ),
              FilledButton(
                onPressed: () {
                  final text = editController.text.trim();
                  if (text.isNotEmpty && _isValidNombre(text)) {
                    Navigator.of(context).pop(text);
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Guardar', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != player.name) {
      // Verificar que el nuevo nombre no exista ya
      final exists = participantes.any(
        (p) => p.name == newName && p.name != player.name,
      );

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe un jugador con ese nombre'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Actualizar el nombre y mantener el color
      final oldName = player.name;
      setState(() {
        final index = participantes.indexWhere((p) => p.name == player.name);
        if (index != -1) {
          participantes[index] = player.copyWith(name: newName);
        }
      });
      // Actualizar el color asociado al nombre
      await _colorService.updatePlayerName(oldName, newName);
      _saveParticipantes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nombre actualizado a: $newName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _startQuickGame() async {
    // Validar cantidad mínima
    if (participantes.length < 2) {
      _showErrorSnackBar('Se necesitan al menos 2 participantes');
      return;
    }

    // Validar que no hay participantes duplicados
    final participantNames = participantes.map((p) => p.name).toList();
    final uniqueNames = participantNames.toSet();

    if (uniqueNames.length != participantNames.length) {
      _showErrorSnackBar(
        'No se pueden tener participantes con el mismo nombre',
      );
      return;
    }

    // Tomar solo los 2 primeros jugadores
    final selectedPlayers = participantNames.take(2).toList();

    if (selectedPlayers.length < 2 ||
        selectedPlayers[0] == selectedPlayers[1]) {
      _showErrorSnackBar('Necesitas 2 jugadores diferentes para jugar');
      return;
    }

    // Establecer orientación landscape ANTES de navegar
    // Hacerlo múltiples veces para asegurar
    for (int i = 0; i < 3; i++) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }

    if (!mounted) return;

    // Navegar con los datos validados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => GameScreen(
              participantes: selectedPlayers,
              modalidad: modalidad,
            ),
      ),
    ).then((_) {
      // Restaurar orientación portrait cuando salgas de GameScreen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });
  }

  void _startTournament() async {
    if (participantes.length < 2) {
      _showErrorSnackBar(
        'Se necesitan al menos 2 participantes para un torneo',
      );
      return;
    }
    await _saveParticipantes();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  TournamentSetupScreen(availablePlayers: participantes),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Configuración',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Estadísticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Preferencias',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xF2EDF0FF)],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) setState(() {});
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 750;
              final double columnSpacing = 16;
              final EdgeInsets contentPadding = EdgeInsets.symmetric(
                horizontal: isWide ? 26 : 18,
                vertical: isWide ? 18 : 16,
              );

              final List<Widget> headerArea = [
                _buildHeader(colorScheme, textTheme),
                const SizedBox(height: 16),
              ];

              final Widget modeCard = _buildModeSelector(
                colorScheme,
                textTheme,
              );
              final Widget addCard = _buildAddParticipantCard(
                colorScheme,
                textTheme,
              );
              final Widget participantsColumn = _buildParticipantsManager(
                colorScheme,
                textTheme,
                isWide,
              );

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: contentPadding,
                child:
                    isWide
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...headerArea,
                                  const SizedBox(height: 18),
                                  modeCard,
                                  const SizedBox(height: 14),
                                  addCard,
                                ],
                              ),
                            ),
                            SizedBox(width: columnSpacing),
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  participantsColumn,
                                  const SizedBox(height: 24),
                                  _buildActionBar(colorScheme, textTheme, true),
                                ],
                              ),
                            ),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...headerArea,
                            const SizedBox(height: 16),
                            modeCard,
                            const SizedBox(height: 14),
                            addCard,
                            const SizedBox(height: 18),
                            participantsColumn,
                            SizedBox(height: mediaQuery.padding.bottom + 28),
                          ],
                        ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar:
          MediaQuery.of(context).size.width < 750
              ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _buildActionBar(colorScheme, textTheme, false),
              )
              : null,
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configura tu partida',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Define modalidad, agrega participantes y comienza a jugar en segundos.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            'Modalidad de puntos',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              _buildModeChip(7, textTheme, colorScheme),
              _buildModeChip(11, textTheme, colorScheme),
              _buildModeChip(21, textTheme, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddParticipantCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: _maxNombreLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: const InputDecoration(
                labelText: 'Agregar participante',
                hintText: 'Ej: JUAN PÉREZ',
                counterText: '',
              ),
              onSubmitted: (_) => _addParticipante(),
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(_maxNombreLength),
                FilteringTextInputFormatter.allow(RegExp(r'[A-ZÁÉÍÓÚÑÜ\s]')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _addParticipante,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(14),
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.add_rounded, size: 22),
          ),
        ],
      ),
    );
  }

  String _initialsFor(String name) {
    return name
        .split(' ')
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .map((segment) => segment.substring(0, 1))
        .join()
        .toUpperCase();
  }

  Widget _buildParticipantsManager(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isWide,
  ) {
    final List<Player> filtered =
        _searchTerm.isEmpty
            ? List<Player>.from(participantes)
            : participantes.where((p) => p.name.contains(_searchTerm)).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Participantes (${participantes.length}/$_maxParticipantes)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ordenar por nombre',
                icon: const Icon(Icons.sort_by_alpha_rounded),
                onPressed:
                    participantes.isEmpty
                        ? null
                        : () {
                          setState(() {
                            participantes.sort(
                              (a, b) => a.name.compareTo(b.name),
                            );
                          });
                        },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchField(colorScheme, textTheme),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                        ? 'Agrega participantes para comenzar'
                        : 'No encontramos coincidencias para "$_searchTerm"',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;
                final int columns =
                    isWide
                        ? math.max(2, math.min(3, availableWidth ~/ 220))
                        : (availableWidth > 360 ? 2 : 1);
                final double spacing = 12;
                final double chipWidth =
                    columns == 1
                        ? availableWidth
                        : (availableWidth - (spacing * (columns - 1))) /
                            columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final player in filtered)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 160,
                          maxWidth: chipWidth,
                        ),
                        child: _participantChip(
                          player: player,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          onEdit: () => _editParticipante(player),
                          onDelete: () => _removeParticipante(player.name),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModeChip(
    int value,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final isSelected = modalidad == value;
    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          value.toString(),
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => modalidad = value),
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.45,
      ),
      selectedColor: colorScheme.primary.withValues(alpha: 0.18),
      side: BorderSide(
        color:
            isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.6),
        width: isSelected ? 1.4 : 1.0,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme, TextTheme textTheme) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchTerm = value.trim().toUpperCase();
        });
      },
      decoration: InputDecoration(
        labelText: 'Buscar participante',
        hintText: 'Ej: LUIS GARCÍA',
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.outline),
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
    );
  }

  Widget _participantChip({
    required Player player,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _initialsFor(player.name),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: colorScheme.primary,
                splashRadius: 20,
                tooltip: 'Editar nombre',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: colorScheme.error,
                splashRadius: 20,
                tooltip: 'Eliminar',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isWide,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text('Partida rápida'),
            onPressed: participantes.length >= 2 ? _startQuickGame : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              elevation: isWide ? 0 : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.emoji_events_outlined, size: 22),
            label: const Text('Modo torneo'),
            onPressed: participantes.length >= 2 ? _startTournament : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
