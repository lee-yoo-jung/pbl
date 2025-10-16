import 'package:flutter/material.dart';
import 'package:pbl_mid/tap/calender/component/custom_text_field.dart';
import 'package:pbl_mid/const/colors.dart';
import 'package:pbl_mid/tap/calender/component/event.dart';
import 'package:pbl_mid/tap/calender/component/color_picker_dialog.dart';



//<목표의 기간과 제목을 입력&저장>

List<String> usersList=['사용자2','사용자3','사용자4']; //친구 목록

class ScheduleBottomSheet extends StatefulWidget{
  ScheduleBottomSheet({Key? key }):super(key:key);

  @override
  State<ScheduleBottomSheet> createState()=>_SchedualBottomSheetState();
}


class _SchedualBottomSheetState extends State<ScheduleBottomSheet>{
  DateTime? startDate;      //시작일
  DateTime? endDate;        //종료
  DateTime? selectedDate;   //선택한 날짜
  Map<DateTime, List<Event>> events = {};  //선택된 범위
  List<String> selected=[]; //공동 목표 사용자들
  Color? color;   // 목표별 색깔 선택
  String hashtags="#";         //목표(이벤트)해시태그
  bool? secret=false;   //공개로 기본설정

  late TextEditingController goalController=TextEditingController(); //입력한 텍스트를 가져오기
  late TextEditingController hashController=TextEditingController(); //입력한 텍스트를 가져오기
  bool close_open=false;

