import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../maintenance_requests/presentation/pages/create_direct_maintenance_request_page.dart';
import '../../data/services/technician_service.dart';

class AvailableTechniciansPage extends StatefulWidget {
  const AvailableTechniciansPage({super.key});

  @override
  State<AvailableTechniciansPage> createState() =>
      _AvailableTechniciansPageState();
}

class _AvailableTechniciansPageState extends State<AvailableTechniciansPage> {
  final _service = TechnicianService();
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();

  List<Map<String, dynamic>> _specializations = [];
  List<Map<String, dynamic>> _technicians = [];

  String? _selectedSpecializationId;
  String? _loadError;
  String? _searchError;

  bool _loadingSpecializations = true;
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    setState(() {
      _loadingSpecializations = true;
      _loadError = null;
    });

    try {
      final items = await _service.getSpecializations().timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _specializations = items;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadError = 'تعذر تحميل التخصصات.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSpecializations = false;
        });
      }
    }
  }

  void _clearResults() {
    setState(() {
      _hasSearched = false;
      _technicians = [];
      _searchError = null;
    });
  }

  Future<void> _search() async {
    if (_searching || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _searching = true;
      _searchError = null;
      _hasSearched = false;
      _technicians = [];
    });

    try {
      final items = await _service
          .getAvailableTechnicians(
            specializationId: _selectedSpecializationId!,
            workArea: _areaController.text.trim(),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() {
        _technicians = items;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _searchError =
            'تعذر تحميل الفنيين. تحقق من الاتصال وحاول البحث مجددًا.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الفنيون المتاحون')),
        body: SafeArea(
          child: _loadingSpecializations
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(
                  child: OutlinedButton.icon(
                    onPressed: _loadSpecializations,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('$_loadError إعادة المحاولة'),
                  ),
                )
              : _specializations.isEmpty
              ? const Center(child: Text('لا توجد تخصصات متاحة حاليًا.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'ابحث عن فني مناسب',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تُعرض الحسابات الموثّقة والمتاحة حاليًا. '
                      'أدخل منطقتك لإظهار فنييها أولًا، '
                      'مع بقاء نتائج المناطق الأخرى.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'التخصص',
                              prefixIcon: Icon(Icons.handyman_outlined),
                            ),
                            items: _specializations.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['id'].toString(),
                                child: Text(
                                  item['name_ar']?.toString() ?? 'تخصص',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _searching
                                ? null
                                : (value) {
                                    _selectedSpecializationId = value;
                                    _clearResults();
                                  },
                            validator: (value) {
                              return value == null ? 'اختر التخصص' : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _areaController,
                            enabled: !_searching,
                            maxLength: 150,
                            decoration: const InputDecoration(
                              labelText: 'منطقتك — اختياري',
                              hintText: 'مثل: غزة',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            onChanged: (_) => _clearResults(),
                            validator: (value) {
                              final area = value?.trim() ?? '';

                              if (area.isNotEmpty &&
                                  (area.length < 2 || area.length > 150)) {
                                return 'أدخل منطقة من 2 إلى 150 حرف';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _searching ? null : _search,
                            icon: _searching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search_rounded),
                            label: Text(
                              _searching ? 'جارٍ البحث...' : 'البحث عن الفنيين',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_searchError != null)
                      Text(
                        _searchError!,
                        style: TextStyle(color: colors.error, height: 1.5),
                      ),
                    if (_hasSearched) ...[
                      Text(
                        'النتائج المعروضة: ${_technicians.length}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_technicians.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'لا يوجد فنيون متاحون لهذا التخصص حاليًا.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._technicians.map(
                          (technician) => _TechnicianCard(
                            key: ValueKey(technician['id'].toString()),
                            technician: technician,
                            onBook: () {
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => CreateDirectMaintenanceRequestPage(
        technician: technician,
        initialSpecializationId: _selectedSpecializationId,
      ),
    ),
  );
},
                          ),
                        ),
                      if (_technicians.length == 50)
                        const Text('تُعرض أول 50 نتيجة حسب ترتيب البحث.'),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'لطلب الصيانة، ابدأ بتشخيص المشكلة '
                      'أو افتح تشخيصًا محفوظًا، ثم اختر الفني '
                      'أثناء إنشاء الطلب.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/diagnosis'),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('تشخيص مشكلة جديدة'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/diagnosis/history');
                      },
                      child: const Text('فتح سجل التشخيصات'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.technician,
    required this.onBook,
    super.key,
  });

  final VoidCallback onBook;
  final Map<String, dynamic> technician;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = technician['name']?.toString().trim() ?? '';
    final area = technician['work_area']?.toString().trim() ?? '';
    final bio = technician['bio']?.toString().trim() ?? '';

    final rating =
        double.tryParse(technician['average_rating']?.toString() ?? '') ?? 0;

    final experience = technician['years_of_experience'] ?? 0;
    final completed = technician['total_completed_jobs'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.engineering_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.isEmpty ? 'فني صيانة' : name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Tooltip(
                message: 'فني موثّق',
                child: Icon(Icons.verified_rounded, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('منطقة العمل: ${area.isEmpty ? 'غير محددة' : area}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              Text('الخبرة: $experience سنة'),
              Text('الأعمال المكتملة: $completed'),
              Text(
                rating > 0
                    ? '★ ${rating.toStringAsFixed(2)} / 5'
                    : 'لا توجد تقييمات بعد',
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
            ),
          ],
      
                const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('طلب صيانة'),
            ),
          ),
        ],
      ),
    );
  }
}
