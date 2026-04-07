import 'package:flutter/material.dart';
import 'package:iot_flutter/widgets/setting_card.dart';

class WeatherControl extends StatefulWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final Set<String> selected;
  final ValueChanged<Set<String>> onSelectedChanged;
  final double closurePercent;
  final ValueChanged<double> onClosurePercentChanged;

  const WeatherControl({
    required this.enabled,
    required this.onEnabledChanged,
    required this.selected,
    required this.onSelectedChanged,
    required this.closurePercent,
    required this.onClosurePercentChanged,
    super.key,
  });

  @override
  State<WeatherControl> createState() => _WeatherControlState();
}

class _WeatherControlState extends State<WeatherControl> {
  late double _localClosurePercent;

  @override
  void initState() {
    super.initState();
    _localClosurePercent = widget.closurePercent;
  }

  @override
  void didUpdateWidget(WeatherControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.closurePercent != oldWidget.closurePercent) {
      _localClosurePercent = widget.closurePercent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: 'Weather Control',
      icon: Icons.cloud,
      trailing: Switch(value: widget.enabled, onChanged: widget.onEnabledChanged),
      child: widget.enabled
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
                    _buildWeatherChip(context, 'Rain', Icons.water_drop),
                    _buildWeatherChip(
                      context,
                      'Thunderstorm',
                      Icons.thunderstorm,
                    ),
                    _buildWeatherChip(context, 'Clouds', Icons.cloud),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Open to:',
                      style: TextStyle(
                        color: widget.selected.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                    Text(
                      '${_localClosurePercent.round()}%',
                      style: TextStyle(
                        color: widget.selected.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _localClosurePercent,
                  max: 100,
                  divisions: 100,
                  label: '${_localClosurePercent.round()}%',
                  onChanged: widget.selected.isEmpty
                      ? null
                      : (v) {
                          setState(() {
                            _localClosurePercent = v;
                          });
                        },
                  onChangeEnd: widget.selected.isEmpty
                      ? null
                      : (v) {
                          widget.onClosurePercentChanged(v);
                        },
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildWeatherChip(
    BuildContext context,
    String weather,
    IconData icon,
  ) {
    final isSelected = widget.selected.contains(weather);
    final canSelect = widget.selected.length < 3 || isSelected;
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
          ? (sel) {
              final newSet = Set<String>.from(widget.selected);
              if (sel) {
                newSet.add(weather);
              } else {
                newSet.remove(weather);
              }
              widget.onSelectedChanged(newSet);
            }
          : null,
    );
  }
}
