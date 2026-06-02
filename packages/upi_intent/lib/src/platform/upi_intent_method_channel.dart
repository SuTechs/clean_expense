import 'package:flutter/services.dart';

import '../models/upi_app.dart';
import '../models/upi_response.dart';
import 'upi_intent_platform_interface.dart';

/// Android + iOS method channel implementation
class MethodChannelUpiIntent extends UpiIntentPlatform {
  static const MethodChannel _channel = MethodChannel('upi_intent');

  @override
  Future<List<UpiApp>> getInstalledApps() async {
    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('getInstalledUpiApps');

    if (result == null) return [];

    return result.map((app) {
      final map = Map<String, dynamic>.from(app as Map);
      return UpiApp(
        name: map['name'] as String,
        packageName: map['packageName'] as String,
        icon: map['icon'] != null
            ? Uint8List.fromList(List<int>.from(map['icon'] as List))
            : null,
      );
    }).toList();
  }

  @override
  Future<UpiResponse?> launchUpiApp({
    required String upiUrl,
    required String packageName,
  }) async {
    final String? response = await _channel.invokeMethod<String>(
      'launchUpiApp',
      {'upiUrl': upiUrl, 'packageName': packageName},
    );

    if (response == null || response.isEmpty) return null;
    return UpiResponse.fromResponseString(response);
  }
}
