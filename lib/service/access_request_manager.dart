import 'package:flutter/services.dart';

class AccessRequestManager {
  static const MethodChannel _channel = MethodChannel('com.sweat.lock/requests');

  static Future<Map<String, dynamic>?> checkForPendingRequest() async {
    try {
      final result = await _channel.invokeMethod('getPendingRequest');
      if (result != null) {
        return {
          'timestamp': result['timestamp'] as double,
          'appId': result['appId'] as String,
        };
      }
    } catch (e) {
      print("Error reading request: $e");
    }
    return null;
  }
}