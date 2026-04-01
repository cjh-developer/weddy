import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:weddy/features/attachment/presentation/widget/attachment_section_widget.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/roadmap/data/model/custom_roadmap_model.dart';
import 'package:weddy/features/roadmap/data/model/hall_tour_model.dart';
import 'package:weddy/features/roadmap/data/model/roadmap_step_model.dart';
import 'package:weddy/features/roadmap/presentation/notifier/custom_roadmap_notifier.dart';
import 'package:weddy/features/roadmap/presentation/notifier/roadmap_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF1A1A19);
const _kBg2 = Color(0xFF111110);
const _kGlass = Color(0x14FFFFFF);
const _kGlassBorder = Color(0x33FFFFFF);
const _kPink = Color(0xFFEC4899);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kTextMute = Color(0x66FFFFFF);
const _kDone = Color(0xFF10B981);
const _kUrgent = Color(0xFFEF4444);

// ---------------------------------------------------------------------------
// 유틸
// ---------------------------------------------------------------------------

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _fmtMoney(int amount) {
  final fmt = NumberFormat('#,###', 'ko_KR');
  return '${fmt.format(amount)}원';
}

// ---------------------------------------------------------------------------
// RoadmapScreen
// ---------------------------------------------------------------------------

class RoadmapScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  const RoadmapScreen({super.key, this.showBackButton = false, this.onBack});

  @override
  ConsumerState<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends ConsumerState<RoadmapScreen>
    with TickerProviderStateMixin {

  TabController? _tabController;

  // ── TabController 초기화 (동적 탭 수 지원) ───────────────────────────────

  void _initTabController({int tabCount = 2, int jumpTo = 0}) {
    final old = _tabController;
    final count = tabCount < 2 ? 2 : tabCount;
    final controller = TabController(length: count, vsync: this);
    if (jumpTo > 0 && jumpTo < count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.animateTo(jumpTo);
      });
    }
    controller.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _tabController = controller);
    old?.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) return;
      // Initial / Error 상태일 때만 loadSteps() 호출 (Loaded/Loading 중복 방지)
      final current = ref.read(roadmapNotifierProvider);
      if (current is RoadmapInitial || current is RoadmapError) {
        ref.read(roadmapNotifierProvider.notifier).loadSteps();
      }
      // 직접 로드맵도 초기 로드
      final customCurrent = ref.read(customRoadmapNotifierProvider);
      if (customCurrent is CustomRoadmapInitial ||
          customCurrent is CustomRoadmapError) {
        ref.read(customRoadmapNotifierProvider.notifier).loadCustomRoadmaps();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapNotifierProvider);
    final customState = ref.watch(customRoadmapNotifierProvider);

    // 에러 스낵바
    ref.listen<RoadmapState>(roadmapNotifierProvider, (prev, next) {
      if (next is RoadmapError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(roadmapNotifierProvider.notifier).clearError();
      }
    });

    // customRoadmaps가 로드되면 탭 컨트롤러 재초기화
    final customRoadmaps = customState is CustomRoadmapLoaded
        ? customState.roadmaps
        : <CustomRoadmapModel>[];
    final expectedTabCount = 1 + customRoadmaps.length + 1; // 기본 + custom들 + "+"
    if (_tabController == null || _tabController!.length != expectedTabCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initTabController(tabCount: expectedTabCount);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFab(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: SafeArea(
          child: _buildBody(context, roadmapState),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 18),
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: const Text(
        '웨딩 관리',
        style:
            TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, RoadmapState state) {
    if (state is RoadmapLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kPink, strokeWidth: 2),
      );
    }

    if (state is RoadmapLoaded) {
      if (_tabController == null) {
        return const Center(
          child: CircularProgressIndicator(color: _kPink, strokeWidth: 2),
        );
      }

      // 기본 탭: groupOid가 null인 단계 (서버가 이미 필터링하지만 클라이언트도 방어)
      final basicSteps =
          state.steps.where((s) => s.groupOid == null).toList();

      final customState = ref.watch(customRoadmapNotifierProvider);
      final customRoadmaps = customState is CustomRoadmapLoaded
          ? customState.roadmaps
          : <CustomRoadmapModel>[];

      final authState = ref.read(authNotifierProvider);
      final weddingDate =
          authState is AuthAuthenticated ? authState.user.weddingDate : null;

      // 탭 수 검증 (1 + customRoadmaps.length + 1)
      final expectedTabCount = 1 + customRoadmaps.length + 1;
      if (_tabController!.length != expectedTabCount) {
        return const Center(
          child: CircularProgressIndicator(color: _kPink, strokeWidth: 2),
        );
      }

      return Column(
        children: [
          _buildTabBar(basicSteps, customRoadmaps),
          const Divider(height: 1, color: Color(0x22FFFFFF)),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                // Tab 0 — 기본 로드맵
                _BasicRoadmapTimelineView(
                  steps: basicSteps,
                  weddingDate: weddingDate,
                  onUpdateStatus: (oid, newStatus) =>
                      ref.read(roadmapNotifierProvider.notifier).updateStatus(oid, newStatus),
                  onTap: (step) => _showStepDetailBottomSheet(context, step),
                  onInitDefault: () =>
                      ref.read(roadmapNotifierProvider.notifier).initDefaultRoadmap(),
                ),
                // Tab 1~N — 직접 로드맵들
                ...customRoadmaps.map((roadmap) => _CustomRoadmapTabView(
                  roadmap: roadmap,
                  weddingDate: weddingDate,
                  onUpdateStatus: (oid, newStatus) =>
                      ref.read(roadmapNotifierProvider.notifier).updateStatus(oid, newStatus),
                  onTap: (step) => _showStepDetailBottomSheet(context, step),
                  onShowMenu: () => _showCustomRoadmapMenu(context, roadmap),
                )),
                // 마지막 탭 — "+" (빈 안내 화면)
                const _AddRoadmapTab(),
              ],
            ),
          ),
        ],
      );
    }

    return _buildEmptyState(context);
  }

  Widget _buildTabBar(
      List<RoadmapStepModel> basicSteps,
      List<CustomRoadmapModel> customRoadmaps) {
    if (_tabController == null) return const SizedBox.shrink();

    final doneCnt = basicSteps.where((s) => s.isDone).length;
    final totalCnt = basicSteps.length;

    return TabBar(
      controller: _tabController!,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      indicatorColor: _kPink,
      indicatorWeight: 2,
      labelColor: _kText,
      unselectedLabelColor: _kTextMute,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      dividerColor: Colors.transparent,
      tabs: [
        // Tab 0 — 기본 로드맵
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14),
              const SizedBox(width: 6),
              const Text('기본 로드맵'),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kPink.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '$doneCnt/$totalCnt',
                  style: const TextStyle(fontSize: 10, color: _kPink),
                ),
              ),
            ],
          ),
        ),
        // Tab 1~N — 직접 로드맵들
        ...customRoadmaps.map((roadmap) {
          final doneCount = roadmap.steps.where((s) => s.isDone).length;
          final totalCount = roadmap.steps.length;
          return Tab(
            child: GestureDetector(
              onLongPress: () => _showCustomRoadmapMenu(context, roadmap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note, size: 14),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      roadmap.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF60A5FA).withOpacity(0.3),
                            width: 1),
                      ),
                      child: Text(
                        '$doneCount/$totalCount',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF60A5FA)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        // 마지막 탭 — "+"
        const Tab(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.add_circle_outline,
                size: 20, color: Color(0xFF60A5FA)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 56,
            color: _kPink.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            '웨딩 관리 정보를 불러오지 못했습니다.',
            style: TextStyle(fontSize: 14, color: _kTextSub),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(roadmapNotifierProvider.notifier).loadSteps(),
            child: const Text('다시 시도', style: TextStyle(color: _kPink)),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    final tabIndex = _tabController?.index;
    if (tabIndex == null) return const SizedBox.shrink();

    final stateVal = ref.read(roadmapNotifierProvider);
    if (stateVal is! RoadmapLoaded) return const SizedBox.shrink();

    final customState = ref.read(customRoadmapNotifierProvider);
    final customRoadmaps = customState is CustomRoadmapLoaded
        ? customState.roadmaps
        : <CustomRoadmapModel>[];

    final isBasicTab = tabIndex == 0;
    final isPlusTab = tabIndex == 1 + customRoadmaps.length;
    final isCustomTab =
        !isBasicTab && !isPlusTab && tabIndex >= 1 && tabIndex <= customRoadmaps.length;

    // "+" 탭: 새 직접 로드맵 생성
    if (isPlusTab) {
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF60A5FA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('로드맵 추가',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () => _showCreateRoadmapDialog(context, customRoadmaps.length),
      );
    }

    // 기본 탭 FAB
    if (isBasicTab) {
      final basicExisting = stateVal.steps
          .where((s) => s.groupOid == null && s.stepType != 'ETC')
          .map((s) => s.stepType)
          .toList();
      return FloatingActionButton.extended(
        backgroundColor: _kPink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('단계 추가',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            builder: (ctx) {
              final maxH = MediaQuery.of(ctx).size.height * 0.85;
              final maxW = MediaQuery.of(ctx).size.width - 40;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
                  child: Material(
                    color: Colors.transparent,
                    child: _AddStepBottomSheet(
                      scaffoldContext: context,
                      notifier: ref.read(roadmapNotifierProvider.notifier),
                      existingStepTypes: basicExisting,
                      hideEtc: true,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // 직접 로드맵 탭 FAB
    if (isCustomTab) {
      final roadmap = customRoadmaps[tabIndex - 1];
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF60A5FA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('항목 추가',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            builder: (ctx) {
              final maxH = MediaQuery.of(ctx).size.height * 0.85;
              final maxW = MediaQuery.of(ctx).size.width - 40;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
                  child: Material(
                    color: Colors.transparent,
                    child: _AddStepBottomSheet(
                      scaffoldContext: context,
                      notifier: ref.read(roadmapNotifierProvider.notifier),
                      existingStepTypes: const [],
                      hideEtc: false,
                      groupOid: roadmap.oid,
                      onSuccess: () {
                        ref
                            .read(customRoadmapNotifierProvider.notifier)
                            .loadCustomRoadmaps();
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showStepDetailBottomSheet(
      BuildContext context, RoadmapStepModel step) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: _StepDetailBottomSheet(
          step: step,
          scaffoldContext: context,
          notifier: ref.read(roadmapNotifierProvider.notifier),
          onSaved: step.groupOid != null
              ? () => ref
                  .read(customRoadmapNotifierProvider.notifier)
                  .loadCustomRoadmaps()
              : null,
          onDeleted: step.groupOid != null
              ? () => ref
                  .read(customRoadmapNotifierProvider.notifier)
                  .loadCustomRoadmaps()
              : null,
        ),
      ),
    );
  }

  // ── 직접 로드맵 관리 메서드 ──────────────────────────────────────────────

  void _showCustomRoadmapMenu(BuildContext context, CustomRoadmapModel roadmap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x44FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                roadmap.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: Colors.white70),
              title: const Text('이름 변경',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, roadmap);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Color(0xFFEF4444)),
              title: const Text('삭제',
                  style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteCustomRoadmap(context, roadmap);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, CustomRoadmapModel roadmap) {
    final ctrl = TextEditingController(text: roadmap.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로드맵 이름 변경',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: '로드맵 이름',
            hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x33FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEC4899)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소',
                style: TextStyle(color: Color(0xAAFFFFFF))),
          ),
          TextButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              await ref
                  .read(customRoadmapNotifierProvider.notifier)
                  .renameCustomRoadmap(roadmap.oid, newName);
            },
            child: const Text('변경',
                style: TextStyle(color: Color(0xFFEC4899))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomRoadmap(
      BuildContext context, CustomRoadmapModel roadmap) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로드맵 삭제',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(
          '"${roadmap.name}" 로드맵과 소속 항목을 모두 삭제합니다.',
          style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소',
                style: TextStyle(color: Color(0xAAFFFFFF))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(customRoadmapNotifierProvider.notifier)
                  .deleteCustomRoadmap(roadmap.oid);
              // 기본 로드맵 탭으로 이동
              _tabController?.animateTo(0);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showCreateRoadmapDialog(BuildContext context, int currentCount) {
    if (currentCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('직접 로드맵은 최대 10개까지 만들 수 있습니다.'),
          backgroundColor: Color(0xFF2A2A3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('새 로드맵 추가',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: '로드맵 이름 (예: 스드메, 신혼여행)',
            hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x33FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF60A5FA)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소',
                style: TextStyle(color: Color(0xAAFFFFFF))),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              final newRoadmap = await ref
                  .read(customRoadmapNotifierProvider.notifier)
                  .createCustomRoadmap(name);
              if (newRoadmap != null && mounted) {
                // 새로 생성된 탭으로 이동
                final latestCustomState =
                    ref.read(customRoadmapNotifierProvider);
                final roadmaps = latestCustomState is CustomRoadmapLoaded
                    ? latestCustomState.roadmaps
                    : <CustomRoadmapModel>[];
                final newIndex =
                    roadmaps.indexWhere((r) => r.oid == newRoadmap.oid);
                if (newIndex >= 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _tabController?.animateTo(newIndex + 1);
                  });
                }
              }
            },
            child: const Text('추가',
                style: TextStyle(color: Color(0xFF60A5FA))),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 기본 로드맵 — 기간별 그룹 카드 뷰
// ---------------------------------------------------------------------------

class _BasicRoadmapTimelineView extends StatelessWidget {
  final List<RoadmapStepModel> steps;
  final DateTime? weddingDate;
  final void Function(String oid, String newStatus) onUpdateStatus;
  final void Function(RoadmapStepModel step) onTap;
  final VoidCallback? onInitDefault;

  const _BasicRoadmapTimelineView({
    required this.steps,
    this.weddingDate,
    required this.onUpdateStatus,
    required this.onTap,
    this.onInitDefault,
  });

  List<_PeriodGroup> _buildGroups() {
    final Map<String, List<RoadmapStepModel>> groupMap = {};
    final Map<String, DateTime?> groupDates = {};
    for (final step in steps) {
      final label = (weddingDate != null && step.dueDate != null)
          ? step.dDayText(weddingDate!)
          : step.dueDate != null
              ? DateFormat('yyyy.MM.dd').format(step.dueDate!)
              : '날짜 미정';
      groupMap.putIfAbsent(label, () => []).add(step);
      groupDates.putIfAbsent(label, () => step.dueDate);
    }
    return groupMap.entries
        .map((e) => _PeriodGroup(label: e.key, dueDate: groupDates[e.key], steps: e.value))
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return _buildEmptyBasic();
    final groups = _buildGroups();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: groups.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildProgressHeader();
        final group = groups[i - 1];
        return _PeriodGroupTile(
          key: ValueKey(group.label),
          group: group,
          isLast: i == groups.length,
          onUpdateStatus: onUpdateStatus,
          onTap: onTap,
        );
      },
    );
  }

  // 진행률 헤더 (컴팩트)
  Widget _buildProgressHeader() {
    final total = steps.length;
    final done = steps.where((s) => s.status == 'DONE').length;
    final inProgress = steps.where((s) => s.status == 'IN_PROGRESS').length;
    final notStarted = total - done - inProgress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '결혼 준비 여정',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText),
              ),
              Text(
                '$done / $total 완료',
                style: const TextStyle(fontSize: 12, color: _kTextSub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: total == 0
                  ? Container(color: const Color(0x2210B981))
                  : Row(
                      children: [
                        if (done > 0) Flexible(flex: done, child: Container(color: _kDone)),
                        if (inProgress > 0) Flexible(flex: inProgress, child: Container(color: const Color(0xFFF59E0B))),
                        if (notStarted > 0) Flexible(flex: notStarted, child: Container(color: const Color(0x2210B981))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatusBadge('완료', done, _kDone),
              const SizedBox(width: 6),
              _StatusBadge('진행중', inProgress, const Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              _StatusBadge('미진행', notStarted, const Color(0x66FFFFFF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBasic() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kPink.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _kPink.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome, size: 32, color: _kPink),
          ),
          const SizedBox(height: 16),
          const Text(
            '기본 로드맵이 없습니다.',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kText),
          ),
          const SizedBox(height: 6),
          const Text(
            '결혼 날짜 기준 8단계를 자동 생성합니다.',
            style: TextStyle(fontSize: 13, color: _kTextSub),
          ),
          const SizedBox(height: 24),
          if (onInitDefault != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPink,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.auto_awesome,
                  size: 18, color: Colors.white),
              label: const Text(
                '기본 로드맵 생성',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              onPressed: onInitDefault,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 직접 로드맵 탭 뷰 (CustomRoadmap 컨테이너 한 개에 해당)
// ---------------------------------------------------------------------------

class _CustomRoadmapTabView extends StatefulWidget {
  final CustomRoadmapModel roadmap;
  final DateTime? weddingDate;
  final void Function(String oid, String newStatus) onUpdateStatus;
  final void Function(RoadmapStepModel step) onTap;
  final VoidCallback? onShowMenu;

  const _CustomRoadmapTabView({
    required this.roadmap,
    this.weddingDate,
    required this.onUpdateStatus,
    required this.onTap,
    this.onShowMenu,
  });

  @override
  State<_CustomRoadmapTabView> createState() => _CustomRoadmapTabViewState();
}

class _CustomRoadmapTabViewState extends State<_CustomRoadmapTabView> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final steps = widget.roadmap.steps;

    if (steps.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        // 헤더 (이름 + 진행률 + 순서 변경 버튼)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roadmap.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${steps.where((s) => s.isDone).length}/${steps.length} 완료',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xAAFFFFFF)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      _isEditMode ? Icons.check : Icons.swap_vert,
                      size: 16,
                      color: const Color(0xFF60A5FA),
                    ),
                    label: Text(
                      _isEditMode ? '완료' : '순서 변경',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF60A5FA)),
                    ),
                    onPressed: () => setState(() => _isEditMode = !_isEditMode),
                  ),
                  if (widget.onShowMenu != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Color(0x88FFFFFF), size: 18),
                      onPressed: widget.onShowMenu,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isEditMode
              ? _buildReorderableList(steps)
              : _buildTimeline(steps),
        ),
      ],
    );
  }

  Widget _buildTimeline(List<RoadmapStepModel> steps) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: steps.length,
      itemBuilder: (ctx, i) {
        final step = steps[i];
        return _TimelineStepNode(
          key: ValueKey(step.oid),
          step: step,
          weddingDate: widget.weddingDate,
          isFirst: i == 0,
          isLast: i == steps.length - 1,
          onUpdateStatus: () =>
              widget.onUpdateStatus(step.oid, step.nextStatus),
          onTap: () => widget.onTap(step),
        );
      },
    );
  }

  Widget _buildReorderableList(List<RoadmapStepModel> steps) {
    return Consumer(
      builder: (context, ref, _) => ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: steps.length,
        onReorder: (oldIndex, newIndex) {
          final list = List<RoadmapStepModel>.from(steps);
          if (newIndex > oldIndex) newIndex--;
          final item = list.removeAt(oldIndex);
          list.insert(newIndex, item);
          ref.read(roadmapNotifierProvider.notifier).reorderSteps(list);
        },
        itemBuilder: (ctx, i) {
          final step = steps[i];
          return _TimelineStepNode(
            key: ValueKey(step.oid),
            step: step,
            weddingDate: widget.weddingDate,
            isFirst: i == 0,
            isLast: i == steps.length - 1,
            onUpdateStatus: () =>
                widget.onUpdateStatus(step.oid, step.nextStatus),
            onTap: () => widget.onTap(step),
            showDragHandle: true,
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF60A5FA).withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.edit_note,
                size: 32, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 16),
          Text(
            '"${widget.roadmap.name}" 로드맵이 비어있습니다.',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            '아래 + 버튼을 눌러 항목을 추가하세요.',
            style: TextStyle(fontSize: 13, color: Color(0xAAFFFFFF)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "+" 탭 안내 화면
// ---------------------------------------------------------------------------

class _AddRoadmapTab extends StatelessWidget {
  const _AddRoadmapTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF60A5FA).withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.add, size: 32, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 16),
          const Text(
            '직접 로드맵 추가',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            '아래 + 버튼을 눌러 새 로드맵을 만드세요.',
            style: TextStyle(fontSize: 13, color: Color(0xAAFFFFFF)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 타임라인 노드 — 수직 라인 + 마커 + 카드
// ---------------------------------------------------------------------------

class _TimelineStepNode extends StatelessWidget {
  final RoadmapStepModel step;
  final DateTime? weddingDate;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onUpdateStatus;
  final VoidCallback onTap;
  final bool showDragHandle;

  const _TimelineStepNode({
    super.key,
    required this.step,
    this.weddingDate,
    required this.isFirst,
    required this.isLast,
    required this.onUpdateStatus,
    required this.onTap,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.effectiveColor;
    final dDayText =
        weddingDate != null ? step.dDayText(weddingDate!) : '';
    final isOverdue = step.status == 'NOT_STARTED' && dDayText.contains('지남');

    // status 기반 3색 노드
    final Color nodeColor = switch (step.status) {
      'DONE' => _kDone,
      'IN_PROGRESS' => const Color(0xFFF59E0B),
      _ => isOverdue ? _kUrgent : color.withOpacity(0.6),
    };
    final bool nodeFilled =
        step.status != 'NOT_STARTED' || isOverdue;

    // 연결선 색상
    final lineColor = step.status == 'DONE'
        ? _kDone.withOpacity(0.4)
        : _kGlassBorder.withOpacity(0.4);

    // 카드 테두리 색상 — 흰색 유리 스타일로 통일
    const Color cardBorderColor = _kGlassBorder;

    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 드래그 핸들 (순서 변경 모드) ──
            // ReorderableListView.builder가 자동으로 drag 핸들을 제공하므로
            // 시각적 힌트만 표시한다.
            if (showDragHandle)
              const Padding(
                padding: EdgeInsets.only(right: 4, top: 4),
                child: Icon(Icons.drag_handle, size: 18, color: _kTextMute),
              ),
            // ── 왼쪽: 라인 + 노드 ──
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  // 위쪽 연결선
                  if (!isFirst)
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(width: 2, color: lineColor),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  // 노드 원 — AnimatedSwitcher로 상태 전환 애니메이션
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Container(
                      key: ValueKey(step.status),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: nodeFilled
                            ? nodeColor.withOpacity(0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: nodeColor,
                          width: step.status == 'DONE' ? 2.0 : 1.5,
                        ),
                      ),
                      child: Icon(step.statusIcon, size: 16, color: nodeColor),
                    ),
                  ),
                  // 아래쪽 연결선
                  if (!isLast)
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Container(width: 2, color: lineColor),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── 오른쪽: 카드 내용 ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: isFirst ? 0 : 8,
                  bottom: isLast ? 0 : 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: _kGlass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 기간 텍스트를 먼저 (있을 때만)
                            if (dDayText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  dDayText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isOverdue ? _kUrgent : const Color(0x88FFFFFF),
                                  ),
                                ),
                              ),
                            // 그 다음 제목
                            Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: step.status == 'DONE'
                                    ? _kTextSub
                                    : _kText,
                                decoration: step.status == 'DONE'
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: _kTextSub,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // 상태 배지만 (D-Day는 위로 올라갔으므로 제거)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: nodeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                step.statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: nodeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusCycleButton(
                        status: step.status,
                        onTap: onUpdateStatus,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// 기간 그룹 데이터 클래스
// ---------------------------------------------------------------------------

class _PeriodGroup {
  final String label;
  final DateTime? dueDate;
  final List<RoadmapStepModel> steps;
  const _PeriodGroup({required this.label, this.dueDate, required this.steps});
}

// ---------------------------------------------------------------------------
// 기간 그룹 타임라인 타일 (홈화면 _TimelineTile 스타일)
// ---------------------------------------------------------------------------

class _PeriodGroupTile extends StatelessWidget {
  final _PeriodGroup group;
  final bool isLast;
  final void Function(String oid, String newStatus) onUpdateStatus;
  final void Function(RoadmapStepModel step) onTap;

  const _PeriodGroupTile({
    super.key,
    required this.group,
    required this.isLast,
    required this.onUpdateStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final doneCnt = group.steps.where((s) => s.status == 'DONE').length;
    final allDone = doneCnt == group.steps.length;
    final anyInProgress = group.steps.any((s) => s.status == 'IN_PROGRESS');

    // 그룹 상태 색상 (중립 기반)
    final Color dotColor = allDone
        ? _kDone
        : anyInProgress
            ? const Color(0xFFF59E0B)
            : const Color(0x88FFFFFF);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 왼쪽: 점 + 세로선 ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                  child: Icon(
                    allDone
                        ? Icons.check_circle
                        : anyInProgress
                            ? Icons.timelapse
                            : Icons.radio_button_unchecked,
                    size: 12,
                    color: dotColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [dotColor.withOpacity(0.4), const Color(0x14FFFFFF)],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── 오른쪽: 유리 카드 ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x28FFFFFF), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 기간 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: dotColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  group.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: dotColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$doneCnt/${group.steps.length}',
                                style: const TextStyle(fontSize: 10, color: _kTextMute),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0x18FFFFFF)),
                        // 단계 행 목록
                        ...group.steps.asMap().entries.map((e) {
                          final step = e.value;
                          final isLastStep = e.key == group.steps.length - 1;
                          return Column(
                            children: [
                              _buildStepRow(step),
                              if (!isLastStep)
                                const Divider(
                                    height: 1,
                                    color: Color(0x0CFFFFFF),
                                    indent: 12,
                                    endIndent: 12),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(RoadmapStepModel step) {
    final stepColor = step.effectiveColor;
    final nodeColor = switch (step.status) {
      'DONE' => _kDone,
      'IN_PROGRESS' => const Color(0xFFF59E0B),
      _ => stepColor,
    };
    return InkWell(
      onTap: () => onTap(step),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: nodeColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: nodeColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(RoadmapStepModel.stepIcon(step.stepType), size: 13, color: nodeColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: step.status == 'DONE' ? _kTextSub : _kText,
                      decoration: step.status == 'DONE' ? TextDecoration.lineThrough : null,
                      decorationColor: _kTextSub,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: nodeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step.statusLabel,
                      style: TextStyle(fontSize: 9, color: nodeColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            _StatusCycleButton(
              status: step.status,
              onTap: () => onUpdateStatus(step.oid, step.nextStatus),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3상태 순환 버튼 — 모던 pill 스타일
// ---------------------------------------------------------------------------

class _StatusCycleButton extends StatelessWidget {
  final String status;
  final VoidCallback onTap;

  const _StatusCycleButton({required this.status, required this.onTap});

  static Color _bg(String s) => switch (s) {
        'DONE' => const Color(0x2810B981),
        'IN_PROGRESS' => const Color(0x28F59E0B),
        _ => const Color(0x10FFFFFF),
      };

  static Color _border(String s) => switch (s) {
        'DONE' => const Color(0x6010B981),
        'IN_PROGRESS' => const Color(0x60F59E0B),
        _ => const Color(0x28FFFFFF),
      };

  static Color _fg(String s) => switch (s) {
        'DONE' => const Color(0xFF10B981),
        'IN_PROGRESS' => const Color(0xFFF59E0B),
        _ => const Color(0x55FFFFFF),
      };

  static List<BoxShadow>? _glow(String s) => switch (s) {
        'DONE' => [
            const BoxShadow(
                color: Color(0x2810B981), blurRadius: 8, spreadRadius: 0)
          ],
        'IN_PROGRESS' => [
            const BoxShadow(
                color: Color(0x28F59E0B), blurRadius: 8, spreadRadius: 0)
          ],
        _ => null,
      };

  static IconData _icon(String s) => switch (s) {
        'DONE' => Icons.check_rounded,
        'IN_PROGRESS' => Icons.timelapse_rounded,
        _ => Icons.radio_button_unchecked,
      };

  static String _label(String s) => switch (s) {
        'DONE' => '완료',
        'IN_PROGRESS' => '진행중',
        _ => '시작',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child),
        ),
        child: AnimatedContainer(
          key: ValueKey(status),
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _bg(status),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border(status), width: 1),
            boxShadow: _glow(status),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(status), size: 10, color: _fg(status)),
              const SizedBox(width: 4),
              Text(
                _label(status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _fg(status),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 상태 배지 (진행률 헤더용)
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 단계 상세 BottomSheet
// ---------------------------------------------------------------------------

class _StepDetailBottomSheet extends StatefulWidget {
  final RoadmapStepModel step;
  final BuildContext scaffoldContext;
  final RoadmapNotifier notifier;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;

  const _StepDetailBottomSheet({
    required this.step,
    required this.scaffoldContext,
    required this.notifier,
    this.onSaved,
    this.onDeleted,
  });

  @override
  State<_StepDetailBottomSheet> createState() =>
      _StepDetailBottomSheetState();
}

class _StepDetailBottomSheetState extends State<_StepDetailBottomSheet> {
  late bool _isDone;
  late bool _hasDueDate;
  DateTime? _dueDate;
  bool _isSaving = false;

  // 공통 controllers
  final _titleCtrl = TextEditingController();

  // BUDGET
  final _budgetAmountCtrl = TextEditingController();
  final List<Map<String, TextEditingController>> _budgetItems = [];

  // HALL — 투어 목록
  List<HallTourModel> _hallTours = [];
  bool _hallToursLoading = false;

  // PLANNER
  final _plannerStudioCtrl = TextEditingController();
  final _plannerDressCtrl = TextEditingController();
  final _plannerMakeupCtrl = TextEditingController();

  // DRESS
  final _dressFittingFeeCtrl = TextEditingController();
  final List<TextEditingController> _dressVendorCtrls = [];
  final _dressBalanceCtrl = TextEditingController();
  DateTime? _dressBalanceDate;

  // HOME
  String _homeType = '전세';
  final _homeNameCtrl = TextEditingController();
  final _homePhoneCtrl = TextEditingController();
  final _homeAmountCtrl = TextEditingController();
  final _homeLocationCtrl = TextEditingController();
  final List<bool> _homeChecklist = List.filled(5, false);
  final _homeSubwayCtrl = TextEditingController();
  final _homeWalkDistCtrl = TextEditingController();

  // TRAVEL
  final _travelSourceCtrl = TextEditingController();
  final _travelDepartureCtrl = TextEditingController();
  final _travelDestCtrl = TextEditingController();
  final List<TextEditingController> _travelStopoverCtrls = [];
  final _travelFlightInfoCtrl = TextEditingController();
  final _travelAirlineCtrl = TextEditingController();

  // GIFT
  final List<Map<String, TextEditingController>> _giftItems = [];

  // SANGGYEONRYE
  final _sangNameCtrl = TextEditingController();
  final _sangPricePerPersonCtrl = TextEditingController();
  final _sangGuestsCtrl = TextEditingController();
  final _sangTotalAmountCtrl = TextEditingController();
  DateTime? _sangDate;
  final List<Map<String, TextEditingController>> _sangExtraItems = [];

  // ETC
  final List<Map<String, TextEditingController>> _etcItems = [];

  static const _homeChecklistLabels = [
    '등기부등본 확인',
    '확정일자 신청',
    '전입신고',
    '임대인 신분 확인',
    '계약서 공증',
  ];

  @override
  void initState() {
    super.initState();
    final step = widget.step;
    _isDone = step.isDone;
    _hasDueDate = step.hasDueDate;
    _dueDate = step.dueDate;
    _titleCtrl.text = step.title;

    _initFromDetails(step.details);

    if (step.stepType == 'HALL') {
      _loadHallTours();
    }
  }

  void _initFromDetails(Map<String, dynamic> d) {
    final step = widget.step;
    switch (step.stepType) {
      case 'BUDGET':
        // BE syncBudgetSettings()와 DataInitializer는 'totalBudget' key를 사용한다.
        _budgetAmountCtrl.text =
            (d['totalBudget'] as num?)?.toString() ?? '';
        final budgetItemsList = d['budgetItems'] as List<dynamic>? ?? [];
        for (final item in budgetItemsList) {
          final m = item as Map<String, dynamic>;
          _budgetItems.add({
            'name': TextEditingController(text: m['name'] as String? ?? ''),
            'deposit': TextEditingController(text: (m['deposit'] as num?)?.toString() ?? ''),
            'balance': TextEditingController(text: (m['balance'] as num?)?.toString() ?? ''),
          });
        }
        if (_budgetItems.isEmpty) _addBudgetItem();
        break;
      case 'PLANNER':
        // 신규 포맷
        _plannerStudioCtrl.text = d['studio'] as String? ?? '';
        _plannerDressCtrl.text = d['dress'] as String? ?? '';
        _plannerMakeupCtrl.text = d['makeup'] as String? ?? '';
        // 기존 vendors[] 레거시 폴백 (구버전 데이터 호환)
        if (_plannerStudioCtrl.text.isEmpty && _plannerDressCtrl.text.isEmpty) {
          final vendors = d['vendors'] as List<dynamic>? ?? [];
          if (vendors.isNotEmpty) _plannerStudioCtrl.text = vendors[0].toString();
          if (vendors.length > 1) _plannerDressCtrl.text = vendors[1].toString();
          if (vendors.length > 2) _plannerMakeupCtrl.text = vendors[2].toString();
        }
        break;
      case 'DRESS':
        _dressFittingFeeCtrl.text =
            (d['fittingFee'] as num?)?.toString() ?? '';
        final dVendors = d['vendors'] as List<dynamic>? ?? [];
        for (final v in dVendors) {
          _dressVendorCtrls
              .add(TextEditingController(text: v.toString()));
        }
        if (_dressVendorCtrls.isEmpty) {
          _dressVendorCtrls.add(TextEditingController());
        }
        _dressBalanceCtrl.text =
            (d['balanceAmount'] as num?)?.toString() ?? '';
        if (d['balanceDate'] != null) {
          _dressBalanceDate =
              DateTime.tryParse(d['balanceDate'] as String);
        }
        break;
      case 'HOME':
        _homeType = d['homeType'] as String? ?? '전세';
        _homeNameCtrl.text = d['propertyName'] as String? ?? '';
        _homePhoneCtrl.text = d['contactPhone'] as String? ?? '';
        _homeAmountCtrl.text =
            (d['amount'] as num?)?.toString() ?? '';
        _homeLocationCtrl.text = d['location'] as String? ?? '';
        final checks = d['checklist'] as List<dynamic>? ?? [];
        for (int i = 0; i < _homeChecklist.length; i++) {
          _homeChecklist[i] =
              i < checks.length ? checks[i] as bool? ?? false : false;
        }
        _homeSubwayCtrl.text = d['subway'] as String? ?? '';
        _homeWalkDistCtrl.text = d['walkDistance'] as String? ?? '';
        break;
      case 'TRAVEL':
        _travelSourceCtrl.text = d['purchaseSource'] as String? ?? '';
        _travelDepartureCtrl.text = d['departure'] as String? ?? '';
        _travelDestCtrl.text = d['destination'] as String? ?? '';
        final stopovers = d['stopovers'] as List<dynamic>? ?? [];
        for (final v in stopovers) {
          _travelStopoverCtrls
              .add(TextEditingController(text: v.toString()));
        }
        _travelFlightInfoCtrl.text = d['flightInfo'] as String? ?? '';
        _travelAirlineCtrl.text = d['airline'] as String? ?? '';
        break;
      case 'GIFT':
        final items = d['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final m = item as Map<String, dynamic>;
          _giftItems.add({
            'name': TextEditingController(
                text: m['name'] as String? ?? ''),
            'brand': TextEditingController(
                text: m['brand'] as String? ?? ''),
            'store': TextEditingController(
                text: m['store'] as String? ?? ''),
            'price': TextEditingController(
                text: (m['price'] as num?)?.toString() ?? ''),
            'detail': TextEditingController(
                text: m['detail'] as String? ?? ''),
          });
        }
        if (_giftItems.isEmpty) _addGiftItem();
        break;
      case 'SANGGYEONRYE':
        _sangNameCtrl.text = d['restaurantName'] as String? ?? '';
        _sangPricePerPersonCtrl.text =
            (d['pricePerPerson'] as num?)?.toString() ?? '';
        _sangGuestsCtrl.text =
            (d['guestCount'] as num?)?.toString() ?? '';
        _sangTotalAmountCtrl.text =
            (d['totalAmount'] as num?)?.toString() ?? '';
        if (d['date'] != null) {
          _sangDate = DateTime.tryParse(d['date'] as String);
        }
        final extras = d['extraItems'] as List<dynamic>? ?? [];
        for (final item in extras) {
          final m = item as Map<String, dynamic>;
          _sangExtraItems.add({
            'name': TextEditingController(
                text: m['name'] as String? ?? ''),
            'amount': TextEditingController(
                text: (m['amount'] as num?)?.toString() ?? ''),
          });
        }
        break;
      case 'ETC':
        final etcItems = d['items'] as List<dynamic>? ?? [];
        for (final item in etcItems) {
          final m = item as Map<String, dynamic>;
          _etcItems.add({
            'name': TextEditingController(
                text: m['name'] as String? ?? ''),
            'amount': TextEditingController(
                text: (m['amount'] as num?)?.toString() ?? ''),
            'guests': TextEditingController(
                text: (m['guests'] as num?)?.toString() ?? ''),
            'location': TextEditingController(
                text: m['location'] as String? ?? ''),
            'deposit': TextEditingController(
                text: (m['deposit'] as num?)?.toString() ?? ''),
            'balance': TextEditingController(
                text: (m['balance'] as num?)?.toString() ?? ''),
          });
        }
        if (_etcItems.isEmpty) _addEtcItem();
        break;
    }
  }

  Future<void> _loadHallTours() async {
    setState(() => _hallToursLoading = true);
    try {
      final tours =
          await widget.notifier.getHallTours(widget.step.oid);
      if (mounted) {
        setState(() {
          _hallTours = tours;
          _hallToursLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hallToursLoading = false);
    }
  }

  void _addBudgetItem() {
    _budgetItems.add({
      'name': TextEditingController(),
      'deposit': TextEditingController(),
      'balance': TextEditingController(),
    });
  }

  void _addGiftItem() {
    _giftItems.add({
      'name': TextEditingController(),
      'brand': TextEditingController(),
      'store': TextEditingController(),
      'price': TextEditingController(),
      'detail': TextEditingController(),
    });
  }

  void _addEtcItem() {
    _etcItems.add({
      'name': TextEditingController(),
      'amount': TextEditingController(),
      'guests': TextEditingController(),
      'location': TextEditingController(),
      'deposit': TextEditingController(),
      'balance': TextEditingController(),
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetAmountCtrl.dispose();
    for (final m in _budgetItems) {
      for (final c in m.values) { c.dispose(); }
    }
    _plannerStudioCtrl.dispose();
    _plannerDressCtrl.dispose();
    _plannerMakeupCtrl.dispose();
    _dressFittingFeeCtrl.dispose();
    for (final c in _dressVendorCtrls) { c.dispose(); }
    _dressBalanceCtrl.dispose();
    _homeNameCtrl.dispose();
    _homePhoneCtrl.dispose();
    _homeAmountCtrl.dispose();
    _homeLocationCtrl.dispose();
    _homeSubwayCtrl.dispose();
    _homeWalkDistCtrl.dispose();
    for (final c in _travelStopoverCtrls) { c.dispose(); }
    _travelSourceCtrl.dispose();
    _travelDepartureCtrl.dispose();
    _travelDestCtrl.dispose();
    _travelFlightInfoCtrl.dispose();
    _travelAirlineCtrl.dispose();
    for (final m in _giftItems) {
      for (final c in m.values) { c.dispose(); }
    }
    _sangNameCtrl.dispose();
    _sangPricePerPersonCtrl.dispose();
    _sangGuestsCtrl.dispose();
    _sangTotalAmountCtrl.dispose();
    for (final m in _sangExtraItems) {
      for (final c in m.values) { c.dispose(); }
    }
    for (final m in _etcItems) {
      for (final c in m.values) { c.dispose(); }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final color = RoadmapStepModel.stepColor(widget.step.stepType);
    final icon = RoadmapStepModel.stepIcon(widget.step.stepType);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 헤더 (닫기 버튼 포함, 핸들바 제거)
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.step.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 완료 토글
            _buildToggleRow(
              label: '완료로 표시',
              value: _isDone,
              onChanged: (v) => setState(() => _isDone = v),
            ),
            const SizedBox(height: 12),

            // 마감일 토글
            _buildToggleRow(
              label: '마감일 설정',
              value: _hasDueDate,
              onChanged: (v) {
                setState(() {
                  _hasDueDate = v;
                  if (v && _dueDate == null) {
                    _dueDate = DateTime.now();
                  }
                });
              },
            ),
            if (_hasDueDate && _dueDate != null) ...[
              const SizedBox(height: 8),
              _buildDatePicker(
                date: _dueDate!,
                onSelected: (d) => setState(() => _dueDate = d),
              ),
              const SizedBox(height: 6),
              // D-Day 실시간 표시
              Builder(builder: (_) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final due = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);
                final diff = due.difference(today).inDays;
                String dText;
                Color dColor;
                if (diff < 0) {
                  dText = '${diff.abs()}일 지남';
                  dColor = _kUrgent;
                } else if (diff == 0) {
                  dText = '오늘';
                  dColor = _kPink;
                } else {
                  dText = 'D-$diff';
                  dColor = _kDone;
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dColor.withOpacity(0.3)),
                  ),
                  child: Text(dText, style: TextStyle(fontSize: 11, color: dColor)),
                );
              }),
            ],

            const SizedBox(height: 16),
            const Divider(color: Color(0x22FFFFFF), height: 1),
            const SizedBox(height: 16),

            // stepType별 특화 UI
            _buildStepSpecificForm(),

            const SizedBox(height: 20),
            const Divider(color: Color(0x22FFFFFF), height: 1),
            const SizedBox(height: 16),

            // 첨부파일 섹션
            AttachmentSectionWidget(
              refType: 'ROADMAP_STEP',
              refOid: widget.step.oid,
            ),

            const SizedBox(height: 24),

            // 저장 / 삭제 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kUrgent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : _onDelete,
                    child: const Text(
                      '삭제',
                      style: TextStyle(
                          color: _kUrgent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : _onSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '저장',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── 공통 UI 빌더 ─────────────────────────────────────────────────────────

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          activeColor: _kPink,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required DateTime date,
    required ValueChanged<DateTime> onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _kPink,
                surface: Color(0xFF1E1E2E),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: _kPink),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(date),
              style:
                  const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xAAFFFFFF),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool numbersOnly = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
      inputFormatters:
          numbersOnly ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPink, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _kPink.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: _kTextSub),
      ),
    );
  }

  // ── stepType별 특화 폼 ────────────────────────────────────────────────────

  Widget _buildStepSpecificForm() {
    switch (widget.step.stepType) {
      case 'BUDGET':
        return _buildBudgetForm();
      case 'HALL':
        return _buildHallForm();
      case 'PLANNER':
        return _buildPlannerForm();
      case 'DRESS':
        return _buildDressForm();
      case 'HOME':
        return _buildHomeForm();
      case 'TRAVEL':
        return _buildTravelForm();
      case 'GIFT':
        return _buildGiftForm();
      case 'SANGGYEONRYE':
        return _buildSanggyeonryeForm();
      case 'ETC':
        return _buildEtcForm();
      default:
        return const SizedBox.shrink();
    }
  }

  // BUDGET
  Widget _buildBudgetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('전체 예산 금액 (원)'),
        const SizedBox(height: 6),
        _buildTextField(_budgetAmountCtrl, '예: 50000000', numbersOnly: true),
        const SizedBox(height: 10),
        _buildInfoChip('예산 관리와 자동 연동됩니다'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('계약금/잔금 항목'),
            TextButton.icon(
              onPressed: () => setState(() => _addBudgetItem()),
              icon: const Icon(Icons.add, size: 14, color: _kPink),
              label: const Text('항목 추가', style: TextStyle(fontSize: 12, color: _kPink)),
              style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildInfoChip('항목별 계약금·잔금을 입력하면 예산 관리에 자동 반영됩니다'),
        const SizedBox(height: 10),
        ..._budgetItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          // 계약금 + 잔금 합산
          final deposit = int.tryParse(m['deposit']!.text) ?? 0;
          final balance = int.tryParse(m['balance']!.text) ?? 0;
          final total = deposit + balance;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('항목 ${idx + 1}',
                        style: const TextStyle(fontSize: 12, color: _kTextMute, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () {
                        for (final c in m.values) { c.dispose(); }
                        setState(() => _budgetItems.removeAt(idx));
                      },
                      child: const Icon(Icons.remove_circle_outline, color: _kUrgent, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(m['name']!, '항목명 (예: 예식장, 스드메)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('계약금 (원)'),
                          const SizedBox(height: 4),
                          _buildTextField(m['deposit']!, '예: 1000000', numbersOnly: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('잔금 (원)'),
                          const SizedBox(height: 4),
                          _buildTextField(m['balance']!, '예: 5000000', numbersOnly: true),
                        ],
                      ),
                    ),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kDone.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kDone.withOpacity(0.3)),
                    ),
                    child: Text(
                      '합계: ${_fmtMoney(total)}',
                      style: const TextStyle(fontSize: 11, color: _kDone),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // HALL
  Widget _buildHallForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('웨딩홀 투어 일정'),
            TextButton.icon(
              onPressed: _showAddHallTourDialog,
              icon: const Icon(Icons.add, size: 14, color: _kPink),
              label: const Text(
                '투어 추가',
                style: TextStyle(fontSize: 12, color: _kPink),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInfoChip('투어 추가 시 일정에도 자동 등록됩니다'),
        const SizedBox(height: 10),
        if (_hallToursLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                  color: _kPink, strokeWidth: 2),
            ),
          )
        else if (_hallTours.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '등록된 투어 일정이 없습니다.',
              style: TextStyle(color: _kTextMute, fontSize: 13),
            ),
          )
        else
          ...(_hallTours.map((tour) => _buildHallTourItem(tour)).toList()),
      ],
    );
  }

  Widget _buildHallTourItem(HallTourModel tour) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tour.hallName,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          if (tour.tourDate != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy년 M월 d일', 'ko_KR').format(tour.tourDate!),
              style: const TextStyle(
                  fontSize: 11, color: _kTextMute),
            ),
          ],
          if (tour.rentalFee != null || tour.mealPrice != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (tour.rentalFee != null)
                  Text(
                    '대관료: ${_fmtMoney(tour.rentalFee!)}',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSub),
                  ),
                if (tour.rentalFee != null && tour.mealPrice != null)
                  const Text('  |  ',
                      style: TextStyle(
                          fontSize: 11, color: _kTextMute)),
                if (tour.mealPrice != null)
                  Text(
                    '식대: ${_fmtMoney(tour.mealPrice!)} / 1인',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSub),
                  ),
              ],
            ),
            if (tour.minGuests != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '보증인원: ${tour.minGuests}명 → 총 식대: ${_fmtMoney(tour.calculatedTotalMealCost)}',
                  style: const TextStyle(
                      fontSize: 11, color: _kTextSub),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showAddHallTourDialog() {
    final hallNameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final rentalFeeCtrl = TextEditingController();
    final mealPriceCtrl = TextEditingController();
    final minGuestsCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    DateTime? tourDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final bottomInset =
                MediaQuery.of(ctx).viewInsets.bottom;
            return Dialog(
              backgroundColor: const Color(0xFF1E1E2E),
              insetPadding: EdgeInsets.fromLTRB(
                  20, 40, 20, 20 + bottomInset),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '웨딩홀 투어 추가',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('웨딩홀 이름 *'),
                    const SizedBox(height: 6),
                    _buildTextField(hallNameCtrl, '예: 더채플앳청담'),
                    const SizedBox(height: 12),
                    _buildLabel('투어 날짜'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              tourDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (c, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme:
                                  const ColorScheme.dark(
                                primary: _kPink,
                                surface: Color(0xFF1E1E2E),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(
                              () => tourDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0x33FFFFFF)),
                        ),
                        child: Text(
                          tourDate != null
                              ? DateFormat(
                                      'yyyy년 M월 d일', 'ko_KR')
                                  .format(tourDate!)
                              : '날짜 선택',
                          style: TextStyle(
                            color: tourDate != null
                                ? Colors.white
                                : _kTextMute,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('장소'),
                    const SizedBox(height: 6),
                    _buildTextField(locationCtrl, '예: 서울 강남구'),
                    const SizedBox(height: 12),
                    _buildLabel('대관료 (원)'),
                    const SizedBox(height: 6),
                    _buildTextField(rentalFeeCtrl, '예: 5000000',
                        numbersOnly: true),
                    const SizedBox(height: 12),
                    _buildLabel('식대 / 1인 (원)'),
                    const SizedBox(height: 6),
                    _buildTextField(mealPriceCtrl, '예: 80000',
                        numbersOnly: true),
                    const SizedBox(height: 12),
                    _buildLabel('보증 인원 (명)'),
                    const SizedBox(height: 6),
                    _buildTextField(minGuestsCtrl, '예: 200',
                        numbersOnly: true),
                    const SizedBox(height: 12),
                    _buildLabel('메모'),
                    const SizedBox(height: 6),
                    _buildTextField(memoCtrl, '메모를 입력하세요',
                        maxLines: 2),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                  color: _kTextSub),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPink,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12)),
                            ),
                            onPressed: () async {
                              final name =
                                  hallNameCtrl.text.trim();
                              if (name.isEmpty) return;

                              final body = <String, dynamic>{
                                'hallName': name,
                                if (tourDate != null)
                                  'tourDate':
                                      _fmtDate(tourDate!),
                                if (tourDate != null)
                                  'scheduleTitle': '$name 투어',
                                if (locationCtrl
                                    .text.isNotEmpty)
                                  'location': locationCtrl
                                      .text
                                      .trim(),
                                if (rentalFeeCtrl
                                    .text.isNotEmpty)
                                  'rentalFee': int.tryParse(
                                      rentalFeeCtrl.text),
                                if (mealPriceCtrl
                                    .text.isNotEmpty)
                                  'mealPrice': int.tryParse(
                                      mealPriceCtrl.text),
                                if (minGuestsCtrl
                                    .text.isNotEmpty)
                                  'minGuests': int.tryParse(
                                      minGuestsCtrl.text),
                                if (memoCtrl.text.isNotEmpty)
                                  'memo': memoCtrl.text
                                      .trim(),
                              };

                              Navigator.pop(ctx);
                              final ok = await widget.notifier
                                  .addHallTour(
                                      widget.step.oid, body);
                              if (ok && mounted) {
                                _loadHallTours();
                              }
                            },
                            child: const Text(
                              '추가',
                              style: TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // PLANNER
  Widget _buildPlannerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoChip('스튜디오/드레스/메이크업 업체를 카테고리별로 입력하세요'),
        const SizedBox(height: 14),
        _buildLabel('스튜디오'),
        const SizedBox(height: 6),
        _buildTextField(_plannerStudioCtrl, '예: 강남 웨딩스튜디오'),
        const SizedBox(height: 12),
        _buildLabel('드레스'),
        const SizedBox(height: 6),
        _buildTextField(_plannerDressCtrl, '예: 클라라 드레스'),
        const SizedBox(height: 12),
        _buildLabel('메이크업'),
        const SizedBox(height: 6),
        _buildTextField(_plannerMakeupCtrl, '예: 아름다운 헤어메이크업'),
      ],
    );
  }

  // DRESS
  Widget _buildDressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('피팅비 (원)'),
        const SizedBox(height: 6),
        _buildTextField(_dressFittingFeeCtrl, '예: 150000',
            numbersOnly: true),
        const SizedBox(height: 8),
        _buildInfoChip('예산에 즉시 반영됩니다'),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('업체 목록'),
            TextButton.icon(
              onPressed: () => setState(
                  () => _dressVendorCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add, size: 14, color: _kPink),
              label: const Text(
                '업체 추가',
                style: TextStyle(fontSize: 12, color: _kPink),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._dressVendorCtrls.asMap().entries.map((entry) {
          final idx = entry.key;
          final ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(ctrl, '업체명'),
                ),
                if (_dressVendorCtrls.length > 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(
                        () => _dressVendorCtrls.removeAt(idx)),
                    child: const Icon(Icons.remove_circle_outline,
                        color: _kUrgent, size: 20),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        _buildLabel('잔금 금액 (원)'),
        const SizedBox(height: 6),
        _buildTextField(_dressBalanceCtrl, '예: 1000000',
            numbersOnly: true),
        const SizedBox(height: 14),
        _buildLabel('잔금 납부일'),
        const SizedBox(height: 6),
        _buildDatePicker(
          date: _dressBalanceDate ?? DateTime.now(),
          onSelected: (d) => setState(() => _dressBalanceDate = d),
        ),
      ],
    );
  }

  // HOME
  Widget _buildHomeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('거래 유형'),
        const SizedBox(height: 8),
        Row(
          children: ['매매', '전세', '월세'].map((type) {
            final isSelected = _homeType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _homeType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF22D3EE).withOpacity(0.2)
                        : const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF22D3EE)
                          : const Color(0x33FFFFFF),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF22D3EE)
                          : _kTextSub,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildLabel('부동산/건물명'),
        const SizedBox(height: 6),
        _buildTextField(_homeNameCtrl, '예: 래미안 강남 아파트'),
        const SizedBox(height: 12),
        _buildLabel('연락처'),
        const SizedBox(height: 6),
        _buildTextField(_homePhoneCtrl, '예: 02-1234-5678'),
        const SizedBox(height: 12),
        _buildLabel('금액 (원)'),
        const SizedBox(height: 6),
        _buildTextField(_homeAmountCtrl, '예: 300000000',
            numbersOnly: true),
        const SizedBox(height: 12),
        _buildLabel('위치'),
        const SizedBox(height: 6),
        _buildTextField(_homeLocationCtrl, '예: 서울 강남구 역삼동'),
        const SizedBox(height: 12),
        _buildLabel('인근 지하철역'),
        const SizedBox(height: 6),
        _buildTextField(_homeSubwayCtrl, '예: 강남역 (2호선)'),
        const SizedBox(height: 12),
        _buildLabel('도보 거리'),
        const SizedBox(height: 6),
        _buildTextField(_homeWalkDistCtrl, '예: 도보 10분'),
        const SizedBox(height: 16),
        _buildLabel('필수 체크리스트'),
        const SizedBox(height: 8),
        ...List.generate(_homeChecklistLabels.length, (i) {
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _homeChecklist[i],
            onChanged: (v) =>
                setState(() => _homeChecklist[i] = v ?? false),
            title: Text(
              _homeChecklistLabels[i],
              style: const TextStyle(
                  fontSize: 13, color: Colors.white),
            ),
            activeColor: _kPink,
            checkColor: Colors.white,
            side: const BorderSide(color: Color(0x55FFFFFF)),
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
      ],
    );
  }

  // TRAVEL
  Widget _buildTravelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('구매처'),
        const SizedBox(height: 6),
        _buildTextField(_travelSourceCtrl, '예: 하나투어'),
        const SizedBox(height: 12),
        _buildLabel('출발지'),
        const SizedBox(height: 6),
        _buildTextField(_travelDepartureCtrl, '예: 인천국제공항 (ICN)'),
        const SizedBox(height: 12),
        _buildLabel('목적지'),
        const SizedBox(height: 6),
        _buildTextField(_travelDestCtrl, '예: 방콕 수완나품 (BKK)'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('경유지'),
            TextButton.icon(
              onPressed: () => setState(() =>
                  _travelStopoverCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add, size: 14, color: _kPink),
              label: const Text(
                '경유지 추가',
                style: TextStyle(fontSize: 12, color: _kPink),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._travelStopoverCtrls.asMap().entries.map((entry) {
          final idx = entry.key;
          final ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(ctrl, '예: 두바이 (DXB)'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(
                      () => _travelStopoverCtrls.removeAt(idx)),
                  child: const Icon(Icons.remove_circle_outline,
                      color: _kUrgent, size: 20),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _buildLabel('항공편 정보'),
        const SizedBox(height: 6),
        _buildTextField(
            _travelFlightInfoCtrl, '예: KE123 (2026-04-01 13:00)'),
        const SizedBox(height: 12),
        _buildLabel('항공사'),
        const SizedBox(height: 6),
        _buildTextField(_travelAirlineCtrl, '예: 대한항공'),
      ],
    );
  }

  // GIFT
  Widget _buildGiftForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('상품 목록'),
            TextButton.icon(
              onPressed: () => setState(() => _addGiftItem()),
              icon: const Icon(Icons.add, size: 14, color: _kPink),
              label: const Text(
                '상품 추가',
                style: TextStyle(fontSize: 12, color: _kPink),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._giftItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '상품 ${idx + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kTextMute,
                          fontWeight: FontWeight.w600),
                    ),
                    if (_giftItems.length > 1)
                      GestureDetector(
                        onTap: () {
                          for (final c in m.values) { c.dispose(); }
                          setState(() => _giftItems.removeAt(idx));
                        },
                        child: const Icon(
                            Icons.remove_circle_outline,
                            color: _kUrgent,
                            size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(m['name']!, '상품명'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildTextField(m['brand']!, '브랜드')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTextField(m['store']!, '구매처')),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(m['price']!, '가격 (원)',
                    numbersOnly: true),
                const SizedBox(height: 8),
                _buildTextField(m['detail']!, '상세내용',
                    maxLines: 2),
              ],
            ),
          );
        }),
      ],
    );
  }

  // SANGGYEONRYE
  Widget _buildSanggyeonryeForm() {
    return StatefulBuilder(
      builder: (ctx, setInnerState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('식당명'),
            const SizedBox(height: 6),
            _buildTextField(_sangNameCtrl, '예: 더 파크뷰 레스토랑'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('1인당 가격 (원)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _sangPricePerPersonCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '예: 80000',
                          hintStyle: const TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 14),
                          filled: true,
                          fillColor: const Color(0x0FFFFFFF),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0x33FFFFFF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0x33FFFFFF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: _kPink, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('인원 수'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _sangGuestsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '예: 20',
                          hintStyle: const TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 14),
                          filled: true,
                          fillColor: const Color(0x0FFFFFFF),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0x33FFFFFF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0x33FFFFFF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: _kPink, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLabel('전체 금액 (원)'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sangTotalAmountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '자동 계산 또는 직접 입력',
                      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0x0FFFFFFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPink, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final p = int.tryParse(_sangPricePerPersonCtrl.text) ?? 0;
                    final g = int.tryParse(_sangGuestsCtrl.text) ?? 0;
                    if (p > 0 && g > 0) {
                      setState(() => _sangTotalAmountCtrl.text = (p * g).toString());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPink.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('자동계산', style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLabel('상견례 날짜'),
            const SizedBox(height: 6),
            _buildDatePicker(
              date: _sangDate ?? DateTime.now(),
              onSelected: (d) =>
                  setState(() => _sangDate = d),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('부대 항목'),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _sangExtraItems.add({
                      'name': TextEditingController(),
                      'amount': TextEditingController(),
                    });
                  }),
                  icon: const Icon(Icons.add,
                      size: 14, color: _kPink),
                  label: const Text(
                    '항목 추가',
                    style: TextStyle(
                        fontSize: 12, color: _kPink),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._sangExtraItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(m['name']!, '항목명'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                          m['amount']!, '금액',
                          numbersOnly: true),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        for (final c in m.values) { c.dispose(); }
                        setState(
                            () => _sangExtraItems.removeAt(idx));
                      },
                      child: const Icon(
                          Icons.remove_circle_outline,
                          color: _kUrgent,
                          size: 20),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ETC
  Widget _buildEtcForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('카테고리명'),
        const SizedBox(height: 6),
        _buildTextField(_titleCtrl, '이 단계의 이름을 입력하세요'),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('세부 항목'),
            TextButton.icon(
              onPressed: () => setState(() => _addEtcItem()),
              icon: const Icon(Icons.add, size: 14, color: _kPink),
              label: const Text(
                '항목 추가',
                style: TextStyle(fontSize: 12, color: _kPink),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._etcItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '항목 ${idx + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kTextMute,
                          fontWeight: FontWeight.w600),
                    ),
                    if (_etcItems.length > 1)
                      GestureDetector(
                        onTap: () {
                          for (final c in m.values) { c.dispose(); }
                          setState(() => _etcItems.removeAt(idx));
                        },
                        child: const Icon(
                            Icons.remove_circle_outline,
                            color: _kUrgent,
                            size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(m['name']!, '항목명'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            m['amount']!, '금액',
                            numbersOnly: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTextField(
                            m['guests']!, '인원',
                            numbersOnly: true)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(m['location']!, '위치'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            m['deposit']!, '계약금',
                            numbersOnly: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTextField(
                            m['balance']!, '잔금',
                            numbersOnly: true)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── 저장 / 삭제 ────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildDetails() {
    switch (widget.step.stepType) {
      case 'BUDGET':
        // BE syncBudgetSettings()가 'totalBudget' key를 파싱하므로 동일 key 사용
        return {
          if (_budgetAmountCtrl.text.isNotEmpty &&
              int.tryParse(_budgetAmountCtrl.text) != null)
            'totalBudget': int.parse(_budgetAmountCtrl.text),
          'budgetItems': _budgetItems.map((m) {
            return {
              if (m['name']!.text.isNotEmpty) 'name': m['name']!.text.trim(),
              if (m['deposit']!.text.isNotEmpty &&
                  int.tryParse(m['deposit']!.text) != null)
                'deposit': int.parse(m['deposit']!.text),
              if (m['balance']!.text.isNotEmpty &&
                  int.tryParse(m['balance']!.text) != null)
                'balance': int.parse(m['balance']!.text),
            };
          }).where((m) => m.containsKey('name')).toList(),
        };
      case 'PLANNER':
        return {
          if (_plannerStudioCtrl.text.isNotEmpty) 'studio': _plannerStudioCtrl.text.trim(),
          if (_plannerDressCtrl.text.isNotEmpty) 'dress': _plannerDressCtrl.text.trim(),
          if (_plannerMakeupCtrl.text.isNotEmpty) 'makeup': _plannerMakeupCtrl.text.trim(),
        };
      case 'DRESS':
        return {
          if (_dressFittingFeeCtrl.text.isNotEmpty &&
              int.tryParse(_dressFittingFeeCtrl.text) != null)
            'fittingFee': int.parse(_dressFittingFeeCtrl.text),
          'vendors': _dressVendorCtrls
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          if (_dressBalanceCtrl.text.isNotEmpty &&
              int.tryParse(_dressBalanceCtrl.text) != null)
            'balanceAmount': int.parse(_dressBalanceCtrl.text),
          if (_dressBalanceDate != null)
            'balanceDate': _fmtDate(_dressBalanceDate!),
        };
      case 'HOME':
        return {
          'homeType': _homeType,
          if (_homeNameCtrl.text.isNotEmpty)
            'propertyName': _homeNameCtrl.text.trim(),
          if (_homePhoneCtrl.text.isNotEmpty)
            'contactPhone': _homePhoneCtrl.text.trim(),
          if (_homeAmountCtrl.text.isNotEmpty &&
              int.tryParse(_homeAmountCtrl.text) != null)
            'amount': int.parse(_homeAmountCtrl.text),
          if (_homeLocationCtrl.text.isNotEmpty)
            'location': _homeLocationCtrl.text.trim(),
          'checklist': _homeChecklist.toList(),
          if (_homeSubwayCtrl.text.isNotEmpty)
            'subway': _homeSubwayCtrl.text.trim(),
          if (_homeWalkDistCtrl.text.isNotEmpty)
            'walkDistance': _homeWalkDistCtrl.text.trim(),
        };
      case 'TRAVEL':
        return {
          if (_travelSourceCtrl.text.isNotEmpty)
            'purchaseSource': _travelSourceCtrl.text.trim(),
          if (_travelDepartureCtrl.text.isNotEmpty)
            'departure': _travelDepartureCtrl.text.trim(),
          if (_travelDestCtrl.text.isNotEmpty)
            'destination': _travelDestCtrl.text.trim(),
          'stopovers': _travelStopoverCtrls
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          if (_travelFlightInfoCtrl.text.isNotEmpty)
            'flightInfo': _travelFlightInfoCtrl.text.trim(),
          if (_travelAirlineCtrl.text.isNotEmpty)
            'airline': _travelAirlineCtrl.text.trim(),
        };
      case 'GIFT':
        return {
          'items': _giftItems.map((m) {
            return {
              if (m['name']!.text.isNotEmpty)
                'name': m['name']!.text.trim(),
              if (m['brand']!.text.isNotEmpty)
                'brand': m['brand']!.text.trim(),
              if (m['store']!.text.isNotEmpty)
                'store': m['store']!.text.trim(),
              if (m['price']!.text.isNotEmpty &&
                  int.tryParse(m['price']!.text) != null)
                'price': int.parse(m['price']!.text),
              if (m['detail']!.text.isNotEmpty)
                'detail': m['detail']!.text.trim(),
            };
          }).toList(),
        };
      case 'SANGGYEONRYE':
        final price = int.tryParse(_sangPricePerPersonCtrl.text);
        final guests = int.tryParse(_sangGuestsCtrl.text);
        // totalAmount: 수동 입력값 우선, 없으면 자동계산
        final totalAmountStr = _sangTotalAmountCtrl.text;
        final totalAmount = totalAmountStr.isNotEmpty
            ? int.tryParse(totalAmountStr)
            : (price != null && guests != null ? price * guests : null);
        return {
          if (_sangNameCtrl.text.isNotEmpty)
            'restaurantName': _sangNameCtrl.text.trim(),
          if (price != null) 'pricePerPerson': price,
          if (guests != null) 'guestCount': guests,
          if (totalAmount != null) 'totalAmount': totalAmount,
          if (_sangDate != null) 'date': _fmtDate(_sangDate!),
          'extraItems': _sangExtraItems.map((m) {
            return {
              if (m['name']!.text.isNotEmpty)
                'name': m['name']!.text.trim(),
              if (m['amount']!.text.isNotEmpty &&
                  int.tryParse(m['amount']!.text) != null)
                'amount': int.parse(m['amount']!.text),
            };
          }).toList(),
        };
      case 'ETC':
        return {
          'items': _etcItems.map((m) {
            return {
              if (m['name']!.text.isNotEmpty)
                'name': m['name']!.text.trim(),
              if (m['amount']!.text.isNotEmpty &&
                  int.tryParse(m['amount']!.text) != null)
                'amount': int.parse(m['amount']!.text),
              if (m['guests']!.text.isNotEmpty &&
                  int.tryParse(m['guests']!.text) != null)
                'guests': int.parse(m['guests']!.text),
              if (m['location']!.text.isNotEmpty)
                'location': m['location']!.text.trim(),
              if (m['deposit']!.text.isNotEmpty &&
                  int.tryParse(m['deposit']!.text) != null)
                'deposit': int.parse(m['deposit']!.text),
              if (m['balance']!.text.isNotEmpty &&
                  int.tryParse(m['balance']!.text) != null)
                'balance': int.parse(m['balance']!.text),
            };
          }).toList(),
        };
      default:
        return {};
    }
  }

  Future<void> _onSave() async {
    // async gap 이전에 캡처
    final messenger =
        ScaffoldMessenger.of(widget.scaffoldContext);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      final details = _buildDetails();
      // ETC 타입이거나 직접 로드맵 단계(groupOid != null)이면 제목 수정 허용
      final newTitle =
          (widget.step.stepType == 'ETC' || widget.step.groupOid != null)
              ? _titleCtrl.text.trim()
              : null;

      final ok = await widget.notifier.updateStep(
        widget.step.oid,
        details,
        title: newTitle,
        dueDate: _hasDueDate ? _dueDate : null,
        hasDueDate: _hasDueDate,
        clearDueDate: !_hasDueDate,
      );

      // isDone 변경된 경우 status도 함께 업데이트
      if (ok && _isDone != widget.step.isDone && mounted) {
        final newStatus = _isDone ? 'DONE' : 'NOT_STARTED';
        await widget.notifier.updateStatus(widget.step.oid, newStatus);
      }

      if (mounted) {
        if (ok) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('저장되었습니다.'),
              backgroundColor: Color(0xFF2A2A3E),
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pop();
          widget.onSaved?.call();
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onDelete() async {
    // async gap 이전에 캡처
    final messenger =
        ScaffoldMessenger.of(widget.scaffoldContext);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('단계 삭제',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          '이 단계를 삭제하면\n연동된 예산 및 일정 데이터가\n함께 삭제됩니다.\n\n계속하시겠습니까?',
          style:
              TextStyle(color: Color(0xAAFFFFFF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Color(0xAAFFFFFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final ok =
          await widget.notifier.deleteStep(widget.step.oid);
      if (mounted) {
        if (ok) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('단계가 삭제되었습니다.'),
              backgroundColor: Color(0xFF2A2A3E),
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pop();
          widget.onDeleted?.call();
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// 커스텀 단계 추가 BottomSheet
// ---------------------------------------------------------------------------

class _AddStepBottomSheet extends StatefulWidget {
  final BuildContext scaffoldContext;
  final RoadmapNotifier notifier;
  final List<String> existingStepTypes;
  final bool hideEtc;
  final String? groupOid;
  final VoidCallback? onSuccess;

  const _AddStepBottomSheet({
    required this.scaffoldContext,
    required this.notifier,
    required this.existingStepTypes,
    this.hideEtc = false,
    this.groupOid,
    this.onSuccess,
  });

  @override
  State<_AddStepBottomSheet> createState() => _AddStepBottomSheetState();
}

class _AddStepBottomSheetState extends State<_AddStepBottomSheet> {
  String? _selectedStepType;
  final _customTitleCtrl = TextEditingController();
  bool _hasDueDate = false;
  DateTime? _dueDate;
  bool _isSaving = false;

  Color _customColor = const Color(0xFFEC4899);

  static const _colorPalette = [
    Color(0xFFEC4899), // pink
    Color(0xFFF472B6), // light pink
    Color(0xFF8B5CF6), // purple
    Color(0xFF60A5FA), // blue
    Color(0xFF34D399), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF22D3EE), // cyan
    Color(0xFFF97316), // orange
    Color(0xFFA78BFA), // violet
    Color(0xFF4ADE80), // lime
    Color(0xFFFBBF24), // yellow
  ];

  static const _stepInfos = [
    ('BUDGET', '결혼 예산', Icons.account_balance_wallet),
    ('HALL', '웨딩홀 투어', Icons.celebration),
    ('PLANNER', '플래너/예약', Icons.person_outline),
    ('DRESS', '드레스 투어', Icons.checkroom),
    ('HOME', '신혼집/부동산', Icons.home_outlined),
    ('TRAVEL', '항공권/여행', Icons.flight),
    ('GIFT', '예물/혼수', Icons.card_giftcard),
    ('SANGGYEONRYE', '상견례', Icons.restaurant),
    ('ETC', '기타 (직접 입력)', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _customTitleCtrl.dispose();
    super.dispose();
  }

  bool _isAlreadyExist(String stepType) {
    if (stepType == 'ETC') return false;
    return widget.existingStepTypes.contains(stepType);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '단계 추가',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              '추가할 로드맵 단계를 선택하세요.',
              style: TextStyle(fontSize: 12, color: Color(0x66FFFFFF)),
            ),
            const SizedBox(height: 16),
            // 단계 선택 Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stepInfos
                .where((info) => !(widget.hideEtc && info.$1 == 'ETC'))
                .map((info) {
                final (type, label, icon) = info;
                final alreadyExists = _isAlreadyExist(type);
                final isSelected = _selectedStepType == type;
                final color = RoadmapStepModel.stepColor(type);

                return GestureDetector(
                  onTap: alreadyExists ? null : () => setState(() => _selectedStepType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: alreadyExists
                          ? const Color(0x08FFFFFF)
                          : isSelected
                              ? color.withOpacity(0.2)
                              : const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: alreadyExists
                            ? const Color(0x15FFFFFF)
                            : isSelected
                                ? color
                                : const Color(0x30FFFFFF),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: alreadyExists
                              ? const Color(0x33FFFFFF)
                              : isSelected
                                  ? color
                                  : const Color(0x88FFFFFF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: alreadyExists
                                ? const Color(0x33FFFFFF)
                                : isSelected
                                    ? color
                                    : const Color(0xAAFFFFFF),
                          ),
                        ),
                        if (alreadyExists) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check, size: 10, color: Color(0x44FFFFFF)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // ETC 선택 시 제목 직접 입력 + 색상 선택
            if (_selectedStepType == 'ETC') ...[
              const SizedBox(height: 16),
              const Text(
                '단계 이름',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xAAFFFFFF)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _customTitleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '예: 청첩장, 사진촬영, 혼수 준비 등',
                  hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0x0FFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPink, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '색상 선택',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xAAFFFFFF)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorPalette.map((c) => GestureDetector(
                  onTap: () => setState(() => _customColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _customColor == c
                          ? Border.all(color: Colors.white, width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                      boxShadow: _customColor == c
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                    child: _customColor == c
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                )).toList(),
              ),
            ],

            // 마감일 설정
            if (_selectedStepType != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '마감일 설정',
                    style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _hasDueDate,
                    activeColor: _kPink,
                    onChanged: (v) => setState(() {
                      _hasDueDate = v;
                      if (v && _dueDate == null) _dueDate = DateTime.now();
                    }),
                  ),
                ],
              ),
              if (_hasDueDate && _dueDate != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: _kPink,
                            surface: Color(0xFF1E1E2E),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: _kPink),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_dueDate!),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedStepType != null ? _kPink : const Color(0x22FFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (_selectedStepType != null && !_isSaving) ? _onAdd : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '추가',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAdd() async {
    final stepType = _selectedStepType!;
    String title;

    if (stepType == 'ETC') {
      title = _customTitleCtrl.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          const SnackBar(
            content: Text('단계 이름을 입력해주세요.'),
            backgroundColor: Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      title = RoadmapStepModel.defaultTitle(stepType);
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.scaffoldContext);
    final ok = await widget.notifier.createStep(
      stepType: stepType,
      title: title,
      dueDate: _hasDueDate ? _dueDate : null,
      hasDueDate: _hasDueDate,
      groupOid: widget.groupOid,
      initialDetails: stepType == 'ETC' ? {'customColor': _customColor.value} : null,
    );

    if (mounted) {
      if (ok) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('단계가 추가되었습니다.'),
            backgroundColor: Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSuccess?.call();
      } else {
        setState(() => _isSaving = false);
      }
    }
  }
}
