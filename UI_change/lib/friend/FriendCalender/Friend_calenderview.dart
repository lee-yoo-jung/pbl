import 'package:flutter/material.dart';
import 'package:pbl/tap/calender/component/main_calender.dart';
import 'package:pbl/tap/calender/component/prints.dart';
import 'package:pbl/const/colors.dart';
import 'package:pbl/tap/calender/component/event.dart';
import 'package:pbl/tap/friend/friendtap.dart';
import 'package:pbl/services/supabase_calendar_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pbl/weather/weather_api_service.dart';
import 'package:pbl/weather/weather_day.dart';

//<메인 화면(캘린더) 구상>

class FriendCalenderview extends StatefulWidget{
  final Friend friend;

  const FriendCalenderview({
    required this.friend,
    Key? key,
  }):super(key:key);

  @override
  State<FriendCalenderview> createState()=>_FriendCalenderviewState();
}

class _FriendCalenderviewState extends State<FriendCalenderview>{
  final CalendarService _calendarService = CalendarService();
  List<Event> eventsList = [];
  bool _isLoading = false;

  //선택된 날짜를 관리할 변수
  DateTime selectedDate=DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // 날씨
  Map<DateTime, WeatherDay> _weatherForecastMap = {};
  final WeatherApiService _weatherService = WeatherApiService();


  //페이지가 생성될 때 한번만 initSate() 생성
  @override
  void initState() {
    super.initState();
    _loadFriendEvents(); // 앱 시작 시 친구 데이터 가져오기
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);

      final forecasts = await _weatherService.fetchAllWeatherForecast(position);

      _weatherForecastMap = forecasts.fold<Map<DateTime, WeatherDay>>({}, (map, day) {
        // 시간 정보를 제거한 순수한 날짜를 키로 사용
        final dateKey = DateTime(day.date.year, day.date.month, day.date.day);
        map[dateKey] = day;
        return map;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendEvents() async {
    setState(() => _isLoading = true);
    try {
      // 서비스에 추가한 getFriendGoals 호출
      final events = await _calendarService.getFriendGoals(widget.friend.uid);
      setState(() {
        eventsList = events;
      });
    } catch (e) {
      print("친구 데이터 로드 실패: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //모든 이벤트를 날짜별로 나눠서 eventsMap에 저장
  Map<DateTime,List<Event>> generateGoals(List<Event> events) {
    final Map<DateTime, List<Event>> map={};

    //사용자의 이벤트 리스트를 순회
    for (var event in events) {
      DateTime current = event.startDate;           //각 이벤트의 startDate(시작 날짜)를 current로 설정
      //endDate(종료 날짜)까지 하루씩 반복
      while (!current.isAfter(event.endDate)) {
        final key = DateTime(current.year,current.month,current.day);         //current를 통일된 형식으로 key에 저장

        //key가 없다면 초기화
        if (!map.containsKey(key)) {
          map[key] = [];
        }
        map[key]!.add(event);                 //위의 key를 eventsMap 인덱스로 사용해 이벤트를 값으로 저장
        current = current.add(const Duration(days: 1));
      }
    }
    return map;
  }

  void _showReadOnlyMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('친구의 일정은 수정할 수 없습니다.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final TogetherGoals=eventsList.where((goal)=> (goal.togeter.isNotEmpty)).toList();
    final SingleGoals=eventsList.where((goal)=> (goal.togeter.isEmpty)).toList();

    final TogetherGoalsMap=generateGoals(TogetherGoals);
    final SingleGoalsMap=generateGoals(SingleGoals);
    final AllGoalsMap=generateGoals(eventsList);

    return DefaultTabController(
      length: 3,
      child: Scaffold(  //상단 앱바
        appBar: AppBar(
          backgroundColor: Colors.white,
          //가로로 배치
          title: Row(
            children: [
              Text("${widget.friend.nickname}님의 캘린더",
                style: TextStyle(
                  color: PRIMARY_COLOR,
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
            ],
          ),
          toolbarHeight: 60.0,  //앱바의 높이 지정
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [
                  Tab(text: '개인'),
                  Tab(text: '개인 & 공동'),
                  Tab(text: '공동'),
                ],
                labelColor: Colors.black ,  //선택된 탭의 글 색상
                unselectedLabelColor: Colors.grey,  //선택되지 않은 탭의 글 색상
                indicatorColor: Colors.black, //선택된 탭 아래 막대 색상
                indicatorWeight: 2.5, //선택된 탭 아래 막대의 높이
                indicatorSize: TabBarIndicatorSize.label, //선택된 탭 아래 막대의 너비: 해당 탭의 글자의 너비에 맞게
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: TabBarView(
            children: [
              Calendar(SingleGoals, SingleGoalsMap),      //개인 캘린더
              Calendar(eventsList, AllGoalsMap),          //개인&공동 캘린더
              Calendar(TogetherGoals, TogetherGoalsMap),  //공동 캘린더
            ],
          ),
        ),

      ),
    );
  }

  Widget Calendar (List<Event> list, Map<DateTime,List<Event>> map){
    return //기기의 하단 메뉴바 같은 시스템 UI를 피해서 구현
      SafeArea(
        //달력과 목표/계획의 리스트를 세로로 배치
        child: Stack(
          children: [
            //'main_calender.dart'의 MainCalendar 위젯 배치
            MainCalendar(
              onDaySelected: (selectedDay, focusedDay) {  //날짜 선택 시 실행할 함수
                setState(() {                             //상태 변경을 알리고 rebuild
                  selectedDate = selectedDay;
                });
              },
              selectedDate: selectedDate,                 //선택된 날짜
              events: map,                          //각 탭에 해당되는 목표 데이터
              weatherForecasts: _weatherForecastMap,
            ),

            //Prints 위젯 배치
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.1,  //화면의 초기 크기
                minChildSize: 0.1,      //최소 크기
                maxChildSize: 0.8,        //최대 크기
                builder: (context,scrollController)=>Prints(
                  selectedDate: selectedDate,           //선택된 날짜
                  eventsMap: map,                 //날짜 별로 이벤트를 저장한 저장소
                  scrollController: scrollController,

                  onPlanUpdated: (Event event) {
                    _showReadOnlyMessage();
                  },

                  //[이벤트 삭제, 계획 추가/삭제/수정] 명령 함수 => 타 사용자 캘린더엔 불가)
                  adddel: (Event event,{Plan? plan, bool removePlan=false ,bool removeEvent=false}) {
                    _showReadOnlyMessage();
                  },
                ),
              ),
            ),
          ],
        ),
      );
  }

}