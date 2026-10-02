import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/services/certificate_service.dart';

class CertificateImageThumbnail extends StatefulWidget {
  const CertificateImageThumbnail({required this.certificateId, super.key});

  final String certificateId;

  @override
  State<CertificateImageThumbnail> createState() =>
      _CertificateImageThumbnailState();
}

class _CertificateImageThumbnailState extends State<CertificateImageThumbnail> {
  final _service = CertificateService();

  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CertificateImageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.certificateId != widget.certificateId) {
      _loadImage();
    }
  }

  void _loadImage() {
    _imageFuture = _service.getCertificateImage(widget.certificateId);
  }

  void _retry() {
    setState(_loadImage);
  }

  void _openImage(Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CertificateImageViewer(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: colors.surfaceContainerHighest,
          child: FutureBuilder<Uint8List>(
            future: _imageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return IconButton(
                  onPressed: _retry,
                  tooltip: 'تعذر تحميل الصورة — إعادة المحاولة',
                  icon: const Icon(Icons.refresh_rounded),
                );
              }

              final bytes = snapshot.data!;

              return Semantics(
                button: true,
                label: 'عرض صورة الشهادة بملء الشاشة',
                child: Tooltip(
                  message: 'عرض صورة الشهادة',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openImage(bytes),
                      child: Image.memory(
                        bytes,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: 192,
                        errorBuilder: (_, _, _) {
                          return IconButton(
                            onPressed: _retry,
                            tooltip: 'إعادة تحميل الصورة',
                            icon: const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CertificateImageViewer extends StatelessWidget {
  const _CertificateImageViewer({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('صورة الشهادة'),
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return const Text(
                      'تعذر عرض الصورة',
                      style: TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
