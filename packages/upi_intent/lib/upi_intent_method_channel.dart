import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'upi_intent_platform_interface.dart';

/// An implementation of [UpiIntentPlatform] that uses method channels.
class MethodChannelUpiIntent extends UpiIntentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('upi_intent');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
