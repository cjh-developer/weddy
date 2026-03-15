import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/couple/presentation/notifier/couple_notifier.dart';

// ---------------------------------------------------------------------------
// Dark Glassmorphism 색상 상수
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF0D0D1A);
const _kBg2 = Color(0xFF1B0929);
const _kGlass = Color(0x14FFFFFF);        // white 8%
const _kGlassBorder = Color(0x33FFFFFF);  // white 20%
const _kPink = Color(0xFFEC4899);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);      // white 67%
const _kTextMute = Color(0x66FFFFFF);     // white 40%
const _kUrgent = Color(0xFFEF4444);
const _kThisWeek = Color(0xFFF59E0B);
const _kDone = Color(0xFF10B981);

// 아이콘 특성 색상 (각 기능별 고유 색상)
const _kIconCalendar = Color(0xFF60A5FA); // 파랑 — 일정
const _kIconBudget   = Color(0xFF34D399); // 에메랄드 — 예산
const _kIconStore    = Color(0xFFFBBF24); // 앰버 — 업체
const _kIconGuest    = Color(0xFFA78BFA); // 보라 — 하객
const _kIconHome     = Color(0xFF22D3EE); // 시안 — 가전/혼수
const _kIconPartner  = Color(0xFFF472B6); // 라이트핑크 — 파트너
// 카드 neutral glass (향후 사용 예정)
// const _kCard       = Color(0x0DFFFFFF); // white 5%
// const _kCardBorder = Color(0x1AFFFFFF); // white 10%

// ---------------------------------------------------------------------------
// 유틸
// ---------------------------------------------------------------------------

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('준비 중입니다.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 6) return '새벽';
  if (hour < 12) return '오전';
  if (hour < 18) return '오후';
  return '저녁';
}

