import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:weddy/features/checklist/data/model/checklist_item_model.dart';
import 'package:weddy/features/checklist/data/model/checklist_model.dart';
import 'package:weddy/features/checklist/presentation/notifier/checklist_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수 (홈 화면 Dark Glass 테마 동일 적용)
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF0D0D1A);
const _kBg2 = Color(0xFF1B0929);
const _kGlass = Color(0x14FFFFFF);
const _kGlassBorder = Color(0x33FFFFFF);
const _kPink = Color(0xFFEC4899);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kTextMute = Color(0x66FFFFFF);
const _kDone = Color(0xFF10B981);
const _kUrgent = Color(0xFFEF4444);
const _kThisWeek = Color(0xFFF59E0B);

// ---------------------------------------------------------------------------
// 유틸 함수
// ---------------------------------------------------------------------------

/// dueDate 기준 D-DAY 문자열 반환.
String _formatDueDate(DateTime? dueDate) {
  if (dueDate == null) return '';
  final today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = due.difference(today).inDays;
  if (diff < 0) return 'D+${-diff}';
  if (diff == 0) return 'D-DAY';
  return 'D-$diff';
}

/// D-DAY 문자열에 따른 색상 반환.
Color _dueDateColor(DateTime? dueDate) {
  if (dueDate == null) return _kTextMute;
  final today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = due.difference(today).inDays;
  if (diff < 0) return _kUrgent;
  if (diff <= 7) return _kThisWeek;
  return _kTextMute;
}

