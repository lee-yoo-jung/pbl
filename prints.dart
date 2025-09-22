import 'package:flutter/material.dart';
import 'package:calendar_scheduler/component/detailplan.dart';
import 'package:calendar_scheduler/component/event.dart';

/*<이벤트와 이벤트 속 계획 리스트를 출력>
<이벤트 삭제와 계획 추가/삭제를 할 수 있는 로직>*/

class Prints extends StatelessWidget{
  final DateTime selectedDate;                //선택된 날짜
  final Map<DateTime, List<Event>> eventsMap; //기간 저장소
  final Function(Event,{Plan? plan,bool removePlan ,bool removeEvent}) adddel;  //이벤트 삭제, 계획 추가/삭제 명령 함수

  //매개변수
  const Prints({
    required this.selectedDate,
    required this.eventsMap,
    required this.adddel,
    Key? key,
  }) : super(key: key);

  //시간 제거해서 날짜 형식 통일
  DateTime _getDateKey(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context){
    final events = eventsMap[_getDateKey(selectedDate)] ?? [];  //선택한 날짜를 key로 사용해서 이벤트 리스트를 가져오고, 없으면 빈 리스트로 처리

    return
      ListView( // 캘린더 아래에 해당 기간의 목표 출력
        //날짜를 키로, 이벤트를 값을 설정한 events의 각각을 event로 설정해, 하나씩 실행
        children: events.map((event) => Container(
          margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0), //컨테이너의 테두리와 화면의 여백 설정
          padding: EdgeInsets.all(10.0),  //컨테이너의 테두리와 내용의 여백 설정

          //컨테이너의 디자인
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(5.0),
          ),

          //[목표의 이름과 기간, 계획 추가버튼],[목표와 목표 제거 버튼],[목표 제거 버튼]을 컨테이너 안에 세로로 배치
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, //내용을 왼쪽으로 붙이기
            children: [
              // 목표의 이름과 기간, 계획 추가버튼 가로로 배치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,  //균등하게 배치

                children: [
                  Expanded(
                    //목표의 이름과 기간
                    child: Text(
                      "${event.title}\n기간: ${event.startDate.year}-${event.startDate.month}-${event.startDate.day} ~ ${event.endDate.year}-${event.endDate.month}-${event.endDate.day}",
                      style: TextStyle(
                        fontSize: 18,),
                      ),
                    ),

                    //계획 추가 버튼
                    IconButton(
                      onPressed: () async { //버튼을 눌렀을 때

                        //새 페이지에서 반환되는 값을 Plan객체로 updatedPlan에 저장됨
                        final updatedPlan = await Navigator.push<Plan>(
                          context,
                          MaterialPageRoute(    //지정된 이벤트와 선택된 날짜를 Datailplan 페이지로 이동
                            builder: (context) => Detailplan(event: event, initialDate:selectedDate),
                          ),
                        );

                        //반환된 updatedPlan이 null이 아니라면, 지정된 이벤트와 계획을 전달=추가
                        if (updatedPlan != null) {
                          adddel(event,plan:updatedPlan);
                        }
                      },
                      icon: Icon(Icons.add, color: Colors.red),
                      iconSize: 30,
                    ),

                  ],
                ),

                SizedBox(height: 8),  //위 가로로 배치한 컨테이너와 계획 부분의 간격

                // 지정된 event 안의 plan이 비어있지 않은 경우
                if (event.plans.isNotEmpty)

                  //세로로 배치
                  Column(
                    children: event.plans //지정된 event의 계획들.
                    //이것의 계획이 비어있지 않고, 선택한 날짜와 계획의 날짜가 같다면
                  .where((plan) =>
                      selectedDate != null && plan.selectdate.year == selectedDate!.year &&plan.selectdate.month == selectedDate!.month &&plan.selectdate.day == selectedDate!.day)
                    //계획의 날짜와 시간을 "YYYY-MM-DD"(dateStr)와 "HH:MM"(timeStr)로 바꾸기
                        .map((plan) {
                       final dateStr =
                          "${plan.selectdate.year}-${plan.selectdate.month.toString().padLeft(2, '0')}-${plan.selectdate.day.toString().padLeft(2, '0')}";
                      final timeStr =
                          "${plan.selectdate.hour.toString().padLeft(2, '0')}:${plan.selectdate.minute.toString().padLeft(2, '0')}";

                      //계획의 날짜와 시간, 계획 제거 버튼을 가로로 배치
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,  //균등하게 배치
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0), //수직 여백
                            //계획 YYY-MM-DD HH:MM - 일정: plan
                            child: Text(
                              "계획 $dateStr $timeStr - 일정: ${plan.text}",
                              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                            ),
                          ),

                          //계획 삭제 버튼
                          IconButton(
                            icon: Icon(
                                Icons.dangerous,
                                size: 30,
                                color: Colors.red
                            ),
                            onPressed: () { //눌렀을 때, 계획 삭제 여부를 true로 바꾸고. 해당 이벤트와 계획을 전달=계획 삭제
                              adddel(event, plan:plan, removePlan: true);
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                //이벤트 삭제 버튼
                IconButton(
                  icon: Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red
                  ),
                  onPressed: () { //눌렀을 때, 이벤트 삭제 여부를 true로 바꾸고. 해당 이벤트를 전달=이벤트 삭제
                    adddel(event, removeEvent: true);
                  },
                ),
              ],
            ),
          ),).toList(), //이를 리스트로 설정
        );
  }
}