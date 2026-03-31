import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:weddy/features/guest/data/model/guest_group_model.dart';
import 'package:weddy/features/guest/data/model/guest_model.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_group_notifier.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_notifier.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_summary_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수 (앱 전체 글래스모피즘 테마와 동일)
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF080810);
const _kBg2 = Color(0xFF0C0820);
const _kGlass = Color(0x1AFFFFFF);
const _kGlassBorder = Color(0x33FFFFFF);
const _kPink = Color(0xFFEC4899);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kTextMute = Color(0x66FFFFFF);
const _kGreen = Color(0xFF4CAF50);
const _kRed = Color(0xFFF44336);

// ---------------------------------------------------------------------------
// GuestScreen
// ---------------------------------------------------------------------------

/// 하객 관리 화면.
///
/// 상단 대시보드: 총 하객 수, 참석/미정/불참, 총 축의금
/// 탭바: [전체] + 그룹별 탭 + [+] (그룹 생성)
/// 정렬 칩 + 하객 목록 (Dismissible 좌우 스와이프 삭제)
class GuestScreen extends ConsumerStatefulWidget {
  const GuestScreen({super.key});

  @override
  ConsumerState<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends ConsumerState<GuestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _currentSort = 'NAME_ASC';
  String? _currentGroupOid; // null = 전체

