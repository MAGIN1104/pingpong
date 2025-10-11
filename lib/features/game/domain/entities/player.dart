import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String name;
  final String avatarId;
  final String? customAvatarPath; // Para avatares personalizados futuros

  const Player({
    required this.name,
    required this.avatarId,
    this.customAvatarPath,
  });

  Player copyWith({
    String? name,
    String? avatarId,
    String? customAvatarPath,
  }) {
    return Player(
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      customAvatarPath: customAvatarPath ?? this.customAvatarPath,
    );
  }

  // Convertir de String (compatibilidad hacia atrás)
  factory Player.fromString(String name) {
    return Player(
      name: name,
      avatarId: _getDefaultAvatar(name),
    );
  }

  // Convertir a String (compatibilidad hacia atrás)
  @override
  String toString() => name;

  // Obtener avatar por defecto basado en el nombre
  static String _getDefaultAvatar(String name) {
    final hash = name.hashCode;
    final avatars = ['avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6'];
    return avatars[hash.abs() % avatars.length];
  }

  @override
  List<Object?> get props => [name, avatarId, customAvatarPath];
}
