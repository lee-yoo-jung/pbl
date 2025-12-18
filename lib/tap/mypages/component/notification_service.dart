import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pbl/tap/calender/component/event.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pbl/services/supabase_calendar_service.dart';

class NotificationService {
  // 싱글톤 패턴
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false; // 초기화 상태 확인 플래그

  final CalendarService _calendarService = CalendarService();

  Future<void> init() async {
    if (_isInitialized) return;

    // 시간대 초기화
    tz.initializeTimeZones();

    // 안드로이드 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

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

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("알림 클릭됨: ${details.payload}");
      },
    );

    // 알림 권한 요청
    var status = await Permission.notification.request();
    debugPrint('알림 권한 상태: $status');

    _isInitialized = true; // 초기화 완료 표시
    debugPrint('NotificationService 초기화 완료');
  }

  // 알림 스위치 ON/OFF 관리 함수
  Future<void> setNotificationEnabled(bool isEnabled) async {
    if (!_isInitialized) {
      debugPrint('알림 서비스가 초기화되지 않아 초기화를 시도합니다.');
      await init();
    }

    // 기존 알림 모두 취소
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('기존 알림 모두 취소됨 (재설정을 위해)');
    } catch (e) {
      debugPrint('알림 취소 중 에러 발생: $e');
      debugPrint('플러그인 재초기화 후 다시 시도합니다...');

      await init();
      try {
        await flutterLocalNotificationsPlugin.cancelAll();
        debugPrint('재시도 성공: 알림 취소 완료');
      } catch (e2) {
        debugPrint('재시도 실패: $e2');
        return;
      }
    }

    // 스위치가 ON이면, 일정들을 불러와서 예약
    if (isEnabled) {
      try {
        debugPrint('DB에서 목표 불러오는 중...');

        // 필요한 시점에 서비스 생성
        final calendarService = CalendarService();
        List<Event> dbEvents = await calendarService.getGoals();

        if (dbEvents.isNotEmpty) {
          await _scheduleAllCalendarEvents(dbEvents);
          debugPrint('${dbEvents.length}개의 목표에 대한 알림 예약 완료');
        } else {
          debugPrint('예약할 목표가 DB에 없습니다.');
        }
      } catch (e) {
        debugPrint('알림 예약 중 오류 발생: $e');
      }
    }
  }

  // 내부 함수: 리스트에 있는 모든 이벤트를 예약
  Future<void> _scheduleAllCalendarEvents(List<Event> events) async {
    final now = tz.TZDateTime.now(tz.local);
    int scheduledCount = 0;

    for (var event in events) {
      if (event.id == null) continue;

      try {
        tz.TZDateTime scheduledDate = tz.TZDateTime.from(
          event.startDate,
          tz.local,
        );

        // 현재 시간보다 미래인지 확인
        if (scheduledDate.isAfter(now)) {
          int notificationId = event.id.hashCode;

          await scheduleNotification(
            id: notificationId,
            title: "목표 알림: ${event.title}",
            body: "${event.title} 목표가 예정되어 있습니다. 파이팅!",
            scheduledDate: scheduledDate,
          );
          scheduledCount++;
        }
      } catch (e) {
        debugPrint('개별 일정 예약 실패 (${event.title}): $e');
      }
    }
    debugPrint('총 $scheduledCount 개의 미래 일정이 예약되었습니다.');
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
          'calendar_event_channel',
          '목표 일정 알림',
          channelDescription: '목표 시작일에 맞춰 알림을 보냅니다.',
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