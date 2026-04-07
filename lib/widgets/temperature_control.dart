// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:iot_flutter/widgets/setting_card.dart';

class TemperatureControl extends StatefulWidget {
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
  State<TemperatureControl> createState() => _TemperatureControlState();
}

class _TemperatureControlState extends State<TemperatureControl> {
  late double _localThreshold;
  late double _localClosurePercent;

  @override
  void initState() {
    super.initState();
    _localThreshold = widget.threshold;
    _localClosurePercent = widget.closurePercent;
  }

  @override
  void didUpdateWidget(TemperatureControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.threshold != oldWidget.threshold) {
      _localThreshold = widget.threshold;
    }
    if (widget.closurePercent != oldWidget.closurePercent) {
      _localClosurePercent = widget.closurePercent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: 'Temperature Control',
      icon: Icons.thermostat,
      trailing: Switch(
        value: widget.enabled,
        onChanged: widget.onEnabledChanged,
      ),
      child:
          widget.enabled
              ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Threshold:'),
                      Text('${_localThreshold.round()}°C'),
                    ],
                  ),
                  Slider(
                    value: _localThreshold,
                    min: 15,
                    max: 40,
                    divisions: 25,
                    label: '${_localThreshold.round()}°C',
                    onChanged: (v) {
                      setState(() {
                        _localThreshold = v;
                      });
                    },
                    onChangeEnd: (v) {
                      widget.onThresholdChanged(v);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Close by:'),
                      Text('${_localClosurePercent.round()}%'),
                    ],
                  ),
                  Slider(
                    value: _localClosurePercent,
                    max: 100,
                    divisions: 100,
                    label: '${_localClosurePercent.round()}%',
                    onChanged: (v) {
                      setState(() {
                        _localClosurePercent = v;
                      });
                    },
                    onChangeEnd: (v) {
                      widget.onClosurePercentChanged(v);
                    },
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }
}
