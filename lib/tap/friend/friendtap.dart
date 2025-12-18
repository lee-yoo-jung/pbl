import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl/tap/friend/friendsearch.dart';
import 'package:pbl/services/friend_service.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/friend/FriendCalender/Friend_calenderview.dart';

class Friend {
  final String uid;
  final String nickname;
  final String? avatarUrl;
  final List<String> goalTypes;
  final int level;
  final List<String> sharedGoals;

  Friend({
    required this.uid,
    required this.nickname,
    this.avatarUrl,
    required this.goalTypes,
    required this.level,
    required this.sharedGoals,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['id'].toString(),
      nickname: map['nickname'] ?? '알 수 없음',
      avatarUrl: map['avatar_url'],
      goalTypes: map['goal_types'] != null
          ? List<String>.from(map['goal_types'])
          : ['목표미설정'],
      level: map['level'] != null ? int.parse(map['level'].toString()) : 1,
      sharedGoals: map['shared_goals'] != null
          ? List<String>.from(map['shared_goals'])
          : [],
    );
  }
}

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final FriendService _friendService = FriendService();
  final _supabase = Supabase.instance.client;
  List<Friend> _friendsList = [];
  bool _isLoading = true;

  StreamSubscription<List<Map<String, dynamic>>>? _friendsSubscription;

  @override
  void initState() {
    super.initState();
    _loadFriends();

    _setupFriendsStream();
  }

  @override
  void dispose() {
    _friendsSubscription?.cancel();
    super.dispose();
  }

  // 친구 목록 데이터 로드
  Future<void> _loadFriends() async {
    if (!mounted) return;
    if (_friendsList.isEmpty) setState(() => _isLoading = true);

    try {
      final data = await _friendService.getFriendsList();
      if (mounted) {
        setState(() {
          _friendsList = data.map((e) => Friend.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("친구 목록 로드 중 에러: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupFriendsStream() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    _friendsSubscription = _supabase
        .from('friends')
        .stream(primaryKey: ['id'])
        .eq('status', 'accepted')
        .listen((List<Map<String, dynamic>> data) {

      _loadFriends();

    }, onError: (e) {
      debugPrint("친구 목록 실시간 에러: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: const Icon(
          Icons.group,
          size: 30,
          color: PRIMARY_COLOR,
        ),
        title: const Text(
          '친구',
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 40,
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // '친구 목록' 제목과 '친구추가' 버튼 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 12.0),
            child: Row(
              children: [
                const Text(
                  '친구 목록',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    debugPrint('친구추가 버튼 클릭됨');
                    // 친구 검색 화면으로 이동
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FriendSearchScreen()),
                    );
                    // 돌아왔을 때 목록 새로고침
                    _loadFriends();
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                      Icon(Icons.keyboard_arrow_right)
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 친구 목록 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friendsList.isEmpty
                ? const Center(child: Text("등록된 친구가 없습니다.", textAlign: TextAlign.center))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              itemCount: _friendsList.length,
              itemBuilder: (context, index) {
                return _FriendListCard(
                  friend: _friendsList[index],
                  onDelete: _loadFriends,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendListCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onDelete;

  const _FriendListCard({
    required this.friend,
    this.onDelete
  });

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
    // 삭제 기능을 위한 서비스
    final FriendService friendService = FriendService();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3.0),
      child: InkWell(
        onTap: () {
          // 친구 캘린더로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendCalenderview(
                friend: friend,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필, 닉네임, 레벨, 삭제 버튼 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    // 이미지가 있으면 NetworkImage, 없으면 null
                    backgroundImage: (friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty)
                        ? NetworkImage(friend.avatarUrl!)
                        : null,
                    // 이미지가 없을 때만 아이콘 표시
                    child: (friend.avatarUrl == null || friend.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // 닉네임, 목표 유형
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 닉네임
                        Text(
                          friend.nickname,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        // 목표 유형
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

                  // 레벨 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Text(
                      '등급 ${friend.level}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // 삭제 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.black.withOpacity(0.7),
                        size: 22,
                      ),
                      onPressed: () {
                        // 삭제 확인 팝업
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("친구 삭제",
                              style: TextStyle(
                              fontFamily: "Pretendard",
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,),
                            content: Text("${friend.nickname}님을 친구 목록에서 삭제하시겠습니까?",
                              style: TextStyle(
                              fontFamily: "Pretendard",
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("취소", style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context); // 팝업 닫기
                                  try {
                                    // DB에서 삭제
                                    await friendService.deleteFriend(friend.uid);

                                    if (onDelete != null) onDelete!();

                                    // 메시지 표시
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${friend.nickname}님을 삭제했습니다.'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint("친구 삭제 실패: $e");
                                  }
                                },
                                child: const Text("삭제", style: TextStyle(color: Colors.red)),
                              ),
                            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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