import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pbl/services/chart_service.dart';

class SynfusionBar extends StatelessWidget {
  final ChartService _chartService = ChartService();

  SynfusionBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Event>>(
      future: _chartService.fetchBarChartData(),
      builder: (context, snapshot) {
        // 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 500,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // 에러가 났을 때
        if (snapshot.hasError) {
          return const SizedBox(
            height: 500,
            child: Center(child: Text("데이터를 불러오는 중 오류가 발생했습니다.")),
          );
        }

        // 데이터가 도착했을 때
        final List<Event> data = snapshot.data ?? [];

        if (data.isEmpty) {
          return const SizedBox(
            height: 500,
            child: Center(child: Text("등록된 목표가 없습니다.")),
          );
        }

        // Y축 최대값 계산
        final int maxPlanLength = data.map((d) => d.plans.length)
            .reduce((a, b) => a > b ? a : b);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: data.length < 3 ? MediaQuery.of(context).size.width : data.length * 80.0,
            height: 500,
            child: SfCartesianChart(
              title: ChartTitle(
                textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              legend: Legend(isVisible: false),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int tooltipIndex) {
                  Event event = data as Event;
                  if (tooltipIndex == 0) { // 전체 계획 막대 툴팁
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black12.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${event.title}\n 총 계획 개수: ${event.plans.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  } else if (tooltipIndex == 1) { // 완료 계획 막대 툴팁
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: PRIMARY_COLOR.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${event.title}\n 완료한 계획: ${event.plans.where((plan) => plan.done).length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(fontSize: 11),
                labelIntersectAction: AxisLabelIntersectAction.wrap,
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: const MajorTickLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: (maxPlanLength + 5).toDouble(), // Y축 최대값 동적 적용
                interval: 5,
                labelStyle: const TextStyle(fontSize: 12),
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: const MajorTickLines(width: 0),
              ),
              series: <CartesianSeries<Event, String>>[
                // 전체 계획 수 (배경 막대)
                ColumnSeries<Event, String>(
                  dataSource: data,
                  xValueMapper: (Event data, _) => data.title,
                  yValueMapper: (Event data, _) => data.plans.length,
                  color: DARK_BLUE,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(fontSize: 10, color: Colors.white),
                    labelAlignment: ChartDataLabelAlignment.top,
                  ),
                  spacing: 0.2, // 막대 간격 조정
                ),
                // 완료된 계획 수 (앞쪽 막대)
                ColumnSeries<Event, String>(
                  dataSource: data,
                  xValueMapper: (Event data, _) => data.title,
                  yValueMapper: (Event data, _) =>
                  data.plans.where((plan) => plan.done).length,
                  color: PRIMARY_COLOR,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(fontSize: 10, color: Colors.white),
                    labelAlignment: ChartDataLabelAlignment.middle,
                  ),
                  spacing: 0.2,
                ),
              ],
              enableSideBySideSeriesPlacement: false, // 겹쳐서 보이게 설정
            ),
          ),
        );
      },
    );
  }
}