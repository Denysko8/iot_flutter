// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/cubits/profile_cubit.dart';
import 'package:iot_flutter/widgets/custom_button.dart';
import 'package:iot_flutter/widgets/custom_text_field.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _cityController = TextEditingController();
  bool _isLoading = false;
  String? _currentCity;
  double? _currentLat;
  double? _currentLon;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _loadCurrentLocation() {
    final user = context.read<ProfileCubit>().state.currentUser;
    if (user != null && user.city != null) {
      setState(() {
        _currentCity = user.city;
        _currentLat = user.latitude;
        _currentLon = user.longitude;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final location = await context.read<ProfileCubit>().getCurrentLocation();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (location != null) {
          _currentCity = location['city'] as String;
          _currentLat = location['latitude'] as double;
          _currentLon = location['longitude'] as double;
        }
      });
    }
  }

  Future<void> _setLocationByCity() async {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введіть назву міста')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final location = await context.read<ProfileCubit>().setLocationByCity(
      _cityController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (location != null) {
          _currentCity = location['city'] as String;
          _currentLat = location['latitude'] as double;
          _currentLon = location['longitude'] as double;
          _cityController.clear();
        }
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_currentCity == null || _currentLat == null || _currentLon == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Спочатку оберіть локацію')));
      return;
    }

    final success = await context.read<ProfileCubit>().saveLocation(
      _currentCity!,
      _currentLat!,
      _currentLon!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Локацію успішно збережено'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування локації')),
      body: SafeArea(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.location_on,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Встановіть вашу локацію',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Локація використовується для моніторингу погоди та розрахунку часу світанку',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_currentCity != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Поточна локація:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentCity!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Широта: ${_currentLat!.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Довгота: ${_currentLon!.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (context.watch<ProfileCubit>().state.errorMessage !=
                    null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(
                      context.watch<ProfileCubit>().state.errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                CustomButton(
                  text:
                      _isLoading ? 'Завантаження...' : 'Визначити автоматично',
                  onPressed: _isLoading ? () {} : _getCurrentLocation,
                  icon: Icons.my_location,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'або введіть назву міста:',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _cityController,
                  label: 'Назва міста',
                  icon: Icons.location_city,
                  hint: 'Наприклад: Kyiv, Lviv, Odesa',
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: _isLoading ? 'Пошук...' : 'Знайти місто',
                  onPressed: _isLoading ? () {} : _setLocationByCity,
                  isPrimary: false,
                  icon: Icons.search,
                ),
                const SizedBox(height: 32),
                if (_currentCity != null)
                  CustomButton(
                    text: 'Зберегти локацію',
                    onPressed: _saveLocation,
                    icon: Icons.save,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
