//rankingtap.dart 랭킹 탭
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 랭킹 데이터
class RankUser {
  final String name;
  final int exp;

  RankUser({required this.name, required this.exp});
}

// 랭킹 페이지 메인 위젯
class RankingTap extends StatefulWidget {
  const RankingTap({super.key});

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
    return DefaultTabController(
      length: 2, // 탭 개수: 전체, 친구
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white),
              SizedBox(width: 8),
              Text('랭킹', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          elevation: 0,
          // TabBar를 AppBar의 bottom 영역에 배치
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),  child: Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: '전체 랭킹'),
                  Tab(text: '친구 랭킹'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
              ),
            ),
          ),

        ),
        body: TabBarView(
          children: [
            _buildRankingList(_allUsers),
            _buildRankingList(_friendUsers),
          ],
        ),

      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      // 순위에 따라 표시
      leading: _buildRankIcon(rank),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'EXP',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatter.format(user.exp),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 순위에 따라 아이콘을 반환하는 위젯
  Widget _buildRankIcon(int rank) {
    switch (rank) {
      case 1:
        return _MedalIcon(color: Colors.amber, rank: rank); // 금메달
      case 2:
        return _MedalIcon(color: Colors.grey.shade400, rank: rank); // 은메달
      case 3:
        return _MedalIcon(color: const Color(0xFFCD7F32), rank: rank); // 동메달
      default:
      // 4위부터는 숫자
        return SizedBox(
          width: 40,
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
        );
    }
  }
}

// 메달 아이콘을 위한 별도 위젯
class _MedalIcon extends StatelessWidget {
  final Color color;
  final int rank;

  const _MedalIcon({required this.color, required this.rank});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.workspace_premium, color: color, size: 40),
          Text(
            rank.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
