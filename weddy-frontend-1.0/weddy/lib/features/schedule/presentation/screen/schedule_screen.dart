import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:weddy/features/schedule/data/model/schedule_model.dart';
import 'package:weddy/features/schedule/presentation/notifier/schedule_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수 (홈 화면과 동일한 다크 글래스모피즘 팔레트)
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF080810);
const _kBg2 = Color(0xFF0C0820);
const _kGlass = Color(0x14FFFFFF);
const _kGlassBorder = Color(0x33FFFFFF);
const _kPink = Color(0xFFEC4899);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kTextMute = Color(0x66FFFFFF);

// ---------------------------------------------------------------------------
// 뷰 모드 enum
// ---------------------------------------------------------------------------

enum _ViewMode { monthly, weekly, daily }

// ---------------------------------------------------------------------------
// ScheduleScreen
// ---------------------------------------------------------------------------

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  _ViewMode _viewMode = _ViewMode.monthly;
  late DateTime _weekStart; // 해당 주의 월요일

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      ref.read(scheduleNotifierProvider.notifier).loadSchedules(
            year: now.year,
            month: now.month,
          );
    });
  }

  /// 주어진 날짜가 속한 주의 월요일(시작일)을 반환한다.
  DateTime _getWeekStart(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleNotifierProvider);

    ref.listen<ScheduleState>(scheduleNotifierProvider, (prev, next) {
      if (next is ScheduleError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(scheduleNotifierProvider.notifier).clearError();
      }
    });

    final schedules = scheduleState is ScheduleLoaded
        ? scheduleState.schedules
        : <ScheduleModel>[];

    final selectedDaySchedules = schedules
        .where((s) => isSameDay(s.startAt, _selectedDay))
        .toList();

    final isLoading = scheduleState is ScheduleLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
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
              _buildViewToggle(),
              if (_viewMode == _ViewMode.monthly) ...[
                _buildCalendarCard(schedules),
                Expanded(
                  child: _buildScheduleList(
                    context,
                    selectedDaySchedules,
                    isLoading,
                  ),
                ),
              ] else if (_viewMode == _ViewMode.weekly) ...[
                Expanded(child: _buildWeeklyView(schedules)),
              ] else ...[
                Expanded(child: _buildDailyView(schedules, isLoading)),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPink,
        onPressed: () => _showScheduleFormBottomSheet(context, _selectedDay),
        child: const Icon(Icons.add, color: Colors.white),
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
        '일정 관리',
        style: TextStyle(
          color: _kText,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  // =========================================================
  // 뷰 모드 토글
  // =========================================================

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        child: Row(
          children: [
            _viewToggleBtn('월별', _ViewMode.monthly),
            _viewToggleBtn('주별', _ViewMode.weekly),
            _viewToggleBtn('일별', _ViewMode.daily),
          ],
        ),
      ),
    );
  }

  Widget _viewToggleBtn(String label, _ViewMode mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchViewMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_kPink, Color(0xFFF472B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _kPink.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xAAFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _switchViewMode(_ViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    final notifier = ref.read(scheduleNotifierProvider.notifier);
    switch (mode) {
      case _ViewMode.monthly:
        notifier.loadSchedules(year: _focusedDay.year, month: _focusedDay.month);
      case _ViewMode.weekly:
        final weekEnd = _weekStart.add(const Duration(days: 6));
        notifier.loadSchedulesForRange(_weekStart, weekEnd);
      case _ViewMode.daily:
        notifier.loadSchedules(year: _selectedDay.year, month: _selectedDay.month);
    }
  }

  // =========================================================
  // 월별 뷰
  // =========================================================

  Widget _buildCalendarCard(List<ScheduleModel> schedules) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGlassBorder, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: TableCalendar<ScheduleModel>(
            locale: 'ko_KR',
            firstDay: DateTime(2020),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) =>
                schedules.where((s) => isSameDay(s.startAt, day)).toList(),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              ref.read(scheduleNotifierProvider.notifier).changeMonth(
                    focusedDay.year,
                    focusedDay.month,
                  );
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 13),
              weekendTextStyle:
                  const TextStyle(color: Color(0xAAFFFFFF), fontSize: 13),
              outsideDaysVisible: false,
              outsideTextStyle:
                  const TextStyle(color: Color(0x44FFFFFF), fontSize: 13),
              todayDecoration: BoxDecoration(
                color: _kPink.withOpacity(0.25),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              todayTextStyle:
                  const TextStyle(color: _kPink, fontWeight: FontWeight.w700),
              selectedDecoration: const BoxDecoration(
                color: _kPink,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              markerDecoration: const BoxDecoration(
                color: _kPink,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 5,
              markerMargin:
                  const EdgeInsets.symmetric(horizontal: 0.5),
              cellMargin: const EdgeInsets.all(4),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: Colors.white),
              headerPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xAAFFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: Color(0xAAFFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                // 카테고리 색상 점 표시 (최대 3개)
                final dots = events.take(3).map((e) {
                  final color = ScheduleModel.categoryColor(e.category);
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList();

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: dots,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 주별 뷰
  // =========================================================

  Widget _buildWeeklyView(List<ScheduleModel> allSchedules) {
    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final selectedDaySchedules = allSchedules
        .where((s) => isSameDay(s.startAt, _selectedDay))
        .toList();
    final isLoading = ref.watch(scheduleNotifierProvider) is ScheduleLoading;

    // 주간 범위 레이블: "3/24 ~ 3/30"
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('M/d', 'ko_KR');
    final weekLabel = '${fmt.format(_weekStart)} ~ ${fmt.format(weekEnd)}';

    return Column(
      children: [
        // 주간 헤더 카드
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGlassBorder, width: 1.5),
          ),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            children: [
              // 주 이동 행
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevWeek,
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Text(
                    weekLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextWeek,
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 7일 타일 행
              Row(
                children: weekDays.map((day) {
                  final isSelected = isSameDay(day, _selectedDay);
                  final isToday = isSameDay(day, DateTime.now());
                  final dayEvents = allSchedules
                      .where((s) => isSameDay(s.startAt, day))
                      .toList();
                  final dayOfWeek = DateFormat('E', 'ko_KR').format(day);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: Column(
                        children: [
                          Text(
                            dayOfWeek,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? _kPink
                                  : const Color(0xAAFFFFFF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kPink
                                  : (isToday
                                      ? _kPink.withOpacity(0.25)
                                      : Colors.transparent),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday ? _kPink : Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 8,
                            child: dayEvents.isNotEmpty
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: dayEvents.take(3).map((e) =>
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 0.5),
                                        decoration: BoxDecoration(
                                          color: ScheduleModel.categoryColor(
                                              e.category),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ).toList(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // 선택된 날 일정 목록
        Expanded(
          child: _buildScheduleList(context, selectedDaySchedules, isLoading),
        ),
      ],
    );
  }

  void _prevWeek() {
    final newWeekStart = _weekStart.subtract(const Duration(days: 7));
    setState(() {
      _weekStart = newWeekStart;
      _selectedDay = newWeekStart;
    });
    final weekEnd = newWeekStart.add(const Duration(days: 6));
    ref
        .read(scheduleNotifierProvider.notifier)
        .loadSchedulesForRange(newWeekStart, weekEnd);
  }

  void _nextWeek() {
    final newWeekStart = _weekStart.add(const Duration(days: 7));
    setState(() {
      _weekStart = newWeekStart;
      _selectedDay = newWeekStart;
    });
    final weekEnd = newWeekStart.add(const Duration(days: 6));
    ref
        .read(scheduleNotifierProvider.notifier)
        .loadSchedulesForRange(newWeekStart, weekEnd);
  }

  // =========================================================
  // 일별 뷰
  // =========================================================

  Widget _buildDailyView(List<ScheduleModel> allSchedules, bool isLoading) {
    final daySchedules = allSchedules
        .where((s) => isSameDay(s.startAt, _selectedDay))
        .toList()
      ..sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        return a.startAt.compareTo(b.startAt);
      });

    final allDayItems = daySchedules.where((s) => s.isAllDay).toList();
    final timedItems = daySchedules.where((s) => !s.isAllDay).toList();

    return Column(
      children: [
        // 날짜 네비게이션
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Container(
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGlassBorder, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevDay,
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Text(
                  DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDay),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _nextDay,
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 일정 목록
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _kPink,
                    strokeWidth: 2,
                  ),
                )
              : daySchedules.isEmpty
                  ? _buildEmptyState()
                  : Builder(
                      builder: (listCtx) {
                        final messenger = ScaffoldMessenger.of(listCtx);
                        return ListView(
                          padding:
                              const EdgeInsets.fromLTRB(12, 8, 12, 80),
                          children: [
                            if (allDayItems.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '종일',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _kTextMute,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...allDayItems.map((s) => _ScheduleItemCard(
                                    schedule: s,
                                    onEdit: () =>
                                        _showScheduleFormBottomSheet(
                                            context, s.startAt,
                                            schedule: s),
                                    onDelete: () async {
                                      final ok = await ref
                                          .read(scheduleNotifierProvider
                                              .notifier)
                                          .deleteSchedule(s.oid);
                                      if (!ok && mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('일정 삭제에 실패했습니다.'),
                                            backgroundColor:
                                                Color(0xFF2A2A3E),
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  )),
                              const SizedBox(height: 8),
                            ],
                            ...timedItems.map((s) {
                              final timeLabel =
                                  DateFormat('HH:mm', 'ko_KR').format(s.startAt);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 4, left: 2),
                                    child: Text(
                                      timeLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _kTextMute,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _ScheduleItemCard(
                                    schedule: s,
                                    onEdit: () =>
                                        _showScheduleFormBottomSheet(
                                            context, s.startAt,
                                            schedule: s),
                                    onDelete: () async {
                                      final ok = await ref
                                          .read(scheduleNotifierProvider
                                              .notifier)
                                          .deleteSchedule(s.oid);
                                      if (!ok && mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('일정 삭제에 실패했습니다.'),
                                            backgroundColor:
                                                Color(0xFF2A2A3E),
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              );
                            }),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _prevDay() {
    final prev = _selectedDay.subtract(const Duration(days: 1));
    final needsReload =
        prev.year != _selectedDay.year || prev.month != _selectedDay.month;
    setState(() {
      _selectedDay = prev;
      _weekStart = _getWeekStart(prev);
    });
    if (needsReload) {
      ref
          .read(scheduleNotifierProvider.notifier)
          .loadSchedules(year: prev.year, month: prev.month);
    }
  }

  void _nextDay() {
    final next = _selectedDay.add(const Duration(days: 1));
    final needsReload =
        next.year != _selectedDay.year || next.month != _selectedDay.month;
    setState(() {
      _selectedDay = next;
      _weekStart = _getWeekStart(next);
    });
    if (needsReload) {
      ref
          .read(scheduleNotifierProvider.notifier)
          .loadSchedules(year: next.year, month: next.month);
    }
  }

  // =========================================================
  // 공통 일정 목록 (월별/주별/일별 공유)
  // =========================================================

  Widget _buildScheduleList(
    BuildContext context,
    List<ScheduleModel> schedules,
    bool isLoading,
  ) {
    final dateLabel = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${schedules.length}개',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _kPink,
                    strokeWidth: 2,
                  ),
                )
              : schedules.isEmpty
                  ? _buildEmptyState()
                  : Builder(
                      builder: (listCtx) {
                        final messenger =
                            ScaffoldMessenger.of(listCtx);
                        return ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: schedules.length,
                          itemBuilder: (_, index) {
                            final s = schedules[index];
                            return _ScheduleItemCard(
                              schedule: s,
                              onEdit: () =>
                                  _showScheduleFormBottomSheet(
                                context,
                                s.startAt,
                                schedule: s,
                              ),
                              onDelete: () async {
                                final ok = await ref
                                    .read(scheduleNotifierProvider
                                        .notifier)
                                    .deleteSchedule(s.oid);
                                if (!ok && mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('일정 삭제에 실패했습니다.'),
                                      backgroundColor:
                                          Color(0xFF2A2A3E),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: _kPink.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            '이 날의 일정이 없습니다.',
            style: TextStyle(fontSize: 14, color: _kTextSub),
          ),
          const SizedBox(height: 4),
          const Text(
            '+ 버튼으로 일정을 추가해보세요.',
            style: TextStyle(fontSize: 12, color: _kTextMute),
          ),
        ],
      ),
    );
  }

  void _showScheduleFormBottomSheet(
      BuildContext context, DateTime initialDate,
      {ScheduleModel? schedule}) {
    // async gap 이전에 ScaffoldMessenger를 캡처한다.
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = schedule != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormBottomSheet(
        scaffoldContext: context,
        initialDate: schedule?.startAt ?? initialDate,
        initialSchedule: schedule,
        onSaved: (title, category, isAllDay, startAt, endAt, location,
            alertBefore, description) async {
          if (isEditing) {
            final ok = await ref
                .read(scheduleNotifierProvider.notifier)
                .updateSchedule(
                  schedule.oid,
                  title: title,
                  category: category,
                  isAllDay: isAllDay,
                  startAt: startAt,
                  endAt: endAt,
                  location: location.isNotEmpty ? location : null,
                  alertBefore:
                      alertBefore.isNotEmpty ? alertBefore : null,
                  description:
                      description.isNotEmpty ? description : null,
                );
            if (!mounted) return;
            if (ok) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('일정이 수정되었습니다.'),
                  backgroundColor: Color(0xFF2A2A3E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            final ok = await ref
                .read(scheduleNotifierProvider.notifier)
                .createSchedule(
                  title: title,
                  category: category,
                  startAt: startAt,
                  description:
                      description.isNotEmpty ? description : null,
                  isAllDay: isAllDay,
                  endAt: endAt,
                  location: location.isNotEmpty ? location : null,
                  alertBefore:
                      alertBefore.isNotEmpty ? alertBefore : null,
                );
            if (!mounted) return;
            if (ok) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('일정이 추가되었습니다.'),
                  backgroundColor: Color(0xFF2A2A3E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 일정 카드 (Dismissible 스와이프 삭제)
// ---------------------------------------------------------------------------

class _ScheduleItemCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ScheduleItemCard({
    required this.schedule,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = ScheduleModel.categoryColor(schedule.category);
    final timeLabel = _buildTimeLabel();

    return Dismissible(
      key: Key('schedule-${schedule.oid}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('일정 삭제',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            content: Text(
              '"${schedule.title}" 일정을 삭제하시겠습니까?',
              style: const TextStyle(
                  color: Color(0xAAFFFFFF), fontSize: 14),
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
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _kGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGlassBorder, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 카테고리 색상 바 (gradient)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [catColor, catColor.withOpacity(0.5)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kText,
                              ),
                            ),
                            if (timeLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextSub,
                                ),
                              ),
                            ],
                            if (schedule.location != null &&
                                schedule.location!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 11, color: _kTextMute),
                                  const SizedBox(width: 2),
                                  Text(
                                    schedule.location!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _kTextMute,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 카테고리 배지 + 수정 힌트
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              schedule.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: catColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.edit_outlined,
                            size: 12,
                            color: _kTextMute,
                          ),
                        ],
                      ),
                    ],
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

  String _buildTimeLabel() {
    if (schedule.isAllDay) return '종일';
    final fmt = DateFormat('HH:mm', 'ko_KR');
    final start = fmt.format(schedule.startAt);
    if (schedule.endAt != null) {
      return '$start ~ ${fmt.format(schedule.endAt!)}';
    }
    return start;
  }
}

// ---------------------------------------------------------------------------
// 일정 추가 BottomSheet
// ---------------------------------------------------------------------------

typedef _OnScheduleSaved = Future<void> Function(
  String title,
  String category,
  bool isAllDay,
  DateTime startAt,
  DateTime? endAt,
  String location,
  String alertBefore,
  String description,
);

class _ScheduleFormBottomSheet extends StatefulWidget {
  final BuildContext scaffoldContext;
  final DateTime initialDate;
  final ScheduleModel? initialSchedule;
  final _OnScheduleSaved onSaved;

  const _ScheduleFormBottomSheet({
    required this.scaffoldContext,
    required this.initialDate,
    this.initialSchedule,
    required this.onSaved,
  });

  @override
  State<_ScheduleFormBottomSheet> createState() =>
      _ScheduleFormBottomSheetState();
}

class _ScheduleFormBottomSheetState
    extends State<_ScheduleFormBottomSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = '기타';
  bool _isAllDay = false;
  late DateTime _startAt;
  DateTime? _endAt;
  String _alertBefore = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSchedule;
    if (s != null) {
      _titleCtrl.text = s.title;
      _locationCtrl.text = s.location ?? '';
      _descCtrl.text = s.description ?? '';
      _category = s.category;
      _isAllDay = s.isAllDay;
      _startAt = s.startAt;
      _endAt = s.endAt;
      _alertBefore = s.alertBefore ?? '';
    } else {
      _startAt = widget.initialDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
            // 제목
            Text(
              widget.initialSchedule != null ? '일정 수정' : '일정 추가',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // 일정 제목
            _buildLabel('일정 제목 *'),
            const SizedBox(height: 6),
            _buildTextField(_titleCtrl, '제목을 입력하세요'),
            const SizedBox(height: 14),
            // 카테고리
            _buildLabel('카테고리'),
            const SizedBox(height: 6),
            _buildCategoryChips(),
            const SizedBox(height: 14),
            // 종일 여부
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '종일',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _isAllDay,
                  activeColor: _kPink,
                  onChanged: (v) => setState(() => _isAllDay = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 시작 일시
            _buildLabel('시작'),
            const SizedBox(height: 6),
            _buildDateTimePicker(
              date: _startAt,
              showTime: !_isAllDay,
              onDateSelected: (d) => setState(() => _startAt = d),
              onTimeSelected: (t) => setState(() {
                _startAt = DateTime(
                  _startAt.year,
                  _startAt.month,
                  _startAt.day,
                  t.hour,
                  t.minute,
                );
              }),
            ),
            const SizedBox(height: 14),
            // 종료 일시 (선택)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '종료 일시 (선택)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xAAFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_endAt != null)
                  GestureDetector(
                    onTap: () => setState(() => _endAt = null),
                    child: const Text(
                      '제거',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (_endAt != null)
              _buildDateTimePicker(
                date: _endAt!,
                showTime: !_isAllDay,
                onDateSelected: (d) => setState(() => _endAt = d),
                onTimeSelected: (t) => setState(() {
                  _endAt = DateTime(
                    _endAt!.year,
                    _endAt!.month,
                    _endAt!.day,
                    t.hour,
                    t.minute,
                  );
                }),
              )
            else
              GestureDetector(
                onTap: () => setState(() => _endAt = _startAt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0x33FFFFFF), width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Color(0xAAFFFFFF)),
                      SizedBox(width: 6),
                      Text(
                        '종료 일시 추가',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xAAFFFFFF)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            // 장소
            _buildLabel('장소 (선택)'),
            const SizedBox(height: 6),
            _buildTextField(_locationCtrl, '장소를 입력하세요'),
            const SizedBox(height: 14),
            // 알림
            _buildLabel('알림'),
            const SizedBox(height: 6),
            _buildAlertDropdown(),
            const SizedBox(height: 14),
            // 메모
            _buildLabel('메모 (선택)'),
            const SizedBox(height: 6),
            _buildTextField(_descCtrl, '메모를 입력하세요', maxLines: 3),
            const SizedBox(height: 24),
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    : Text(
                        widget.initialSchedule != null ? '수정' : '저장',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPink, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: ScheduleModel.categories.map((cat) {
        final isSelected = _category == cat;
        final color = ScheduleModel.categoryColor(cat);
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : const Color(0x33FFFFFF),
                width: 1.5,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : const Color(0xAAFFFFFF),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimePicker({
    required DateTime date,
    required bool showTime,
    required ValueChanged<DateTime> onDateSelected,
    required ValueChanged<TimeOfDay> onTimeSelected,
  }) {
    final dateFmt = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final timeFmt = DateFormat('HH:mm', 'ko_KR');

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
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
              if (picked != null) onDateSelected(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0x33FFFFFF), width: 1),
              ),
              child: Text(
                dateFmt.format(date),
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
        if (showTime) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(date),
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
              if (picked != null) onTimeSelected(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0x33FFFFFF), width: 1),
              ),
              child: Text(
                timeFmt.format(date),
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertDropdown() {
    const options = ScheduleModel.alertOptions;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _alertBefore,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E2E),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xAAFFFFFF)),
          items: options.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _alertBefore = v ?? ''),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
        const SnackBar(
          content: Text('일정 제목을 입력해주세요.'),
          backgroundColor: Color(0xFF2A2A3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSaved(
        title,
        _category,
        _isAllDay,
        _startAt,
        _endAt,
        _locationCtrl.text.trim(),
        _alertBefore,
        _descCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
