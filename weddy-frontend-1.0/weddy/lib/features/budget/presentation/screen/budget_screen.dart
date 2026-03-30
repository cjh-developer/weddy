import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:weddy/features/attachment/presentation/widget/attachment_section_widget.dart';
import 'package:weddy/features/budget/data/model/budget_item_model.dart';
import 'package:weddy/features/budget/data/model/budget_model.dart';
import 'package:weddy/features/budget/data/model/budget_settings_model.dart';
import 'package:weddy/features/budget/presentation/notifier/budget_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수 (홈/체크리스트 Dark Glass 테마 통일)
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF080810);
const _kBg2 = Color(0xFF0C0820);
const _kGlass = Color(0x14FFFFFF);
const _kGlassBorder = Color(0x33FFFFFF);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kTextMute = Color(0x66FFFFFF);
const _kGreen = Color(0xFF10B981);
const _kUrgent = Color(0xFFEF4444);
const _kAmber = Color(0xFFF59E0B);
const _kBudgetColor = Color(0xFF34D399); // 에메랄드 — 예산 테마

// ---------------------------------------------------------------------------
// 유틸 함수
// ---------------------------------------------------------------------------

final _moneyFmt = NumberFormat('#,###', 'ko_KR');

String _formatMoney(int amount) => '${_moneyFmt.format(amount)}원';

String _formatMoneyShort(int amount) {
  if (amount >= 100000000) {
    final eok = amount / 100000000;
    return eok == eok.truncateToDouble()
        ? '${eok.toInt()}억원'
        : '${eok.toStringAsFixed(1)}억원';
  }
  if (amount >= 10000) {
    final man = amount / 10000;
    return man == man.truncateToDouble()
        ? '${man.toInt()}만원'
        : '${man.toStringAsFixed(1)}만원';
  }
  return '${_moneyFmt.format(amount)}원';
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// 공통 다이얼로그 입력 필드 (top-level — _BudgetScreenState, _BudgetSectionState 공유)
// ---------------------------------------------------------------------------

Widget _buildBudgetDialogField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    keyboardAppearance: Brightness.dark,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
      prefixIcon: Icon(icon, color: _kBudgetColor, size: 18),
      filled: true,
      fillColor: const Color(0x1AFFFFFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBudgetColor, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    ),
  );
}

