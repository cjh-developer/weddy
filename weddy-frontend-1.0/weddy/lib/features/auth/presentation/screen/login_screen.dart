import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Color Constants — Dark Glassmorphism
// ---------------------------------------------------------------------------

const _kPink = Color(0xFFD4748A);           // 채도 낮춘 로즈
const _kDarkPink = Color(0xFFB85C72);
const _kBgDark1 = Color(0xFF1A1A19);
const _kBgDark2 = Color(0xFF111110);
// Glass layers
const _kGlass = Color(0x14FFFFFF);          // white 8%
const _kGlassBorder = Color(0x28FFFFFF);    // white 16%
const _kInputFill = Color(0x14FFFFFF);
const _kInputFillFocus = Color(0x1FFFFFFF);
// Text
const _kTextMute = Color(0x66FFFFFF);       // white 40%
// Social
const _kNaverGreen = Color(0xFF03C75A);
const _kKakaoYellow = Color(0xFFFEE500);

// ---------------------------------------------------------------------------
// LoginScreen
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).login(
          _userIdController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go(AppRoutes.home);
        return;
      }
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

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
          // ── 배경 핑크 앰비언트 글로우 ─────────────────────────────
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kPink.withOpacity(0.13),
                    _kPink.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kDarkPink.withOpacity(0.10),
                    _kDarkPink.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // ── 콘텐츠 ───────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kGlass,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _kGlassBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 32,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── 로고 영역 ────────────────────────────
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        color: _kPink,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _kPink.withOpacity(0.20),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(Icons.favorite,
                                              color: Colors.white, size: 38),
                                          Icon(Icons.favorite,
                                              color: Colors.white.withOpacity(0.35),
                                              size: 28),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'WEDDLY',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 5,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '당신의 완벽한 결혼 준비 파트너',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.white.withOpacity(0.50),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── 아이디 ──────────────────────────────
                              _AnimatedField(
                                controller: _userIdController,
                                enabled: !isLoading,
                                hintText: '아이디',
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                autofillHints: const [AutofillHints.username],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return '아이디를 입력해주세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── 비밀번호 ────────────────────────────
                              _AnimatedField(
                                controller: _passwordController,
                                enabled: !isLoading,
                                hintText: '비밀번호',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: _handleLogin,
                                suffixIcon: _VisibilityButton(
                                  obscure: _obscurePassword,
                                  onToggle: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return '비밀번호를 입력해주세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ── 로그인 버튼 ─────────────────────────
                              _PinkButton(
                                label: '로그인',
                                isLoading: isLoading,
                                onPressed: _handleLogin,
                              ),
                              const SizedBox(height: 14),

                              // ── 회원가입 링크 ────────────────────────
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '아직 계정이 없으신가요?',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.60)),
                                    ),
                                    const SizedBox(width: 5),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: isLoading
                                            ? null
                                            : () => context.go(AppRoutes.signUp),
                                        child: Text(
                                          '회원가입',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isLoading
                                                ? _kTextMute
                                                : _kPink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── 소셜 구분선 ─────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.20)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      '소셜 로그인',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.40)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.20)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // ── 소셜 버튼 ───────────────────────────
                              _SocialButton(
                                label: 'Google 로그인',
                                bgColor: Colors.white.withOpacity(0.10),
                                textColor: Colors.white,
                                borderColor: Colors.white.withOpacity(0.22),
                                icon: const _GoogleGLogo(size: 20),
                                onTap: () => _showComingSoon(context),
                              ),
                              const SizedBox(height: 8),
                              _SocialButton(
                                label: 'Naver 로그인',
                                bgColor: _kNaverGreen,
                                textColor: Colors.white,
                                icon: const _NaverN(),
                                onTap: () => _showComingSoon(context),
                              ),
                              const SizedBox(height: 8),
                              _SocialButton(
                                label: 'Kakao 로그인',
                                bgColor: _kKakaoYellow,
                                textColor: const Color(0xFF191919),
                                icon: const _KakaoK(),
                                onTap: () => _showComingSoon(context),
                              ),
                              const SizedBox(height: 32),

                              // ── 푸터 ───────────────────────────────
                              Column(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white.withOpacity(0.30),
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      '이용약관',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '© 2025 CJH. All rights reserved.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.30)),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('소셜 로그인은 준비 중입니다.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedField — FocusNode 기반 포커스 애니메이션 (다크 글래스)
// ---------------------------------------------------------------------------

class _AnimatedField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final VoidCallback? onFieldSubmitted;
  final Widget? suffixIcon;

  const _AnimatedField({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _focused ? 1.012 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: _kPink.withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.40), fontSize: 14),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _focused
                  ? _kPink
                  : Colors.white.withOpacity(0.50),
              size: 20,
            ),
            suffixIcon: widget.suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x33FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0x80EC4899), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            filled: true,
            fillColor: _focused ? _kInputFillFocus : _kInputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: widget.validator,
          onFieldSubmitted:
              widget.onFieldSubmitted != null
                  ? (_) => widget.onFieldSubmitted!()
                  : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// 비밀번호 보이기/숨기기 버튼.
class _VisibilityButton extends StatefulWidget {
  final bool obscure;
  final VoidCallback onToggle;

  const _VisibilityButton({required this.obscure, required this.onToggle});

  @override
  State<_VisibilityButton> createState() => _VisibilityButtonState();
}

class _VisibilityButtonState extends State<_VisibilityButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: IconButton(
        icon: Icon(
          widget.obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _hovered ? _kPink : Colors.white.withOpacity(0.50),
          size: 20,
        ),
        onPressed: widget.onToggle,
      ),
    );
  }
}

/// 핑크 그라디언트 버튼 (강화된 glow).
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
      cursor:
          widget.isLoading ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
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
              borderRadius: BorderRadius.circular(10),
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
                        color: _kPink.withOpacity(_pressed ? 0.10 : 0.22),
                        blurRadius: _pressed ? 4 : 12,
                        offset: Offset(0, _pressed ? 1 : 3),
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

/// 소셜 로그인 버튼.
class _SocialButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            decoration: BoxDecoration(
              color: _hovered
                  ? Color.lerp(widget.bgColor, Colors.white, 0.10)
                  : widget.bgColor,
              borderRadius: BorderRadius.circular(10),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!)
                  : null,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
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
// Google G 로고 (실제 Google 브랜드 색상, CustomPainter)
// ---------------------------------------------------------------------------

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final sw = s.width * 0.155;
    final r = (s.width / 2) - sw / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const d2r = math.pi / 180;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    arc.color = _green;
    canvas.drawArc(rect, 20 * d2r, 30 * d2r, false, arc);

    arc.color = _yellow;
    canvas.drawArc(rect, 50 * d2r, 60 * d2r, false, arc);

    arc.color = _red;
    canvas.drawArc(rect, 110 * d2r, 90 * d2r, false, arc);

    arc.color = _blue;
    canvas.drawArc(rect, 200 * d2r, 140 * d2r, false, arc);

    final bar = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - sw / 2, cx + r + sw / 2, cy + sw / 2),
      bar,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter old) => false;
}

/// Naver "N" 아이콘.
class _NaverN extends StatelessWidget {
  const _NaverN();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Kakao "k" 아이콘.
class _KakaoK extends StatelessWidget {
  const _KakaoK();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF191919).withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'k',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF191919),
          ),
        ),
      ),
    );
  }
}
