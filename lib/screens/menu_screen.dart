// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_sign_cricket/Transitions/pageTransitions.dart';
import 'package:hand_sign_cricket/screens/settings_dialog_screen.dart';
import 'package:hand_sign_cricket/screens/toss_screen.dart';
import 'package:hand_sign_cricket/screens/Bot.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/audio_provider.dart';
import 'package:provider/provider.dart';
import '../themes/app_colors.dart';
import '../widgets/howtoplay.dart';
import '../widgets/rating_dialog.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  // ScreenTransition _screenTransition = ScreenTransition();

  late AnimationController _titleController,
      _menuController,
      _floatingController;
  late Animation<double> _titleSlide,
      _menuOpacity,
      _buttonScale,
      _floatingMovement;

  @override
  void initState() {
    super.initState();
    Provider.of<AudioProvider>(context, listen: false).playMusic();
    // Title Slide-in Animation
    _titleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _titleSlide = Tween(begin: -50.0, end: 0.0).animate(
        CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    // Menu Fade-in & Bounce Animation
    _menuController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _menuOpacity =
        CurvedAnimation(parent: _menuController, curve: Curves.easeInOut);
    _buttonScale = Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _menuController, curve: Curves.elasticOut));

    // Floating Animation for Icons
    _floatingController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
        reverseDuration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _floatingMovement = Tween(begin: 0.0, end: 5.0).animate(
        CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleController.forward();
      _menuController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _menuController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _showResetAiDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.yellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.black, width: 3),
          ),
          title: const Text(
            '🤖 Reset AI Learning',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "This will reset the bot's learning data. The AI will forget all patterns it has learned from your gameplay.\n\nAre you sure?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Reset AI learning data
                AiBot tempBot = AiBot(difficulty: Difficulty.medium);
                await tempBot.resetPatternData();
                Navigator.of(context).pop();

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🤖 AI learning data has been reset!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Reset',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Title
          AnimatedBuilder(
            animation: _titleSlide,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _titleSlide.value),
                child: child,
              );
            }, //🏏
            child: Column(
              children: [
                Text(
                  "HAND CRICKET",
                  style: GoogleFonts.pressStart2p(
                    fontSize: 50,
                    fontWeight: FontWeight.w900,
                    color: Colors.orangeAccent,
                    shadows: [
                      const Shadow(
                          blurRadius: 12.0,
                          color: Colors.redAccent,
                          offset: Offset(10, 3)),
                      const Shadow(
                          blurRadius: 1.0,
                          color: Colors.black,
                          offset: Offset(5, 5)),
                      const Shadow(
                          blurRadius: 13.0,
                          color: Colors.deepOrange,
                          offset: Offset(-2, -3)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  "",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Animated Menu Buttons
          FadeTransition(
            opacity: _menuOpacity,
            child: Column(
              children: [
                AnimatedScaleButton(
                  text: "ꜱɪɴɢʟᴇ ᴘʟᴀʏᴇʀ",
                  onTap: () {
                    Navigator.of(context)
                        .push(ScreenTransition.createRoute(TossScreen()));
                  },
                  child: AnimatedScaleButton(
                    text: "Single Player",
                    onTap: () {
                      audioProvider.playSoundEffect('button_click.mp3');
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TossScreen()));
                    },
                    icon: Icons.person,
                    scaleAnimation: _buttonScale,
                  ),
                ),
                AnimatedScaleButton(
                  text: "ᴍᴜʟᴛɪᴘʟᴀʏᴇʀ",
                  onTap: () {
                    audioProvider.playSoundEffect('button_click.mp3');
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side:
                                const BorderSide(color: Colors.black, width: 3),
                          ),
                          content: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              "🚀 We will bring this feature very soon! Stay tuned! 🎉",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icons.group,
                  scaleAnimation: _buttonScale,
                ),
                AnimatedScaleButton(
                  text: "ʜᴏᴡ ᴛᴏ ᴘʟᴀʏ",
                  onTap: () {
                    audioProvider.playSoundEffect('button_click.mp3');
                    play.showHowToPlayDialog(context);
                  },
                  icon: Icons.help,
                  scaleAnimation: _buttonScale,
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),

          // Floating Icons (GitHub & Rating)
          AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingMovement.value),
                  child: child,
                );
              },
              // child: Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     GestureDetector(
              //       onTap: () {
              //         audioProvider.playSoundEffect('button_click.mp3');
              //         const url =
              //             "https://github.com/aavvvacado/Hand-sign-Cricket";
              //         launchUrl(Uri.parse(url),
              //             mode: LaunchMode.externalApplication);
              //       },
              //       child: Image.asset(
              //         "assets/icons/github.png",
              //         width: 50,
              //         height: 50,
              //       ),
              //     ),
              //     const SizedBox(width: 50),
              //     GestureDetector(
              //       onTap: () {
              //         audioProvider.playSoundEffect('button_click.mp3');
              //         showDialog(
              //             context: context, builder: (_) => RatingDialog());
              //       },
              //       child: const Icon(Icons.star, color: Colors.white, size: 50),
              //     ),
              //     const SizedBox(width: 50),
              //     GestureDetector(
              //       onTap: () {
              //         audioProvider.playSoundEffect('button_click.wav');
              //         showDialog(
              //             context: context,
              //             builder: (_) => const SettingsDialog());
              //       },
              //       child:
              //           const Icon(Icons.settings, color: Colors.black, size: 50),
              //     ),
              //   ],
              // ),

              // Replace your Row with this Wrap widget

              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 40.0,
                children: [
                  GestureDetector(
                    onTap: () {
                      audioProvider.playSoundEffect('button_click.wav');
                      const url =
                          "https://github.com/aavvvacado/Hand-sign-Cricket";
                      launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    },
                    child: Image.asset(
                      "assets/icons/github.png",
                      width: 50,
                      height: 50,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      audioProvider.playSoundEffect('button_click.wav');
                      showDialog(
                          context: context, builder: (_) => RatingDialog());
                    },
                    child:
                        const Icon(Icons.star, color: Colors.white, size: 50),
                  ),
                  GestureDetector(
                    onTap: () {
                      audioProvider.playSoundEffect('button_click.wav');
                      showDialog(
                          context: context,
                          builder: (_) => const SettingsDialog());
                    },
                    child: const Icon(Icons.settings,
                        color: Colors.black, size: 50),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

// Custom Animated Scale Button
class AnimatedScaleButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData icon;
  final Animation<double> scaleAnimation;

  const AnimatedScaleButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.icon,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 320,
            height: 70,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.boxYellow,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                const BoxShadow(
                    color: Colors.black,
                    offset: Offset(9, 9),
                    blurRadius: 5,
                    blurStyle: BlurStyle.solid)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.textRed, size: 30),
                const SizedBox(width: 15),
                Text(text,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textRed)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
