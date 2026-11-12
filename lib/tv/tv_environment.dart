import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Decides at startup whether the TV UI should run instead of the phone UI.
class TvEnvironment {
  TvEnvironment._();

  static const _forceTv = bool.fromEnvironment('FORCE_TV');
  static const _channel = MethodChannel('com.predidit.kazumi/tv');

  static bool? _cached;

  static Future<bool> isTV() async {
    if (_forceTv) return true;
    final cached = _cached;
    if (cached != null) return cached;
    if (defaultTargetPlatform != TargetPlatform.android) return _cached = false;
    try {
      return _cached = await _channel.invokeMethod<bool>('isTelevision') ?? false;
    } catch (_) {
      return _cached = false;
    }
  }

  /// Clears the cache; [override] pins the result without touching the channel.
  @visibleForTesting
  static void debugReset({bool? override}) => _cached = override;
}
