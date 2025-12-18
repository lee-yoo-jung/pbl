import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/mypages/component/chart/barchart.dart';
import 'package:pbl/tap/mypages/component/chart/broken_line_graph.dart';

class chart extends StatelessWidget {

  const chart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double innerPadding = 15.0;
    const double sectionSpacing = 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.area_chart,
              color: PRIMARY_COLOR,
            ),
            SizedBox(width: 8),
            Text(
              "목표 데이터 분석",
              style: TextStyle(
                color: PRIMARY_COLOR,
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
          ],
        ),
        toolbarHeight: 40.0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            const SizedBox(height: sectionSpacing),

            // 꺾은선 그래프
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(innerPadding),
                child: SizedBox(
                  height: 280,
                  child: GoalLineChart(),
                ),
              ),
            ),

            const SizedBox(height: sectionSpacing),

            // 막대 그래프
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(innerPadding),
                child: SizedBox(
                  height: 300, // 높이 조정됨
                  child: SynfusionBar(),
                ),
              ),
            ),

            const SizedBox(height: sectionSpacing),
          ],
        ),
      ),
    );
  }
}