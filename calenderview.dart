import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/main_calender.dart';
import 'package:pbl/tap/calender/component/schedule_bottom_sheet.dart';
import 'package:pbl/tap/calender/component/prints.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/tap/calender/component/alarm.dart';
import 'package:pbl/services/supabase_calendar_service.dart';
import 'package:pbl/tap/calender/board/board_page.dart';
import 'package:pbl/services/badge_service.dart';
import 'package:pbl/services/level_service.dart';

//<메인 화면(캘린더) 구상>

class Calenderview extends StatefulWidget{
  const Calenderview({Key? key}):super(key:key);

  @override
  State<Calenderview> createState()=>_CalenderviewState();
}

class _CalenderviewState extends State<Calenderview>{
  final CalendarService _calendarService = CalendarService();
  List<Event> eventsList = [];
  bool _isLoading = false;


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
    // 로딩 중 표시 (데이터가 없을 때만)
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
                onPressed:(){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=> BoardPage()),
                  );
                },
                icon: Icon(Icons.event_note_rounded, size: 25,color: POINT_COLOR,
                ),
              ),
              SizedBox(width: 5),

              IconButton(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=> AlarmList()),
                  );
                },
                icon: Icon(Icons.notifications,
                  size: 25,
                  color: POINT_COLOR,
                ),
              ),
            ],
          ),
          toolbarHeight: 40.0,  //앱바의 높이 지정
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
                indicatorColor: PRIMARY_COLOR, //선택된 탭 아래 막대 색상
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
          padding: const EdgeInsets.only(bottom: 100),
          child: SizedBox(
            width: 45,
            height: 45,
            child:FloatingActionButton(
              backgroundColor: PRIMARY_COLOR,
              onPressed: () async{
                // 목표 설정에서 반환되는 값은 Event객체로 newGoal에 저장됨
                final newGoal = await showModalBottomSheet<Event>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  builder: (context) => ScheduleBottomSheet(), // 기존 바텀시트 위젯
                );

                if(newGoal != null){
                  await _calendarService.addGoalWithTodos(newGoal);
                  await _loadEvents();
                }
              },
              shape: const CircleBorder(),  //둥근 모양
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
    return SafeArea(
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
                  // DB 업데이트
                  await _calendarService.updateGoal(event);

                  // 뱃지 & 레벨업 로직
                  if (context.mounted && event.id != null) {

                    // 꾸준이 & 성실이 체크
                    await BadgeService().checkSteadyBadge(context, event.id!);

                    int total = event.plans.length;
                    int done = event.plans.where((p) => p.isDone).length;

                    if (total > 0) {
                      double rate = done / total;
                      await BadgeService().checkSincereBadge(context, rate);
                    }

                    bool isShared = event.togeter.isNotEmpty;

                    // 사진 인증 여부
                    bool hasPhoto = false;

                    await LevelService().grantExpForPlanCompletion(
                        context,
                        goalId: event.id!,
                        isPhotoVerified: hasPhoto,
                        isSharedGoal: isShared
                    );
                  }

                  // 화면 갱신
                  await _loadEvents();
                },

                adddel: (Event event, {Plan? plan, bool removePlan = false, bool removeEvent = false}) async {

                  // 목표(Event) 자체 삭제
                  if (removeEvent) {
                    if (event.id != null) {
                      await _calendarService.deleteGoal(event.id!);
                    }
                  }

                  // 세부 계획(Plan) 삭제
                  else if (removePlan && plan != null) {

                    if (plan.id != null) {
                      // 공유 목표인지 확인 (togeter 리스트가 있으면 공유 목표)
                      bool isShared = event.togeter.isNotEmpty;

                      await _calendarService.deletePlan(plan.id!, isShared: isShared);
                    }

                    event.plans.remove(plan);

                  }
                  // 세부 계획(Plan) 추가 시도
                  else if (plan != null) {

                    // 날짜 비교 로직 추가
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    // 목표의 종료일(endDate)과 오늘을 비교
                    // endDate가 오늘보다 이전이면(과거라면) 추가 금지
                    if (event.endDate.isBefore(today)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("기간이 종료된 목표에는 계획을 추가할 수 없습니다."),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.redAccent, // 경고 느낌을 위해 빨간색 추천
                          ),
                        );
                      }
                      return; // 여기서 함수 강제 종료
                    }

                    // 기간이 지나지 않았다면 정상적으로 추가 진행
                    event.plans.add(plan);
                    await _calendarService.updateGoal(event);
                  }

                  await _loadEvents(); // 목록 갱신
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}