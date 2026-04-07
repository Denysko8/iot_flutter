import 'package:flutter/material.dart';
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/models/user.dart';

class CloudSyncState {
  final String? id;
  final User user;
  final bool isAutoMode;
  final int manualPosition;
  final AutoModeSettings autoSettings;
  final String mqttBrokerIp;
  final Map<String, String> mqttTopics;
  final DateTime updatedAt;
  final bool fromCache;

  const CloudSyncState({
    required this.user,
    required this.isAutoMode,
    required this.manualPosition,
    required this.autoSettings,
    required this.mqttBrokerIp,
    required this.mqttTopics,
    required this.updatedAt,
    this.id,
    this.fromCache = false,
  });

  CloudSyncState copyWith({
    String? id,
    User? user,
    bool? isAutoMode,
    int? manualPosition,
    AutoModeSettings? autoSettings,
    String? mqttBrokerIp,
    Map<String, String>? mqttTopics,
    DateTime? updatedAt,
    bool? fromCache,
  }) {
    return CloudSyncState(
      id: id ?? this.id,
      user: user ?? this.user,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      manualPosition: manualPosition ?? this.manualPosition,
      autoSettings: autoSettings ?? this.autoSettings,
      mqttBrokerIp: mqttBrokerIp ?? this.mqttBrokerIp,
      mqttTopics: mqttTopics ?? this.mqttTopics,
      updatedAt: updatedAt ?? this.updatedAt,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userEmail': user.email,
      'user': user.toMap(),
      'isAutoMode': isAutoMode,
      'manualPosition': manualPosition,
      'autoSettings': _autoSettingsToMap(autoSettings),
      'mqttBrokerIp': mqttBrokerIp,
      'mqttTopics': mqttTopics,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CloudSyncState.fromMap(
    Map<String, dynamic> map, {
    bool fromCache = false,
  }) {
    return CloudSyncState(
      id: map['id']?.toString(),
      user: User.fromMap(Map<String, dynamic>.from(map['user'] as Map)),
      isAutoMode: map['isAutoMode'] as bool? ?? false,
      manualPosition: ((map['manualPosition'] as num?) ?? 50).round().clamp(
        0,
        100,
      ),
      autoSettings: _autoSettingsFromMap(
        Map<String, dynamic>.from(map['autoSettings'] as Map? ?? {}),
      ),
      mqttBrokerIp: map['mqttBrokerIp'] as String? ?? '192.168.0.102',
      mqttTopics: _stringMapFromDynamic(map['mqttTopics']),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      fromCache: fromCache,
    );
  }

  static Map<String, dynamic> _autoSettingsToMap(AutoModeSettings settings) {
    return {
      'wakeBeforeSunrise': settings.wakeBeforeSunrise,
      'wakeAtSunriseTime': settings.wakeAtSunriseTime,
      'wakeTimeHour': settings.wakeTime.hour,
      'wakeTimeMinute': settings.wakeTime.minute,
      'wakeMinutesBefore': settings.wakeMinutesBefore,
      'wakeyOpenPercent': settings.wakeyOpenPercent,
      'temperatureControlEnabled': settings.temperatureControlEnabled,
      'temperatureThreshold': settings.temperatureThreshold,
      'temperatureClosurePercent': settings.temperatureClosurePercent,
      'weatherControlEnabled': settings.weatherControlEnabled,
      'selectedWeathers': settings.selectedWeathers.toList(),
      'weatherClosurePercent': settings.weatherClosurePercent,
    };
  }

  static AutoModeSettings _autoSettingsFromMap(Map<String, dynamic> map) {
    return AutoModeSettings(
      wakeBeforeSunrise: map['wakeBeforeSunrise'] as bool? ?? false,
      wakeAtSunriseTime: map['wakeAtSunriseTime'] as bool? ?? true,
      wakeTime: TimeOfDay(
        hour: (map['wakeTimeHour'] as num? ?? 7).toInt(),
        minute: (map['wakeTimeMinute'] as num? ?? 0).toInt(),
      ),
      wakeMinutesBefore: (map['wakeMinutesBefore'] as num? ?? 0).toInt(),
      wakeyOpenPercent: (map['wakeyOpenPercent'] as num? ?? 100).toDouble(),
      temperatureControlEnabled:
          map['temperatureControlEnabled'] as bool? ?? false,
      temperatureThreshold:
          (map['temperatureThreshold'] as num? ?? 22).toDouble(),
      temperatureClosurePercent:
          (map['temperatureClosurePercent'] as num? ?? 50).toDouble(),
      weatherControlEnabled: map['weatherControlEnabled'] as bool? ?? false,
      selectedWeathers: Set<String>.from(
        (map['selectedWeathers'] as List? ?? []).map((e) => e.toString()),
      ),
      weatherClosurePercent:
          (map['weatherClosurePercent'] as num? ?? 50).toDouble(),
    );
  }

  static Map<String, String> _stringMapFromDynamic(dynamic raw) {
    if (raw is! Map) {
      return <String, String>{};
    }

    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }
}
