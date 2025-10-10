// ignore_for_file: file_names, avoid_print

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

enum Difficulty { easy, medium, hard }

enum GameSituation { batting, bowling, chasing, defending }

class GameState {
  final int playerScore;
  final int botScore;
  final int wickets;
  final int balls;
  final int overs;
  final int target;
  final bool isFirstInnings;
  final bool isPlayerBatting;
  final int maxOvers;
  final int maxWickets;

  GameState({
    required this.playerScore,
    required this.botScore,
    required this.wickets,
    required this.balls,
    required this.overs,
    required this.target,
    required this.isFirstInnings,
    required this.isPlayerBatting,
    required this.maxOvers,
    required this.maxWickets,
  });

  // Calculate remaining balls in the innings
  int get remainingBalls => (maxOvers * 6) - balls;

  // Calculate remaining overs (with decimals)
  double get remainingOvers => remainingBalls / 6.0;

  // Calculate runs needed (for chasing)
  int get runsNeeded => target - (isPlayerBatting ? playerScore : botScore);

  // Calculate required run rate for chasing team
  double get requiredRunRate => remainingBalls > 0 ? runsNeeded / remainingOvers : 0;

  // Determine the current game situation
  GameSituation get situation {
    if (isFirstInnings) {
      return isPlayerBatting ? GameSituation.batting : GameSituation.bowling;
    } else {
      return isPlayerBatting ? GameSituation.chasing : GameSituation.defending;
    }
  }

  // Check if it's a pressure situation
  bool get isPressureSituation {
    if (isFirstInnings) {
      // Last few overs or few wickets remaining
      return remainingOvers <= 2.0 || (maxWickets - wickets) <= 1;
    } else {
      // Close chase or defending small target
      return runsNeeded <= 15 || requiredRunRate > 8;
    }
  }
}

class UserPattern {
  List<int> recentChoices = [];
  Map<int, int> frequencyMap = {};
  int consecutivePatternCount = 0;
  int? lastChoice;

  void addChoice(int choice) {
    recentChoices.add(choice);
    if (recentChoices.length > 20) {
      recentChoices.removeAt(0); // Keep only last 20 choices
    }

    frequencyMap[choice] = (frequencyMap[choice] ?? 0) + 1;

    // Track consecutive patterns
    if (lastChoice == choice) {
      consecutivePatternCount++;
    } else {
      consecutivePatternCount = 0;
    }
    lastChoice = choice;
  }

  int? get mostFrequent {
    if (frequencyMap.isEmpty) return null;
    int mostFreqNum = 1;
    int maxCount = 0;
    for (var entry in frequencyMap.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostFreqNum = entry.key;
      }
    }
    return mostFreqNum;
  }

  int? get leastFrequent {
    if (frequencyMap.isEmpty) return null;
    int leastFreqNum = 1;
    int minCount = double.maxFinite.toInt();
    for (var entry in frequencyMap.entries) {
      if (entry.value < minCount) {
        minCount = entry.value;
        leastFreqNum = entry.key;
      }
    }
    return leastFreqNum;
  }

  bool get hasRepeatingPattern => consecutivePatternCount >= 2;

  List<int> get last3Choices {
    if (recentChoices.length < 3) return recentChoices;
    return recentChoices.sublist(recentChoices.length - 3);
  }
}

class AiBot {
  final Difficulty difficulty;
  final UserPattern userPattern = UserPattern();
  final Random _random = Random();

  AiBot({required this.difficulty});

  // Main decision method
  int makeDecision(int userChoice, GameState gameState) {
    // Learn from user's choice
    userPattern.addChoice(userChoice);

    switch (difficulty) {
      case Difficulty.easy:
        return _easyDecision(userChoice, gameState);
      case Difficulty.medium:
        return _mediumDecision(userChoice, gameState);
      case Difficulty.hard:
        return _hardDecision(userChoice, gameState);
    }
  }

  // Easy difficulty: Mostly random with basic logic
  int _easyDecision(int userChoice, GameState gameState) {
    // 80% random, 20% basic strategy
    if (_random.nextDouble() < 0.2) {
      return _basicStrategy(gameState);
    }
    return _random.nextInt(6) + 1;
  }

