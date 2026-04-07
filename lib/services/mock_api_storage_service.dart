// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:iot_flutter/models/auto_mode_settings.dart';
import 'package:iot_flutter/models/cloud_sync_state.dart';
import 'package:iot_flutter/models/user.dart';
import 'package:iot_flutter/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiStorageService {
  final SharedPreferences _prefs;
  final ConnectivityService _connectivityService;
  final http.Client _client;

  static const String _collectionPath = 'window_states';
  static const String _cachePrefix = 'mockapi_cloud_state_';

  MockApiStorageService({
    required SharedPreferences prefs,
    required ConnectivityService connectivityService,
    http.Client? client,
  }) : _prefs = prefs,
       _connectivityService = connectivityService,
       _client = client ?? http.Client();

  String? get _baseUrl {
    final value =
        dotenv.env['MOCKAPI_BASE_URL'] ??
        const String.fromEnvironment('MOCKAPI_BASE_URL');
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool get isConfigured => _baseUrl != null;

  Uri _collectionUri([String suffix = '']) {
    return Uri.parse('${_baseUrl!}/$_collectionPath$suffix');
  }

  String _cacheKey(String email) => '$_cachePrefix$email';

  Future<CloudSyncState?> fetchLatestState(String userEmail) async {
    final canUseRemote =
        isConfigured && await _connectivityService.checkConnection();

    if (canUseRemote) {
      final remote = await _fetchLatestFromRemote(userEmail);
      if (remote != null) {
        await _saveCache(userEmail, remote.toMap());
        return remote;
      }
    }

    return _loadCache(userEmail);
  }

  Future<void> syncState(CloudSyncState state) async {
    await _saveCache(state.user.email, state.toMap());

    if (!isConfigured) {
      print('MockApiStorageService: MOCKAPI_BASE_URL не заданий');
      return;
    }

    final hasConnection = await _connectivityService.checkConnection();
    if (!hasConnection) {
      print(
        'MockApiStorageService: немає інтернету, зберігаємо тільки локально',
      );
      return;
    }

    try {
      final existing = await _findRemoteRecordByEmail(state.user.email);
      if (existing != null) {
        final existingId = existing['id']?.toString();
        if (existingId != null && existingId.isNotEmpty) {
          await _client.put(
            _collectionUri('/$existingId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(state.toMap()),
          );
          return;
        }
      }

      await _client.post(
        _collectionUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(state.toMap()),
      );
    } catch (e) {
      print('MockApiStorageService: помилка syncState - $e');
    }
  }

  Future<void> syncUser(User user) async {
    final cachedState = await fetchLatestState(user.email);
    final state =
        cachedState?.copyWith(
          user: user,
          updatedAt: DateTime.now(),
          fromCache: false,
        ) ??
        CloudSyncState(
          user: user,
          isAutoMode: false,
          manualPosition: 50,
          autoSettings: AutoModeSettings(),
          mqttBrokerIp: _prefs.getString('mqtt_broker_ip') ?? '192.168.0.102',
          mqttTopics: <String, String>{},
          updatedAt: DateTime.now(),
        );

    await syncState(state);
  }

  Future<CloudSyncState?> _fetchLatestFromRemote(String userEmail) async {
    try {
      final uri = _collectionUri(
        '?userEmail=$userEmail&sortBy=updatedAt&order=desc&page=1&limit=1',
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty) {
        final first = Map<String, dynamic>.from(decoded.first as Map);
        return CloudSyncState.fromMap(first);
      }
      return null;
    } catch (e) {
      print('MockApiStorageService: помилка _fetchLatestFromRemote - $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _findRemoteRecordByEmail(
    String userEmail,
  ) async {
    try {
      final uri = _collectionUri('?userEmail=$userEmail&page=1&limit=1');
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(
    String userEmail,
    Map<String, dynamic> payload,
  ) async {
    await _prefs.setString(_cacheKey(userEmail), jsonEncode(payload));
  }

  CloudSyncState? _loadCache(String userEmail) {
    final raw = _prefs.getString(_cacheKey(userEmail));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return CloudSyncState.fromMap(decoded, fromCache: true);
    } catch (e) {
      print('MockApiStorageService: помилка _loadCache - $e');
      return null;
    }
  }
}
