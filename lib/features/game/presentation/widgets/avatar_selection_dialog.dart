import 'package:flutter/material.dart';
import 'package:ping_pong_fie/core/utils/avatar_helper.dart';
import '../../domain/entities/player.dart';

class AvatarSelectionDialog extends StatefulWidget {
  final Player currentPlayer;
  final Function(Player) onAvatarSelected;

  const AvatarSelectionDialog({
    super.key,
    required this.currentPlayer,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarSelectionDialog> createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  late String selectedAvatarId;

  @override
  void initState() {
    super.initState();
    selectedAvatarId = widget.currentPlayer.avatarId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Seleccionar Avatar para ${widget.currentPlayer.name}',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar actual seleccionado (más grande)
            const SizedBox(height: 16),
            AvatarHelper.buildAvatarWidget(
              avatarId: selectedAvatarId,
              size: 80,
            ),
            const SizedBox(height: 8),
            Text(
              AvatarHelper.getAvatarById(selectedAvatarId)?.name ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            // Grid de avatares disponibles
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: AvatarHelper.availableAvatars.length,
              itemBuilder: (context, index) {
                final avatar = AvatarHelper.availableAvatars[index];
                final isSelected = avatar.id == selectedAvatarId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAvatarId = avatar.id;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? avatar.color : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: avatar.color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatar.color.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: ClipOval(
                          child: Image.asset(
                            avatar.imagePath,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback a emoji si la imagen no se puede cargar
                              return Text(
                                avatar.emoji,
                                style: const TextStyle(fontSize: 24),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final updatedPlayer = widget.currentPlayer.copyWith(
              avatarId: selectedAvatarId,
            );
            widget.onAvatarSelected(updatedPlayer);
            Navigator.of(context).pop();
          },
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }
}

// Widget para mostrar avatar con opción de edición
class EditableAvatar extends StatelessWidget {
  final Player player;
  final Function(Player) onAvatarChanged;
  final double size;
  final bool showEditIcon;

  const EditableAvatar({
    super.key,
    required this.player,
    required this.onAvatarChanged,
    this.size = 60.0,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AvatarHelper.buildAvatarWidget(avatarId: player.avatarId, size: size),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AvatarSelectionDialog(
                        currentPlayer: player,
                        onAvatarSelected: onAvatarChanged,
                      ),
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
