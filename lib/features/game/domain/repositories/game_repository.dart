import '../entities/game.dart';

abstract class GameRepository {
  Future<List<Game>> getGameHistory();
  Future<void> saveGame(Game game);
  Future<void> clearGameHistory();
  Future<void> saveLastPlayers(String player1, String player2);
  Future<Map<String, String?>> getLastPlayers();
}
