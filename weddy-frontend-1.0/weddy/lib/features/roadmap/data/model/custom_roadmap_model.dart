import 'package:weddy/features/roadmap/data/model/roadmap_step_model.dart';

/// 사용자 정의 로드맵 컨테이너 모델.
///
/// 여러 [RoadmapStepModel]을 그룹화하는 컨테이너이며,
/// 서버의 weddy_custom_roadmaps 테이블과 1:1 대응한다.
class CustomRoadmapModel {
  final String oid;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RoadmapStepModel> steps;

  const CustomRoadmapModel({
    required this.oid,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.steps = const [],
  });

  factory CustomRoadmapModel.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return CustomRoadmapModel(
      oid: json['oid'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      steps: rawSteps
          .map((e) => RoadmapStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CustomRoadmapModel copyWith({
    String? oid,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoadmapStepModel>? steps,
  }) {
    return CustomRoadmapModel(
      oid: oid ?? this.oid,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      steps: steps ?? this.steps,
    );
  }
}
