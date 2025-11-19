//friendsearch.dart 친구추가
import 'package:flutter/material.dart';
import 'package:pbl/tap/friend/friendtap.dart';
import 'package:pbl/const/colors.dart';

// 친구 데이터 모델 정의
class Friend {
  final String nickname;
  final List<String> goalTypes;
  final int grade; // 1부터 5
  bool isFriend; // 이미 친구인지 여부

  Friend({
    required this.nickname,
    required this.goalTypes,
    required this.grade,
    required this.isFriend,
  });
}


// 가상 데이터 (Mock Data) 생성
final List<Friend> mockFriends = [
  Friend(nickname: 'apple', goalTypes: ['입시', '시험'], grade: 4, isFriend: false),
  Friend(nickname: 'strawberry', goalTypes: ['운동', '식단', '취미'], grade: 5, isFriend: true),
  Friend(nickname: 'banana', goalTypes: ['취업'], grade: 2, isFriend: false),
  Friend(nickname: 'peach', goalTypes: ['자기개발', '취미', '기타'], grade: 1, isFriend: false),
  Friend(nickname: 'melon', goalTypes: ['시험', '취업'], grade: 3, isFriend: false),
  Friend(nickname: 'pineapple', goalTypes: ['운동', '식단'], grade: 3, isFriend: true),
  Friend(nickname: 'pear', goalTypes: ['취미', '자기개발'], grade: 1, isFriend: false),
];


// 친구 검색 화면 위젯
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  String _searchQuery = '';
  List<Friend> _searchResults = mockFriends;

  @override
  void initState() {
    super.initState();
    _searchResults = mockFriends;
  }

  // 검색 로직
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _searchResults = mockFriends;
      } else {
        _searchResults = mockFriends.where((friend) {
          final nicknameLower = friend.nickname.toLowerCase();
          final goalTypesLower = friend.goalTypes.map((type) => type.toLowerCase());

          return nicknameLower.startsWith(_searchQuery) ||
              goalTypesLower.any((type) => type.startsWith(_searchQuery));
        }).toList();
      }
    });
  }

  // 검색 입력 위젯
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50.0), // 둥근 모서리
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: _performSearch,
          decoration: const InputDecoration(
            hintText: '친구 이름 또는 목표 유형으로 검색',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none, // 기본 밑줄 제거
            contentPadding: EdgeInsets.symmetric(vertical: 12.0,horizontal: 15),
            suffixIcon: Icon(Icons.search, color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // 이부분 통일하기
      appBar: AppBar(
        title: const
          Text('친구 검색',
              style: TextStyle(
                color: PRIMARY_COLOR,
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w800,
              ),
        ),
        toolbarHeight: 60,
        backgroundColor: Colors.white, // 이미지의 상단 바 색상
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // 검색 입력바
          _buildSearchBar(),

          const SizedBox(height: 10),

          // 검색 결과 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                // 친구 상태 변화를 반영하기 위해 FriendListItem을 사용
                return FriendListItem(friend: _searchResults[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}


// 친구 목록 항목 위젯
class FriendListItem extends StatefulWidget {
  final Friend friend;
  const FriendListItem({required this.friend, super.key});

  @override
  State<FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends State<FriendListItem> {

  // 목표 유형을 칩 형태로 표시하는 위젯 (회색 배경, 둥근 모서리)
  Widget _buildGoalTypeChip(String type) {
    return Container(
      // Wrap으로 변경 시, 세로 간격을 위해 bottom 마진 추가
      margin: const EdgeInsets.only(right: 6.0, bottom: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[300], // 회색 배경
        borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
      ),
      child: Text(
        '#$type',
        style: TextStyle(
          fontSize: 11, // 목표 유형 글자 크기
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 친구 상태 토글 함수
  void _toggleFriendship() {
    setState(() {
      widget.friend.isFriend = !widget.friend.isFriend;
      debugPrint('${widget.friend.nickname} 친구 상태: ${widget.friend.isFriend ? '친구됨' : '친구 아님'}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradeBackgroundColor = Colors.grey[200];
    const gradeTextColor = Colors.black;

    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 이미지 (아바타)
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),

              // 닉네임 및 목표 유형
              Expanded( // Expanded로 감싸서 남은 공간을 모두 차지하도록 보장
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 닉네임
                    Text(
                      widget.friend.nickname,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // 목표 유형 (Wrap 위젯으로 변경하여 줄 바꿈 처리)
                    Wrap(
                      spacing: 0,
                      runSpacing: 0,
                      children: widget.friend.goalTypes
                          .take(3)
                          .map((type) => _buildGoalTypeChip(type))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 등급 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '등급 ${widget.friend.grade}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: gradeTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // 친구 추가 버튼
              SizedBox(
                width: 85,
                child: ElevatedButton(
                  onPressed: _toggleFriendship,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.friend.isFriend ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.friend.isFriend ? '친구 요청' : '친구 추가',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}
