//rankingtap.dart 랭킹 탭
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/mypages/mypage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 랭킹 데이터
class RankUser {
  final String uid;
  final String nickname;
  final int level;
  final int exp;
  final String? avatarUrl;

  RankUser({
    required this.uid,
    required this.nickname,
    required this.level,
    required this.exp,
    this.avatarUrl,
  });

  factory RankUser.fromJson(Map<String, dynamic> json) {
    // DB의 'id' (UUID)를 안전하게 String으로 파싱합니다.
    final String idString = json['id']?.toString() ?? '';

    // DB의 'exp' (int8/BIGINT)를 int (64bit)로 안전하게 파싱합니다.
    final int expValue = (json['exp'] is int)
        ? json['exp'] as int
        : int.tryParse(json['exp'].toString()) ?? 0;

    return RankUser(
      uid: idString, // DB 필드명 'id' -> Dart 필드명 'uid'
      nickname: json['nickname'] as String,
      level: json['level'] as int,
      exp: expValue,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

// 랭킹 페이지 메인 위젯
class RankingTap extends StatefulWidget {
  final bool isRankingPublic;
  final ValueChanged<int>? onTabSwitch;

  const RankingTap({
    super.key,
    required this.isRankingPublic,
    this.onTabSwitch,
  });

  @override
  State<RankingTap> createState() => _RankingTapState();
}

class _RankingTapState extends State<RankingTap> {
  List<RankUser> _allUsers = [];
  List<RankUser> _friendUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  final _supabase = Supabase.instance.client;

  //임시 데이터
  static final List<RankUser> _defaultAllUsers = [
    RankUser(uid: '1234', nickname: '사용자 A', level: 40, exp:5678987650),
    RankUser(uid: '2345', nickname: '사용자 B', level: 38, exp: 4567656770),
    RankUser(uid: '3456', nickname: '사용자 C', level: 37, exp: 444567650),
    RankUser(uid: '4567', nickname: '사용자 D', level: 31, exp: 3124654320),
    RankUser(uid: '5678', nickname: '사용자 E', level: 28, exp: 2124654320),
  ];

  static final List<RankUser> _defaultFriendUsers = [
    RankUser(uid: '2345', nickname: '찬구 B', level: 38, exp: 4567656770),
    RankUser(uid: '4567', nickname: '친구 A', level: 31, exp: 3124654320),
    RankUser(uid: '6789', nickname: '친구 C', level: 18, exp: 1124654320),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isRankingPublic) {
      _fetchRankingData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchRankingData() async {
    if (!widget.isRankingPublic) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<RankUser> fetchedAll = [];
    List<RankUser> fetchedFriends = [];

    // 현재 사용자 ID
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      _errorMessage = "로그인 정보가 없습니다. 랭킹을 조회할 수 없습니다.";
      // 로딩을 끄고 에러 메시지를 표시하거나, 이 시점에서 함수 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    _currentUserId = currentUserId;

    try {
      // 전체 랭킹 조회
      final allRankingData = await _supabase
          .from('users')
          .select('id, nickname, level, exp, created_at, avatar_url')
          .eq('is_ranking_public', true)
          // 랭킹 결정
          // 1차: exp 내림차순
          .order('exp', ascending: false)
          // 2차: created_at 오름차순 (경험치가 같을 때 먼저 가입한 사람이 우선)
          .order('created_at', ascending: true);

      // 친구 관계 레코드 조회
      final friendRecords = await _supabase
          .from('friends')
          .select('requester_id, receiver_id')
          .eq('status', 'accepted')
          .or('requester_id.eq.$currentUserId,receiver_id.eq.$currentUserId');

      // 친구 UID 추출
      final Set<String> friendUidsSet = {};

      for (final record in friendRecords) {
        final requesterId = record['requester_id'] as String;
        final receiverId = record['receiver_id'] as String;

        if (requesterId == currentUserId) {
          // 내가 요청자라면, 상대방은 receiver_id
          friendUidsSet.add(receiverId);
        } else if (receiverId == currentUserId) {
          // 내가 수신자라면, 상대방은 requester_id
          friendUidsSet.add(requesterId);
        }
      }
      List<String> friendUids = [];

      if (friendUidsSet.isNotEmpty) {
        final publishedFriendsData = await _supabase
            .from('users')
            .select('id')
            .inFilter('id', friendUidsSet.toList())
            .eq('is_ranking_public', true); // 공개 설정이 true인 친구만 필터링

        friendUids.addAll(publishedFriendsData.map((e) => e['id'] as String));
      }

      final currentUserProfile = await _supabase
          .from('users')
          .select('is_ranking_public')
          .eq('id', currentUserId)
          .single();

      final isCurrentUserRankingPublic =
      currentUserProfile['is_ranking_public'] as bool;

      if (isCurrentUserRankingPublic) { // 내가 공개했을 때만 나를 포함
        friendUids.add(currentUserId);
      }
      final List<String> finalFriendUids = friendUids.toSet().toList(); // 중복 제거

      if (finalFriendUids.isNotEmpty) {
        final friendRankingData = await _supabase
            .from('users')
            .select('id, nickname, level, exp, created_at, avatar_url')
            .inFilter('id', finalFriendUids)
            .order('exp', ascending: false);

        fetchedFriends = friendRankingData.map((json) => RankUser.fromJson(json)).toList();
      }

      // 데이터 변환 (전체 랭킹)
      fetchedAll = allRankingData.map((json) => RankUser.fromJson(json)).toList();

    } on PostgrestException catch (e) {
      _errorMessage = '데이터베이스 오류: ${e.message}';
    } catch (e) {
      _errorMessage = '데이터 로드 실패: $e';
    }

    // 데이터 할당 및 폴백 로직
    _allUsers = (_errorMessage != null || fetchedAll.isEmpty)
        ? _defaultAllUsers
        : fetchedAll;

    _friendUsers = (_errorMessage != null || fetchedFriends.isEmpty)
        ? _defaultFriendUsers
        : fetchedFriends;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전달받은 isRankingPublic 값에 따라 다른 화면을 보여줌
    // StatefulWidget에서는 widget.isRankingPublic 으로 접근
    if (!widget.isRankingPublic) {
      // 랭킹 공개 == off
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildCommonAppBar(), // 공통 AppBar 사용
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height:100),
                Text(
                  "랭킹을 보려면 마이페이지에서\n'랭킹보기'를 켜주세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily:"Pretendard",
                      fontSize: 20,
                      color: Colors.grey[600]
                  ),
                ),

                SizedBox(height: 40),

                TextButton(
                  onPressed:(){
                    if (widget.onTabSwitch != null) {
                      widget.onTabSwitch!(4);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: PRIMARY_COLOR,
                    textStyle: const TextStyle(
                      fontFamily: "Pretendard",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text(
                    "마이페이지→",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 랭킹 공개 == on
    return DefaultTabController(

      length: 2, // 탭 개수: 전체, 친구
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: PRIMARY_COLOR,
              ),
              SizedBox(width: 8),
              Text('랭킹',
                style: TextStyle(
                  color: PRIMARY_COLOR,
                  fontSize: 20,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          toolbarHeight: 40.0,
          elevation: 0,
          // TabBar를 AppBar의 bottom 영역에 배치
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: '전체 랭킹'),
                  Tab(text: '친구 랭킹'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: PRIMARY_COLOR,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
              ),
            ),
          ),

        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: PRIMARY_COLOR));
    }

    // 에러 발생 시 임시 데이터로 대체했더라도 에러 메시지를 사용자에게 보여줄지 결정
    if (_errorMessage != null && _allUsers.isEmpty && _friendUsers.isEmpty) {
      return Center(
        child: Text('데이터 로드 오류: $_errorMessage', textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: TabBarView(
        children: [
          _buildRankingList(_allUsers),
          _buildRankingList(_friendUsers),
        ],
      ),
    );
  }

  // 중복되는 AppBar를 공통 함수로 분리
  AppBar _buildCommonAppBar({PreferredSizeWidget? bottom}) {
    return AppBar(
      backgroundColor: Colors.white,
      title: const Row(
        children: [
          Text('랭킹',
            style: TextStyle(
              color: PRIMARY_COLOR,
              fontSize: 20,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      elevation: 0,
      bottom: bottom, // TabBar가 있을 경우에만 bottom이 추가됨
      automaticallyImplyLeading: false, // AppBar의 뒤로가기 버튼 자동 생성 방지
    );
  }

  // 랭킹 리스트를 생성
  Widget _buildRankingList(List<RankUser> users) {
    // exp 높은 순으로 정렬
    users.sort((a, b) => b.exp.compareTo(a.exp));

    if (users.isEmpty) {
      return const Center(child: Text('랭킹 정보가 없습니다.'));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final rank = index + 1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: _buildRankItem(user, rank),
        );
      },
    );
  }

  // 랭킹 리스트의 각 항목 UI
  Widget _buildRankItem(RankUser user, int rank) {
    final formatter = NumberFormat('#,###');

    // 현재 사용자 여부 확인
    final isCurrentUser = user.uid == _currentUserId;

    // 배경색 설정(내 랭킹 표시)
    final itemColor = isCurrentUser
        ? POINT_COLOR.withOpacity(0.1) // 내 랭킹일 경우 연한 강조색
        : Colors.transparent; // 일반적인 경우 투명

    Widget profileAvatar;

    // 등록된 프로필 있다면 그거 사용
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      profileAvatar = CircleAvatar(
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: PRIMARY_COLOR, // 로딩 또는 에러 시 대비
      );
    } else {
      // URL이 없다면 기본 아이콘 사용
      profileAvatar = const CircleAvatar(
        backgroundColor: PRIMARY_COLOR,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      // 순위에 따라 표시
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 순위 아이콘
          _buildRankIcon(rank),
          const SizedBox(width: 15),

          // 프로필
          profileAvatar,

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(
                      fontFamily: "Pretendard",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: DARK_BLUE.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3.0,
                            color: Colors.grey,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'EXP',
                        style: TextStyle(
                          fontFamily: "Pretendard",
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        formatter.format(user.exp), // 경험치
                        style: const TextStyle(
                            fontFamily: "Pretendard",
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87
                        )
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // 순위에 따라 아이콘을 반환하는 위젯
  Widget _buildRankIcon(int rank) {
    switch (rank) {
      case 1:
        return _MedalImage(
          imagePath: 'assets/images/rank/gold.png',
        ); // 금메달
      case 2:
        return _MedalImage(
          imagePath: 'assets/images/rank/silver.png',
        ); // 은메달
      case 3:
        return _MedalImage(
          imagePath: 'assets/images/rank/bronze.png',
        ); // 동메달
      default:
      // 4위부터는 숫자
        return SizedBox(
          width: 40,
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                fontFamily: "Pretendard",
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,),
            ),
          ),
        );
    }
  }
}

// 메달 아이콘을 위한 별도 위젯
class _MedalImage extends StatelessWidget {
  final String imagePath;
  const _MedalImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.asset(
        imagePath,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      ),
    );
  }
}
