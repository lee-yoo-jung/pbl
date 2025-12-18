import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Friend {
  final String uid;
  final String nickname;
  final List<String> goalTypes;
  final int level;
  String status;

  Friend({
    required this.uid,
    required this.nickname,
    required this.goalTypes,
    required this.level,
    this.status = 'none',
  });

  factory Friend.fromJson(Map<String, dynamic> json, String myId, List<Map<String, dynamic>> relations) {
    String friendStatus = 'none';
    final targetId = json['id'];

    // 나와의 관계 확인
    final relation = relations.firstWhere(
          (r) => (r['requester_id'] == myId && r['receiver_id'] == targetId) ||
          (r['requester_id'] == targetId && r['receiver_id'] == myId),
      orElse: () => {},
    );

    if (relation.isNotEmpty) {
      if (relation['status'] == 'accepted') {
        friendStatus = 'accepted';
      } else if (relation['requester_id'] == myId) {
        friendStatus = 'pending'; // 내가 보냄
      } else {
        friendStatus = 'received'; // 상대가 보냄
      }
    }

    return Friend(
      uid: json['id'],
      nickname: json['nickname'] ?? '알 수 없음',
      goalTypes: json['goal_types'] != null
          ? List<String>.from(json['goal_types'])
          : [],
      level: json['grade'] ?? 1,
      status: friendStatus,
    );
  }
}

class FriendSearchService {
  final supabase = Supabase.instance.client;

  // 유저 검색
  Future<List<Friend>> searchUsers(String query) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || query.isEmpty) return [];

    try {
      // 닉네임으로 유저 검색 (나 제외)
      final usersResponse = await supabase
          .from('users')
          .select()
          .ilike('nickname', '$query%') // 해당 검색어로 시작하는 닉네임
          .neq('id', myId);

      // 친구 관계 조회
      final relationsResponse = await supabase
          .from('friends')
          .select()
          .or('requester_id.eq.$myId,receiver_id.eq.$myId');

      final relations = List<Map<String, dynamic>>.from(relationsResponse);
      final users = List<Map<String, dynamic>>.from(usersResponse);

      // 매핑
      return users.map((u) => Friend.fromJson(u, myId, relations)).toList();
    } catch (e) {
      debugPrint("검색 에러: $e");
      return [];
    }
  }

  // 친구 요청 보내기
  Future<bool> sendFriendRequest(String targetId) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return false;
    try {
      await supabase.from('friends').insert({
        'requester_id': myId,
        'receiver_id': targetId,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 요청 취소
  Future<bool> cancelRequest(String targetId) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return false;
    try {
      await supabase.from('friends').delete()
          .eq('requester_id', myId)
          .eq('receiver_id', targetId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final FriendSearchService _friendService = FriendSearchService();
  String _searchQuery = '';
  List<Friend> _searchResults = [];
  bool _isLoading = false;

  // 검색 실행
  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query.trim();
    });

    if (_searchQuery.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _friendService.searchUsers(_searchQuery);
      setState(() => _searchResults = results);
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
          borderRadius: BorderRadius.circular(12.0),
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
            hintText: '친구 이름으로 검색',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _performSearch(_searchQuery),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          onChanged: (val) => _searchQuery = val,
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
          const SizedBox(height: 30),

          // 검색창
          _buildSearchBar(),

          const SizedBox(height: 20),

          // 결과 리스트
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

class FriendListItem extends StatefulWidget {
  final Friend friend;
  const FriendListItem({required this.friend, super.key});

  @override
  State<FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends State<FriendListItem> {
  final FriendSearchService _friendService = FriendSearchService();
  bool _isProcessing = false;

  // 목표 유형 칩
  Widget _buildGoalTypeChip(String type) {
    return Container(
      margin: const EdgeInsets.only(right: 6.0, bottom: 4.0),
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

  // 버튼 클릭 핸들러
  Future<void> _handleButtonPress() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 친구 아님 -> 요청 보내기
      if (widget.friend.status == 'none') {
        final success = await _friendService.sendFriendRequest(widget.friend.uid);
        if (success) {
          setState(() => widget.friend.status = 'pending');
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.friend.nickname}님에게 요청을 보냈습니다.')),
            );
          }
        }
      }
      // 요청 보냄 -> 요청 취소
      else if (widget.friend.status == 'pending') {
        final success = await _friendService.cancelRequest(widget.friend.uid);
        if (success) {
          setState(() => widget.friend.status = 'none');
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('친구 요청을 취소했습니다.')),
            );
          }
        }
      }
      // 이미 친구이거나 받은 요청은 여기서 처리하지 않음 (버튼 비활성화)
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeBackgroundColor = Colors.grey[200];
    const gradeTextColor = Colors.black;

    // 상태에 따른 버튼 텍스트 및 스타일 결정
    String btnText = '친구 추가';
    Color btnColor = Colors.blue;
    bool isDisabled = false;

    switch (widget.friend.status) {
      case 'accepted':
        btnText = '친구';
        btnColor = Colors.grey;
        isDisabled = true;
        break;
      case 'pending':
        btnText = '요청됨';
        btnColor = Colors.grey;
        break;
      case 'received':
        btnText = '수락 대기'; // 알림 탭에서 수락해야 함
        btnColor = Colors.grey;
        isDisabled = true;
        break;
      case 'none':
      default:
        btnText = '친구 추가';
        btnColor = POINT_COLOR;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 프로필 이미지
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),

          // 닉네임 및 목표 유형
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.nickname,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
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
              onPressed: isDisabled ? null : _handleButtonPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                // 비활성화 상태일 때 스타일
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.white,
              ),
              child: _isProcessing
                  ? const SizedBox(width:12, height:12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                btnText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}