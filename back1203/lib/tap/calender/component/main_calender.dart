import 'package:pbl/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';  //테이블 캘린더 패키지
import 'event.dart';
import 'dart:math';

/* <캘린더 패키지 적용 (캘린더 모양/글꼴/색깔 & 날짜 선택 시, 적용되는 함수)>,
   <목표 설정시, 캘린더 속 하이라이트 적용>
*/

class MainCalendar extends StatelessWidget {
  final OnDaySelected onDaySelected; //날짜 선택 시 실행할 함수
  final DateTime selectedDate; //선택된 날짜
  final Map<DateTime, List<Event>> events; //사용자의 목표=Event 객체 리스트

  final Function(DateTime focusedDay)? onPageChanged;

  //매개변수
  MainCalendar({
    required this.onDaySelected,
    required this.selectedDate,
    required this.events,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0), // 상하좌우 여백 추가
      color: Colors.white,
      child: SingleChildScrollView(
        child: TableCalendar(
          locale: 'ko_kr',
          //한국어 적용
          ////어떤 날짜를 선택된 날짜로 지정할지 결정
          onDaySelected: onDaySelected,
          selectedDayPredicate: (
              date) => //선택된 날짜(연,월,일)와 캘린더 속 날짜가 동일한지 확인해서, True면 선택된 날짜로 표시. False면 선택되지 않은 날짜로 지정
          date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day,
          focusedDay: selectedDate,
          //화면에 보여지는 날
          firstDay: DateTime(1800, 1, 1),
          //첫째 날
          lastDay: DateTime(3000, 1, 1),
          //마지막 날
          rowHeight: 80,
          //날짜 칸 높이 조정
          onPageChanged: onPageChanged,

          //캘린더 최상단 스타일
          headerStyle: HeaderStyle(
            titleCentered: true, //제목 중앙에 위치
            formatButtonVisible: false, //달력 크기 선택 옵션
            titleTextStyle: TextStyle( //제목 글꼴
              fontFamily: 'Pretendard', // 글꼴
              fontWeight: FontWeight.w600, // 글꼴 두께
              fontSize: 15.0, // 글꼴 크기
              color: Colors.black, // 글꼴 색상
            ),
          ),

          // 월화수목금토일 폰트 설정
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
              color: Colors.black,
            ),
            weekendStyle: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
              color: Colors.black,
            ),
          ),

          //캘린더 스타일
          calendarStyle: CalendarStyle(
            //오늘 날짜 하이라이트 설정과 스타일
            isTodayHighlighted: true,
            todayDecoration: BoxDecoration(
              color: Colors.transparent, //투명도 0.5
              borderRadius: BorderRadius.circular(10.0), //둥글게
            ),

            //주말 날짜 스타일
            weekendDecoration: BoxDecoration(
              color: Colors.transparent,
            ),
            markersMaxCount: 0, //목표 기간 입력 후, 생기는 점 마커를 비활성화
          ),


          //특정 날짜(day)의 이벤트들을 가져옴
          eventLoader: (day) {
            final dateKey = DateTime(
                day.year, day.month, day.day); //순수한 날짜로 키 활용
            return events[dateKey] ??
                <Event>[]; //day에서 이벤트의 시작일과 종료일 사이에 있는 이벤트들을 가져옴, 없으면 빈 리스트
          },

          //캘린더 커스텀
          calendarBuilders: CalendarBuilders(
            // 이달로 표시되는 날짜 설정
            defaultBuilder: (context, day, focusedDay) {
              final isSaturday = day.weekday == DateTime.saturday;
              final isSunday = day.weekday == DateTime.sunday;
              final Color textColor = isSunday
                  ? const Color(0xFFFA3A3A) // 일요일 빨간색
                  : isSaturday
                  ? const Color(0xFF3A6BFA) // 토요일 파란색
                  : Colors.black;

              return Container(
                padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                alignment: Alignment.topLeft, // 좌측 상단 배치
                decoration: BoxDecoration(
                  color: Colors.transparent, //날짜 박스의 색 (transparent: 투명하게)
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontSize: 14.0,
                  ),
                ),
              );
            },

