//로컬 푸시 알람 lib/tap/mypages/component/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz; //tz=timezone
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 싱글톤 패턴
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 시간대 초기화 (필수)
    tz.initializeTimeZones();

    // 안드로이드 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // 앱 아이콘 사용

    // iOS 설정
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // 큰 목표 알림 예약 함수 (매일 반복)
  Future<void> scheduleMajorGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour, // 0~23
    bool isYesterday = false, // '전날'인지 판단
  }) async {
    // 현재 날짜 기준으로 알림 시간 설정
    final now = tz.TZDateTime.now(tz.local);

    // 사용자가 설정한 시간 (hour: 00분 00초)
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

    // 만약 설정한 시간이 현재보다 과거라면 내일로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    //알람 매일 울림
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'major_goal_channel', // 채널 ID
          '큰 목표 알림', // 채널 이름
          channelDescription: '큰 목표 수행을 위한 알림입니다.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간에 반복
    );
  }


  // 세부 목표 알림 예약(반복 알림)
  Future<void> scheduleDetailedGoalNotification({
    required int id,
    required String title,
    required String body,
    required int minutesBefore, // 몇 분 전에 알릴지 (예: 10, 30, 60)
    required int goalHour,      // 목표 시간 (예: 14시)
    required int goalMinute,    // 목표 분 (예: 30분)
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // 1. 목표 시간 설정 (오늘 날짜 기준)
    var goalTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        goalHour,
        goalMinute
    );

    //알림 울릴 시간 계산(목표 시간 - n분)
    var scheduledDate = goalTime.subtract(Duration(minutes: minutesBefore));

    //만약 계산된 알림 시간이 이미 지났다면 내일로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'detailed_goal_channel', // 채널 ID 구분
          '세부 목표 알림',
          channelDescription: '세부 목표 수행 임박 알림입니다.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간에 반복
    );
  }



  // 알림 취소 함수
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
