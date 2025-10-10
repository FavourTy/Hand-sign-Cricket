// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors_in_immutables

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_sign_cricket/providers/audio_provider.dart';
import 'package:hand_sign_cricket/screens/menu_screen.dart';
import 'package:hand_sign_cricket/screens/Bot.dart';
import 'package:hand_sign_cricket/screens/toss_screen.dart';
import 'package:hand_sign_cricket/themes/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  final bool userBatsFirst;
  final Difficulty difficulty;

  GameScreen(
      {super.key,
      required this.userBatsFirst,
      this.difficulty = Difficulty.medium});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int playerScore = 0;
  int botScore = 0;
  int wickets = 0;
  int balls = 0;
  int overs = 0;
  int target = 0;
  bool isFirstInnings = true;
  bool isPlayerBatting = true;
  bool gameOver = false;
  bool _showOutGif = false;

  late AiBot aiBot;
  final int maxOvers = 5;
  final int maxWickets = 2;

  @override
  void initState() {
    super.initState();
    isPlayerBatting = widget.userBatsFirst;
    aiBot = AiBot(difficulty: widget.difficulty);
    _loadGameData();
    _initializeAiBot();
  }

  @override
  void dispose() {
    // Save pattern data when leaving the screen
    aiBot.savePatternData();
    super.dispose();
  }

  Future<void> _initializeAiBot() async {
    await aiBot.loadPatternData();
  }

  Future<void> _loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      playerScore = prefs.getInt('playerScore') ?? 0;
      botScore = prefs.getInt('botScore') ?? 0;
      wickets = prefs.getInt('wickets') ?? 0;
      balls = prefs.getInt('balls') ?? 0;
      overs = prefs.getInt('overs') ?? 0;
      target = prefs.getInt('target') ?? 0;
      isFirstInnings = prefs.getBool('isFirstInnings') ?? true;
      isPlayerBatting =
          prefs.getBool('isPlayerBatting') ?? widget.userBatsFirst;
    });
  }

  int botDecision(int userShot) {
    // Create current game state
    GameState currentState = GameState(
      playerScore: playerScore,
      botScore: botScore,
      wickets: wickets,
      balls: balls,
      overs: overs,
      target: target,
      isFirstInnings: isFirstInnings,
      isPlayerBatting: isPlayerBatting,
      maxOvers: maxOvers,
      maxWickets: maxWickets,
    );

    // Use AI bot to make decision
    return aiBot.makeDecision(userShot, currentState);
  }

  // void playBall(int shot) {
  //   final audioProvider = Provider.of<AudioProvider>(context, listen: false);
  //   if (gameOver) return;
  //   int botShot = botDecision(shot);

  //   setState(() {
  //     if (isPlayerBatting) {
  //       if (shot == botShot) {
  //         audioProvider.playSoundEffect('wicket_sound.mp3');
  //         audioProvider.playSoundEffect('crowd_groan.mp3');
  //         wickets++;
  //         _showOutGif = true; // Show "out" GIF
  //         Future.delayed(Duration(seconds: 2), () {
  //           setState(() {
  //             _showOutGif = false; // Hide GIF after delay
  //           });
  //         });
  //       } else {
  //         playerScore += shot;
  //       }
  //     } else {
  //       if (shot == botShot) {
  //         wickets++;
  //         _showOutGif = true;
  //         Future.delayed(Duration(seconds: 2), () {
  //           setState(() {
  //             _showOutGif = false;
  //           });
  //         });
  //       } else {
  //         botScore += botShot;
  //       }
  //     }
  //     balls++;
  //     if (balls % 6 == 0) overs++;

  //     _checkGameState();
  //   });
  // }

  void playBall(int shot) {
    if (gameOver) return;

    // Get a reference to the audio provider
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    int botShot = botDecision(shot);

    setState(() {
      if (isPlayerBatting) {
        if (shot == botShot) {
          // PLAYER IS OUT
          audioProvider.playSoundEffect('wicket_sound.mp3');
          audioProvider.playSoundEffect('crowd_groan.mp3');
          wickets++;
          _showOutGif = true;
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              _showOutGif = false;
            });
          });
        } else {
          audioProvider.playSoundEffect('bat_hit.mp3');
          if (shot >= 4) {
            audioProvider.playSoundEffect('loud_cheer.mp3');
          } else {
            audioProvider.playSoundEffect('short_cheer.mp3');
          }
          playerScore += shot;
        }
      } else {
        // Player is Bowling
        if (shot == botShot) {
          // BOT IS OUT (Good for player)
          audioProvider.playSoundEffect('wicket_sound.mp3');
          audioProvider.playSoundEffect('loud_cheer.mp3');
          wickets++;
          _showOutGif = true;
          Future.delayed(const Duration(milliseconds: 2000), () {
            setState(() {
              _showOutGif = false;
            });
          });
        } else {
          // BOT SCORES (Bad for player)
          audioProvider.playSoundEffect('bat_hit.mp3');
          audioProvider.playSoundEffect('crowd_groan.mp3');
          botScore += botShot;
        }
      }
      balls++;
      if (balls % 6 == 0) overs++;

      _checkGameState();
    });
  }

  void _checkGameState() {
    if (isFirstInnings && (wickets >= maxWickets || overs >= maxOvers)) {
      _endInnings();
    } else if (!isFirstInnings) {
      if (botScore >= target) {
        _endGame(false);
      } else if (playerScore >= target) {
        _endGame(true);
      } else if (wickets >= maxWickets || overs >= maxOvers) {
        _endGame(botScore < target);
      }
    }
  }

  void _endInnings() {
    setState(() {
      isFirstInnings = false;
      target = isPlayerBatting ? playerScore + 1 : botScore + 1;
      wickets = 0;
      balls = 0;
      overs = 0;
      isPlayerBatting = !isPlayerBatting;
    });
  }

  void _endGame(bool playerWon) {
    gameOver = true;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.stopMusic();
    if (playerWon) {
      audioProvider.playSoundEffect('victory_cheer.mp3');
    } else {
      audioProvider.playSoundEffect('crowd_groan.mp3');
    }

    // Save AI bot learning data
    aiBot.savePatternData();

    String result = playerWon ? "🎉 You Win! 🎉" : "😢 Bot Wins! 😢";
    String gifPath = playerWon
        ? "assets/animation/Trophy.gif"
        : "assets/animation/sad.gif"; // Choose GIF based on result

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.yellowAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              " Match Over ",
              style: TextStyle(
                color: Color.fromARGB(255, 230, 48, 35),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10), // Space between title and GIF
            Container(
              // color: Colors.white,

              height: 120, // Adjust size as needed
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(gifPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10), // Space between GIF and result text
          ],
        ),
        content: Text(
          result,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    audioProvider.playSoundEffect('button_click.mp3');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => TossScreen()),
                    );
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Try Again",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
            child: ElevatedButton(
              onPressed: () {
                audioProvider.playSoundEffect('button_click.mp3');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MenuScreen()),
                );
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                const SizedBox(
                  height: 4,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MenuScreen()),
                    );
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Back to Main Menu",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), // Extra space at bottom for better UI
        ],
      ),
    );
  }

  String _getDifficultyLabel() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return "Easy 🟢";
      case Difficulty.medium:
        return "Medium 🟡";
      case Difficulty.hard:
        return "Hard 🔴";
    }
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }

  void _showAiInfo() {
    String info = "";
    if (aiBot.userPattern.frequencyMap.isNotEmpty) {
      info += "📊 Your number usage:\n";
      for (var entry in aiBot.userPattern.frequencyMap.entries) {
        info += "${entry.key}: ${entry.value} times\n";
      }
      info +=
          "\n🎯 Bot's favorite: ${aiBot.userPattern.mostFrequent ?? 'None'}\n";
      info +=
          "🔍 Pattern detected: ${aiBot.userPattern.hasRepeatingPattern ? 'Yes' : 'No'}\n";
      info +=
          "📝 Recent choices: ${aiBot.userPattern.recentChoices.take(5).toList()}";
    } else {
      info =
          "🤖 Bot is still learning your patterns!\nPlay more to see statistics.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.yellowAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: const Text(
          "🧠 AI Analysis",
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          info,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "👦🏻\nYou",
                          style: GoogleFonts.bangers(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            shadows: [
                              const Shadow(
                                  blurRadius: 3.0,
                                  color: Colors.black,
                                  offset: Offset(1, 1)),
                            ],
                          ),
                        ),
                        Text(
                          "VS",
                          style: GoogleFonts.montserrat(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                  blurRadius: 30.0,
                                  color: Colors.grey,
                                  offset: Offset(5, 4)),
                            ],
                          ),
                        ),
                        Text(
                          " 🤖 \nBot",
                          style: GoogleFonts.bangers(
                            fontSize: 60,
                            color: Colors.black,
                            shadows: [
                              const Shadow(
                                  blurRadius: 3.0,
                                  color: Colors.black,
                                  offset: Offset(1, 1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text("SCOREBOARD",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w800)),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Difficulty: ${_getDifficultyLabel()}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getDifficultyColor())),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              audioProvider.playSoundEffect('button_click.wav');
                              _showAiInfo();
                            },
                            child: Icon(Icons.info_outline,
                                color: Colors.blue, size: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text("You: $playerScore", style: TextStyle(fontSize: 24)),
                      Text("Bot: $botScore", style: TextStyle(fontSize: 24)),
                      Text("Wickets: $wickets / $maxWickets",
                          style: TextStyle(fontSize: 18)),
                      Text("Overs: $overs.${balls % 6} / $maxOvers",
                          style: TextStyle(fontSize: 18)),
                      if (!isFirstInnings)
                        Text("Target: $target",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      if (_showOutGif)
                        Container(
                          // Semi-transparent background
                          child: Center(
                            child: Image.asset(
                              'assets/animation/out.gif',
                              width: 200, // Adjust size as needed
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text("You: $playerScore",
                            style: GoogleFonts.montserrat(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Text("Bot: $botScore",
                            style: GoogleFonts.montserrat(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Text("Wickets: $wickets / $maxWickets",
                            style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Text("Overs: $overs.${balls % 6} / $maxOvers",
                            style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        if (!isFirstInnings)
                          Text("Target: $target",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_showOutGif)
                          SizedBox(
                            height: 80, // Adjust size as needed
                            width: 100,
                            child: Center(
                              child: Image.asset(
                                'assets/animation/wckt.gif',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 20),
                  // grid of 6 boxes
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      int number = index + 1;
                      return GestureDetector(
                        onTap: () => playBall(number),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.boxYellow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 5),
                          ),
                          child: Image.asset('assets/gestures/$number.png',
                              fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
