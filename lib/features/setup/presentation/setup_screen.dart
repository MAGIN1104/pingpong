import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../game/presentation/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<String> participantes = [];
  final TextEditingController _controller = TextEditingController();
  int modalidad = 11;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadParticipantes();
  }

  @override
  void dispose() {
    // Restaurar orientación por defecto solo al salir de SetupScreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forzar orientación vertical cada vez que se entra a SetupScreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _loadParticipantes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('participantes');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        participantes.clear();
        participantes.addAll(decoded.cast<String>());
      });
    }
  }

  Future<void> _saveParticipantes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('participantes', jsonEncode(participantes));
  }

  void _addParticipante() {
    final nombre = _controller.text.trim().toUpperCase();
    if (nombre.isNotEmpty && !participantes.contains(nombre)) {
      setState(() {
        participantes.add(nombre);
        _controller.clear();
      });
      _saveParticipantes();
    }
  }

  void _removeParticipante(String nombre) {
    setState(() {
      participantes.remove(nombre);
    });
    _saveParticipantes();
  }

  void _startQuickGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => GameScreen(
              participantes: List<String>.from(participantes),
              modalidad: modalidad,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Configura tu partida',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Modalidad',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text('7', style: TextStyle(fontSize: 18)),
                    ),
                    selected: modalidad == 7,
                    onSelected: (_) => setState(() => modalidad = 7),
                  ),
                  ChoiceChip(
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text('11', style: TextStyle(fontSize: 18)),
                    ),
                    selected: modalidad == 11,
                    onSelected: (_) => setState(() => modalidad = 11),
                  ),
                  ChoiceChip(
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text('21', style: TextStyle(fontSize: 18)),
                    ),
                    selected: modalidad == 21,
                    onSelected: (_) => setState(() => modalidad = 21),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Participantes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.15),
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
                                final nombre = participantes[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    child: Text(
                                      nombre[0],
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    nombre,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: colorScheme.error,
                                    ),
                                    onPressed:
                                        () => _removeParticipante(nombre),
                                    tooltip: 'Eliminar',
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
                      decoration: InputDecoration(
                        labelText: 'Agregar participante',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.08),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _addParticipante(),
                      inputFormatters: [UpperCaseTextFormatter()],
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
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Comenzar partida',
                  style: TextStyle(fontSize: 20),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: participantes.length >= 2 ? _startQuickGame : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
