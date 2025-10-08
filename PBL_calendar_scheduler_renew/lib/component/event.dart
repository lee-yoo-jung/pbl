// 계획 클래스
class Plan {
  String text;         // 계획 내용
  DateTime selectdate;  // 계획 시작 시간 (날짜 포함)

  Plan({
    required this.text,
    required this.selectdate,
  });
}

// 이벤트(목표) 클래스
class Event {
  String title;
  DateTime startDate;
  DateTime endDate;
  String hashtags;
  bool secret;
  List<String> togeter=[];
  List<Plan> plans = [];  //이벤트 속 계획 리스트, 일단 초기화

  Event({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.togeter,
    required this.hashtags,
    required this.secret,
    List<Plan>? plans,
  }): plans = plans ?? [];

}

List<Event> eventsList = [];  //빈 객체 리스트