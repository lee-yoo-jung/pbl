import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/main_calender.dart';
import 'package:pbl/tap/calender/component/schedule_bottom_sheet.dart';
import 'package:pbl/tap/calender/component/prints.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/services/supabase_calendar_service.dart';

//<메인 화면(캘린더) 구상>

class Calenderview extends StatefulWidget{
  const Calenderview({Key? key}):super(key:key);

  @override
  State<Calenderview> createState()=>_CalenderviewState();
}

class _CalenderviewState extends State<Calenderview>{
  final CalendarService _calendarService = CalendarService(); // 서비스 객체
  List<Event> eventsList = []; // 오류 해결: eventsList 선언
  bool _isLoading = false; // 로딩 상태 표시용

  //선택된 날짜를 관리할 변수
  DateTime selectedDate=DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  //페이지가 생성될 때 한번만 실행
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  //Supabase에서 목표 리스트 가져오는 함수
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _calendarService.getGoals();
      setState(() {
        eventsList = events;
      });
    } catch (e) {
      print("데이터 로드 실패: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //모든 이벤트를 날짜별로 나눠서 eventsMap에 저장
  Map<DateTime,List<Event>> generateGoals(List<Event> events) {
    final Map<DateTime, List<Event>> map={};

    for (var event in events) {
      DateTime current = event.startDate;
      while (!current.isAfter(event.endDate)) {
        final key = DateTime(current.year,current.month,current.day);

        if (!map.containsKey(key)) {
          map[key] = [];
        }
        map[key]!.add(event);
        current = current.add(const Duration(days: 1));
      }
    }
    return map;
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading && eventsList.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final TogetherGoals = eventsList.where((goal)=> (goal.togeter.isNotEmpty)).toList();
    final SingleGoals = eventsList.where((goal)=> (goal.togeter.isEmpty)).toList();

    final TogetherGoalsMap = generateGoals(TogetherGoals);
    final SingleGoalsMap = generateGoals(SingleGoals);
    final AllGoalsMap = generateGoals(eventsList);

    return DefaultTabController(
      length: 3,
      child: Scaffold(  //상단 앱바
        appBar: AppBar(
          backgroundColor: Colors.white,
          //가로로 배치
          title: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: PRIMARY_COLOR,
              ),
              const SizedBox(width: 8),
              const Text(
                "내캘린더",
                style: TextStyle(
                  color: PRIMARY_COLOR,
                  fontSize: 20,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: null,
                icon: Icon(Icons.notifications,
                  size: 25,
                  color: POINT_COLOR,
                ),
              ),
            ],
          ),
          toolbarHeight: 40.0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: '개인'),
                  Tab(text: '개인 & 공동'),
                  Tab(text: '공동'),
                ],
                labelColor: Colors.black ,  //선택된 탭의 글 색상
                unselectedLabelColor: Colors.grey,  //선택되지 않은 탭의 글 색상
                indicatorColor: Colors.black, //선택된 탭 아래 막대 색상
                indicatorWeight: 2.5, //선택된 탭 아래 막대의 높이
                indicatorSize: TabBarIndicatorSize.label, //선택된 탭 아래 막대의 너비: 해당 탭의 글자의 너비에 맞게
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: TabBarView(
            children: [
              Calendar(SingleGoals, SingleGoalsMap),      //개인 캘린더
              Calendar(eventsList, AllGoalsMap),          //개인&공동 캘린더
              Calendar(TogetherGoals, TogetherGoalsMap),  //공동 캘린더
            ],
          ),
        ),

        //이벤트(목표) 추가 버튼
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: SizedBox(
            width: 45,
            height: 45,
            child:FloatingActionButton(
              backgroundColor: PRIMARY_COLOR,
              onPressed: () async{
                // 목표 설정에서 반환되는 값은 Event객체
                final newGoal = await showModalBottomSheet<Event>(
                    context: context,
                    isScrollControlled: true,
                  builder: (context) => ScheduleBottomSheet(),
                );

                if(newGoal != null){
                  await _calendarService.addGoalWithTodos(newGoal); // DB 저장
                  await _loadEvents(); // 목록 새로고침
                }
              },
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget Calendar (List<Event> list, Map<DateTime,List<Event>> map){
    return //기기의 하단 메뉴바 같은 시스템 UI를 피해서 구현
      SafeArea(
        //달력과 목표/계획의 리스트를 세로로 배치
      child: Stack(
        children: [
          //'main_calender.dart'의 MainCalendar 위젯 배치
          MainCalendar(
            onDaySelected: (selectedDay, focusedDay) {  //날짜 선택 시 실행할 함수
              setState(() {                             //상태 변경을 알리고 rebuild
                selectedDate = selectedDay;
              });
            },
            selectedDate: selectedDate,                 //선택된 날짜
            events: map,                          //각 탭에 해당되는 목표 데이터
          ),

          //Prints 위젯 배치
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.1,  //화면의 초기 크기
              minChildSize: 0.1,      //최소 크기
              maxChildSize: 0.9,        //최대 크기
              builder: (context,scrollController)=>Prints(
                selectedDate: selectedDate,           //선택된 날짜
                eventsMap: map,                 //날짜 별로 이벤트를 저장한 저장소
                scrollController: scrollController,
                onPlanUpdated: (Event event) async {
                  await _calendarService.updateGoal(event);
                  await _loadEvents();
                },

                //[이벤트 삭제, 계획 추가/삭제/수정] 명령 함수 => (이벤트 객체, {계획 객체,계획삭제여부(기본 F), 이벤트삭제여부(기본 F)})
                adddel: (Event event,{Plan? plan, bool removePlan=false ,bool removeEvent=false}) async {
                  if(removeEvent){
                    // 이벤트 삭제
                    if (event.id != null) {
                      await _calendarService.deleteGoal(event.id!);
                    }
                  } else if(removePlan && plan != null){
                    // 계획 삭제
                    event.plans.remove(plan);
                    await _calendarService.updateGoal(event);
                  } else if(plan != null){
                    // 계획 추가/수정
                    event.plans.add(plan);
                    await _calendarService.updateGoal(event);
                  }
                  // 작업 후 새로고침
                  await _loadEvents();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}