import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'upi_intent_method_channel.dart';

abstract class UpiIntentPlatform extends PlatformInterface {
  /// Constructs a UpiIntentPlatform.
  UpiIntentPlatform() : super(token: _token);

  static final Object _token = Object();

  static UpiIntentPlatform _instance = MethodChannelUpiIntent();

  /// The default instance of [UpiIntentPlatform] to use.
  ///
  /// Defaults to [MethodChannelUpiIntent].
  static UpiIntentPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UpiIntentPlatform] when
  /// they register themselves.
  static set instance(UpiIntentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
