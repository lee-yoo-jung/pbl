import 'package:flutter/material.dart';
import 'package:calendar_scheduler/component/custom_text_field.dart';
import 'package:calendar_scheduler/const/colors.dart';
import 'package:calendar_scheduler/component/event.dart';

//<계획의 시간과 내용을 입력하는 페이지>

class Detailplan extends StatefulWidget {
  final Event event;
  final DateTime initialDate;

  //매개변수
  const Detailplan({
    required this.event,
    required this.initialDate,
    Key? key,
  }) : super(key: key);

  @override
  State<Detailplan> createState() => _Detailplan();
}

class _Detailplan extends State<Detailplan> {
  List<DateTime> dates = [];  //DateTime 타입의 dates 리스트
  DateTime? selectedDate;     //선택된 날짜

  final TextEditingController startTimeController = TextEditingController();  //입력한 텍스트를 가져오기 (시간)
  final TextEditingController planController = TextEditingController();       //입력한 텍스트를 가져오기 (계획)

  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;  //부모 StatefulWidget로 전달받은 값을 선택한 날짜에 넣기
  }

  //DateTime타입을 통일된 형식으로 설정 YYYY-MM-DD
  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //상단 앱바
      appBar: AppBar(
        title: const Text("상세 계획"),
        backgroundColor: PRIMARY_COLOR,
        toolbarHeight: 45.0,
      ),

      //Child을 스크롤할 수 있게 함
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),  //페이지와 이 요소의 여백

        //날짜 배치와 시간 설정, 계획 텍스트, 저장 버튼을 세로로 배치
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, //가로로 각 요소를 늘리기,

          children: [
            Text("날짜:, "+_formatDate(selectedDate!)), //선택한 날짜 표시= 계획을 추가할 날짜

            const SizedBox(height: 8),  //날짜와 시간 설정의 간격

            //시간 설정
            SizedBox(
              height: 60,
              //시간 표시 필드
              child: CustomTextField(
                label: '시작 시간',
                isTime: true,                     //시간만 가능
                readOnly: true,                   //입력할 수 없게
                controller: startTimeController,  //설정한 시간(텍스트)을 읽을 수 있게

                onTap: () async {   //눌렀을 때. 시간 다이얼로그 (showTimePicker)을 실행하고, TimeOfDay 타입의 picked에 저장
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(), //기본 시간: 현재 시간
                  );
                  //picked가 비어있지 않으면, 텍스트를 읽는 곳에 picked의 시각(HH:MM)을 입력하기
                  if (picked != null) {
                    startTimeController.text =
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                  }
                },
              ),
            ),

            const SizedBox(height: 8),  //시간 다이얼로그와 계획을 적는 필드의 간격 설정

            //계획을 적는 필드
            SizedBox(
              height: 60,
              child: CustomTextField(
                label: '계획',
                isTime: false,              //시간 형태 불가능
                controller: planController, //설정한 계획을 읽을 수 있게
              ),
            ),

            const SizedBox(height: 16), // 계획을 적는 필드와 저장 버튼의 간격 설정

            //저장 버튼
            ElevatedButton(
              onPressed: savePlan, //눌렀을 때 savePlan 함수가 실행하기
              style: ElevatedButton.styleFrom(foregroundColor: PRIMARY_COLOR),
              child: const Text("저장"),
            ),
          ],
        ),
      ),
    );
  }

  //계획(날짜,시간,계획)을 저장하는 함수
  void savePlan() {
    //선택된 날짜와 선택된 시간, 입력한 계획 중 어느 하나라도 비어있다면, 스낵바로 알려주기
    if (selectedDate == null ||
        startTimeController.text.isEmpty ||
        planController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("날짜, 시간, 계획을 모두 입력해주세요.")),
      );
      return;
    }

    final timeParts = startTimeController.text.split(':');  //입력받은 시간의 : 를 제거 [HH,MM]

    //DateTime 타입으로 만들기 (YYYY-MM-DD HH:MM)
    final selectedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final newPlan = Plan(text: planController.text, selectdate:selectedDateTime); //계획과 DateTime 타입으로 만든 날짜와 시간을 Plan 클래스에 담아 저장

    Navigator.pop(context, newPlan); // 캘린더 페이지로 newPlan을 반환
  }
}
