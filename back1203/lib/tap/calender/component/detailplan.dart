import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/custom_text_field.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/const/TimePicker.dart';


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

  final List<String> planTypes = ['공부', '운동', '식단', '음악', '기타'];

  String? selectedType;

  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;  //부모 StatefulWidget로 전달받은 값을 선택한 날짜에 넣기
  }

  //DateTime타입을 통일된 형식으로 설정 YYYY.MM.DD
  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,

      //Child을 스크롤할 수 있게 함
      content: SingleChildScrollView(
        padding: EdgeInsets.all(5),

        //날짜 배치와 시간 설정, 계획 텍스트, 저장 버튼을 세로로 배치
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, //가로로 각 요소를 늘리기,
          children: [
            Text( _formatDate(selectedDate!),
              style: TextStyle(
                color: PRIMARY_COLOR,
                fontSize: 15,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ), //선택한 날짜 표시 = 계획을 추가할 날짜

            const SizedBox(height: 10),  //날짜와 시간 설정의 간격

            //시간 설정
            SizedBox(
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: Colors.grey.shade600,
                    width: 1.0,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),

                onPressed: () async {
                  final pickedTime = await showTimeWheelPicker(context);

                  if (pickedTime != null) {
                    startTimeController.text = pickedTime;
                    setState(() {});
                  }
                },

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 텍스트 표시: 시간이 있으면 시간, 없으면 레이블 표시
                    Text(
                      startTimeController.text.isNotEmpty
                          ? startTimeController.text
                          : '시작 시간',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        color: startTimeController.text.isNotEmpty
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),

                    // 시계 아이콘 추가
                    Icon(
                      Icons.access_time,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20), // 계획 필드와 유형 필드 사이의 간격

            // 유형을 고르는 필드
            SizedBox(
              height: 50,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '유형',
                  labelStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: PRIMARY_COLOR, width: 2.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),

                dropdownColor: Colors.white,  // 배경
                elevation: 4, // 그림자

                // 항목 스타일
                selectedItemBuilder: (BuildContext context) {
                  return planTypes.map((String type) {
                    return Text(
                        type,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: PRIMARY_COLOR,
                        )
                    );
                  }).toList();
                },

                value: selectedType,
                hint: Text(
                  '유형을 선택해주세요',
                  style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500
                  ),
                ),

                items: planTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),

                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                },

                iconSize: 24,
              ),
            ),

            const SizedBox(height: 16), // 계획을 적는 필드와 저장 버튼의 간격 설정

            //저장 버튼
            ElevatedButton(
              onPressed: savePlan, //눌렀을 때 savePlan 함수가 실행하기
              style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                  minimumSize: const Size(double.infinity, 40)
              ),
              child: const Text(
                "저장",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
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

    final newPlan = Plan(text: planController.text, selectdate:selectedDateTime, hashtag: selectedType!); //계획과 DateTime 타입으로 만든 날짜와 시간을 Plan 클래스에 담아 저장

    Navigator.pop(context, newPlan); // 캘린더 페이지로 newPlan을 반환
  }
}