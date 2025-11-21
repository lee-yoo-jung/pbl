import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/main_calender.dart';
import 'package:pbl/tap/calender/component/schedule_bottom_sheet.dart';
import 'package:pbl/tap/calender/component/prints.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';

//<메인 화면(캘린더) 구상>

class Calenderview extends StatefulWidget{
  const Calenderview({Key? key}):super(key:key);

  @override
  State<Calenderview> createState()=>_CalenderviewState();
}

class _CalenderviewState extends State<Calenderview>{
  Map<Plan, bool> checked = {}; //체크박스

  //선택된 날짜를 관리할 변수
  DateTime selectedDate=DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Map<DateTime,List<Event>> eventsMap={}; //날짜 별로 이벤트를 저장한 저장소

  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    generateGoals(eventsList);  //eventsMap 초기화
  }

  //모든 이벤트를 날짜별로 나눠서 eventsMap에 저장
  Map<DateTime,List<Event>> generateGoals(List<Event> events) {
    final Map<DateTime, List<Event>> map={};

    //사용자의 이벤트 리스트를 순회
    for (var event in events) {
      DateTime current = event.startDate;           //각 이벤트의 startDate(시작 날짜)를 current로 설정
      //endDate(종료 날짜)까지 하루씩 반복
      while (!current.isAfter(event.endDate)) {
        final key = DateTime(current.year,current.month,current.day);         //current를 통일된 형식으로 key에 저장

        //key가 없다면 초기화
        if (!map.containsKey(key)) {
          map[key] = [];
        }
        map[key]!.add(event);                 //위의 key를 eventsMap 인덱스로 사용해 이벤트를 값으로 저장
        current = current.add(const Duration(days: 1));
      }
    }
    return map;
  }


  @override
  Widget build(BuildContext context) {

    final TogetherGoals=eventsList.where((goal)=> (goal.togeter?.isNotEmpty?? false)).toList();
    final SingleGoals=eventsList.where((goal)=> !(goal.togeter?.isNotEmpty?? false)).toList();

    final TogetherGoalsMap=generateGoals(TogetherGoals);
    final SingleGoalsMap=generateGoals(SingleGoals);
    final AllGoalsMap=generateGoals(eventsList);

    return DefaultTabController(
      length: 3,
      child: Scaffold(  //상단 앱바
        appBar: AppBar(
          backgroundColor: Colors.white,
          //가로로 배치
          title: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: PRIMARY_COLOR,
              ),
              SizedBox(width: 8),
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
                // 목표 설정에서 반환되는 값은 Event객체로 newGoal에 저장됨
                final newGoal= await showModalBottomSheet<Event>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => ScheduleBottomSheet(), // 기존 바텀시트 위젯
                );
                //위의 newGoal에 값이 있다면, Event 객체 리스트의 이벤트에 추가한 뒤, 재생성
                if(newGoal!=null){
                  setState(() {
                    eventsList.add(newGoal);
                    generateGoals(eventsList);
                  });
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
                  checked:checked,  //체크 여부
                  //체크 여부 동기화 함수
                  onChecked:(plan,value){
                    setState(() {
                      checked[plan]=value;
                    });
                  },

                  //[이벤트 삭제, 계획 추가/삭제/수정] 명령 함수 => (이벤트 객체, {계획 객체,계획삭제여부(기본 F), 이벤트삭제여부(기본 F)})
                  adddel: (Event event,{Plan? plan, bool removePlan=false ,bool removeEvent=false}) {
                    setState(() {                                 //상태 변경을 알리고 rebuild
                      if(removeEvent){                              //이벤트 삭제 여부가 True로, 이벤트(목표) 삭제
                        eventsList.remove(event);
                      }else if(removePlan&&plan!=null){             //계획 삭제 여부가 True로, 계획 삭제
                        event.plans.remove(plan);
                      }else if(plan!=null){                        //계획이 입력으로 들어오면, Event객체에 plan 추가/수정
                        event.plans.add(plan);
                      }
                      generateGoals(eventsList);                            //이벤트 리스트를 다시 조회할 수 있도록 제생성
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      );
  }
}