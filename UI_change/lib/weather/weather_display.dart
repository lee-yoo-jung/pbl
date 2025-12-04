import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/src/shared/utils.dart';
import 'package:pbl/weather/weather_day.dart';

class WeatherDisplay extends StatefulWidget {
  final WeatherDay? weather;
  final DateTime selectedDate;

  const WeatherDisplay({
    super.key,
    required this.weather,
    required this.selectedDate,
  });

  @override
  State<WeatherDisplay> createState() => _WeatherDisplayState();
}

class _WeatherDisplayState extends State<WeatherDisplay> {
  // 강수량/강수 확률 토글 상태
  bool showRainProb = true;
  // 날씨 예측 범위 체크 로직 (오늘부터 10일 이내)
  bool _isWithinForecastRange(DateTime date) {
    final today = DateTime.now();
    final selectedKey = DateTime(date.year, date.month, date.day);
    // 예측 기간은 오늘 포함 11일 (0일차부터 10일차까지)
    final forecastEndDay = today.add(const Duration(days: 10));

    // 선택 날짜가 (어제 이후)이고 (10일차 이후 이전)인지 확인
    return selectedKey.isAfter(today.subtract(const Duration(days: 1))) &&
        selectedKey.isBefore(forecastEndDay.add(const Duration(days: 1)));
  }

  Widget _buildContent() {
    final selectedKey = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    final isWithinRange = _isWithinForecastRange(widget.selectedDate);
    final isDataAvailable = widget.weather != null && isSameDay(widget.weather!.date, selectedKey);
    final forecastEndDay = DateTime.now().add(const Duration(days: 10));

    if (isDataAvailable) {
      final w = widget.weather!;

      // 🌧️ 강수 정보 섹션 구성 (강수 확률만 사용)
      String rainData = '';
      // 강수 코드(pcp)가 0보다 크고 강수확률 값이 있을 때만 표시
      final bool hasRainProb = w.pcp > 0 && w.rainProb != null;

      if (hasRainProb) {
        // ☔ 강수확률만 표시
        rainData = '☔${w.rainProb!}%';
      }

      // 온도 구성 (null 안전성 확보)
      final current = w.currentTemp?.toStringAsFixed(0) ?? '-';
      final max = w.maxTemp?.toStringAsFixed(0) ?? '-';
      final min = w.minTemp?.toStringAsFixed(0) ?? '-';

      // 최종 요약 텍스트 구성: (이모지) 날씨 | 현재 온도 | 최고/최저 온도 | 강수확률
      final summaryText =
          '${w.mainEmoji} ${w.mainText}  •  ${current} '
          '🔺${max}° / 🔻${min}°'
          '${rainData.isNotEmpty ? ' | 💧 $rainData' : ''}'; // 강수 데이터가 있을 때만 파이프 추가

      return Row(
        // 강수확률만 표시하므로 토글 버튼 로직 제거
        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬로 간소화
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 날씨 요약 텍스트 (Expanded를 제거하고 Text 위젯만으로 구성)
          Text(
            summaryText,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    else if (isWithinRange) {
      return Center(
        child: Text(
          '날씨 정보 불러오는 중...🛰`',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    else {
      return Center(
        child: Text(
          '⚠️ 날씨 예측 기간 (${DateFormat('MM/dd').format(DateTime.now())} ~ ${DateFormat('MM/dd').format(forecastEndDay)})이 아닙니다.',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: _buildContent(),
    );
  }
}