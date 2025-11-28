import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';

class Goal {
  String name;
  List<String> participants;
  String achievement;

  Goal({
    required this.name,
    required this.participants,
    required this.achievement,
  });
}

//샘플데이터
final List<Goal> Goals = [
  Goal(
    name: "체중 10kg 감량하기",
    participants: [],
    achievement: '60%'
  ),
  Goal(
    name: "토익 900점 이상 받기",
    participants: ["현재 사용자", "선우"],
    achievement: '90%'
  ),
  Goal(
      name: "PBL A+ 받기",
    participants: ["현재 사용자", "은지", "태형", "수민", "현우"],
    achievement: '40%'
  ),
];

class GoalAll extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
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
              itemCount: Goals.length,  ///사용자의 목표 숫자
              itemBuilder: (context, index) {
                final goal = Goals[index];
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
                                        '달성률: ${goal.achievement}',
                                        style: const TextStyle(fontSize: 12,
                                            color: Colors.blueGrey),
                                      ),
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