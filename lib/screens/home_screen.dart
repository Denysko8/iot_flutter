import 'package:flutter/material.dart';
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/screens/profile_screen.dart';
import 'package:iot_flutter/widgets/auto_mode_controls.dart';
import 'package:iot_flutter/widgets/manual_mode_controls.dart';
import 'package:iot_flutter/widgets/mode_toggle_button.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _sliderValue = 50;
  bool _isAutoMode = false;
  AutoModeSettings _autoSettings = AutoModeSettings();

  void _toggleMode() {
    setState(() {
      _isAutoMode = !_isAutoMode;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Blinds Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.window,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                ModeToggleButton(
                  isAutoMode: _isAutoMode,
                  onToggle: _toggleMode,
                ),
                const SizedBox(height: 24),
                if (!_isAutoMode)
                  ManualModeControls(
                    sliderValue: _sliderValue,
                    onSliderChanged: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                  )
                else
                  AutoModeControls(
                    settings: _autoSettings,
                    onChanged: (value) {
                      setState(() {
                        _autoSettings = value;
                      });
                    },
                    parentActive: _isAutoMode,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
