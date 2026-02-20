import 'package:flutter/material.dart';
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/widgets/temperature_control.dart';
import 'package:iot_flutter/widgets/wakey_settings.dart';
import 'package:iot_flutter/widgets/weather_control.dart';

class AutoModeControls extends StatelessWidget {
  final AutoModeSettings settings;
  final ValueChanged<AutoModeSettings> onChanged;
  final bool parentActive;

  const AutoModeControls({
    required this.settings,
    required this.onChanged,
    this.parentActive = true,
    super.key,
  });

  void _update(void Function(AutoModeSettings) fn) {
    final copy = AutoModeSettings(
      wakeBeforeSunrise: settings.wakeBeforeSunrise,
      wakeAtSunriseTime: settings.wakeAtSunriseTime,
      wakeTime: settings.wakeTime,
      wakeMinutesBefore: settings.wakeMinutesBefore,
      temperatureControlEnabled: settings.temperatureControlEnabled,
      temperatureThreshold: settings.temperatureThreshold,
      temperatureClosurePercent: settings.temperatureClosurePercent,
      weatherControlEnabled: settings.weatherControlEnabled,
      selectedWeathers: Set<String>.from(settings.selectedWeathers),
      weatherClosurePercent: settings.weatherClosurePercent,
    );
    fn(copy);
    onChanged(copy);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WakeySettings(
          enabled: settings.wakeBeforeSunrise,
          onEnabledChanged: (v) => _update((s) => s.wakeBeforeSunrise = v),
          atSunrise: settings.wakeAtSunriseTime,
          onAtSunriseChanged: (v) =>
              _update((s) => s.wakeAtSunriseTime = v),
          time: settings.wakeTime,
          onTimeChanged: (t) => _update((s) => s.wakeTime = t),
          minutesBefore: settings.wakeMinutesBefore,
          onMinutesBeforeChanged: (m) =>
              _update((s) => s.wakeMinutesBefore = m),
          parentActive: parentActive,
        ),
        const SizedBox(height: 16),
        TemperatureControl(
          enabled: settings.temperatureControlEnabled,
          onEnabledChanged: (v) =>
              _update((s) => s.temperatureControlEnabled = v),
          threshold: settings.temperatureThreshold,
          onThresholdChanged: (v) =>
              _update((s) => s.temperatureThreshold = v),
          closurePercent: settings.temperatureClosurePercent,
          onClosurePercentChanged: (v) =>
              _update((s) => s.temperatureClosurePercent = v),
        ),
        const SizedBox(height: 16),
        WeatherControl(
          enabled: settings.weatherControlEnabled,
          onEnabledChanged: (v) =>
              _update((s) => s.weatherControlEnabled = v),
          selected: settings.selectedWeathers,
          onSelectedChanged: (set) => _update((s) => s.selectedWeathers = set),
          closurePercent: settings.weatherClosurePercent,
          onClosurePercentChanged: (v) =>
              _update((s) => s.weatherClosurePercent = v),
        ),
      ],
    );
  }
}
