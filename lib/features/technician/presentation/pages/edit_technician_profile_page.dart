import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/technician_service.dart';
import '../providers/technician_profile_provider.dart';

class EditTechnicianProfilePage extends ConsumerStatefulWidget {
  const EditTechnicianProfilePage({super.key});

  @override
  ConsumerState<EditTechnicianProfilePage> createState() =>
      _EditTechnicianProfilePageState();
}

class _EditTechnicianProfilePageState
    extends ConsumerState<EditTechnicianProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _service = TechnicianService();

  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _areaController = TextEditingController();
  final _yearsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _areaController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await _service.getMyProfile().timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      _phoneController.text = profile['phone']?.toString() ?? '';
      _bioController.text = profile['bio']?.toString() ?? '';
      _areaController.text = profile['work_area']?.toString() ?? '';
      _yearsController.text = profile['years_of_experience']?.toString() ?? '0';

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تحميل الملف المهني';
      });
    }
  }

  String _normalizeNumber(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var normalized = value.trim();

    for (var i = 0; i < 10; i++) {
      normalized = normalized
          .replaceAll(arabic[i], '$i')
          .replaceAll(persian[i], '$i');
    }

    return normalized.replaceAll('٫', '.');
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await _service
          .updateMyProfile(
            phone: _normalizeNumber(_phoneController.text),
            bio: _bioController.text.trim(),
            workArea: _areaController.text.trim(),
            yearsOfExperience: int.parse(
              _normalizeNumber(_yearsController.text),
            ),
            
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      ref.invalidate(technicianProfileProvider);

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ الملف المهني')));

      // Allow PopScope to rebuild after saving finishes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _saveError =
            'تعذر تأكيد الحفظ. إذا انتهت مهلة الانتظار، '
            'قد يكون التحديث وصل إلى الخادم؛ '
            'أعد فتح الملف للتحقق قبل المحاولة مجددًا.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isSaving,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('تعديل الملف المهني')),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        Text(
                          'حدّث معلوماتك لتساعد المستخدمين على اختيار الفني المناسب.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final phone = _normalizeNumber(value ?? '');

                            if (phone.length < 7 ||
                                phone.length > 20 ||
                                !RegExp(r'^\+?[0-9\s()-]+$').hasMatch(phone)) {
                              return 'أدخل رقم هاتف صحيحًا من 7 إلى 20 حرفًا';
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
                            labelText: 'نبذة عنك (اختياري)',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if ((value?.trim().length ?? 0) > 1000) {
                              return 'الحد الأقصى 1000 حرف';
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
                            final years = int.tryParse(
                              _normalizeNumber(value ?? ''),
                            );

                            if (years == null || years < 0 || years > 80) {
                              return 'أدخل عددًا صحيحًا من 0 إلى 80';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                       
                        const SizedBox(height: 24),
                        if (_saveError != null) ...[
                          Text(
                            _saveError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
                          ),
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
