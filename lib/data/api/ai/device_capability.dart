import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Gates the AI feature on devices that can actually run a ~0.6B model.
class DeviceCapability {
  DeviceCapability._();

  static const _minRamMb = 3000;

  /// Physical RAM in MB, or null when it can't be determined.
  /// Used to hide model tiers a device can't run.
  static Future<int?> physicalRamMb() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        return (await plugin.androidInfo).physicalRamSize;
      }
      if (Platform.isIOS) {
        return (await plugin.iosInfo).physicalRamSize;
      }
    } catch (e) {
      debugPrint('DeviceCapability.physicalRamMb failed: $e');
    }
    return null;
  }

  /// Returns a human-readable reason the device can't run on-device AI,
  /// or null when it can. Errs on the side of allowing (an honest failure
  /// at load beats blocking a capable device).
  static Future<String?> unsupportedReason() async {
    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        if (!info.supportedAbis.contains('arm64-v8a')) {
          return 'This device has a 32-bit processor. On-device AI needs '
              'a 64-bit (arm64) device.';
        }
        if (info.physicalRamSize < _minRamMb) {
          return 'This device has less than 3 GB of RAM, which is not '
              'enough to run the AI model.';
        }
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final major = int.tryParse(info.systemVersion.split('.').first) ?? 0;
        if (major < 16) {
          return 'On-device AI needs iOS 16 or newer.';
        }
        if (info.physicalRamSize < _minRamMb) {
          return 'This device does not have enough RAM to run the AI model.';
        }
      }
      return null;
    } catch (e) {
      debugPrint('DeviceCapability check failed: $e');
      return null;
    }
  }
}
