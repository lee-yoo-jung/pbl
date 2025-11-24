import 'package:pbl/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/tap/calender/component/detailplan.dart';
import 'package:pbl/tap/calender/component/schedule_bottom_sheet.dart';

/*<이벤트와 이벤트 속 계획 리스트를 출력>
<이벤트 삭제와 계획 추가/삭제를 할 수 있는 로직>*/

class Prints extends StatefulWidget{
  final DateTime selectedDate;                //선택된 날짜
  final Map<DateTime, List<Event>> eventsMap; //기간 저장소
  final Function(Event,{Plan? plan,bool removePlan ,bool removeEvent}) adddel;  //이벤트 삭제, 계획 추가/삭제 명령 함수
  final ScrollController? scrollController;
  final Function(Event event) onPlanUpdated;

  //매개변수
  const Prints({
    required this.selectedDate,
    required this.eventsMap,
    required this.adddel,
    required this.onPlanUpdated,
    this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  State<Prints> createState()=>PrintsState();
}

class PrintsState extends State<Prints>{

  //시간 제거해서 날짜 형식 통일
  DateTime getDateKey(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context){
    final events = widget.eventsMap[getDateKey(widget.selectedDate)] ?? [];

    return Container( //아래 스크롤 공간
      decoration: BoxDecoration(
        color: DARK_BLUE,
        borderRadius: const BorderRadius.only(
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
                margin: const EdgeInsets.symmetric(horizontal: 185, vertical: 7),
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }

            final event = events[index-1];  //이벤트

            //목표 공간을 한번 눌렀을 때, 계획 추가
            return GestureDetector(
              onTap: () async {
                //새 페이지에서 반환되는 값은 Plan객체
                final updatedPlan = await Navigator.push<Plan>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Detailplan(
                        event: event,
                        initialDate: widget.selectedDate
                    ),
                  ),
                );

                if (updatedPlan != null) {
                  widget.adddel(event, plan:updatedPlan);
                }
              },

              //목표 공간을 길게 눌렀을 때, 목표 삭제
              onLongPress: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context){
                    //목표 삭제 여부 확인
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      actionsAlignment: MainAxisAlignment.center,
                      icon: Icon(
                        Icons.warning_rounded,
                        color: Colors.red[700],
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black45,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      title: const Text(
                        '목표 삭제',
                        style: TextStyle(
                          fontFamily: "Pretendard",
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      content: Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: '목표를 영구히 삭제하시겠습니까?\n',
                              style: TextStyle(
                                fontFamily: "Pretendard",
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: '삭제된 목표는 되돌리거나\n복구할 수 없습니다.',
                              style: TextStyle(
                                fontFamily: "Pretendard",
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      actions: [
                        //그냥 닫기
                        ElevatedButton(
                          onPressed: (){ Navigator.of(context).pop(); },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.black87,
                            elevation: 2,
                          ),
                          child: const Text(
                            '삭제 취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        //목표 삭제 후, 다이얼로그 닫기
                        ElevatedButton(
                          onPressed: () {
                            widget.adddel(event, removeEvent: true);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[500],
                            foregroundColor: Colors.white,
                            elevation: 4,
                          ),
                          child: const Text(
                            '목표 삭제', // 명확한 텍스트
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },


              //목표(이벤트)출력
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 17.0),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10)
                ),

                //[목표의 이름과 기간],[목표에 대한 계획]을 컨테이너 안에 세로로 배치
                child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
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
                              color: Colors.black
                          ),
                          softWrap: true,
                        ),

                        Text(
                          (event.description.isEmpty) ?
                          "": "#${event.description}",
                          style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black
                          ),
                          softWrap: true,
                        ),

                        Text(
                          (event.secret) ?
                          "비공개": "공개",
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black
                          ),
                          softWrap: true,
                        ),
                        Text( //목표의 기간
                          "${event.startDate.year}-${event.startDate.month}-${event.startDate.day} ~ ${event.endDate.year}-${event.endDate.month}-${event.endDate.day}",
                          style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

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

                          final timeStr =
                              "${plan.selectdate.hour.toString().padLeft(2, '0')}:${plan.selectdate.minute.toString().padLeft(2, '0')}";

                          //계획의 날짜와 시간, 체크박스를 가로로 배치
                          return AbsorbPointer(
                            absorbing: plan.isDone,
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,  //균등하게 배치
                                children: [
                                  GestureDetector(
                                    //목표 공간을 길게 눌렀을 때, 계획 삭제
                                    onLongPress:(){
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context){
                                          return AlertDialog(
                                            title: const Text('계획 삭제'),
                                            content: const Text('이 계획을 삭제하시겠습니까?'),
                                            actions: [
                                              TextButton(onPressed: (){
                                                Navigator.of(context).pop();
                                              }, child: const Text('취소'),
                                              ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: plan.isDone ? DARK_BLUE: Colors.white ,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: DARK_BLUE.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),

                                      child: Text(
                                        "$timeStr | ${plan.text}",
                                        style: const TextStyle(
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
                                    scale:1.6,
                                    child: Checkbox(
                                      value: plan.isDone,

                                      onChanged: (tf) {
                                        if(tf==true){
                                          showDialog(
                                            context: context,
                                            builder: (_)=>AlertDialog(
                                              title: const Text('수행 확인'),
                                              content: const Text('완료하셨나요?'),
                                              actions: [
                                                //계획 체크 후, 다이얼로그 닫기
                                                TextButton(onPressed: (){
                                                  setState(() {
                                                    plan.isDone = true; // 상태 변경
                                                    widget.onPlanUpdated(event); // DB 업데이트 요청
                                                  });
                                                  Navigator.of(context).pop();
                                                }, child: const Text('확인'),
                                                ),

                                                TextButton(onPressed: (){
                                                  // 자동으로 체크를 해제하기
                                                  setState(() {
                                                    plan.isDone = false;
                                                  });
                                                  Navigator.of(context).pop();
                                                }, child: const Text('취소'),
                                                ),

                                              ],
                                            ),
                                          );
                                        } else {
                                          setState(() {
                                            plan.isDone = false;
                                            widget.onPlanUpdated(event);
                                          });
                                        }
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      //테두리 색/두께
                                      side: BorderSide(
                                        color: DARK_BLUE.withOpacity(0.3),
                                        width: 0.7,
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
                              ),
                            ),
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