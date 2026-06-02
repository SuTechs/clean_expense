import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/upi_app.dart';
import '../models/upi_response.dart';

/// Platform interface for upi_intent plugin
abstract class UpiIntentPlatform extends PlatformInterface {
  UpiIntentPlatform() : super(token: _token);

  static final Object _token = Object();
  static UpiIntentPlatform _instance = _UpiIntentPlatformDefault();

  static UpiIntentPlatform get instance => _instance;

  static set instance(UpiIntentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns list of UPI apps installed on the device
  Future<List<UpiApp>> getInstalledApps() {
    throw UnimplementedError('getInstalledApps() not implemented.');
  }

  /// Launches a UPI app with the given URL and returns transaction response
  Future<UpiResponse?> launchUpiApp({
    required String upiUrl,
    required String packageName,
  }) {
    throw UnimplementedError('launchUpiApp() not implemented.');
  }
}

class _UpiIntentPlatformDefault extends UpiIntentPlatform {}
