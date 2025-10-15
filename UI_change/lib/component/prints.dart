import 'package:calendar_scheduler/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:calendar_scheduler/component/event.dart';
import 'package:calendar_scheduler/component/detailplan.dart';
import 'package:calendar_scheduler/component/schedule_bottom_sheet.dart';

/*<이벤트와 이벤트 속 계획 리스트를 출력>
<이벤트 삭제와 계획 추가/삭제를 할 수 있는 로직>*/

class Prints extends StatefulWidget{
  final DateTime selectedDate;                //선택된 날짜
  final Map<DateTime, List<Event>> eventsMap; //기간 저장소
  final Function(Event,{Plan? plan,bool removePlan ,bool removeEvent}) adddel;  //이벤트 삭제, 계획 추가/삭제 명령 함수
  final ScrollController? scrollController;

  //매개변수
  const Prints({
    required this.selectedDate,
    required this.eventsMap,
    required this.adddel,
    this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  State<Prints> createState()=>PrintsState();
}

class PrintsState extends State<Prints>{
  Map<Plan,bool> checked={};  //체크박스

  //시간 제거해서 날짜 형식 통일
  DateTime getDateKey(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context){
    final events = widget.eventsMap[getDateKey(widget.selectedDate)] ?? [];  //선택한 날짜를 key로 사용해서 이벤트 리스트를 가져오고, 없으면 빈 리스트로 처리

    return Container( //아래 스크롤 공간
      decoration: BoxDecoration(
        color: DARK_BLUE,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),

      //스크롤 핸들, 이벤트(계획들) 리스트 뷰
      child:ListView.builder(
          controller: widget.scrollController,
          itemCount: events.length+1,     //스크롤 핸들 포함: +1
          itemBuilder: (context,index){
            if (index == 0) {
              // 스크롤 핸들
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 185, vertical: 7),
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }

            final event=events[index-1];  //스크롤 핸들 불포함=이벤트(계획)

            //목표 공간을 한번 눌렀을 때, 계획 추가
            return GestureDetector(
              onTap: () async {
                //새 페이지에서 반환되는 값은 Plan객체로 updatedPlan에 저장됨
                final updatedPlan = await Navigator.push<Plan>(
                  context,
                  //지정된 이벤트와 선택된 날짜를 Datailplan 페이지로 이동
                  MaterialPageRoute(
                    builder: (context) => Detailplan(
                        event: event,
                        initialDate:widget.selectedDate),
                  ),
                );
                //반환된 updatedPlan이 null이 아니라면, 지정된 이벤트와 계획을 전달=추가
                if (updatedPlan != null) {
                  widget.adddel(event,plan:updatedPlan);
                }
              },

              //목표 공간을 길게 눌렀을 때, 목표 삭제
              onLongPress: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context){
                    //목표 삭제 여부 확인
                    return AlertDialog(
                      title: const Text('목표 삭제'),
                      content: const Text('이 목표를 삭제하시겠습니까?'),
                      actions: [
                        //그냥 닫기
                        TextButton(onPressed: (){Navigator.of(context).pop();
                        }, child: const Text('취소'),
                        ),
                        //목표 삭제 후, 다이얼로그 닫기
                        TextButton(onPressed: (){
                          widget.adddel(event, removeEvent: true);
                          Navigator.of(context).pop();
                        }, child: const Text('확인'),
                        ),
                      ],
                    );
                  },
                );
              },


              //목표(이벤트)출력
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 17.0), //컨테이너의 테두리와 화면의 여백 설정
                padding: EdgeInsets.all(5.0),                                   //컨테이너의 테두리와 내용의 여백 설정
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10)
                ),

