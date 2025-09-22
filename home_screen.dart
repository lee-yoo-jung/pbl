import 'package:flutter/material.dart';
import 'package:calendar_scheduler/component/main_calender.dart';
import 'package:calendar_scheduler/component/selectday_banner.dart';
import 'package:calendar_scheduler/component/schedule_bottom_sheet.dart';
import 'package:calendar_scheduler/component/prints.dart';
import 'package:calendar_scheduler/const/colors.dart';
import 'package:calendar_scheduler/component/event.dart';

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

  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    generateGoals();  //eventsMap 초기화
  }

  //모든 이벤트를 날짜별로 나눠서 eventsMap에 저장
  void generateGoals() {
    eventsMap.clear();  //eventsMap을 깨끗이 처리

    //사용자의 이벤트 리스트를 순회
    for (var event in eventsList) {
      DateTime current = event.startDate; //각 이벤트의 startDate(시작 날짜)를 current로 설정
      //endDate(종료 날짜)까지 하루씩 반복
      while (!current.isAfter(event.endDate)) {
        final key = _getDateKey(current);         //current를 통일된 형식으로 key에 저장

        //key가 없다면 초기화
        if (!eventsMap.containsKey(key)) {
          eventsMap[key] = [];
        }
        eventsMap[key]!.add(event);                 //위의 key를 eventsMap 인덱스로 사용해 이벤트를 값으로 저장
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
        toolbarHeight: 45.0,  //앱바의 높이 지정
      ),

      body: SafeArea(       //기기의 하단 메뉴바 같은 시스템 UI를 피해서 구현
          child: Column(    //달력과 선택된 날짜의 배너,목표/계획의 리스트를 세로로 배치
            children: [
              Expanded(                   //최대 사이즈까지 확장
                child: MainCalendar(      //'main_calender.dart'의 MainCalendar 위젯 배치
                  onDaySelected: (selectedDay, focusedDay) {  //날짜 선택 시 실행할 함수
                    setState(() {         //상태 변경을 알리고 rebuild
                      selectedDate = selectedDay;
                    });},
                  selectedDate: selectedDate,                 //선택된 날짜
                  events: eventsList,                         //사용자의 목표=Event 객체 리스트
                ),
              ),

              SizedBox(height: 1.0),   //캘린더와 날짜 배너의 간격
              //배너 추가하기
              SelectdayBanner(
                selectedDate: selectedDate, //선택된 날짜
              ),

              Expanded(
                //Prints 위젯 배치
                child: Prints(
                  selectedDate: selectedDate, //선택된 날짜
                  eventsMap: eventsMap,       //날짜 별로 이벤트를 저장한 저장소

                  //이벤트 삭제, 계획 추가/삭제 명령 함수 => 이벤트 객체, {계획 객체,계획삭제여부(기본 F), 이벤트삭제여부(기본 F)}
                  adddel: (Event event,{Plan? plan, bool removePlan=false ,bool removeEvent=false}) {
                    setState(() {                   //상태 변경을 알리고 rebuild

                      if(removeEvent){              //이벤트 삭제 여부가 True로, 이벤트(목표) 삭제
                        eventsList.remove(event);
                      }else if(removePlan){         //계획 삭제 여부가 True로, 계획 삭제
                        event.plans.remove(plan);
                      }else if(plan!=null){         //계획이 입력으로 들어오면, Event객체에 plan 추가
                        event.plans.add(plan);
                      }
                      generateGoals();          //이벤트 리스트가 다시 조회할 수 있도록 제생성
                    });
                  },
                ),
              ),
              SizedBox(height: 8.0),  //여러 이벤트의 간격 설정
            ],
          )
      ),

      //이벤트(목표) 추가 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: PRIMARY_COLOR,
        onPressed: () async{  //눌렀을 때 실행
          //모달 시트에서 반환되는 값을 Event객체로 newGoal에 저장됨
          final newGoal= await showModalBottomSheet<Event>(
            context: context,                         //빌드할 컨텐츠
            isDismissible: true,                      //배경 탭했을 때 BottomSheet 닫기
            builder: (_) => ScheduleBottomSheet(),    //ScheduleBottomSheet페이지를 (슬라이드처럼 올라오는) 모달 시트로 빌드
            isScrollControlled: true,                 //스크롤 가능
          );

          //위의 newGoal에 값이 있다면. Event 객체 리스트의 이벤트에 추가한 뒤, 재생성
          if(newGoal!=null){
            setState(() {
              eventsList.add(newGoal);
              generateGoals();
            });
          }
        },
        //이벤트(목표) 추가 버튼의 아이콘
        child: Icon(
          Icons.add,
        ),
      ),
    );
  }
}