  @override
  Widget build(BuildContext context){
    final bottomInset=MediaQuery.of(context).viewInsets.bottom; //화면 하단에서 시스템 UI가 차지하는 높이

    return SafeArea(
      child: Container(
        height:MediaQuery.of(context).size.height/2+bottomInset,  //화면 절반 높이 + 키보드 높이만큼 올라오는 BottomSheet 설정
        color:Colors.white,
        child: Padding(
          padding: EdgeInsets.only(left: 5,right:5,top:5,bottom:bottomInset), //컨테이너 테두리와 페이지의 간격

          //기간 입력과 목표 입력 필드, 저장 버튼을 세로로 배치
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(
                    '기간',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: PRIMARY_COLOR,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // 시작일 선택 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => selectDate(isStart: true), // 시작일 선택
                      child: Text(
                        startDate == null
                            ? '시작일'
                            : '${startDate!.toString().split(' ')[0]}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 종료일 선택 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => selectDate(isStart: false), // 종료일 선택
                      child: Text(
                        endDate == null
                            ? '종료일'
                            : '${endDate!.toString().split(' ')[0]}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              //목표 입력
              Expanded(
                child: CustomTextField(
                  label: '목표',
                  isTime: false,              //시간 형태 불가능
                  controller: goalController, //입력한 목표를 가져오기
                ),
              ),

              Expanded(
                child: CustomTextField(
                  label: '유형',
                  isTime: false,
                  controller: hashController,
                ),
              ),


              // 목표별 색상 선택
              Row(
                children: [
                  const Text(
                      '색상 선택',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PRIMARY_COLOR,
                      )
                  ),

                  const SizedBox(width: 8), // 텍스트와 버튼 사이 간격 추가

                  TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.all(4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        )
                    ),

                    onPressed: () async {
                      final newColor = await showDialog<Color>(
                        context: context,
                        builder: (context) {
                          return ColorPickerDialog(
                              initialColor: color ?? PRIMARY_COLOR
                          );
                        },
                      );
                      if (newColor != null) {
                        setState(() => color = newColor);
                      }
                    },

                    // 현재 색상 표시
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color ?? PRIMARY_COLOR,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  // 색상 선택 상자가 꽉 채우지 않음 -> 빈 공간을 채움
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 위젯들을 양 끝으로 벌림
                children: [
                  //공동목표 수립을 위해 친구 목록에서 친구 선택(다중선택 가능)
                  TextButton(
                    onPressed: () async{
                      //이 다이얼로그에서 반환되는 값은 List<String>으로 picked에 저장됨
                      final picked = await showDialog<List<String>>(
                        context: context,
                        builder: (context){
                          return AlertDialog(
                            title: Text('친구 목록'),
                            content: StatefulBuilder(               //상태 업데이트가 가능하게
                              builder: (context,setState){
                                return Directionality(
                                  textDirection: TextDirection.ltr,
                                  child:  Column(
                                    mainAxisSize: MainAxisSize.min, //다이얼로그의 크기=체크리스트 크기
                                    children: usersList.map((item){ //각 item에 대한 체크박스 생성
                                      //다중선택 가능한 체크박스
                                      return CheckboxListTile(
                                        title: Text(item),
                                        value: selected.contains(item), //체크박스가 체크되어 있는지
                                        onChanged: (bool? checked){     //체크박스를 클릭할 때 호출되는 함수
                                          setState((){
                                            if(checked==true){
                                              selected.add(item);
                                            }else{
                                              selected.remove(item);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                            actions: [
                              TextButton( //선택없이 닫기
                                  onPressed: ()=>Navigator.pop(context),
                                  child: Text('취소')
                              ),
                              TextButton( //선택한 리스트 반환
                                  onPressed: ()=>Navigator.pop(context,selected),
                                  child: Text('확인')
                              ),
                            ],
                          );
                        },
                      );
                      //선택한 값으로 업데이트 후, ui갱신
                      if(picked!=null){
                        setState(() {
                          selected=picked;
                        });
                      }},
                    //선택한 사람이 있을 시엔, 선택한 사람이 표시
                    child: Text(
                      (selected.isEmpty)
                          ? '목표 공유' : selected.join(","),
                      style: TextStyle (
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: PRIMARY_COLOR
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '비공개',
                        style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: PRIMARY_COLOR
                        ),
                      ),
                      //비공개 or 공개(디폴트)
                      Switch(
                        value: close_open,
                        onChanged: (value){
                          setState(() {
                            close_open = value;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: PRIMARY_COLOR,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: DARK_BLUE,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              //저장 버튼
              ElevatedButton(
                onPressed: savegoal,    //눌렀을 때 savegoal 함수가 실행하기
                style: ElevatedButton.styleFrom(
                    foregroundColor: PRIMARY_COLOR,
                    backgroundColor: Colors.white
                ),
                child: Text(
                  '저장',
                  style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 날짜 선택 함수
  Future<void> selectDate({required bool isStart}) async {
    // isStart가 true면 startDate, false면 endDate에 현재 저장된 값을 초기값으로 사용
    DateTime? initialDate = isStart ? startDate : endDate;

    // showDatePicker로 단일 날짜 선택
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(), // 초기값 설정
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // 사용자가 날짜를 선택했으면 상태 업데이트
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          // 시작일이 선택되면 default 종료일을 startDate+1일로 설정
          if (endDate == null || startDate!.isAfter(endDate!)) {
            endDate = startDate!.add(const Duration(days: 1));
          }
        } else {
          endDate = picked;
          // 종료일이 시작일보다 빠르면 시작일 초기화
          if (startDate != null && endDate!.isBefore(startDate!)) {
            startDate = null;
          }
        }
      });
    }
  }


  //저장버튼
  void savegoal(){
    final goal=goalController.text;   //입력한 목표(event)을 가져오기
    String hashtags = hashController.text ?? "";

    //시작 날짜,종료 날짜,목표가 하나 라도 비워 있으면, 함수 종료
    if(startDate==null ||endDate==null || goal.isEmpty){
      return;
    }


    // Event 객체 생성
    final newEvent = Event(
      title: goal,
      startDate: startDate!,
      endDate: endDate!,
      togeter: selected,
      hashtags: hashtags,
      color: color ?? PRIMARY_COLOR,
      secret: close_open!,
    );

    // 날짜별로 분리하여 Map에 저장
    for (var day = startDate!; !day.isAfter(endDate!); day = day.add(Duration(days: 1))) {
      final dateKey = DateTime(day.year, day.month, day.day); // 시간 제거
      if (!events.containsKey(dateKey)) events[dateKey] = [];
      events[dateKey]!.add(newEvent);
    }


    // SnackBar로 띄우기 (로직 확인용)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "새 이벤트: ${newEvent.title}\n친구: ${newEvent.togeter.join(", ")}\n 비공개: ${newEvent.secret}",
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, newEvent); //캘린더로 이동
  }
}