import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/custom_text_field.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/tap/calender/component/color_picker_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:pbl/services/friend_service.dart';

class ScheduleBottomSheet extends StatefulWidget{
  ScheduleBottomSheet({Key? key }):super(key:key);

  @override
  State<ScheduleBottomSheet> createState()=>_SchedualBottomSheetState();
}

class _SchedualBottomSheetState extends State<ScheduleBottomSheet>{
  DateTime? startDate;
  DateTime? endDate;

  List<String> selected=[];
  List<String> friendList = [];
  final FriendService _friendService = FriendService();

  Color? color;
  bool close_open = false;
  String selectedEmoji = '✨';

  late TextEditingController goalController=TextEditingController(); //입력한 텍스트를 가져오기
  late TextEditingController hashController=TextEditingController(); //입력한 텍스트를 가져오기

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friendsData = await _friendService.getFriendsList();
      setState(() {
        friendList = friendsData.map((e) => (e['username'] ?? '알 수 없음').toString()).toList();
      });
    } catch (e) {
      debugPrint("친구 목록 로드 실패: $e");
    }
  }

  void _pickEmoji() async {
    final pickedEmoji = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // 전체 화면을 덮을 수 있도록 설정
      builder: (BuildContext context) {
        return SizedBox(
          height: 300, // 피커 높이
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context, emoji.emoji);
            },
            config: const Config(
              emojiViewConfig: EmojiViewConfig(
                columns: 7,
                emojiSizeMax: 32.0,
              ),
            ),
          ),
        );
      },
    );

    if (pickedEmoji != null) {
      setState(() {
        selectedEmoji = pickedEmoji;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    final bottomInset=MediaQuery.of(context).viewInsets.bottom; //화면 하단에서 시스템 UI가 차지하는 높이

      return SafeArea(
        child: Container(
          height:MediaQuery.of(context).size.height/2+bottomInset,  //화면 절반 높이 + 키보드 높이만큼 올라오는 BottomSheet 설정

          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),

          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(left: 25,right:25,top:25,bottom:bottomInset), //컨테이너 테두리와 페이지의 간격

              //기간 입력과 목표 입력 필드, 저장 버튼을 세로로 배치
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 기간 설정 UI ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2.0, bottom: 4.0),
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
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => selectDate(isStart: true), // 시작일 선택
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PRIMARY_COLOR.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0), // 살짝 둥근 사각형
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8), // 패딩 조정
                                ),
                                child: Text(
                                  startDate == null
                                      ? '시작일'
                                      : '${startDate!.toString().split(' ')[0]}',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 13.0,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  overflow: TextOverflow.ellipsis, // 날짜가 길어지면 ... 처리
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => selectDate(isStart: false), // 종료일 선택
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PRIMARY_COLOR.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0), // 살짝 둥근 사각형
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8), // 패딩 조정
                                ),
                                child: Text(
                                  endDate == null
                                      ? '종료일'
                                      : '${endDate!.toString().split(' ')[0]}',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 13.0,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  overflow: TextOverflow.ellipsis, // 날짜가 길어지면 ... 처리
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 14),

                  //목표 입력
                  CustomTextField(
                    label: '목표',
                    isTime: false,              //시간 형태 불가능
                    controller: goalController, //입력한 목표를 가져오기
                  ),

                  // --- 목표별 색상 및 이모지 선택---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // 💡 두 그룹을 양 끝으로 벌립니다.
                    children: [
                      // 색상 선택 그룹
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 8), // 텍스트와 버튼 사이 간격
                          TextButton(
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
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 이모지 선택 그룹
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                              '이모지 선택',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PRIMARY_COLOR,
                              )
                          ),

                          const SizedBox(width: 8), // 텍스트와 버튼 사이 간격 추가

                          IconButton(
                            onPressed: _pickEmoji,
                            icon: Text(
                              selectedEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ---친구 공유 및 공개 설정 ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // 위젯들을 양 끝으로 벌림
                    children: [
                      //공동목표 수립을 위해 친구 목록에서 친구 선택(다중선택 가능)
                      Expanded(
                        child: TextButton(
                          onPressed: () async{
                            if (friendList.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('친구 목록이 비어있습니다.')),
                              );
                              return;
                            }

                            //이 다이얼로그에서 반환되는 값은 List<String>으로 picked에 저장됨
                            final picked = await showDialog<List<String>>(
                              context: context,
                              builder: (context){
                                return AlertDialog(
                                  title: Text(
                                    '친구 목록',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  content: StatefulBuilder(               //상태 업데이트가 가능하게
                                    builder: (context,setState){
                                      final maxDialogHeight = MediaQuery.of(context).size.height * 0.5;
                                      return SizedBox(
                                        width: double.maxFinite,
                                        height: maxDialogHeight,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: friendList.length,
                                            itemBuilder: (context, index) {
                                              final item = friendList[index];
                                              //다중선택 가능한 체크박스
                                              return CheckboxListTile(
                                                title: Text(
                                                  item,
                                                  style: TextStyle(
                                                    fontFamily: "Pretendard",
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.black
                                                  ),
                                                ),
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
                                                activeColor: PRIMARY_COLOR,
                                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                                  (Set<MaterialState> states){
                                                    if(states.contains(MaterialState.selected)){
                                                      return PRIMARY_COLOR; //체크될 때,색
                                                    }
                                                    return Colors.white;   //체크 표시 색
                                                  }
                                                ),
                                              );
                                            },
                                        ),
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: ()=>Navigator.pop(context),
                                        child: Text('취소', style: TextStyle(color: PRIMARY_COLOR))
                                    ),
                                    TextButton(
                                        onPressed: ()=>Navigator.pop(context,selected),
                                        child: Text('확인', style: TextStyle(color: PRIMARY_COLOR))
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle (
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: PRIMARY_COLOR
                            ),
                          ),
                        ),
                      ),

                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
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

                            SizedBox(width: 4),

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
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  //저장 버튼
                  ElevatedButton(
                    onPressed: () => savegoal(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PRIMARY_COLOR,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        minimumSize: const Size(double.infinity, 40)
                    ),
                    child: Text(
                      '저장',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
    );
  }

  // 날짜 선택 함수
  Future<void> selectDate({required bool isStart}) async {
    DateTime? initialDate = isStart ? startDate : endDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(), // 초기값 설정
      firstDate: DateTime(2000), // 최소 범위
      lastDate: DateTime(2100),   // 최대 범위

      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: PRIMARY_COLOR,     // 선택된 날짜 색상
              onPrimary: Colors.white,    // 선택한 날짜 폰트 색상
              onSurface: Colors.black,    // 본문 (날짜) 텍스트 색상
            ),
            dialogBackgroundColor: Colors.white, // 다이얼로그 배경색
            textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Pretendard',
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                foregroundColor: PRIMARY_COLOR,
              ),
            ),

            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),

            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // 캘린더 피커 내부 모서리
              ),
              // 선택된 날짜 색상 안정성 강화
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.black;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    // 사용자가 날짜를 선택했으면 상태 업데이트 (기존 로직 유지)
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate == null || startDate!.isAfter(endDate!)) {
            endDate = startDate!.add(const Duration(days: 1));
          }
        } else {
          endDate = picked;
          if (startDate != null && endDate!.isBefore(startDate!)) {
            startDate = null;
          }
        }
      });
    }
  }


  //저장버튼
  void savegoal(BuildContext ctx){
    final goal = goalController.text;

    if(startDate == null || endDate == null || goal.isEmpty){
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("목표와 기간을 모두 입력해주세요.")),
      );
      return;
    }

    final newEvent = Event(
      title: goal,
      startDate: startDate!,
      endDate: endDate!,
      togeter: selected,
      color: color ?? PRIMARY_COLOR,
      emoji: selectedEmoji,
      secret: close_open,
      plans: [],
    );

    Navigator.pop(context, newEvent);
  }
}
