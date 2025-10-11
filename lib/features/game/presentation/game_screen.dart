import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'results_screen.dart';
import 'dart:async';
import '../../../core/utils/avatar_helper.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/statistics_service.dart';

class GameScreen extends StatefulWidget {
  final List<String> participantes;
  final int modalidad;
  final bool isTournamentMode;
  final String? tournamentMatchId;

  const GameScreen({
    super.key,
    required this.participantes,
    required this.modalidad,
    this.isTournamentMode = false,
    this.tournamentMatchId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score1 = 0;
  int score2 = 0;
  String? player1;
  String? player2;
  String? saqueInicial;
  String? saqueActual;
  String? player1AvatarId;
  String? player2AvatarId;
  int saquesRestantes = 2;
  bool showMatchPoint = false;
  int ultimoMatchPointMostrado = -1;
  int puntosParaGanar = 11;
  int puntosParaMatchPoint = 10;
  String? winnerName;
  late ConfettiController _confettiController;
  List<Map<String, dynamic>> partidas = [];

  bool _isWarmingUp = false;
  int _warmupRemaining = 0;
  Timer? _warmupTimer;

  // Servicios
  final _hapticService = HapticService();
  final _soundService = SoundService();
  final _statsService = StatisticsService();

  Future<void> _initServices() async {
    await _hapticService.init();
    await _soundService.init();
    await _statsService.init();
  }

  @override
  void initState() {
    super.initState();
    _initServices();
    Future.delayed(Duration.zero, () async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    puntosParaGanar = widget.modalidad;
    puntosParaMatchPoint = widget.modalidad - 1;
    if (widget.participantes.length >= 2) {
      // Validar que los jugadores no sean iguales
      if (widget.participantes[0] == widget.participantes[1]) {
        // Mostrar error y volver
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pueden tener jugadores con el mismo nombre'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        });
        return;
      }

      player1 = widget.participantes[0];
      player2 = widget.participantes[1];
      player1AvatarId = AvatarHelper.getDefaultAvatar(player1!).id;
      player2AvatarId = AvatarHelper.getDefaultAvatar(player2!).id;
      saqueInicial = player1;
      saqueActual = player1;
    }
    _loadPartidas();
    _loadLastPlayers();
    _warmupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onWarmupTick(),
    );
  }

  void _onWarmupTick() {
    if (_warmupRemaining > 0) {
      setState(() {
        _warmupRemaining--;
        if (_warmupRemaining <= 0) {
          _isWarmingUp = false;
          _warmupTimer?.cancel();
        }
      });
    }
  }

  void _startWarmup(int seconds) {
    setState(() {
      _isWarmingUp = true;
      _warmupRemaining = seconds;
    });
    _warmupTimer?.cancel();
    _warmupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onWarmupTick(),
    );
  }

  Future<void> _loadPartidas() async {
    final prefs = await SharedPreferences.getInstance();
    final partidasStr = prefs.getString('partidas');
    if (partidasStr != null) {
      final List<dynamic> decoded = jsonDecode(partidasStr);
      setState(() {
        partidas = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _savePartida() async {
    final prefs = await SharedPreferences.getInstance();
    partidas.add({
      "p1": player1,
      "p2": player2,
      "s1": score1,
      "s2": score2,
      "fecha": DateTime.now().toIso8601String(),
    });
    await prefs.setString('partidas', jsonEncode(partidas));
  }

  Future<void> _clearPartidas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('partidas');
    setState(() {
      partidas.clear();
    });
  }

  Future<void> _saveLastPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_player1', player1 ?? '');
    await prefs.setString('last_player2', player2 ?? '');
  }

  Future<void> _loadLastPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final last1 = prefs.getString('last_player1');
    final last2 = prefs.getString('last_player2');
    if (last1 != null && widget.participantes.contains(last1)) {
      setState(() {
        player1 = last1;
        player1AvatarId = AvatarHelper.getDefaultAvatar(last1).id;
      });
    }
    if (last2 != null && widget.participantes.contains(last2)) {
      setState(() {
        player2 = last2;
        player2AvatarId = AvatarHelper.getDefaultAvatar(last2).id;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _warmupTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _incrementScore(bool isPlayer1) {
    // No permitir incrementar durante el calentamiento
    if (_isWarmingUp) return;

    // Haptic feedback y sonido
    _hapticService.light();
    _soundService.playScoreUp();

    setState(() {
      if (isPlayer1) {
        score1++;
      } else {
        score2++;
      }
      _handleSaque();
      _checkMatchPoint();
      _checkWinner();
    });
  }

  void _decrementScore(bool isPlayer1) {
    // No permitir decrementar durante el calentamiento
    if (_isWarmingUp) return;

    // Haptic feedback y sonido
    _hapticService.medium();
    _soundService.playScoreDown();

    setState(() {
      if (isPlayer1 && score1 > 0) {
        score1--;
      } else if (!isPlayer1 && score2 > 0) {
        score2--;
      }

      bool modoExtendido =
          score1 >= puntosParaMatchPoint && score2 >= puntosParaMatchPoint;
      if (modoExtendido) {
        saqueActual = saqueActual == player1 ? player2 : player1;
        saquesRestantes = 1;
      } else {
        int totalPuntos = score1 + score2;
        int cadaCuantos = 2;
        if (totalPuntos == 0) {
          saquesRestantes = cadaCuantos;
          saqueActual = saqueInicial ?? player1;
        } else {
          int turnos = totalPuntos ~/ cadaCuantos;
          saquesRestantes = cadaCuantos - (totalPuntos % cadaCuantos);
          if (turnos % 2 == 0) {
            saqueActual = saqueInicial ?? player1;
          } else {
            saqueActual =
                (saqueInicial ?? player1) == player1 ? player2 : player1;
          }
        }
      }
      _checkMatchPoint();
    });
  }

  void _handleSaque() {
    bool modoExtendido =
        score1 >= puntosParaMatchPoint && score2 >= puntosParaMatchPoint;
    if (modoExtendido) {
      saqueActual = saqueActual == player1 ? player2 : player1;
      saquesRestantes = 1;
    } else {
      int cadaCuantos = 2;
      if (score1 + score2 == 0) {
        saquesRestantes = cadaCuantos;
        return;
      }
      if (saquesRestantes == 1) {
        saqueActual = saqueActual == player1 ? player2 : player1;
        saquesRestantes = cadaCuantos;
      } else {
        saquesRestantes--;
      }
    }
  }

  void _checkMatchPoint() async {
    // En modo extendido (después de empate a 10) se necesita una ventaja de 2 puntos
    bool modoExtendido =
        score1 >= puntosParaMatchPoint && score2 >= puntosParaMatchPoint;
    if (modoExtendido) {
      // En modo extendido, cada punto puede ser match point si hay ventaja
      final enMatchPoint = (score1 == score2 + 1) || (score2 == score1 + 1);
      if (enMatchPoint && ultimoMatchPointMostrado != max(score1, score2)) {
        setState(() {
          showMatchPoint = true;
          ultimoMatchPointMostrado = max(score1, score2);
        });
        _confettiController.play();
        final player = AudioPlayer();
        player.play(AssetSource('matchpoint.mp3'));
        Future.delayed(const Duration(seconds: 2)).then((_) {
          if (mounted && showMatchPoint) {
            setState(() => showMatchPoint = false);
          }
        });
      }
    } else {
      // Modo normal (antes del empate a 10)
      final matchPointActual = puntosParaMatchPoint;
      final enMatchPoint =
          (score1 == matchPointActual || score2 == matchPointActual);
      if (enMatchPoint && ultimoMatchPointMostrado != matchPointActual) {
        setState(() {
          showMatchPoint = true;
          ultimoMatchPointMostrado = matchPointActual;
        });
        _confettiController.play();
        final player = AudioPlayer();
        player.play(AssetSource('matchpoint.mp3'));
        Future.delayed(const Duration(seconds: 2)).then((_) {
          if (mounted && showMatchPoint) {
            setState(() => showMatchPoint = false);
          }
        });
      }
    }
  }

  void _checkWinner() {
    bool modoExtendido =
        score1 >= puntosParaMatchPoint && score2 >= puntosParaMatchPoint;
    bool hayGanador = false;

    if (modoExtendido) {
      // En modo extendido, se necesita una ventaja de 2 puntos
      if ((score1 >= puntosParaGanar && score1 - score2 >= 2) ||
          (score2 >= puntosParaGanar && score2 - score1 >= 2)) {
        hayGanador = true;
      }
    } else {
      // En modo normal, se gana al llegar a los puntos establecidos
      // Solo uno puede tener >= puntosParaGanar cuando no están en modo extendido
      if (score1 >= puntosParaGanar || score2 >= puntosParaGanar) {
        hayGanador = true;
      }
    }

    if (hayGanador) {
      final winner = score1 > score2 ? player1 : player2;
      final loser = score1 > score2 ? player2 : player1;

      if (winner == null || loser == null) return;

      winnerName = winner;

      _savePartida();

      // Guardar estadísticas
      _statsService.recordGame(
        winnerName: winner,
        loserName: loser,
        winnerScore: score1 > score2 ? score1 : score2,
        loserScore: score1 > score2 ? score2 : score1,
        modality: puntosParaGanar,
      );

      // Haptic y sonido de victoria
      _hapticService.victory();
      _soundService.playWin();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Si es modo torneo, mostrar diálogo y regresar al bracket automáticamente
          if (widget.isTournamentMode) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _buildTournamentWinnerDialog(winner, loser),
            ).then((dialogResult) {
              // Regresar al bracket con el resultado
              if (mounted) {
                print('🏆 Torneo: Cerrando partido. Ganador: $winner');
                Navigator.of(context).pop({
                  'matchId': widget.tournamentMatchId,
                  'winner': winner,
                  'score1': score1,
                  'score2': score2,
                });
              }
            });
          } else {
            // Modo normal - mostrar diálogo y resetear
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _buildWinnerDialog(winnerName!),
            ).then((_) {
              // Reset automático después de cerrar el diálogo del ganador
              _resetGame();
            });
          }
        }
      });
    }
  }

