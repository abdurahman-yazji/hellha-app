import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_router.dart';
import '../../../profile/data/services/user_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _userService = UserService();

  String? _accountType;
  String? _error;
  String? _pendingName;

  bool _isLoading = false;
  bool _hasAuthenticatedAccount = false;
  bool _continueAsTechnician = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _finishRegistration() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('لم يتم تسجيل الدخول.');
    }

    final name = _pendingName;

    if (name != null) {
      await user.updateDisplayName(name).timeout(const Duration(seconds: 20));
      _pendingName = null;
    }

    await _userService.syncUser().timeout(const Duration(seconds: 20));

    final profile = await _userService.getProfile().timeout(
      const Duration(seconds: 20),
    );

    if (!mounted) return;

    ref.invalidate(userProfileProvider);

    final shouldCompleteTechnicianProfile =
        _continueAsTechnician && profile['role'] == 'user';

    setState(() {
      _isLoading = false;
    });

    context.go(shouldCompleteTechnicianProfile ? '/technician/join' : '/');

    authStateNotifier.endRegistration();
  }

  Future<void> _register({required bool withGoogle}) async {
    if (_isLoading) return;

    if (_accountType == null) {
      setState(() {
        _error = 'اختر نوع الحساب أولًا.';
      });
      return;
    }

    if (!withGoogle && !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    authStateNotifier.beginRegistration();

    try {
      if (withGoogle) {
        final credential = await _authService.signInWithGoogle();

        _hasAuthenticatedAccount = true;

        // Existing Google accounts keep their saved role.
        _continueAsTechnician =
            credential.additionalUserInfo?.isNewUser == true &&
            _accountType == 'technician';
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        _hasAuthenticatedAccount = true;
        _continueAsTechnician = _accountType == 'technician';
        _pendingName = _nameController.text.trim();
      }

      await _finishRegistration();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        if (_hasAuthenticatedAccount) {
          _error =
              'تم إنشاء جلسة الحساب، لكن تعذر إكمال بياناته. '
              'اضغط «إكمال التسجيل» للمحاولة مجددًا.';
        } else {
          switch (error.code) {
            case 'email-already-in-use':
              _error = 'هذا البريد مسجّل بالفعل. استخدم تسجيل الدخول.';
              break;
            case 'invalid-email':
              _error = 'أدخل بريدًا إلكترونيًا صحيحًا.';
              break;
            case 'weak-password':
              _error = 'كلمة المرور ضعيفة.';
              break;
            case 'network-request-failed':
              _error = 'تعذر الاتصال. تحقق من الإنترنت وحاول مجددًا.';
              break;
            default:
              _error = 'تعذر إنشاء الحساب. حاول مجددًا.';
          }
        }
      });
    } catch (_) {
      if (!mounted) return;

      // Authentication can finish even when a client-side timeout occurs.
      if (FirebaseAuth.instance.currentUser != null) {
        _hasAuthenticatedAccount = true;
      }

      setState(() {
        _error = _hasAuthenticatedAccount
            ? 'أنت مسجّل الدخول، لكن لم نتمكن من إكمال بيانات الحساب. '
                  'اضغط «إكمال التسجيل».'
            : 'لم تكتمل عملية التسجيل. إذا أغلقت نافذة Google، '
                  'يمكنك المحاولة مجددًا.';
      });
    } finally {
      if (!_hasAuthenticatedAccount) {
        authStateNotifier.endRegistration();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retryCompletion() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    authStateNotifier.beginRegistration();

    try {
      await _finishRegistration();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'تعذر إكمال بيانات الحساب. تأكد من تشغيل السيرفر '
            'والاتصال بالإنترنت ثم حاول مجددًا.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _returnHome() {
    ref.invalidate(userProfileProvider);
    context.go('/');
    authStateNotifier.endRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canEdit = !_isLoading && !_hasAuthenticatedAccount;

    return PopScope(
      canPop: !_isLoading && !_hasAuthenticatedAccount,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('إنشاء حساب')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'كيف تريد استخدام حلّها؟',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            ChoiceChip(
                              avatar: const Icon(Icons.home_repair_service),
                              label: const Text('أحتاج خدمات صيانة'),
                              selected: _accountType == 'user',
                              onSelected: canEdit
                                  ? (_) {
                                      setState(() {
                                        _accountType = 'user';
                                        _error = null;
                                      });
                                    }
                                  : null,
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.engineering_outlined),
                              label: const Text('أريد العمل كفني'),
                              selected: _accountType == 'technician',
                              onSelected: canEdit
                                  ? (_) {
                                      setState(() {
                                        _accountType = 'technician';
                                        _error = null;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        if (_accountType == 'technician') ...[
                          const SizedBox(height: 12),
                          Text(
                            'بعد إنشاء الحساب ستكمل بياناتك المهنية '
                            'وتخصصاتك وشهاداتك. استقبال الطلبات '
                            'يتطلب توثيق المسؤول.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          enabled: canEdit,
                          decoration: const InputDecoration(labelText: 'الاسم'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'أدخل الاسم';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: canEdit,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty || !email.contains('@')) {
                              return 'أدخل بريدًا إلكترونيًا صحيحًا';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: canEdit,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: canEdit,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'كلمتا المرور غير متطابقتين';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: TextStyle(color: colors.error, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FilledButton(
                          onPressed: _isLoading
                              ? null
                              : _hasAuthenticatedAccount
                              ? _retryCompletion
                              : () => _register(withGoogle: false),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _hasAuthenticatedAccount
                                      ? 'إكمال التسجيل'
                                      : 'إنشاء الحساب بالبريد',
                                ),
                        ),
                        if (!_hasAuthenticatedAccount) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _register(withGoogle: true),
                            icon: const Text(
                              'G',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            label: const Text('المتابعة باستخدام Google'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عند استخدام Google لا تحتاج تعبئة حقول البريد '
                            'وكلمة المرور. الحساب الموجود يحتفظ بدوره الحالي.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => context.go('/login'),
                            child: const Text('لديك حساب؟ تسجيل الدخول'),
                          ),
                        ] else
                          TextButton(
                            onPressed: _isLoading ? null : _returnHome,
                            child: const Text('الانتقال للرئيسية'),
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
    );
  }
}