  // 마지막으로 렌더링한 그룹 목록 (탭 재생성 감지용)
  List<GuestGroupModel> _lastGroups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await ref.read(guestGroupNotifierProvider.notifier).loadGroups();
    await ref.read(guestNotifierProvider.notifier).loadGuests(sort: _currentSort);
  }

  /// 그룹 목록이 바뀌면 TabController를 재생성한다.
  void _syncTabController(List<GuestGroupModel> groups) {
    if (_lastGroups.length == groups.length &&
        _lastGroups.every((g) =>
            groups.any((ng) => ng.oid == g.oid && ng.name == g.name))) {
      return;
    }
    _lastGroups = List.unmodifiable(groups);

    // 탭 수: [전체] + 그룹 수 + [+]
    final tabCount = 1 + groups.length + 1;
    _tabController.dispose();
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: _currentGroupOid == null
          ? 0
          : 1 + groups.indexWhere((g) => g.oid == _currentGroupOid),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;

      // [+] 탭 클릭 시
      if (idx == groups.length + 1) {
        // 즉시 이전 탭으로 복원
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(_currentGroupOid == null
                ? 0
                : 1 + groups.indexWhere((g) => g.oid == _currentGroupOid));
          }
        });
        _showCreateGroupDialog();
        return;
      }

      // 일반 탭 전환
      final newGroupOid = idx == 0 ? null : groups[idx - 1].oid;
      if (newGroupOid != _currentGroupOid) {
        _currentGroupOid = newGroupOid;
        ref
            .read(guestNotifierProvider.notifier)
            .loadGuests(groupOid: newGroupOid, sort: _currentSort);
      }
    });
  }

  // ── 그룹 생성 다이얼로그 ─────────────────────────────────────────────────

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGlassBorder, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '새 그룹 만들기',
                    style: TextStyle(
                      color: _kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: _kText, fontSize: 15),
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: '그룹명 입력',
                      hintStyle: const TextStyle(color: _kTextMute),
                      counterStyle: const TextStyle(color: _kTextMute),
                      filled: true,
                      fillColor: _kGlass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kGlassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kGlassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('취소',
                            style: TextStyle(color: _kTextSub)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          Navigator.of(ctx).pop();
                          await ref
                              .read(guestGroupNotifierProvider.notifier)
                              .createGroup(name);
                        },
                        child: const Text('만들기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 그룹 이름 수정 다이얼로그 ─────────────────────────────────────────────

  void _showEditGroupDialog(GuestGroupModel group) {
    final nameCtrl = TextEditingController(text: group.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGlassBorder, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '그룹 이름 수정',
                    style: TextStyle(
                      color: _kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: _kText, fontSize: 15),
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: '그룹명 입력',
                      hintStyle: const TextStyle(color: _kTextMute),
                      counterStyle: const TextStyle(color: _kTextMute),
                      filled: true,
                      fillColor: _kGlass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kGlassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kGlassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('취소',
                            style: TextStyle(color: _kTextSub)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          Navigator.of(ctx).pop();
                          await ref
                              .read(guestGroupNotifierProvider.notifier)
                              .updateGroup(group.oid, name);
                        },
                        child: const Text('저장'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 그룹 삭제 확인 다이얼로그 ─────────────────────────────────────────────

  void _confirmDeleteGroup(GuestGroupModel group) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('그룹 삭제', style: TextStyle(color: _kText)),
        content: Text(
          '"${group.name}" 그룹을 삭제하시겠습니까?\n소속 하객은 미분류로 이동됩니다.',
          style: const TextStyle(color: _kTextSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: _kTextSub)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // 탭이 삭제될 그룹을 가리키고 있으면 전체 탭으로 이동
              if (_currentGroupOid == group.oid) {
                _currentGroupOid = null;
                await ref
                    .read(guestNotifierProvider.notifier)
                    .loadGuests(sort: _currentSort);
              }
              await ref
                  .read(guestGroupNotifierProvider.notifier)
                  .deleteGroup(group.oid);
            },
            child: const Text('삭제', style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );
  }

  // ── 정렬 칩 ──────────────────────────────────────────────────────────────

  static const _kSortOptions = [
    ('NAME_ASC', '이름순'),
    ('ATTEND_STATUS', '참석순'),
    ('INVITATION_STATUS', '청첩장순'),
    ('GIFT_HIGH', '축의금↓'),
    ('GIFT_LOW', '축의금↑'),
  ];

  // ── 빌드 ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(guestGroupNotifierProvider);
    final guestState = ref.watch(guestNotifierProvider);
    final summaryAsync = ref.watch(guestSummaryProvider);

    List<GuestGroupModel> groups = [];
    if (groupState is GuestGroupLoaded) {
      groups = groupState.groups;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncTabController(groups);
      });
    }

    return Scaffold(
      backgroundColor: _kBg1,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPink,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await context.push<bool>('/guest/form');
          if (result == true && mounted) {
            ref.invalidate(guestSummaryProvider);
            ref.read(guestNotifierProvider.notifier).loadGuests(
                  groupOid: _currentGroupOid,
                  sort: _currentSort,
                );
          }
        },
        child: const Icon(Icons.person_add_outlined),
      ),
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
              // ── AppBar ───────────────────────────────────────────────────
              _buildAppBar(context),

              // ── 대시보드 카드 ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildDashboard(summaryAsync),
              ),

              // ── 탭바 + 목록 ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    _buildTabBar(groups),
                    const SizedBox(height: 4),
                    _buildSortChips(),
                    Expanded(
                      child: _buildGuestList(guestState, groups),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: _kText, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          const Text(
            '하객 관리',
            style: TextStyle(
              color: _kText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: _kTextSub, size: 22),
            onPressed: () {
              ref.invalidate(guestSummaryProvider);
              ref.read(guestGroupNotifierProvider.notifier).loadGroups();
              ref.read(guestNotifierProvider.notifier).loadGuests(
                    groupOid: _currentGroupOid,
                    sort: _currentSort,
                  );
            },
          ),
        ],
      ),
    );
  }

  // ── 대시보드 ─────────────────────────────────────────────────────────────

  Widget _buildDashboard(AsyncValue<dynamic> summaryAsync) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGlassBorder, width: 1),
          ),
          child: summaryAsync.when(
            loading: () => const Center(
              child: SizedBox(
                height: 40,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPink),
              ),
            ),
            error: (_, __) => const Center(
              child: Text('집계 정보를 불러올 수 없습니다.',
                  style: TextStyle(color: _kTextSub, fontSize: 13)),
            ),
            data: (summary) => Column(
              children: [
                // 총 하객
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${summary.totalCount}',
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '명',
                      style: TextStyle(color: _kTextSub, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 참석 상태 3개
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DashStat(
                      label: '참석',
                      value: '${summary.attendCount}',
                      color: _kGreen,
                    ),
                    _DashDivider(),
                    _DashStat(
                      label: '미정',
                      value: '${summary.undecidedCount}',
                      color: _kTextSub,
                    ),
                    _DashDivider(),
                    _DashStat(
                      label: '불참',
                      value: '${summary.absentCount}',
                      color: _kRed,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 축의금
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.currency_exchange,
                          size: 14, color: _kPink),
                      const SizedBox(width: 6),
                      const Text(
                        '축의금 합계',
                        style: TextStyle(color: _kTextSub, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₩${_formatAmount(summary.totalGiftAmount)}',
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 탭바 ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar(List<GuestGroupModel> groups) {
    // TabController 길이가 실제 탭 수와 일치하지 않으면 빈 탭바를 반환
    final expectedLength = 1 + groups.length + 1;
    if (_tabController.length != expectedLength) {
      return const SizedBox.shrink();
    }

    final tabs = <Widget>[
      const Tab(text: '전체'),
      ...groups.map((g) => Tab(
            child: GestureDetector(
              // 롱프레스: 기본 그룹이 아닌 경우 수정/삭제 메뉴
              onLongPress: g.isDefault
                  ? null
                  : () => _showGroupMenu(context, g),
              child: Text(g.name),
            ),
          )),
      const Tab(
        child: Icon(Icons.add, size: 18),
      ),
    ];

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: _kPink,
      unselectedLabelColor: _kTextSub,
      indicatorColor: _kPink,
      indicatorWeight: 2,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
      tabs: tabs,
    );
  }

  /// 비기본 그룹 롱프레스 메뉴: 수정 / 삭제
  void _showGroupMenu(BuildContext context, GuestGroupModel group) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGlassBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                group.name,
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Divider(height: 1, color: _kGlassBorder),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _kPink),
              title: const Text('그룹 이름 수정',
                  style: TextStyle(color: _kText)),
              onTap: () {
                Navigator.of(context).pop();
                _showEditGroupDialog(group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _kRed),
              title: const Text('그룹 삭제',
                  style: TextStyle(color: _kRed)),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDeleteGroup(group);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── 정렬 칩 ──────────────────────────────────────────────────────────────

  Widget _buildSortChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _kSortOptions.map((opt) {
          final (value, label) = opt;
          final isSelected = _currentSort == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (isSelected) return;
                setState(() => _currentSort = value);
                ref.read(guestNotifierProvider.notifier).changeSort(value);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _kPink.withOpacity(0.2)
                      : _kGlass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kPink : _kGlassBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _kPink : _kTextSub,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 하객 목록 ─────────────────────────────────────────────────────────────

  Widget _buildGuestList(GuestState guestState, List<GuestGroupModel> groups) {
    if (guestState is GuestLoading || guestState is GuestInitial) {
      return const Center(
        child: CircularProgressIndicator(color: _kPink, strokeWidth: 2),
      );
    }

    if (guestState is GuestError) {
      return Center(
        child: Text(
          guestState.message,
          style: const TextStyle(color: _kTextSub, fontSize: 14),
        ),
      );
    }

    if (guestState is GuestLoaded) {
      final guests = guestState.guests;
      if (guests.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  color: _kTextMute, size: 48),
              SizedBox(height: 12),
              Text(
                '등록된 하객이 없습니다.',
                style: TextStyle(color: _kTextSub, fontSize: 15),
              ),
              SizedBox(height: 8),
              Text(
                '오른쪽 아래 + 버튼으로 추가하세요.',
                style: TextStyle(color: _kTextMute, fontSize: 12),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: guests.length,
        itemBuilder: (context, index) {
          final guest = guests[index];
          return _GuestTile(
            key: ValueKey(guest.oid),
            guest: guest,
            onTap: () => _onGuestTap(guest),
            onDelete: () => _onGuestDelete(guest),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  // ── 하객 탭 → 수정 폼 ────────────────────────────────────────────────────

  Future<void> _onGuestTap(GuestModel guest) async {
    final result =
        await context.push<bool>('/guest/form?oid=${guest.oid}');
    if (result == true && mounted) {
      ref.invalidate(guestSummaryProvider);
      ref.read(guestNotifierProvider.notifier).loadGuests(
            groupOid: _currentGroupOid,
            sort: _currentSort,
          );
    }
  }

  // ── 하객 삭제 ─────────────────────────────────────────────────────────────

  Future<void> _onGuestDelete(GuestModel guest) async {
    await ref.read(guestNotifierProvider.notifier).deleteGuest(guest.oid);
    if (mounted) {
      ref.invalidate(guestSummaryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${guest.name}님을 삭제했습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2A2A3E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── 유틸 ─────────────────────────────────────────────────────────────────

  static String _formatAmount(int amount) {
    if (amount >= 1000000) {
      final man = amount ~/ 10000;
      final remainder = amount % 10000;
      if (remainder == 0) return '$man만';
      return '$man만 ${_addComma(remainder)}';
    }
    return _addComma(amount);
  }

  static String _addComma(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ---------------------------------------------------------------------------
// 대시보드 서브 위젯
// ---------------------------------------------------------------------------

class _DashStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DashStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: _kTextSub, fontSize: 12),
        ),
      ],
    );
  }
}

class _DashDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: _kGlassBorder,
    );
  }
}

// ---------------------------------------------------------------------------
// 하객 타일
// ---------------------------------------------------------------------------

class _GuestTile extends StatelessWidget {
  final GuestModel guest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GuestTile({
    super.key,
    required this.guest,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${guest.oid}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // 낙관적 삭제는 notifier에서 처리
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGlassBorder, width: 1),
          ),
          child: Row(
            children: [
              // 아바타
              CircleAvatar(
                radius: 22,
                backgroundColor: _kPink.withOpacity(0.15),
                child: Text(
                  guest.name.isNotEmpty
                      ? guest.name.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: _kPink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 이름 + 그룹명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.name,
                      style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (guest.groupName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        guest.groupName!,
                        style: const TextStyle(
                          color: _kTextMute,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (guest.memo != null && guest.memo!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        guest.memo!,
                        style: const TextStyle(
                          color: _kTextMute,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 오른쪽 배지들
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 참석 뱃지
                  _StatusBadge(
                    label: guest.attendLabel,
                    color: _attendColor(guest.attendStatus),
                  ),
                  const SizedBox(height: 4),
                  // 청첩장 뱃지
                  _StatusBadge(
                    label: guest.inviteLabel,
                    color: _inviteColor(guest.invitationStatus),
                  ),
                  if (guest.companionCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${guest.companionCount}명',
                      style: const TextStyle(
                        color: _kTextSub,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _attendColor(String status) => switch (status) {
        'ATTEND' => _kGreen,
        'ABSENT' => _kRed,
        _ => const Color(0x88FFFFFF),
      };

  Color _inviteColor(String status) => switch (status) {
        'PAPER' => const Color(0xFF60A5FA),
        'MOBILE' => const Color(0xFFFBBF24),
        _ => const Color(0x88FFFFFF),
      };
}

// ---------------------------------------------------------------------------
// 상태 뱃지
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
