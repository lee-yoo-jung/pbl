import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pbl/tap/mypages/component/chart/goal_data.dart';

// 꺾은 선 그래프
// 지정한 month 기준 최근 6개월 간의 달성률을 나타내는 그래프
// 기본 : 현재 날짜에 해당하는 month
// 앞, 뒤 범위 변경
// 그래프가 그려지는 애니메이션

String _getMonthLabel(DateTime date) {
  return '${date.month}월';
}

// 6개월 슬라이딩(한 페이지에 세팅 날로부터 최근 6개월의 그래프가 보이도록 함)
class GoalLineChart extends StatefulWidget{
  GoalLineChart({Key? key}):super(key:key);

  @override
  State<GoalLineChart> createState() => _GoalLineChartState();
}

class _GoalLineChartState extends State<GoalLineChart> {
  final int _dataWindowSize = 6;
  int _endIndex = allGoalData.length - 1;
  int get _minEndIndex => _dataWindowSize - 1;

  List<GoalRecord> _getCurrentData() {
    final startIndex = (_endIndex - _dataWindowSize + 1).clamp(0, allGoalData.length - _dataWindowSize);
    return allGoalData.sublist(startIndex, _endIndex + 1);
  }

  // 이전 기간으로 이동
  void _showPreviousData() {
    setState(() {
      _endIndex = (_endIndex - 1).clamp(_dataWindowSize - 1, allGoalData.length - 1);
    });
  }

  // 다음 기간으로 이동
  void _showNextData() {
    setState(() {
      _endIndex = (_endIndex + 1).clamp(_dataWindowSize - 1, allGoalData.length - 1);
    });
  }

  void _setEndMonth(DateTime date) {
    final index = allGoalData.indexWhere(
      (record) => record.date.year == date.year && record.date.month == date.month);

    if (index != -1 && index >= _dataWindowSize - 1) {
      setState(() {
        _endIndex = index;
      });
    } else if (index != -1 && index < _dataWindowSize - 1) {
      setState(() {
        _endIndex = _dataWindowSize - 1;
      });
    }
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    // 현재 그래프의 마지막 달
    final initialDate = allGoalData[_endIndex].date;
    final firstDate = allGoalData.first.date;
    final lastDate = allGoalData.last.date;

    final pickedDate = await showDatePicker(
      context: context,
      initialDatePickerMode: DatePickerMode.year, // 초기 모드를 년도로 설정
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,

      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: PRIMARY_COLOR,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: PRIMARY_COLOR,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // 선택된 날짜를 기준 endIndex를 업데이트
      _setEndMonth(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _getCurrentData(); // 그래프를 그리는 Data
    final isPreviousEnabled = _endIndex > _dataWindowSize - 1;  // 이전 기간의 유무
    final isNextEnabled = _endIndex < allGoalData.length - 1;

    final startDate = displayData.isNotEmpty ? displayData.first.date : DateTime.now();
    final endDate = displayData.isNotEmpty ? displayData.last.date : DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),

      child: Column(
        children: [
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 이전 버튼
              SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    color: isPreviousEnabled ? PRIMARY_COLOR : Colors.grey.shade400,
                    onPressed: isPreviousEnabled ? _showPreviousData : null,
                  )
              ),

              GestureDetector(
                onTap: () => _showMonthPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayData.isNotEmpty
                            ? '${startDate.year}.${startDate.month} ~ ${endDate.year}.${endDate.month}'
                            : '데이터 없음',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PRIMARY_COLOR,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, size: 16, color: PRIMARY_COLOR),
                    ],
                  ),
                ),
              ),

              // 다음 버튼
              SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    color: isNextEnabled ? PRIMARY_COLOR : Colors.grey.shade400,
                    onPressed: isNextEnabled ? _showNextData : null,
                  )
              ),
            ],
          ),

          SizedBox(height: 10),

          SfCartesianChart(
            // 범례
            legend: Legend(isVisible: false),

            // 툴팁 활성화
            tooltipBehavior: TooltipBehavior(
              enable: true,
              header: '달성률',
              format: 'point.x : point.y',
            ),

            //x축 설정
            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  color: Colors.black
              ),
              majorGridLines: const MajorGridLines(width: 0),
            ),

            //y축 설정
            primaryYAxis: NumericAxis(
              //y축 최솟값
              minimum: 0,
              //y축 최대값
              maximum: 100,
              //y축 간격
              interval: 20,
              labelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 10,
                color: Colors.black
              ),
              labelFormat: '{value}%',
              majorGridLines: const MajorGridLines( // 가로줄 설정
                width: 0.5,
                color: Color(0xC4C4CFDF),
                dashArray: <double>[5, 5]
              ),
            ),

            series: <CartesianSeries<GoalRecord, String>> [
              //꺾은 선 그래프
              LineSeries<GoalRecord, String>(
                dataSource: displayData,
                xValueMapper: (GoalRecord record, _) => _getMonthLabel(record.date), // X축 : 월
                yValueMapper: (GoalRecord record, _) => record.achievementRate, // Y축 : 달성률(%)
                color: PRIMARY_COLOR, // 선 색상
                width: 2,

                // 마커
                markerSettings: MarkerSettings(
                  isVisible: true,
                  // 각 부분 동그라미 표시
                  shape: DataMarkerType.circle,
                  width: 5,
                  height: 5,
                  color: PRIMARY_COLOR,
                ),

                dataLabelSettings: DataLabelSettings(
                  isVisible: false,
                  textStyle: const TextStyle(
                    fontFamily: "Pretendard",
                      fontSize: 10,
                      color: PRIMARY_COLOR,
                      fontWeight: FontWeight.w400
                    ),

                  builder: (data, point, series, pointIndex, seriesIndex) {
                    final record = data as GoalRecord;
                    return Text(
                      '${record.achievementRate.toStringAsFixed(0)}%',
                      // 정수형으로 표시
                      style: const TextStyle(
                        fontFamily: "Pretendard",
                        fontSize: 10,
                        color: PRIMARY_COLOR,
                        fontWeight: FontWeight.w400
                      ),
                    );
                  }
                )
              )
            ],
          ),
        ],
      ),
    );
  }
}