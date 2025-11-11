import 'package:flutter/material.dart';
import 'package:calendar_scheduler/tab/calendar/component/main_calender.dart';
import 'package:calendar_scheduler/tab/calendar/component/schedule_bottom_sheet.dart';
import 'package:calendar_scheduler/tab/calendar/component/prints.dart';
import 'package:calendar_scheduler/const/colors.dart';
import 'package:calendar_scheduler/tab/calendar/component/event.dart';
import 'package:calendar_scheduler/services/supabase_calendar_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //선택된 날짜를 관리할 변수
  DateTime selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Map<DateTime, List<Event>> eventsMap = {}; //날짜 별로 이벤트를 저장한 저장소

  // --- Supabase 연동을 위한 변수들 ---
  List<Event> allEvents = []; // DB에서 가져온 모든 이벤트를 저장할 리스트
  final calendarService _calendarService = calendarService(); // 서비스 인스턴스 생성 (클래스 이름은 실제 파일에 맞게 확인)
  bool _isLoading = true; // 로딩 상태 변수
  // ---

  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    _loadEventsFromDB(); // 2. DB에서 데이터를 불러오는 함수로 변경
  }

  // --- Supabase 연동 함수들 ---
  // DB에서 이벤트를 비동기로 가져오는 함수
  Future<void> _loadEventsFromDB() async {
    if (!mounted) return; // 위젯이 화면에 없으면 중단
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    allEvents = await _calendarService.getGoals();
    _populateEventsMap(); // 가져온 데이터로 eventsMap 채우기

    if (mounted) {
      setState(() {
        _isLoading = false; // 로딩 끝
      });
    }
  }

  // allEvents 리스트를 기반으로 eventsMap을 채우는 함수
  void _populateEventsMap() {
    eventsMap.clear();
    for (var event in allEvents) {
      DateTime current = event.startDate;
      while (!current.isAfter(event.endDate)) {
        final key = _getDateKey(current);
        if (!eventsMap.containsKey(key)) {
          eventsMap[key] = [];
        }
        eventsMap[key]!.add(event);
        current = current.add(const Duration(days: 1));
      }
    }
  }

  //시간 제거해서 날짜 형식 통일
  DateTime _getDateKey(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _handlePlanUpdate(Event event) async {
    // Prints 위젯에서 이미 plan.isDone = true로 변경된 'event' 객체를 받음
    await _calendarService.updateGoal(event);

    // DB 업데이트 후, 화면을 즉시 갱신
    setState(() {
      _populateEventsMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              "내캘린더",
              style: TextStyle(
                color: PRIMARY_COLOR,
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: null,
              icon: Icon(
                Icons.notifications,
                size: 25,
                color: PRIMARY_COLOR,
              ),
            ),
          ],
        ),
        toolbarHeight: 40.0,
      ),

      //기기의 하단 메뉴바 같은 시스템 UI를 피해서 구현
      body: SafeArea(
        // 3. Stack -> Column으로 변경 (레이아웃 오류 수정)
        // 4. 로딩 중일 때 인디케이터 표시
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            MainCalendar(
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                });
              },
              selectedDate: selectedDate,
              events: eventsMap,
            ),

            //Prints 위젯 배치
            Expanded( // Column 하위에서 Expanded 정상 작동
              child: DraggableScrollableSheet(
                initialChildSize: 0.1,
                minChildSize: 0.1,
                maxChildSize: 0.8, // 최대 크기 0.8로 적용
                builder: (context, scrollController) => Prints(
                  selectedDate: selectedDate,
                  eventsMap: eventsMap,
                  scrollController: scrollController,

                  // 5. adddel 함수에 Supabase 삭제 로직 연동
                  adddel: (Event event, {Plan? plan, bool removePlan = false, bool removeEvent = false}) async {
                    if (removeEvent) {
                      // 이벤트(목표) 삭제
                      if (event.id != null) {
                        await _calendarService.deleteGoal(event.id!);
                        _loadEventsFromDB(); // DB에서 데이터 다시 불러오기
                      }
                    } else if (removePlan && plan != null) {
                      // (추후 구현) 계획 삭제 로직
                      // event.plans.remove(plan);
                      // await _calendarService.updateGoal(event);
                      // _loadEventsFromDB();
                    } else if (plan != null) {
                      // (추후 구현) 계획 추가/수정 로직
                      // event.plans.add(plan);
                      // await _calendarService.updateGoal(event);
                      // _loadEventsFromDB();
                    }
                  },
                  onPlanUpdated: _handlePlanUpdate,
                ),
              ),
            ),
          ],
        ),
      ),

      //이벤트(목표) 추가 버튼
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: 45,
          height: 45,
          child: FloatingActionButton(
            backgroundColor: PRIMARY_COLOR,
            onPressed: () async {
              // 6. 새로운 AlertDialog 팝업 방식 사용
              final newGoal = await showDialog<Event>(
                context: context,
                barrierDismissible: true,
                builder: (_) => AlertDialog(
                  content: ScheduleBottomSheet(), // ScheduleBottomSheet을 content로 사용
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  backgroundColor: Colors.white,
                ),
              );

              // 7. newGoal이 있다면, Supabase에 추가
              if (newGoal != null) {
                final addedGoal = await _calendarService.addGoal(newGoal);
                if (addedGoal != null) {
                  _loadEventsFromDB(); // 성공 시 DB에서 데이터 다시 불러오기
                }
              }
            },
            shape: const CircleBorder(),
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}