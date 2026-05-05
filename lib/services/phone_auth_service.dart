import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String normalizeKenyanPhone(String input) {
    final raw = input.replaceAll(RegExp(r'\s+|-'), '');
    if (raw.startsWith('+254')) return raw;
    if (raw.startsWith('254')) return '+$raw';
    if (raw.startsWith('07') && raw.length == 10) {
      return '+254${raw.substring(1)}';
    }
    throw const FormatException(
      'Use a valid Kenyan number, e.g. 0712345678 or +254712345678.',
    );
  }

  Future<void> sendOtp({
    required String phoneInput,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onFailed,
  }) async {
    final phoneNumber = normalizeKenyanPhone(phoneInput);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? e.code);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    await _auth.signInWithCredential(credential);
  }
}
