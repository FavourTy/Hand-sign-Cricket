// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hand_sign_cricket/screens/toss_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

import '../themes/app_colors.dart';

class GameSetupScreen extends StatefulWidget {
  final bool isMultiplayer;
  const GameSetupScreen({super.key, required this.isMultiplayer});

  @override
  _GameSetupScreenState createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _overs = 1;
  int _numPlayers = 2;
  String _teamName = '';
  List<String> _playerNames = [];
  final _teamNameController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _playerNames = List.generate(_numPlayers, (_) => '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTitle(),
              const SizedBox(height: 20),
              _buildTeamNameInput(),
              const SizedBox(height: 20),
              widget.isMultiplayer
                  ? _buildMultiplayerPlayerSelection()
                  : _buildSinglePlayerSettings(),
              _buildDropdown("Number of Overs", _overs, 1, 5, (value) {
                setState(() => _overs = value);
              }),
              const SizedBox(height: 20),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.boxYellow,
        borderRadius: BorderRadius.circular(12),
        boxShadow:const [ BoxShadow(color: AppColors.shadowBlack, blurRadius: 5)],
      ),
      child: Text(
        widget.isMultiplayer ? "Multiplayer Setup" : "Single Player Setup",
        style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextBrown),
      ),
    );
  }

  Widget _buildTeamNameInput() {
    return TextField(
      controller: _teamNameController,
      onChanged: (value) => setState(() => _teamName = value),
      decoration: InputDecoration(
        labelText: "Team Name",
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        filled: true,
        fillColor: AppColors.boxYellow.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.boxYellow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.boxYellow),
        ),
      ),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMultiplayerPlayerSelection() {
    return Column(
      children: [
        _buildDropdown("Number of Players", _numPlayers, 1, 4, (value) {
          setState(() {
            _numPlayers = value;
            _playerNames = List.generate(value, (_) => '');
          });
        }),
        const SizedBox(height: 20),
        for (int i = 0; i < _numPlayers; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              onChanged: (value) => setState(() => _playerNames[i] = value),
              decoration: InputDecoration(
                labelText: "Player ${i + 1} Name",
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                filled: true,
                fillColor: AppColors.boxYellow.withValues(alpha :0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.boxYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.boxYellow),
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildSinglePlayerSettings() {
    return Column(
      children: [
        _buildDropdown("Number of Players", _numPlayers, 1, 3, (value) {
          setState(() {
            _numPlayers = value;
            _playerNames = List.generate(value, (_) => '');
          });
        }),
        const SizedBox(height: 20),
        for (int i = 0; i < _numPlayers; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              onChanged: (value) => setState(() => _playerNames[i] = value),
              decoration: InputDecoration(
                labelText: "Player ${i + 1} Name",
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                filled: true,
                fillColor: AppColors.boxYellow.withValues(alpha :0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.boxYellow),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.boxYellow),
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(
      String label, int value, int min, int max, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.boxYellow.withValues(alpha :0.2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const[ BoxShadow(color: AppColors.shadowBlack, blurRadius: 5)],
          ),
          child: DropdownButtonFormField<int>(
            initialValue: value,
            dropdownColor: AppColors.boxYellow,
            decoration: const InputDecoration.collapsed(hintText: ''),
            items: List.generate(max - min + 1, (index) => min + index)
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) => setState(() => onChanged(newValue!)),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: () {},
      child: const Text(
        "Start Game",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        backgroundColor: AppColors.boxYellow,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: AppColors.shadowBlack,
      ),
      child: const Text(
        "Start Game",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _startSinglePlayerGame() async {
    // Save game settings to local storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('teamName', _teamName);
    prefs.setInt('overs', _overs);
    prefs.setStringList('playerNames', _playerNames);

    // Navigate to TossScreen with isMultiplayer = false
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => TossScreen(),
      ),
    );
  }

  void _syncMultiplayerSettings() {
    // Save game settings to Firebase for multiplayer matchmaking
    String gameId = DateTime.now().millisecondsSinceEpoch.toString();
    _database.child('games/$gameId').set({
      'teamName': _teamName,
      'overs': _overs,
      'playerNames': _playerNames,
      'status': 'waiting', // Players are waiting to join
    }).then((_) {
      // Navigate to TossScreen with isMultiplayer = true
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => TossScreen(isMultiplayer: true),
      //   ),
      // );
    });
  }
}
