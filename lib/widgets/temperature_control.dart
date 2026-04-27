// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:iot_flutter/widgets/setting_card.dart';

class TemperatureControl extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final double threshold;
  final ValueChanged<double> onThresholdChanged;
  final double closurePercent;
  final ValueChanged<double> onClosurePercentChanged;

  const TemperatureControl({
    required this.enabled,
    required this.onEnabledChanged,
    required this.threshold,
    required this.onThresholdChanged,
    required this.closurePercent,
    required this.onClosurePercentChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: 'Temperature Control',
      icon: Icons.thermostat,
      trailing: Switch(value: enabled, onChanged: onEnabledChanged),
      child:
          enabled
              ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Threshold:'),
                      Text('${threshold.round()}°C'),
                    ],
                  ),
                  Slider(
                    value: threshold,
                    min: 15,
                    max: 40,
                    divisions: 25,
                    label: '${threshold.round()}°C',
                    onChanged: onThresholdChanged,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Close by:'),
                      Text('${closurePercent.round()}%'),
                    ],
                  ),
                  Slider(
                    value: closurePercent,
                    max: 100,
                    divisions: 100,
                    label: '${closurePercent.round()}%',
                    onChanged: onClosurePercentChanged,
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }
}
