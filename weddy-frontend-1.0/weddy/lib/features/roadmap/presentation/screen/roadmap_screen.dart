import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/roadmap/data/model/hall_tour_model.dart';
import 'package:weddy/features/roadmap/data/model/roadmap_step_model.dart';
import 'package:weddy/features/roadmap/presentation/notifier/roadmap_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수
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
  const RoadmapScreen({super.key});

  @override
  ConsumerState<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends ConsumerState<RoadmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) return;
      ref.read(roadmapNotifierProvider.notifier).loadSteps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapNotifierProvider);

    ref.listen<RoadmapState>(roadmapNotifierProvider, (prev, next) {
      if (next is RoadmapError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(roadmapNotifierProvider.notifier).clearError();
      }
    });

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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '웨딩 관리',
        style: TextStyle(
            color: _kText, fontSize: 17, fontWeight: FontWeight.w700),
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
      final steps = state.steps;
      if (steps.isEmpty) {
        return _buildNoDataState(context);
      }

      final authState = ref.read(authNotifierProvider);
      final weddingDate = authState is AuthAuthenticated
          ? authState.user.weddingDate
          : null;

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: steps.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildHeaderCard(steps);
          final step = steps[i - 1];
          return _RoadmapStepCard(
            step: step,
            weddingDate: weddingDate,
            onToggle: () =>
                ref.read(roadmapNotifierProvider.notifier).toggleDone(step.oid),
            onTap: () => _showStepDetailBottomSheet(context, step),
          );
        },
      );
    }

    // RoadmapInitial or error → retry UI
    return _buildEmptyState(context);
  }

  // 로드 성공했지만 데이터가 없는 경우
  Widget _buildNoDataState(BuildContext context) {
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
            '웨딩 관리 단계가 없습니다.',
            style: TextStyle(fontSize: 14, color: _kTextSub),
          ),
          const SizedBox(height: 4),
          const Text(
            '단계를 추가하여 결혼 준비를 시작하세요.',
            style: TextStyle(fontSize: 12, color: _kTextMute),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(roadmapNotifierProvider.notifier).loadSteps(),
            child: const Text(
              '새로고침',
              style: TextStyle(color: _kPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(List<RoadmapStepModel> steps) {
    final total = steps.length;
    final done = steps.where((s) => s.isDone).length;
    final percent = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGlassBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '결혼 준비 로드맵',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText),
              ),
              Text(
                '$done / $total 완료',
                style: const TextStyle(fontSize: 12, color: _kTextSub),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0x3310B981),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_kDone),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '각 단계를 탭해서 세부 정보를 입력하세요.',
            style: TextStyle(fontSize: 11, color: _kTextMute),
          ),
        ],
      ),
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
            child: const Text(
              '다시 시도',
              style: TextStyle(color: _kPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: _kPink,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('단계 추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      onPressed: () {
        final scaffoldContext = context;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddStepBottomSheet(
            scaffoldContext: scaffoldContext,
            notifier: ref.read(roadmapNotifierProvider.notifier),
            existingStepTypes: (ref.read(roadmapNotifierProvider) is RoadmapLoaded)
                ? (ref.read(roadmapNotifierProvider) as RoadmapLoaded).steps.map((s) => s.stepType).toList()
                : [],
          ),
        );
      },
    );
  }

  void _showStepDetailBottomSheet(
      BuildContext context, RoadmapStepModel step) {
    final scaffoldContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StepDetailBottomSheet(
        step: step,
        scaffoldContext: scaffoldContext,
        notifier: ref.read(roadmapNotifierProvider.notifier),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 단계 카드 위젯
// ---------------------------------------------------------------------------

class _RoadmapStepCard extends StatelessWidget {
  final RoadmapStepModel step;
  final DateTime? weddingDate;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _RoadmapStepCard({
    required this.step,
    this.weddingDate,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = RoadmapStepModel.stepColor(step.stepType);
    final icon = RoadmapStepModel.stepIcon(step.stepType);
    final dDayText = weddingDate != null
        ? step.dDayText(weddingDate!)
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kGlass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: step.isDone
                ? _kDone.withOpacity(0.3)
                : _kGlassBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // 아이콘 원형 배경
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // 제목 & 상태
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: step.isDone
                          ? _kTextSub
                          : _kText,
                      decoration: step.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (dDayText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dDayText,
                      style: TextStyle(
                        fontSize: 11,
                        color: dDayText.contains('지남')
                            ? _kUrgent
                            : _kTextMute,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 완료/미완료 토글 버튼
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: step.isDone
                      ? _kDone.withOpacity(0.15)
                      : const Color(0x0FFFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: step.isDone
                        ? _kDone
                        : const Color(0x33FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  step.isDone ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: step.isDone ? _kDone : _kTextMute,
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
// 단계 상세 BottomSheet
// ---------------------------------------------------------------------------

class _StepDetailBottomSheet extends StatefulWidget {
  final RoadmapStepModel step;
  final BuildContext scaffoldContext;
  final RoadmapNotifier notifier;

  const _StepDetailBottomSheet({
    required this.step,
    required this.scaffoldContext,
    required this.notifier,
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

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x44FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 헤더
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
      final newTitle = widget.step.stepType == 'ETC'
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

      // isDone 토글 (변경된 경우에만, mounted 확인 후 수행)
      if (ok && _isDone != widget.step.isDone && mounted) {
        await widget.notifier.toggleDone(widget.step.oid);
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

  const _AddStepBottomSheet({
    required this.scaffoldContext,
    required this.notifier,
    required this.existingStepTypes,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x44FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              children: _stepInfos.map((info) {
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

            // ETC 선택 시 제목 직접 입력
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
      } else {
        setState(() => _isSaving = false);
      }
    }
  }
}
