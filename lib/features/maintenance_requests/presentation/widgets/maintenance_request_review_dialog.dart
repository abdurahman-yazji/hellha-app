import 'package:flutter/material.dart';

class MaintenanceRequestReviewInput {
  const MaintenanceRequestReviewInput({
    required this.rating,
    required this.comment,
  });

  final int rating;
  final String comment;
}

class MaintenanceRequestReviewDialog extends StatefulWidget {
  const MaintenanceRequestReviewDialog({super.key});

  @override
  State<MaintenanceRequestReviewDialog> createState() =>
      _MaintenanceRequestReviewDialogState();
}

class _MaintenanceRequestReviewDialogState
    extends State<MaintenanceRequestReviewDialog> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد الإنجاز وتقييم الفني'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أكد أن أعمال الصيانة اكتملت، ثم قيّم تجربتك '
                'مع الفني. عند الإرسال سيُغلق الطلب.',
              ),
              const SizedBox(height: 20),
              const Text('تقييمك من 1 إلى 5'),
              const SizedBox(height: 8),
              Wrap(
                children: List.generate(5, (index) {
                  final value = index + 1;

                  return IconButton(
                    tooltip: 'تقييم $value من 5',
                    onPressed: () {
                      setState(() {
                        _rating = value;
                      });
                    },
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: value <= _rating
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 32,
                    ),
                  );
                }),
              ),
              Text(_rating == 0 ? 'اختر عدد النجوم' : 'التقييم: $_rating من 5'),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'تعليقك (اختياري)',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: _rating == 0
                ? null
                : () {
                    Navigator.of(context).pop(
                      MaintenanceRequestReviewInput(
                        rating: _rating,
                        comment: _commentController.text.trim(),
                      ),
                    );
                  },
            child: const Text('تأكيد وإرسال'),
          ),
        ],
      ),
    );
  }
}
