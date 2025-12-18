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
import 'package:badges/badges.dart' as badges;
import 'package:pbl/tap/calender/component/alarm_notifer.dart';


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
  DateTime selectedDate = DateTime.utc(
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
      if (mounted) setState(() => _isLoading = false);
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

              ValueListenableBuilder<int>(
                valueListenable: alarmCountNotifier,
                builder: (context, count, _) {
                  return badges.Badge(
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: Colors.redAccent
                    ),
                    position: badges.BadgePosition.topEnd(
                      top: 5,
                      end: -2,
                    ),
                    showBadge: count > 0,
                    badgeContent: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications,size: 25,color: POINT_COLOR,),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlarmList()),
                        );
                      },
                    ),
                  );
                },
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
                indicatorSize: TabBarIndicatorSize.label, //선택된 탭 아래 막대의 너비
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
                final newGoal = await showModalBottomSheet<Event>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  builder: (context) => ScheduleBottomSheet(),
                );

                if(newGoal != null){
                  await _calendarService.addGoalWithTodos(newGoal);
                  await _loadEvents();
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
    return SafeArea(
      //달력과 목표/계획의 리스트를 세로로 배치
      child: Stack(
        children: [
          MainCalendar(
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                selectedDate = selectedDay;
              });
            },
            selectedDate: selectedDate,
            events: map,
          ),

          //Prints 위젯 배치
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.1,  //화면의 초기 크기
              minChildSize: 0.1,      //최소 크기
              maxChildSize: 0.9,      //최대 크기
              builder: (context,scrollController)=>Prints(
                selectedDate: selectedDate,
                eventsMap: map,
                scrollController: scrollController,

                onPlanUpdated: (Event event) async {
                  // DB 업데이트
                  await _calendarService.updateGoal(event);

                  // 뱃지 & 레벨업 로직
                  if (context.mounted && event.id != null) {

                    // 공유 목표인지 확인
                    bool isShared = event.togeter.isNotEmpty;

                    // 꾸준이
                    await BadgeService().checkSteadyBadge(context, event.id!, !isShared);

                    // 성실이
                    int total = event.plans.length;
                    int done = event.plans.where((p) => p.isDone).length;

                    if (total > 0) {
                      double rate = done / total;
                      await BadgeService().checkSincereBadge(context, rate);
                    }

                    // 경험치 지급
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
                      bool isShared = event.togeter.isNotEmpty;
                      await _calendarService.deletePlan(plan.id!, isShared: isShared);
                    }
                    event.plans.remove(plan);
                  }

                  // 세부 계획(Plan) 추가
                  else if (plan != null) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    // 목표 종료일 체크
                    if (event.endDate.isBefore(today)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("기간이 종료된 목표에는 계획을 추가할 수 없습니다."),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                      return;
                    }

                    // 기간 문제 없으면 추가
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