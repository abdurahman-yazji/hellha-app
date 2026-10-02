import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/diagnosis_service.dart';

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  final DiagnosisService _diagnosisService = DiagnosisService();

  String? _selectedCategory;
  bool _isSubmitting = false;

  static const _categories = <String>[
    'الكهرباء',
    'السباكة',
    'التكييف والتبريد',
    'الأجهزة المنزلية',
    'البناء والتشققات',
    'غير متأكد',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitDiagnosis() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _diagnosisService.diagnoseIssue(
        description: _descriptionController.text,
        category: _selectedCategory,
      );

      if (!mounted) return;

      context.push('/diagnosis/result', extra: result);
    } on TimeoutException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('استغرق التشخيص وقتًا طويلًا. حاول مرة أخرى.'),
        ),
      );
    } catch (error) {
      debugPrint('DIAGNOSIS ERROR: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تشخيص المشكلة حاليًا. حاول مرة أخرى.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showImageMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ستتوفر ميزة إضافة الصور في النسخة القادمة.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تشخيص العطل')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1F3A), Color(0xFF163A63)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'دعنا نساعدك في فهم المشكلة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'صف العطل بالتفصيل وسنحلله ونقترح الخطوات المناسبة.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'نوع المشكلة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'اختر نوع المشكلة إن كنت تعرفه',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'وصف العطل',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اذكر ما حدث، ومتى بدأ، وأي أصوات أو روائح أو علامات لاحظتها.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 1000,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText:
                        'مثال: المكيف يعمل لكن لا يبرد، وبدأ يصدر صوتًا غير معتاد منذ يومين...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final description = value?.trim() ?? '';

                    if (description.isEmpty) {
                      return 'اكتب وصفًا للمشكلة';
                    }

                    if (description.length < 10) {
                      return 'اكتب وصفًا أوضح لا يقل عن 10 أحرف';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                Text(
                  'صورة العطل',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'إضافة صورة اختيارية قد تساعد في تحسين نتيجة التشخيص.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),

                Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _showImageMessage,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 42,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'إضافة صورة',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'من الكاميرا أو معرض الصور',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'إذا كان هناك حريق، دخان كثيف، رائحة غاز، أسلاك مكشوفة أو خطر مباشر، ابتعد عن مصدر الخطر ولا تحاول إصلاحه بنفسك.',
                          style: TextStyle(
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitDiagnosis,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _isSubmitting ? 'جارٍ تحليل المشكلة...' : 'تشخيص المشكلة',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
