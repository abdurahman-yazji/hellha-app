import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/certificate_service.dart';

class AddCertificatePage extends StatefulWidget {
  const AddCertificatePage({super.key});

  @override
  State<AddCertificatePage> createState() => _AddCertificatePageState();
}

class _AddCertificatePageState extends State<AddCertificatePage> {
  final _formKey = GlobalKey<FormState>();
  final _service = CertificateService();
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imagePreview;
  bool _isPickingImage = false;

  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _issueController = TextEditingController();
  final _expiryController = TextEditingController();
  final _urlController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _issueController.dispose();
    _expiryController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _parseDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }

    final date = DateTime.tryParse('${value}T00:00:00Z');

    if (date == null || date.toIso8601String().substring(0, 10) != value) {
      return null;
    }

    return date;
  }

  String? _validateDate(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    if (_parseDate(text) == null) {
      return 'اختر تاريخًا صحيحًا';
    }

    return null;
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required bool isExpiry,
  }) async {
    if (_isSaving) return;

    final firstDate = DateTime(1900);
    final lastDate = DateTime(2200, 12, 31);

    final existing = _parseDate(controller.text.trim());
    final issue = _parseDate(_issueController.text.trim());

    DateTime initialDate = DateUtils.dateOnly(DateTime.now());

    if (existing != null) {
      initialDate = DateTime(existing.year, existing.month, existing.day);
    } else if (isExpiry && issue != null) {
      initialDate = DateTime(issue.year, issue.month, issue.day);
    }

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: isExpiry
          ? 'اختر تاريخ انتهاء الشهادة'
          : 'اختر تاريخ إصدار الشهادة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );

    if (!mounted || selected == null) return;

    final year = selected.year.toString().padLeft(4, '0');
    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');

    setState(() {
      controller.text = '$year-$month-$day';
    });
  }

  Future<void> _pickImage() async {
    if (_isSaving || _isPickingImage) return;

    setState(() {
      _isPickingImage = true;
      _errorMessage = null;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );

      if (!mounted || image == null) return;

      const maxBytes = 5 * 1024 * 1024;

      if (await image.length() > maxBytes) {
        throw Exception('حجم الصورة يجب ألا يتجاوز 5 ميجابايت');
      }

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty || bytes.length > maxBytes) {
        throw Exception('الصورة فارغة أو حجمها أكبر من المسموح');
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _imagePreview = bytes;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'تعذر اختيار الصورة. اختر صورة JPEG أو PNG أو WebP '
            'بحجم لا يتجاوز 5 ميجابايت.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || _isPickingImage) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _service.createCertificate(
        certificateName: _nameController.text.trim(),
        issuingOrganization: _optionalText(_organizationController.text),
        issueDate: _optionalText(_issueController.text),
        expiryDate: _optionalText(_expiryController.text),
        documentUrl: _optionalText(_urlController.text),
        image: _selectedImage,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت إضافة الشهادة')));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage =
            'تعذر تأكيد إضافة الشهادة. ارجع إلى قائمة الشهادات '
            'وحدّثها قبل إعادة الإرسال لتجنب تكرارها.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('إضافة شهادة')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'صورة الشهادة (اختياري)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSaving || _isPickingImage ? null : _pickImage,
                    icon: _isPickingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _isPickingImage
                          ? 'جارٍ اختيار الصورة...'
                          : _selectedImage == null
                          ? 'اختيار صورة من المعرض'
                          : 'تغيير الصورة',
                    ),
                  ),
                  if (_imagePreview != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _imagePreview!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) {
                          return const SizedBox(
                            height: 100,
                            child: Center(
                              child: Text('تعذر عرض معاينة الصورة'),
                            ),
                          );
                        },
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSaving || _isPickingImage
                          ? null
                          : () {
                              setState(() {
                                _selectedImage = null;
                                _imagePreview = null;
                              });
                            },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('إزالة الصورة'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'اسم الشهادة',
                      prefixIcon: Icon(Icons.workspace_premium_outlined),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';

                      if (name.length < 2 || name.length > 200) {
                        return 'أدخل اسمًا من 2 إلى 200 حرف';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _organizationController,
                    enabled: !_isSaving,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'الجهة المانحة (اختياري)',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (value) {
                      if ((value?.trim().length ?? 0) > 200) {
                        return 'الحد الأقصى 200 حرف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _issueController,
                    enabled: !_isSaving,
                    readOnly: true,
                    textDirection: TextDirection.ltr,
                    onTap: () {
                      _pickDate(controller: _issueController, isExpiry: false);
                    },
                    decoration: InputDecoration(
                      labelText: 'تاريخ الإصدار (اختياري)',
                      hintText: 'اضغط لاختيار التاريخ',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: _issueController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح التاريخ',
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _issueController.clear();
                                      });
                                    },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                    validator: _validateDate,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expiryController,
                    enabled: !_isSaving,
                    readOnly: true,
                    textDirection: TextDirection.ltr,
                    onTap: () {
                      _pickDate(controller: _expiryController, isExpiry: true);
                    },
                    decoration: InputDecoration(
                      labelText: 'تاريخ الانتهاء (اختياري)',
                      hintText: 'اضغط لاختيار التاريخ',
                      helperText: 'اتركه فارغًا إذا كانت الشهادة بلا انتهاء',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.event_outlined),
                      suffixIcon: _expiryController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح التاريخ',
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _expiryController.clear();
                                      });
                                    },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                    validator: (value) {
                      final error = _validateDate(value);
                      if (error != null) return error;

                      final expiry = _parseDate(value?.trim() ?? '');
                      final issue = _parseDate(_issueController.text.trim());

                      if (expiry != null &&
                          issue != null &&
                          expiry.isBefore(issue)) {
                        return 'تاريخ الانتهاء لا يسبق تاريخ الإصدار';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    enabled: !_isSaving,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'رابط وثيقة الشهادة (اختياري)',
                      hintText: 'https://example.com/certificate.pdf',
                      helperText: 'يمكن إدخال رابط مباشر لملف PDF',
                      helperMaxLines: 2,
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;

                      final uri = Uri.tryParse(text);

                      if (uri == null ||
                          !uri.hasAuthority ||
                          uri.host.isEmpty ||
                          (uri.scheme != 'http' && uri.scheme != 'https')) {
                        return 'أدخل رابط HTTP أو HTTPS صحيحًا';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _isSaving || _isPickingImage ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      _isSaving ? 'جارٍ الإضافة...' : 'إضافة الشهادة',
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
