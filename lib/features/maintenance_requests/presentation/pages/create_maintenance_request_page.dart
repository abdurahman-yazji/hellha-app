import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../diagnosis/domain/models/diagnosis_result.dart';
import '../../../technician/data/services/technician_service.dart';
import '../../data/services/maintenance_request_service.dart';

class CreateMaintenanceRequestPage extends StatefulWidget {
  const CreateMaintenanceRequestPage({required this.diagnosis, super.key});

  final DiagnosisResult diagnosis;

  @override
  State<CreateMaintenanceRequestPage> createState() =>
      _CreateMaintenanceRequestPageState();
}

class _CreateMaintenanceRequestPageState
    extends State<CreateMaintenanceRequestPage> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _workAreaController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final _maintenanceService = MaintenanceRequestService();
  final _technicianService = TechnicianService();

  late Future<List<Map<String, dynamic>>> _specializationsFuture;

  List<Map<String, dynamic>> _availableTechnicians = [];

  String? _selectedSpecializationId;
  String? _selectedTechnicianId;
  bool _isLoadingTechnicians = false;
  bool _technicianSearchCompleted = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _specializationsFuture = _technicianService.getSpecializations();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _workAreaController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTechnicians() async {
    if (_selectedSpecializationId == null) {
      setState(() {
        _errorMessage = 'اختر تخصص الفني المطلوب أولًا';
      });
      return;
    }

    final workArea = _workAreaController.text.trim();

    if (workArea.length < 2) {
      setState(() {
        _errorMessage = 'أدخل المنطقة قبل البحث عن الفنيين';
      });
      return;
    }

    setState(() {
      _isLoadingTechnicians = true;
      _technicianSearchCompleted = false;
      _availableTechnicians = [];
      _selectedTechnicianId = null;
      _errorMessage = null;
    });

    try {
      final technicians = await _technicianService.getAvailableTechnicians(
        specializationId: _selectedSpecializationId!,
        workArea: workArea,
      );

      if (!mounted) return;

      setState(() {
        _availableTechnicians = technicians;
        _technicianSearchCompleted = true;
        _isLoadingTechnicians = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingTechnicians = false;
        _technicianSearchCompleted = true;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final diagnosisId = widget.diagnosis.id;

    if (diagnosisId == null) {
      setState(() {
        _errorMessage = 'تعذر تحديد التشخيص المرتبط بالطلب';
      });
      return;
    }

    if (_selectedTechnicianId == null) {
      setState(() {
        _errorMessage = 'ابحث عن الفنيين واختر فنيًا قبل إرسال الطلب';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _maintenanceService.createRequest(
        diagnosisId: diagnosisId,
        specializationId: _selectedSpecializationId!,
        technicianProfileId: _selectedTechnicianId!,
        contactPhone: _phoneController.text,
        workArea: _workAreaController.text,
        addressDetails: _addressController.text,
        notes: _notesController.text,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 52,
            ),
            title: const Text('تم إرسال الطلب', textAlign: TextAlign.center),
            content: const Text(
              'تم إرسال طلب الصيانة إلى الفني الذي اخترته.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('حسنًا'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      context.go('/');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _retrySpecializations() {
    setState(() {
      _specializationsFuture = _technicianService.getSpecializations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلب فني صيانة')),
        body: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _specializationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _LoadError(onRetry: _retrySpecializations);
              }

              final specializations = snapshot.data ?? const [];

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  children: [
                    _DiagnosisSummary(diagnosis: widget.diagnosis),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecializationId,
                      decoration: const InputDecoration(
                        labelText: 'تخصص الفني المطلوب',
                        prefixIcon: Icon(Icons.handyman_outlined),
                      ),
                      items: specializations.map((specialization) {
                        final id = specialization['id'].toString();
                        final name =
                            specialization['name_ar']?.toString() ??
                            'تخصص غير محدد';

                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedSpecializationId = value;
                                _selectedTechnicianId = null;
                                _availableTechnicians = [];
                                _technicianSearchCompleted = false;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'اختر تخصص الفني المطلوب';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _workAreaController,
                      decoration: const InputDecoration(
                        labelText: 'المنطقة أو المدينة',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      onChanged: (_) {
                        if (_technicianSearchCompleted ||
                            _selectedTechnicianId != null) {
                          setState(() {
                            _availableTechnicians = [];
                            _selectedTechnicianId = null;
                            _technicianSearchCompleted = false;
                          });
                        }
                      },
                      validator: (value) {
                        final area = value?.trim() ?? '';

                        if (area.length < 2) {
                          return 'أدخل المنطقة';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _isLoadingTechnicians || _isSubmitting
                          ? null
                          : _loadAvailableTechnicians,
                      icon: _isLoadingTechnicians
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      label: Text(
                        _isLoadingTechnicians
                            ? 'جارٍ البحث...'
                            : 'عرض الفنيين المتاحين',
                      ),
                    ),
                    if (_availableTechnicians.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        'اختر الفني المناسب',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._availableTechnicians.map((technician) {
                        final technicianId = technician['id'].toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TechnicianCard(
                            technician: technician,
                            isSelected: _selectedTechnicianId == technicianId,
                            onTap: () {
                              setState(() {
                                _selectedTechnicianId = technicianId;
                                _errorMessage = null;
                              });
                            },
                          ),
                        );
                      }),
                    ] else if (_technicianSearchCompleted &&
                        _errorMessage == null) ...[
                      const SizedBox(height: 18),
                      const _NoTechniciansCard(),
                    ],
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم التواصل',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final phone = value?.trim() ?? '';

                        if (phone.length < 7 || phone.length > 30) {
                          return 'أدخل رقم تواصل صحيحًا';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل العنوان',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        final address = value?.trim() ?? '';

                        if (address.length < 5) {
                          return 'أدخل تفاصيل عنوان واضحة';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات إضافية (اختياري)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'جارٍ إرسال الطلب...'
                            : 'إرسال الطلب للفني المختار',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiagnosisSummary extends StatelessWidget {
  const _DiagnosisSummary({required this.diagnosis});

  final DiagnosisResult diagnosis;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'العطل المتوقع',
            style: TextStyle(color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            diagnosis.predictedFault,
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.technician,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, dynamic> technician;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = technician['name']?.toString() ?? 'فني صيانة';
    final workArea = technician['work_area']?.toString() ?? 'المنطقة غير محددة';
    final experience = technician['years_of_experience']?.toString() ?? '0';
    final rating = technician['average_rating']?.toString() ?? '0';
    final completedJobs = technician['total_completed_jobs']?.toString() ?? '0';

    return Material(
      color: isSelected
          ? colors.primary.withValues(alpha: 0.08)
          : colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.secondaryContainer,
                child: Icon(
                  Icons.engineering_rounded,
                  color: colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.blue,
                          size: 19,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$workArea • خبرة $experience سنة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '⭐ $rating  •  $completedJobs أعمال مكتملة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? colors.primary : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTechniciansCard extends StatelessWidget {
  const _NoTechniciansCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, size: 38),
          SizedBox(height: 10),
          Text(
            'لا يوجد فنيون متاحون في هذا التخصص حاليًا',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('تعذر تحميل التخصصات - إعادة المحاولة'),
      ),
    );
  }
}
