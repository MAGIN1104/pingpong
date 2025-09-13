import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';

class SharedPreferencesGameRepository implements GameRepository {
  static const String _gamesKey = 'partidas';
  static const String _lastPlayer1Key = 'last_player1';
  static const String _lastPlayer2Key = 'last_player2';

  @override
  Future<List<Game>> getGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesStr = prefs.getString(_gamesKey);
    if (gamesStr == null) return [];

    final List<dynamic> decoded = jsonDecode(gamesStr);
    return decoded.map((gameData) {
      return Game(
        player1: gameData['p1'] as String,
        player2: gameData['p2'] as String,
        score1: gameData['s1'] as int,
        score2: gameData['s2'] as int,
        currentServer: gameData['p1'] as String,
        pointsToWin: 11,
        timestamp: DateTime.parse(gameData['fecha'] as String),
      );
    }).toList();
  }

  @override
  Future<void> saveGame(Game game) async {
    final prefs = await SharedPreferences.getInstance();
    final currentGames = await getGameHistory();

    currentGames.add(game);

    final gameDataList =
        currentGames
            .map(
              (game) => {
                'p1': game.player1,
                'p2': game.player2,
                's1': game.score1,
                's2': game.score2,
                'fecha':
                    game.timestamp?.toIso8601String() ??
                    DateTime.now().toIso8601String(),
              },
            )
            .toList();

    await prefs.setString(_gamesKey, jsonEncode(gameDataList));
  }

  @override
  Future<void> clearGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gamesKey);
  }

  @override
  Future<void> saveLastPlayers(String player1, String player2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayer1Key, player1);
    await prefs.setString(_lastPlayer2Key, player2);
  }

  @override
  Future<Map<String, String?>> getLastPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'player1': prefs.getString(_lastPlayer1Key),
      'player2': prefs.getString(_lastPlayer2Key),
    };
  }
}
