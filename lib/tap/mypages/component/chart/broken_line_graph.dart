import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pbl/tap/mypages/component/chart/goal_data.dart';
import 'package:pbl/services/chart_service.dart';

// 꺾은 선 그래프
class GoalLineChart extends StatefulWidget {
  const GoalLineChart({Key? key}) : super(key: key);

  @override
  State<GoalLineChart> createState() => _GoalLineChartState();
}

class _GoalLineChartState extends State<GoalLineChart> {
  final ChartService _chartService = ChartService();

  // 전체 데이터 저장소
  List<GoalRecord> _allData = [];
  bool _isLoading = true;

  // 슬라이딩 윈도우 설정
  final int _dataWindowSize = 6;
  int _endIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 데이터 로드
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _chartService.fetchMonthlyGoalStats();
      if (mounted) {
        setState(() {
          _allData = data;
          // 데이터가 있으면 마지막 달을 기준으로 설정
          if (_allData.isNotEmpty) {
            _endIndex = _allData.length - 1;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("라인 차트 데이터 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 현재 보여줄 6개월 데이터 추출
  List<GoalRecord> _getCurrentData() {
    if (_allData.isEmpty) return [];

    // 데이터가 6개보다 적으면 전체 다 보여줌
    if (_allData.length <= _dataWindowSize) {
      return _allData;
    }

    final startIndex = (_endIndex - _dataWindowSize + 1).clamp(0, _allData.length - _dataWindowSize);
    return _allData.sublist(startIndex, _endIndex + 1);
  }

  String _getMonthLabel(DateTime date) {
    return '${date.month}월';
  }

  // 이전 기간으로 이동
  void _showPreviousData() {
    if (_endIndex - 1 >= _dataWindowSize - 1) {
      setState(() {
        _endIndex--;
      });
    }
  }

  // 다음 기간으로 이동
  void _showNextData() {
    if (_endIndex + 1 < _allData.length) {
      setState(() {
        _endIndex++;
      });
    }
  }

  // 월 선택
  Future<void> _showMonthPicker(BuildContext context) async {
    if (_allData.isEmpty) return;

    final initialDate = _allData[_endIndex].date;
    final firstDate = _allData.first.date;
    final lastDate = _allData.last.date;

    final pickedDate = await showDatePicker(
      context: context,
      initialDatePickerMode: DatePickerMode.year,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: PRIMARY_COLOR,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      _setEndMonth(pickedDate);
    }
  }

  void _setEndMonth(DateTime date) {
    final index = _allData.indexWhere(
            (record) => record.date.year == date.year && record.date.month == date.month);

    if (index != -1) {
      setState(() {
        if (index < _dataWindowSize - 1) {
          _endIndex = (_dataWindowSize - 1).clamp(0, _allData.length - 1);
        } else {
          _endIndex = index;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_allData.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text("데이터가 없습니다.")),
      );
    }

    final displayData = _getCurrentData();

    // 버튼 활성화 여부
    final isPreviousEnabled = _allData.length > _dataWindowSize && _endIndex > _dataWindowSize - 1;
    final isNextEnabled = _endIndex < _allData.length - 1;

    final startDate = displayData.isNotEmpty ? displayData.first.date : DateTime.now();
    final endDate = displayData.isNotEmpty ? displayData.last.date : DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 상단 컨트롤러
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    color: isPreviousEnabled ? PRIMARY_COLOR : Colors.grey.shade300,
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
                        '${startDate.year}.${startDate.month} ~ ${endDate.year}.${endDate.month}',
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

              SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    color: isNextEnabled ? PRIMARY_COLOR : Colors.grey.shade300,
                    onPressed: isNextEnabled ? _showNextData : null,
                  )
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 차트 영역
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              key: ValueKey('GoalLineChartKey_$_endIndex'), // 리빌드 최적화
              legend: const Legend(isVisible: false),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '평균 달성률',
                builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int tooltipIndex) {
                  final record = data as GoalRecord;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PRIMARY_COLOR.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${record.date.year}.${record.date.month}\n${record.averageRate.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                },
              ),

              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    color: Colors.black
                ),
                majorGridLines: const MajorGridLines(width: 0),
              ),

              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: 100, // 달성률 100% 기준
                interval: 20,
                labelStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    color: Colors.black
                ),
                labelFormat: '{value}%',
                majorGridLines: const MajorGridLines(
                    width: 0.5,
                    color: Color(0xC4C4CFDF),
                    dashArray: <double>[5, 5]
                ),
              ),

              series: <CartesianSeries<GoalRecord, String>> [
                LineSeries<GoalRecord, String>(
                    dataSource: displayData,
                    xValueMapper: (GoalRecord record, _) => _getMonthLabel(record.date),
                    yValueMapper: (GoalRecord record, _) => record.averageRate, // 평균 달성률 사용
                    color: PRIMARY_COLOR,
                    width: 2,
                    animationDuration: 500, // 애니메이션 추가
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      width: 5,
                      height: 5,
                      color: PRIMARY_COLOR,
                    ),
                    dataLabelSettings: DataLabelSettings(
                        isVisible: false,
                        builder: (data, point, series, pointIndex, seriesIndex) {
                          final record = data as GoalRecord;
                          return Text(
                            '${record.averageRate.toStringAsFixed(0)}%',
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
          ),
        ],
      ),
    );
  }
}