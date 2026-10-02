import 'package:flutter/material.dart';

import '../../domain/models/maintenance_request.dart';

class MaintenanceRequestDetailsPage extends StatelessWidget {
  const MaintenanceRequestDetailsPage({
    required this.request,
    this.isTechnicianView = false,
    super.key,
  });

  final MaintenanceRequest request;
  final bool isTechnicianView;

  String _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'غير محدد' : text;
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} - $hour:$minute';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'created':
        return 'تم الإنشاء';
      case 'assigned':
        return 'تم الإسناد';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'closed':
        return 'مغلق';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  String _severityLabel(String? severity) {
    switch (severity) {
      case 'low':
        return 'منخفضة';
      case 'medium':
        return 'متوسطة';
      case 'high':
        return 'مرتفعة';
      case 'critical':
        return 'حرجة';
      default:
        return 'غير محددة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = request.reviewRating;
    final comment = request.reviewComment?.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'طلب رقم ${request.id}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الحالة: ${_statusLabel(request.status)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
                            const SizedBox(height: 20),
              _DetailsSection(
                title: request.isDirectRequest
                    ? 'تفاصيل المشكلة'
                    : 'المشكلة والتشخيص',
                icon: Icons.build_circle_outlined,
                children: [
                  _DetailItem(
                    label: 'نوع الطلب',
                    value: request.isDirectRequest
                        ? 'طلب صيانة مباشر'
                        : 'طلب بعد تشخيص بالذكاء الاصطناعي',
                  ),
                  _DetailItem(
                    label: 'التخصص',
                    value: _text(request.specializationName),
                  ),
                  _DetailItem(
                    label: 'وصف المشكلة',
                    value: request.problemDescription,
                  ),
                  if (!request.isDirectRequest) ...[
                    _DetailItem(
                      label: 'العطل المتوقع',
                      value: _text(request.predictedFault),
                    ),
                    _DetailItem(
                      label: 'درجة الخطورة',
                      value: _severityLabel(request.severity),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _DetailsSection(
                title: 'بيانات الزيارة',
                icon: Icons.location_on_outlined,
                children: [
                  _DetailItem(
                    label: 'منطقة العمل',
                    value: _text(request.workArea),
                  ),
                  _DetailItem(
                    label: 'العنوان',
                    value: _text(request.addressDetails),
                  ),
                  _DetailItem(
                    label: 'رقم التواصل للطلب',
                    value: _text(request.contactPhone),
                  ),
                  _DetailItem(
                    label: 'الملاحظات',
                    value: request.notes?.trim().isNotEmpty == true
                        ? request.notes!.trim()
                        : 'لا توجد ملاحظات',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DetailsSection(
                title: isTechnicianView ? 'بيانات العميل' : 'الفني',
                icon: isTechnicianView
                    ? Icons.person_outline_rounded
                    : Icons.engineering_outlined,
                children: [
                  if (isTechnicianView) ...[
                    _DetailItem(
                      label: 'اسم العميل',
                      value: _text(request.customerName),
                    ),
                    _DetailItem(
                      label: 'رقم التواصل للطلب',
                      value: _text(request.contactPhone),
                    ),
                  ] else if (request.technicianProfileId == null)
                    const Text('لم يتم اختيار فني حاليًا.')
                  else ...[
                    _DetailItem(
                      label: 'الاسم',
                      value: _text(request.technicianName),
                    ),
                    _DetailItem(
                      label: 'رقم الهاتف',
                      value: _text(request.technicianPhone),
                    ),
                    _DetailItem(
                      label: 'منطقة العمل',
                      value: _text(request.technicianWorkArea),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _DetailsSection(
                title: 'تواريخ الطلب',
                icon: Icons.schedule_rounded,
                children: [
                  _DetailItem(
                    label: 'إنشاء الطلب',
                    value: _formatDate(request.createdAt),
                  ),
                  if (request.assignedAt != null)
                    _DetailItem(
                      label: 'إسناد الطلب',
                      value: _formatDate(request.assignedAt!),
                    ),
                  if (request.startedAt != null)
                    _DetailItem(
                      label: 'بدء العمل',
                      value: _formatDate(request.startedAt!),
                    ),
                  if (request.completedAt != null)
                    _DetailItem(
                      label: 'اكتمال العمل',
                      value: _formatDate(request.completedAt!),
                    ),
                  if (request.closedAt != null)
                    _DetailItem(
                      label: 'إغلاق الطلب',
                      value: _formatDate(request.closedAt!),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _DetailsSection(
                title: isTechnicianView ? 'تقييم العميل' : 'تقييمك للخدمة',
                icon: Icons.star_outline_rounded,
                children: [
                  if (rating == null)
                    const Text('لا يوجد تقييم محفوظ لهذا الطلب.')
                  else ...[
                    Semantics(
                      label: 'التقييم $rating من 5',
                      child: ExcludeSemantics(
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Icon(
                                index < rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: colors.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      comment == null || comment.isEmpty
                          ? 'لا يوجد تعليق مرفق بالتقييم.'
                          : comment,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    if (request.reviewCreatedAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'تاريخ التقييم: '
                        '${_formatDate(request.reviewCreatedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
