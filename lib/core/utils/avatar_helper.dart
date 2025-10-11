import 'package:flutter/material.dart';

class AvatarHelper {
  // Lista de avatares disponibles - Personajes Épicos
  static const List<AvatarData> availableAvatars = [
    // MARVEL / AVENGERS
    AvatarData(
      id: 'avatar_1',
      emoji: '🦸‍♂️',
      name: 'Iron Man',
      color: Color(0xFFD32F2F),
      imagePath: 'assets/avatars/avatar_1.svg',
    ),
    AvatarData(
      id: 'avatar_2',
      emoji: '🛡️',
      name: 'Cap América',
      color: Color(0xFF1976D2),
      imagePath: 'assets/avatars/avatar_2.svg',
    ),
    AvatarData(
      id: 'avatar_3',
      emoji: '💪',
      name: 'Hulk',
      color: Color(0xFF388E3C),
      imagePath: 'assets/avatars/avatar_3.svg',
    ),
    AvatarData(
      id: 'avatar_4',
      emoji: '⚡',
      name: 'Thor',
      color: Color(0xFF0277BD),
      imagePath: 'assets/avatars/avatar_4.svg',
    ),
    AvatarData(
      id: 'avatar_5',
      emoji: '🕷️',
      name: 'Spider-Man',
      color: Color(0xFFD32F2F),
      imagePath: 'assets/avatars/avatar_5.svg',
    ),
    AvatarData(
      id: 'avatar_6',
      emoji: '🐆',
      name: 'Pantera',
      color: Color(0xFF424242),
      imagePath: 'assets/avatars/avatar_6.svg',
    ),

    // CARS / PIXAR
    AvatarData(
      id: 'avatar_7',
      emoji: '🏎️',
      name: 'Rayo McQueen',
      color: Color(0xFFD32F2F),
      imagePath: 'assets/avatars/avatar_7.svg',
    ),
    AvatarData(
      id: 'avatar_8',
      emoji: '🚗',
      name: 'Mate',
      color: Color(0xFF8D6E63),
      imagePath: 'assets/avatars/avatar_8.svg',
    ),

    // STAR WARS
    AvatarData(
      id: 'avatar_9',
      emoji: '⚔️',
      name: 'Jedi',
      color: Color(0xFF1976D2),
      imagePath: 'assets/avatars/avatar_9.svg',
    ),
    AvatarData(
      id: 'avatar_10',
      emoji: '🤖',
      name: 'R2-D2',
      color: Color(0xFF0288D1),
      imagePath: 'assets/avatars/avatar_10.svg',
    ),

    // DISNEY CLÁSICOS
    AvatarData(
      id: 'avatar_11',
      emoji: '🐭',
      name: 'Mickey',
      color: Color(0xFFD32F2F),
      imagePath: 'assets/avatars/avatar_11.svg',
    ),
    AvatarData(
      id: 'avatar_12',
      emoji: '❄️',
      name: 'Elsa',
      color: Color(0xFF0288D1),
      imagePath: 'assets/avatars/avatar_12.svg',
    ),

    // TOY STORY
    AvatarData(
      id: 'avatar_13',
      emoji: '🚀',
      name: 'Buzz',
      color: Color(0xFF7B1FA2),
      imagePath: 'assets/avatars/avatar_13.svg',
    ),
    AvatarData(
      id: 'avatar_14',
      emoji: '🤠',
      name: 'Woody',
      color: Color(0xFFF57C00),
      imagePath: 'assets/avatars/avatar_14.svg',
    ),
    AvatarData(
      id: 'avatar_15',
      emoji: '🦖',
      name: 'Rex',
      color: Color(0xFF388E3C),
      imagePath: 'assets/avatars/avatar_15.svg',
    ),

    // MINIONS
    AvatarData(
      id: 'avatar_16',
      emoji: '😄',
      name: 'Minion',
      color: Color(0xFFFDD835),
      imagePath: 'assets/avatars/avatar_16.svg',
    ),

    // DC COMICS
    AvatarData(
      id: 'avatar_17',
      emoji: '🦇',
      name: 'Batman',
      color: Color(0xFF212121),
      imagePath: 'assets/avatars/avatar_17.svg',
    ),
    AvatarData(
      id: 'avatar_18',
      emoji: '⚡',
      name: 'Flash',
      color: Color(0xFFD32F2F),
      imagePath: 'assets/avatars/avatar_18.svg',
    ),
    AvatarData(
      id: 'avatar_19',
      emoji: '🌊',
      name: 'Aquaman',
      color: Color(0xFF00838F),
      imagePath: 'assets/avatars/avatar_19.svg',
    ),

    // MARIO BROS
    AvatarData(
      id: 'avatar_20',
      emoji: '🍄',
      name: 'Mario',
      color: Color(0xFFD32F2F),
      imagePath: 'assets/avatars/avatar_20.svg',
    ),
    AvatarData(
      id: 'avatar_21',
      emoji: '👻',
      name: 'Luigi',
      color: Color(0xFF388E3C),
      imagePath: 'assets/avatars/avatar_21.svg',
    ),

    // POKÉMON
    AvatarData(
      id: 'avatar_22',
      emoji: '⚡',
      name: 'Pikachu',
      color: Color(0xFFFDD835),
      imagePath: 'assets/avatars/avatar_22.svg',
    ),
    AvatarData(
      id: 'avatar_23',
      emoji: '🔥',
      name: 'Charizard',
      color: Color(0xFFFF6F00),
      imagePath: 'assets/avatars/avatar_23.svg',
    ),

    // VIDEOJUEGOS CLÁSICOS
    AvatarData(
      id: 'avatar_24',
      emoji: '👾',
      name: 'Pac-Man',
      color: Color(0xFFFDD835),
      imagePath: 'assets/avatars/avatar_24.svg',
    ),
  ];

  // Obtener avatar por ID
  static AvatarData? getAvatarById(String id) {
    try {
      return availableAvatars.firstWhere((avatar) => avatar.id == id);
    } catch (e) {
      return availableAvatars.first; // Avatar por defecto
    }
  }

  // Obtener avatar aleatorio
  static AvatarData getRandomAvatar() {
    final random =
        DateTime.now().millisecondsSinceEpoch % availableAvatars.length;
    return availableAvatars[random];
  }

  // Obtener avatar por defecto basado en nombre
  static AvatarData getDefaultAvatar(String name) {
    final hash = name.hashCode;
    return availableAvatars[hash.abs() % availableAvatars.length];
  }

  // Crear widget de avatar
  static Widget buildAvatarWidget({
    required String avatarId,
    double size = 60.0,
    bool showBorder = true,
    Color? borderColor,
    bool useImage = true,
  }) {
    final avatar = getAvatarById(avatarId) ?? availableAvatars.first;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatar.color.withValues(alpha: 0.2),
        border:
            showBorder
                ? Border.all(color: borderColor ?? avatar.color, width: 3)
                : null,
        boxShadow:
            showBorder
                ? [
                  BoxShadow(
                    color: avatar.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: Center(
        child:
            useImage && avatar.imagePath.isNotEmpty
                ? ClipOval(
                  child: Image.asset(
                    avatar.imagePath,
                    width: size * 0.8,
                    height: size * 0.8,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback a emoji si la imagen no se puede cargar
                      return Text(
                        avatar.emoji,
                        style: TextStyle(fontSize: size * 0.5),
                      );
                    },
                  ),
                )
                : Text(avatar.emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

class AvatarData {
  final String id;
  final String emoji;
  final String name;
  final Color color;
  final String imagePath;

  const AvatarData({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
    required this.imagePath,
  });
}
