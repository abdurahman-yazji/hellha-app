import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  final _service = NotificationService();

  int _unreadCount = 0;
  int _loadVersion = 0;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCount();
    }
  }

  Future<void> _loadCount() async {
    final version = ++_loadVersion;

    try {
      final count = await _service.getUnreadCount();

      if (!mounted || version != _loadVersion) return;

      setState(() {
        _unreadCount = count;
      });
    } catch (_) {
      // Keep the bell usable when the count cannot be loaded.
    }
  }

  Future<void> _openNotifications() async {
    if (_opening) return;

    setState(() {
      _opening = true;
    });

    try {
      await context.push('/notifications');
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });

        await _loadCount();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _unreadCount > 0
          ? 'الإشعارات: $_unreadCount غير مقروءة'
          : 'الإشعارات',
      onPressed: _opening ? null : _openNotifications,
      icon: Badge(
        isLabelVisible: _unreadCount > 0,
        label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
