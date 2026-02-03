import 'dart:io';

import 'package:flutter/services.dart';

class MultipeerBridge {
  static const MethodChannel _channel =
      MethodChannel('cleanquest/multipeer');

  static Future<void> startAdvertiser({
    required String householdId,
    required String hostUserId,
    String? displayName,
    String? householdName,
  }) async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod<void>('startAdvertiser', <String, dynamic>{
      'householdId': householdId,
      'hostUserId': hostUserId,
      if (displayName != null && displayName.trim().isNotEmpty)
        'displayName': displayName.trim(),
      if (householdName != null && householdName.trim().isNotEmpty)
        'householdName': householdName.trim(),
    });
  }

  static Future<void> stopAdvertiser() async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod<void>('stopAdvertiser');
  }

  static Future<List<Map<String, String>>> browseNearby({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!Platform.isIOS) {
      return [];
    }
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'browseNearby',
      <String, dynamic>{
        'timeoutMs': timeout.inMilliseconds,
      },
    );
    if (raw == null) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map((entry) => entry.map(
              (key, value) =>
                  MapEntry(key.toString(), value?.toString() ?? ''),
            ))
        .toList();
  }
}
