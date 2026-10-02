import 'package:flutter/material.dart';

import '../../data/services/technician_service.dart';

class EditTechnicianSpecializationsPage extends StatefulWidget {
  const EditTechnicianSpecializationsPage({super.key});

  @override
  State<EditTechnicianSpecializationsPage> createState() =>
      _EditTechnicianSpecializationsPageState();
}

class _EditTechnicianSpecializationsPageState
    extends State<EditTechnicianSpecializationsPage> {
  final _service = TechnicianService();

  List<Map<String, dynamic>> _specializations = [];
  Set<String> _selectedIds = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasInactiveSelections = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  Future<void> _loadSpecializations() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _service.getSpecializations(),
        _service.getMySpecializations(),
      ]).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      final available = results[0];
      final current = results[1];

      final availableIds = available
          .map((item) => item['id'].toString())
          .toSet();

      final currentIds = current.map((item) => item['id'].toString()).toSet();

      setState(() {
        _specializations = available;
        _selectedIds = currentIds.intersection(availableIds);
        _hasInactiveSelections = currentIds.difference(availableIds).isNotEmpty;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'تعذر تحميل التخصصات';
      });
    }
  }

  void _toggleSelection(String id, bool selected) {
    if (_isSaving) return;

    if (selected && _selectedIds.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يمكنك اختيار 10 تخصصات كحد أقصى')),
      );
      return;
    }

    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
      _saveError = null;
    });
  }

  Future<void> _save() async {
  if (_isSaving) return;

  if (_selectedIds.isEmpty || _selectedIds.length > 10) {
    setState(() {
      _saveError = 'اختر من تخصص واحد إلى 10 تخصصات';
    });
    return;
  }

  setState(() {
    _isSaving = true;
    _saveError = null;
  });

  try {
    await _service.setMySpecializations(_selectedIds.toList());

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إرسال طلب تعديل التخصصات للمسؤول. '
          'ستبقى تخصصاتك الحالية حتى الموافقة.',
        ),
      ),
    );

    // الانتظار حتى يُحدَّث PopScope ويسمح بالرجوع.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  } on StateError catch (error) {
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _saveError = error.message;
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _saveError =
          'تعذر تأكيد إرسال الطلب. قد يكون وصل إلى الخادم؛ '
          'تحقق من حالة طلب المراجعة قبل المحاولة مجددًا.';
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
          appBar: AppBar(title: const Text('طلب تعديل التخصصات')),
          body: SafeArea(child: _buildBody(theme)),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadSpecializations,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_specializations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'لا توجد تخصصات متاحة حاليًا.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadSpecializations,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'اختر التخصصات التي تريد اعتمادها. '
'ستُرسل للمسؤول للمراجعة، وتبقى تخصصاتك الحالية حتى الموافقة.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'المحدد: ${_selectedIds.length} من 10',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_hasInactiveSelections) ...[
          const SizedBox(height: 12),
          const Text(
            'بعض تخصصاتك السابقة لم تعد متاحة. '
            'عند الحفظ ستُستبدل بالقائمة المحددة أدناه.',
          ),
        ],
        const SizedBox(height: 20),
        ..._specializations.map((specialization) {
          final id = specialization['id'].toString();
          final name = specialization['name_ar']?.toString() ?? 'تخصص';
          final description = specialization['description']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedIds.contains(id)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: CheckboxListTile(
                value: _selectedIds.contains(id),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        _toggleSelection(id, value == true);
                      },
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: description.isEmpty ? null : Text(description),
              ),
            ),
          );
        }),
        if (_saveError != null) ...[
          const SizedBox(height: 8),
          Text(_saveError!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isSaving || _selectedIds.isEmpty ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
label: Text(
  _isSaving ? 'جارٍ الإرسال...' : 'إرسال طلب المراجعة',
),        ),
      ],
    );
  }
}
