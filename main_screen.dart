// lib/screen/main_screen.dart 하단 바(네비게이션 바)
import 'package:flutter/material.dart';
import 'package:calendar/const/colors.dart';
import 'package:calendar/screen/home_screen.dart';       // 내 캘린더
import 'package:calendar/screen/rankingtap.dart';      // 랭킹
import 'package:calendar/screen/grouptap.dart';        // 그룹
import 'package:calendar/screen/friendtap.dart';       // 친구
import 'package:calendar/component/mypage.dart';        // 마이페이지

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 탭의 인덱스 (초기값: 2, '내 캘린더')
  int _selectedIndex = 2;

  bool _isRankingPublic = true; //랭킹 공개여부

  //MyPage의 스위치 값이 바뀔 때 호출될 함수
  void _onRankingSettingsChanged(bool value) {
    setState(() {
      _isRankingPublic = value;
    });
  }

/*  static const List<Widget> _widgetOptions = <Widget>[
    RankingTap(),   // 0번: 랭킹 페이지
    GroupGoalPage(),     // 1번: 그룹 페이지
    HomeScreen(),   // 2번: 내 캘린더 페이지 (기존 HomeScreen)
    FriendsListPage(),    // 3번: 친구 페이지
    MyPage(),       // 4번: 마이페이지
  ];
 */

  // 탭을 선택했을 때 인덱스를 변경하고 화면을 다시 그리는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //build 메서드 안에서 위젯 리스트를 만들어야 최신 상태가 반영됩니다.
    final List<Widget> widgetOptions = <Widget>[
      // RankingTap에 현재 랭킹 공개 상태를 전달
      RankingTap(isRankingPublic: _isRankingPublic), // 0번: 랭킹페이지

      const GroupGoalPage(), // 1번: 그룹 페이지
      const HomeScreen(), // 2번: 내 캘린더 페이지(HomeScreen)
      const FriendsListPage(), // 3번: 친구 페이지

      // MyPage에 현재 상태와, 상태를 변경시킬 함수를 전달합니다.
      MyPage(
        isRankingPublic: _isRankingPublic,
        onRankingChanged: _onRankingSettingsChanged,
      ), // 4번: 마이페이지
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),

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
