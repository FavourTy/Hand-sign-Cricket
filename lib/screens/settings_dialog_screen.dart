// In lib/widgets/settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../themes/app_colors.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return AlertDialog(
          backgroundColor: AppColors.boxYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black, width: 3),
          ),
          title: const Text(
            'Audio Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textRed,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Master Sound Toggle
              SwitchListTile(
                title: const Text(
                  'Sound',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                value: audioProvider.isSoundEnabled,
                onChanged: (value) {
                  audioProvider.toggleSound(value);
                },
                activeColor: AppColors.textRed,
              ),
              const SizedBox(height: 10),

              // Music Volume Slider
              const Text('Music Volume',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: audioProvider.musicVolume,
                onChanged: audioProvider.isSoundEnabled
                    ? (value) => audioProvider.setMusicVolume(value)
                    : null,
                activeColor: AppColors.textRed,
                inactiveColor: Colors.black26,
              ),
              const Text('Sound Effects Volume',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: audioProvider.sfxVolume,
                onChanged: audioProvider.isSoundEnabled
                    ? (value) => audioProvider.setSfxVolume(value)
                    : null, // Disable if sound is off
                activeColor: AppColors.textRed,
                inactiveColor: Colors.black26,
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  audioProvider.playSoundEffect('button_click.mp3');
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
