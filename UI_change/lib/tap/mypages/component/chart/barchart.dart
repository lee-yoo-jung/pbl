import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// syncfusion_flutter_charts 막대 그래프


// 계획 클래스
class Plan {
  Plan(this.title, this.done);
  final String title;
  final bool done;
}

// 이벤트(목표) 클래스
class Event {
  Event(this.title,List<Plan>? plans,): plans = plans ?? [];
  final String title;
  List<Plan> plans = [];  //이벤트 속 계획 리스트, 일단 초기화
}

final List<Event> data = [
  Event("운영체제 A+",[Plan("운영체제 역사 공부", false),Plan("멀티프로그래밍os 공부", true), Plan("상호배제 공부", true),Plan("교착상태 공부", false),Plan("멀티스레드 공부", false),]),
  Event("48kg 달성",[Plan("유산균 홈트", true),Plan("하체 홈트", true), Plan("러닝", true),Plan("100분 러닝", false),Plan("헬스장 상체", false),Plan("헬스장 하체", false),]),
  Event("PBL A+",[Plan("역할 분담", true),Plan("플러터 공부", true), Plan("캘린더 틀", false),Plan("세부 로직", false),Plan("데이터분석", true),Plan("DB 구조 설계", true),Plan("백엔드 설정", true),]),
  Event("미라클 모닝",[Plan("1차 미라클모닝", true),Plan("2차 미라클모닝", true), Plan("3차 미라클모닝", false),Plan("4차 미라클모닝", true),]),
  Event("코딩테스트 파이썬 공부",[Plan("레벨0", true),Plan("레벨0", true), Plan("레벨1", true),Plan("레벨1", false),Plan("레벨1", false),Plan("레벨2", true),]),
  Event("코딩테스트 c++ 공부",[Plan("레벨0", false),Plan("레벨0", false), Plan("레벨1", true),Plan("레벨1", false),Plan("레벨1", false),]),
];

class synfusionbar extends StatelessWidget{

  final int maxpaln_length=data.map((d)=>d.plans.length).reduce((a,b)=>a>b? a:b);

  synfusionbar({Key? key}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: data.length * 80,
            height: 500,
            child: SfCartesianChart(
              title: ChartTitle(
                textStyle: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              //범례
              legend: Legend( isVisible: false),
              //툴팁 활성화
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int tooltipIndex) {
                  Event event = data as Event;
                  if (tooltipIndex == 0) {
                    return Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black12.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${event.title}\n 총 계획 개수: ${event.plans.length}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }
                  else if (tooltipIndex == 1) {
                    return Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${event.title}\n 완료한 계획 개수: ${data.plans
                            .where((plan) => plan.done == true)
                            .length}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              //x축 설정
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(fontSize: 11),
                labelIntersectAction: AxisLabelIntersectAction.wrap,  //x요소의 줄바꿈
                majorGridLines: MajorGridLines(width: 0),
                majorTickLines: MajorTickLines(width: 0),
              ),
              //y축 설정
              primaryYAxis: NumericAxis(
                minimum: 0,   //y축 최솟값
                maximum: maxpaln_length+5, //y축 최대값
                interval: 10, //y축 간격
                labelStyle: TextStyle(fontSize: 12),
                majorGridLines: MajorGridLines(width: 0),
                majorTickLines: MajorTickLines(width: 0),
              ),

              series: <CartesianSeries<Event,String>>[
                //TooltipIndex=0
                ColumnSeries<Event,String>(
                  dataSource: data, //데이터 리스트
                  xValueMapper: (Event data, _)=>data.title,  //X축
                  yValueMapper: (Event data,_)=>data.plans.length,  //Y축
                  color: DARK_BLUE, //막대 색상
                  borderRadius: BorderRadius.all(Radius.circular(4)), //막대 모서리
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,  //막대 위에 값 표시
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  spacing: 0,
                ),
                //TooltipIndex=1
                ColumnSeries<Event,String>(
                  dataSource: data, //데이터 리스트
                  xValueMapper: (Event data,_)=>data.title,  //X축
                  yValueMapper: (Event data,_)=>data.plans.where((plan)=>plan.done==true).length,  //Y축
                  name:'AA',
                  color: PRIMARY_COLOR, //막대 색상
                  borderRadius: BorderRadius.all(Radius.circular(4)), //막대 모서리
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,  //막대 위에 값 표시
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  spacing: 0,
                ),
              ],
              enableSideBySideSeriesPlacement: false,
            ),
          ),
    );
  }
}

