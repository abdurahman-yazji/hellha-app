import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/diagnosis_result.dart';

class DiagnosisResultPage extends StatelessWidget {
  const DiagnosisResultPage({required this.result, super.key});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final severityColor = _severityColor(result.severity);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('نتيجة التشخيص')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.30),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _severityIcon(result.severity),
                        color: severityColor,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'العطل المتوقع',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      result.predictedFault,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'درجة الخطورة: ${_severityLabel(result.severity)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (result.safetyWarnings.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SafetyWarningCard(
                  warnings: result.safetyWarnings,
                  severityColor: severityColor,
                ),
              ],

              const SizedBox(height: 28),

              _SectionTitle(
                icon: Icons.build_outlined,
                title: 'الأدوات المقترحة',
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),

              if (result.tools.isEmpty)
                const _EmptySection(message: 'لا توجد أدوات مطلوبة حاليًا.')
              else
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: result.tools.map((tool) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.handyman_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            tool,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 28),

              _SectionTitle(
                icon: Icons.format_list_numbered_rounded,
                title: 'خطوات الحل المقترحة',
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 12),

              if (result.guide.isEmpty)
                const _EmptySection(message: 'لا توجد خطوات إصلاح آمنة متاحة.')
              else
                ...List.generate(result.guide.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _GuideStep(
                      number: index + 1,
                      description: result.guide[index],
                    ),
                  );
                }),

              const SizedBox(height: 18),

              if (result.requiresTechnician)
                _TechnicianRequiredCard(
                  onPressed: () {
                    if (result.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تعذر تحديد التشخيص المرتبط بالطلب'),
                        ),
                      );
                      return;
                    }

                    context.push('/maintenance-requests/create', extra: result);
                  },
                )
              else
                _SelfRepairCard(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green.shade700;
      case 'medium':
        return Colors.orange.shade700;
      case 'high':
        return Colors.deepOrange.shade700;
      case 'critical':
        return Colors.red.shade800;
      default:
        return Colors.orange.shade700;
    }
  }

  String _severityLabel(String severity) {
    switch (severity.toLowerCase()) {
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

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Icons.check_circle_outline_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.dangerous_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _SafetyWarningCard extends StatelessWidget {
  const _SafetyWarningCard({
    required this.warnings,
    required this.severityColor,
  });

  final List<String> warnings;
  final Color severityColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: severityColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: severityColor),
              const SizedBox(width: 9),
              Text(
                'تحذيرات السلامة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: severityColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map((warning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: severityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 9),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.description});

  final int number;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number.toString(),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                description,
                style: const TextStyle(
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianRequiredCard extends StatelessWidget {
  const _TechnicianRequiredCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.engineering_outlined, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            'يُنصح بالاستعانة بفني',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'قد تتطلب هذه المشكلة خبرة أو أدوات متخصصة لتجنب الضرر أو الخطر.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.search_rounded),
            label: const Text('ابحث عن فني مناسب'),
          ),
        ],
      ),
    );
  }
}

class _SelfRepairCard extends StatelessWidget {
  const _SelfRepairCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home_repair_service_outlined,
            color: Colors.green,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'يمكن تجربة الخطوات الآمنة المقترحة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تشخيص مشكلة أخرى'),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
