import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/cubits/home_cubit.dart';
import 'package:iot_flutter/models/cloud_sync_state.dart';
import 'package:iot_flutter/screens/profile_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';
import 'package:iot_flutter/widgets/auto_mode_controls.dart';
import 'package:iot_flutter/widgets/manual_mode_controls.dart';
import 'package:iot_flutter/widgets/mode_toggle_button.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create:
          (_) => HomeCubit(
            prefs: ServiceLocator().prefs,
            mqttRepo: ServiceLocator().smartWindowRepository,
            connectivityService: ServiceLocator().connectivityService,
            autoModeExecutor: ServiceLocator().autoModeExecutor,
            userUseCase: ServiceLocator().userUseCase,
            mockApiStorageService: ServiceLocator().mockApiStorageService,
          )..init(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen:
          (previous, current) =>
              previous.errorMessage != current.errorMessage ||
              previous.infoMessage != current.infoMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<HomeCubit>().clearMessages();
        } else if (state.infoMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.infoMessage!),
              backgroundColor: Colors.green,
            ),
          );
          context.read<HomeCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Blinds Control'),
            actions: [
              Icon(
                state.isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
                color: state.isConnectedToInternet ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Icon(
                state.isConnectedToMqtt ? Icons.cloud_done : Icons.cloud_off,
                color: state.isConnectedToMqtt ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
              ),
            ],
          ),
          body: SafeArea(
            child: ResponsivePadding(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.window,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    if (!_isFullyConnected(state))
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                !state.isConnectedToInternet
                                    ? 'Немає з\'єднання з Інтернетом'
                                    : 'Немає з\'єднання з MQTT брокером',
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (kIsWeb)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'MQTT функціонал обмежений у веб-версії',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ModeToggleButton(
                      isAutoMode: state.isAutoMode,
                      onToggle: () => context.read<HomeCubit>().toggleMode(),
                    ),
                    const SizedBox(height: 24),
                    if (!state.isAutoMode)
                      ManualModeControls(
                        sliderValue: state.sliderValue,
                        onSliderChanged:
                            (value) => context
                                .read<HomeCubit>()
                                .manualPositionChanging(value),
                        onSliderChangeEnd:
                            (value) => context
                                .read<HomeCubit>()
                                .manualPositionChangeEnd(value),
                      )
                    else
                      AutoModeControls(
                        settings: state.autoSettings,
                        onChanged:
                            (settings) => context
                                .read<HomeCubit>()
                                .autoModeChanged(settings),
                        onSave:
                            () => context.read<HomeCubit>().saveAutoSettings(),
                        parentActive: state.isAutoMode,
                      ),
                    const SizedBox(height: 16),
                    _CloudStateCard(
                      cloudState: state.cloudState,
                      isLoading: state.isCloudLoading,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isFullyConnected(HomeState state) {
    return state.isConnectedToInternet && state.isConnectedToMqtt;
  }
}

class _CloudStateCard extends StatelessWidget {
  final CloudSyncState? cloudState;
  final bool isLoading;

  const _CloudStateCard({required this.cloudState, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Завантаження даних з API...'),
            ],
          ),
        ),
      );
    }

    if (cloudState == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Дані з API ще не синхронізовані'),
        ),
      );
    }

    final sourceLabel = cloudState!.fromCache ? 'локальний кеш' : 'MockAPI';
    final updated =
        '${cloudState!.updatedAt.hour.toString().padLeft(2, '0')}:'
        '${cloudState!.updatedAt.minute.toString().padLeft(2, '0')}';
    final temperatureStatus =
        cloudState!.autoSettings.temperatureControlEnabled ? 'on' : 'off';
    final weatherStatus =
        cloudState!.autoSettings.weatherControlEnabled ? 'on' : 'off';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Синхронізовані дані ($sourceLabel)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Користувач: ${cloudState!.user.name} '
              '(${cloudState!.user.email})',
            ),
            Text('Режим: ${cloudState!.isAutoMode ? "Auto" : "Manual"}'),
            Text('Позиція: ${cloudState!.manualPosition}%'),
            Text(
              'Wakey: '
              '${cloudState!.autoSettings.wakeySensors ? "on" : "off"}',
            ),
            Text('Temperature: $temperatureStatus'),
            Text('Weather: $weatherStatus'),
            Text('Оновлено: $updated'),
          ],
        ),
      ),
    );
  }
}
