import 'package:flutter/material.dart';

const List<String> goalTypes = [
  '입시',
  '취업',
  '자기개발',
  '시험',
  '운동',
  '식단',
  '취미',
  '기타',
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '목표 유형 설정',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // 폰트 지정
        useMaterial3: false, // Material 2 테마 사용
      ),
      home: const GoalTypeSelectorPage(), // 시작 화면 지정
    );
  }
}

// 목표 유형 선택 화면을 나타내는 StatefulWidget
class GoalTypeSelectorPage extends StatefulWidget {
  const GoalTypeSelectorPage({super.key});

  @override
  State<GoalTypeSelectorPage> createState() => _GoalTypeSelectorPageState();
}

// 화면의 동적 상태(선택된 항목 목록)를 관리하는 State 클래스
class _GoalTypeSelectorPageState extends State<GoalTypeSelectorPage> {
  // 선택된 목표 유형을 저장하는 리스트
  final List<String> _selectedGoals = [];
  // 최대 선택 가능한 개수
  final int _maxSelection = 3;


  // 목표 유형 토글(선택/해제) 핸들러
  void _handleToggle(String goalName) {
    setState(() {
      if (_selectedGoals.contains(goalName)) {         // 이미 선택된 경우: 선택 해제
        _selectedGoals.remove(goalName);
      } else {                                         // 선택되지 않은 경우:
        if (_selectedGoals.length < _maxSelection) {
          // 최대 개수 미만일 때만 추가
          _selectedGoals.add(goalName);
        } else {
          // 최대 개수 초과 시 알림
          _showErrorNotification('최대 3개까지만 선택할 수 있습니다.');
        }
      }
    });
  }

  // 오류 알림 메시지 표시
  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 성공 알림 메시지 표시
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


  // 저장 버튼 클릭 핸들러
  void _handleSave() {
    if (_selectedGoals.isEmpty) {   // 선택된 항목이 하나도 없을 경우 오류 표시
      _showErrorNotification('하나 이상의 목표 유형을 선택해주세요.');
      return;
    }
    final message = '저장되었습니다.';
    debugPrint(message);
    _showSuccessNotification(message); // 성공 메시지 출력

    // 실제 저장 로직은 여기에 구현


  }

  @override
  Widget build(BuildContext context) {
    // 렌더링 시 현재 선택 개수가 최대치에 도달했는지 확인
    final bool isMaxReached = _selectedGoals.length >= _maxSelection;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '목표 유형 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // 그림자 제거
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '최대 3개',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Text(
                '목표 유형을 선택해주세요.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),

            // 목표 유형 목록 (스크롤 가능)
            Expanded( // 남은 공간을 모두 차지하도록 확장
              child: ListView.builder(
                itemCount: goalTypes.length,
                itemBuilder: (context, index) {
                  final goal = goalTypes[index];
                  final bool isSelected = _selectedGoals.contains(goal);

                  return _GoalTypeItem( // 개별 항목 위젯 호출
                    name: goal,
                    isSelected: isSelected,
                    isMaxReached: isMaxReached,
                    onTap: () => _handleToggle(goal), // 탭 시 토글 함수 호출
                  );
                },
              ),
            ),

            // 저장 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
              child: ElevatedButton(
                // 선택된 목표가 있을 때만 버튼 활성화, 없으면 비활성화
                onPressed: _selectedGoals.isNotEmpty ? _handleSave : null,
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 개별 목표 유형 항목을 나타내는 StatelessWidget (재사용을 위한 분리)
class _GoalTypeItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isMaxReached;
  final VoidCallback onTap; // 탭 이벤트 콜백 함수

  const _GoalTypeItem({
    required this.name,
    required this.isSelected,
    required this.isMaxReached,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 터치 이벤트를 감지
      onTap: onTap, // 탭 발생 시 부모 위젯의 _handleToggle 호출
      child: AnimatedContainer( // 상태 변화(선택/해제) 시 부드러운 애니메이션 효과 적용
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // 배경색
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          // 테두리
          border: Border.all(
            color: isSelected ? Colors.blue.shade500 : Colors.grey.shade200,
            width: 2,
          ),
          // 그림자
          boxShadow: isSelected
              ? [ // 선택된 경우: 파란색 계열의 부드러운 그림자
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ]
              : [ // 해제된 경우: 회색 계열의 약한 그림자
            BoxShadow(
              color: Colors.grey.shade100,
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
              ),
            ),
            Icon(
              // 아이콘 변경: 선택 시 채워진 체크박스, 해제 시 윤곽선 체크박스
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              color: isSelected
                  ? Colors.blue.shade500 // 선택 시 파란색
                  : (isMaxReached && !isSelected) // 최대치 도달 + 미선택 항목
                  ? Colors.grey.shade300 // 회색으로 흐리게 (선택 불가능 시각화)
                  : Colors.grey.shade400, // 일반 미선택 시 연한 회색
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}