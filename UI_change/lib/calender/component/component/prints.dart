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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0), // 상하 여백 추가
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              );
            }

            final event=events[index-1];  //스크롤 핸들 불포함=이벤트(계획)

            //목표 공간을 한번 눌렀을 때, 계획 추가
            return GestureDetector(
              onTap: () async {
                //새 페이지에서 반환되는 값은 Plan객체로 updatedPlan에 저장됨
                final updatedPlan = await showDialog<Plan>(
                  context: context,
                  //지정된 이벤트와 선택된 날짜를 Datailplan 페이지로 이동
                  barrierDismissible: true, //배경탭 시, 닫기
                  builder: (_)=> Detailplan(event: event, initialDate: widget.selectedDate),
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
                      backgroundColor: Colors.white,
                      actionsAlignment: MainAxisAlignment.center,
                      icon: Icon(
                        Icons.warning_rounded,
                        color: Colors.red[700],
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.grey.withOpacity(0.5),
                            offset: Offset(1, 3),
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
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade600,
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
                            backgroundColor: PRIMARY_COLOR,
                            foregroundColor: Colors.black87,
                            elevation: 2,
                          ),
                          child: const Text(
                            '삭제 취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
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
                            backgroundColor: Color(0xFFFFDBDB),
                            foregroundColor: Colors.white,
                            elevation: 4,
                          ),
                          child: const Text(
                            '목표 삭제', // 명확한 텍스트
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFFF30404),
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
                margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 17.0), //컨테이너의 테두리와 화면의 여백 설정
                padding: EdgeInsets.all(5.0),                                   //컨테이너의 테두리와 내용의 여백 설정
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)
                ),

                //[목표의 이름과 기간],[목표에 대한 계획]을 컨테이너 안에 세로로 배치
                child: ListView(
                  shrinkWrap: true,     //자식의 크기에 맞춰 크기를 정함
                  physics: NeverScrollableScrollPhysics(), // List view 스크롤 가능 위젯 안에서 스크롤 중복 방지
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              SizedBox(width: 10),

                              // 목표 제목
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 이모지
                                  Text(
                                    event.emoji ?? '⭐', // 이모지가 null일 경우 '⭐'로 대체
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(width: 4), // 이모지와 제목 사이의 간격

                                  // 제목
                                  Expanded(
                                    child: Text(
                                      insertSpacesForWrapping(event.title, 60),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 공유 시 친구 목록
                              if (event.togeter.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    "with ${event.togeter.join(", ")}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: DARK_GREY_COLOR,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(width: 20),

                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.apple_rounded),
                          iconSize: 20,
                        ),

                        SizedBox(width: 10),

                        // 목표의 정보 출력
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  contentPadding: const EdgeInsets.all(16.0),
                                  backgroundColor: LIGHT_GREY_COLOR.withOpacity(0.8),

                                  // 다이얼로그의 내용
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min, // 내용 크기에 맞게 다이얼로그 크기 최소화
                                    crossAxisAlignment: CrossAxisAlignment.start, // 내용을 왼쪽 정렬
                                    children: [
                                      Text(
                                        '공개 범위',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: PRIMARY_COLOR,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text( // 공개/비공개 여부
                                        (event.secret == true) ? "비공개" : "공개",
                                        style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black
                                        ),
                                      ),

                                      const Divider(height: 20, thickness: 0.5),

                                      Text(
                                        '목표 기간',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: PRIMARY_COLOR,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text( // 목표의 기간
                                        // 날짜 포맷을 YYYY-MM-DD 형식으로 통일
                                        "${event.startDate.toString().split(' ')[0]} ~ ${event.endDate.toString().split(' ')[0]}",
                                        style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black
                                        ),
                                      ),

                                      const Divider(height: 20, thickness: 0.5), // 구분선

                                      Text(
                                        '공유 친구 (${event.togeter.length}명)',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: PRIMARY_COLOR,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // 친구 목록 표시 (쉼표로 구분)
                                      Text(
                                        (event.togeter.isNotEmpty)
                                            ? event.togeter.join(', ')
                                            : '공유된 친구 없음',
                                        style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black
                                        ),
                                        softWrap: true, // 자동 줄바꿈
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                  ),
                                );
                              },
                            );
                          },

                          // 툴팁을 트리거하는 아이콘
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: DARK_GREY_COLOR,
                          ),
                        ),
                        SizedBox(width: 10),
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
                        plan.selectdate.year == widget.selectedDate.year &&
                            plan.selectdate.month == widget.selectedDate.month &&
                            plan.selectdate.day == widget.selectedDate.day)
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
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      //목표 공간을 길게 눌렀을 때, 계획 삭제
                                      onLongPress:(){
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context){
                                            //계획 삭제 여부

                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              actionsAlignment: MainAxisAlignment.center,
                                              icon: Icon(
                                                Icons.delete_forever_outlined,
                                                color: DARK_BLUE,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 4.0,
                                                    color: Colors.grey.withOpacity(0.5),
                                                    offset: Offset(1, 3),
                                                  ),
                                                ],
                                              ),
                                              title: const Text(
                                                '계획 삭제',
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
                                                      text: '계획을 영구히 삭제하시겠습니까?\n',
                                                      style: TextStyle(
                                                        fontFamily: "Pretendard",
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '삭제된 계획은 되돌리거나\n복구할 수 없습니다.',
                                                      style: TextStyle(
                                                        fontFamily: "Pretendard",
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.red.shade600,
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
                                                    backgroundColor: PRIMARY_COLOR,
                                                    foregroundColor: Colors.black87,
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    '삭제 취소',
                                                    style: TextStyle(
                                                      fontFamily: 'Pretendard',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                //목표 삭제 후, 다이얼로그 닫기
                                                ElevatedButton(
                                                  onPressed: (){
                                                    widget.adddel(event, plan:plan, removePlan: true);
                                                    Navigator.of(context).pop();
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(0xFFFFDBDB),
                                                    foregroundColor: Colors.white,
                                                    elevation: 4,
                                                  ),
                                                  child: Text(
                                                    '계획 삭제',
                                                    style: TextStyle(
                                                      fontFamily: 'Pretendard',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Color(0xFFF30404),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      //계획 컨테이너
                                      child: Container(
                                        height: 31,
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), // 안쪽 여백
                                        decoration: BoxDecoration(
                                          //체크박스에 체크가 되면 회색, 체크가 안되면 흰색
                                          color: plan.isDone ? DARK_BLUE : Colors.white,          // 배경색
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: DARK_BLUE.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),

                                        child: Text(
                                          "$timeStr | ${plan.hashtag != null ? "${plan.hashtag} | " : ""}${plan.text}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black
                                          ),
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
                                              backgroundColor: Colors.white,
                                              title: Text(
                                                '수행 확인',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: "Pretendard",
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,

                                                ),
                                              ),
                                              content: Text(
                                                '${plan.text}를 완료하셨나요?',
                                                style: TextStyle(
                                                  fontFamily: "Pretendard",
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              actions: [
                                                //계획 체크 후, 다이얼로그 닫기
                                                TextButton(
                                                  onPressed: (){
                                                    setState(() {
                                                      plan.isDone = true; // 로컬 상태 먼저 변경
                                                      widget.onPlanUpdated(event); // DB 업데이트 요청
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: PRIMARY_COLOR,
                                                    foregroundColor: Colors.black87,
                                                    elevation: 2,
                                                  ),
                                                  child: Text(
                                                    '확인',
                                                    style: TextStyle(
                                                      fontFamily: 'Pretendard',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),

                                                // 그냥 닫기
                                                TextButton(
                                                  onPressed: (){
                                                    Navigator.of(context).pop();
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: PRIMARY_COLOR,
                                                    foregroundColor: Colors.black87,
                                                    elevation: 2,
                                                  ), child: Text(
                                                  '취소',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                ),

                                              ],
                                            ),
                                          );
                                        } else {
                                          setState(() {
                                            plan.isDone = false;
                                            widget.onPlanUpdated(event); // DB 업데이트
                                          });
                                        }
                                      },

                                      //모서리 둥글게
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
                                  SizedBox(width: 5),
                                ],
                              ),
                            ),
                          );
                        }
                        ).toList(),
                      ),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }
}

String insertSpacesForWrapping(String text, int n) {
  String result = '';
  // 텍스트를 n(여기서는 15)자 간격으로 나누어 공백을 삽입
  for (int i = 0; i < text.length; i += n) {
    if (i + n < text.length) {
      // 15자 간격으로 공백 삽입
      result += text.substring(i, i + n) + ' ';
    } else {
      result += text.substring(i);
    }
  }
  return result;
}