// ---------------------------------------------------------------------------
// ChecklistScreen
// ---------------------------------------------------------------------------

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(checklistNotifierProvider);
      if (state is ChecklistInitial) {
        ref.read(checklistNotifierProvider.notifier).loadChecklists();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final checklistState = ref.watch(checklistNotifierProvider);

    // 에러 SnackBar
    ref.listen<ChecklistState>(checklistNotifierProvider, (prev, next) {
      if (next is ChecklistError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(checklistNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _buildBody(context, checklistState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kGlass,
                shape: BoxShape.circle,
                border: Border.all(color: _kGlassBorder, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kTextSub, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '웨딩 체크리스트',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddChecklistDialog(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPink, Color(0xFFF9A8D4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withOpacity(0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── 본문 ─────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, ChecklistState checklistState) {
    if (checklistState is ChecklistLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kPink),
      );
    }

    if (checklistState is ChecklistError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kUrgent, size: 48),
            const SizedBox(height: 12),
            Text(
              checklistState.message,
              style: const TextStyle(color: _kTextSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () =>
                  ref.read(checklistNotifierProvider.notifier).loadChecklists(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPink, Color(0xFFF9A8D4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (checklistState is ChecklistLoaded) {
      final checklists = checklistState.checklists;
      if (checklists.isEmpty) {
        return _buildEmptyState(context);
      }
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChecklistSection(
                    checklist: checklists[index],
                    onAddItem: (content, dueDate) {
                      ref.read(checklistNotifierProvider.notifier).addItem(
                            checklists[index].oid,
                            content,
                            dueDate,
                            checklists[index].items.length,
                          );
                    },
                    onToggleItem: (itemOid, currentIsDone) {
                      ref.read(checklistNotifierProvider.notifier).toggleItem(
                            checklists[index].oid,
                            itemOid,
                            currentIsDone,
                          );
                    },
                    onDeleteItem: (itemOid) {
                      ref.read(checklistNotifierProvider.notifier).deleteItem(
                            checklists[index].oid,
                            itemOid,
                          );
                    },
                    onDeleteChecklist: () {
                      ref
                          .read(checklistNotifierProvider.notifier)
                          .deleteChecklist(checklists[index].oid);
                    },
                  ),
                ),
                childCount: checklists.length,
              ),
            ),
          ),
        ],
      );
    }

    // ChecklistInitial — 로딩 중 스피너
    return const Center(
      child: CircularProgressIndicator(color: _kPink),
    );
  }

  // ── 빈 상태 ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kGlass,
              shape: BoxShape.circle,
              border: Border.all(color: _kGlassBorder, width: 1.5),
            ),
            child: const Icon(Icons.checklist_rounded,
                color: _kPink, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            '체크리스트가 없습니다',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '+ 버튼을 눌러 체크리스트를 만들어보세요',
            style: TextStyle(fontSize: 13, color: _kTextSub),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showAddChecklistDialog(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPink, Color(0xFFF9A8D4)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withOpacity(0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '첫 체크리스트 만들기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 체크리스트 추가 다이얼로그 ──────────────────────────────────────────
  void _showAddChecklistDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x33FFFFFF), width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0x33EC4899),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.checklist_rounded,
                          color: _kPink, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '새 체크리스트',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kGlass,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _kGlassBorder, width: 1),
                        ),
                        child: const Icon(Icons.close,
                            color: _kTextSub, size: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 제목 입력
                _buildDialogField(
                  controller: titleCtrl,
                  hint: '체크리스트 제목 (필수)',
                  icon: Icons.title,
                ),
                const SizedBox(height: 12),
                // 카테고리 입력
                _buildDialogField(
                  controller: categoryCtrl,
                  hint: '카테고리 (선택, 예: 예식, 스드메, 여행)',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 20),
                // 버튼
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      final category = categoryCtrl.text.trim();
                      Navigator.of(ctx).pop();
                      ref
                          .read(checklistNotifierProvider.notifier)
                          .createChecklist(
                              title, category.isEmpty ? null : category);
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPink, Color(0xFFF9A8D4)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _kPink.withOpacity(0.40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '만들기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      titleCtrl.dispose();
      categoryCtrl.dispose();
    });
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
          prefixIcon: Icon(icon, color: _kPink, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChecklistSection — 체크리스트 카드 (펼침/접기)
// ---------------------------------------------------------------------------

class _ChecklistSection extends StatefulWidget {
  final ChecklistModel checklist;
  final void Function(String content, DateTime? dueDate) onAddItem;
  final void Function(String itemOid, bool currentIsDone) onToggleItem;
  final void Function(String itemOid) onDeleteItem;
  final VoidCallback onDeleteChecklist;

  const _ChecklistSection({
    required this.checklist,
    required this.onAddItem,
    required this.onToggleItem,
    required this.onDeleteItem,
    required this.onDeleteChecklist,
  });

  @override
  State<_ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends State<_ChecklistSection> {
  bool _expanded = true;
  final _addContentCtrl = TextEditingController();

  @override
  void dispose() {
    _addContentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklist = widget.checklist;
    final items = checklist.items;
    final doneCount = items.where((i) => i.isDone).length;

    return Container(
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGlassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kPink.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  // 카테고리 배지 또는 기본 아이콘
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0x33EC4899),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.checklist_rounded,
                        color: _kPink, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (checklist.category != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0x1AEC4899),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              checklist.category!,
                              style: const TextStyle(
                                  fontSize: 10, color: _kPink),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 완료 카운트
                  Text(
                    '$doneCount/${items.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kTextSub,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  // 삭제
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.delete_outline,
                          color: _kTextMute, size: 18),
                    ),
                  ),
                  // 펼침 화살표
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: _kTextSub, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // ── 항목 목록 ──
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                if (items.isNotEmpty) ...[
                  Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.06),
                      indent: 16,
                      endIndent: 16),
                  ...items.map((item) => _ItemTile(
                        item: item,
                        onToggle: () =>
                            widget.onToggleItem(item.oid, item.isDone),
                        onDelete: () => widget.onDeleteItem(item.oid),
                      )),
                ],
                // ── 항목 추가 Row ──
                Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.06),
                    indent: 16,
                    endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x0AFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: TextField(
                            controller: _addContentCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '새 항목 추가...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.30),
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (v) => _submitItem(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _submitItem,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x33EC4899),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0x66EC4899), width: 1),
                          ),
                          child:
                              const Icon(Icons.add, color: _kPink, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  void _submitItem() {
    final content = _addContentCtrl.text.trim();
    if (content.isEmpty) return;
    widget.onAddItem(content, null);
    _addContentCtrl.clear();
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('체크리스트 삭제',
            style: TextStyle(color: _kText, fontSize: 16)),
        content: const Text(
          '체크리스트와 모든 항목이 삭제됩니다.\n계속하시겠습니까?',
          style: TextStyle(color: _kTextSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소',
                style: TextStyle(color: _kTextSub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteChecklist();
            },
            child: const Text('삭제',
                style: TextStyle(color: _kUrgent)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ItemTile — 개별 체크리스트 항목
// ---------------------------------------------------------------------------

class _ItemTile extends StatelessWidget {
  final ChecklistItemModel item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dueDateText = _formatDueDate(item.dueDate);
    final dueDateColor = _dueDateColor(item.dueDate);

    return Dismissible(
      key: Key('item_${item.oid}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _kUrgent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: _kUrgent, size: 20),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 체크 버튼
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isDone
                      ? _kDone.withOpacity(0.20)
                      : const Color(0x0AFFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isDone ? _kDone : const Color(0x44FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: item.isDone
                    ? const Icon(Icons.check, color: _kDone, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // 내용
            Expanded(
              child: Text(
                item.content,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: item.isDone ? _kTextMute : _kText,
                  decoration:
                      item.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: _kTextMute,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // D-DAY 배지
            if (dueDateText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: dueDateColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dueDateText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: dueDateColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
