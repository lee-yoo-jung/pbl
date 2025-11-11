// lib/component/event.dart (수정된 파일)

import 'package:supabase_flutter/supabase_flutter.dart';

// 계획 클래스 (Plan)
class Plan {
  String text;
  DateTime selectdate;
  bool isDone;

  Plan({
    required this.text,
    required this.selectdate,
    this.isDone = false,
  });

  // 1. Plan을 위한 JSON 변환 함수들 추가
  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      text: json['text'],
      selectdate: DateTime.parse(json['selectdate']),
      isDone: json['isDone'] ?? false, // <-- 3. DB에서 isDone 상태 읽어오기
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'selectdate': selectdate.toIso8601String(),
      'isDone': isDone, // <-- 4. DB에 isDone 상태 저장하기
    };
  }
}

// 이벤트(목표) 클래스 (Event)
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

  // 4. DB에서 받은 JSON(Map)을 Event 객체로 변환하는 함수
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['created_at']),
      endDate: DateTime.parse(json['completed_at']),
      hashtags: json['hashtag'],
      secret: json['visibility'] == '비공개',
      togeter: json['together'] != null ? List<String>.from(json['together']) : [],
      plans: json['plans'] != null
          ? (json['plans'] as List).map((plan) => Plan.fromJson(plan)).toList()
          : [],
    );
  }

  // 5. Event 객체를 DB에 보낼 JSON(Map)으로 변환하는 함수
  Map<String, dynamic> toJson(String ownerId) {
    return {
      'owner_id': ownerId,
      'title': title,
      'created_at': startDate.toIso8601String(),
      'completed_at': endDate.toIso8601String(),
      'hashtag': hashtags,
      'visibility': secret ? '비공개' : '공개',
      'together': togeter,
      'plans': plans.map((plan) => plan.toJson()).toList(), // plans 목록 전체 저장
    };
  }
}