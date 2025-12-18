import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';

DateTime _stripTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

// Plan (세부 계획)
class Plan {
  final String? id;
  final String? goalId;
  String text;
  DateTime selectdate;
  bool isDone;
  String? hashtag;

  Plan({
    this.id,
    this.goalId,
    required this.text,
    required this.selectdate,
    this.isDone = false,
    this.hashtag,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString(),
      goalId: json['goal_id']?.toString() ?? json['share_goal_id']?.toString(),
      text: json['title'] ?? '',
      selectdate: json['start_at'] != null
          ? DateTime.parse(json['start_at']).toLocal()
          : DateTime.parse(json['created_at']).toLocal(),
      isDone: json['is_completed'] ?? false,
      hashtag: json['hashtag'],
    );
  }

  Map<String, dynamic> toJson(String userId, String goalId) {
    return {
      'goal_id': goalId,
      'user_id': userId,
      'title': text,
      'created_at': DateTime.now().toIso8601String(),
      'start_at': selectdate.toUtc().toIso8601String(),
      'is_completed': isDone,
      'hashtag': hashtag,
    };
  }
}

// Event (목표)
class Event {
  final String? id;
  String title;
  DateTime startDate;
  DateTime endDate;
  bool secret;
  List<String> togeter;
  String? emoji;
  List<Plan> plans;
  Color color;

  bool isCompleted;

  Event({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.secret,
    required this.togeter,
    this.emoji,
    List<Plan>? plans,
    Color? color,
    this.isCompleted = false,
  }) : plans = plans ?? [],
        color = color ?? PRIMARY_COLOR;

  factory Event.fromJson(Map<String, dynamic> json) {
    var plansList = json['todos'] as List?;
    if (plansList == null && json['todos_shares'] != null) {
      plansList = json['todos_shares'] as List?;
    }

    // 종료 날짜 계산
    DateTime calcEndDate = () {
      DateTime dt = DateTime.parse(json['completed_at']).toLocal();
      return DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
    }();

    bool checkIsCompleted = (json['is_completed'] == true) ||
        calcEndDate.isBefore(DateTime.now());

    return Event(
      id: json['id']?.toString(),
      title: json['title'] ?? '',

      startDate: _stripTime(DateTime.parse(json['created_at']).toLocal()),

      endDate: calcEndDate,

      isCompleted: checkIsCompleted,

      secret: json['visibility'] ?? false,
      togeter: json['together'] != null
          ? List<String>.from(json['together'])
          : [],
      emoji: json['emoji'],

      plans: plansList != null
          ? plansList.map((plan) {
        try {
          return Plan.fromJson(plan);
        } catch (e) {
          return null;
        }
      }).whereType<Plan>().toList()
          : [],

      color: json['color'] != null
          ? hexToColor(json['color'])
          : PRIMARY_COLOR,
    );
  }

  Map<String, dynamic> toJson(String ownerId) {
    return {
      'owner_id': ownerId,
      'title': title,
      'created_at': _stripTime(startDate).toIso8601String(),
      'completed_at': _stripTime(endDate).toIso8601String(),
      'visibility': secret,
      'together': togeter,
      'emoji': emoji,
      'color': colorToHex(color),
      'is_completed': isCompleted,
    };
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return PRIMARY_COLOR;
    }
  }
}