import 'package:calendar_scheduler/const./colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';  //테이블 캘린더 패키지
import 'event.dart';

/* <캘린더 패키지 적용 (캘린더 모양/글꼴/색깔 & 날짜 선택 시, 적용되는 함수)>,
   <목표 설정시, 캘린더 속 하이라이터 적용>
*/

class MainCalendar extends StatelessWidget{
  final OnDaySelected onDaySelected;  //날짜 선택 시 실행할 함수
  final DateTime selectedDate;        //선택된 날짜
  final List<Event> events;           //사용자의 목표=Event 객체 리스트

  //매개변수
  MainCalendar({
    required this.onDaySelected,
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'ko_kr',                //한국어 적용

      ////어떤 날짜를 선택된 날짜로 지정할지 결정
      onDaySelected: onDaySelected,
      selectedDayPredicate: (date)=>  //선택된 날짜(연,월,일)과 캘린더 속 날짜가 동일한지 확인해서, True면 선택된 날짜로 표시. False면 선택되지 않은 날짜로 지정
        date.year==selectedDate.year &&
        date.month==selectedDate.month &&
        date.day==selectedDate.day,

      focusedDay: selectedDate,  //화면에 보여지는 날
      firstDay: DateTime(1800,1,1), //첫째 날
      lastDay: DateTime(3000,1,1),  //마지막 날

      //캘린더 최상단 스타일
      headerStyle: HeaderStyle(
        titleCentered: true,            //제목 중앙에 위치
        formatButtonVisible: false,     //달력 크기 선택 옵션
        titleTextStyle: TextStyle(      //제목 글꼴
          fontWeight: FontWeight.w700,    //글꼴 두께
          fontSize: 20.0,                 //글꼴 크기
          color: Colors.lightBlueAccent,  //글꼴 색상
        ),
      ),


      //캘린더 스타일
      calendarStyle: CalendarStyle(

        //오늘 날짜 하이라이트 설정과 스타일
        isTodayHighlighted: true,
        todayDecoration: BoxDecoration(
          color: PRIMARY_COLOR.withOpacity(0.5),     //투명도 0.5
          borderRadius: BorderRadius.circular(50.0),//둥글게
        ),

        //기본 날짜 스타일
        defaultDecoration: BoxDecoration(
          color: Colors.transparent,  //날짜 박스의 색 (transparent: 투명하게)
        ),

        //주말 날짜 스타일
        weekendDecoration: BoxDecoration(
          color: Colors.transparent,
        ),

        //선택 날짜 스타일
        selectedDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0), //날짜 박스의 모서리
          border: Border.all(           //날짜 박스 테두리의 속성(색, 두께)
            color: PRIMARY_COLOR,
            width: 1.0,
          ),
        ),

        markersMaxCount: 0,   //목표 기간 입력 후, 생기는 점 마커를 비활성화

        defaultTextStyle: TextStyle(  //기본 글꼴(두께, 색)
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
        weekendTextStyle: TextStyle(  //주말 글꼴
          fontWeight: FontWeight.w600,
          color:Color(0xFFFA3A3A),
        ),
        selectedTextStyle: TextStyle(  //선택된 날짜 글꼴
          fontWeight: FontWeight.w600,
          color: PRIMARY_COLOR,
        ),
      ),

      //특정 날짜(day)가 event의 시작일과 종료일 사이에 있는 이벤트들을 가져옴
      eventLoader: (day) {
        // events 리스트에서 특정 날짜가 startDate부터 endDate까지 포함되는 것만 필터
        return events.where((event) =>
        !day.isBefore(event.startDate) && !day.isAfter(event.endDate)
        ).toList();
      },

      //캘린더 커스텀
      calendarBuilders: CalendarBuilders(
        //기간에 하이라이트 표시
        rangeHighlightBuilder: (context, day, eventList) {
          //day가 포함된 이벤트만 matchedEvents에 넣기
            final matchedEvents = events.where(
                  (event) => !day.isBefore(event.startDate) && !day.isAfter(event.endDate),
            ).toList();

            //이벤트가 있다면
            if (matchedEvents.isNotEmpty) {

              //세로로 배치
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, //가로로 늘리기
                children: [

                  //각 이벤트 마다 목표와 하이라이터 표시
                  ...matchedEvents.map((event) {
                    bool Start = day.isAtSameMomentAs(event.startDate); //이벤트 시작일
                    bool End = day.isAtSameMomentAs(event.endDate);     //이벤트 종료일

                    return Container(
                      height: 15, //하이라이터 높이
                      margin: const EdgeInsets.symmetric(vertical: 2),  //하이라이터 간 간격
                      decoration: BoxDecoration(
                        color: PRIMARY_COLOR.withOpacity(0.15), //은은하게

                        //하이라이트의 양쪽은 둥글지만, 중앙은 길게 이어짐
                        borderRadius: BorderRadius.horizontal(
                          left: Start ? const Radius.circular(8) : Radius.zero, //시작일 왼쪽은 둥글게
                          right: End ? const Radius.circular(8) : Radius.zero,  //종료일 오른쪽은 둥글게
                          //나머지에 해당되는 날짜는 둥글지 않게
                        ),),

                      //이벤트 시각일에만 이벤트의 title 표시
                      child: Start
                          ? Center(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,  //길면 ...처리하기
                        ),
                      ) : null,
                    );
                  }).toList(),
                ],
              );
            }
            return null;
          },
          defaultBuilder: (context, day, focusedDay) => null, // defaultBuilder는 비워두기
      ),
    );
  }
}