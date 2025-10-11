import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../../core/utils/avatar_helper.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/domain/entities/player.dart';
import '../../game/presentation/widgets/avatar_selection_dialog.dart';
import 'widgets/adaptive_setup_layout.dart';
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
  int modalidad = 11;
  final ScrollController _scrollController = ScrollController();

  // Constantes de seguridad
  static const int _maxParticipantes = 20;
  static const int _maxNombreLength = 20;
  static const int _minNombreLength = 2;
  static final RegExp _nombreRegex = RegExp(r'^[A-ZÁÉÍÓÚÑÜ\s]+$');

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
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
            final avatarId = item['avatarId'] as String?;
            if (name != null && _isValidNombre(name)) {
              loadedParticipantes.add(
                Player(
                  name: name,
                  avatarId: avatarId ?? AvatarHelper.getDefaultAvatar(name).id,
                ),
              );
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
              .map((p) => {'name': p.name, 'avatarId': p.avatarId})
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

      // Actualizar el nombre
      setState(() {
        final index = participantes.indexWhere((p) => p.name == player.name);
        if (index != -1) {
          participantes[index] = player.copyWith(name: newName);
        }
      });
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
    // Validar que no hay participantes duplicados
    final participantNames = participantes.map((p) => p.name).toList();
    if (participantNames.length != participantNames.toSet().length) {
      _showErrorSnackBar(
        'No se pueden tener participantes con el mismo nombre',
      );
      return;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => GameScreen(
                participantes: participantNames,
                modalidad: modalidad,
              ),
        ),
      ).then((_) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
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
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: AdaptiveSetupLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Configura tu partida',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Modalidad',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('7', style: TextStyle(fontSize: 18)),
                  ),
                  selected: modalidad == 7,
                  onSelected: (_) => setState(() => modalidad = 7),
                ),
                ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('11', style: TextStyle(fontSize: 18)),
                  ),
                  selected: modalidad == 11,
                  onSelected: (_) => setState(() => modalidad = 11),
                ),
                ChoiceChip(
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('21', style: TextStyle(fontSize: 18)),
                  ),
                  selected: modalidad == 21,
                  onSelected: (_) => setState(() => modalidad = 21),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participantes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  '${participantes.length}/$_maxParticipantes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    participantes.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 40,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega participantes para comenzar',
                                style: TextStyle(color: colorScheme.outline),
                              ),
                            ],
                          ),
                        )
                        : Scrollbar(
                          thumbVisibility: true,
                          radius: const Radius.circular(12),
                          controller: _scrollController,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: participantes.length,
                            separatorBuilder:
                                (_, __) =>
                                    const Divider(height: 1, thickness: 0.5),
                            itemBuilder: (context, index) {
                              final player = participantes[index];
                              return ListTile(
                                key: ValueKey(
                                  player.name,
                                ), // Agregar key para optimizar rebuilds
                                leading: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AvatarSelectionDialog(
                                            currentPlayer: player,
                                            onAvatarSelected: (updatedPlayer) {
                                              setState(() {
                                                final index = participantes
                                                    .indexWhere(
                                                      (p) =>
                                                          p.name == player.name,
                                                    );
                                                if (index != -1) {
                                                  participantes[index] =
                                                      updatedPlayer;
                                                }
                                              });
                                              _saveParticipantes();
                                            },
                                          ),
                                    );
                                  },
                                  child: AvatarHelper.buildAvatarWidget(
                                    avatarId: player.avatarId,
                                    size: 50,
                                    showBorder: true,
                                  ),
                                ),
                                title: Text(
                                  player.name,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  AvatarHelper.getAvatarById(
                                        player.avatarId,
                                      )?.name ??
                                      '',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colorScheme.outline),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed:
                                          () => _editParticipante(player),
                                      tooltip: 'Editar nombre',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: colorScheme.error,
                                      ),
                                      onPressed:
                                          () =>
                                              _removeParticipante(player.name),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: Colors.transparent,
                              );
                            },
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: _maxNombreLength,
                    decoration: InputDecoration(
                      labelText: 'Agregar participante',
                      counterText: '', // Ocultar contador
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.08,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      hintText: 'Ej: JUAN PÉREZ',
                    ),
                    onChanged: (value) {
                      // Solo rebuild cuando sea necesario
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    onSubmitted: (_) => _addParticipante(),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(_maxNombreLength),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-ZÁÉÍÓÚÑÜ\s]'),
                      ),
                    ],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addParticipante,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.add, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Botón de partida rápida
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text(
                'Partida Rápida',
                style: TextStyle(fontSize: 18),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
                backgroundColor: colorScheme.primary,
              ),
              onPressed: participantes.length >= 2 ? _startQuickGame : null,
            ),
            const SizedBox(height: 12),
            // Botón de torneo
            OutlinedButton.icon(
              icon: Icon(
                Icons.emoji_events,
                size: 28,
                color: colorScheme.primary,
              ),
              label: Text(
                'Modo Torneo',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: colorScheme.primary, width: 2),
                foregroundColor: colorScheme.primary,
              ),
              onPressed: participantes.length >= 2 ? _startTournament : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
