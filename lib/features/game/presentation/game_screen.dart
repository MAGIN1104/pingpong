import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/statistics_service.dart';
import 'results_screen.dart';

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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  int score1 = 0;
  int score2 = 0;
  String? player1;
  String? player2;
  String? saqueInicial;
  String? saqueActual;
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
  late AnimationController _coinFlipController;

  // Servicios
  final _hapticService = HapticService();
  final _soundService = SoundService();
  final _statsService = StatisticsService();

  String? _lastScorer;
  int _currentStreak = 0;
  bool _gameFinished = false;

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
    _coinFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

      // Validar que todos los participantes tengan nombres únicos
      final uniqueNames = widget.participantes.toSet();
      if (uniqueNames.length != widget.participantes.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Todos los participantes deben tener nombres únicos',
              ),
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
      saqueInicial = player1;
      saqueActual = player1;
    }
    _loadPartidas();
    _clearCorruptedPlayerData();
    _loadLastPlayers();

    // Validación final: asegurar que no haya duplicados después de cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (player1 != null && player2 != null && player1 == player2) {
        print(
          '⚠️ Game Screen: Final validation - duplicate players detected, fixing...',
        );
        setState(() {
          final availablePlayers =
              widget.participantes.where((p) => p != player1).toList();
          if (availablePlayers.isNotEmpty) {
            player2 = availablePlayers.first;
          }
        });
      }
    });
    _warmupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onWarmupTick(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _coinFlipController.dispose();
    _warmupTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
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
    // Validar que los jugadores sean diferentes antes de guardar
    if (player1 != null && player2 != null && player1 == player2) {
      print(
        '⚠️ Game Screen: Attempted to save duplicate players, preventing save...',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_player1', player1 ?? '');
    await prefs.setString('last_player2', player2 ?? '');
  }

  // Función para limpiar datos corruptos en SharedPreferences
  Future<void> _clearCorruptedPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final last1 = prefs.getString('last_player1');
    final last2 = prefs.getString('last_player2');

    if (last1 != null && last2 != null && last1 == last2) {
      print('🧹 Game Screen: Clearing corrupted player data...');
      await prefs.remove('last_player1');
      await prefs.remove('last_player2');
    }
  }

  Future<void> _loadLastPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final last1 = prefs.getString('last_player1');
    final last2 = prefs.getString('last_player2');

    // Validar que los jugadores guardados sean diferentes
    if (last1 != null && last2 != null && last1 == last2) {
      print(
        '⚠️ Game Screen: Duplicate players detected in saved data, ignoring...',
      );
      return;
    }

    if (last1 != null && widget.participantes.contains(last1)) {
      setState(() {
        player1 = last1;
      });
    }
    if (last2 != null &&
        widget.participantes.contains(last2) &&
        last2 != last1) {
      setState(() {
        player2 = last2;
      });
    }

    // Validación adicional: asegurar que los jugadores cargados sean diferentes
    if (player1 != null && player2 != null && player1 == player2) {
      print(
        '⚠️ Game Screen: Duplicate players after loading, resetting player2...',
      );
      setState(() {
        // Buscar un jugador diferente para player2
        final availablePlayers =
            widget.participantes.where((p) => p != player1).toList();
        if (availablePlayers.isNotEmpty) {
          player2 = availablePlayers.first;
        } else {
          player2 = null;
        }
      });
    }
  }

  void _incrementScore(bool isPlayer1) {
    // No permitir incrementar durante el calentamiento
    if (_isWarmingUp || _gameFinished) return;

    // Haptic feedback y sonido
    _hapticService.light();
    _soundService.playScoreUp();

    final scorer = isPlayer1 ? player1 : player2;
    final target = puntosParaGanar;
    final bool modoDeuce =
        score1 >= puntosParaMatchPoint && score2 >= puntosParaMatchPoint;

    if (!modoDeuce) {
      if ((isPlayer1 && score1 >= target) || (!isPlayer1 && score2 >= target)) {
        return;
      }
    }

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

    _updateStreak(scorer);
  }

  void _decrementScore(bool isPlayer1) {
    // No permitir decrementar durante el calentamiento
    if (_isWarmingUp || _gameFinished) return;

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

    _lastScorer = null;
    _currentStreak = 0;
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

  void _updateStreak(String? scorer) {
    if (scorer == null) return;
    if (_lastScorer == scorer) {
      _currentStreak += 1;
    } else {
      _lastScorer = scorer;
      _currentStreak = 1;
    }

    if (_currentStreak == 3) {
      Future.microtask(() async {
        await _soundService.playFinisher();
      });
    }
  }

  void _checkMatchPoint() async {
    final bool modoDeuce =
        score1 >= puntosParaMatchPoint && score2 >= puntosParaMatchPoint;
    final int diferencia = (score1 - score2).abs();

    bool activarMatchPoint = false;
    int marcadorReferencia = max(score1, score2);

    if (modoDeuce) {
      // A partir del empate se requiere ventaja de un punto para tener match point
      activarMatchPoint = diferencia == 1;
      marcadorReferencia = max(score1, score2);
    } else {
      // Antes del deuce, el jugador que queda a un punto del objetivo está en match point
      activarMatchPoint =
          (score1 == puntosParaGanar - 1) || (score2 == puntosParaGanar - 1);
      marcadorReferencia = puntosParaGanar - 1;
    }

    if (activarMatchPoint && ultimoMatchPointMostrado != marcadorReferencia) {
      setState(() {
        showMatchPoint = true;
        ultimoMatchPointMostrado = marcadorReferencia;
      });
      _confettiController.play();
      _soundService.playMatchPoint();
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (mounted && showMatchPoint) {
          setState(() => showMatchPoint = false);
        }
      });
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
      if (mounted) {
        setState(() {
          _gameFinished = true;
        });
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Si es modo torneo, mostrar diálogo y regresar al bracket automáticamente
          if (widget.isTournamentMode) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _buildTournamentWinnerDialog(winner, loser),
            ).then((dialogResult) async {
              // Regresar al bracket con el resultado
              if (mounted) {
                print('🏆 Torneo: Cerrando partido. Ganador: $winner');
                // Restaurar orientación a portrait antes de hacer pop para
                // que la pantalla anterior (configuración) reciba la orientación inmediatamente.
                try {
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                } catch (e) {
                  // Ignorar errores
                }

                if (mounted) {
                  Navigator.of(context).pop({
                    'matchId': widget.tournamentMatchId,
                    'winner': winner,
                    'score1': score1,
                    'score2': score2,
                  });
                }
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
      _lastScorer = null;
      _currentStreak = 0;
      _gameFinished = false;
    });
  }

  Future<void> _tossForServe() async {
    if (_isWarmingUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Espera a que termine el calentamiento para sortear el saque',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (player1 == null || player2 == null) {
      return;
    }

    final selectedPlayer = Random().nextBool() ? player1! : player2!;

    setState(() {
      saqueInicial = selectedPlayer;
      saqueActual = selectedPlayer;
      saquesRestantes = 2;
    });

    await _soundService.playClick();

    if (!mounted) return;

    final otherPlayer = selectedPlayer == player1 ? player2 : player1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _CoinFlipDialog(
            controller: _coinFlipController,
            winner: selectedPlayer,
            opponent: otherPlayer,
          ),
    );
  }

  Widget _buildModernScoreCard(
    String player,
    int score,
    bool isLeft,
    ColorScheme colorScheme, {
    double scoreFontSize = 80,
    double nameFontSize = 14,
    double cardHeight = 400,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final isSaque = saqueActual == player;
    final isWinner = score == puntosParaGanar;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool showMinus = false;

        return LayoutBuilder(
          builder: (context, constraints) {
            final effectiveHeight =
                constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : cardHeight;
            final cardWidth =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
            final baseScoreFont = effectiveHeight * 0.42;
            final double minScoreConstraint = min(48.0, scoreFontSize * 0.8);
            final double maxScoreConstraint = max(64.0, scoreFontSize * 1.6);
            final double localScoreFont =
                baseScoreFont
                    .clamp(minScoreConstraint, maxScoreConstraint)
                    .toDouble();
            final baseNameSize = effectiveHeight * 0.055;
            final upperNameBound = max(18.0, nameFontSize);
            final double nameFont =
                baseNameSize
                    .clamp(min(upperNameBound, 12.0), upperNameBound)
                    .toDouble();
            final isCompact = effectiveHeight < 260 || cardWidth < 220;
            Color cardColor = const Color(0xFFF5F6FA);
            if (isWinner) {
              cardColor = const Color(0xFFFFF3D6); // toque dorado suave
            } else if (isSaque) {
              cardColor = const Color(0xFFE6F5EB); // verde menta tipo mesa
            }
            final Color accentColor =
                isWinner
                    ? const Color(0xFFC47F00)
                    : isSaque
                    ? const Color(0xFF1E7A4B)
                    : colorScheme.outline;
            final double verticalPadding =
                (effectiveHeight * 0.06).clamp(16.0, 30.0).toDouble();
            final double horizontalPadding =
                (cardWidth * 0.025).clamp(14.0, 22.0).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: _isWarmingUp ? null : () => _incrementScore(isLeft),
                onVerticalDragEnd:
                    _isWarmingUp
                        ? null
                        : (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! > 0) {
                            _decrementScore(isLeft);
                            setLocalState(() => showMinus = true);
                            Future.delayed(
                              const Duration(milliseconds: 360),
                              () {
                                setLocalState(() => showMinus = false);
                              },
                            );
                          }
                        },
                child: Material(
                  color: cardColor,
                  elevation: 18,
                  shadowColor: (isSaque
                          ? colorScheme.primary
                          : colorScheme.outline)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(36),
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: PopupMenuButton<String>(
                                    initialValue: player,
                                    tooltip:
                                        _isWarmingUp
                                            ? 'Cambios no disponibles durante el calentamiento'
                                            : 'Cambiar jugador',
                                    enabled: !_isWarmingUp,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    onSelected: (nuevo) {
                                      if (nuevo != player) {
                                        final otherPlayer =
                                            isLeft ? player2 : player1;
                                        if (nuevo == otherPlayer) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$nuevo ya está jugando en el otro lado',
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        if ((isLeft && nuevo == player2) ||
                                            (!isLeft && nuevo == player1)) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'No se puede seleccionar el mismo jugador en ambos lados',
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          if (isLeft) {
                                            player1 = nuevo;
                                          } else {
                                            player2 = nuevo;
                                          }
                                          _saveLastPlayers();
                                        });
                                      }
                                    },
                                    itemBuilder:
                                        (context) =>
                                            widget.participantes
                                                .where(
                                                  (nombre) =>
                                                      nombre !=
                                                      (isLeft
                                                          ? player2
                                                          : player1),
                                                )
                                                .map(
                                                  (nombre) =>
                                                      PopupMenuItem<String>(
                                                        value: nombre,
                                                        child: Text(
                                                          nombre,
                                                          style:
                                                              textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: max(cardWidth * 0.03, 14),
                                        vertical: isCompact ? 8 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              player,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontSize: nameFont,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: colorScheme.outline,
                                            size: isCompact ? 20 : 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (isSaque)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            size: 18,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Saque',
                                            style: textTheme.labelLarge
                                                ?.copyWith(color: accentColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(
                                    '$score',
                                    style: textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: localScoreFont,
                                      letterSpacing: -2.5,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Toca para sumar · Desliza hacia abajo para restar',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.outline,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWinner)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (showMinus)
                        Positioned(
                          bottom: 32,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            opacity: showMinus ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.remove_circle_outline,
                                  color: colorScheme.error,
                                  size: 34,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '-1',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_isWarmingUp)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Bloqueado',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchPointBanner(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.whatshot_rounded, color: colorScheme.error),
            const SizedBox(width: 10),
            Text(
              '¡Match point!',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Necesitas ventaja de dos puntos para cerrar la partida.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error.withValues(alpha: 0.75),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarmupDialog(ColorScheme colorScheme, TextTheme textTheme) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.35,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de fuego - lado izquierdo
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.local_fire_department,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Contenido central - columna
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      'Calentamiento',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Cronómetro
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(_warmupRemaining ~/ 60).toString().padLeft(2, '0')}:${(_warmupRemaining % 60).toString().padLeft(2, '0')}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Advertencia de bloqueo
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Puntuaciones bloqueadas',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Botón Cancelar - lado derecho
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _isWarmingUp = false;
                      _warmupTimer?.cancel();
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    // El sonido ya se reproduce cuando se detecta la victoria
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
    final textTheme = Theme.of(context).textTheme;
    final orientation = MediaQuery.of(context).orientation;

    if (player1 == null || player2 == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (orientation == Orientation.portrait) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Gira tu dispositivo',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEEF0FF), Color(0xFFF7F8FC)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.screen_rotation,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'La experiencia está optimizada en horizontal.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gira tu dispositivo para continuar con la partida.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Partida en curso',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              onPressed: _tossForServe,
              tooltip: 'Sortear saque',
              icon: const Icon(Icons.casino_rounded),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF0FF), Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardHeightHint = constraints.maxHeight * 0.76;
              final cardWidth = constraints.maxWidth;
              final cardFontSize = min(cardHeightHint * 0.55, cardWidth * 0.35);
              final nameFontSize = min(cardHeightHint * 0.08, cardWidth * 0.05);
              final double boardGap = max(18.0, constraints.maxWidth * 0.02);
              final double dividerWidth = max(
                2.0,
                constraints.maxWidth * 0.004,
              );
              final bottomInset = MediaQuery.of(context).padding.bottom;

              return Stack(
                children: [
                  // Contenido principal (tablero de puntuación)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child:
                            showMatchPoint
                                ? _buildMatchPointBanner(colorScheme, textTheme)
                                : const SizedBox.shrink(),
                      ),
                      if (showMatchPoint) const SizedBox(height: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildModernScoreCard(
                                  player1!,
                                  score1,
                                  true,
                                  colorScheme,
                                  scoreFontSize: cardFontSize,
                                  nameFontSize: nameFontSize,
                                  cardHeight: cardHeightHint,
                                ),
                              ),
                              SizedBox(width: boardGap * 0.5),
                              Container(
                                width: dividerWidth,
                                margin: EdgeInsets.symmetric(
                                  vertical: max(18.0, cardHeightHint * 0.08),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colorScheme.outline.withValues(
                                        alpha: 0.0,
                                      ),
                                      colorScheme.outline.withValues(
                                        alpha: 0.25,
                                      ),
                                      colorScheme.outline.withValues(
                                        alpha: 0.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: boardGap * 0.5),
                              Expanded(
                                child: _buildModernScoreCard(
                                  player2!,
                                  score2,
                                  false,
                                  colorScheme,
                                  scoreFontSize: cardFontSize,
                                  nameFontSize: nameFontSize,
                                  cardHeight: cardHeightHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: max(12.0, bottomInset)),
                    ],
                  ),

                  // Dialog overlay del calentamiento (centrado y al frente)
                  if (_isWarmingUp) _buildWarmupDialog(colorScheme, textTheme),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
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
            const SizedBox(height: 12),
            FloatingActionButton.small(
              heroTag: 'reset',
              onPressed: _resetGame,
              tooltip: 'Reiniciar partida',
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.small(
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

class _CoinFlipDialog extends StatefulWidget {
  final AnimationController controller;
  final String winner;
  final String? opponent;

  const _CoinFlipDialog({
    required this.controller,
    required this.winner,
    this.opponent,
  });

  @override
  State<_CoinFlipDialog> createState() => _CoinFlipDialogState();
}

class _CoinFlipDialogState extends State<_CoinFlipDialog> {
  late final Animation<double> _spinAnimation;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _spinAnimation = CurvedAnimation(
      parent: widget.controller,
      curve: Curves.easeInOut,
    );
    widget.controller
      ..stop()
      ..reset()
      ..repeat(period: const Duration(milliseconds: 220));

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _showResult = true);
      widget.controller.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Size screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: min(screenSize.width * 0.8, 420),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactHeight = constraints.maxHeight < 320;
            final double loaderSize = max(
              64.0,
              min(constraints.maxWidth * 0.45, constraints.maxHeight * 0.38),
            );
            final double spacingAfterSpinner = isCompactHeight ? 18 : 28;
            final double spacingAfterInfo = isCompactHeight ? 18 : 28;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: Text(
                          'Saque inicial',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child:
                          _showResult
                              ? Container(
                                key: const ValueKey('result_view'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.winner,
                                      textAlign: TextAlign.center,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SizedBox(
                                key: const ValueKey('spinner'),
                                height: loaderSize,
                                width: loaderSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: loaderSize,
                                      width: loaderSize,
                                      child: CircularProgressIndicator(
                                        strokeWidth: loaderSize * 0.1,
                                        valueColor: AlwaysStoppedAnimation(
                                          colorScheme.primary,
                                        ),
                                        backgroundColor: colorScheme
                                            .outlineVariant
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    RotationTransition(
                                      turns: Tween<double>(
                                        begin: 0,
                                        end: 1,
                                      ).animate(_spinAnimation),
                                      child: Icon(
                                        Icons.autorenew_rounded,
                                        size: loaderSize * 0.42,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                    SizedBox(height: spacingAfterSpinner),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child:
                          _showResult
                              ? const SizedBox(height: 2)
                              : Column(
                                key: const ValueKey('loading'),
                                children: [
                                  Text(
                                    'Sorteando saque…',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Esperando resultado',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                    SizedBox(height: spacingAfterInfo),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            _showResult
                                ? FilledButton.icon(
                                  key: const ValueKey('ready'),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Listo'),
                                  onPressed: () => Navigator.of(context).pop(),
                                )
                                : FilledButton.icon(
                                  key: const ValueKey('disabled'),
                                  icon: const Icon(Icons.hourglass_top_rounded),
                                  label: const Text('Sorteando…'),
                                  onPressed: null,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
