import 'package:intl/intl.dart';

class AttachmentModel {
  final String oid;
  final String originalName;
  final int fileSize;
  final String mimeType;
  final DateTime createdAt;

  const AttachmentModel({
    required this.oid,
    required this.originalName,
    required this.fileSize,
    required this.mimeType,
    required this.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      oid: json['oid'] as String,
      originalName: json['originalName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      mimeType: json['mimeType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isImage =>
      mimeType == 'image/jpeg' ||
      mimeType == 'image/png' ||
      mimeType == 'image/webp';

  bool get isPdf => mimeType == 'application/pdf';

  String get fileSizeText {
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (fileSize >= 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSize B';
  }

  String get formattedDate {
    final fmt = DateFormat('yy.MM.dd', 'ko_KR');
    return fmt.format(createdAt);
  }
}
