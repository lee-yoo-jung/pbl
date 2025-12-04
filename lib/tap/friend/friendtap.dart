//friendtap.dart 친구 탭
import 'package:pbl/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:pbl/tap/friend/friendsearch.dart';
import 'package:pbl/tap/friend/FriendCalender/Friend_calenderview.dart';

// 친구 데이터 모델 정의
class Friend {
  final String nickname;
  final List<String> goalTypes;
  final int grade; // 1부터 5
  bool isFriend; // 현재 친구인지 여부 (친구 목록이므로 모두 true여야 함)
  final List<String> sharedGoals; // 공동 목표 목록

  Friend({
    required this.nickname,
    required this.goalTypes,
    required this.grade,
    required this.isFriend,
    required this.sharedGoals,
  });
}


// 가상 친구 목록 데이터 (Mock Data)
final List<Friend> mockFriendsList = [
  Friend(
    nickname: '친구1',
    goalTypes: ['입시', '시험'],
    grade: 4,
    isFriend: true,
    sharedGoals: ['체중 10kg 감량하기'],
  ),
  Friend(
    nickname: '친구2',
    goalTypes: ['운동', '식단', '취미'],
    grade: 5,
    isFriend: true,
    sharedGoals: ['토익 900점 이상 받기', 'PBL A+ 받기', '여행'],
  ),
  Friend(
    nickname: '친구3',
    goalTypes: ['취업'],
    grade: 2,
    isFriend: true,
    sharedGoals: [], // 공동 목표 없음
  ),
  Friend(
    nickname: '친구4',
    goalTypes: ['자기개발', '취미', '기타'],
    grade: 1,
    isFriend: true,
    sharedGoals: ['대전여행', '중간고사'],
  ),
];


// 친구 목록 페이지 위젯 (FriendsListPage)
class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: const Icon(Icons.group, size: 30),
        title: const Text('친구',
          style: TextStyle(
          color: PRIMARY_COLOR,
          fontSize: 20,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w800,
        ),),
        toolbarHeight:40,
        backgroundColor: Colors.white, // 이미지의 상단 바 색상
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // '친구 목록' 제목과 '친구추가' 버튼이 배치된 영역
          Container(
            color: Colors.white, // 흰색 배경
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 12.0),
            child: Row(
              children: [
                // 왼쪽: '친구 목록' 제목
                const Text(
                  '친구 목록',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard-',
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(), // 오른쪽 버튼을 끝까지 밀어냄
                // 오른쪽:  '친구추가' 버튼
                TextButton(
                  onPressed: () {
                    debugPrint('친구추가 버튼 클릭됨');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FriendSearchScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        '친구추가',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                        color: Colors.black54),
                      ),
                      Icon(Icons.keyboard_arrow_right)
                    ],
                  )
                ),
              ],
            ),
          ),
          // 친구 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              itemCount: mockFriendsList.length,
              itemBuilder: (context, index) {
                return _FriendListCard(friend: mockFriendsList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}


// 친구 목록 항목 카드 위젯
class _FriendListCard extends StatelessWidget {
  final Friend friend;
  const _FriendListCard({required this.friend});

  // 목표 유형 칩 스타일
  Widget _buildGoalTypeChip(String type) {
    return Container(
      margin: const EdgeInsets.only(right: 6.0, top: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        '#$type',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 공동 목표 상태 텍스트 생성
  String _getSharedGoalsStatus() {
    if (friend.sharedGoals.isEmpty) {
      return '함께 참여하는 일정 없음';
    } else {
      // 최대 2개까지만 표시하고 나머지는 '외'로 처리
      final displayedGoals = friend.sharedGoals.take(2).join("', '");
      final remainingCount = friend.sharedGoals.length - 2;

      String text = "'$displayedGoals'";
      if (remainingCount > 0) {
        text += " 외 $remainingCount개";
      }
      return '$text 일정에 함께 참여중';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal:3.0, vertical: 3.0),
      child:  InkWell(
        onTap: () {
          debugPrint('${friend.nickname}의 캘린더로 이동 클릭됨');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>
                FriendCalenderview(friendname: friend.nickname,)
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필, 닉네임, 등급 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // 닉네임, 목표 유형 (수직 정렬)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 닉네임 (가장 위)
                        Text(
                          friend.nickname,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        // 목표 유형 (닉네임 바로 아래에서 Wrap)
                        Wrap(
                          spacing: 0,
                          runSpacing: 0,
                          children: friend.goalTypes
                              .take(3)
                              .map((type) => _buildGoalTypeChip(type))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // 등급 표시 (오른쪽 끝)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Text(
                      '등급 ${friend.grade}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child:IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.black.withOpacity(0.7),
                        size: 22,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${friend.nickname} 삭제'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 10),

              // 공동 목표 상태
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Text(
                _getSharedGoalsStatus(),
                style: TextStyle(
                  fontSize: 13,
                  color: friend.sharedGoals.isEmpty ? Colors.grey[600] : Colors.black87,
                  fontWeight: friend.sharedGoals.isEmpty ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
            ],
          ),
        ),


      ),

    );
  }
}
