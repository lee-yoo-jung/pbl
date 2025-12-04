//rankingtap.dart 랭킹 탭
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl/const/colors.dart';

// 랭킹 데이터
class RankUser {
  final String name;
  final int exp;

  RankUser({required this.name, required this.exp});
}

// 랭킹 페이지 메인 위젯
class RankingTap extends StatefulWidget {
  final bool isRankingPublic;

  const RankingTap({
    super.key,
    required this.isRankingPublic,
  });

  @override
  State<RankingTap> createState() => _RankingTapState();
}

class _RankingTapState extends State<RankingTap> {
//임시 데이터
  final List<RankUser> _allUsers = [
    RankUser(name: '사용자 A', exp:5678987654),
    RankUser(name: '사용자 B', exp: 4567656776),
    RankUser(name: '사용자 C', exp: 4445676579),
    RankUser(name: '사용자 D', exp: 3124654321),
    RankUser(name: '사용자 E', exp: 2124654321),
  ];

  final List<RankUser> _friendUsers = [
    RankUser(name: '친구 B', exp: 4567656776),
    RankUser(name: '친구 A', exp: 3124654321),
    RankUser(name: '친구 C', exp: 1124654321),
  ];
  // ------

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
                  onPressed: () {

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
        body: Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 1.0),
          child: TabBarView(
            children: [
              _buildRankingList(_allUsers),
              _buildRankingList(_friendUsers),
            ],
          ),
        ),
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
        return _buildRankItem(user, rank);
      },
    );
  }

  // 랭킹 리스트의 각 항목 UI
  Widget _buildRankItem(RankUser user, int rank) {
    final formatter = NumberFormat('#,###');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      // 순위에 따라 표시
      leading: _buildRankIcon(rank),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: PRIMARY_COLOR,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
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
        ],
      ),
      trailing: const Row(mainAxisSize: MainAxisSize.min),
    );
  }

  // 순위에 따라 아이콘을 반환하는 위젯
  Widget _buildRankIcon(int rank) {
    switch (rank) {
      case 1:
        return _MedalIcon(
            color: Colors.amber,
            textColor: Color(0xFF604000),
            rank: rank
        ); // 금메달
      case 2:
        return _MedalIcon(
            color: Color(0xFFB4C8D2),
            textColor: Color(0xFF4A5560),
            rank: rank
        )
        ; // 은메달
      case 3:
        return _MedalIcon(
            color: Color(0xFFB87333),
            textColor: Color(0xFF3A1500),
            rank: rank
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
class _MedalIcon extends StatelessWidget {
  final Color color;
  final Color textColor;
  final int rank;

  const _MedalIcon({required this.color, required this.rank, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: color,
            size: 40,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: color.withOpacity(0.5),
                offset: Offset(2, 4),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0.0, -4.0),
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontFamily: "Pretendard",
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}