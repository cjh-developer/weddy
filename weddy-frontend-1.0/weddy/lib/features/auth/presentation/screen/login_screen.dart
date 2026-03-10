import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

/// 로그인 화면.
///
/// - 아이디/비밀번호 입력 후 로그인 버튼으로 [AuthNotifier.login]을 호출한다.
/// - [AuthError] 상태 전환 시 SnackBar로 에러 메시지를 표시한다.
/// - [AuthAuthenticated] 전환은 go_router의 redirect가 자동으로 처리한다.
/// - 로딩 중 입력 필드와 버튼을 비활성화하여 중복 제출을 방지한다.
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
    // 에러 상태 전환 시 SnackBar를 표시하고 상태를 리셋한다.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 에러 메시지 표시 후 Unauthenticated로 리셋하여 재시도 가능하게 한다.
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 영역
                  const _WeddyLogo(),
                  const SizedBox(height: 48),

                  // 아이디 입력
                  TextFormField(
                    controller: _userIdController,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      hintText: '아이디를 입력해주세요',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '아이디를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력해주세요',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outline
                              : Icons.visibility_off_outline,
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 로그인 버튼
                  FilledButton(
                    onPressed: isLoading ? null : _handleLogin,
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
                            '로그인',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 회원가입 이동 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go(AppRoutes.signUp),
                        child: const Text('회원가입'),
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
}

/// Weddy 로고 위젯 (임시 텍스트 로고).
class _WeddyLogo extends StatelessWidget {
  const _WeddyLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.favorite,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Weddy',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '우리의 특별한 날을 함께해요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
