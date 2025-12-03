//로컬 푸시 알람 lib/tap/mypages/component/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz; //tz=timezone
import 'package:timezone/timezone.dart' as tz;
import 'package:pbl/tap/calender/component/event.dart';
import 'package:flutter/foundation.dart'; // debugPrint용
import 'package:permission_handler/permission_handler.dart';
import 'package:pbl/services/supabase_calendar_service.dart';

class NotificationService {
// 싱글톤 패턴
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final CalendarService _calendarService = CalendarService();

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
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("알림 클릭됨: ${details.payload}");
      },
    );

    var status = await Permission.notification.request();
    debugPrint('Android 알림 권한 상태: $status');
  }

// [통합] 알림 스위치 ON/OFF 관리 함수
  Future<void> setNotificationEnabled(bool isEnabled) async {
// 1. 기존 알림 모두 취소 (OFF 상태이거나, 목록 갱신을 위해 초기화)
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('모든 알림 취소됨');

// 2. 스위치가 ON이면, eventsList의 일정들을 예약
    if (isEnabled) {
      try {
        // DB에서 최신 목표 리스트 가져오기
        List<Event> dbEvents = await _calendarService.getGoals();

        if (dbEvents.isNotEmpty) {
          await _scheduleAllCalendarEvents(dbEvents);
        } else {
          debugPrint('예약할 목표가 DB에 없습니다.');
        }
      } catch (e) {
        debugPrint('알림 예약 중 데이터 로드 실패: $e');
      }
    }
  }

// 내부 함수: 리스트에 있는 모든 이벤트를 예약
    Future<void> _scheduleAllCalendarEvents(List<Event> events) async {
      final now = tz.TZDateTime.now(tz.local);
      int scheduledCount = 0;

      for (var event in events) {
        // startDate를 Timezone 인식 시간으로 변환
        tz.TZDateTime scheduledDate = tz.TZDateTime.from(
            event.startDate,
            tz.local
        );

// [핵심] 현재 시간보다 미래에 있는 일정만 알림 예약
        if (scheduledDate.isAfter(now)) {
          int notificationId = event.id.hashCode;

          await scheduleNotification(
            id: notificationId,
            title: "일정 알림: ${event.title}",
            body: "${event.title} 일정이 있습니다.",
            scheduledDate: scheduledDate,
          );
          scheduledCount++;
        }
      }
      debugPrint('총 $scheduledCount 개의 미래 일정이 알림 예약되었습니다.');
    }

// 실제 알림 예약 실행 함수
    Future<void> scheduleNotification({
      required int id,
      required String title,
      required String body,
      required tz.TZDateTime scheduledDate,
    }) async {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'calendar_event_channel', // 채널 ID
            '일정 알림', // 채널 이름
            channelDescription: '캘린더 일정에 맞춘 알림입니다.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }