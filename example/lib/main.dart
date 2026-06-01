import 'package:flutter/material.dart';
import 'package:flutter_rich_notifications/flutter_rich_notifications.dart';

void main() {
  FlutterRichNotifications.configure(
    const RichNotificationConfig(
      androidChannelId: 'demo_channel',
      androidChannelName: 'Demo Rich Notifications',
      androidChannelDescription:
          'Example notifications from flutter_rich_notifications',
      androidImageHeightDp: 200,
    ),
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_rich_notifications demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _longBody =
      'Hi Manish, your rent payment of ₹12,500 to Krishna Apartments has '
      'been successfully processed via UPI. Transaction ID: INP123456789. '
      'Tap to view receipt and download PDF for your records.';

  static const _imageUrl = 'https://picsum.photos/600/400';

  Future<void> _sendWithImage() async {
    await FlutterRichNotifications.show(
      title: 'Payment Successful',
      body: _longBody,
      imageUrl: _imageUrl,
      screenRoute: '/post_payment_screen',
      payload: const {'transaction_id': 'INP123456789'},
    );
  }

  Future<void> _sendTextOnly() async {
    await FlutterRichNotifications.show(
      title: 'Reminder',
      body: _longBody,
      screenRoute: '/reminders',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_rich_notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _sendWithImage,
              icon: const Icon(Icons.image),
              label: const Text('Send rich notification with image'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _sendTextOnly,
              icon: const Icon(Icons.notifications),
              label: const Text('Send rich notification (text-only)'),
            ),
          ],
        ),
      ),
    );
  }
}
