import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_it/get_it.dart';
import 'package:gym_tracker/common/routes/route_args.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const String _activeWorkoutRoute = '/active-workout';
const int kWorkoutInProgressId = 1;
const int kRestTimerEndId = 2;

const String _restEndedText = 'Rest Time ended! Back to Lift!!';
const String _restChannelId = 'rest_timer';
const String _restChannelName = 'Rest Timer';
const String _workoutChannelId = 'workout_in_progress';
const String _workoutChannelName = 'Workout';

/// Local notifications for workout + rest timer. Countdown stays in-app; OS only fires at scheduled time.
class NotificationService {
  NotificationService();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        tzdata.initializeTimeZones();
        try {
          final timeZoneName = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(timeZoneName));
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
        }
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      await _ensureAndroidRestChannel();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _ensureAndroidRestChannel() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _restChannelId,
        _restChannelName,
        description: 'Rest complete alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _workoutChannelId,
        _workoutChannelName,
        description: 'Workout in progress',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('active_workout:')) return;
    final workoutId = payload.substring('active_workout:'.length);
    if (workoutId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(
        _activeWorkoutRoute,
        arguments: ActiveWorkoutRouteArgs(workoutId: workoutId),
      );
    });
  }

  Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> showWorkoutInProgress({
    required String workoutId,
    required String routineName,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    required String elapsed,
  }) async {
    if (!_initialized) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final android = AndroidNotificationDetails(
      _workoutChannelId,
      _workoutChannelName,
      channelDescription: 'Workout in progress',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );
    final details = NotificationDetails(android: android, iOS: ios);

    await _plugin.show(
      kWorkoutInProgressId,
      '🏋️ $routineName — In Progress',
      '$exerciseName · Set $setNumber of $totalSets  |  $elapsed elapsed',
      details,
      payload: 'active_workout:$workoutId',
    );
  }

  Future<void> scheduleRestEnd({
    required String workoutId,
    required int restSeconds,
    required String nextExercise,
    required int nextSet,
  }) async {
    if (!_initialized) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (restSeconds <= 0) {
      await cancelRestEnd();
      return;
    }

    await cancelRestEnd();

    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: restSeconds));
    const android = AndroidNotificationDetails(
      _restChannelId,
      _restChannelName,
      channelDescription: 'Rest complete',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: android, iOS: ios);

    await _plugin.zonedSchedule(
      kRestTimerEndId,
      _restEndedText,
      null,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'active_workout:$workoutId',
    );
  }

  Future<void> showRestEnded({required String workoutId}) async {
    if (!_initialized) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    const android = AndroidNotificationDetails(
      _restChannelId,
      _restChannelName,
      channelDescription: 'Rest complete',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    await _plugin.show(
      kRestTimerEndId,
      _restEndedText,
      null,
      details,
      payload: 'active_workout:$workoutId',
    );
  }

  Future<void> cancelRestEnd() async {
    await _plugin.cancel(kRestTimerEndId);
  }

  Future<void> cancelWorkoutInProgress() async {
    await _plugin.cancel(kWorkoutInProgressId);
  }

  Future<void> cancelAllWorkoutNotifications() async {
    await cancelRestEnd();
    await cancelWorkoutInProgress();
  }
}

Future<void> cancelWorkoutNotificationsFromGetIt() async {
  final g = GetIt.instance;
  if (g.isRegistered<NotificationService>()) {
    await g<NotificationService>().cancelAllWorkoutNotifications();
  }
}
