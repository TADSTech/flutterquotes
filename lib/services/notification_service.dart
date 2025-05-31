import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterquotes/quote_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutterquotes/services/http_service.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const _notificationChannelId = 'daily_quotes_channel';
  static const _notificationChannelName = 'FlutterQuotes';
  static const _backgroundTaskName = 'fetchDailyQuote';
  static const _alarmId = 0;

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      await _requestNotificationPermissions();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      await _notificationsPlugin.initialize(
        InitializationSettings(android: initializationSettingsAndroid),
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      await _setupNotificationChannel();
      await _scheduleDailyNotifications();
      await _setupBackgroundFetch();
    } catch (e) {
      _logError('Initialization failed', e);
    }
  }

  static Future<void> _requestNotificationPermissions() async {
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        throw Exception('Notification permission not granted');
      }
    } catch (e) {
      _logError('Permission request failed', e);
    }
  }

  static Future<void> _setupNotificationChannel() async {
    final androidChannel = const AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Inspirational quotes delivered daily',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  static Future<void> _scheduleDailyNotifications() async {
    try {
      // Cancel any existing alarms
      await AndroidAlarmManager.cancel(_alarmId);

      // Schedule for 5 times a day (every 4.8 hours)
      await AndroidAlarmManager.periodic(
        const Duration(hours: 4, minutes: 48),
        _alarmId,
        showDailyQuoteNotification,
        startAt: _nextScheduledTime(),
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } catch (e) {
      _logError('Notification scheduling failed', e);
    }
  }

  static DateTime _nextScheduledTime() {
    final now = DateTime.now();
    final nextTime = now.add(const Duration(minutes: 10)); // First in 10 mins
    return nextTime;
  }

  static Future<void> _setupBackgroundFetch() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      await Workmanager().registerPeriodicTask(
        _backgroundTaskName,
        _backgroundTaskName,
        frequency: const Duration(hours: 4, minutes: 48),
        initialDelay: const Duration(minutes: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      _logError('Background fetch setup failed', e);
    }
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        await showDailyQuoteNotification();
        return true;
      } catch (e) {
        return false;
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> showDailyQuoteNotification() async {
    try {
      final quote = await _fetchQuote();
      if (quote != null) {
        await _showNotification(quote);
      }
    } catch (e) {
      _logError('Notification display failed', e);
    }
  }

  static Future<Quote?> _fetchQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quoteProvider = QuoteProvider(prefs);
      await quoteProvider.fetchQuote();
      return quoteProvider.currentQuote;
    } catch (e) {
      _logError('Quote fetch failed', e);
      return null;
    }
  }

  static Future<void> _showNotification(Quote quote) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        channelDescription: 'Inspirational quotes delivered daily',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      await _notificationsPlugin.show(
        0,
        'Daily Inspiration',
        quote.text,
        const NotificationDetails(android: androidDetails),
        payload: jsonEncode(quote.toJson()),
      );
    } catch (e) {
      _logError('Notification display failed', e);
    }
  }

  static void _handleNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final quote = Quote.fromJson(jsonDecode(response.payload!));
        //TODO:  Handle quote tap (e.g., navigate to quote detail)
      }
    } catch (e) {
      _logError('Notification tap handling failed', e);
    }
  }

  static void _logError(String message, dynamic error) {
    //TODO: Implement error logging here (e.g., Sentry, Firebase Crashlytics)
    debugPrint('$message: $error');
  }

  // For testing purposes
  static Future<void> triggerTestNotification() async {
    try {
      final quote = await _fetchQuote();
      if (quote != null) {
        await _showNotification(quote);
      }
    } catch (e) {
      _logError('Test notification failed', e);
    }
  }
}
