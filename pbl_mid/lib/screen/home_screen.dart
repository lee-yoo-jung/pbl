import 'package:flutter/material.dart';
import 'package:pbl_mid/tap/calender/calenderview.dart';  // 내 캘린더
import 'package:pbl_mid/tap/rankingtap.dart';             // 랭킹
import 'package:pbl_mid/tap/grouptap.dart';               // 그룹
import 'package:pbl_mid/tap/friend/friendtap.dart';       // 친구
import 'package:pbl_mid/tap/mypages/mypage.dart';         // 마이페이지

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭의 인덱스 (초기값: 2, '내 캘린더')
  int _selectedIndex = 2;

  // 각 탭에 해당하는 페이지 위젯들을 리스트로 관리합니다.
  static const List<Widget> _widgetOptions = <Widget>[
    RankingTap(),   // 0번: 랭킹 페이지
    GroupGoalPage(),     // 1번: 그룹 페이지
    Calenderview(),   // 2번: 내 캘린더 페이지
    FriendsListPage(),    // 3번: 친구 페이지
    MyPage(),       // 4번: 마이페이지
  ];

  // 탭을 선택했을 때 인덱스를 변경하고 화면을 다시 그리는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: '그룹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '내캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search),
            label: '친구',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
        selectedItemColor: const Color(0xFF000080), // 남색(Navy)
        unselectedItemColor: Colors.white,
        selectedFontSize: 12.0,
        unselectedFontSize: 12.0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

    );
  }
}