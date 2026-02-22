import 'package:flutter/material.dart';

class LocationButton extends StatelessWidget {
  final String? location;
  final VoidCallback onRequestLocation;

  const LocationButton({
    required this.location,
    required this.onRequestLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onRequestLocation,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location ?? 'Tap to enable location access',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: location != null
                                ? Colors.grey[700]
                                : Colors.grey[500],
                            fontStyle: location == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                location != null ? Icons.check_circle : Icons.arrow_forward,
                color: location != null
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
