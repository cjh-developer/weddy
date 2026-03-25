import 'dart:convert';
import 'package:flutter/material.dart';

/// 웨딩 로드맵 단계 모델.
///
/// 각 단계는 고유한 stepType을 가지며, 진행 상태, 마감일, 세부 정보를 포함한다.
class RoadmapStepModel {
  final String oid;
  final String stepType;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final bool hasDueDate;
  final int sortOrder;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  const RoadmapStepModel({
    required this.oid,
    required this.stepType,
    required this.title,
    required this.isDone,
    this.dueDate,
    required this.hasDueDate,
    required this.sortOrder,
    required this.details,
    required this.createdAt,
  });

  factory RoadmapStepModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedDetails = {};
    final rawDetails = json['details'];
    if (rawDetails is Map<String, dynamic>) {
      parsedDetails = rawDetails;
    } else if (rawDetails is String && rawDetails.isNotEmpty) {
      // 서버가 JSON 문자열로 내려보낼 경우 대비
      try {
        parsedDetails = jsonDecode(rawDetails) as Map<String, dynamic>;
      } catch (_) {
        parsedDetails = {};
      }
    }

    return RoadmapStepModel(
      oid: json['oid'] as String,
      stepType: json['stepType'] as String,
      title: json['title'] as String? ??
          defaultTitle(json['stepType'] as String),
      isDone: json['isDone'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      hasDueDate: json['hasDueDate'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      details: parsedDetails,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oid': oid,
      'stepType': stepType,
      'title': title,
      'isDone': isDone,
      if (dueDate != null) 'dueDate': _fmtDate(dueDate!),
      'hasDueDate': hasDueDate,
      'sortOrder': sortOrder,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RoadmapStepModel copyWith({
    String? oid,
    String? stepType,
    String? title,
    bool? isDone,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? hasDueDate,
    int? sortOrder,
    Map<String, dynamic>? details,
    DateTime? createdAt,
  }) {
    return RoadmapStepModel(
      oid: oid ?? this.oid,
      stepType: stepType ?? this.stepType,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      hasDueDate: hasDueDate ?? this.hasDueDate,
      sortOrder: sortOrder ?? this.sortOrder,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 예식일 기준 D-Day 텍스트를 반환한다.
  String dDayText(DateTime weddingDate) {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return '${diff.abs()}일 지남';
    if (diff == 0) return '오늘';

    // 예식일 기준 "몇 개월 전" 표시
    final wedding =
        DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
    final monthsDiff = wedding.difference(due).inDays ~/ 30;
    if (monthsDiff > 0) return '예식 $monthsDiff개월 전';
    return 'D-$diff';
  }

  /// stepType별 기본 제목 (한국어)
  static String defaultTitle(String stepType) {
    switch (stepType) {
      case 'BUDGET':
        return '결혼 예산';
      case 'HALL':
        return '웨딩홀 투어';
      case 'PLANNER':
        return '플래너/예약';
      case 'DRESS':
        return '드레스 투어';
      case 'HOME':
        return '신혼집/부동산';
      case 'TRAVEL':
        return '항공권/여행';
      case 'GIFT':
        return '예물/혼수';
      case 'SANGGYEONRYE':
        return '상견례';
      case 'ETC':
        return '기타';
      default:
        return stepType;
    }
  }

  /// stepType별 Material 아이콘
  static IconData stepIcon(String stepType) {
    switch (stepType) {
      case 'BUDGET':
        return Icons.account_balance_wallet;
      case 'HALL':
        return Icons.celebration;
      case 'PLANNER':
        return Icons.person_outline;
      case 'DRESS':
        return Icons.checkroom;
      case 'HOME':
        return Icons.home_outlined;
      case 'TRAVEL':
        return Icons.flight;
      case 'GIFT':
        return Icons.card_giftcard;
      case 'SANGGYEONRYE':
        return Icons.restaurant;
      case 'ETC':
        return Icons.more_horiz;
      default:
        return Icons.circle_outlined;
    }
  }

  /// stepType별 테마 색상
  static Color stepColor(String stepType) {
    switch (stepType) {
      case 'BUDGET':
        return const Color(0xFF34D399);
      case 'HALL':
        return const Color(0xFFEC4899);
      case 'PLANNER':
        return const Color(0xFF8B5CF6);
      case 'DRESS':
        return const Color(0xFFF472B6);
      case 'HOME':
        return const Color(0xFF22D3EE);
      case 'TRAVEL':
        return const Color(0xFF60A5FA);
      case 'GIFT':
        return const Color(0xFFF59E0B);
      case 'SANGGYEONRYE':
        return const Color(0xFFEF4444);
      case 'ETC':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  /// 전체 stepType 목록 (서버 등록 순서와 동일)
  static const List<String> allStepTypes = [
    'BUDGET',
    'HALL',
    'PLANNER',
    'DRESS',
    'HOME',
    'TRAVEL',
    'GIFT',
    'SANGGYEONRYE',
    'ETC',
  ];
}
