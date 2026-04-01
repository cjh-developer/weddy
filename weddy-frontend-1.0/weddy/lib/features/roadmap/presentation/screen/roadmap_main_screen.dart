import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/roadmap/presentation/notifier/roadmap_notifier.dart';
import 'package:weddy/features/roadmap/presentation/screen/roadmap_screen.dart';

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

/// 웨딩 관리 진입 메인 화면.
/// 단계가 없으면 생성 방식 선택 화면, 있으면 RoadmapScreen을 표시한다.
class RoadmapMainScreen extends ConsumerStatefulWidget {
  const RoadmapMainScreen({super.key});

  @override
  ConsumerState<RoadmapMainScreen> createState() => _RoadmapMainScreenState();
}

class _RoadmapMainScreenState extends ConsumerState<RoadmapMainScreen> {
  bool _isCreating = false;
  bool _showCustomRoadmap = false;

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
    final state = ref.watch(roadmapNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: SafeArea(
          child: _buildContent(state),
        ),
      ),
    );
  }

  Widget _buildContent(RoadmapState state) {
    // 로딩 중
    if (state is RoadmapLoading || _isCreating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kPink, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              '로드맵을 준비하고 있어요...',
              style: TextStyle(color: _kTextSub, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // 단계가 있거나 직접 로드맵 선택 → RoadmapScreen 표시
    if ((state is RoadmapLoaded && state.steps.isNotEmpty) || _showCustomRoadmap) {
      return RoadmapScreen(
        showBackButton: true,
        onBack: _showCustomRoadmap ? () => setState(() => _showCustomRoadmap = false) : null,
      );
    }

    // 초기화 상태 또는 빈 상태 → 선택 화면
    return _buildSelectionView();
  }

  Widget _buildSelectionView() {
    return Column(
      children: [
        // AppBar 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  '웨딩 관리',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 48), // 버튼 공간 균형
            ],
          ),
        ),
        // 선택 화면 본문
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _kPink.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 36, color: _kPink),
                ),
                const SizedBox(height: 24),
                const Text(
                  '결혼 준비를 시작해볼까요?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '로드맵 방식을 선택하세요.',
                  style: TextStyle(fontSize: 14, color: _kTextSub),
                ),
                const SizedBox(height: 40),

                // 기본 로드맵 카드
                _OptionCard(
                  icon: Icons.auto_awesome_mosaic,
                  iconColor: _kPink,
                  title: '기본 로드맵으로 시작',
                  subtitle: '결혼 날짜 기준 8단계 자동 생성\n12개월 전 ~ 당일까지 단계별 안내',
                  onTap: _createDefaultRoadmap,
                ),
                const SizedBox(height: 16),

                // 직접 로드맵 카드
                _OptionCard(
                  icon: Icons.edit_note,
                  iconColor: const Color(0xFF60A5FA),
                  title: '직접 로드맵 만들기',
                  subtitle: '원하는 단계를 직접 추가하고\n순서와 내용을 자유롭게 구성',
                  onTap: _createCustomRoadmap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createDefaultRoadmap() async {
    setState(() => _isCreating = true);
    try {
      final ok =
          await ref.read(roadmapNotifierProvider.notifier).initDefaultRoadmap();
      if (!mounted) return;
      if (!ok) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기본 로드맵 생성에 실패했습니다.'),
            backgroundColor: Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // 성공 시: state가 RoadmapLoaded로 변경되면 _buildContent가 RoadmapScreen을 표시
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _createCustomRoadmap() {
    // 직접 로드맵 탭으로 이동 (같은 화면 내 전환 — Riverpod 상태 공유)
    setState(() => _showCustomRoadmap = true);
  }
}

// ---------------------------------------------------------------------------
// 옵션 선택 카드
// ---------------------------------------------------------------------------

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGlassBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: iconColor.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _kTextSub),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: _kTextMute),
          ],
        ),
      ),
    );
  }
}
