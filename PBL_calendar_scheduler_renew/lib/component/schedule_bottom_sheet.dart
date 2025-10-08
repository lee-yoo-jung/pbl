import 'package:flutter/material.dart';
import 'package:calendar_scheduler/component/custom_text_field.dart';
import 'package:calendar_scheduler/const/colors.dart';
import 'package:calendar_scheduler/component/event.dart';


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

                Row(
                  children: [
                    Expanded(
                      //기간 입력 버튼
                      child: OutlinedButton(
                        onPressed: selectDateRange, //시작 날짜와 종료 날짜를 한 번에 선택하는 기능(selectDateRange)
                        //기간을 입력하기 전이면, '날짜 선택', 입력한 후면 입력한 기간이 버튼에 나타남'
                        child: Text(
                          startDate == null || endDate == null
                              ? '날짜 선택'
                              : '${startDate!.toString().split(' ')[0]} ~ ${endDate!.toString().split(' ')[0]}',
                        ),
                      ),
                    ),

                  ],
                ),

                //목표 입력
                Expanded(
                    child: CustomTextField(
                      label: '목표',
                      isTime: false,              //시간 형태 불가능
                      controller: goalController, //입력한 목표를 가져오기
                    ),
                ),

                  //해시태그 입력'
                Expanded(
                    child: CustomTextField(
                      label: '해시태그',
                      isTime: false,              //시간 형태 불가능
                      controller: hashController, //입력한 목표를 가져오기
                    ),
                ),

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
                          ? 'Together' : selected.join(",")
                  ),
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('비공개'),
                    //비공개 or 공개(디폴트)
                    Switch(
                      value: close_open,
                      onChanged: (value){
                        setState(() {
                          close_open = value;
                        });
                        },
                    ),
                  ],
                ),


                //저장 버튼
                ElevatedButton(
                  onPressed: savegoal,    //눌렀을 때 savegoal 함수가 실행하기
                  style: ElevatedButton.styleFrom(
                    foregroundColor: PRIMARY_COLOR,
                  ),
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // 날짜 범위 선택 함수
  Future<void> selectDateRange() async {
    //showDateRangePicker로 반환된 DateTimeRange 타입의 picked
    final DateTimeRange? picked = await showDateRangePicker(  //기간 선택
      context: context,

      //선택 가능한 최소(2000.1.1.)/최대(2100.1.1.) 날짜 범위
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),

      //선택된 기간(시작일과 종료일이 채워져있으면 DateTimeRange 객체로 설정, 없으면 null)
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    //사용자가 날짜를 선택했으면, startDate와 endDate 변수에 선택한 범위를 저장
    if (picked != null) {
      setState(() { //선택한 날짜를 화면에 반영하기 위해 setState 사용
        startDate = picked.start;
        endDate = picked.end;
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