import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late Duration selectedTime;

  late Timer _timer;
  bool _isRunning = false;

  Duration _duration = const Duration();

  @override
  void initState() {
    super.initState();

    selectedTime = const Duration(
      hours: 0,
      minutes: 1,
    );

    setupLocationNotification();

    tz.initializeTimeZones();

    // TODO: implement initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local notifications"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              displayNotification();
            },
            child: const Text("Show Notification"),
          ),
          CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: selectedTime,
            onTimerDurationChanged: (Duration newTime) {
              setState(() {
                selectedTime = newTime;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              _duration = selectedTime;
              // setState(() {});
              // _isRunning ? _stopTimer : _startTimer;
              displayScheduledNotification();
            },
            child: const Text("Show scheduled Notification"),
          ),
          const SizedBox(
            height: 10,
          ),
          if (_isRunning)
            Center(
              child: Text(
                "Notification arrives in: ${_formatDuration(_duration)}",
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),

          // ElevatedButton(
          //   onPressed: _isRunning ? _stopTimer : _startTimer,
          //   child: Text(_isRunning ? 'Stop Timer' : 'Start Timer'),
          // ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = Duration(seconds: _duration.inSeconds - 1);
      });
      if (_duration == const Duration(seconds: 0)) {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer.cancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  setupLocationNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (response) {
      log(response.toString());
    });

    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    if (Platform.isAndroid) {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();
    }
  }

  void displayNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'high_importance',
      'High Importance',
      channelDescription: 'This is high important notification',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      'plain title',
      'plain body',
      notificationDetails,
      payload: 'item x',
    );
  }

  void displayScheduledNotification() async {
    _startTimer();
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Scheduled Notification',
      'This is the body of the notification',
      tz.TZDateTime.now(tz.local).add(selectedTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance',
          'High Importance',
          channelDescription: 'This is a high importance notification',
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Duration calculateDurationWithSeconds(DateTime selectedDateTime) {
    // Get the current date and time
    final now = DateTime.now();

    // Calculate the difference as a Duration
    return selectedDateTime.difference(now);
  }
}