                //[목표의 이름과 기간],[목표에 대한 계획]을 컨테이너 안에 세로로 배치
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,          //내용을 왼쪽으로 붙이기
                  children: [
                    // 목표의 이름과 기간, 계획 추가버튼 가로로 배치
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,  //균등하게 배치
                      children: [
                        Text( //목표의 이름
                          (event.togeter.isEmpty) ?
                          "\t${event.title}": "\t${event.title} \n with ${event.togeter.join(",")}",
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white
                          ),
                          softWrap: true, //자동 줄바꿈
                        ),
                        Text( //해시태그 있으면 추가
                          (event.hashtags.isEmpty) ?
                          "": "#${event.hashtags}",
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white
                          ),
                          softWrap: true, //자동 줄바꿈
                        ),
                        Text( //공개/비공개 여부
                          (event.secret==true) ?
                          "비공개": "공개",
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white
                          ),
                          softWrap: true, //자동 줄바꿈
                        ),
                        Text( //목표의 기간
                          "${event.startDate.year}-${event.startDate.month}-${event.startDate.day} ~ ${event.endDate.year}-${event.endDate.month}-${event.endDate.day}",
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),  //위 가로로 배치한 컨테이너와 계획 부분의 간격

                    // 지정된 event 안의 plan이 비어있지 않은 경우
                    if (event.plans.isNotEmpty)
                    //목표의 계획을 세로로 배치
                      Column(
                        children: event.plans //지정된 event의 계획들.
                        //이것의 계획이 비어있지 않고, 선택한 날짜와 계획의 날짜가 같다면
                            .where((plan) =>
                        widget.selectedDate != null && plan.selectdate.year == widget.selectedDate!.year &&plan.selectdate.month == widget.selectedDate!.month &&plan.selectdate.day == widget.selectedDate!.day)
                        //계획의 날짜와 시간을 "YYYY-MM-DD"(dateStr)와 "HH:MM"(timeStr)로 바꾸기
                            .map((plan) {
                          checked.putIfAbsent(plan, ()=>false); //초기값은 false
                          final dateStr =
                              "${plan.selectdate.year}-${plan.selectdate.month.toString().padLeft(2, '0')}-${plan.selectdate.day.toString().padLeft(2, '0')}";
                          final timeStr =
                              "${plan.selectdate.hour.toString().padLeft(2, '0')}:${plan.selectdate.minute.toString().padLeft(2, '0')}";

                          //계획의 날짜와 시간, 체크박스를 가로로 배치
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,  //균등하게 배치
                            children: [
                              GestureDetector(
                                //목표 공간을 길게 눌렀을 때, 계획 삭제
                                onLongPress:(){
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context){
                                      //계획 삭제 여부
                                      return AlertDialog(
                                        title: const Text('계획 삭제'),
                                        content: const Text('이 계획을 삭제하시겠습니까?'),
                                        actions: [
                                          //그냥 닫기
                                          TextButton(onPressed: (){
                                            Navigator.of(context).pop();
                                          }, child: const Text('취소'),
                                          ),
                                          //계획 삭제후, 다이얼로그 닫기
                                          TextButton(onPressed: (){
                                            widget.adddel(event, plan:plan, removePlan: true);
                                            Navigator.of(context).pop();
                                          }, child: const Text('확인'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },

                                //계획 컨테이너
                                child: Container(
                                  width: 300,
                                  height: 31,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), // 안쪽 여백
                                  decoration: BoxDecoration(
                                    color: Colors.white,                 // 배경색
                                    border: Border.all(color: Colors.transparent),  // 테두리 투명
                                    borderRadius: BorderRadius.circular(8),  // 모서리 둥글게
                                  ),

                                  child: Text(
                                    "$dateStr $timeStr | ${plan.text}",
                                    style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black
                                    ),
                                  ),
                                ),
                              ),


                              //체크박스
                              Transform.scale(    //크기 조정
                                scale:1.5,
                                child: Checkbox(
                                  value: checked[plan],
                                  onChanged: (tf) {
                                    setState(() {
                                      checked[plan] = tf!;          // 값 변경 시 상태 업데이트
                                    });
                                  },
                                  //모서리 둥글게
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  //테두리 색/두께
                                  side: const BorderSide(
                                    color: Colors.transparent, // 테두리 투명
                                    width: 1,
                                  ),

                                  fillColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states){
                                        if(states.contains(MaterialState.selected)){
                                          return PRIMARY_COLOR; //체크될 때,색
                                        }
                                        return Colors.white;   //체크 표시 색
                                      }
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
