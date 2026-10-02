import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class EditAdminProfilePage extends ConsumerStatefulWidget {
  const EditAdminProfilePage({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditAdminProfilePage> createState() =>
      _EditAdminProfilePageState();
}

class _EditAdminProfilePageState extends ConsumerState<EditAdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _isSaving = false;
  bool _firebaseNameUpdated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != widget.profile.firebaseUid) {
      setState(() {
        _error = 'تغيّرت جلسة الحساب. ارجع وسجّل الدخول مجددًا.';
      });
      return;
    }

    final userService = ref.read(userServiceProvider);

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await user.updateDisplayName(_nameController.text.trim());

      _firebaseNameUpdated = true;

      // Refresh the token so backend synchronization receives the new name.
      await user.getIdToken(true);

      await userService.syncUser().timeout(const Duration(seconds: 20));

      if (!mounted) return;

      ref.invalidate(userProfileProvider);

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث اسم المسؤول بنجاح')),
      );

      // Allow PopScope to rebuild before leaving.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _error = _firebaseNameUpdated
            ? 'تم تحديث الاسم في حساب الدخول، لكن تعذر تأكيد '
                  'مزامنته مع السيرفر. اضغط حفظ مجددًا.'
            : 'تعذر تحديث الاسم. تحقق من الاتصال وحاول مجددًا.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: !_isSaving,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('تعديل بيانات المسؤول')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 64,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الملف الشخصي',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        maxLength: 100,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'الاسم المعروض',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';

                          if (name.length < 2 || name.length > 100) {
                            return 'أدخل اسمًا من 2 إلى 100 حرف';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'البريد الإلكتروني',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.profile.email ?? 'غير محدد',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 20),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.shield_outlined),
                      title: Text('الدور'),
                      subtitle: Text('مسؤول المنصة'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: colors.error, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'جارٍ الحفظ...' : 'حفظ التعديلات',
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
}