String _formatDate(DateTime date) {
  const months = [
    '', '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];
  return '${date.year}년 ${months[date.month]} ${date.day}일';
}

String _dDayText(DateTime weddingDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final wedding =
      DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
  final diff = wedding.difference(today).inDays;
  if (diff == 0) return 'D-DAY';
  if (diff > 0) return 'D-$diff';
  return 'D+${diff.abs()}';
}

// ---------------------------------------------------------------------------
// 체크리스트 목업 데이터 모델
// ---------------------------------------------------------------------------

class _CheckItem {
  final String title;
  final String category;
  final bool done;
  final String deadline;
  final Color categoryColor;
  const _CheckItem({
    required this.title,
    required this.category,
    required this.done,
    required this.deadline,
    required this.categoryColor,
  });
}

const _kCheckItems = [
  _CheckItem(title: '예식장 계약 및 날짜 확정',       category: '예식',   done: true,  deadline: '완료',     categoryColor: _kDone),
  _CheckItem(title: '스튜디오·드레스·메이크업 계약',   category: '스드메', done: false, deadline: '3개월 전', categoryColor: _kIconStore),
  _CheckItem(title: '청첩장 디자인 및 제작',           category: '청첩장', done: false, deadline: '2개월 전', categoryColor: _kIconGuest),
  _CheckItem(title: '신혼여행 항공·숙소 예약',         category: '여행',   done: false, deadline: '3개월 전', categoryColor: _kIconHome),
];

// ---------------------------------------------------------------------------
// 타임라인 목업 데이터 모델
// ---------------------------------------------------------------------------

class _TimelineItem {
  final String period;
  final String title;
  final List<String> tasks;
  final bool isActive;
  final bool isCompleted;
  const _TimelineItem({
    required this.period,
    required this.title,
    required this.tasks,
    this.isActive = false,
    this.isCompleted = false,
  });
}

const _kTimelineItems = [
  _TimelineItem(period: '12개월 전', title: '초기 예약',  tasks: ['예식장 선정·예약', '스드메 업체 계약'], isCompleted: false),
  _TimelineItem(period: '6개월 전',  title: '본격 준비',  tasks: ['청첩장 제작', '신혼여행 계획 수립', '혼수 목록 작성'], isActive: true),
  _TimelineItem(period: '3개월 전',  title: '세부 준비',  tasks: ['가전·혼수 구매', '청첩장 발송', '예식 리허설 일정 잡기']),
  _TimelineItem(period: '1개월 전',  title: '최종 점검',  tasks: ['리허설 진행', '당일 시간표 확인', '하객 좌석 배치']),
  _TimelineItem(period: 'D-DAY',     title: '결혼식 ♥',  tasks: ['행복한 결혼식']),
];

// ---------------------------------------------------------------------------
// 목업 데이터 모델
// ---------------------------------------------------------------------------

class _PopItem {
  final String title;
  final String category;
  final int likes;
  final int comments;
  final String timeAgo;

  const _PopItem({
    required this.title,
    required this.category,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

class _VendorItem {
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final String priceRange;

  const _VendorItem({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.priceRange,
  });
}

// ---------------------------------------------------------------------------
// 업체 목업 데이터 (탭 6개 x 3개)
// ---------------------------------------------------------------------------

const _kVendorData = {
  '스튜디오': [
    _VendorItem(
        name: '시그니처 스튜디오',
        location: '강남',
        rating: 4.9,
        reviewCount: 312,
        priceRange: '150만~'),
    _VendorItem(
        name: '로맨스 사진관',
        location: '홍대',
        rating: 4.8,
        reviewCount: 248,
        priceRange: '120만~'),
    _VendorItem(
        name: '드림 웨딩 스튜디오',
        location: '청담',
        rating: 4.9,
        reviewCount: 186,
        priceRange: '180만~'),
  ],
  '메이크업': [
    _VendorItem(
        name: '화이트 브라이드',
        location: '압구정',
        rating: 4.9,
        reviewCount: 427,
        priceRange: '80만~'),
    _VendorItem(
        name: '글로우 메이크업',
        location: '강남',
        rating: 4.8,
        reviewCount: 351,
        priceRange: '70만~'),
    _VendorItem(
        name: '핑크 뷰티',
        location: '신사',
        rating: 4.8,
        reviewCount: 274,
        priceRange: '65만~'),
  ],
  '드레스': [
    _VendorItem(
        name: '엘레강스 드레스',
        location: '청담',
        rating: 4.9,
        reviewCount: 198,
        priceRange: '200만~'),
    _VendorItem(
        name: '로즈 웨딩',
        location: '강남',
        rating: 4.8,
        reviewCount: 163,
        priceRange: '150만~'),
    _VendorItem(
        name: '퓨어 화이트',
        location: '압구정',
        rating: 4.8,
        reviewCount: 142,
        priceRange: '180만~'),
  ],
  '상견례식당': [
    _VendorItem(
        name: '더 테라스',
        location: '여의도',
        rating: 4.9,
        reviewCount: 512,
        priceRange: '1인 8만~'),
    _VendorItem(
        name: '시그니처 레스토랑',
        location: '강남',
        rating: 4.8,
        reviewCount: 438,
        priceRange: '1인 7만~'),
    _VendorItem(
        name: '가든 파티',
        location: '한남',
        rating: 4.8,
        reviewCount: 361,
        priceRange: '1인 9만~'),
  ],
  '가전추천': [
    _VendorItem(
        name: '삼성 디지털프라자 강남',
        location: '강남',
        rating: 4.8,
        reviewCount: 624,
        priceRange: '패키지 문의'),
    _VendorItem(
        name: 'LG 베스트샵 홍대',
        location: '홍대',
        rating: 4.7,
        reviewCount: 518,
        priceRange: '패키지 문의'),
    _VendorItem(
        name: '롯데하이마트 신촌',
        location: '신촌',
        rating: 4.7,
        reviewCount: 443,
        priceRange: '패키지 문의'),
  ],
  '가구추천': [
    _VendorItem(
        name: '이케아 광명점',
        location: '광명',
        rating: 4.6,
        reviewCount: 1284,
        priceRange: '가격 다양'),
    _VendorItem(
        name: '한샘 플래그십',
        location: '강남',
        rating: 4.8,
        reviewCount: 387,
        priceRange: '패키지 문의'),
    _VendorItem(
        name: '일룸 쇼룸',
        location: '논현',
        rating: 4.7,
        reviewCount: 312,
        priceRange: '패키지 문의'),
  ],
};

const _kVendorTabs = ['스튜디오', '메이크업', '드레스', '상견례식당', '가전추천', '가구추천'];

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;
  int _vendorTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 인증된 상태일 때만 커플 정보 조회 (미인증 시 401 cascade 방지)
      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) return;
      final coupleState = ref.read(coupleNotifierProvider);
      if (coupleState is CoupleInitial) {
        ref.read(coupleNotifierProvider.notifier).loadMyCouple();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final coupleState = ref.watch(coupleNotifierProvider);

    // 커플 에러 시 SnackBar
    ref.listen<CoupleState>(coupleNotifierProvider, (prev, next) {
      if (next is CoupleError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(coupleNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
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
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, user, coupleState),
                      const SizedBox(height: 16),
                      _buildPartnerSection(context, user, coupleState),
                      const SizedBox(height: 12),
                      _buildProgressCard(),
                      const SizedBox(height: 12),
                      _buildMenuGrid(context),
                      const SizedBox(height: 16),
                      _buildChecklistSection(context),
                      const SizedBox(height: 20),
                      _buildTimelineSection(context),
                      const SizedBox(height: 20),
                      _buildVendorSection(context),
                      const SizedBox(height: 20),
                      _buildPopularSection(context),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _GlassBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (i) {
          if (i == 0) {
            setState(() => _bottomNavIndex = 0);
          } else {
            _showComingSoon(context);
          }
        },
      ),
    );
  }

  // ── 상단 헤더 ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, dynamic user, CoupleState coupleState) {
    final name = user?.name ?? '';
    // 커플 weddingDate 우선, 없으면 개인 weddingDate 사용
    final coupleWeddingDate =
        coupleState is CoupleConnected ? coupleState.couple.weddingDate : null;
    final weddingDate = coupleWeddingDate ?? user?.weddingDate as DateTime?;

    // 커플 연결 시 "신랑 ♥ 신부 예비부부님" 서브텍스트
    final String subText;
    if (coupleState is CoupleConnected) {
      final groom = coupleState.couple.groomName;
      final bride = coupleState.couple.brideName ?? '';
      subText = '$groom ♥ $bride 예비부부님 오늘도 알차게 준비해봐요!';
    } else {
      subText = name.isNotEmpty ? '$name님, 오늘도 알차게!' : '오늘도 알차게 준비해볼까요?';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kPink.withOpacity(0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'W',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '좋은 ${_greeting()}에요!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    Text(
                      subText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kGlass,
                shape: BoxShape.circle,
                border: Border.all(color: _kGlassBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _kTextSub,
                size: 20,
              ),
            ),
          ],
        ),
        if (weddingDate != null) ...[
          const SizedBox(height: 12),
          _DDayChip(weddingDate: weddingDate),
        ],
      ],
    );
  }

  // ── 파트너 섹션 (버튼 or 연결 완료 배지) ─────────────────────────────────
  Widget _buildPartnerSection(BuildContext context, dynamic user, CoupleState coupleState) {
    if (coupleState is CoupleConnected) {
      final couple = coupleState.couple;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x1A10B981),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x4D10B981), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0x3310B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: _kDone, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${couple.groomName} ♥ ${couple.brideName ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kDone,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    '예비부부 연결 완료',
                    style: TextStyle(fontSize: 11, color: _kTextSub),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: _kDone, size: 20),
          ],
        ),
      );
    }
    return _PartnerInviteButton(user: user);
  }

  // ── 전체 진행률 카드 (컴팩트) ────────────────────────────────────────────
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGlassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '전체 진행률',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: _kTextSub, size: 14),
                ],
              ),
              Row(
                children: [
                  Text(
                    '0%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kIconCalendar,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '0/28',
                    style: TextStyle(fontSize: 12, color: _kTextSub),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 6,
              backgroundColor: Color(0x3360A5FA),
              valueColor: AlwaysStoppedAnimation<Color>(_kIconCalendar),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                  child: _StatItem(
                      count: '0', label: '마감 임박', color: _kUrgent)),
              Expanded(
                  child: _StatItem(
                      count: '0', label: '이번 주', color: _kThisWeek)),
              Expanded(
                  child: _StatItem(count: '0', label: '완료', color: _kDone)),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3열 그리드 메뉴 ───────────────────────────────────────────────────────
  Widget _buildMenuGrid(BuildContext context) {
    const menus = [
      (icon: Icons.calendar_today, label: '일정'),
      (icon: Icons.account_balance_wallet, label: '예산'),
      (icon: Icons.store, label: '업체'),
      (icon: Icons.people, label: '하객'),
      (icon: Icons.home, label: '가전·혼수'),
    ];
    const menuColors = [
      _kIconCalendar,
      _kIconBudget,
      _kIconStore,
      _kIconGuest,
      _kIconHome,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: menus.length,
      itemBuilder: (context, i) {
        final menu = menus[i];
        final iconColor = menuColors[i];
        final iconBgColor = Color.fromARGB(
          26,
          iconColor.red,
          iconColor.green,
          iconColor.blue,
        );
        return GestureDetector(
          onTap: () => _showComingSoon(context),
          child: Container(
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(menu.icon, color: iconColor, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  menu.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 웨딩 체크리스트 섹션 ──────────────────────────────────────────────────
  Widget _buildChecklistSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.checklist_rounded, color: _kIconCalendar, size: 18),
                SizedBox(width: 6),
                Text(
                  '웨딩 체크리스트',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showComingSoon(context),
              child: const Text(
                '더보기 >',
                style: TextStyle(fontSize: 12, color: _kTextSub),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Column(
            children: _kCheckItems.asMap().entries.map((e) {
              final isLast = e.key == _kCheckItems.length - 1;
              return _ChecklistTile(item: e.value, isLast: isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── 웨딩 타임라인 섹션 ────────────────────────────────────────────────────
  Widget _buildTimelineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.timeline, color: _kIconBudget, size: 18),
            SizedBox(width: 6),
            Text(
              '웨딩 타임라인',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_kTimelineItems.length, (i) {
          final item = _kTimelineItems[i];
          final isLast = i == _kTimelineItems.length - 1;
          return _TimelineTile(item: item, isLast: isLast);
        }),
      ],
    );
  }

  // ── 업체 탭 섹션 ──────────────────────────────────────────────────────────
  Widget _buildVendorSection(BuildContext context) {
    final vendors = _kVendorData[_kVendorTabs[_vendorTabIndex]] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.store_outlined, color: _kPink, size: 18),
            SizedBox(width: 6),
            Text(
              '추천 업체',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 탭 칩 (가로 스크롤)
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kVendorTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final selected = i == _vendorTabIndex;
              return GestureDetector(
                onTap: () => setState(() => _vendorTabIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _kIconStore : _kGlass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _kIconStore
                          : _kGlassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _kVendorTabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _kTextSub,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 업체 카드 리스트
        ...vendors.map((v) => _VendorCard(vendor: v)),
      ],
    );
  }

  // ── 인기글 ────────────────────────────────────────────────────────────────
  Widget _buildPopularSection(BuildContext context) {
    const posts = [
      _PopItem(
        title: '청첩장 - 보지카드에서 했는데 대만족',
        category: '업체추가',
        likes: 9,
        comments: 2,
        timeAgo: '1개월 전',
      ),
      _PopItem(
        title: '포토테이블 사진',
        category: '업체추가',
        likes: 8,
        comments: 2,
        timeAgo: '1개월 전',
      ),
      _PopItem(
        title: '대전 웨딩 토탈 업체 후기',
        category: '자유',
        likes: 8,
        comments: 2,
        timeAgo: '1개월 전',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: _kUrgent, size: 18),
                SizedBox(width: 6),
                Text(
                  '인기글',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showComingSoon(context),
              child: const Text(
                '더보기 >',
                style: TextStyle(fontSize: 12, color: _kTextSub),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          posts.length,
          (i) => _PopularPostTile(rank: i + 1, post: posts[i]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// D-DAY 칩
// ---------------------------------------------------------------------------

class _DDayChip extends StatelessWidget {
  final DateTime weddingDate;

  const _DDayChip({required this.weddingDate});

  @override
  Widget build(BuildContext context) {
    final ddayText = _dDayText(weddingDate);
    final isToday = ddayText == 'D-DAY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday ? _kPink : const Color(0x4D60A5FA),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isToday ? '오늘 결혼식!' : _formatDate(weddingDate),
            style: const TextStyle(
              fontSize: 12,
              color: _kTextMute,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ddayText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isToday ? _kPink : _kText,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 파트너 초대 버튼 (미연결 상태 - 클릭 시 모달 오픈)
// ---------------------------------------------------------------------------

class _PartnerInviteButton extends StatelessWidget {
  final dynamic user;

  const _PartnerInviteButton({this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 다이얼로그 외부의 Scaffold context를 캡처해 모달에 전달
        final scaffoldCtx = context;
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black.withOpacity(0.65),
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (ctx, anim1, anim2, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: anim1, curve: Curves.easeIn),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: _PartnerConnectModal(
                      user: user,
                      scaffoldContext: scaffoldCtx,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x4DF472B6), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x33F472B6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_outline, color: _kIconPartner, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '파트너와 함께 준비하세요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '초대 코드로 동반자를 연결해보세요',
                    style: TextStyle(fontSize: 12, color: _kTextSub),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: _kIconPartner, size: 14),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 파트너 연결 모달
// ---------------------------------------------------------------------------

class _PartnerConnectModal extends ConsumerStatefulWidget {
  final dynamic user;
  /// 다이얼로그 외부 Scaffold의 BuildContext — ScaffoldMessenger 접근용
  final BuildContext scaffoldContext;

  const _PartnerConnectModal({
    this.user,
    required this.scaffoldContext,
  });

  @override
  ConsumerState<_PartnerConnectModal> createState() =>
      _PartnerConnectModalState();
}

class _PartnerConnectModalState extends ConsumerState<_PartnerConnectModal> {
  final _codeController = TextEditingController();
  bool _copied = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final coupleState = ref.watch(coupleNotifierProvider);
    final inviteCode = widget.user?.inviteCode as String?;
    final isConnecting = coupleState is CoupleLoading;

    ref.listen<CoupleState>(coupleNotifierProvider, (prev, next) {
      if (next is CoupleConnected) {
        // pop 먼저 — 이후 context는 무효화되므로 scaffoldContext 사용
        Navigator.of(context).pop();
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          SnackBar(
            content: const Text('파트너 연결이 완료되었습니다!'),
            backgroundColor: _kDone,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                // 타이틀 + 닫기
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0x33EC4899),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: _kPink, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '파트너를 초대하세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Icon(Icons.close, color: _kTextSub, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 내 초대 코드
                const Text(
                  '내 초대 코드',
                  style: TextStyle(fontSize: 12, color: _kTextSub),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x1A10B981),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x4D10B981)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          inviteCode ?? '코드 생성 중...',
                          style: GoogleFonts.robotoMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: inviteCode != null ? _kPink : _kTextSub,
                            letterSpacing: 4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (inviteCode != null)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _copyCode(inviteCode),
                              child: Icon(
                                _copied ? Icons.check : Icons.copy_rounded,
                                color: _copied ? _kDone : _kTextSub,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () => _showComingSoon(widget.scaffoldContext),
                              child: const Icon(
                                Icons.share_outlined,
                                color: _kTextSub,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 동반자 코드 입력
                const Text(
                  '동반자 코드 입력',
                  style: TextStyle(fontSize: 12, color: _kTextSub),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.20)),
                        ),
                        child: TextField(
                          controller: _codeController,
                          enabled: !isConnecting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: '6자리 코드를 입력하세요',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: isConnecting
                          ? null
                          : () {
                              final code = _codeController.text.trim();
                              if (code.isEmpty) return;
                              ref
                                  .read(coupleNotifierProvider.notifier)
                                  .connectCouple(code);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          gradient: isConnecting
                              ? null
                              : const LinearGradient(
                                  colors: [_kPink, Color(0xFFF9A8D4)],
                                ),
                          color: isConnecting ? const Color(0x33FFFFFF) : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isConnecting
                              ? null
                              : [
                                  BoxShadow(
                                    color: _kPink.withOpacity(0.40),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: isConnecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '연동',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 통계 아이템
// ---------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kTextSub,
          ),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// 업체 카드 (Dark Glass 스타일)
// ---------------------------------------------------------------------------

class _VendorCard extends StatelessWidget {
  final _VendorItem vendor;

  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGlassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 업체 아이콘
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x26FBBF24), // 앰버 15%
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_outlined, color: _kIconStore, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: _kTextSub),
                    const SizedBox(width: 2),
                    Text(
                      vendor.location,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSub),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded,
                        size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '${vendor.rating}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${vendor.reviewCount})',
                      style: const TextStyle(
                          fontSize: 10, color: _kTextSub),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x26FBBF24), // 앰버 15%
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vendor.priceRange,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kIconStore,
                  ),
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
// 인기글 타일 (Dark Glass 스타일)
// ---------------------------------------------------------------------------

class _PopularPostTile extends StatelessWidget {
  final int rank;
  final _PopItem post;

  const _PopularPostTile({required this.rank, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGlassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: rank <= 3 ? _kPink : _kTextSub,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x26A78BFA), // 보라 15%
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _kIconGuest,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite_outline,
                        size: 12, color: _kTextSub),
                    const SizedBox(width: 3),
                    Text('${post.likes}',
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSub)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chat_bubble_outline,
                        size: 12, color: _kTextSub),
                    const SizedBox(width: 3),
                    Text('${post.comments}',
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSub)),
                    const Spacer(),
                    Text(post.timeAgo,
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSub)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: _kTextSub, size: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 체크리스트 타일
// ---------------------------------------------------------------------------

class _ChecklistTile extends StatelessWidget {
  final _CheckItem item;
  final bool isLast;

  const _ChecklistTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 체크박스 아이콘
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: item.done
                      ? _kDone.withOpacity(0.15)
                      : const Color(0x14FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.done ? _kDone : const Color(0x33FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: item.done
                    ? const Icon(Icons.check, color: _kDone, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              // 제목
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: item.done ? _kTextSub : _kText,
                    decoration:
                        item.done ? TextDecoration.lineThrough : null,
                    decorationColor: _kTextSub,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 카테고리 배지
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.categoryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 마감
              Text(
                item.deadline,
                style: TextStyle(
                  fontSize: 11,
                  color: item.done ? _kDone : _kTextMute,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.white.withOpacity(0.06),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 타임라인 타일
// ---------------------------------------------------------------------------

class _TimelineTile extends StatelessWidget {
  final _TimelineItem item;
  final bool isLast;

  const _TimelineTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    // 상태에 따른 색상/아이콘
    final Color dotColor;
    final IconData dotIcon;
    if (item.period == 'D-DAY') {
      dotColor = _kPink;
      dotIcon = Icons.favorite;
    } else if (item.isActive) {
      dotColor = _kIconCalendar;
      dotIcon = Icons.radio_button_checked;
    } else if (item.isCompleted) {
      dotColor = _kDone;
      dotIcon = Icons.check_circle;
    } else {
      dotColor = const Color(0x66FFFFFF);
      dotIcon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 왼쪽: 점 + 선
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Icon(dotIcon, color: dotColor, size: 20),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            dotColor.withOpacity(0.5),
                            const Color(0x14FFFFFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 오른쪽: 내용 카드
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? const Color(0x1A60A5FA)
                      : item.period == 'D-DAY'
                          ? const Color(0x1AEC4899)
                          : _kGlass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isActive
                        ? const Color(0x4D60A5FA)
                        : item.period == 'D-DAY'
                            ? const Color(0x4DEC4899)
                            : _kGlassBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: dotColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.period,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: dotColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: item.isActive
                                ? _kIconCalendar
                                : item.period == 'D-DAY'
                                    ? _kPink
                                    : _kText,
                          ),
                        ),
                        if (item.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x4D60A5FA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '진행 중',
                              style: TextStyle(
                                fontSize: 9,
                                color: _kIconCalendar,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...item.tasks.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(
                                    right: 8, top: 2),
                                decoration: BoxDecoration(
                                  color: dotColor.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  task,
                                  style: const TextStyle(
                                      fontSize: 12, color: _kTextSub),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
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
// 하단 네비게이션 (Dark Glass 스타일)
// ---------------------------------------------------------------------------

class _GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xCC0D0D1A), // dark 80%
        border: Border(
          top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFFF472B6),
        unselectedItemColor: Colors.white.withOpacity(0.50),
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: '예산',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}
