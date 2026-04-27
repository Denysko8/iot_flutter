import 'package:flutter/material.dart';
import 'package:iot_flutter/widgets/setting_card.dart';

class WakeySettings extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final bool atSunrise;
  final ValueChanged<bool> onAtSunriseChanged;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final int minutesBefore;
  final ValueChanged<int> onMinutesBeforeChanged;
  final double openPercent;
  final ValueChanged<double> onOpenPercentChanged;
  final bool parentActive;

  const WakeySettings({
    required this.enabled,
    required this.onEnabledChanged,
    required this.atSunrise,
    required this.onAtSunriseChanged,
    required this.time,
    required this.onTimeChanged,
    required this.minutesBefore,
    required this.onMinutesBeforeChanged,
    required this.openPercent,
    required this.onOpenPercentChanged,
    this.parentActive = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showExpanded = enabled && parentActive;
    return SettingCard(
      title: 'Wakey, wakey!',
      icon: Icons.wb_sunny,
      trailing: Switch(value: enabled, onChanged: onEnabledChanged),
      child:
          showExpanded
              ? Column(
                children: [
                  CheckboxListTile(
                    title: const Text('At dawn'),
                    value: atSunrise,
                    onChanged: (v) {
                      onAtSunriseChanged(v ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  InkWell(
                    onTap:
                        atSunrise
                            ? null
                            : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: time,
                              );
                              if (picked != null) onTimeChanged(picked);
                            },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: atSunrise ? Colors.grey.shade300 : Colors.blue,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Wake up time:',
                            style: TextStyle(
                              color: atSunrise ? Colors.grey : Colors.black,
                            ),
                          ),
                          Text(
                            time.format(context),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: atSunrise ? Colors.grey : Colors.black,
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
                          color: atSunrise ? Colors.grey : Colors.black,
                        ),
                      ),
                      Text(
                        '$minutesBefore min',
                        style: TextStyle(
                          color: atSunrise ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: minutesBefore.toDouble(),
                    max: 60,
                    divisions: 60,
                    label: '$minutesBefore min',
                    onChanged:
                        atSunrise
                            ? null
                            : (v) => onMinutesBeforeChanged(v.round()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Open to:'),
                      Text('${openPercent.round()}%'),
                    ],
                  ),
                  Slider(
                    value: openPercent,
                    max: 100,
                    divisions: 100,
                    label: '${openPercent.round()}%',
                    onChanged: onOpenPercentChanged,
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }
}
