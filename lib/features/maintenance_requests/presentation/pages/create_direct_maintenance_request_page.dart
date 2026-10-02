import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/maintenance_request_service.dart';

class CreateDirectMaintenanceRequestPage extends StatefulWidget {
  const CreateDirectMaintenanceRequestPage({
    required this.technician,
    this.initialSpecializationId,
    super.key,
  });

  final Map<String, dynamic> technician;
  final String? initialSpecializationId;

  @override
  State<CreateDirectMaintenanceRequestPage> createState() =>
      _CreateDirectMaintenanceRequestPageState();
}

class _CreateDirectMaintenanceRequestPageState
    extends State<CreateDirectMaintenanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = MaintenanceRequestService();

  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  late final List<Map<String, dynamic>> _specializations;
  String? _specializationId;

  bool _submitting = false;
  bool _uncertainResult = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final raw = widget.technician['specializations'];

    _specializations = raw is List
        ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['id'] != null)
              .toList()
        : [];

    final initialId = widget.initialSpecializationId;

    if (_specializations.any(
      (item) => item['id'].toString() == initialId,
    )) {
      _specializationId = initialId;
    } else if (_specializations.length == 1) {
      _specializationId = _specializations.first['id'].toString();
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _phone.dispose();
    _area.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateLength(
    String? value,
    String label,
    int min,
    int max,
  ) {
    final length = (value ?? '').trim().runes.length;

    if (length < min || length > max) {
      return '$label يجب أن يحتوي بين $min و$max حرف';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_submitting || _uncertainResult) return;
    if (!_formKey.currentState!.validate()) return;

    final technicianId = widget.technician['id']?.toString();

    if (technicianId == null || _specializationId == null) {
      setState(() {
        _error = 'بيانات الفني غير مكتملة. ارجع وابحث مجددًا.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _service.createRequest(
        requestDescription: _description.text,
        specializationId: _specializationId!,
        technicianProfileId: technicianId,
        contactPhone: _phone.text,
        workArea: _area.text,
        addressDetails: _address.text,
        notes: _notes.text,
      );

           if (!mounted) return;

      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();
      router.go('/');

      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب الصيانة للفني بنجاح'),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _uncertainResult = true;
        _error =
            'لم يصل تأكيد من الخادم. افتح طلباتي وتحقق من وجود الطلب '
            'قبل محاولة إنشاء طلب جديد.';
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _uncertainResult = true;
        _error =
            'تعذر تأكيد إرسال الطلب. تحقق من الاتصال وراجع طلباتي '
            'قبل إعادة المحاولة.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
    int lines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        maxLength: max,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (value) => _validateLength(
          value,
          label,
          min,
          max,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final technicianName =
        widget.technician['name']?.toString() ?? 'الفني';

    return PopScope(
      canPop: !_submitting,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('طلب صيانة مباشر'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'طلب صيانة من $technicianName',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'صف المشكلة وحدّد عنوان الصيانة '
                      'ليطّلع الفني على تفاصيل طلبك.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AbsorbPointer(
                      absorbing: _submitting || _uncertainResult,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _specializationId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'التخصص المطلوب',
                            ),
                            items: _specializations.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['id'].toString(),
                                child: Text(
                                  item['name_ar']?.toString() ?? 'تخصص',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _specializationId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'اختر تخصصًا من تخصصات الفني';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _textField(
                            controller: _description,
                            label: 'وصف المشكلة',
                            min: 10,
                            max: 2000,
                            lines: 4,
                            keyboardType: TextInputType.multiline,
                          ),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            maxLength: 30,
                            decoration: const InputDecoration(
                              labelText: 'رقم التواصل',
                            ),
                            validator: (value) {
                              final phone = (value ?? '').trim();

                              if (phone.length < 7 ||
                                  phone.length > 30 ||
                                  !RegExp(r'^[0-9+()\-\s]+$')
                                      .hasMatch(phone)) {
                                return 'أدخل رقم تواصل صحيحًا';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _textField(
                            controller: _area,
                            label: 'منطقة الصيانة',
                            min: 2,
                            max: 150,
                          ),
                          _textField(
                            controller: _address,
                            label: 'العنوان التفصيلي',
                            min: 5,
                            max: 500,
                            lines: 2,
                          ),
                          _textField(
                            controller: _notes,
                            label: 'ملاحظات إضافية — اختياري',
                            min: 0,
                            max: 1000,
                            lines: 2,
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(color: colors.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_uncertainResult)
                      OutlinedButton.icon(
                        onPressed: () {
                          context.go('/maintenance-requests');
                        },
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('فتح طلباتي'),
                      )
                    else
                      FilledButton.icon(
                        onPressed:
                            _submitting || _specializations.isEmpty
                            ? null
                            : _submit,
                        icon: _submitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _submitting
                              ? 'جارٍ إرسال الطلب...'
                              : 'إرسال طلب الصيانة',
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