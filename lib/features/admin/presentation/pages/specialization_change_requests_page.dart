import 'package:flutter/material.dart';

import '../../data/services/admin_service.dart';

class SpecializationChangeRequestsPage extends StatefulWidget {
  const SpecializationChangeRequestsPage({super.key});

  @override
  State<SpecializationChangeRequestsPage> createState() =>
      _SpecializationChangeRequestsPageState();
}

class _SpecializationChangeRequestsPageState
    extends State<SpecializationChangeRequestsPage> {
  final _service = AdminService();

  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _processing = false;
  bool _needsRefresh = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_processing) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await _service.getPendingSpecializationChanges();

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _loading = false;
        _needsRefresh = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'تعذر تحميل طلبات تعديل التخصصات';
      });
    }
  }

  String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<void> _review(
    Map<String, dynamic> request, {
    required bool approved,
  }) async {
    if (_processing || _needsRefresh) return;

    setState(() {
      _processing = true;
    });

    try {
      final note = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final formKey = GlobalKey<FormState>();
          var reviewNote = '';

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                approved ? 'اعتماد التخصصات؟' : 'رفض طلب التعديل؟',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approved
                            ? 'ستُستبدل تخصصات الفني الحالية '
                                'بالقائمة المقترحة.'
                            : 'ستبقى تخصصات الفني الحالية كما هي.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظة للمراجعة (اختياري)',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (value) {
                          reviewNote = value;
                        },
                        validator: (value) {
                          if ((value?.trim().runes.length ?? 0) > 1000) {
                            return 'الحد الأقصى 1000 حرف';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(dialogContext).pop(reviewNote.trim());
                  },
                  child: Text(
                    approved ? 'تأكيد الموافقة' : 'تأكيد الرفض',
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || note == null) return;

      final requestId = request['id'].toString();

      await _service.reviewSpecializationChange(
        requestId: requestId,
        approved: approved,
        reviewNote: note,
      );

      if (!mounted) return;

      setState(() {
        _requests.removeWhere(
          (item) => item['id'].toString() == requestId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'تم اعتماد التخصصات الجديدة'
                : 'تم رفض طلب تعديل التخصصات',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      // قد يكون القرار حُفظ رغم انقطاع الاتصال.
      // نطلب تحديث القائمة قبل السماح بقرار آخر.
      setState(() {
        _needsRefresh = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : 'تعذر تأكيد حفظ القرار. حدّث القائمة للتحقق.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Widget _specializations(dynamic value, String emptyMessage) {
    final items = value is List ? value : const [];

    if (items.isEmpty) {
      return Text(emptyMessage);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.whereType<Map>().map((item) {
        final name = _text(item['name_ar'], 'تخصص');
        final inactive = item['is_active'] == false;

        return Chip(
          avatar: Icon(
            inactive
                ? Icons.block_rounded
                : Icons.handyman_outlined,
            size: 18,
          ),
          label: Text(inactive ? '$name — غير متاح' : name),
        );
      }).toList(),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(request['technician_name'], 'فني بدون اسم'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'طلب رقم ${request['id']} • '
            '${_text(request['work_area'], 'المنطقة غير محددة')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'التخصصات الحالية',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _specializations(
            request['current_specializations'],
            'لا توجد تخصصات معتمدة حاليًا',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Text(
            'التخصصات المقترحة',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _specializations(
            request['requested_specializations'],
            'لا توجد تخصصات مقترحة',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _processing || _needsRefresh
                      ? null
                      : () => _review(request, approved: true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('موافقة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing || _needsRefresh
                      ? null
                      : () => _review(request, approved: false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('رفض'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('طلبات تعديل التخصصات'),
            actions: [
              IconButton(
                onPressed: _loading || _processing ? null : _load,
                tooltip: 'تحديث القائمة',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_processing) ...[
                              const LinearProgressIndicator(),
                              const SizedBox(height: 16),
                            ],
                            if (_needsRefresh) ...[
                              const Text(
                                'حدّث القائمة للتحقق من حالة الطلبات '
                                'قبل اتخاذ قرار آخر.',
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _processing ? null : _load,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('تحديث القائمة'),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_requests.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.fact_check_outlined,
                                      size: 56,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'لا توجد طلبات تعديل قيد المراجعة',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._requests.map(_requestCard),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}