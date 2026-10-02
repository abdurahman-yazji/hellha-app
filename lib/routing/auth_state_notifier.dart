import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  bool _registrationInProgress = false;

  bool get registrationInProgress => _registrationInProgress;

  void beginRegistration() {
    if (_registrationInProgress) return;

    _registrationInProgress = true;
    notifyListeners();
  }

  void endRegistration() {
    if (!_registrationInProgress) return;

    _registrationInProgress = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
