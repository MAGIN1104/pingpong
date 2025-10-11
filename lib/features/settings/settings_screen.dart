import 'package:flutter/material.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/statistics_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hapticService = HapticService();
  final _soundService = SoundService();
  final _statsService = StatisticsService();

  bool _hapticEnabled = true;
  bool _soundEnabled = true;
  double _soundVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _hapticEnabled = _hapticService.isEnabled;
      _soundEnabled = _soundService.isEnabled;
      _soundVolume = _soundService.volume;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de Sonido
          _buildSectionHeader('Sonido y Vibración', Icons.volume_up),
          const SizedBox(height: 8),
          _buildSoundSettings(colorScheme),

          const SizedBox(height: 32),

          // Sección de Datos
          _buildSectionHeader('Datos y Estadísticas', Icons.storage),
          const SizedBox(height: 8),
          _buildDataSettings(colorScheme),

          const SizedBox(height: 32),

          // Sección de Acerca de
          _buildSectionHeader('Acerca de', Icons.info_outline),
          const SizedBox(height: 8),
          _buildAboutSettings(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSoundSettings(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Efectos de Sonido'),
            subtitle: const Text('Reproducir sonidos durante el juego'),
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await _soundService.setEnabled(value);
              if (value) {
                await _soundService.playClick();
              }
            },
            secondary: const Icon(Icons.music_note),
          ),
          if (_soundEnabled) ...[
            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_down, size: 20),
                      Expanded(
                        child: Slider(
                          value: _soundVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_soundVolume * 100).round()}%',
                          onChanged: (value) async {
                            setState(() => _soundVolume = value);
                            await _soundService.setVolume(value);
                          },
                          onChangeEnd: (value) async {
                            await _soundService.playClick();
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 20),
                    ],
                  ),
                  Text(
                    'Volumen: ${(_soundVolume * 100).round()}%',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          SwitchListTile(
            title: const Text('Vibración Háptica'),
            subtitle: const Text('Vibrar durante las interacciones'),
            value: _hapticEnabled,
            onChanged: (value) async {
              setState(() => _hapticEnabled = value);
              await _hapticService.setEnabled(value);
              if (value) {
                await _hapticService.medium();
              }
            },
            secondary: const Icon(Icons.vibration),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Borrar Estadísticas'),
            subtitle: const Text('Eliminar todas las estadísticas guardadas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showResetStatsDialog(context),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Exportar Datos'),
            subtitle: const Text('Guardar estadísticas en un archivo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función próximamente disponible'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0'),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Desarrollador'),
            subtitle: const Text('Designed with ❤️ by Magin'),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Reportar un Error'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacto: tu-email@example.com'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showResetStatsDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Borrar Estadísticas?'),
            content: const Text(
              'Esta acción eliminará todas las estadísticas guardadas de todos los jugadores. Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Borrar'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _statsService.resetAllStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estadísticas borradas exitosamente'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
