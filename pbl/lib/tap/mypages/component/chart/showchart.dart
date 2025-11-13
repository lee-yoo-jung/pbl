import 'package:flutter/material.dart';
import 'package:pbl/tap/mypages/component/chart/barchart.dart';
import 'package:pbl/tap/mypages/component/chart/broken_line_graph.dart';

class chart extends StatelessWidget{

  chart({Key? key}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목표데이터 분석'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            GoalLineChart(),
            synfusionbar(),
          ],
        ),
      ),
    );
  }
}