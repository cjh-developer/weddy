import 'package:flutter/material.dart';

/// 일정 단일 항목 모델.
///
/// 서버 응답 JSON을 파싱하며, 카테고리별 색상을 정적 메서드로 제공한다.
class ScheduleModel {
  final String oid;
  final String title;
  final String? description;
  final String category;
  final bool isAllDay;
  final DateTime startAt;
  final DateTime? endAt;
  final String? location;
  final String? alertBefore;
  final String? sourceType;
  final DateTime createdAt;

  const ScheduleModel({
    required this.oid,
    required this.title,
    this.description,
    required this.category,
    required this.isAllDay,
    required this.startAt,
    this.endAt,
    this.location,
    this.alertBefore,
    this.sourceType,
    required this.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      oid: json['oid'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? '기타',
      isAllDay: json['isAllDay'] as bool? ?? false,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] != null
          ? DateTime.parse(json['endAt'] as String)
          : null,
      location: json['location'] as String?,
      alertBefore: json['alertBefore'] as String?,
      sourceType: json['sourceType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oid': oid,
      'title': title,
      if (description != null) 'description': description,
      'category': category,
      'isAllDay': isAllDay,
      'startAt': startAt.toIso8601String(),
      if (endAt != null) 'endAt': endAt!.toIso8601String(),
      if (location != null) 'location': location,
      if (alertBefore != null) 'alertBefore': alertBefore,
      if (sourceType != null) 'sourceType': sourceType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ScheduleModel copyWith({
    String? oid,
    String? title,
    String? description,
    String? category,
    bool? isAllDay,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? alertBefore,
    String? sourceType,
    DateTime? createdAt,
  }) {
    return ScheduleModel(
      oid: oid ?? this.oid,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isAllDay: isAllDay ?? this.isAllDay,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      alertBefore: alertBefore ?? this.alertBefore,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 카테고리별 테마 색상을 반환한다.
  static Color categoryColor(String category) {
    switch (category) {
      case '예식장':
        return const Color(0xFFEC4899);
      case '플래너':
        return const Color(0xFF8B5CF6);
      case '스튜디오':
        return const Color(0xFF60A5FA);
      case '드레스':
        return const Color(0xFFF472B6);
      case '메이크업':
        return const Color(0xFFFBBF24);
      case '신혼여행':
        return const Color(0xFF34D399);
      case '예물':
        return const Color(0xFFF59E0B);
      case '혼수':
        return const Color(0xFF22D3EE);
      case '백화점':
        return const Color(0xFFA78BFA);
      case '상견례':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  /// 지원하는 카테고리 목록
  static const List<String> categories = [
    '예식장',
    '플래너',
    '스튜디오',
    '드레스',
    '메이크업',
    '신혼여행',
    '예물',
    '혼수',
    '백화점',
    '상견례',
    '기타',
  ];

  /// 알림 설정 선택지 (서버 전송값 → 표시 레이블)
  static const Map<String, String> alertOptions = {
    '': '없음',
    '10MINUTES': '10분 전',
    '30MINUTES': '30분 전',
    '1HOUR': '1시간 전',
    '1DAY': '1일 전',
    '3DAYS': '3일 전',
    '1WEEK': '1주일 전',
  };
}
