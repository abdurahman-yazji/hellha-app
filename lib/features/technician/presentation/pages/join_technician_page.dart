import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/services/technician_service.dart';

class JoinTechnicianPage extends ConsumerStatefulWidget {
  const JoinTechnicianPage({super.key});

  @override
  ConsumerState<JoinTechnicianPage> createState() => _JoinTechnicianPageState();
}

class _JoinTechnicianPageState extends ConsumerState<JoinTechnicianPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = TechnicianService();

  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _yearsController = TextEditingController(text: '0');
  final _bioController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _areaController.dispose();
    _yearsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('التحويل إلى حساب فني'),
              content: const Text(
                'ستتحول واجهة حسابك إلى واجهة الفني، '
                'ولن تتوفر خدمات حساب المستخدم بهذا الدور.\n\n'
                'بعد إنشاء الملف، أضف تخصصاتك وشهاداتك. '
                'استقبال الطلبات يتطلب توثيق المسؤول '
                'ثم تفعيل التوفر من حسابك.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('تراجع'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('إنشاء حساب الفني'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || confirmed != true) return;

      await _service.createMyProfile(
        phone: _phoneController.text,
        workArea: _areaController.text,
        yearsOfExperience: int.parse(_yearsController.text.trim()),
        bio: _bioController.text,
      );

      if (!mounted) return;

      ref.invalidate(userProfileProvider);

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء ملف الفني. أكمل التخصصات والشهادات.'),
        ),
      );

      context.go('/');
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'تعذر تأكيد إنشاء الملف. قد تكون العملية تمت بالفعل. '
            'ارجع للرئيسية وحدّث بيانات الحساب قبل إعادة المحاولة.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
          appBar: AppBar(title: const Text('انضم كفني')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'قدّم خدماتك عبر حلّها',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ابدأ ببياناتك المهنية، ثم أضف تخصصاتك '
                      'وشهاداتك من لوحة الفني ليتمكن المسؤول '
                      'من مراجعة حسابك.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              final phone = value?.trim() ?? '';

                              if (phone.length < 7 ||
                                  phone.length > 20 ||
                                  !RegExp(
                                    r'^\+?[0-9\s()-]+$',
                                  ).hasMatch(phone)) {
                                return 'أدخل رقم هاتف صحيحًا بالأرقام الإنجليزية';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _areaController,
                            enabled: !_isSaving,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'منطقة العمل',
                              hintText: 'مثل: غزة',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: (value) {
                              final area = value?.trim() ?? '';

                              if (area.length < 2 || area.length > 100) {
                                return 'أدخل منطقة العمل من 2 إلى 100 حرف';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _yearsController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سنوات الخبرة',
                              prefixIcon: Icon(Icons.work_outline_rounded),
                            ),
                            validator: (value) {
                              final years = int.tryParse(value?.trim() ?? '');

                              if (years == null || years < 0 || years > 80) {
                                return 'أدخل عددًا صحيحًا من 0 إلى 80';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bioController,
                            enabled: !_isSaving,
                            minLines: 3,
                            maxLines: 5,
                            maxLength: 1000,
                            decoration: const InputDecoration(
                              labelText: 'نبذة عن خبرتك — اختياري',
                              alignLabelWithHint: true,
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: colors.error,
                                height: 1.5,
                              ),
                            ),
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      ref.invalidate(userProfileProvider);
                                      context.go('/');
                                    },
                              child: const Text(
                                'العودة للرئيسية وتحديث الحساب',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.engineering_outlined),
                            label: Text(
                              _isSaving
                                  ? 'جارٍ المعالجة...'
                                  : 'إنشاء ملف الفني',
                            ),
                          ),
                        ],
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