            // 이번달로 표시되지 않는 날짜 설정
            outsideBuilder: (context, day, focusedDay) {
              final isSaturday = day.weekday == DateTime.saturday;
              final isSunday = day.weekday == DateTime.sunday;
              final Color textColor = isSunday
                  ? const Color(0xFFE0A0A0) // 이전달 일요일은 흐리게 빨강
                  : isSaturday
                  ? const Color(0xFFA0B8FA) // 이전달 토요일은 흐리게 파랑
                  : Colors.grey.shade400;

              return Container(
                padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                alignment: Alignment.topLeft, // 좌측 상단 배치
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 14.0,
                  ),
                ),
              );
            },

            // 선택된 날짜 설정
            selectedBuilder: (context, day, focusedDay) {
              return Container(
                padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(7.0),
                  border: Border.all(
                    color: PRIMARY_COLOR,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: PRIMARY_COLOR,
                  ),
                ),
              );
            },

            // 현재 날짜 원으로 표현
            todayBuilder: (context, day, focusedDay) {
              return Container(
                padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                // text 좌측 상단에 배치
                alignment: Alignment.topLeft,
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  margin: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(
                    color: DARK_BLUE,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              );
            },

            rangeHighlightBuilder: (context, day, eventsInDay) {
              final dateKey = DateTime(day.year, day.month, day.day);
              final eventList = events[dateKey] ?? [];

              if (eventList.isEmpty) return null;

              final eventsHeight = 12.0; //한 하이라이트 높이
              var margin = 2.0; //하이라이트 간격

              final sortedEvents = List<Event>.from(eventList);
              sortedEvents.sort((a, b) =>
                  a.id.toString().compareTo(b.id.toString()));

              List<Widget> markers = [];

              for (var event in sortedEvents) {
                int maxIndex = 0;

                DateTime current = event.startDate;
                while (!current.isAfter(event.endDate)) {
                  final key = DateTime(
                      current.year, current.month, current.day);

                  final dayList = events[key];
                  if (dayList != null) {
                    final tempSorted = List<Event>.from(dayList);
                    tempSorted.sort((a, b) =>
                        a.id.toString().compareTo(b.id.toString()));

                    final index = tempSorted.indexOf(event);
                    if (index > maxIndex) maxIndex = index;
                  }
                  current = current.add(const Duration(days: 1));
                }

                final top = maxIndex * (eventsHeight + margin);

                final isStart = isSameDay(day, event.startDate);
                final isEnd = isSameDay(day, event.endDate);

                markers.add(
                  Positioned(
                    top: 25 + top,
                    left: 0,
                    right: 0,
                    height: eventsHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.15),
                        borderRadius: BorderRadius.horizontal(
                          left: isStart ? const Radius.circular(8) : Radius.zero,
                          right: isEnd ? const Radius.circular(8) : Radius.zero,
                        ),
                      ),
                      child: isStart
                          ? Center(
                        child: Text(
                          (event.emoji ?? '') + ' ' + event.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                          : null,
                    ),
                  ),
                );
              }

              return Stack(children: markers);
            },
          ),
        ),
      ),
    );
  }
}

            //기간에 하이라이트 표시
  //           rangeHighlightBuilder: (context, day, eventsInDay) {
  //
  //             final Map<Event, double> eventTopMap = {};  //이벤트와 Top의 맵(캘린더 하이라이터)
  //             final Map<DateTime, List<Event>> eventsByDay = {};  // 날짜마다 겹치는 이벤트를 계산
  //
  //             final dateKey = DateTime(day.year, day.month, day.day); //순수 날짜만 key로 사용
  //             final eventList = events[dateKey] ?? <Event>[];         //날짜별로 이벤트를 저장한 맵, 이벤트가 없다면 빈 리스트
  //
  //             if (eventList.isEmpty) return null;     //이벤트가 없으면 null 반환
  //
  //             final eventsHeight = 12.0;  //한 하이라이트 높이
  //             var margin = 2.0;         //하이라이트 간격
  //
  //             //모든 이벤트에서 중복을 제거하고 List로 변환
  //             final allEvents = events.values.expand((list) => list).toSet().toList();
  //             //모든 이벤트를 시작일 기준으로 정렬
  //             allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
  //
  //             //모든 이벤트를 날짜별로 모으기 ex. 10.14={[목표1], [목표2]} // 10.15={[목표1], [목표2], [목표3]}
  //             for (var event in allEvents) {  // 정렬된 allEvents 사용
  //               for (var day = event.startDate; !day.isAfter(event.endDate);
  //               day = day.add(Duration(days: 1))) {
  //                 eventsByDay.putIfAbsent(day, () => []); //day라는 key가 맵에 없으면 빈 리스트
  //                 // 중복 추가 방지
  //                 if (!eventsByDay[day]!.contains(event)) {
  //                   eventsByDay[day]!.add(event); //day에 걸친 리스트를 하나의 리스트로 모으기
  //                 }
  //               }
  //             }
  //
  //             // 현재 날짜(day)에 걸친 이벤트 리스트를 가져옴
  //             final eventsForCurrentDay = eventsByDay[dateKey] ?? [];
  //             if (eventsForCurrentDay.isEmpty) return null;
  //
  //             // top 위치 계산 (현재 날짜에 걸친 이벤트만 계산)
  //             for(var event in eventsForCurrentDay){
  //               int maxIndex = 0;
  //               //이벤트 기간 내에서 해당 이벤트가 가장 뒤에 위치하는 인덱스 찾기
  //               for (var day = event.startDate; !day.isAfter(event.endDate);
  //               day = day.add(Duration(days: 1))) {
  //                 final index = eventsByDay[day]!.indexOf(event);
  //                 if (maxIndex < index)
  //                   maxIndex=index;
  //               }
  //               eventTopMap[event] = maxIndex * (eventsHeight + margin) + 15; //해당 이벤트에 탑 저장
  //             }
  //
  //
  //             final widgets=eventTopMap.entries.map((entry) {
  //               final event=entry.key;
  //               final top = entry.value;
  //               final Start = isSameDay(day, event.startDate);
  //               final End = isSameDay(day, event.endDate);
  //
  //               //각 이벤트의 하이라이트 UI를 특정
  //               return Positioned(
  //                 top:10+top,
  //                 left: 0,
  //                 right: 0,
  //                 height: eventsHeight,
  //                 child: Container(
  //                   //하이라이트 막대 스타일
  //                   decoration: BoxDecoration(
  //                     color: event.color.withOpacity(0.15),
  //                     borderRadius: BorderRadius.horizontal(
  //                       left: Start ? const Radius.circular(8) : Radius.zero, //시작일이면 왼쪽 둥글게
  //                       right: End ? const Radius.circular(8) : Radius.zero,  //종료일이름 오른쪽 둥글게
  //                       // 중간날짜면 양쪽 평평
  //                     ),
  //                   ),
  //                   //이벤트 시작일의 하이라이트에 제목 표시
  //                   child: Start
  //                       ? Center(
  //                     child: Text(
  //                       event.title,
  //                       style: const TextStyle(
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.black,
  //                       ),
  //                       overflow: TextOverflow.ellipsis,  //글자가 길면 ...처리
  //                     ),
  //                   ) : null, //시작일이 아니면 null
  //                 ),
  //               );
  //             }).toList();
  //             if(widgets.isEmpty) return null;
  //             return Stack(children: widgets);
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }}