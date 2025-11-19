import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap//mypages/component/notification_service.dart'; // 알림 서비스 import 추가

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

// 화면의 동적 상태를 관리하는 State 클래스
class _NotificationSettingsPageState extends State<NotificationSettingsPage> {

  // 각 알림 항목의 토글 상태 관리 변수
  bool _majorGoalEnabled = false;       // 큰 목표 알림 ON/OFF
  bool _detailedGoalEnabled = false;    // 세부 목표 알림 ON/OFF
  bool _supportEnabled = false;         // 응원 알림 ON/OFF
  bool _urgeEnabled = false;            // 독촉 알림 ON/OFF
  bool _groupImminentEnabled = false;   // 그룹 목표 임박 알림 ON/OFF

  // 큰 목표 설정 관련 상태 및 옵션
  final List<String> _majorGoalDayOptions = ['당일', '전날'];
  String _majorGoalDay = '당일';

  final List<int> _hourOptions = List.generate(24, (i) => i); // 0시부터 23시까지
  int _majorGoalHour = 9; // 기본값 9시

  // 세부 목표 설정 관련 상태 및 옵션
  final List<String> _detailedGoalTimeOptions = [
    '1분전', '5분전', '10분전', '20분전', '30분전',
    '40분전', '50분전', '1시간전'
  ];
  String _detailedGoalTimeBefore = '10분전';

  // '10분전' -> 10, '1시간전' -> 60 으로 변환함.
  int _parseMinutesBefore(String timeString) {
    if (timeString.contains('시간')) {
      // '1시간전' -> 숫자만 추출 (1) * 60
      String numberStr = timeString.replaceAll(RegExp(r'[^0-9]'), '');
      return int.parse(numberStr) * 60;
    } else {
      // '10분전' -> 숫자만 추출 (10)
      String numberStr = timeString.replaceAll(RegExp(r'[^0-9]'), '');
      return int.parse(numberStr);
    }
  }


