import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/attachment/data/model/attachment_model.dart';
import 'package:weddy/features/attachment/presentation/notifier/attachment_notifier.dart';

class AttachmentThumbnailWidget extends ConsumerStatefulWidget {
  final AttachmentModel attachment;
  final String refType;
  final String refOid;

  const AttachmentThumbnailWidget({
    super.key,
    required this.attachment,
    required this.refType,
    required this.refOid,
  });

  @override
  ConsumerState<AttachmentThumbnailWidget> createState() =>
      _AttachmentThumbnailWidgetState();
}

class _AttachmentThumbnailWidgetState
    extends ConsumerState<AttachmentThumbnailWidget> {
  Uint8List? _imageBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isImage) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.get<List<int>>(
        '/attachments/${widget.attachment.oid}/download',
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      if (res.data != null) {
        setState(() {
          _imageBytes = Uint8List.fromList(res.data!);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    return Stack(
      children: [
        GestureDetector(
          onLongPress: () => _showDeleteDialog(context),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33FFFFFF), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildContent(a),
            ),
          ),
        ),
        // 삭제 버튼
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _showDeleteDialog(context),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AttachmentModel a) {
    if (a.isImage) {
      if (_loading) {
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white54),
          ),
        );
      }
      if (_imageBytes != null) {
        return Image.memory(_imageBytes!, fit: BoxFit.cover);
      }
      return const Icon(Icons.image, color: Colors.white38, size: 28);
    }
    // PDF
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 28),
        const SizedBox(height: 4),
        Text(
          a.fileSizeText,
          style: const TextStyle(fontSize: 9, color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('파일 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${widget.attachment.originalName}"을(를) 삭제하시겠습니까?',
          style: const TextStyle(color: Color(0xAAFFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('삭제', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref
            .read(attachmentNotifierProvider(
                    (widget.refType, widget.refOid))
                .notifier)
            .delete(widget.attachment.oid);
      }
    });
  }
}
