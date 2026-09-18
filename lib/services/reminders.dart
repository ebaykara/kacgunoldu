import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

/// The operating system's side of reminders. [CardStore] talks to this
/// interface only, so tests run against [NoopReminders] and never touch a
/// platform channel.
abstract class Reminders {
  Future<void> init();

  /// Asks for notification permission; `true` when granted (or not needed).
  Future<bool> requestPermission();

  /// Replaces every pending reminder with [plan].
  Future<void> sync(List<Reminder> plan);

  /// Shows one straight away — the "Test bildirimi" button.
  Future<void> showNow(String title, String body);

  /// The card whose notification launched the app from a closed state.
  Future<String?> launchCardId();

  /// Card ids of notifications tapped while the app was running.
  Stream<String> get taps;
}

class NoopReminders implements Reminders {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(List<Reminder> plan) async {}

  @override
  Future<void> showNow(String title, String body) async {}

  @override
  Future<String?> launchCardId() async => null;

  @override
  Stream<String> get taps => const Stream.empty();
}

const _channelId = 'hatirlatmalar';

class LocalReminders implements Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  var _ready = false;

  @override
  Stream<String> get taps => _taps.stream;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Hatırlatmalar',
      channelDescription: 'Bir kartın sırası geldiğinde haber verir.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_notification',
      styleInformation: BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          // Permission is asked when the person first turns a reminder on,
          // not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id != null && id.isNotEmpty) _taps.add(id);
        },
      );
      _ready = true;
    } catch (e) {
      debugPrint('Bildirimler başlatılamadı: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: false, sound: true) ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sync(List<Reminder> plan) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      for (final r in plan) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          notificationDetails: _details,
          // Inexact: no special "alarms" permission, and a reminder that
          // lands a few minutes late is still a reminder.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: r.cardId,
        );
      }
    } catch (e) {
      debugPrint('Hatırlatmalar planlanamadı: $e');
    }
  }

  @override
  Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(id: 1, title: title, body: body, notificationDetails: _details);
    } catch (e) {
      debugPrint('Bildirim gösterilemedi: $e');
    }
  }

  @override
  Future<String?> launchCardId() async {
    if (!_ready) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final id = details?.notificationResponse?.payload;
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}
    return null;
  }
}
