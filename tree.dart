import 'package:flutter/material.dart';
//나무 성장 페이지(달성률 게임화 요소 페이지)

class Tree extends StatefulWidget {
  @override
  TreeState createState() => TreeState();
}

class TreeState extends State<Tree> {

  @override
  void initState() {
    super.initState();
    loadStage();
  }

  //나무를 어느정도 성장 시킨 뒤, 상태 저장
  void loadStage() async {
    ///MaxStage()-> DB 달성률 대입
    int savedStage = await MaxStage(0);
    setState(() {
      stage = savedStage;
    });
  }

  int stage = 0;  //나무 단계 인덱스

  // 여러 단계의 나무 사진
  final List<String> treeImages = [
    'assets/images/tree2.png',
    'assets/images/tree3.png',
    'assets/images/tree4.png',
    'assets/images/tree5.png',
    'assets/images/tree6.png',
    'assets/images/tree7.png',
    'assets/images/tree8.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/images/tree1.png'), // 배경 이미지
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('나무 키우기'),
        backgroundColor: Colors.transparent,),
        body: Column(
          children: [
            SizedBox(height: 250),
            Center(
              //stage 값이 바뀔 때, 새 이미지로 교체
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),  //애니메이션 지속 속도

                transitionBuilder: (Widget child, Animation<double> animation) {
                  //이미지가 점점 나타나게
                  return FadeTransition(
                    opacity: animation,
                    //나무가 성장 느낌-> 커지게
                    child: ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                // 여러 개 이미지 중 현재 단계 이미지 표시
                child: stage>0
                    ? Image.asset(
                  treeImages[stage-1],  //stage 1이면, tree2로 ...
                  key: ValueKey(stage),
                  width: 230,
                ):SizedBox(
                  width: 200,
                  height: 410,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 50,right: 50,bottom: 10),
              child: LinearProgressIndicator(
                ///달성률
                value: 50/100,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 15,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            ///달성률
            Text('00%', style: TextStyle(fontSize: 20,color: Colors.white) ,),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  ///MaxStage()-> DB 달성률 대입
                  int maxS=MaxStage(80);

                  if(stage<maxS){
                    stage+=1;
                  }else if(stage!=7) {  //열매나무(100%)가 아닌 이상, 추가로 버튼을 누르면 안내메시지
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('달성률이 더 높아야합니다.'),
                        duration: Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('성장시키기', style: TextStyle(fontSize: 18),),
            ),
          ],
        ),
      ),



    );
  }
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
}
