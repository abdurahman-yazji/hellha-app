import 'dart:async';
import '../../../notifications/data/services/push_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    debugPrint('GOOGLE SIGN-IN: Starting initialization');

    await _googleSignIn.initialize().timeout(const Duration(seconds: 20));

    _googleInitialized = true;

    debugPrint('GOOGLE SIGN-IN: Initialization completed');
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'Google authentication is not supported on this platform',
        );
      }

      debugPrint('GOOGLE SIGN-IN: Waiting for account selection');

      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate()
          .timeout(const Duration(seconds: 45));

      debugPrint('GOOGLE SIGN-IN: Google account selected');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('GOOGLE SIGN-IN: Signing in to Firebase');

      final userCredential = await _firebaseAuth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));

      debugPrint('GOOGLE SIGN-IN: Firebase sign-in completed');

      return userCredential;
    } catch (error, stackTrace) {
      debugPrint('GOOGLE SIGN-IN ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    await PushNotificationService.instance.signOut(() async {
      try {
        await _initializeGoogleSignIn();

        await _googleSignIn.signOut().timeout(const Duration(seconds: 20));
      } catch (_) {
        debugPrint('GOOGLE SIGN-OUT: provider cleanup failed');
      }

      await _firebaseAuth.signOut();
    });
  }
}
