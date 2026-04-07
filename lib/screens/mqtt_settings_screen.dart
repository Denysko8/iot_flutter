// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:iot_flutter/services/service_locator.dart';
import 'package:iot_flutter/widgets/custom_button.dart';
import 'package:iot_flutter/widgets/custom_text_field.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class MqttSettingsScreen extends StatefulWidget {
  const MqttSettingsScreen({super.key});

  @override
  State<MqttSettingsScreen> createState() => _MqttSettingsScreenState();
}

class _MqttSettingsScreenState extends State<MqttSettingsScreen> {
  final _brokerIpController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _brokerIpController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = ServiceLocator().prefs;
    final currentIp = prefs.getString('mqtt_broker_ip') ?? '192.168.0.102';
    _brokerIpController.text = currentIp;
  }

  Future<void> _saveAndTestConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final brokerIp = _brokerIpController.text.trim();

      if (brokerIp.isEmpty) {
        setState(() {
          _statusMessage = 'Будь ласка, введіть IP адресу брокера';
          _isSuccess = false;
          _isLoading = false;
        });
        return;
      }

      // Зберегти нову адресу
      await ServiceLocator().saveMqttBrokerAddress(brokerIp);

      // Оновити MQTT репозиторій з новою адресою
      ServiceLocator().updateMqttRepository(brokerIp);

      // Спробувати підключитися
      final mqttRepo = ServiceLocator().smartWindowRepository;
      final connected = await mqttRepo.connect();

      setState(() {
        _isSuccess = connected;
        _statusMessage =
            connected
                ? 'Підключення успішне! IP адресу збережено.'
                : 'Не вдалося підключитися до брокера. Перевірте IP адресу.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Помилка: $e';
        _isSuccess = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування MQTT')),
      body: SafeArea(
        child: ResponsivePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.settings_remote,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Налаштування MQTT брокера',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Введіть IP адресу вашого комп\'ютера, на якому запущено MQTT брокер (наприклад, Mosquitto)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _brokerIpController,
                label: 'IP адреса брокера',
                icon: Icons.computer,
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
                hint: '192.168.1.100',
              ),
              const SizedBox(height: 16),
              const Text(
                'Порт: 1883 (за замовчуванням)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        _isSuccess
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _isSuccess
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color:
                            _isSuccess
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color:
                                _isSuccess
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              CustomButton(
                text:
                    _isLoading ? 'Підключення...' : 'Зберегти та підключитися',
                onPressed: _isLoading ? null : _saveAndTestConnection,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Інструкція:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Встановіть MQTT брокер (Mosquitto) на вашому ПК\n'
                '2. Дізнайтеся IP адресу вашого ПК (ipconfig в Windows)\n'
                '3. Переконайтеся, що пристрої в одній мережі\n'
                '4. Введіть IP адресу та натисніть "Зберегти"',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
