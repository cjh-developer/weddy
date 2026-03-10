/// 페이지네이션 응답 모델.
///
/// 서버 응답 구조:
/// ```json
/// {
///   "content": [ ... ],
///   "totalElements": 42,
///   "totalPages": 5,
///   "currentPage": 0,
///   "size": 10
/// }
/// ```
///
/// 사용 예:
/// ```dart
/// ApiResponse<PageResponse<UserDto>>.fromJson(
///   json,
///   (data) => PageResponse.fromJson(
///     data as Map<String, dynamic>,
///     (item) => UserDto.fromJson(item as Map<String, dynamic>),
///   ),
/// );
/// ```
class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int size;

  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.size,
  });

  /// [fromJsonT]: content 배열의 각 요소를 [T]로 변환하는 콜백.
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawContent = json['content'];
    final List<T> parsedContent;

    if (rawContent is List) {
      parsedContent = rawContent.map(fromJsonT).toList();
    } else {
      parsedContent = [];
    }

    return PageResponse<T>(
      content: parsedContent,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
    );
  }

  /// 마지막 페이지 여부.
  ///
  /// [totalPages]가 0인 빈 결과셋은 마지막 페이지로 간주한다.
  /// `totalPages - 1` 연산에서 totalPages=0 이면 -1 이 되어
  /// 우연히 true 를 반환하던 기존 로직을 명시적 조건으로 대체한다.
  bool get isLast => totalPages == 0 || currentPage >= totalPages - 1;

  /// 첫 번째 페이지 여부.
  bool get isFirst => currentPage == 0;

  /// 다음 페이지 번호. 마지막 페이지이면 null 반환.
  int? get nextPage => isLast ? null : currentPage + 1;

  /// 데이터가 비어있는지 여부.
  bool get isEmpty => content.isEmpty;

  PageResponse<T> copyWith({
    List<T>? content,
    int? totalElements,
    int? totalPages,
    int? currentPage,
    int? size,
  }) {
    return PageResponse<T>(
      content: content ?? this.content,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      size: size ?? this.size,
    );
  }

  @override
  String toString() {
    return 'PageResponse('
        'totalElements: $totalElements, '
        'totalPages: $totalPages, '
        'currentPage: $currentPage, '
        'size: $size, '
        'content.length: ${content.length}'
        ')';
  }
}
