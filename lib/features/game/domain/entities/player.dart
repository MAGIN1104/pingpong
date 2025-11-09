import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String name;

  const Player({required this.name});

  Player copyWith({String? name}) {
    return Player(name: name ?? this.name);
  }

  factory Player.fromString(String name) => Player(name: name);

  @override
  String toString() => name;

  @override
  List<Object?> get props => [name];
}
