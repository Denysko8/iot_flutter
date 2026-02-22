import 'package:flutter/material.dart';

class AutoModeSettings {
  bool wakeBeforeSunrise;
  bool wakeAtSunriseTime;
  TimeOfDay wakeTime;
  int wakeMinutesBefore;
  bool temperatureControlEnabled;
  double temperatureThreshold;
  double temperatureClosurePercent;
  bool weatherControlEnabled;
  Set<String> selectedWeathers;
  double weatherClosurePercent;

  AutoModeSettings({
    this.wakeBeforeSunrise = false,
    this.wakeAtSunriseTime = true,
    TimeOfDay? wakeTime,
    this.wakeMinutesBefore = 0,
    this.temperatureControlEnabled = false,
    this.temperatureThreshold = 22.0,
    this.temperatureClosurePercent = 50,
    this.weatherControlEnabled = false,
    Set<String>? selectedWeathers,
    this.weatherClosurePercent = 50,
  })  : wakeTime = wakeTime ?? const TimeOfDay(hour: 7, minute: 0),
        selectedWeathers = selectedWeathers ?? <String>{};
}
