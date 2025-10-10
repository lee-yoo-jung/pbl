import 'package:flutter/material.dart';
import 'package:calendar_scheduler/component/main_calender.dart';
import 'package:calendar_scheduler/component/schedule_bottom_sheet.dart';
import 'package:calendar_scheduler/component/prints.dart';
import 'package:calendar_scheduler/const/colors.dart';
import 'package:calendar_scheduler/component/event.dart';
import 'package:calendar_scheduler/services/supabase_calendar_service.dart';

//<메인 화면(캘린더) 구상>

class HomeScreen extends StatefulWidget{
  const HomeScreen({Key? key}):super(key:key);

  @override
  State<HomeScreen> createState()=>_HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{

  //선택된 날짜를 관리할 변수
  DateTime selectedDate=DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Map<DateTime,List<Event>> eventsMap={}; //날짜 별로 이벤트를 저장한 저장소
  List<Event> allEvents = []; // 2. DB에서 가져온 모든 이벤트를 저장할 리스트
  final calendarService _calendarService = calendarService(); // 3. 서비스 인스턴스 생성
  bool _isLoading = true; // 4. 로딩 상태 변수

  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    _loadEventsFromDB();  //eventsMap 초기화
  }

  // DB에서 이벤트를 비동기로 가져오는 함수
  Future<void> _loadEventsFromDB() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    allEvents = await _calendarService.getGoals();
    _populateEventsMap(); // 가져온 데이터로 eventsMap 채우기

    setState(() {
      _isLoading = false; // 로딩 끝
    });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //상단 앱바
      appBar: AppBar(
        backgroundColor: PRIMARY_COLOR,
        //가로로 배치
        title: Row(
          children: [
            IconButton(
              onPressed: null,
              icon: Icon(Icons.calendar_month_rounded,  //아이콘 모양
                size: 35,             //아이콘 크기
                color: Colors.white,  //아이콘 색상
              ),
            ),
            Text("내캘린더",
              style: TextStyle(
                  color:Colors.white
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: null,
              icon: Icon(Icons.notifications,
                size: 25,
                color: Colors.white,
              ),
            ),
          ],
        ),
        toolbarHeight: 50.0,  //앱바의 높이 지정
      ),

      //기기의 하단 메뉴바 같은 시스템 UI를 피해서 구현
      body: SafeArea(

        //달력과 목표/계획의 리스트를 세로로 배치
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // 6. 로딩 중일 때 인디케이터 표시
            : Column(
          children: [
            //'main_calender.dart'의 MainCalendar 위젯 배치
            MainCalendar(
              onDaySelected: (selectedDay, focusedDay) {  //날짜 선택 시 실행할 함수
                setState(() {                             //상태 변경을 알리고 rebuild
                  selectedDate = selectedDay;
                });
              },
              selectedDate: selectedDate,                 //선택된 날짜
              events: eventsMap,                          //사용자의 목표=Event 객체 리스트
            ),

            //Prints 위젯 배치
            Expanded(
              child: DraggableScrollableSheet(
                initialChildSize: 0.1,  //화면의 초기 크기
                minChildSize: 0.1,      //최소 크기
                maxChildSize: 1,        //최대 크기
                builder: (context,scrollController)=>Prints(
                  selectedDate: selectedDate,           //선택된 날짜
                  eventsMap: eventsMap,                 //날짜 별로 이벤트를 저장한 저장소

                  scrollController: scrollController,

                  //[이벤트 삭제, 계획 추가/삭제/수정] 명령 함수 => (이벤트 객체, {계획 객체,계획삭제여부(기본 F), 이벤트삭제여부(기본 F)})
                  adddel: (Event event,{Plan? plan, bool removePlan=false ,bool removeEvent=false}) async {
                    if (removeEvent) {
                      if (event.id != null) {
                        await _calendarService.deleteGoal(event.id!);
                        _loadEventsFromDB();
                      }
                    }
                  },
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
          width: 50,
          height: 50,

          child:FloatingActionButton(
            backgroundColor: PRIMARY_COLOR,
            onPressed: () async{
              //(슬라이드처럼 올라오는) 모달 시트에서 반환되는 값은 Event객체로 newGoal에 저장됨
              final newGoal= await showModalBottomSheet<Event>(
                context: context,                         //빌드할 컨텐츠
                isDismissible: true,                      //배경 탭했을 때 BottomSheet 닫기
                builder: (_) => ScheduleBottomSheet(),    //ScheduleBottomSheet페이지를 모달 시트로 빌드
                isScrollControlled: true,                 //스크롤 가능
              );

              if (newGoal != null) {
                final addedGoal = await _calendarService.addGoal(newGoal);
                if (addedGoal != null) {
                  _loadEventsFromDB(); // 추가 후 데이터 다시 로드
                }
              }
            },
            shape: const CircleBorder(),  //둥근 모양

            //이벤트(목표) 추가 버튼의 아이콘
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