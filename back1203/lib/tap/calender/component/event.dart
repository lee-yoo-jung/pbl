import 'package:flutter/material.dart';
import 'package:pbl/const/colors.dart';

//Plan
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
      goalId: json['goal_id']?.toString(),
      text: json['title'] ?? '', // DB 컬럼명은 title
      selectdate: DateTime.parse(json['created_at']).toLocal(), // DB 컬럼명은 created_at
      isDone: json['is_completed'] ?? false,
      hashtag: json['hashtag'],
    );
  }

  Map<String, dynamic> toJson(String userId, String goalId) {
    return {
      'goal_id': goalId,
      'user_id': userId,
      'title': text,
      'created_at': selectdate.toIso8601String(),
      'is_completed': isDone,
      'hashtag': hashtag,
    };
  }
}

//Event
class Event {
  final String? id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  bool secret;
  List<String> togeter;
  String? emoji;
  List<Plan> plans;
  Color color;

  Event({
    this.id,
    required this.title,
    this.description = '',
    required this.startDate,
    required this.endDate,
    required this.secret,
    required this.togeter,
    this.emoji,
    List<Plan>? plans,
    Color? color,
  }) : plans = plans ?? [],
        color = color ?? PRIMARY_COLOR;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['created_at']).toLocal(),
      endDate: DateTime.parse(json['completed_at']).toLocal(),
      secret: json['visibility'] ?? false,
      togeter: json['together'] != null ? List<String>.from(json['together']) : [],
      emoji: json['emoji'],
      plans: json['todos'] != null
          ? (json['todos'] as List).map((plan) => Plan.fromJson(plan)).toList()
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
      'description': description,
      'created_at': startDate.toIso8601String(),
      'completed_at': endDate.toIso8601String(),
      'visibility': secret,
      'together': togeter,
      'emoji': emoji,
      'color': colorToHex(color),
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