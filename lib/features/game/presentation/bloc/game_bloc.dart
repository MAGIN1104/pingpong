import 'dart:async';
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository _repository;
  Timer? _warmupTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  GameBloc(this._repository)
    : super(
        GameState(
          game: Game(
            player1: '',
            player2: '',
            currentServer: '',
            pointsToWin: 11,
          ),
        ),
      ) {
    on<GameStarted>(_onGameStarted);
    on<PlayerScored>(_onPlayerScored);
    on<ScoreDecremented>(_onScoreDecremented);
    on<GameReset>(_onGameReset);
    on<WarmupStarted>(_onWarmupStarted);
    on<WarmupCancelled>(_onWarmupCancelled);
    on<WarmupTicked>(_onWarmupTicked);
    on<ServerChanged>(_onServerChanged);
    on<PlayerChanged>(_onPlayerChanged);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    if (event.participants.length < 2) return;

    final lastPlayers = await _repository.getLastPlayers();
    final player1 = lastPlayers['player1'];
    final player2 = lastPlayers['player2'];

    String initialPlayer1 = player1 ?? event.participants[0];
    String initialPlayer2 = player2 ?? event.participants[1];

    if (!event.participants.contains(initialPlayer1)) {
      initialPlayer1 = event.participants[0];
    }
    if (!event.participants.contains(initialPlayer2)) {
      initialPlayer2 = event.participants[1];
    }

    final gameHistory = await _repository.getGameHistory();

    emit(
      state.copyWith(
        game: Game(
          player1: initialPlayer1,
          player2: initialPlayer2,
          currentServer: initialPlayer1,
          pointsToWin: event.pointsToWin,
        ),
        gameHistory: gameHistory,
      ),
    );
  }

  Future<void> _onPlayerScored(
    PlayerScored event,
    Emitter<GameState> emit,
  ) async {
    final currentGame = state.game;
    int newScore1 = currentGame.score1;
    int newScore2 = currentGame.score2;

    if (event.isPlayer1) {
      newScore1++;
    } else {
      newScore2++;
    }

    final newGame = _handleGameLogic(
      currentGame.copyWith(score1: newScore1, score2: newScore2),
    );

    _checkMatchPoint(newGame, emit);

    if (newGame.hasWinner) {
      await _handleWinner(newGame, emit);
    }

    emit(state.copyWith(game: newGame));
  }

  void _onScoreDecremented(ScoreDecremented event, Emitter<GameState> emit) {
    final currentGame = state.game;
    if ((event.isPlayer1 && currentGame.score1 == 0) ||
        (!event.isPlayer1 && currentGame.score2 == 0)) {
      return;
    }

    final newGame = _handleGameLogic(
      currentGame.copyWith(
        score1: event.isPlayer1 ? currentGame.score1 - 1 : currentGame.score1,
        score2: event.isPlayer1 ? currentGame.score2 : currentGame.score2 - 1,
      ),
    );

    _checkMatchPoint(newGame, emit);
    emit(state.copyWith(game: newGame));
  }

  Game _handleGameLogic(Game game) {
    // Manejo de saques
    int remainingServes = game.remainingServes;
    String currentServer = game.currentServer;

    if (game.isExtendedMode) {
      // En modo extendido, el saque cambia en cada punto
      currentServer =
          currentServer == game.player1 ? game.player2 : game.player1;
      remainingServes = 1;
    } else {
      // Modo normal: cambio de saque cada 2 puntos
      if (remainingServes == 1) {
        currentServer =
            currentServer == game.player1 ? game.player2 : game.player1;
        remainingServes = 2;
      } else {
        remainingServes--;
      }
    }

    return game.copyWith(
      currentServer: currentServer,
      remainingServes: remainingServes,
    );
  }

  void _checkMatchPoint(Game game, Emitter<GameState> emit) async {
    if (game.isExtendedMode) {
      final hasAdvantage =
          (game.score1 == game.score2 + 1) || (game.score2 == game.score1 + 1);

      if (hasAdvantage &&
          state.lastMatchPointShown != math.max(game.score1, game.score2)) {
        _playMatchPointSound();
        emit(
          state.copyWith(
            showMatchPoint: true,
            lastMatchPointShown: math.max(game.score1, game.score2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (state.showMatchPoint) {
          emit(state.copyWith(showMatchPoint: false));
        }
      }
    } else {
      final matchPoint = game.pointsToWin - 1;
      final isMatchPoint =
          game.score1 == matchPoint || game.score2 == matchPoint;

      if (isMatchPoint && state.lastMatchPointShown != matchPoint) {
        _playMatchPointSound();
        emit(
          state.copyWith(showMatchPoint: true, lastMatchPointShown: matchPoint),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (state.showMatchPoint) {
          emit(state.copyWith(showMatchPoint: false));
        }
      }
    }
  }

  Future<void> _handleWinner(Game game, Emitter<GameState> emit) async {
    await _repository.saveGame(game.copyWith(timestamp: DateTime.now()));
    final gameHistory = await _repository.getGameHistory();
    emit(state.copyWith(gameHistory: gameHistory));
    _playWinSound();
  }

  void _onGameReset(GameReset event, Emitter<GameState> emit) {
    emit(
      state.copyWith(
        game: state.game.copyWith(score1: 0, score2: 0, remainingServes: 2),
        showMatchPoint: false,
        lastMatchPointShown: -1,
      ),
    );
  }

  void _onWarmupStarted(WarmupStarted event, Emitter<GameState> emit) {
    _warmupTimer?.cancel();
    emit(
      state.copyWith(
        game: state.game.copyWith(
          isWarmingUp: true,
          warmupTimeRemaining: event.seconds,
        ),
      ),
    );

    _warmupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(WarmupTicked()),
    );
  }

  void _onWarmupCancelled(WarmupCancelled event, Emitter<GameState> emit) {
    _warmupTimer?.cancel();
    emit(
      state.copyWith(
        game: state.game.copyWith(isWarmingUp: false, warmupTimeRemaining: 0),
      ),
    );
  }

  void _onWarmupTicked(WarmupTicked event, Emitter<GameState> emit) {
    if (state.game.warmupTimeRemaining > 0) {
      emit(
        state.copyWith(
          game: state.game.copyWith(
            warmupTimeRemaining: state.game.warmupTimeRemaining - 1,
          ),
        ),
      );

      if (state.game.warmupTimeRemaining == 0) {
        _warmupTimer?.cancel();
        emit(state.copyWith(game: state.game.copyWith(isWarmingUp: false)));
      }
    }
  }

  void _onServerChanged(ServerChanged event, Emitter<GameState> emit) {
    if (event.newServer == state.game.player1 ||
        event.newServer == state.game.player2) {
      emit(
        state.copyWith(
          game: state.game.copyWith(
            currentServer: event.newServer,
            remainingServes: 2,
          ),
        ),
      );
    }
  }

  Future<void> _onPlayerChanged(
    PlayerChanged event,
    Emitter<GameState> emit,
  ) async {
    Game newGame = state.game;
    if (event.isPlayer1) {
      newGame = newGame.copyWith(player1: event.newPlayer);
      if (newGame.player2 == event.newPlayer) {
        // Evitar duplicados
        newGame = newGame.copyWith(player2: newGame.player1);
      }
    } else {
      newGame = newGame.copyWith(player2: event.newPlayer);
      if (newGame.player1 == event.newPlayer) {
        // Evitar duplicados
        newGame = newGame.copyWith(player1: newGame.player2);
      }
    }

    await _repository.saveLastPlayers(newGame.player1, newGame.player2);
    emit(state.copyWith(game: newGame));
  }

  void _playMatchPointSound() {
    _audioPlayer.play(AssetSource('matchpoint.mp3'));
  }

  void _playWinSound() {
    _audioPlayer.play(AssetSource('win.mp3'));
  }

  @override
  Future<void> close() {
    _warmupTimer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
