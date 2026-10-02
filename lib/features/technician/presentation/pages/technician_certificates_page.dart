import 'package:flutter/material.dart';

import '../../data/services/certificate_service.dart';
import 'add_certificate_page.dart';
import '../widgets/certificate_image_thumbnail.dart';

class TechnicianCertificatesPage extends StatefulWidget {
  const TechnicianCertificatesPage({super.key});

  @override
  State<TechnicianCertificatesPage> createState() =>
      _TechnicianCertificatesPageState();
}

class _TechnicianCertificatesPageState
    extends State<TechnicianCertificatesPage> {
  final _service = CertificateService();
  final Set<String> _deletingIds = {};

  late Future<List<Map<String, dynamic>>> _certificatesFuture;
  bool _isOpeningForm = false;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  void _loadCertificates() {
    _certificatesFuture = _service.getMyCertificates().timeout(
      const Duration(seconds: 20),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(_loadCertificates);

    try {
      await _certificatesFuture;
    } catch (_) {
      // FutureBuilder displays the loading error.
    }
  }

  Future<void> _addCertificate() async {
    if (_isOpeningForm) return;

    setState(() {
      _isOpeningForm = true;
    });

    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddCertificatePage()));

    if (!mounted) return;

    setState(() {
      _isOpeningForm = false;
    });

    // Refresh even after cancellation: a timed-out save may have succeeded.
    await _refresh();
  }

  Future<void> _deleteCertificate(Map<String, dynamic> certificate) async {
    final id = certificate['id'].toString();

    if (_deletingIds.contains(id)) return;

    setState(() {
      _deletingIds.add(id);
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('حذف الشهادة'),
              content: Text(
                'هل تريد حذف شهادة '
                '«${certificate['certificate_name'] ?? ''}»؟',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('رجوع'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || confirmed != true) return;

      await _service.deleteCertificate(id).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الشهادة')));

      await _refresh();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر تأكيد الحذف. حدّث القائمة للتحقق قبل المحاولة مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الشهادات المهنية'),
          actions: [
            IconButton(
              onPressed: _refresh,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isOpeningForm ? null : _addCertificate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة شهادة'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _certificatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تعذر تحميل الشهادات — إعادة المحاولة'),
                  ),
                );
              }

              final certificates = snapshot.data ?? const [];

              if (certificates.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'لم تضف شهادات بعد.\n'
                      'اضغط «إضافة شهادة» لإدخال بيانات شهادتك.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: certificates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final certificate = certificates[index];
                    final id = certificate['id'].toString();

                    return _CertificateCard(
                      certificate: certificate,
                      isDeleting: _deletingIds.contains(id),
                      onDelete: () {
                        _deleteCertificate(certificate);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.certificate,
    required this.isDeleting,
    required this.onDelete,
  });

  final Map<String, dynamic> certificate;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = certificate['certificate_name']?.toString() ?? '';
    final organization = certificate['issuing_organization']?.toString();
    final issueDate = certificate['issue_date']?.toString();
    final expiryDate = certificate['expiry_date']?.toString();
    final documentUrl = certificate['document_url']?.toString();
    final isVerified = certificate['is_verified'] == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (certificate['has_image'] == true)
                CertificateImageThumbnail(
                  key: ValueKey('certificate-image-${certificate['id']}'),
                  certificateId: certificate['id'].toString(),
                )
              else
                Icon(Icons.workspace_premium_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'حذف الشهادة',
                  icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isVerified ? 'شهادة موثّقة' : 'شهادة غير موثّقة',
            style: TextStyle(
              color: isVerified ? Colors.green : colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (organization != null && organization.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('الجهة المانحة: $organization'),
          ],
          if (issueDate != null) ...[
            const SizedBox(height: 8),
            Text('تاريخ الإصدار: $issueDate'),
          ],
          if (expiryDate != null) ...[
            const SizedBox(height: 8),
            Text('تاريخ الانتهاء: $expiryDate'),
          ],
          if (documentUrl != null && documentUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('رابط الوثيقة:'),
            const SizedBox(height: 4),
            SelectableText(
              documentUrl,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: colors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
