//friendsearch.dart 친구추가
import 'package:flutter/material.dart';
import 'package:pbl/tap/friend/friendtap.dart';
import 'package:pbl/services/friend_service.dart';
import 'package:pbl/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/const/colors.dart';

// 친구 데이터 모델 정의
class Friend {
  final String uid;
  final String nickname;
  final List<String> goalTypes;
  final int level; // 1부터 5
  bool isFriend; // 이미 친구인지 여부

  Friend({
    required this.uid,
    required this.nickname,
    required this.goalTypes,
    required this.level,
    required this.isFriend,
  });

  // DB 데이터 -> Friend 객체 변환
  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['id'],
      nickname: map['nickname'] ?? '알 수 없음',
      // DB에 goal_types나 grade 컬럼이 없다면 기본값 사용
      goalTypes: map['goal_types'] != null
          ? List<String>.from(map['goal_types'])
          : ['목표미설정'],
      level: map['grade'] ?? 1,
      isFriend: map['is_friend'] ?? false,
    );
  }
}

// 친구 검색 화면 위젯
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final FriendService _friendService = FriendService();
  String _searchQuery = '';
  List<Friend> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 초기에는 빈 리스트 또는 추천 친구를 보여줄 수 있음
    _searchResults = [];
  }

  // 검색 로직
  Future<void> _performSearch(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 서비스에서 검색 결과 가져오기 (친구 상태 포함)
      final results = await _friendService.searchUsersWithStatus(_searchQuery);

      setState(() {
        _searchResults = results.map((data) => Friend.fromMap(data)).toList();
      });
    } catch (e) {
      print("검색 실패: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 검색 입력 위젯
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
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
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '친구 이름 또는 목표 유형으로 검색',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none, // 기본 밑줄 제거
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _performSearch(_searchQuery),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
          onChanged: (val) => _searchQuery = val,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white, // 이미지의 상단 바 색상
        title: const Row(
          children: [
            Icon(
              Icons.search,
              size: 25,
              color: PRIMARY_COLOR,
            ),
            SizedBox(width: 8),
            Text(
                '친구 검색',
              style: TextStyle(
                color: PRIMARY_COLOR,
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 30),

          // 검색 입력바
          _buildSearchBar(),

          const SizedBox(height: 20),

          // 검색 결과 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchQuery.isNotEmpty
                ? const Center(child: Text("검색 결과가 없습니다."))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
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
  final FriendService _friendService = FriendService();
  bool _isProcessing = false; // 버튼 중복 클릭 방지

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
  Future<void> _toggleFriendship() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (widget.friend.isFriend) {
        // 이미 친구인 경우 -> 친구 삭제 (또는 요청 취소)
        await _friendService.deleteFriend(widget.friend.uid);
        setState(() {
          widget.friend.isFriend = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.friend.nickname}님을 친구 목록에서 삭제했습니다.')),
        );
      } else {
        // 친구가 아닌 경우 -> 친구 요청 전송
        await _friendService.sendFriendRequest(widget.friend.uid);
        setState(() {
          widget.friend.isFriend = true; // UI상으로는 바로 친구된 것처럼 표시 (혹은 요청중으로 표시 가능)
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.friend.nickname}님에게 친구 요청을 보냈습니다.')),
        );
      }
    } catch (e) {
      print("친구 작업 실패: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeBackgroundColor = Colors.grey[200];
    const gradeTextColor = Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 프로필 이미지 (아바타)
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue,
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

          // 레벨 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: gradeBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '레벨 ${widget.friend.level}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: gradeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

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
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.friend.isFriend ? '친구 해제' : '친구 추가',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}