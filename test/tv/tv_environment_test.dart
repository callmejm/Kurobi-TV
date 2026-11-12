import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.predidit.kazumi/tv');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TvEnvironment.debugReset();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
    TvEnvironment.debugReset();
  });

  test('isTV returns true when debug override is true', () async {
    TvEnvironment.debugReset(override: true);
    expect(await TvEnvironment.isTV(), isTrue);
  });

  test(
    'isTV returns false and does not throw when the channel is missing',
    () async {
      expect(await TvEnvironment.isTV(), isFalse);
    },
  );

  test('isTV returns the channel result and caches it', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      expect(call.method, 'isTelevision');
      return true;
    });
    expect(await TvEnvironment.isTV(), isTrue);
    expect(await TvEnvironment.isTV(), isTrue);
    expect(calls, 1);
  });

  test('isTV is false off Android without calling the channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return true;
    });
    expect(await TvEnvironment.isTV(), isFalse);
    expect(calls, 0);
  });
}
