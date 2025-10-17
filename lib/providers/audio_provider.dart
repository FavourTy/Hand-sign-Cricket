// In lib/providers/audio_provider.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioProvider with ChangeNotifier {
  // State variables
  bool _isSoundEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.8;

  // Player for long-running background music
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Optional: small pool for overlapping low-latency sfx (reused to reduce lag)
  final List<AudioPlayer> _sfxPool = List.generate(
    4,
    (_) => AudioPlayer(),
  );
  int _nextSfxIndex = 0;

  // Cap durations (ms) for specific long sfx to avoid perceived lag
  static const Map<String, int> _sfxDurationCapsMs = {
    'loud_cheer.mp3': 800,
    'victory_cheer.mp3': 900,
    'crowd_groan.mp3': 700,
    'wicket_sound.mp3': 700,
  };

  // Getters
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isMusicEnabled => _isSoundEnabled; // Alias for consistency
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  AudioProvider() {
    // Set the release mode to loop for the background music player
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    // Ensure music plays as media; SFX will use low-latency mode
    _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    // Configure audio context so music and sfx can mix (not interrupt each other)
    _musicPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  // --- Music Methods ---
  void playMusic() {
    if (_isSoundEnabled) {
      _musicPlayer.setVolume(_musicVolume);
      _musicPlayer.play(AssetSource('sounds/background_music.mp3'));
    }
  }

  void stopMusic() {
    _musicPlayer.stop();
  }

  // ==========================================================
  // ## THIS IS THE CORRECTED METHOD ##
  // ==========================================================
  void playSoundEffect(String soundName) {
    if (_isSoundEnabled) {
      // Use a small reusable low-latency pool to avoid asset decode lag
      final sfxPlayer = _sfxPool[_nextSfxIndex];
      _nextSfxIndex = (_nextSfxIndex + 1) % _sfxPool.length;

      sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      sfxPlayer.setReleaseMode(ReleaseMode.stop);
      sfxPlayer.setVolume(_sfxVolume);
      // SFX should not steal audio focus from music; allow mixing
      sfxPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            // No mixWithOthers here; ambient already mixes by default on iOS
          ),
        ),
      );
      sfxPlayer.play(AssetSource('sounds/$soundName'));

      // Optionally cap long cheers/groans to keep gameplay snappy
      final cap = _sfxDurationCapsMs[soundName];
      if (cap != null) {
        Future.delayed(Duration(milliseconds: cap), () {
          // Stop only if still playing this sound
          sfxPlayer.stop();
        });
      }
    }
  }

  // --- Settings Methods ---
  void toggleSound([bool? isEnabled]) {
    if (isEnabled != null) {
      _isSoundEnabled = isEnabled;
    } else {
      _isSoundEnabled = !_isSoundEnabled;
    }
    if (_isSoundEnabled) {
      playMusic();
    } else {
      stopMusic();
    }
    notifyListeners();
  }

  void toggleMusic() {
    _isSoundEnabled = !_isSoundEnabled;
    if (_isSoundEnabled) {
      playMusic();
    } else {
      stopMusic();
    }
    notifyListeners();
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume;
    _musicPlayer.setVolume(_musicVolume);
    notifyListeners();
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume;
    notifyListeners();
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    super.dispose();
  }
}
