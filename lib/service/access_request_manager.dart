import 'dart:developer';

import 'package:flutter/services.dart';

class AccessRequestManager {
  static const MethodChannel _channel = MethodChannel(
    'com.sweat.lock/requests',
  );

  static Future<Map<String, dynamic>?> checkForPendingRequest() async {
    try {
      final result = await _channel.invokeMethod('getPendingRequest');
      log("result from above ::: $result");
      if (result != null) {
        return {
          'timestamp': result['timestamp'] as double,
          'bundleId': result['bundleId'] as String,
          'appName': result['appName'] as String,
          "appToken": result['appToken'] as String,
        };
      }
    } catch (e) {
      print("Error reading request: $e");
    }
    return null;
  }

  static Future<List<dynamic>> pickIOSApps() async {
    final permission = await _channel.invokeMethod("requestPermission");

    if (!permission) {
      log("permission declined");
      return [];
    }

    final result = await _channel.invokeMethod("blockApp");

    log("Selected result :: $result");

    if (result is Map && result.containsKey('blockedTokens')) {
      final List<String> tokens = List<String>.from(result['blockedTokens']);
      print("User blocked ${tokens.length} apps:");
      tokens.forEach(print);
    }
    log("Selected Apps");
    return [];
    // final prefsBox = HiveService.prefsBox;
    // final selected = Set<String>.from(
    //   prefsBox.get('blocked_packages', defaultValue: <String>[]),
    // );
  }
}
