import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 목표 유형 상수 리스트
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

class GoalTypeSelectorPage extends StatefulWidget {
  const GoalTypeSelectorPage({super.key});

  @override
  State<GoalTypeSelectorPage> createState() => _GoalTypeSelectorPageState();
}

class _GoalTypeSelectorPageState extends State<GoalTypeSelectorPage> {
  final supabase = Supabase.instance.client;

  // 선택된 목표 유형을 저장하는 리스트
  final List<String> _selectedGoals = [];
  // 최대 선택 가능한 개수
  final int _maxSelection = 3;
  // 로딩 상태 관리
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserGoalTypes();
  }

  // 기존 저장된 목표 유형 불러오기
  Future<void> _loadUserGoalTypes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('users')
          .select('goal_types')
          .eq('id', user.id)
          .single();

      if (response['goal_types'] != null) {
        setState(() {
          final List<dynamic> loadedData = response['goal_types'];
          _selectedGoals.addAll(loadedData.map((e) => e.toString()));
        });
      }
    } catch (e) {
      debugPrint('데이터 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 목표 유형 저장하기
  Future<void> _saveGoalTypes() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorNotification('로그인이 필요합니다.');
      return;
    }

    if (_selectedGoals.isEmpty) {
      _showErrorNotification('하나 이상의 목표 유형을 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // users 테이블 업데이트
      await supabase.from('users').update({
        'goal_types': _selectedGoals,
      }).eq('id', user.id);

      if (mounted) {
        _showSuccessNotification('성공적으로 저장되었습니다.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('저장 실패: $e');
      if (mounted) {
        _showErrorNotification('저장에 실패했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 목표 유형 토글
  void _handleToggle(String goalName) {
    setState(() {
      if (_selectedGoals.contains(goalName)) {
        _selectedGoals.remove(goalName);
      } else {
        if (_selectedGoals.length < _maxSelection) {
          _selectedGoals.add(goalName);
        } else {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // 뒤로가기 버튼 색상
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

            // 목표 유형 목록
            Expanded(
              child: _isLoading && _selectedGoals.isEmpty
                  ? const Center(child: CircularProgressIndicator()) // 초기 로딩 중일 때
                  : ListView.builder(
                itemCount: goalTypes.length,
                itemBuilder: (context, index) {
                  final goal = goalTypes[index];
                  final bool isSelected = _selectedGoals.contains(goal);

                  return _GoalTypeItem(
                    name: goal,
                    isSelected: isSelected,
                    isMaxReached: isMaxReached,
                    onTap: () => _handleToggle(goal),
                  );
                },
              ),
            ),

            // 저장 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedGoals.isEmpty)
                    ? null
                    : _saveGoalTypes,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  disabledBackgroundColor: Colors.grey.shade300, // 비활성화 색상
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  '저장',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalTypeItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isMaxReached;
  final VoidCallback onTap;

  const _GoalTypeItem({
    super.key,
    required this.name,
    required this.isSelected,
    required this.isMaxReached,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade500 : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ]
              : [
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
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              color: isSelected
                  ? Colors.blue.shade500
                  : (isMaxReached && !isSelected)
                  ? Colors.grey.shade300
                  : Colors.grey.shade400,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}