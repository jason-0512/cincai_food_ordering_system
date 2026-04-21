import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Notification text
const String _paymentSuccessTitle = '🎉 Payment Received!';
const String _paymentSuccessBody  =
    'Payment made, the kitchen will be preparing your order now.';

class NotifService {
  NotifService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static final Map<int, RealtimeChannel> _paymentChannels = {};
  static int _notifId = 0;

  // ── Step 1: Call this in main() before runApp ─────────────────
  // Only sets up the channel + plugin — no permission dialog, never blocks.
  static Future<void> init() async {
    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'payment_status',
      'Payment Status',
      description: 'Notifies you when your payment is confirmed',
      importance:  Importance.high,
      playSound:   true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialise the plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        // Don't request iOS permissions here — use requestPermission() below
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotifTap,
    );
  }

  // ── Step 2: Call this once the app is visible ─────────────────
  // Shows the Allow / Deny dialog to the user.
  // Call from Home's initState:
  //   WidgetsBinding.instance.addPostFrameCallback((_) => NotifService.requestPermission());
  static Future<void> requestPermission() async {
    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> watchPayment(int orderId) async {
    if (_paymentChannels.containsKey(orderId)) return;

    final row = await Supabase.instance.client
        .from('payment')
        .select('payment_id')
        .eq('order_id', orderId)
        .maybeSingle();

    if (row == null) {
      debugPrint('[NotifService] No payment row for order #$orderId — skipped');
      return;
    }

    _subscribeToPayment(
      orderId:   orderId,
      paymentId: row['payment_id'] as int,
    );
  }

  static void _subscribeToPayment({
    required int orderId,
    required int paymentId,
  }) {
    final channel = Supabase.instance.client
        .channel('notif_payment_$paymentId')
        .onPostgresChanges(
      event:  PostgresChangeEvent.update,
      schema: 'public',
      table:  'payment',
      filter: PostgresChangeFilter(
        type:   PostgresChangeFilterType.eq,
        column: 'payment_id',
        value:  paymentId,
      ),
      callback: (payload) {
        final newStatus = payload.newRecord['status'] as String?;
        debugPrint('[NotifService] Payment #$paymentId → "$newStatus"');
        if (newStatus == 'success') {
          _showPaymentSuccessNotification(orderId);
          unwatchPayment(orderId);
        }
      },
    )
        .subscribe();

    _paymentChannels[orderId] = channel;
    debugPrint('[NotifService] Watching payment #$paymentId for order #$orderId');
  }

  static Future<void> unwatchPayment(int orderId) async {
    final ch = _paymentChannels.remove(orderId);
    if (ch != null) {
      await Supabase.instance.client.removeChannel(ch);
      debugPrint('[NotifService] Stopped watching payment for order #$orderId');
    }
  }

  static Future<void> unwatchAll() async {
    for (final ch in _paymentChannels.values) {
      await Supabase.instance.client.removeChannel(ch);
    }
    _paymentChannels.clear();
    debugPrint('[NotifService] All payment watches removed');
  }

  static Future<void> showTest() async {
    await _showPaymentSuccessNotification(0);
  }

  static Future<void> _showPaymentSuccessNotification(int orderId) async {
    final body = orderId > 0
        ? '$_paymentSuccessBody (Order #$orderId)'
        : _paymentSuccessBody;

    await _plugin.show(
      id:    _notifId++,
      title: _paymentSuccessTitle,
      body:  body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_status',
          'Payment Status',
          channelDescription: 'Payment notifications',
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'payment_$orderId',
    );
    debugPrint('[NotifService] Notification shown for order #$orderId');
  }

  static void _onNotifTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    debugPrint('[NotifService] Notification tapped: $payload');
  }
}