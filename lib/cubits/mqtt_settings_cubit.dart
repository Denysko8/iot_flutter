import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/services/service_locator.dart';

class MqttSettingsState {
  final bool isLoading;
  final String brokerIp;
  final String? statusMessage;
  final bool isSuccess;

  const MqttSettingsState({
    this.isLoading = false,
    this.brokerIp = '192.168.0.102',
    this.statusMessage,
    this.isSuccess = false,
  });

  MqttSettingsState copyWith({
    bool? isLoading,
    String? brokerIp,
    String? statusMessage,
    bool? isSuccess,
  }) {
    return MqttSettingsState(
      isLoading: isLoading ?? this.isLoading,
      brokerIp: brokerIp ?? this.brokerIp,
      statusMessage: statusMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class MqttSettingsCubit extends Cubit<MqttSettingsState> {
  MqttSettingsCubit() : super(const MqttSettingsState());

  Future<void> loadCurrentSettings() async {
    final prefs = ServiceLocator().prefs;
    final currentIp = prefs.getString('mqtt_broker_ip') ?? '192.168.0.102';
    emit(state.copyWith(brokerIp: currentIp));
  }

  Future<void> saveAndTestConnection(String brokerIp) async {
    emit(state.copyWith(isLoading: true));

    if (brokerIp.trim().isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          statusMessage: 'Будь ласка, введіть IP адресу брокера',
          isSuccess: false,
        ),
      );
      return;
    }

    try {
      await ServiceLocator().saveMqttBrokerAddress(brokerIp.trim());
      ServiceLocator().updateMqttRepository(brokerIp.trim());

      final mqttRepo = ServiceLocator().smartWindowRepository;
      final connected = await mqttRepo.connect();

      emit(
        state.copyWith(
          isLoading: false,
          brokerIp: brokerIp.trim(),
          isSuccess: connected,
          statusMessage:
              connected
                  ? 'Підключення успішне! IP адресу збережено.'
                  : 'Не вдалося підключитися до брокера. Перевірте IP адресу.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          statusMessage: 'Помилка: $e',
          isSuccess: false,
        ),
      );
    }
  }
}
