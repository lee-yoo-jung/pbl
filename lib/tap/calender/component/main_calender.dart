import 'package:pbl/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';  //테이블 캘린더 패키지
import 'event.dart';
import 'package:intl/intl.dart';


/* <캘린더 패키지 적용 (캘린더 모양/글꼴/색깔 & 날짜 선택 시, 적용되는 함수)>,
   <목표 설정시, 캘린더 속 하이라이트 적용>
*/

class MainCalendar extends StatefulWidget{
  final OnDaySelected onDaySelected; //날짜 선택 시 실행할 함수
  final DateTime selectedDate; //선택된 날짜
  final Map<DateTime, List<Event>> events; //사용자의 목표=Event 객체 리스트
  final Function(DateTime focusedDay)? onPageChanged;

  //매개변수
  MainCalendar({
    super.key,
    required this.onDaySelected,
    required this.selectedDate,
    required this.events,
    this.onPageChanged,
  });

  @override
  State<MainCalendar> createState() => _MainCalendarState();
}

class _MainCalendarState extends State<MainCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant MainCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(widget.selectedDate, _selectedDate)) {
      _selectedDate = widget.selectedDate;
    }
    if (!isSameDay(widget.selectedDate, _focusedDay)) {
      _focusedDay = widget.selectedDate;
    }
  }

  // 이전달로 이동
  void _onPrevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      widget.onPageChanged?.call(_focusedDay);
    });
  }

  // 다음달로 이동
  void _onNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      widget.onPageChanged?.call(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateKey = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);

    return Container(
      padding: const EdgeInsets.all(16.0), // 상하좌우 여백 추가
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 커스텀 헤더 추가
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20,),
                    onPressed: _onPrevMonth,
                    color: Colors.black
                ),
                Text(
                  DateFormat('yyyy년 MM월').format(_focusedDay),
                  style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 20,),
                    onPressed: _onNextMonth,
                    color: Colors.black
                ),
              ],
            ),
          ),

          Expanded(
            // 캘린더 부분만 스크롤
            child:SingleChildScrollView(
              child: TableCalendar(
                locale: 'ko_kr',                //한국어 적용

                headerVisible: false,

                ////어떤 날짜를 선택된 날짜로 지정할지 결정
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  widget.onDaySelected(selectedDay, focusedDay);
                },

                selectedDayPredicate: (date)=> //선택된 날짜(연,월,일)와 캘린더 속 날짜가 동일한지 확인해서, True면 선택된 날짜로 표시. False면 선택되지 않은 날짜로 지정
                date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day,
                focusedDay: _focusedDay,     //화면에 보여지는 날

                firstDay: DateTime(1800,1,1), //첫째 날
                lastDay: DateTime(3000,1,1),  //마지막 날
                rowHeight: 80,                //날짜 칸 높이 조정

                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay; // 상태 업데이트
                  });
                  widget.onPageChanged?.call(focusedDay);
                },

                // 월화수목금토일 폰트 설정
                daysOfWeekStyle: const DaysOfWeekStyle(
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
                    color: Colors.transparent,      //투명도 0.5
                    borderRadius: BorderRadius.circular(10.0),  //둥글게
                  ),

                  //주말 날짜 스타일
                  weekendDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  markersMaxCount: 0,   //목표 기간 입력 후, 생기는 점 마커를 비활성화
                ),


                //특정 날짜(day)의 이벤트들을 가져옴
                eventLoader: (day) {
                  final dateKey = DateTime(day.year, day.month, day.day); //순수한 날짜로 키 활용
                  return widget.events[dateKey] ??  <Event>[]; //day에서 이벤트의 시작일과 종료일 사이에 있는 이벤트들을 가져옴, 없으면 빈 리스트
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
                      decoration: const BoxDecoration(
                        color: Colors.transparent,  //날짜 박스의 색 (transparent: 투명하게)
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
                        ? const Color(0xFFE0A0A0)
                        : isSaturday
                        ? const Color(0xFFA0B8FA)
                        : Colors.grey.shade400;

                    return Container(
                      padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                      alignment: Alignment.topLeft,   // 좌측 상단 배치
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
                        child:Center(
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

                  //기간에 하이라이트 표시
                  rangeHighlightBuilder: (context, day, eventsInDay) {
                    final dateKey = DateTime(day.year, day.month, day.day);
                    final eventList = widget.events[dateKey] ?? [];

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

                        final dayList = widget.events[key];
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
          ),
          SizedBox(height: 80,),
        ],
      ),
    );
  }
}