  // Medium difficulty: Balanced strategy with some pattern recognition
  int _mediumDecision(int userChoice, GameState gameState) {
    // 40% strategic, 30% anti-pattern, 30% random
    double rand = _random.nextDouble();

    if (rand < 0.4) {
      return _strategicDecision(gameState);
    } else if (rand < 0.7) {
      return _antiPatternChoice(userChoice, gameState);
    } else {
      return _random.nextInt(6) + 1;
    }
  }

  // Hard difficulty: Advanced strategy with pattern learning
  int _hardDecision(int userChoice, GameState gameState) {
    // 60% strategic, 25% anti-pattern, 10% psychological, 5% random
    double rand = _random.nextDouble();

    if (rand < 0.6) {
      return _strategicDecision(gameState);
    } else if (rand < 0.85) {
      return _antiPatternChoice(userChoice, gameState);
    } else if (rand < 0.95) {
      return _psychologicalChoice(userChoice, gameState);
    } else {
      return _random.nextInt(6) + 1;
    }
  }

  // Basic strategy for easy difficulty
  int _basicStrategy(GameState gameState) {
    if (!gameState.isFirstInnings && gameState.situation == GameSituation.defending) {
      // When defending, try to get the user out more often
      int runsNeeded = gameState.runsNeeded;
      if (runsNeeded <= 6) {
        return runsNeeded; // Try to deny exact runs needed
      }
    }
    return _random.nextInt(6) + 1;
  }

  // Strategic decision based on game state
  int _strategicDecision(GameState gameState) {
    switch (gameState.situation) {
      case GameSituation.batting:
        return _battingStrategy(gameState);
      case GameSituation.bowling:
        return _bowlingStrategy(gameState);
      case GameSituation.chasing:
        return _chasingStrategy(gameState);
      case GameSituation.defending:
        return _defendingStrategy(gameState);
    }
  }

  int _battingStrategy(GameState gameState) {
    // When bot is batting in first innings
    if (gameState.isPressureSituation) {
      // In pressure, play more conservatively
      List<int> safeChoices = [1, 2, 3];
      return safeChoices[_random.nextInt(safeChoices.length)];
    } else {
      // Normal batting - mix of safe and aggressive
      List<int> choices = [1, 2, 3, 4, 5, 6];
      List<int> weights = [20, 25, 20, 15, 12, 8]; // Favor lower numbers slightly
      return _weightedChoice(choices, weights);
    }
  }

  int _bowlingStrategy(GameState gameState) {
    // When bot is bowling to user in first innings
    if (gameState.isPressureSituation) {
      // In pressure situations, try to get user out
      int? mostFreq = userPattern.mostFrequent;
      if (mostFreq != null) {
        return mostFreq; // Target user's favorite number
      }
    }

    // Normal bowling - try to read user patterns
    if (userPattern.hasRepeatingPattern && userPattern.lastChoice != null) {
      // User is repeating - target that number
      return userPattern.lastChoice!;
    }

    // Default to balanced approach
    return _random.nextInt(6) + 1;
  }

  int _chasingStrategy(GameState gameState) {
    // When bot is chasing a target
    int runsNeeded = gameState.runsNeeded;
    double requiredRate = gameState.requiredRunRate;

    if (runsNeeded <= 0) return _random.nextInt(6) + 1;

    if (runsNeeded <= 6) {
      // Need exact runs - be strategic
      return runsNeeded;
    } else if (requiredRate > 10) {
      // Need to go aggressive
      List<int> aggressive = [4, 5, 6];
      return aggressive[_random.nextInt(aggressive.length)];
    } else if (requiredRate < 4) {
      // Can play safe
      List<int> safe = [1, 2, 3];
      return safe[_random.nextInt(safe.length)];
    } else {
      // Balanced approach
      return _random.nextInt(6) + 1;
    }
  }

  int _defendingStrategy(GameState gameState) {
    // When bot is bowling while defending a target
    int runsNeeded = gameState.runsNeeded;

    if (runsNeeded <= 6) {
      // Try to deny exact runs
      return runsNeeded;
    } else if (runsNeeded <= 15) {
      // Pressure situation - target user patterns
      int? mostFreq = userPattern.mostFrequent;
      if (mostFreq != null) {
        return mostFreq;
      }
    }

    // General defensive bowling
    return _antiPatternChoice(userPattern.lastChoice ?? 1, gameState);
  }

  // Anti-pattern choice - avoid user's frequent numbers
  int _antiPatternChoice(int userChoice, GameState gameState) {
    int? leastFreq = userPattern.leastFrequent;
    if (leastFreq != null) {
      return leastFreq;
    }

    // If user has a pattern, break it
    if (userPattern.hasRepeatingPattern) {
      List<int> avoidChoices = [userChoice];
      if (userPattern.mostFrequent != null) {
        avoidChoices.add(userPattern.mostFrequent!);
      }

      List<int> goodChoices = [];
      for (int i = 1; i <= 6; i++) {
        if (!avoidChoices.contains(i)) {
          goodChoices.add(i);
        }
      }

      if (goodChoices.isNotEmpty) {
        return goodChoices[_random.nextInt(goodChoices.length)];
      }
    }

    return _random.nextInt(6) + 1;
  }

  // Psychological choice - meta-gaming
  int _psychologicalChoice(int userChoice, GameState gameState) {
    // Reverse psychology - sometimes pick the number user just picked
    if (userPattern.recentChoices.length >= 3) {
      List<int> last3 = userPattern.last3Choices;
      if (last3[0] == last3[1] && last3[1] == last3[2]) {
        // User picked same number 3 times - they might avoid it now
        return last3[0];
      }
    }

    // Random psychological play
    if (_random.nextDouble() < 0.3) {
      return userChoice; // Mirror user's choice
    }

    return _random.nextInt(6) + 1;
  }

  // Helper method for weighted random choice
  int _weightedChoice(List<int> choices, List<int> weights) {
    if (choices.length != weights.length) {
      return choices[_random.nextInt(choices.length)];
    }

    int totalWeight = weights.reduce((a, b) => a + b);
    int randomWeight = _random.nextInt(totalWeight);

    int currentWeight = 0;
    for (int i = 0; i < choices.length; i++) {
      currentWeight += weights[i];
      if (randomWeight < currentWeight) {
        return choices[i];
      }
    }

    return choices.last;
  }

  // Save pattern learning data
  Future<void> savePatternData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Save frequency map
      for (var entry in userPattern.frequencyMap.entries) {
        await prefs.setInt('bot_freq_${entry.key}', entry.value);
      }
      
      // Save recent choices
      List<String> recentChoicesStr = userPattern.recentChoices.map((e) => e.toString()).toList();
      await prefs.setStringList('bot_recent_choices', recentChoicesStr);
      
      await prefs.setInt('bot_consecutive_count', userPattern.consecutivePatternCount);
      if (userPattern.lastChoice != null) {
        await prefs.setInt('bot_last_choice', userPattern.lastChoice!);
      }
    } catch (e) {
      print('Error saving pattern data: $e');
    }
  }

  // Load pattern learning data
  Future<void> loadPatternData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Load frequency map
      userPattern.frequencyMap.clear();
      for (int i = 1; i <= 6; i++) {
        int? freq = prefs.getInt('bot_freq_$i');
        if (freq != null && freq > 0) {
          userPattern.frequencyMap[i] = freq;
        }
      }
      
      // Load recent choices
      List<String>? recentChoicesStr = prefs.getStringList('bot_recent_choices');
      if (recentChoicesStr != null) {
        userPattern.recentChoices = recentChoicesStr.map((e) => int.tryParse(e) ?? 1).toList();
      }
      
      userPattern.consecutivePatternCount = prefs.getInt('bot_consecutive_count') ?? 0;
      userPattern.lastChoice = prefs.getInt('bot_last_choice');
    } catch (e) {
      print('Error loading pattern data: $e');
    }
  }

  // Reset learning data (for new games)
  Future<void> resetPatternData() async {
    userPattern.recentChoices.clear();
    userPattern.frequencyMap.clear();
    userPattern.consecutivePatternCount = 0;
    userPattern.lastChoice = null;
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      for (int i = 1; i <= 6; i++) {
        await prefs.remove('bot_freq_$i');
      }
      await prefs.remove('bot_recent_choices');
      await prefs.remove('bot_consecutive_count');
      await prefs.remove('bot_last_choice');
    } catch (e) {
      print('Error resetting pattern data: $e');
    }
  }
}
