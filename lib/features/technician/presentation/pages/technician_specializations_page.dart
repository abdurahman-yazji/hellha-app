import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/technician_service.dart';

class TechnicianSpecializationsPage extends StatefulWidget {
  const TechnicianSpecializationsPage({super.key});

  @override
  State<TechnicianSpecializationsPage> createState() =>
      _TechnicianSpecializationsPageState();
}

class _TechnicianSpecializationsPageState
    extends State<TechnicianSpecializationsPage> {
  final _service = TechnicianService();
Map<String, dynamic>? _changeRequest;

bool get _hasPendingRequest =>
    _changeRequest?['status'] == 'pending';

  List<Map<String, dynamic>> _specializations = [];
  bool _isLoading = true;
  bool _isOpeningEditor = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

Future<void> _loadSpecializations() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final results = await Future.wait<Object?>([
      _service.getMySpecializations(),
      _service.getMySpecializationChangeRequest(),
    ]);

    if (!mounted) return;

    setState(() {
      _specializations =
          results[0] as List<Map<String, dynamic>>;
      _changeRequest = results[1] as Map<String, dynamic>?;
      _isLoading = false;
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _error = 'تعذر تحميل التخصصات وحالة طلب المراجعة';
    });
  }
}

  Future<void> _openEditor() async {
    if (_isOpeningEditor || _hasPendingRequest) return;

    setState(() {
      _isOpeningEditor = true;
    });

    try {
      await context.push<bool>('/technician/specializations/edit');

      if (!mounted) return;

      // تحميل البيانات عند العودة، حتى لو لم يُؤكَّد الحفظ.
      await _loadSpecializations();
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningEditor = false;
        });
      }
    }
  }
  Widget _buildChangeRequestCard() {
  final request = _changeRequest!;
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final status = request['status']?.toString();

  final pending = status == 'pending';
  final approved = status == 'approved';
  final rejected = status == 'rejected';

  final title = pending
      ? 'طلب التعديل قيد المراجعة'
      : approved
          ? 'تمت الموافقة على آخر طلب تعديل'
          : rejected
              ? 'تم رفض آخر طلب تعديل'
              : 'حالة الطلب غير معروفة';

  final description = pending
      ? 'تبقى تخصصاتك الحالية معتمدة حتى يراجع المسؤول طلبك.'
      : approved
          ? 'تم اعتماد القائمة المطلوبة، وهي معروضة ضمن تخصصاتك أدناه.'
          : rejected
              ? 'لم تتغير تخصصاتك الحالية. يمكنك تقديم طلب جديد.'
              : 'حدّث الصفحة للتحقق من حالة الطلب.';

  final color = rejected ? colors.error : colors.primary;

  final icon = pending
      ? Icons.schedule_rounded
      : approved
          ? Icons.check_circle_outline_rounded
          : Icons.info_outline_rounded;

  final note = request['review_note']?.toString().trim() ?? '';
  final rawItems = request['requested_specializations'];
  final items = rawItems is List ? rawItems : const [];

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: color.withValues(alpha: 0.30),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'التخصصات المطلوبة في هذا الطلب',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.whereType<Map>().map((item) {
              final name = item['name_ar']?.toString() ?? 'تخصص';

              return Chip(
                label: Text(name),
              );
            }).toList(),
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'ملاحظة المسؤول',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(note),
        ],
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تخصصاتي'),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadSpecializations,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSpecializations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_changeRequest != null) ...[
  _buildChangeRequestCard(),
  const SizedBox(height: 24),
],
          Text(
            'تخصصات الصيانة التي تقدمها',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عدد التخصصات: ${_specializations.length}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (_specializations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.handyman_outlined,
                    size: 42,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لم تضف تخصصات بعد.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أضف التخصصات التي تقدم خدماتك فيها.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._specializations.map((specialization) {
              final name =
                  specialization['name_ar']?.toString().trim() ?? '';
              final description =
                  specialization['description']?.toString().trim() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.handyman_outlined,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'تخصص' : name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          FilledButton.icon(
  onPressed: _isOpeningEditor || _hasPendingRequest
      ? null
      : _openEditor,
  icon: Icon(
    _hasPendingRequest
        ? Icons.schedule_rounded
        : Icons.edit_outlined,
  ),
  label: Text(
    _hasPendingRequest
        ? 'بانتظار مراجعة المسؤول'
        : _specializations.isEmpty
            ? 'طلب إضافة تخصصات'
            : 'طلب تعديل التخصصات',
  ),
),
        ],
      ),
    );
  }
}