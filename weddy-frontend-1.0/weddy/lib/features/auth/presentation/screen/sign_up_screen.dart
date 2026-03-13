import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/auth/data/model/sign_up_request.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Color Constants
// ---------------------------------------------------------------------------

const _kPink = Color(0xFFEC4899);
const _kDarkPink = Color(0xFFDB2777);
const _kLightPink = Color(0xFFFCE7F3);
const _kBg = Color(0xFFFDF2F8);
const _kBorder = Color(0xFFE5E7EB);
// 회원가입 버튼 (연한 검은색 계열)
const _kDark = Color(0xFF374151);
const _kDarkHover = Color(0xFF1F2937);

// ---------------------------------------------------------------------------
// SignUpScreen
// ---------------------------------------------------------------------------

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _handPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedRole;
  bool _roleError = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _handPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() => _roleError = _selectedRole == null);
    if (!(_formKey.currentState?.validate() ?? false) || _selectedRole == null) return;

    final request = SignUpRequest(
      userId: _userIdController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      handPhone: _handPhoneController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole!,
    );

    await ref.read(authNotifierProvider.notifier).signup(request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous is AuthLoading && next is AuthUnauthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('회원가입이 완료되었습니다. 로그인해 주세요.'),
              ],
            ),
            backgroundColor: _kDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go(AppRoutes.login);
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
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 32,
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
                      // ── 로고 영역 ──────────────────────────────────────
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
                                    color: _kPink.withOpacity(0.38),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.white, size: 38),
                                  Icon(Icons.favorite, color: _kLightPink, size: 28),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'WEDDY',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: 5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '당신의 완벽한 결혼 준비 파트너',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[500],
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── 아이디 ─────────────────────────────────────────
                      _AnimatedField(
                        controller: _userIdController,
                        enabled: !isLoading,
                        hintText: '아이디',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        autofillHints: const [AutofillHints.newUsername],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '아이디를 입력해주세요.';
                          if (v.trim().length < 4) return '4자 이상 입력해주세요.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── 비밀번호 ───────────────────────────────────────
                      _AnimatedField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        hintText: '비밀번호',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        suffixIcon: _VisibilityButton(
                          obscure: _obscurePassword,
                          onToggle: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
                          if (v.length < 8) return '8자 이상 입력해주세요.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── 이름 ───────────────────────────────────────────
                      _AnimatedField(
                        controller: _nameController,
                        enabled: !isLoading,
                        hintText: '이름',
                        prefixIcon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '이름을 입력해주세요.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── 휴대폰 번호 ────────────────────────────────────
                      _AnimatedField(
                        controller: _handPhoneController,
                        enabled: !isLoading,
                        hintText: "휴대폰 번호 ('-' 없이 입력)",
                        prefixIcon: Icons.phone_outlined,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '휴대폰 번호를 입력해주세요.';
                          final d = v.replaceAll(RegExp(r'\D'), '');
                          if (d.length < 10 || d.length > 11) return '올바른 번호를 입력해주세요.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── 이메일 ─────────────────────────────────────────
                      _AnimatedField(
                        controller: _emailController,
                        enabled: !isLoading,
                        hintText: '이메일',
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onFieldSubmitted: _handleSignUp,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요.';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return '올바른 이메일 형식을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── 역할 선택 ──────────────────────────────────────
                      _RoleSelector(
                        selectedRole: _selectedRole,
                        isDisabled: isLoading,
                        hasError: _roleError,
                        onSelect: (role) => setState(() {
                          _selectedRole = role;
                          _roleError = false;
                        }),
                      ),
                      const SizedBox(height: 28),

                      // ── 회원가입 버튼 (연한 검은색) ─────────────────────
                      _DarkButton(
                        label: '회원가입',
                        isLoading: isLoading,
                        onPressed: _handleSignUp,
                      ),
                      const SizedBox(height: 14),

                      // ── 로그인 링크 ────────────────────────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '이미 계정이 있으신가요?',
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 5),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: isLoading ? null : () => context.go(AppRoutes.login),
                                child: Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isLoading ? Colors.grey[400] : _kPink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 푸터 ──────────────────────────────────────────
                      Column(
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[400],
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '이용약관',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© 2025 CJH. All rights reserved.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedField — FocusNode 기반 포커스 애니메이션
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
                    color: _kPink.withOpacity(0.20),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _focused ? _kPink : Colors.grey[400],
              size: 20,
            ),
            suffixIcon: widget.suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPink, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            filled: true,
            fillColor: _focused ? Colors.white : const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: widget.validator,
          onFieldSubmitted:
              widget.onFieldSubmitted != null ? (_) => widget.onFieldSubmitted!() : null,
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
          widget.obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: _hovered ? _kDarkPink : Colors.grey[400],
          size: 20,
        ),
        onPressed: widget.onToggle,
      ),
    );
  }
}

/// 신랑/신부 역할 선택 위젯.
class _RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final bool isDisabled;
  final bool hasError;
  final ValueChanged<String> onSelect;

  const _RoleSelector({
    required this.selectedRole,
    required this.isDisabled,
    required this.hasError,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '역할 선택',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                label: '신랑',
                emoji: '🤵',
                isSelected: selectedRole == 'GROOM',
                isDisabled: isDisabled,
                onTap: () => onSelect('GROOM'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleChip(
                label: '신부',
                emoji: '👰',
                isSelected: selectedRole == 'BRIDE',
                isDisabled: isDisabled,
                onTap: () => onSelect('BRIDE'),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '역할을 선택해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.red[700]),
            ),
          ),
      ],
    );
  }
}

/// 소형 가로 역할 칩 (핑크 선택 색상, hover + press 효과).
class _RoleChip extends StatefulWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_RoleChip> createState() => _RoleChipState();
}

class _RoleChipState extends State<_RoleChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final bgColor = isSelected
        ? _kLightPink
        : _hovered
            ? const Color(0xFFFDF2F8)
            : Colors.white;
    final borderColor = isSelected
        ? _kPink
        : _hovered
            ? const Color(0xFFF9A8D4)
            : _kBorder;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDisabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: widget.isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isDisabled) setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kPink.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                if (isSelected) ...[
                  const Icon(Icons.check, color: _kPink, size: 12),
                  const SizedBox(width: 3),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _kDarkPink : Colors.grey[600],
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

/// 회원가입 버튼 — 연한 검은색(다크 그레이) 솔리드 버튼.
class _DarkButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _DarkButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_DarkButton> createState() => _DarkButtonState();
}

class _DarkButtonState extends State<_DarkButton> {
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
      cursor: widget.isLoading ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
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
              color: widget.isLoading
                  ? Colors.grey[400]
                  : _hovered
                      ? _kDarkHover
                      : _kDark,
              boxShadow: widget.isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(_pressed ? 0.10 : 0.18),
                        blurRadius: _pressed ? 4 : 10,
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
