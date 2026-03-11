import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/auth/data/model/sign_up_request.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

/// 회원가입 화면.
///
/// - 필수 정보 입력 후 역할(GROOM/BRIDE) 선택하여 회원가입을 진행한다.
/// - 모든 필드는 null-safety 유효성 검사를 포함한다.
/// - [AuthAuthenticated] 전환은 go_router redirect가 자동으로 처리한다.
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

  /// 선택된 역할. null이면 아직 선택하지 않은 상태.
  String? _selectedRole;

  static const List<_RoleOption> _roleOptions = [
    _RoleOption(value: 'GROOM', label: '신랑'),
    _RoleOption(value: 'BRIDE', label: '신부'),
  ];

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
    // validate()는 역할 선택 포함 모든 필드를 검증한다.
    // DropdownButtonFormField의 validator가 _selectedRole == null 케이스를 처리한다.
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 아이디
                TextFormField(
                  controller: _userIdController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.newUsername],
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    hintText: '영문, 숫자 조합',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '아이디를 입력해주세요.';
                    }
                    if (value.trim().length < 4) {
                      return '아이디는 4자 이상 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '8자 이상',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이름
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.name,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: '이름',
                    hintText: '실명을 입력해주세요',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 휴대폰
                TextFormField(
                  controller: _handPhoneController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: '휴대폰 번호',
                    hintText: "'-' 없이 입력",
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '휴대폰 번호를 입력해주세요.';
                    }
                    // 숫자만 허용하는 간단한 검증
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 11) {
                      return '올바른 휴대폰 번호를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이메일
                TextFormField(
                  controller: _emailController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이메일을 입력해주세요.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return '올바른 이메일 형식을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 역할 선택
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: '역할',
                    prefixIcon: Icon(Icons.favorite_outline),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('역할을 선택해주세요'),
                  items: _roleOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return '역할을 선택해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 회원가입 버튼
                FilledButton(
                  onPressed: isLoading ? null : _handleSignUp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '회원가입',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // 로그인으로 돌아가기
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있으신가요?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: const Text('로그인'),
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

/// 역할 선택 옵션 데이터 클래스.
class _RoleOption {
  final String value;
  final String label;

  const _RoleOption({required this.value, required this.label});
}
