import 'package:flutter/material.dart';
import 'package:mypage/conponent/GoalTypeSetting.dart';
import 'package:mypage/conponent/NotificationSetting.dart';
import 'package:mypage/conponent/PwChange.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _isProfilePublic = true; // 프로필 공개 여부 상태

  // 로그아웃 또는 탈퇴 시 팝업을 표시하는 함수
  void _showConfirmationDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
            ),
            TextButton(
              // 실제 로직을 위해 색상을 다르게 줄 수 있음
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(title),
              onPressed: () {
                // 여기에 실제 로그아웃 또는 탈퇴 로직을 추가
                print('$title 실행');
                Navigator.of(context).pop(); // 팝업 닫기
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 전체의 배경색을 이미지와 유사하게 설정
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: const Icon(Icons.person, size: 30),
        title: const Text('마이페이지'),
        backgroundColor: Colors.blue, // 이미지의 상단 바 색상
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // --- 1. 프로필 정보 섹션 ---
          _buildProfileSection(),
          const SizedBox(height: 12),

          // --- 2. 완료한 목표 섹션 ---
          _buildCompletedGoalsSection(),
          const SizedBox(height: 12),

          // --- 3. 설정 및 기타 섹션 ---
          _buildSettingsSection(),
        ],
      ),
    );
  }

  // 1. 프로필 정보 위젯
  Widget _buildProfileSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름, 목표 유형, 편집 버튼
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('내이름', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildGoalTypeChip('목표 유형'),
              const SizedBox(width: 4),
              _buildGoalTypeChip('목표 유형'),
              const Spacer(),
              TextButton(
                onPressed: () { /* 편집 화면으로 이동 */ },
                child: const Text('편집', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 등급, 경험치, 진행중인 목표
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 등급 이미지 (실제 이미지 경로로 수정 필요)
              Image.asset('assets/images/badge.png', width: 80, height: 80),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('다이아', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('EXP: 412/500', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 412 / 500,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('진행중인 목표', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildGoalItem('체중 5kg 감량하기'),
                    _buildGoalItem('토익 900점 이상 받기'),
                    _buildGoalItem('PBL A+ 받기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. 완료한 목표 위젯
  Widget _buildCompletedGoalsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('완료한 목표', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () { /* 더보기 화면으로 이동 */ },
                child: const Text('더보기', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          _buildGoalItem('체중 10kg 감량하기'),
          _buildGoalItem('토익 900점 이상 받기'),
          _buildGoalItem('PBL A+ 받기'),
          const Divider(height: 20),
          // 목표 데이터 분석
          InkWell(
            onTap: () { /* 목표 데이터 분석 화면으로 이동 */ },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('목표 데이터 분석', style: TextStyle(fontSize: 15)),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 3. 설정 및 기타 위젯
  Widget _buildSettingsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아이디', style: TextStyle(fontSize: 16, color: Colors.grey)), // 수정 불가능한 아이디
          const SizedBox(height: 10),
          _buildSettingsItem(
            text: '비밀번호 변경',
            onTap: () { /* 비밀번호 변경 화면으로 이동 */
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordChangePage()),
              );},
          ),
          _buildSettingsItem(
            text: '프로필 공개',
            trailing: Switch(
              value: _isProfilePublic,
              onChanged: (value) {
                setState(() {
                  _isProfilePublic = value;
                });
              },
            ),
            onTap: null, // Switch가 있으므로 Row 전체의 onTap은 비활성화
          ),
          _buildSettingsItem(
            text: '목표 유형 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
          ),
          _buildSettingsItem(
            text: '알림 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Notification1()),
              );
            },
          ),
          const Divider(height: 20),
          _buildSettingsItem(
            text: '로그아웃',
            textColor: Colors.red,
            onTap: () => _showConfirmationDialog('로그아웃', '로그아웃 하시겠습니까?'),
          ),
          _buildSettingsItem(
            text: '탈퇴',
            textColor: Colors.red,
            onTap: () => _showConfirmationDialog('탈퇴', '정말로 탈퇴 하시겠습니까?'),
          ),
        ],
      ),
    );
  }

  // --- 보조 위젯들 (재사용을 위해 분리) ---

  // 각 섹션의 기본 컨테이너 스타일
  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: child,
    );
  }

  // 목표 유형 칩 스타일
  Widget _buildGoalTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  // 목표 리스트 아이템 스타일
  Widget _buildGoalItem(String goal) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Text('•', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Text(goal, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  // 설정 메뉴 아이템 스타일
  Widget _buildSettingsItem({
    required String text,
    required VoidCallback? onTap,
    Widget? trailing,
    Color textColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(fontSize: 16, color: textColor)),
            trailing ?? Container(), // trailing 위젯이 없으면 빈 컨테이너
          ],
        ),
      ),
    );
  }
}