// ---------------------------------------------------------------------------
// BudgetScreen
// ---------------------------------------------------------------------------

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final budgetState = ref.read(budgetNotifierProvider);
      if (budgetState is BudgetInitial) {
        ref.read(budgetNotifierProvider.notifier).loadBudgets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetNotifierProvider);

    // 에러 SnackBar
    ref.listen<BudgetState>(budgetNotifierProvider, (prev, next) {
      if (next is BudgetError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(budgetNotifierProvider.notifier).clearError();
        });
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
              Expanded(child: _buildBody(context, budgetState)),
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
            '웨딩 예산',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddBudgetDialog(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kBudgetColor, Color(0xFF6EE7B7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kBudgetColor.withOpacity(0.40),
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
  Widget _buildBody(BuildContext context, BudgetState budgetState) {
    // 전체 예산 설정 여부를 먼저 확인한다.
    final settingsAsync = ref.watch(budgetSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _kBudgetColor),
      ),
      error: (_, __) => const Center(
        child: CircularProgressIndicator(color: _kBudgetColor),
      ),
      data: (settings) {
        // 이하 기존 예산 목록 화면 로직
        if (budgetState is BudgetLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _kBudgetColor),
          );
        }

        if (budgetState is BudgetError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _kUrgent, size: 48),
                const SizedBox(height: 12),
                Text(
                  budgetState.message,
                  style: const TextStyle(color: _kTextSub, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () =>
                      ref.read(budgetNotifierProvider.notifier).loadBudgets(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kBudgetColor, Color(0xFF6EE7B7)],
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

        if (budgetState is BudgetLoaded) {
          final budgets = budgetState.budgets;

          if (budgets.isEmpty) {
            return _buildEmptyState(context, settings);
          }

          // 전체 요약 + 카테고리 섹션
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummaryCard(budgets, settings),
                    const SizedBox(height: 16),
                    ...budgets.map((budget) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BudgetSection(
                            budget: budget,
                            onAddItem: (title, amount, memo, paidAt) {
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .addItem(
                                      budget.oid, title, amount, memo, paidAt);
                            },
                            onDeleteItem: (itemOid) {
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .deleteItem(budget.oid, itemOid);
                            },
                            onDeleteBudget: () {
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .deleteBudget(budget.oid);
                            },
                          ),
                        )),
                  ]),
                ),
              ),
            ],
          );
        }

        // BudgetInitial — 로딩 스피너
        return const Center(
          child: CircularProgressIndicator(color: _kBudgetColor),
        );
      },
    );
  }

  // ── 전체 요약 카드 ────────────────────────────────────────────────────────
  Widget _buildSummaryCard(
      List<BudgetModel> budgets, BudgetSettingsModel settings) {
    final totalPlanned = budgets.fold(0, (sum, b) => sum + b.plannedAmount);
    final totalSpent = budgets.fold(0, (sum, b) => sum + b.spentAmount);
    // 전체 예산 설정값이 있으면 그것을 기준으로, 없으면 계획 금액 기준으로 비율 계산
    final denominator = settings.totalBudget ?? totalPlanned;
    final rawRatio = denominator == 0 ? 0.0 : totalSpent / denominator;
    final usageRatio = rawRatio.clamp(0.0, 1.0);
    final isOver = rawRatio > 1.0;
    final usagePercent = (rawRatio * 100).clamp(0.0, double.infinity).toStringAsFixed(1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x38FFFFFF), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x2634D399),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: _kBudgetColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '예산 요약',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                ],
              ),
              // 전체 예산 행 (항상 표시 — 미설정 시 설정 버튼, 설정 시 수정 버튼)
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '전체 예산',
                    style: TextStyle(color: _kTextSub, fontSize: 13),
                  ),
                  if (settings.totalBudget == null)
                    GestureDetector(
                      onTap: () =>
                          _showEditTotalBudgetDialog(context, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBudgetColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _kBudgetColor.withOpacity(0.4),
                              width: 1),
                        ),
                        child: const Text(
                          '설정하기',
                          style: TextStyle(
                              color: _kBudgetColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMoney(settings.totalBudget!),
                          style: const TextStyle(
                              color: _kText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showEditTotalBudgetDialog(
                              context, settings.totalBudget!),
                          child: const Icon(Icons.edit_outlined,
                              color: _kTextMute, size: 14),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 16),
              // 금액 Row
              Row(
                children: [
                  Expanded(
                    child: _SummaryAmountTile(
                      label: '총 계획 금액',
                      amount: totalPlanned,
                      color: _kTextSub,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0x22FFFFFF),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: _SummaryAmountTile(
                      label: '총 지출 금액',
                      amount: totalSpent,
                      color: _kBudgetColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0x22FFFFFF),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: _SummaryAmountTile(
                      label: '잔여 금액',
                      amount: (settings.totalBudget ?? totalPlanned) -
                          totalSpent,
                      color:
                          (settings.totalBudget ?? totalPlanned) - totalSpent >=
                                  0
                              ? _kGreen
                              : _kUrgent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 진행률 바
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '예산 사용률',
                    style: TextStyle(fontSize: 12, color: _kTextSub),
                  ),
                  Text(
                    isOver
                        ? '${((rawRatio - 1.0) * 100).toStringAsFixed(1)}% 초과'
                        : '$usagePercent%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOver ? _kUrgent : _kBudgetColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: usageRatio.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOver
                              ? [_kUrgent, const Color(0xFFFCA5A5)]
                              : [_kBudgetColor, const Color(0xFF6EE7B7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
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

  // ── 전체 예산 설정/수정 다이얼로그 (화면 중앙) ───────────────────────────
  void _showEditTotalBudgetDialog(
      BuildContext context, int currentBudget) {
    final isNew = currentBudget == 0;
    final amountCtrl = TextEditingController(
        text: isNew ? '' : currentBudget.toString());

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13132A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: const Color(0x33FFFFFF), width: 1),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _kBudgetColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kBudgetColor.withOpacity(0.35),
                            width: 1.5),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: _kBudgetColor,
                          size: 36),
                    ),
                    const SizedBox(height: 20),
                    // 제목
                    Text(
                      isNew ? '전체 예산을 설정해주세요' : '전체 예산 수정',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isNew
                          ? '총 결혼 예산을 입력하면\n카테고리별 예산 관리가 시작됩니다'
                          : '변경할 전체 예산 금액을 입력해주세요',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: _kTextSub, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    // 금액 입력
                    _buildBudgetDialogField(
                      controller: amountCtrl,
                      hint: '전체 예산 금액 (원)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () async {
                          final raw = amountCtrl.text.trim();
                          final amount = int.tryParse(raw);
                          if (amount == null || amount < 1) return;
                          Navigator.of(ctx).pop();
                          final ok = await ref
                              .read(budgetNotifierProvider.notifier)
                              .upsertSettings(amount);
                          if (ok && mounted) {
                            ref.invalidate(budgetSettingsProvider);
                            ref
                                .read(budgetNotifierProvider.notifier)
                                .loadBudgets();
                          }
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kBudgetColor, Color(0xFF6EE7B7)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _kBudgetColor.withOpacity(0.40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isNew ? '예산 설정 시작' : '저장',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
        ),
      ),
    );
  }

  // ── 빈 상태 ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState(
      BuildContext context, BudgetSettingsModel settings) {
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
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: _kBudgetColor, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            '예산이 없습니다',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '+ 버튼을 눌러 첫 예산 카테고리를 추가해보세요',
            style: TextStyle(fontSize: 13, color: _kTextSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 전체 예산 항상 표시 — 설정 시 금액+수정, 미설정 시 설정하기
          GestureDetector(
            onTap: () => _showEditTotalBudgetDialog(
                context, settings.totalBudget ?? 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _kBudgetColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _kBudgetColor.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.isConfigured
                        ? '전체 예산: ${_formatMoneyShort(settings.totalBudget!)}'
                        : '전체 예산 설정하기',
                    style: const TextStyle(
                      color: _kBudgetColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined,
                      color: _kBudgetColor, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAddBudgetDialog(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kBudgetColor, Color(0xFF6EE7B7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kBudgetColor.withOpacity(0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '첫 예산 카테고리 추가',
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

  // ── 예산 카테고리 추가 다이얼로그 ─────────────────────────────────────────
  static const _kBudgetCategories = [
    '예식비', '스드메', '신혼여행', '예물·예단',
    '혼수·가전', '상견례', '청첩장', '기타',
  ];

  void _showAddBudgetDialog(BuildContext context) {
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? selectedCategory;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => BackdropFilter(
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
                          color: Color(0x2634D399),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: _kBudgetColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '새 예산 카테고리',
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
                            border:
                                Border.all(color: _kGlassBorder, width: 1),
                          ),
                          child: const Icon(Icons.close,
                              color: _kTextSub, size: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 카테고리 칩
                  const Text(
                    '카테고리 선택',
                    style: TextStyle(
                        color: _kTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kBudgetCategories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setDialogState(() {
                          selectedCategory = isSelected ? null : cat;
                          if (!isSelected) categoryCtrl.text = cat;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kBudgetColor
                                : const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _kBudgetColor
                                  : const Color(0x33FFFFFF),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : _kTextSub,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // 카테고리 직접 입력
                  _buildBudgetDialogField(
                    controller: categoryCtrl,
                    hint: '카테고리명 직접 입력 (필수)',
                    icon: Icons.label_outline,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  // 계획 금액 입력
                  _buildBudgetDialogField(
                    controller: amountCtrl,
                    hint: '계획 금액 (원, 필수)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  // 생성 버튼
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        final category = categoryCtrl.text.trim();
                        final amountText = amountCtrl.text.trim();
                        if (category.isEmpty || amountText.isEmpty) return;
                        final amount = int.tryParse(amountText);
                        if (amount == null || amount < 1) return;
                        Navigator.of(ctx).pop();
                        ref
                            .read(budgetNotifierProvider.notifier)
                            .createBudget(category, amount);
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kBudgetColor, Color(0xFF6EE7B7)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _kBudgetColor.withOpacity(0.40),
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
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// _SummaryAmountTile — 요약 카드의 금액 셀
// ---------------------------------------------------------------------------

class _SummaryAmountTile extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _SummaryAmountTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _kTextMute),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _formatMoneyShort(amount.abs()),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _BudgetSection — 예산 카테고리 카드 (펼침/접기)
// ---------------------------------------------------------------------------

class _BudgetSection extends StatefulWidget {
  final BudgetModel budget;
  final void Function(String title, int amount, String? memo, DateTime? paidAt)
      onAddItem;
  final void Function(String itemOid) onDeleteItem;
  final VoidCallback onDeleteBudget;

  const _BudgetSection({
    required this.budget,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onDeleteBudget,
  });

  @override
  State<_BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends State<_BudgetSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final usageRatio = budget.usageRatio;
    final isOver = usageRatio > 1.0;

    return Container(
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGlassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kBudgetColor.withOpacity(0.05),
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
                  // 카테고리 아이콘
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0x2634D399),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: _kBudgetColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  // 카테고리명 + 진행률 바
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: usageRatio.clamp(0.0, 1.0),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isOver
                                        ? [_kUrgent, const Color(0xFFFCA5A5)]
                                        : [_kBudgetColor, const Color(0xFF6EE7B7)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 금액 요약
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMoneyShort(budget.spentAmount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isOver ? _kUrgent : _kBudgetColor,
                        ),
                      ),
                      Text(
                        '/ ${_formatMoneyShort(budget.plannedAmount)}',
                        style: const TextStyle(
                            fontSize: 10, color: _kTextMute),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
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
                if (budget.items.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.06),
                    indent: 16,
                    endIndent: 16,
                  ),
                  ...budget.items.map((item) => _BudgetItemTile(
                        item: item,
                        onDelete: () => widget.onDeleteItem(item.oid),
                      )),
                ],
                // ── 항목 추가 버튼 ──
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.06),
                  indent: 16,
                  endIndent: 16,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: GestureDetector(
                    onTap: () => _showAddItemDialog(context),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x1A34D399),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0x4434D399), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: _kBudgetColor, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '지출 항목 추가',
                            style: TextStyle(
                              color: _kBudgetColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── 첨부파일 섹션 ──
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.06),
                  indent: 16,
                  endIndent: 16,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: AttachmentSectionWidget(
                    refType: 'BUDGET',
                    refOid: widget.budget.oid,
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

  void _showAddItemDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final memoCtrl = TextEditingController();

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
                        color: Color(0x2634D399),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long,
                          color: _kBudgetColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '지출 항목 추가',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                      ),
                    ),
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
                // 카테고리 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x2634D399),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.budget.category,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kBudgetColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                // 항목명
                _buildBudgetDialogField(
                  controller: titleCtrl,
                  hint: '항목명 (필수)',
                  icon: Icons.receipt_outlined,
                ),
                const SizedBox(height: 10),
                // 금액
                _buildBudgetDialogField(
                  controller: amountCtrl,
                  hint: '금액 (원, 필수)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 10),
                // 메모
                _buildBudgetDialogField(
                  controller: memoCtrl,
                  hint: '메모 (선택)',
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 20),
                // 추가 버튼
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      final amountText = amountCtrl.text.trim();
                      if (title.isEmpty || amountText.isEmpty) return;
                      final amount = int.tryParse(amountText);
                      if (amount == null || amount < 1) return;
                      final memo = memoCtrl.text.trim();
                      Navigator.of(ctx).pop();
                      widget.onAddItem(
                          title, amount, memo.isEmpty ? null : memo, null);
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kBudgetColor, Color(0xFF6EE7B7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _kBudgetColor.withOpacity(0.40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '추가하기',
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
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('예산 삭제',
            style: TextStyle(color: _kText, fontSize: 16)),
        content: const Text(
          '예산 카테고리와 모든 항목이 삭제됩니다.\n계속하시겠습니까?',
          style: TextStyle(color: _kTextSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('취소', style: TextStyle(color: _kTextSub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteBudget();
            },
            child:
                const Text('삭제', style: TextStyle(color: _kUrgent)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BudgetItemTile — 개별 지출 항목
// ---------------------------------------------------------------------------

class _BudgetItemTile extends StatelessWidget {
  final BudgetItemModel item;
  final VoidCallback onDelete;

  const _BudgetItemTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('budget_item_${item.oid}'),
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
            // 결제일 여부에 따른 아이콘
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.paidAt != null
                    ? const Color(0x2010B981)
                    : const Color(0x20F59E0B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                item.paidAt != null
                    ? Icons.check_circle_outline
                    : Icons.schedule,
                color: item.paidAt != null ? _kGreen : _kAmber,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            // 항목명 + 메모
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.memo != null && item.memo!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.memo!,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextMute),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 금액 + 결제일
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(item.amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kBudgetColor,
                  ),
                ),
                if (item.paidAt != null)
                  Text(
                    _formatDate(item.paidAt),
                    style: const TextStyle(
                        fontSize: 10, color: _kTextMute),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
