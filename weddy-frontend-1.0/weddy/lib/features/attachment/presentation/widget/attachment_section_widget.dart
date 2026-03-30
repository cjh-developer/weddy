import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:weddy/features/attachment/data/model/attachment_model.dart';
import 'package:weddy/features/attachment/presentation/notifier/attachment_notifier.dart';
import 'package:weddy/features/attachment/presentation/widget/attachment_thumbnail_widget.dart';

/// 첨부파일 섹션 위젯.
/// 로드맵 BottomSheet 및 예산 카테고리 카드 하단에 공용으로 사용한다.
class AttachmentSectionWidget extends ConsumerStatefulWidget {
  final String refType; // 'ROADMAP_STEP' | 'BUDGET'
  final String refOid;

  const AttachmentSectionWidget({
    super.key,
    required this.refType,
    required this.refOid,
  });

  @override
  ConsumerState<AttachmentSectionWidget> createState() =>
      _AttachmentSectionWidgetState();
}

class _AttachmentSectionWidgetState
    extends ConsumerState<AttachmentSectionWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(attachmentNotifierProvider(
                  (widget.refType, widget.refOid))
              .notifier)
          .loadAttachments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref
        .watch(attachmentNotifierProvider((widget.refType, widget.refOid)));

    ref.listen<AttachmentState>(
      attachmentNotifierProvider((widget.refType, widget.refOid)),
      (prev, next) {
        if (next is AttachmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: const Color(0xFF2A2A3E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          ref
              .read(attachmentNotifierProvider(
                      (widget.refType, widget.refOid))
                  .notifier)
              .clearError();
        }
      },
    );

    final attachments = switch (state) {
      AttachmentLoaded(attachments: final list) => list,
      AttachmentUploading(current: final list) => list,
      _ => <AttachmentModel>[],
    };
    final isUploading = state is AttachmentUploading;
    final isLoading = state is AttachmentLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file,
                    color: Color(0xAAFFFFFF), size: 15),
                const SizedBox(width: 6),
                Text(
                  '첨부파일 (${attachments.length}/20)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xAAFFFFFF),
                  ),
                ),
                if (isLoading || isUploading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white54),
                  ),
                ],
              ],
            ),
            // 파일 추가 버튼 — 업로드 중이거나 20개 이상이면 비활성화
            if (attachments.length < 20 && !isUploading)
              GestureDetector(
                onTap: () => _showPickerSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1AEC4899),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0x33EC4899), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: Color(0xFFEC4899)),
                      SizedBox(width: 4),
                      Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEC4899),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // 썸네일 그리드
        if (attachments.isEmpty && !isLoading)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0x22FFFFFF),
                  width: 1,
                  style: BorderStyle.solid),
            ),
            child: const Center(
              child: Text(
                '계약서, 현장 사진, PDF를 첨부하세요',
                style:
                    TextStyle(fontSize: 12, color: Color(0x55FFFFFF)),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...attachments.map(
                (a) => AttachmentThumbnailWidget(
                  key: ValueKey(a.oid),
                  attachment: a,
                  refType: widget.refType,
                  refOid: widget.refOid,
                ),
              ),
              if (isUploading)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0x33FFFFFF), width: 1),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _sheetTile(
              ctx,
              icon: Icons.photo_library_outlined,
              label: '사진 선택',
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.gallery);
              },
            ),
            _sheetTile(
              ctx,
              icon: Icons.camera_alt_outlined,
              label: '카메라',
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.camera);
              },
            ),
            _sheetTile(
              ctx,
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF 파일',
              onTap: () async {
                Navigator.pop(ctx);
                await _pickPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xFile == null || !mounted) return;

      // MIME 타입 결정
      final ext = xFile.path.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      await ref
          .read(attachmentNotifierProvider(
                  (widget.refType, widget.refOid))
              .notifier)
          .upload(xFile.path, xFile.name, mime);
    } catch (_) {
      // 사용자 취소 등 무시
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null ||
          !mounted) return;

      final file = result.files.first;
      await ref
          .read(attachmentNotifierProvider(
                  (widget.refType, widget.refOid))
              .notifier)
          .upload(file.path!, file.name, 'application/pdf');
    } catch (_) {
      // 사용자 취소 등 무시
    }
  }
}
