import 'package:flutter/material.dart';

class ManualModeControls extends StatelessWidget {
  final double sliderValue;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;

  const ManualModeControls({
    required this.sliderValue,
    required this.onSliderChanged,
    this.onSliderChangeEnd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Blinds Position',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '${sliderValue.round()}%',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: sliderValue,
              max: 100,
              onChanged: onSliderChanged,
              onChangeEnd: onSliderChangeEnd,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Closed', style: Theme.of(context).textTheme.bodySmall),
                Text('Open', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
