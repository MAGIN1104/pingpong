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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Preferencias',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F4FF), Color(0xFFF9FAFD)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'Personaliza la experiencia y ajusta los detalles de audio, vibración y datos.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 18),

              // Sección de Sonido
              _buildSectionHeader('Sonido y vibración', Icons.volume_up),
              _buildSoundSettings(colorScheme),

              const SizedBox(height: 28),

              // Sección de Datos
              _buildSectionHeader('Datos y estadísticas', Icons.folder_open),
              _buildDataSettings(colorScheme),

              const SizedBox(height: 28),

              // Sección de Acerca de
              _buildSectionHeader('Acerca de la app', Icons.info_outline),
              _buildAboutSettings(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSettings(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Efectos de sonido', style: textTheme.titleSmall),
            subtitle: Text(
              'Reproduce sonidos suaves durante el juego',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await _soundService.setEnabled(value);
              if (value) {
                await _soundService.playClick();
              }
            },
            secondary: Icon(
              Icons.music_note_rounded,
              color: colorScheme.primary,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          if (_soundEnabled) ...[
            Divider(
              height: 1,
              thickness: 0.6,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volume_down_rounded,
                        size: 20,
                        color: colorScheme.outline,
                      ),
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
                      Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                  Text(
                    'Volumen: ${(_soundVolume * 100).round()}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Divider(
            height: 1,
            thickness: 0.6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          SwitchListTile(
            title: Text('Vibración háptica', style: textTheme.titleSmall),
            subtitle: Text(
              'Un toque sutil acompaña cada interacción',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            value: _hapticEnabled,
            onChanged: (value) async {
              setState(() => _hapticEnabled = value);
              await _hapticService.setEnabled(value);
              if (value) {
                await _hapticService.medium();
              }
            },
            secondary: Icon(
              Icons.vibration_rounded,
              color: colorScheme.secondary,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.delete_sweep_outlined,
                color: colorScheme.error,
              ),
            ),
            title: Text('Borrar estadísticas', style: textTheme.titleSmall),
            subtitle: Text(
              'Eliminar todas las estadísticas guardadas',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline,
            ),
            onTap: () => _showResetStatsDialog(context),
          ),
          Divider(
            height: 1,
            thickness: 0.6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.backup_outlined, color: colorScheme.secondary),
            ),
            title: Text('Exportar datos', style: textTheme.titleSmall),
            subtitle: Text(
              'Guarda las estadísticas en un archivo',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline,
            ),
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
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.info_outline, color: colorScheme.primary),
            ),
            title: Text('Versión', style: textTheme.titleSmall),
            subtitle: Text(
              '1.0.0',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.code_rounded, color: colorScheme.secondary),
            ),
            title: Text('Desarrollador', style: textTheme.titleSmall),
            subtitle: Text(
              'Designed by DevMagin',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.bug_report_outlined,
                color: colorScheme.tertiary,
              ),
            ),
            title: Text('Reportar un error', style: textTheme.titleSmall),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacto: maginluna@gmail.com'),
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
