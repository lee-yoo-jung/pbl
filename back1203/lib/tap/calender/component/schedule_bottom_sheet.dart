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
  String selectedEmoji = '😊';

  late TextEditingController goalController=TextEditingController();
  late TextEditingController hashController=TextEditingController();

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
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
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
    final bottomInset=MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent, // 배경 투명 (모서리 둥글게 유지)
      body: Builder(
          builder: (BuildContext scaffoldContext) {
            return SafeArea(
              child: Container(
                height:MediaQuery.of(context).size.height/2+bottomInset + 50,

                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),

                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(left: 25,right:25,top:25,bottom:bottomInset),

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
                                      onPressed: () => selectDate(isStart: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: PRIMARY_COLOR.withOpacity(0.8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 8),
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
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => selectDate(isStart: false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: PRIMARY_COLOR.withOpacity(0.8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 8),
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
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // --- 목표 입력 UI ---
                        CustomTextField(
                          label: '목표',
                          isTime: false,
                          controller: goalController,
                        ),

                        // --- 색상 및 이모지 선택 ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                const SizedBox(width: 8),
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
                                const SizedBox(width: 8),
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

                        // --- 친구 공유 및 공개 설정 ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () async{
                                  if (friendList.isEmpty) {
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      const SnackBar(content: Text('친구 목록이 비어있습니다.')),
                                    );
                                    return;
                                  }

                                  final picked = await showDialog<List<String>>(
                                    context: context,
                                    builder: (context){
                                      return AlertDialog(
                                        title: Text('친구 목록'),
                                        backgroundColor: Colors.white,
                                        content: StatefulBuilder(
                                          builder: (context,setState){
                                            return SizedBox(
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
                                                    value: selected.contains(item),
                                                    onChanged: (bool? checked){
                                                      setState((){
                                                        if(checked==true){
                                                          selected.add(item);
                                                        }else{
                                                          selected.remove(item);
                                                        }
                                                      });
                                                    },
                                                    activeColor: PRIMARY_COLOR,
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
                                  if(picked!=null){
                                    setState(() {
                                      selected=picked;
                                    });
                                  }},
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

                        // --- 저장 버튼 ---
                        ElevatedButton(
                          onPressed: () => savegoal(scaffoldContext),
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
      ),
    );
  }

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