import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rich_notifications/flutter_rich_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_rich_notifications/channel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = <MethodCall>[];
    FlutterRichNotifications.configure(const RichNotificationConfig());
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('RichNotificationConfig', () {
    test('defaults', () {
      const c = RichNotificationConfig();
      expect(c.androidChannelId, 'rich_notifications_default');
      expect(c.androidChannelName, 'Rich Notifications');
      expect(
        c.androidChannelDescription,
        'Notifications with hero image and full body text',
      );
      expect(c.androidSmallIconResName, isNull);
      expect(c.androidImageHeightDp, 200);
    });

    test('overrides', () {
      const c = RichNotificationConfig(
        androidChannelId: 'id',
        androidChannelName: 'name',
        androidChannelDescription: 'desc',
        androidSmallIconResName: 'ic_stat',
        androidImageHeightDp: 320,
      );
      expect(c.androidChannelId, 'id');
      expect(c.androidChannelName, 'name');
      expect(c.androidChannelDescription, 'desc');
      expect(c.androidSmallIconResName, 'ic_stat');
      expect(c.androidImageHeightDp, 320);
    });
  });

  group('show on Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('sends every field and the default config', () async {
      answer((_) => true);
      final ok = await FlutterRichNotifications.show(
        title: 'Paid',
        body: 'Line one\nLine two',
        imageUrl: 'https://example.com/a.png',
        screenRoute: '/receipt',
        payload: const {'txn': '42'},
      );
      expect(ok, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'show');
      expect(calls.single.arguments, <String, dynamic>{
        'title': 'Paid',
        'body': 'Line one\nLine two',
        'imageUrl': 'https://example.com/a.png',
        'screenRoute': '/receipt',
        'data': {'txn': '42'},
        'channelId': 'rich_notifications_default',
        'channelName': 'Rich Notifications',
        'channelDescription':
            'Notifications with hero image and full body text',
        'smallIconResName': null,
        'imageHeightDp': 200,
      });
    });

    test('optional fields are sent as null / empty', () async {
      answer((_) => true);
      await FlutterRichNotifications.show(title: 't', body: 'b');
      final args = calls.single.arguments as Map;
      expect(args['imageUrl'], isNull);
      expect(args['screenRoute'], isNull);
      expect(args['data'], isEmpty);
    });

    test('configure applies to later calls; latest value wins', () async {
      answer((_) => true);
      FlutterRichNotifications.configure(
        const RichNotificationConfig(androidChannelId: 'first'),
      );
      FlutterRichNotifications.configure(
        const RichNotificationConfig(
          androidChannelId: 'orders',
          androidChannelName: 'Orders',
          androidChannelDescription: 'Order updates',
          androidSmallIconResName: 'ic_stat_notify',
          androidImageHeightDp: 256,
        ),
      );
      await FlutterRichNotifications.show(title: 't', body: 'b');
      final args = calls.single.arguments as Map;
      expect(args['channelId'], 'orders');
      expect(args['channelName'], 'Orders');
      expect(args['channelDescription'], 'Order updates');
      expect(args['smallIconResName'], 'ic_stat_notify');
      expect(args['imageHeightDp'], 256);
    });

    test('returns false when the platform returns false', () async {
      answer((_) => false);
      expect(
        await FlutterRichNotifications.show(title: 't', body: 'b'),
        isFalse,
      );
    });

    test('returns false when the platform returns null', () async {
      answer((_) => null);
      expect(
        await FlutterRichNotifications.show(title: 't', body: 'b'),
        isFalse,
      );
    });

    test('returns false on PlatformException', () async {
      answer((_) => throw PlatformException(code: 'image_failed'));
      expect(
        await FlutterRichNotifications.show(title: 't', body: 'b'),
        isFalse,
      );
    });
  });

  group('show on other platforms', () {
    for (final platform
        in TargetPlatform.values.where((p) => p != TargetPlatform.android)) {
      test('${platform.name}: returns true without a platform call', () async {
        debugDefaultTargetPlatformOverride = platform;
        answer((_) => fail('no platform call expected on ${platform.name}'));
        expect(
          await FlutterRichNotifications.show(title: 't', body: 'b'),
          isTrue,
        );
        expect(calls, isEmpty);
      });
    }
  });
}