  void _resetGame() {
    setState(() {
      score1 = 0;
      score2 = 0;
      saqueActual = saqueInicial ?? player1;
      saquesRestantes = 2;
      showMatchPoint = false;
      ultimoMatchPointMostrado = -1;
    });
  }

  Widget _buildScoreCard(
    String player,
    int score,
    bool isLeft,
    ColorScheme colorScheme, {
    double scoreFontSize = 110,
    double nameFontSize = 18,
    double cardHeight = 400,
  }) {
    final avatarId = isLeft ? player1AvatarId : player2AvatarId;
    final isSaque = saqueActual == player;
    final isWinner = (score == puntosParaGanar);
    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool showMinus = false;
        Color? bgColor;
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = cardHeight;
            final isSmall = availableHeight < 220;
            final localScoreFont = isSmall ? 48.0 : scoreFontSize;
            final nameFont = isSmall ? 16.0 : nameFontSize;
            final namePad = isSmall ? 2.0 : 8.0;
            return GestureDetector(
              onTap:
                  _isWarmingUp
                      ? null
                      : () {
                        _incrementScore(isLeft);
                      },
              onVerticalDragEnd:
                  _isWarmingUp
                      ? null
                      : (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! > 0) {
                          _decrementScore(isLeft);
                          setLocalState(() {
                            showMinus = true;
                            bgColor = Colors.red.withValues(alpha: .15);
                          });
                          Future.delayed(const Duration(milliseconds: 400), () {
                            setLocalState(() {
                              showMinus = false;
                              bgColor = null;
                            });
                          });
                        }
                      },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: cardHeight,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                decoration: BoxDecoration(
                  color:
                      bgColor ??
                      (isWinner
                          ? colorScheme.primaryContainer
                          : isSaque
                          ? colorScheme.error.withValues(alpha: .15)
                          : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isSaque ? colorScheme.error : colorScheme.outline,
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: namePad,
                          ),
                          child: PopupMenuButton<String>(
                            initialValue: player,
                            tooltip:
                                _isWarmingUp
                                    ? 'No disponible durante calentamiento'
                                    : 'Seleccionar jugador',
                            enabled:
                                !_isWarmingUp, // Deshabilitar durante calentamiento
                            onSelected: (nuevo) {
                              if (nuevo != player) {
                                setState(() {
                                  if (isLeft) {
                                    player1 = nuevo;
                                    player1AvatarId =
                                        AvatarHelper.getDefaultAvatar(nuevo).id;
                                    if (player2 == nuevo) {
                                      player2 = widget.participantes.firstWhere(
                                        (n) => n != nuevo,
                                        orElse: () => '',
                                      );
                                      player2AvatarId =
                                          AvatarHelper.getDefaultAvatar(
                                            player2!,
                                          ).id;
                                    }
                                    _saveLastPlayers();
                                  } else {
                                    player2 = nuevo;
                                    player2AvatarId =
                                        AvatarHelper.getDefaultAvatar(nuevo).id;
                                    if (player1 == nuevo) {
                                      player1 = widget.participantes.firstWhere(
                                        (n) => n != nuevo,
                                        orElse: () => '',
                                      );
                                      player1AvatarId =
                                          AvatarHelper.getDefaultAvatar(
                                            player1!,
                                          ).id;
                                    }
                                    _saveLastPlayers();
                                  }
                                });
                              }
                            },
                            itemBuilder:
                                (context) =>
                                    widget.participantes
                                        .where(
                                          (nombre) =>
                                              nombre !=
                                              (isLeft ? player2 : player1),
                                        )
                                        .map(
                                          (nombre) => PopupMenuItem<String>(
                                            value: nombre,
                                            child: Text(nombre),
                                          ),
                                        )
                                        .toList(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Avatar prominente del jugador
                                if (avatarId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AvatarHelper.buildAvatarWidget(
                                      avatarId: avatarId,
                                      size: isSmall ? 45 : 60,
                                      showBorder: true,
                                      borderColor:
                                          isSaque ? colorScheme.error : null,
                                    ),
                                  ),
                                // Nombre con icono de saque
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isSaque)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: Icon(
                                          Icons.sports_tennis,
                                          size: nameFont + 2,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    Text(
                                      player,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                        fontSize: nameFont,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$score',
                              style: Theme.of(
                                context,
                              ).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: localScoreFont,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showMinus)
                      Positioned(
                        bottom: 32,
                        child: AnimatedOpacity(
                          opacity: showMinus ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '-1',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Overlay durante calentamiento
                    if (_isWarmingUp)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 32, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  'Bloqueado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTournamentWinnerDialog(String winner, String loser) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 340,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con gradiente
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'VICTORIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Ganador destacado
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, color: Colors.green, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'GANADOR',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              winner,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${score1 > score2 ? score1 : score2} puntos',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Perdedor sutil
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              loser,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${score1 > score2 ? score2 : score1} pts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Botón de acción
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text(
                            'Continuar Torneo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerDialog(String winner) {
    final player = AudioPlayer();
    player.play(AssetSource('win.mp3'));
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '¡GANADOR!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                winner,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nueva partida'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetGame();
                    },
                  ),
                  TextButton(
                    child: const Text('Ver resultados'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ResultsScreen(
                                partidas: partidas,
                                onClear: _clearPartidas,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Partida en curso'), centerTitle: true),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = constraints.maxHeight;
              final cardPadding = 0.0;
              final cardFontSize = cardHeight > 400 ? 160.0 : 120.0;
              final nameFontSize = cardHeight > 400 ? 20.0 : 16.0;
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(cardPadding),
                      child: _buildScoreCard(
                        player1!,
                        score1,
                        true,
                        colorScheme,
                        scoreFontSize: cardFontSize,
                        nameFontSize: nameFontSize,
                        cardHeight: cardHeight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(cardPadding),
                      child: _buildScoreCard(
                        player2!,
                        score2,
                        false,
                        colorScheme,
                        scoreFontSize: cardFontSize,
                        nameFontSize: nameFontSize,
                        cardHeight: cardHeight,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_isWarmingUp)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(24),
                    color: colorScheme.primaryContainer,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.secondaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: .18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Calentamiento',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                'Las puntuaciones están bloqueadas',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Text(
                            '${(_warmupRemaining ~/ 60).toString().padLeft(2, '0')}:${(_warmupRemaining % 60).toString().padLeft(2, '0')}',
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: colorScheme.error,
                              size: 28,
                            ),
                            tooltip: 'Cancelar calentamiento',
                            onPressed: () {
                              setState(() {
                                _isWarmingUp = false;
                                _warmupTimer?.cancel();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
            left: 16,
            right: 16,
            top: 4,
          ),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.sports_tennis),
            label: Text(
              saqueActual ?? 'Seleccionar saque inicial',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onPressed: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Selecciona quién saca primero'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children:
                            [player1, player2]
                                .where((n) => n != null)
                                .map(
                                  (nombre) => ListTile(
                                    title: Text(nombre!),
                                    onTap:
                                        () => Navigator.of(context).pop(nombre),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  );
                },
              );
              if (selected != null &&
                  (selected == player1 || selected == player2)) {
                // Activar orientación landscape al iniciar la partida
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
                setState(() {
                  saqueActual = selected;
                  saqueInicial = selected;
                  saquesRestantes = 2;
                });
              }
            },
          ),
        ),
      ),
      floatingActionButton: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'warmup',
              onPressed: () async {
                int selectedSeconds = 60;
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Tiempo de calentamiento'),
                      content: StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Slider(
                                value: selectedSeconds.toDouble(),
                                min: 30,
                                max: 300,
                                divisions: 9,
                                label:
                                    '${selectedSeconds ~/ 60}:${(selectedSeconds % 60).toString().padLeft(2, '0')}',
                                onChanged: (v) {
                                  setStateDialog(() {
                                    selectedSeconds = v.round();
                                  });
                                },
                              ),
                              Text(
                                'Duración: ${selectedSeconds ~/ 60} min ${(selectedSeconds % 60).toString().padLeft(2, '0')} seg',
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startWarmup(selectedSeconds);
                          },
                          child: const Text('Iniciar'),
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Calentamiento',
              child: const Icon(Icons.local_fire_department),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'reset',
              onPressed: _resetGame,
              tooltip: 'Reiniciar partida',
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'results',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ResultsScreen(
                          partidas: partidas,
                          onClear: _clearPartidas,
                        ),
                  ),
                );
              },
              tooltip: 'Ver resultados',
              child: const Icon(Icons.history),
            ),
            // const SizedBox(height: 16),
            // FloatingActionButton(
            //   heroTag: 'finisher',
            //   onPressed: () async {
            //     final player = AudioPlayer();
            //     await player.play(AssetSource('finisher.mp3'));
            //   },
            //   tooltip: 'Finisher',
            //   child: const Icon(Icons.volume_up),
            // ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
