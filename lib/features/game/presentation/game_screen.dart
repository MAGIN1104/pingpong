import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'results_screen.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  final List<String> participantes;
  final int modalidad;
  const GameScreen({
    super.key,
    required this.participantes,
    required this.modalidad,
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

  @override
  void initState() {
    super.initState();
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
      player1 = widget.participantes[0];
      player2 = widget.participantes[1];
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
      });
    }
    if (last2 != null && widget.participantes.contains(last2)) {
      setState(() {
        player2 = last2;
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((_) {
      _confettiController.dispose();
      _warmupTimer?.cancel();
      super.dispose();
    });
  }

  void _incrementScore(bool isPlayer1) {
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
      // En modo normal, se gana al llegar exactamente a los puntos establecidos
      if (score1 == puntosParaGanar || score2 == puntosParaGanar) {
        hayGanador = true;
      }
    }

    if (hayGanador) {
      winnerName = score1 > score2 ? player1 : player2;
      _savePartida();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _buildWinnerDialog(winnerName!),
          );
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
              onTap: () {
                _incrementScore(isLeft);
              },
              onVerticalDragEnd: (details) {
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
                            tooltip: 'Seleccionar jugador',
                            onSelected: (nuevo) {
                              if (nuevo != player) {
                                setState(() {
                                  if (isLeft) {
                                    player1 = nuevo;
                                    if (player2 == nuevo) {
                                      player2 = widget.participantes.firstWhere(
                                        (n) => n != nuevo,
                                        orElse: () => '',
                                      );
                                    }
                                    _saveLastPlayers();
                                  } else {
                                    player2 = nuevo;
                                    if (player1 == nuevo) {
                                      player1 = widget.participantes.firstWhere(
                                        (n) => n != nuevo,
                                        orElse: () => '',
                                      );
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSaque)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.sports_tennis,
                                      size: nameFont + 4,
                                      color: Colors.red,
                                    ),
                                  ),
                                Text(
                                  player,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: nameFont,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down),
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
                                fontWeight: FontWeight.bold,
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                winner,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
                          Text(
                            'Calentamiento',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            '${(_warmupRemaining ~/ 60).toString().padLeft(2, '0')}:${(_warmupRemaining % 60).toString().padLeft(2, '0')}',
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
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
