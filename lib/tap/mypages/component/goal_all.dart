import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';

class Goal {
  String name;
  List<String> participants;
  int achievement;
  DateTime end; //목표 기간의 종료일

  Goal({
    required this.name,
    required this.participants,
    required this.achievement,
    required this.end,
  });
}

//샘플데이터
final List<Goal> Goals = [
  Goal(
    name: "체중 10kg 감량하기",
    participants: [],
    achievement: 60,
    end: DateTime(2025,11,10),
  ),
  Goal(
    name: "토익 900점 이상 받기",
    participants: ["현재 사용자", "선우"],
    achievement: 90,
    end: DateTime(2025,4,6),
  ),
  Goal(
      name: "PBL A+ 받기",
    participants: ["현재 사용자", "은지", "태형", "수민", "현우"],
    achievement: 40,
    end: DateTime(2025,2,10),
  ),

  ///아직 안 끝남
  Goal(
    name: "체중 15kg 감량하기",
    participants: [],
    achievement: 0,
    end: DateTime(2026,11,1),
  ),
];

class GoalAll extends StatelessWidget {

  //달성도에 따른 나무 사진 인덱스
  int MaxStage(int progress) {
    if (progress < 15) return 0;
    if (progress < 30) return 1;
    if (progress < 45) return 2;
    if (progress < 60) return 3;
    if (progress < 75) return 4;
    if (progress < 90) return 5;
    if (progress < 100) return 6;
    return 7;
  }

  @override
  Widget build(BuildContext context) {

    //나무 이미지
    final List<String> treeImages = [
      'assets/images/tree1_tight.png',
      'assets/images/tree2_tight.png',
      'assets/images/tree3_tight.png',
      'assets/images/tree4_tight.png',
      'assets/images/tree5_tight.png',
      'assets/images/tree6_tight.png',
      'assets/images/tree7_tight.png',
      'assets/images/tree8_tight.png',
    ];

    // end 날짜가 현재보다 이전인 목표만
    final List<Goal> pastGoals = Goals
        .where((goal) => goal.end.isBefore(DateTime.now()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "완료한 목표",
          style: TextStyle(
            color: PRIMARY_COLOR,
            fontSize: 20,
            fontFamily: 'Pretendard-Regular',
            fontWeight: FontWeight.w700,
          ),
        ),
        toolbarHeight: 60.0,
        backgroundColor: Colors.white, // 이미지의 상단 바 색상

      ),
      body: // 참가자 목록 (개인별 달성률 표시)
          ListView.builder(
              itemCount: pastGoals.length,  ///사용자의 목표 숫자
              itemBuilder: (context, index) {
                final goal = pastGoals[index];
                final otherParticipants = goal.participants.where((p) => p != "현재 사용자").toList();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 1.0, vertical: 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Divider(
                        color: Colors.grey.shade300,
                        // 선 색상
                        height: 20,
                        // 위젯의 높이
                        thickness: 1,
                        // 선의 실제 두께
                        indent: 10,
                        // 시작 지점
                        endIndent: 10, // 끝 지점
                      ),
                      Container(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child:
                            Expanded(
                              child: Column(
                                children: [
                                  //목표 이름
                                  Text(
                                    goal.name,
                                    style: const TextStyle(fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 참여한 사용자(본인 제외)
                                      if (otherParticipants.isNotEmpty)
                                        Text(
                                          '참여자: ${otherParticipants.join(', ')}    |    ',
                                          style: const TextStyle(fontSize: 13,
                                              color: Colors.blueGrey),
                                        ),

                                      // 참여한 사용자 표시(본인제외)
                                      Text(
                                        '달성률: ${goal.achievement} %',
                                        style: const TextStyle(fontSize: 12,
                                            color: Colors.blueGrey),
                                      ),
                                      SizedBox(width: 20,),
                                      Image.asset(treeImages[MaxStage(goal.achievement)],width: 40),
                                    ],
                                  )

                                ],
                              ),
                            ),

                          )
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}