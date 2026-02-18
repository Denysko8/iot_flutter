import 'package:flutter/material.dart';
import 'package:iot_flutter/widgets/setting_card.dart';

class AutoModeControls extends StatelessWidget {
  final bool wakeBeforeSunrise;
  final ValueChanged<bool> onWakeBeforeSunriseChanged;
  final bool wakeAtSunriseTime;
  final ValueChanged<bool> onWakeAtSunriseTimeChanged;
  final TimeOfDay wakeTime;
  final ValueChanged<TimeOfDay> onWakeTimeChanged;
  final int wakeMinutesBefore;
  final ValueChanged<int> onWakeMinutesBeforeChanged;
  final bool temperatureControlEnabled;
  final ValueChanged<bool> onTemperatureControlEnabledChanged;
  final double temperatureThreshold;
  final ValueChanged<double> onTemperatureThresholdChanged;
  final double temperatureClosurePercent;
  final ValueChanged<double> onTemperatureClosurePercentChanged;
  final bool weatherControlEnabled;
  final ValueChanged<bool> onWeatherControlEnabledChanged;
  final Set<String> selectedWeathers;
  final ValueChanged<Set<String>> onWeathersChanged;
  final double weatherClosurePercent;
  final ValueChanged<double> onWeatherClosurePercentChanged;

  const AutoModeControls({
    required this.wakeBeforeSunrise,
    required this.onWakeBeforeSunriseChanged,
    required this.wakeAtSunriseTime,
    required this.onWakeAtSunriseTimeChanged,
    required this.wakeTime,
    required this.onWakeTimeChanged,
    required this.wakeMinutesBefore,
    required this.onWakeMinutesBeforeChanged,
    required this.temperatureControlEnabled,
    required this.onTemperatureControlEnabledChanged,
    required this.temperatureThreshold,
    required this.onTemperatureThresholdChanged,
    required this.temperatureClosurePercent,
    required this.onTemperatureClosurePercentChanged,
    required this.weatherControlEnabled,
    required this.onWeatherControlEnabledChanged,
    required this.selectedWeathers,
    required this.onWeathersChanged,
    required this.weatherClosurePercent,
    required this.onWeatherClosurePercentChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingCard(
          title: 'Wakey, wakey!',
          icon: Icons.wb_sunny,
          trailing: Switch(
            value: wakeBeforeSunrise,
            onChanged: onWakeBeforeSunriseChanged,
          ),
          child: wakeBeforeSunrise
              ? Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('At dawn'),
                      value: wakeAtSunriseTime,
                      onChanged: (value) =>
                          onWakeAtSunriseTimeChanged(value ?? true),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    InkWell(
                      onTap: wakeAtSunriseTime
                          ? null
                          : () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: wakeTime,
                              );
                              if (pickedTime != null) {
                                onWakeTimeChanged(pickedTime);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: wakeAtSunriseTime
                                ? Colors.grey.shade300
                                : Colors.blue,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wake up time:',
                              style: TextStyle(
                                color: wakeAtSunriseTime
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              wakeTime.format(context),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: wakeAtSunriseTime
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Launch before waking up:',
                          style: TextStyle(
                            color: wakeAtSunriseTime
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        Text(
                          '$wakeMinutesBefore min',
                          style: TextStyle(
                            color: wakeAtSunriseTime
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: wakeMinutesBefore.toDouble(),
                      max: 60,
                      divisions: 12,
                      onChanged: wakeAtSunriseTime
                          ? null
                          : (value) =>
                              onWakeMinutesBeforeChanged(value.round()),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        SettingCard(
          title: 'Temperature Control',
          icon: Icons.thermostat,
          trailing: Switch(
            value: temperatureControlEnabled,
            onChanged: onTemperatureControlEnabledChanged,
          ),
          child: temperatureControlEnabled
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Threshold:'),
                        Text('${temperatureThreshold.round()}°C'),
                      ],
                    ),
                    Slider(
                      value: temperatureThreshold,
                      min: 15,
                      max: 40,
                      divisions: 25,
                      onChanged: onTemperatureThresholdChanged,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Close by:'),
                        Text('${temperatureClosurePercent.round()}%'),
                      ],
                    ),
                    Slider(
                      value: temperatureClosurePercent,
                      max: 100,
                      divisions: 100,
                      onChanged: onTemperatureClosurePercentChanged,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        SettingCard(
          title: 'Weather Control',
          icon: Icons.cloud,
          trailing: Switch(
            value: weatherControlEnabled,
            onChanged: onWeatherControlEnabledChanged,
          ),
          child: weatherControlEnabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select conditions (1-3):',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWeatherChip(
                          context,
                          'Rain',
                          Icons.water_drop,
                        ),
                        _buildWeatherChip(
                          context,
                          'Thunderstorm',
                          Icons.thunderstorm,
                        ),
                        _buildWeatherChip(
                          context,
                          'Clouds',
                          Icons.cloud,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Open to:',
                          style: TextStyle(
                            color: selectedWeathers.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        Text(
                          '${weatherClosurePercent.round()}%',
                          style: TextStyle(
                            color: selectedWeathers.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: weatherClosurePercent,
                      max: 100,
                      onChanged: selectedWeathers.isEmpty
                          ? null
                          : onWeatherClosurePercentChanged,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildWeatherChip(
    BuildContext context,
    String weather,
    IconData icon,
  ) {
    final isSelected = selectedWeathers.contains(weather);
    final canSelect = selectedWeathers.length < 3 || isSelected;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(weather),
        ],
      ),
      selected: isSelected,
      onSelected: canSelect
          ? (selected) {
              final newSet = Set<String>.from(selectedWeathers);
              if (selected) {
                newSet.add(weather);
              } else {
                newSet.remove(weather);
              }
              onWeathersChanged(newSet);
            }
          : null,
    );
  }
}
