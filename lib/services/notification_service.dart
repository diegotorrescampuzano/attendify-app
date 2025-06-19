import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _channelId = 'reminder_channel';
  static const String _channelName = 'Reminders';
  static const String _channelDescription = 'Attendance reminder notifications';
  static const String _prefsKey = 'notifications_enabled';
  static const String _prefsKeyEveryMinute = 'notify_every_minute';

  bool _testEveryMinute = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Configure the local timezone using flutter_timezone
  Future<void> configureLocalTimeZone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[NotificationService] Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('[NotificationService] Error setting timezone: $e');
      tz.initializeTimeZones();
    }
  }

  /// Initialize notifications, timezone, and channels
  Future<void> init() async {
    debugPrint('[NotificationService] Initializing notification service...');
    await configureLocalTimeZone();
    debugPrint('[NotificationService] Timezones initialized');

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NotificationService] Notification tapped: ${response.notificationResponseType}');
      },
    );
    debugPrint('[NotificationService] Plugin initialized');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    debugPrint('[NotificationService] Notification channel created');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    debugPrint('[NotificationService] iOS permissions requested');
  }

  Future<void> loadEveryMinutePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _testEveryMinute = prefs.getBool(_prefsKeyEveryMinute) ?? false;
    debugPrint('[NotificationService] Loaded every minute preference: $_testEveryMinute');
  }

  Future<void> setEveryMinutePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyEveryMinute, value);
    _testEveryMinute = value;
    debugPrint('[NotificationService] Set every minute preference: $_testEveryMinute');
  }

  /// Schedule reminders (hourly or every minute for testing)
  Future<void> scheduleReminders() async {
    debugPrint('[NotificationService] Starting to schedule reminders...');
    await init();
    await loadEveryMinutePreference();

    const String title = 'Recordatorio de Asistencia';
    const String body =
        'Estimad@ Docente, por favor no olvide registrar la asistencia de sus clases';

    if (_testEveryMinute) {
      debugPrint('[NotificationService] Scheduling notifications every minute for current hour...');
      final now = tz.TZDateTime.now(tz.local);
      final utcNow = tz.TZDateTime.now(tz.UTC);
      debugPrint('[NotificationService] Current local time: ${now.hour}:${now.minute}');
      debugPrint('[NotificationService] Current UTC time: ${utcNow.hour}:${utcNow.minute}');

      for (int minute = 0; minute < 60; minute++) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          now.hour,
          minute,
        );
        if (scheduledDate.isAfter(now)) {
          await _scheduleNotification(
            id: minute,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
          );
          debugPrint('[NotificationService] Scheduled notification for ${scheduledDate.hour}:${scheduledDate.minute}');
        } else {
          debugPrint('[NotificationService] Skipping past time: ${scheduledDate.hour}:${scheduledDate.minute}');
        }
      }
    } else {
      debugPrint('[NotificationService] Scheduling hourly notifications from 08:00 to 23:00...');
      for (int hour = 8; hour <= 23; hour++) {
        await _scheduleDailyNotification(
          id: hour * 100,
          title: title,
          body: body,
          hour: hour,
          minute: 0,
        );
        debugPrint('[NotificationService] Scheduled notification for $hour:00');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    debugPrint('[NotificationService] Reminders scheduled. Preference saved.');
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('[NotificationService] Cancelling all scheduled notifications...');
    await flutterLocalNotificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
    debugPrint('[NotificationService] All notifications cancelled. Preference saved.');
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('[NotificationService] Showing test notification: title="$title", body="$body"');
    await flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    debugPrint('[NotificationService] Scheduling notification: id=$id, time=${scheduledDate.hour}:${scheduledDate.minute}, title="$title", body="$body"');
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NotificationService] Notification scheduled successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule notification: $e');
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('[NotificationService] Scheduled time already passed, rescheduling for next day.');
    }

    debugPrint('[NotificationService] Scheduling daily notification: id=$id, time=${scheduledDate.hour}:${scheduledDate.minute}, title="$title", body="$body"');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NotificationService] Daily notification scheduled successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule daily notification: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKey) ?? true;
    debugPrint('[NotificationService] Notifications enabled: $enabled');
    return enabled;
  }
}
