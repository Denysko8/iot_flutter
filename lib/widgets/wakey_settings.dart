import 'package:flutter/material.dart';
import 'package:iot_flutter/widgets/setting_card.dart';

class WakeySettings extends StatefulWidget {
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
  State<WakeySettings> createState() => _WakeySettingsState();
}

class _WakeySettingsState extends State<WakeySettings> {
  late double _localMinutesBefore;
  late double _localOpenPercent;

  @override
  void initState() {
    super.initState();
    _localMinutesBefore = widget.minutesBefore.toDouble();
    _localOpenPercent = widget.openPercent;
  }

  @override
  void didUpdateWidget(WakeySettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minutesBefore != oldWidget.minutesBefore) {
      _localMinutesBefore = widget.minutesBefore.toDouble();
    }
    if (widget.openPercent != oldWidget.openPercent) {
      _localOpenPercent = widget.openPercent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showExpanded = widget.enabled && widget.parentActive;
    return SettingCard(
      title: 'Wakey, wakey!',
      icon: Icons.wb_sunny,
      trailing: Switch(
        value: widget.enabled,
        onChanged: widget.onEnabledChanged,
      ),
      child:
          showExpanded
              ? Column(
                children: [
                  CheckboxListTile(
                    title: const Text('At dawn'),
                    value: widget.atSunrise,
                    onChanged: (v) {
                      widget.onAtSunriseChanged(v ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  InkWell(
                    onTap:
                        widget.atSunrise
                            ? null
                            : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: widget.time,
                              );
                              if (picked != null) widget.onTimeChanged(picked);
                            },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              widget.atSunrise
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
                              color:
                                  widget.atSunrise ? Colors.grey : Colors.black,
                            ),
                          ),
                          Text(
                            widget.time.format(context),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.atSunrise ? Colors.grey : Colors.black,
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
                          color: widget.atSunrise ? Colors.grey : Colors.black,
                        ),
                      ),
                      Text(
                        '${_localMinutesBefore.round()} min',
                        style: TextStyle(
                          color: widget.atSunrise ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _localMinutesBefore,
                    max: 60,
                    divisions: 60,
                    label: '${_localMinutesBefore.round()} min',
                    onChanged:
                        widget.atSunrise
                            ? null
                            : (v) {
                              setState(() {
                                _localMinutesBefore = v;
                              });
                            },
                    onChangeEnd:
                        widget.atSunrise
                            ? null
                            : (v) {
                              widget.onMinutesBeforeChanged(v.round());
                            },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Open to:'),
                      Text('${_localOpenPercent.round()}%'),
                    ],
                  ),
                  Slider(
                    value: _localOpenPercent,
                    max: 100,
                    divisions: 100,
                    label: '${_localOpenPercent.round()}%',
                    onChanged: (v) {
                      setState(() {
                        _localOpenPercent = v;
                      });
                    },
                    onChangeEnd: (v) {
                      widget.onOpenPercentChanged(v);
                    },
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }
}
