import 'package:flutter/material.dart';
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
  bool _wakeBeforeSunrise = false;
  bool _wakeAtSunriseTime = true;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _wakeMinutesBefore = 15;
  bool _temperatureControlEnabled = false;
  double _temperatureThreshold = 25;
  double _temperatureClosurePercent = 80;
  bool _weatherControlEnabled = false;
  Set<String> _selectedWeathers = {};
  double _weatherClosurePercent = 60;

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
                    wakeBeforeSunrise: _wakeBeforeSunrise,
                    onWakeBeforeSunriseChanged: (value) {
                      setState(() {
                        _wakeBeforeSunrise = value;
                      });
                    },
                    wakeAtSunriseTime: _wakeAtSunriseTime,
                    onWakeAtSunriseTimeChanged: (value) {
                      setState(() {
                        _wakeAtSunriseTime = value;
                      });
                    },
                    wakeTime: _wakeTime,
                    onWakeTimeChanged: (value) {
                      setState(() {
                        _wakeTime = value;
                      });
                    },
                    wakeMinutesBefore: _wakeMinutesBefore,
                    onWakeMinutesBeforeChanged: (value) {
                      setState(() {
                        _wakeMinutesBefore = value;
                      });
                    },
                    temperatureControlEnabled: _temperatureControlEnabled,
                    onTemperatureControlEnabledChanged: (value) {
                      setState(() {
                        _temperatureControlEnabled = value;
                      });
                    },
                    temperatureThreshold: _temperatureThreshold,
                    onTemperatureThresholdChanged: (value) {
                      setState(() {
                        _temperatureThreshold = value;
                      });
                    },
                    temperatureClosurePercent: _temperatureClosurePercent,
                    onTemperatureClosurePercentChanged: (value) {
                      setState(() {
                        _temperatureClosurePercent = value;
                      });
                    },
                    weatherControlEnabled: _weatherControlEnabled,
                    onWeatherControlEnabledChanged: (value) {
                      setState(() {
                        _weatherControlEnabled = value;
                      });
                    },
                    selectedWeathers: _selectedWeathers,
                    onWeathersChanged: (value) {
                      setState(() {
                        _selectedWeathers = value;
                      });
                    },
                    weatherClosurePercent: _weatherClosurePercent,
                    onWeatherClosurePercentChanged: (value) {
                      setState(() {
                        _weatherClosurePercent = value;
                      });
                    },
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
