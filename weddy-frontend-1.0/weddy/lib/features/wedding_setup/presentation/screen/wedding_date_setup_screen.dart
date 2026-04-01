import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/wedding_setup/presentation/notifier/wedding_setup_notifier.dart';

// ---------------------------------------------------------------------------
// Color Constants — Dark Glassmorphism
// ---------------------------------------------------------------------------

const _kPink = Color(0xFFEC4899);
const _kDarkPink = Color(0xFFDB2777);
const _kBgDark1 = Color(0xFF1A1A19);
const _kBgDark2 = Color(0xFF111110);
// Glass layers
const _kGlass = Color(0x0FFFFFFF);          // white 6%
const _kGlassBorder = Color(0x38FFFFFF);    // white 22%
// Text
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);        // white 67%

// ---------------------------------------------------------------------------
// WeddingDateSetupScreen
// ---------------------------------------------------------------------------

class WeddingDateSetupScreen extends ConsumerStatefulWidget {
  const WeddingDateSetupScreen({super.key});

  @override
  ConsumerState<WeddingDateSetupScreen> createState() =>
      _WeddingDateSetupScreenState();
}

class _WeddingDateSetupScreenState
    extends ConsumerState<WeddingDateSetupScreen> {
  // 날짜 범위: 오늘 ~ 10년 뒤
  late final DateTime _minDate;
  late final DateTime _maxDate;

  // 스크롤 컨트롤러
  late final FixedExtentScrollController _yearCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _dayCtrl;

  // 선택된 인덱스 (연도 리스트 내 인덱스, 월/일은 0-based)
  late int _selectedYearIndex;
  late int _selectedMonthIndex; // 0 = 1월
  late int _selectedDayIndex;   // 0 = 1일

  late List<int> _years;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _minDate = DateTime(now.year, now.month, now.day);
    _maxDate = DateTime(now.year + 10, now.month, now.day);

    // 초기값: 1년 뒤
    final initial = DateTime(now.year + 1, now.month, now.day);

    _years = List.generate(
        _maxDate.year - _minDate.year + 1, (i) => _minDate.year + i);

    _selectedYearIndex =
        _years.indexOf(initial.year).clamp(0, _years.length - 1);
    _selectedMonthIndex = (initial.month - 1).clamp(0, 11);
    _selectedDayIndex = (initial.day - 1)
        .clamp(0, _daysInMonth(initial.year, initial.month) - 1);

    _yearCtrl =
        FixedExtentScrollController(initialItem: _selectedYearIndex);
    _monthCtrl =
        FixedExtentScrollController(initialItem: _selectedMonthIndex);
    _dayCtrl =
        FixedExtentScrollController(initialItem: _selectedDayIndex);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int get _currentYear => _years[_selectedYearIndex];
  int get _currentMonth => _selectedMonthIndex + 1;
  int get _currentDay => _selectedDayIndex + 1;
  int get _maxDays => _daysInMonth(_currentYear, _currentMonth);

  /// 선택된 날짜를 DateTime으로 반환. 일이 최대 일수를 초과하면 클램프.
  DateTime get _selectedDate {
    final day = _currentDay.clamp(1, _maxDays);
    return DateTime(_currentYear, _currentMonth, day);
  }

  void _onYearChanged(int index) {
    setState(() {
      _selectedYearIndex = index;
      final newMax = _daysInMonth(_currentYear, _currentMonth);
      if (_selectedDayIndex >= newMax) {
        _selectedDayIndex = newMax - 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dayCtrl.hasClients) {
            _dayCtrl.jumpToItem(_selectedDayIndex);
          }
        });
      }
    });
  }

  void _onMonthChanged(int index) {
    setState(() {
      _selectedMonthIndex = index;
      final newMax = _daysInMonth(_currentYear, _currentMonth);
      if (_selectedDayIndex >= newMax) {
        _selectedDayIndex = newMax - 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dayCtrl.hasClients) {
            _dayCtrl.jumpToItem(_selectedDayIndex);
          }
        });
      }
    });
  }

  void _onDayChanged(int index) {
    setState(() => _selectedDayIndex = index);
  }

  Future<void> _handleSave() async {
    await ref
        .read(weddingSetupProvider.notifier)
        .saveWeddingDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WeddingSetupState>(weddingSetupProvider, (prev, next) {
      if (next is WeddingSetupSuccess) {
        context.go(AppRoutes.home);
        return;
      }
      if (next is WeddingSetupError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(weddingSetupProvider.notifier).clearError();
      }
    });

    final state = ref.watch(weddingSetupProvider);
    final isLoading = state is WeddingSetupLoading;

    return Scaffold(
      backgroundColor: _kBgDark1,
      body: Stack(
        children: [
          // ── 배경 그라디언트 ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kBgDark1, _kBgDark2],
              ),
            ),
          ),
          // ── 배경 핑크 글로우 오브 ────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPink.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kDarkPink.withOpacity(0.05),
              ),
            ),
          ),
          // ── 콘텐츠 ───────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kGlass,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: _kGlassBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: _kPink.withOpacity(0.12),
                              blurRadius: 32,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(36, 40, 36, 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── 로고 ──────────────────────────────
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: _kPink,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kPink.withOpacity(0.45),
                                          blurRadius: 24,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(Icons.favorite,
                                            color: Colors.white, size: 36),
                                        Icon(Icons.favorite,
                                            color: Colors.white
                                                .withOpacity(0.35),
                                            size: 26),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'WEDDLY',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── 안내 문구 ──────────────────────────
                            const Center(
                              child: Column(
                                children: [
                                  Text(
                                    '결혼 예정일을 알려주세요',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _kText,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '소중한 날을 함께 준비할게요',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kTextSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── 날짜 휠 선택기 ─────────────────────
                            _DateWheelPicker(
                              years: _years,
                              yearCtrl: _yearCtrl,
                              monthCtrl: _monthCtrl,
                              dayCtrl: _dayCtrl,
                              selectedYearIndex: _selectedYearIndex,
                              selectedMonthIndex: _selectedMonthIndex,
                              selectedDayIndex: _selectedDayIndex,
                              maxDays: _maxDays,
                              onYearChanged:
                                  isLoading ? null : _onYearChanged,
                              onMonthChanged:
                                  isLoading ? null : _onMonthChanged,
                              onDayChanged:
                                  isLoading ? null : _onDayChanged,
                            ),
                            const SizedBox(height: 24),

                            // ── 선택된 날짜 표시 ───────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0x33EC4899), // 핑크 20%
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _kPink.withOpacity(0.40)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: _kPink),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_currentYear년 $_currentMonth월 ${_currentDay.clamp(1, _maxDays)}일',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _kPink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── 저장하기 버튼 ──────────────────────
                            _PinkButton(
                              label: '저장하기',
                              isLoading: isLoading,
                              onPressed: _handleSave,
                            ),
                            const SizedBox(height: 12),

                            // ── 나중에 설정 ────────────────────────
                            Center(
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        ref
                                            .read(weddingSetupSkippedProvider
                                                .notifier)
                                            .state = true;
                                        context.go(AppRoutes.home);
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Colors.white.withOpacity(0.50),
                                ),
                                child: const Text(
                                  '나중에 설정하기',
                                  style: TextStyle(fontSize: 13),
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
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 날짜 휠 선택기 (다크 글래스)
// ---------------------------------------------------------------------------

class _DateWheelPicker extends StatelessWidget {
  final List<int> years;
  final FixedExtentScrollController yearCtrl;
  final FixedExtentScrollController monthCtrl;
  final FixedExtentScrollController dayCtrl;
  final int selectedYearIndex;
  final int selectedMonthIndex;
  final int selectedDayIndex;
  final int maxDays;
  final ValueChanged<int>? onYearChanged;
  final ValueChanged<int>? onMonthChanged;
  final ValueChanged<int>? onDayChanged;

  const _DateWheelPicker({
    required this.years,
    required this.yearCtrl,
    required this.monthCtrl,
    required this.dayCtrl,
    required this.selectedYearIndex,
    required this.selectedMonthIndex,
    required this.selectedDayIndex,
    required this.maxDays,
    this.onYearChanged,
    this.onMonthChanged,
    this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    const wheelHeight = 200.0;
    const itemExtent = 44.0;

    return Container(
      height: wheelHeight,
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF), // white 8%
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 선택 영역 하이라이트
          Positioned(
            top: (wheelHeight - itemExtent) / 2,
            left: 0,
            right: 0,
            child: Container(
              height: itemExtent,
              decoration: BoxDecoration(
                color: const Color(0x33EC4899), // 핑크 20%
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: _kPink.withOpacity(0.35),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // 세 컬럼
          Row(
            children: [
              // 연도 컬럼
              Expanded(
                flex: 4,
                child: _WheelColumn(
                  controller: yearCtrl,
                  itemCount: years.length,
                  selectedIndex: selectedYearIndex,
                  itemExtent: itemExtent,
                  onSelectedItemChanged: onYearChanged,
                  itemBuilder: (index) => '${years[index]}',
                  suffix: '년',
                ),
              ),
              // 월 컬럼
              Expanded(
                flex: 3,
                child: _WheelColumn(
                  controller: monthCtrl,
                  itemCount: 12,
                  selectedIndex: selectedMonthIndex,
                  itemExtent: itemExtent,
                  onSelectedItemChanged: onMonthChanged,
                  itemBuilder: (index) => '${index + 1}',
                  suffix: '월',
                ),
              ),
              // 일 컬럼
              Expanded(
                flex: 3,
                child: _WheelColumn(
                  controller: dayCtrl,
                  itemCount: maxDays,
                  selectedIndex: selectedDayIndex,
                  itemExtent: itemExtent,
                  onSelectedItemChanged: onDayChanged,
                  itemBuilder: (index) => '${index + 1}',
                  suffix: '일',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 단일 휠 컬럼
// ---------------------------------------------------------------------------

class _WheelColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final double itemExtent;
  final ValueChanged<int>? onSelectedItemChanged;
  final String Function(int index) itemBuilder;
  final String suffix;

  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      physics: onSelectedItemChanged != null
          ? const FixedExtentScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      diameterRatio: 1.8,
      squeeze: 1.0,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: Text(
              '${itemBuilder(index)}$suffix',
              style: TextStyle(
                fontSize: isSelected ? 18 : 14,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w400,
                color: isSelected
                    ? _kPink
                    : Colors.white.withOpacity(0.40),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 핑크 그라디언트 버튼 (강화된 glow)
// ---------------------------------------------------------------------------

class _PinkButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PinkButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_PinkButton> createState() => _PinkButtonState();
}

class _PinkButtonState extends State<_PinkButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!widget.isLoading) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: widget.isLoading
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isLoading) setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: widget.isLoading
                  ? LinearGradient(
                      colors: [Colors.grey[700]!, Colors.grey[600]!])
                  : LinearGradient(
                      colors: _hovered
                          ? [_kDarkPink, const Color(0xFFBE185D)]
                          : [_kPink, const Color(0xFFF9A8D4)],
                    ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: widget.isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: _kPink
                            .withOpacity(_pressed ? 0.20 : 0.45),
                        blurRadius: _pressed ? 6 : 20,
                        offset: Offset(0, _pressed ? 1 : 7),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
