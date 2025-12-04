import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';

Future<String?> showTimeWheelPicker(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: const _TimeWheelPicker(),
      );
    },
  );
}

class _TimeWheelPicker extends StatefulWidget {
  const _TimeWheelPicker({Key? key}) : super(key: key);

  @override
  _TimeWheelPickerState createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<_TimeWheelPicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _ampmController;

  // 상태 변수
  late int selectedHour;
  late int selectedMinute;
  late bool isAm;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    isAm = now.period == DayPeriod.am;
    // 12시간제 시간 (12시는 12로, 1시는 1로)
    selectedHour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    // 분을 5분 단위로 반올림하여 초기값 설정
    selectedMinute = (now.minute ~/ 5) * 5;

    _hourController = FixedExtentScrollController(initialItem: selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: selectedMinute ~/ 5);
    _ampmController = FixedExtentScrollController(initialItem: isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _ampmController.dispose();
    super.dispose();
  }

  String _formatTime() {
    int finalHour = selectedHour;

    // 12 AM (자정)은 00시
    if (selectedHour == 12 && isAm) {
      finalHour = 0;
      // 12 PM (정오)은 12시
    } else if (selectedHour == 12 && !isAm) {
      finalHour = 12;
      // 오후 시간 (1시 -> 13시)
    } else if (!isAm) {
      finalHour = selectedHour + 12;
    }

    return "${finalHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 0), // 좌우 여백
                  decoration: BoxDecoration(
                    color: PRIMARY_COLOR.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      child: ListWheelScrollView.useDelegate(
                        controller: _hourController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            // index : 0~12
                            selectedHour = index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 13, // 0~12
                          builder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Center(
                              child: Text(
                                  index.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  )
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Text(":", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),

                    // 분
                    SizedBox(
                      width: 50,
                      child: ListWheelScrollView.useDelegate(
                        controller: _minuteController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            // 5분 단위 계산
                            selectedMinute = index * 5;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 12,
                            builder: (context, index) {
                              final mins = index * 5;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                child: Center(
                                  child: Text(
                                      mins < 10 ? '0' + mins.toString() : mins.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      )
                                  ),
                                ),
                              );
                            }
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // AM/PM
                    SizedBox(
                      width: 50,
                      child: ListWheelScrollView.useDelegate(
                        controller: _ampmController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            // index 0: am, index 1: pm
                            isAm = index == 0;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 2,
                            builder: (context, index) {
                              final isItAm = index == 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                child: Center(
                                  child: Text(
                                      isItAm ? 'am' : 'pm',
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      )
                                  ),
                                ),
                              );
                            }
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 확인 버튼
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _formatTime()); // 선택된 시간 문자열 반환
            },
            child: const Text('확인'),
            style: ElevatedButton.styleFrom(
                backgroundColor: PRIMARY_COLOR,
                foregroundColor: Colors.white,
                side: BorderSide.none,
                minimumSize: const Size(double.infinity, 40)
            ),
          )
        ],
      ),
    );
  }
}