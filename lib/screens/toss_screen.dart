import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_sign_cricket/Transitions/pageTransitions.dart';
import 'package:hand_sign_cricket/screens/Bot.dart';
import 'package:hand_sign_cricket/themes/app_colors.dart';
import 'package:hand_sign_cricket/themes/app_fonts.dart';

import 'package:hand_sign_cricket/screens/Bot.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import 'game_screen.dart';

class TossScreen extends StatefulWidget {
  @override
  _TossScreenState createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  String? userChoice;
  int? userNumber;
  int botNumber = Random().nextInt(6) + 1;
  String tossResult = "";
  bool userWonToss = false;
  bool tossDone = false;
  String botDecision = "";
  bool isTossing = false;
  String animationAsset = "";
  Difficulty selectedDifficulty = Difficulty.medium;

  void performToss() {
    // Ensure user has made a selection before tossing
    if (userNumber == null || userChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose Odd/Even and a number first!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playSoundEffect('button_click.mp3');
    setState(() {
      isTossing = true;
      animationAsset = 'assets/animation/coinflip.gif';
    });

    Future.delayed(const Duration(seconds: 3), () {
      int sum = userNumber! + botNumber;
      bool isEven = sum % 2 == 0;
      bool userChoseEven = userChoice == "Even";

      setState(() {
        tossDone = true;
        isTossing = false;
        if ((isEven && userChoseEven) || (!isEven && !userChoseEven)) {
          audioProvider.playSoundEffect('toss_win.mp3');
          tossResult = "🎉 Yay! You won!";
          userWonToss = true;
          animationAsset = 'assets/animation/Confetti.gif';
        } else {
          audioProvider.playSoundEffect('toss_loss.mp3');
          tossResult = "😞 Bad luck! You lost!";
          userWonToss = false;
          botDecision = Random().nextBool() ? "Bat" : "Bowl";
          animationAsset = 'assets/animation/loss.gif';
          Future.delayed(const Duration(seconds: 2), () {
            navigateToGame(botDecision);
          });
        }
      });
    });
  }
  // Navigator.of(context)
  //                         .push(ScreenTransition.createRoute(TossScreen()));

  void navigateToGame(String choice) {
    Provider.of<AudioProvider>(context, listen: false)
        .playSoundEffect('button_click.mp3');
    bool userBatsFirst =
        userWonToss ? (choice == "Bat") : (botDecision == "Bowl");

    Navigator.of(context).pushReplacement(ScreenTransition.createRoute(
        GameScreen(
            userBatsFirst: userBatsFirst, difficulty: selectedDifficulty)));

    // Navigator.pushReplacement(

    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => GameScreen(
    //       userBatsFirst: userBatsFirst,
    //       difficulty: selectedDifficulty,
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isTossing || tossDone) Image.asset(animationAsset, height: 180),
            if (tossDone) ...[
              Text(
                tossResult,
                style: AppFonts.bebasNeue(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 20),
              if (userWonToss) ...[
                const Text("Choose Bat or Bowl",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["Bat", "Bowl"]
                      .map((e) => ElevatedButton(
                            onPressed: () => navigateToGame(e),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 10,
                            ),
                            child: Text(e,
                                style: AppFonts.bebasNeue(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ))
                      .toList(),
                ),
              ] else ...[
                Text("Bot chose to $botDecision",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ],
            ],
            if (!isTossing && !tossDone) ...[
              // Difficulty Selection
              _buildDifficultySelection(),
              const SizedBox(height: 30),

              const Text("Choose Odd or Even",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["Odd", "Even"].map((e) {
                  return GestureDetector(
                    onTap: () {
                      audioProvider.playSoundEffect('button_click.mp3');
                      setState(() => userChoice = e);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      decoration: BoxDecoration(
                        color: userChoice == e
                            ? Colors.white
                            : AppColors.boxYellow,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Text(e,
                          style: AppFonts.bebasNeue(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                  );
                }).toList(),
              ),
              if (userChoice != null) ...[
                const SizedBox(height: 20),
                const Text("Select a number (1-6)",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        audioProvider.playSoundEffect('button_click.mp3');
                        setState(() => userNumber = index + 1);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: userNumber == index + 1
                              ? Border.all(color: Colors.yellowAccent, width: 5)
                              : Border.all(color: Colors.black, width: 5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/gestures/${index + 1}.png',
                              fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (userWonToss) ...[
                  const Text("Choose Bat or Bowl",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["🏏Bat", "🥎Bowl"]
                        .map((e) => ElevatedButton(
                              onPressed: () => navigateToGame(e),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 10,
                              ),
                              child: Text(e,
                                  style: AppFonts.bebasNeue(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ))
                        .toList(),
                  ),
                ] else ...[
                  Text("Bot chose to $botDecision",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ],
              ],
              if (!isTossing && !tossDone) ...[
                // This combines the new difficulty feature with your animated switcher
                _buildDifficultySelection(),
                const SizedBox(height: 30),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.2, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: userChoice == null
                      ? _buildOddEvenChooser()
                      : _buildNumberChooser(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOddEvenChooser() {
  Widget _buildDifficultySelection() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return Column(
      key: const ValueKey('chooseOddEven'),
      children: [
        const Text("Choose Odd or Even",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ["Odd", "Even"].map((e) {
            return GestureDetector(
              onTap: () => setState(() => userChoice = e),
              child: Container(
                margin: const EdgeInsets.all(10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.boxYellow,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Text(e,
                    style: AppFonts.bebasNeue(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
            );
          }).toList(),
        const Text(
          'Select Bot Difficulty',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDifficultyButton(
                "Easy", Difficulty.easy, Colors.green, audioProvider),
            _buildDifficultyButton(
                "Medium", Difficulty.medium, Colors.orange, audioProvider),
            _buildDifficultyButton(
                "Hard", Difficulty.hard, Colors.red, audioProvider),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberChooser() {
    return Column(
      key: const ValueKey('chooseNumber'),
      children: [
        const Text("Select a number (1-6)",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 15),
        SizedBox(
          width: 300, // Constrain the width of the GridView
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() => userNumber = index + 1),
                child: Container(
                  decoration: BoxDecoration(
                    border: userNumber == index + 1
                        ? Border.all(color: Colors.yellowAccent, width: 5)
                        : Border.all(color: Colors.black, width: 5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/gestures/${index + 1}.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: performToss,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 12,
          ),
          child: Text("Toss",
              style: AppFonts.bebasNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildDifficultySelection() {
    return Center(
      child: Column(
        children: [
          Row(
            children: [
              Card(
                elevation: 20,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: const Color.fromARGB(255, 1, 77, 139),
                  height: 130,
                  width: 257,
                  child: Text(
                    "Select Bot Difficulty",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Card(
                child: Container(
                  height: 130,
                  width: 100,
                  child: Image.asset(
                    'assets/animation/bot.gif',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDifficultyButton("Easy", Difficulty.easy, Colors.green),
              _buildDifficultyButton(
                  "Medium", Difficulty.medium, Colors.orange),
              _buildDifficultyButton("Hard", Difficulty.hard, Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          _buildDifficultyDescription(),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(
      String label, Difficulty difficulty, Color color) {
    bool isSelected = selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () {
        audioProvider.playSoundEffect('button_click.mp3');
        setState(() => selectedDifficulty = difficulty);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Text(
          label,
          style: AppFonts.bebasNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyDescription() {
    String description;
    Color color;

    switch (selectedDifficulty) {
      case Difficulty.easy:
        description = "🎯 Basic random moves with simple strategy";
        color = Colors.green;
        break;
      case Difficulty.medium:
        description = "🧠 Balanced strategy with pattern detection";
        color = Colors.orange;
        break;
      case Difficulty.hard:
        description = "🔥 Advanced AI with learning capabilities";
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
