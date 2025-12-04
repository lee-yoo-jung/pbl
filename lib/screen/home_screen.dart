// lib/screen/main_screen.dart 하단 바(네비게이션 바)
import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/calenderview.dart';       // 내 캘린더
import 'package:pbl/tap/rankingtap.dart';      // 랭킹
import 'package:pbl/tap/grouptap.dart';        // 그룹
import 'package:pbl/tap/friend/friendtap.dart';       // 친구
import 'package:pbl/tap/mypages/mypage.dart';        // 마이페이지
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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

  // 탭을 선택했을 때 인덱스를 변경하고 화면을 다시 그리는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  CurvedNavigationBar buildCurvedNavigationBar() {
    final List<Widget> items = [
      // 0: 랭킹
      Icon(
        Icons.emoji_events_rounded,
        size: (_selectedIndex == 0) ? 28 : 20,
        color: Colors.white
      ),
      // 1: 그룹
      Icon(
        Icons.groups_rounded,
        size: (_selectedIndex == 1) ? 28 : 20,
        color: Colors.white
      ),
      // 2: 내 캘린더 (초기값)
      Icon(
        Icons.calendar_month_rounded,
        size: (_selectedIndex == 2) ? 28 : 20,
        color: Colors.white
      ),
      // 3: 친구
      Icon(
        Icons.person_search_rounded,
        size: (_selectedIndex == 3) ? 28 : 20,
        color: Colors.white
      ),
      // 4: 마이페이지
      Icon(
        Icons.person_rounded,
        size: (_selectedIndex == 4) ? 28 : 20,
        color: Colors.white
      ),
    ];

    return CurvedNavigationBar(
      index: 2,
      height: 65,

      backgroundColor: Colors.transparent,
      buttonBackgroundColor: POINT_COLOR, // 선택된 버튼 색상
      color: PRIMARY_COLOR, // 하단바 색상

      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,

      onTap: _onItemTapped,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    //build 메서드 안에서 위젯 리스트를 만들어야 최신 상태가 반영됨
    final List<Widget> widgetOptions = <Widget>[
      // 0번: 랭킹페이지(랭킹 공개 상태 전달)
      RankingTap(isRankingPublic: _isRankingPublic),

      const GroupGoalPage(), // 1번: 그룹 페이지
      const Calenderview(), // 2번: 내 캘린더 페이지(HomeScreen)
      const FriendsListPage(), // 3번: 친구 페이지

      // 4번: 마이페이지(상태와 상태를 변경시킬 함수 전달)
      MyPage(
        isRankingPublic: _isRankingPublic,
        onRankingChanged: _onRankingSettingsChanged,
      ),
    ];

    return SafeArea(
        child: Scaffold(
          extendBody: true,
          body: widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: buildCurvedNavigationBar(),
        ),
    );
  }
}
