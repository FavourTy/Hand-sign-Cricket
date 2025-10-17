// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_sign_cricket/providers/audio_provider.dart';
import 'package:hand_sign_cricket/screens/Bot.dart';
import 'package:hand_sign_cricket/screens/menu_screen.dart';
import 'package:hand_sign_cricket/screens/toss_screen.dart';
import 'package:hand_sign_cricket/themes/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  final bool userBatsFirst;
  final Difficulty difficulty;

  GameScreen({
    super.key,
    required this.userBatsFirst,
    this.difficulty = Difficulty.medium,
  });

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
    return aiBot.makeDecision(userShot, currentState);
  }

  void playBall(int shot) {
    if (gameOver) return;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    int botShot = botDecision(shot);

    setState(() {
      if (isPlayerBatting) {
        if (shot == botShot) {
          // Player is out
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
          // Player scores - only cheer for 4s and 6s
          if (shot == 4 || shot == 6) {
            audioProvider.playSoundEffect('loud_cheer.mp3');
          }
          playerScore += shot;
        }
      } else {
        if (shot == botShot) {
          // Bot is out (good for player)
          audioProvider.playSoundEffect('wicket_sound.mp3');
          audioProvider.playSoundEffect('loud_cheer.mp3');
          wickets++;
          _showOutGif = true;
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              _showOutGif = false;
            });
          });
        } else {
          // Bot scores (bad for player) - only groan for 4s and 6s
          if (botShot == 4 || botShot == 6) {
            audioProvider.playSoundEffect('crowd_groan.mp3');
          }
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

    aiBot.savePatternData();

    String result = playerWon ? "🎉 You Win! 🎉" : "😢 Bot Wins! 😢";
    String gifPath =
        playerWon ? "assets/animation/Trophy.gif" : "assets/animation/sad.gif";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.yellowAccent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.black, width: 3)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              " Match Over ",
              style: TextStyle(
                  color: Colors.red, fontSize: 32, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Container(
              height: 120,
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
            SizedBox(height: 10),
          ],
        ),
        content: Text(
          result,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    "Try Again",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () {
                    audioProvider.playSoundEffect('button_click.mp3');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MenuScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
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
          SizedBox(height: 10),
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
          side: BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          "🧠 AI Analysis",
          style: TextStyle(
              color: Colors.red, fontSize: 24, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        content: Text(
          info,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playSoundEffect('button_click.mp3');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            return AlertDialog(
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blue, width: 3),
              ),
              title: Text(
                "⚙️ Audio Settings",
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text(
                      "Music",
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                    ),
                    value: audioProvider.isMusicEnabled,
                    onChanged: (value) {
                      audioProvider.toggleMusic();
                    },
                    activeColor: Colors.blue,
                  ),
                  SwitchListTile(
                    title: Text(
                      "Sound Effects",
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                    ),
                    value: audioProvider.isSoundEnabled,
                    onChanged: (value) {
                      audioProvider.toggleSound();
                    },
                    activeColor: Colors.blue,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Music Volume",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Slider(
                    value: audioProvider.musicVolume,
                    onChanged: (value) {
                      audioProvider.setMusicVolume(value);
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.blue.shade200,
                  ),
                  Text(
                    "Sound Effects Volume",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Slider(
                    value: audioProvider.sfxVolume,
                    onChanged: (value) {
                      audioProvider.setSfxVolume(value);
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.blue.shade200,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    audioProvider.playSoundEffect('button_click.mp3');
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    double width = MediaQuery.of(context).size.width;
    double textScale = width / 400;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // VS Row
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "👦🏻\nYou",
                          style: GoogleFonts.bangers(
                              fontSize: 60 * textScale,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                    blurRadius: 3,
                                    color: Colors.black,
                                    offset: Offset(1, 1))
                              ]),
                        ),
                        Text(
                          "VS",
                          style: GoogleFonts.montserrat(
                              fontSize: 60 * textScale,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    blurRadius: 30,
                                    color: Colors.grey,
                                    offset: Offset(5, 4))
                              ]),
                        ),
                        Text(
                          " 🤖 \nBot",
                          style: GoogleFonts.bangers(
                              fontSize: 60 * textScale,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                    blurRadius: 3,
                                    color: Colors.black,
                                    offset: Offset(1, 1))
                              ]),
                        ),
                      ],
                    ),
                  ),
                   // Scoreboard Widget
                   ScoreBoardWidget(
                     playerScore: playerScore,
                     botScore: botScore,
                     wickets: wickets,
                     balls: balls,
                     overs: overs,
                     maxOvers: maxOvers,
                     maxWickets: maxWickets,
                     isFirstInnings: isFirstInnings,
                     target: target,
                     showOutGif: _showOutGif,
                     difficultyLabel: _getDifficultyLabel(),
                     difficultyColor: _getDifficultyColor(),
                     onInfoTap: _showAiInfo,
                     onSettingsTap: _showSettings,
                   ),
                  // Grid of Numbers
                  NumberGrid(onNumberTap: playBall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Modular Widgets --------------------

class ScoreBoardWidget extends StatefulWidget {
  final int playerScore;
  final int botScore;
  final int wickets;
  final int balls;
  final int overs;
  final int maxOvers;
  final int maxWickets;
  final bool isFirstInnings;
  final int target;
  final bool showOutGif;
  final String difficultyLabel;
  final Color difficultyColor;
  final VoidCallback onInfoTap;
  final VoidCallback onSettingsTap;

  const ScoreBoardWidget({
    Key? key,
    required this.playerScore,
    required this.botScore,
    required this.wickets,
    required this.balls,
    required this.overs,
    required this.maxOvers,
    required this.maxWickets,
    required this.isFirstInnings,
    required this.target,
    required this.showOutGif,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.onInfoTap,
    required this.onSettingsTap,
  }) : super(key: key);

  @override
  _ScoreBoardWidgetState createState() => _ScoreBoardWidgetState();
}

class _ScoreBoardWidgetState extends State<ScoreBoardWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1e3c72),
                Color(0xFF2a5298),
                Color(0xFF4facfe),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, -8),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              // Title with animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.1,
                    child: Text(
                      "🏏 SCOREBOARD 🏏",
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.orange,
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 15),
              
              // Difficulty, Info, and Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.difficultyColor, width: 2),
                    ),
                    child: Text(
                      "Difficulty: ${widget.difficultyLabel}",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.difficultyColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onInfoTap,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onSettingsTap,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Icon(Icons.settings, color: Colors.green, size: 20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Scores with enhanced styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildScoreCard("YOU", widget.playerScore, Colors.green),
                  _buildScoreCard("BOT", widget.botScore, Colors.red),
                ],
              ),
              SizedBox(height: 15),
              
              // Game stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard("WICKETS", "${widget.wickets}/${widget.maxWickets}", Icons.sports_cricket),
                  _buildStatCard("OVERS", "${widget.overs}.${widget.balls % 6}/${widget.maxOvers}", Icons.timer),
                ],
              ),
              
              // Target (if second innings)
              if (!widget.isFirstInnings) ...[
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Text(
                    "TARGET: ${widget.target}",
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              
              // Out GIF
              if (widget.showOutGif)
                Container(
                  margin: EdgeInsets.only(top: 15),
                  child: Image.asset(
                    'assets/animation/out.gif',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "$score",
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NumberGrid extends StatefulWidget {
  final Function(int) onNumberTap;

  const NumberGrid({Key? key, required this.onNumberTap}) : super(key: key);

  @override
  _NumberGridState createState() => _NumberGridState();
}

class _NumberGridState extends State<NumberGrid> {
  bool _isProcessing = false;

  void _handleNumberTap(int number) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    // Wait for 2 seconds before processing the tap
    await Future.delayed(Duration(seconds: 2));
    
    widget.onNumberTap(number);
    
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 6,
      itemBuilder: (context, index) {
        int number = index + 1;
        return GestureDetector(
          onTap: () => _handleNumberTap(number),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isProcessing ? Colors.grey : AppColors.boxYellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isProcessing ? Colors.grey : Colors.black, 
                width: 5
              ),
            ),
            child: Stack(
              children: [
                Image.asset('assets/gestures/$number.png', fit: BoxFit.cover),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
