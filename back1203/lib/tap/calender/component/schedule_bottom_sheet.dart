import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/custom_text_field.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/tap/calender/component/color_picker_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:pbl/services/friend_service.dart';

//<목표의 기간과 제목을 입력&저장>

class ScheduleBottomSheet extends StatefulWidget{
  ScheduleBottomSheet({Key? key }):super(key:key);

  @override
  State<ScheduleBottomSheet> createState()=>_SchedualBottomSheetState();
}

class _SchedualBottomSheetState extends State<ScheduleBottomSheet>{
  DateTime? startDate;      //시작일
  DateTime? endDate;        //종료

  List<String> selected=[]; //공동 목표 사용자들 (이름)

  List<String> friendList = [];
  final FriendService _friendService = FriendService();

  Color? color;   // 목표별 색깔 선택
  bool close_open=false;   //공개(false)로 기본설정 (Event 객체의 secret과 매핑)
  String selectedEmoji = '😊';

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
        friendList = friendsData.map((e) => e['username'] as String).toList();
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
        height:MediaQuery.of(context).size.height/2+bottomInset + 50,  //화면 절반 높이 + 키보드 높이만큼 올라오는 BottomSheet 설정

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

                // 목표별 색상 선택
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 두 그룹을 양 끝으로 벌립니다.
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

                          final picked = await showDialog<List<String>>(
                            context: context,
                            builder: (context){
                              return AlertDialog(
                                title: Text(
                                  '친구 목록',
                                ),
                                backgroundColor: Colors.white,
                                content: StatefulBuilder(               //상태 업데이트가 가능하게
                                  builder: (context,setState){
                                    return Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: friendList.length,
                                          itemBuilder: (context, index) {
                                            final item = friendList[index];
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
                              ? '목표 공유 (친구 선택)' : selected.join(","),
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
                  onPressed: savegoal,    //눌렀을 때 savegoal 함수가 실행하기
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
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),

      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: PRIMARY_COLOR,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

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


  // 저장버튼 로직
  void savegoal(){
    final goal = goalController.text;

    if(startDate == null || endDate == null || goal.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("목표와 기간을 모두 입력해주세요.")),
      );
      return;
    }

    final newEvent = Event(
      title: goal,
      startDate: startDate!,
      endDate: endDate!,
      togeter: selected, // 공유할 친구들
      color: color ?? PRIMARY_COLOR,
      emoji: selectedEmoji,
      secret: close_open, // 공개/비공개 설정
      plans: [], // 초기 생성 시 계획은 없음
    );

    Navigator.pop(context, newEvent);
  }
}