  // 알림 메시지 표시
  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  // 일반 알림 설정 항목 위젯
  Widget _buildSimpleNotificationTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged, // 토글 상태 변경 시 호출될 콜백
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        value: value, // 현재 토글 상태
        onChanged: onChanged, // 토글 변경 시 setState를 포함한 로직 실행
        activeColor: Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // 알림 상태에 따른 아이콘 변화
        secondary: value
            ? const Icon(Icons.notifications_active, color: Colors.blue)
            : const Icon(Icons.notifications_off, color: Colors.grey),
      ),
    );
  }

  // 세부 설정이 있는 알림 설정 위젯 (토글 + 추가 설정 영역)
  Widget _buildConfigurableNotificationTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget configWidget,
  }) {
    return Column(
      children: [
        // 토글 스위치 부분
        _buildSimpleNotificationTile(
          title: title,
          value: value,
          onChanged: onChanged,
        ),
        // 세부 설정 부분
        if (value)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // 애니메이션 시간
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: configWidget, // 전달받은 세부 설정 위젯 표시
          ),
      ],
    );
  }

  // 큰 목표 알림의 세부 설정 위젯
  Widget _buildMajorGoalConfig() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('알림 시점:', style: TextStyle(fontWeight: FontWeight.w500)),

        // 당일/전날 Dropdown 선택 Dropdown
        DropdownButton<String>(
          value: _majorGoalDay,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {   // 상태변경
                _majorGoalDay = newValue;
              });
            }
          },
          items: _majorGoalDayOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          underline: Container(),
        ),

        // 시간 선택 (0시 ~ 23시) Dropdown
        DropdownButton<int>(
          value: _majorGoalHour,
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _majorGoalHour = newValue;
              });
            }
          },
          items: _hourOptions.map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('${value}시'),
            );
          }).toList(),
          underline: Container(),
        ),
      ],
    );
  }

  // 세부 목표 알림의 세부 설정 위젯
  Widget _buildDetailedGoalConfig() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('알림 시점:', style: TextStyle(fontWeight: FontWeight.w500)),

        // Dropdown
        DropdownButton<String>(
          value: _detailedGoalTimeBefore,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _detailedGoalTimeBefore = newValue;
              });
            }
          },
          items: _detailedGoalTimeOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          underline: Container(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정',
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard-Regular',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false, // 제목 왼쪽 정렬
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView( // 내용이 넘쳐도 스크롤 가능하도록
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 큰 목표 알림 (세부 설정 포함)
            _buildConfigurableNotificationTile(
              title: '큰 목표 알림',
              value: _majorGoalEnabled,
              onChanged: (bool value) {
                setState(() {
                  _majorGoalEnabled = value; // 상태 토글
                });
              },
              configWidget: _buildMajorGoalConfig(), // 세부 설정 위젯 전달
            ),

            // 세부 목표 알림 (세부 설정 포함)
            _buildConfigurableNotificationTile(
              title: '세부 목표 알림',
              value: _detailedGoalEnabled,
              onChanged: (bool value) {
                setState(() {
                  _detailedGoalEnabled = value; // 상태 토글
                });
              },
              configWidget: _buildDetailedGoalConfig(), // 세부 설정 위젯 전달
            ),

            const SizedBox(height: 8),

            // 응원 알림 (단순 토글)
            _buildSimpleNotificationTile(
              title: '응원 알림',
              value: _supportEnabled,
              onChanged: (bool value) {
                setState(() {
                  _supportEnabled = value;
                });
              },
            ),

            // 독촉 알림 (단순 토글)
            _buildSimpleNotificationTile(
              title: '독촉 알림',
              value: _urgeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _urgeEnabled = value;
                });
              },
            ),

            // 그룹 목표 임박 알림 (단순 토글)
            _buildSimpleNotificationTile(
              title: '그룹 목표 임박 알림',
              value: _groupImminentEnabled,
              onChanged: (bool value) {
                setState(() {
                  _groupImminentEnabled = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // 설정 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async { // async 추가
                  // 저장 로직 및 성공 알림 실행
                  final message = '저장되었습니다.';

                  // 기존 알림 취소 (재설정)
                  final notificationService = NotificationService();
                  await notificationService.cancelNotification(0); // ID 0번: 큰 목표 알림용

                  // 큰 목표 알림 켜짐: 예약
                  if (_majorGoalEnabled) {
                    // 시각 결정
                    int targetHour = _majorGoalHour;

                    await notificationService.scheduleMajorGoalNotification(
                      id: 0, // 고유 ID, 큰 목표 알림 ID: 0
                      title: "큰 목표 알림",
                      body: "$_majorGoalDay ${_majorGoalHour}시에 설정된 알림이 있습니다. 목표를 확인하세요.",
                      hour: targetHour,
                    );
                    debugPrint('알림 예약 완료: ${_majorGoalHour}시');
                  } else {
                    debugPrint('큰 목표 알림 OFF');
                  }


                  //세부 목표 알림 처리 (ID: 1)
                  await notificationService.cancelNotification(1); // 기존 세부 알림 취소


                  if (_detailedGoalEnabled) {
                    // 선택한 시간 문자열을 숫자로 변환 (예: '10분전' -> 10)
                    int minutesBefore = _parseMinutesBefore(_detailedGoalTimeBefore);

                    // 임의로 "오후 2시 00분"을 목표 시간으로 가정(나중에 변경)
                    int targetHour = 14;
                    int targetMinute = 0;

                    await notificationService.scheduleDetailedGoalNotification(
                      id: 1, // 세부목표 ID: 1번
                      title: "세부 목표 알림",
                      body: "목표 시간 $_detailedGoalTimeBefore입니다!",
                      minutesBefore: minutesBefore,
                      goalHour: targetHour,   // 실제 목표 시간 변수
                      goalMinute: targetMinute, // 실제 목표 분 변수
                    );
                    debugPrint('세부 알림 예약: $targetHour시 $targetMinute분의 $minutesBefore분 전');
                  }

                  // 성공 메시지 표시
                  _showSuccessNotification(message);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }



                  /*
                  // 디버그 콘솔에 현재 설정 값 출력
                  debugPrint('큰 목표 알림: $_majorGoalEnabled, 시점: $_majorGoalDay ${_majorGoalHour}시');
                  debugPrint('세부 목표 알림: $_detailedGoalEnabled, 시점: $_detailedGoalTimeBefore');

                  _showSuccessNotification(message); // 성공 알림 함수 호출
                  */


                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
                child: const Text('설정 저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}