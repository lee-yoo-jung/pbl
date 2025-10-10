import 'package:supabase_flutter/supabase_flutter.dart';

// Plan 클래스: JSON 변환 기능 추가
class Plan {
  String text;
  DateTime selectdate;

  Plan({
    required this.text,
    required this.selectdate,
  });

  // Supabase에서 받은 JSON(Map)을 Plan 객체로 변환하는 생성자
  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      text: json['text'],
      selectdate: DateTime.parse(json['selectdate']),
    );
  }

  // Plan 객체를 Supabase에 보낼 JSON(Map)으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'selectdate': selectdate.toIso8601String(),
    };
  }
}

class Event {
  final int? id;
  String title;
  DateTime startDate;
  DateTime endDate;
  String hashtags;
  bool secret;
  List<String> togeter;
  List<Plan> plans;

  Event({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.togeter,
    required this.hashtags,
    required this.secret,
    List<Plan>? plans,
  }) : plans = plans ?? [];

  // Supabase에서 받은 JSON(Map)을 Event 객체로 변환하는 생성자
  factory Event.fromJson(Map<String, dynamic> json) {
    final List<Plan> planList = json['plans'] != null
        ? (json['plans'] as List).map((plan) => Plan.fromJson(plan)).toList()
        : [];

    final List<String> togetherList = json['together'] != null
        ? List<String>.from(json['together'])
        : [];

    return Event(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['created_at']),
      endDate: DateTime.parse(json['completed_at']),
      hashtags: json['hashtag'],
      secret: json['visibility'] == false,
      togeter: togetherList,
      plans: planList,
    );
  }

  // Event 객체를 Supabase에 보낼 JSON(Map)으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return {
      'owner_id': userId,
      'title': title,
      'created_at': startDate.toIso8601String(),
      'completed_at': endDate.toIso8601String(),
      'hashtag': hashtags,
      'visibility': secret ? false : true,
      'together': togeter,
      'plans': plans.map((plan) => plan.toJson()).toList(),
    };
  }
}