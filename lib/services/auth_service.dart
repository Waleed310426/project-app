// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:task_ly/helpers/database_helper.dart';
// استخدام alias لتجنب التعارض بين نموذج المستخدم الخاص بنا ونموذج Firebase.
import 'package:task_ly/models/user_model.dart' as app_user; 

/// هذا الكلاس (`AuthService`) هو المسؤول الوحيد عن كل عمليات المصادقة في التطبيق.
/// يقوم بتغليف منطق Firebase Auth و Google Sign-In وقاعدة البيانات المحلية في مكان واحد.
class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- 1. Stream لمراقبة حالة المستخدم (مهم جدًا!) ---
  /// هذا الـ Stream هو "قلب" نظام المصادقة.
  /// `AuthWrapper` يستمع لهذا الـ Stream ليقرر أي شاشة يعرضها (تسجيل الدخول أو الرئيسية).
  /// **المنطق الرئيسي**: لا نعتبر المستخدم مسجلاً دخوله إلا إذا كان حسابه في Firebase موجودًا **و** بريده الإلكتروني مفعّلاً.
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map((firebaseUser) {
      // إذا لم يكن هناك مستخدم في Firebase، أرجع null.
      if (firebaseUser == null) {
        print("AuthService: No Firebase user found.");
        return null;
      }
      
      // [التعديل الرئيسي هنا]
      // إذا كان المستخدم موجودًا ولكن بريده غير مفعل، تعامل معه كأنه غير مسجل الدخول.
      if (firebaseUser.emailVerified) {
        print("AuthService: User is logged in and verified (${firebaseUser.email}).");
        // فقط إذا كان البريد مفعلاً، قم بتحويله إلى نموذج المستخدم الخاص بنا (`app_user.User`) وأرجعه.
        return app_user.User.fromFirebase(firebaseUser);
      }
      
      // في جميع الحالات الأخرى (مستخدم غير مفعل)، أرجع null.
      print("AuthService: User exists but email is NOT verified (${firebaseUser.email}). Returning null.");
      return null;
    });
  }

  /// دالة `signInAndSyncUser`: تقوم بتسجيل دخول المستخدم ومزامنة بياناته مع قاعدة البيانات المحلية.
  /// ترجع إما كائن `app_user.User` في حالة النجاح، أو `String` (رسالة خطأ) في حالة الفشل.
  Future<dynamic> signInAndSyncUser(String email, String password) async {
    try {
      // 1. محاولة تسجيل الدخول عبر Firebase.
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user;

      // 2. التحقق من التفعيل.
      if (firebaseUser == null || !firebaseUser.emailVerified) {
        if (firebaseUser != null) {
          await firebaseUser.sendEmailVerification(); // إرسال رابط تفعيل جديد.
          await signOut(); // تسجيل الخروج فورًا.
        }
        return 'الحساب غير مفعل. تم إرسال رابط تفعيل جديد إلى بريدك.';
      }

      // 3. [المنطق الجديد] البحث عن المستخدم في قاعدة البيانات المحلية SQLite.
      var localUser = await _dbHelper.queryRow(DatabaseHelper.tableUsers, firebaseUser.uid);
       
      // 4. إذا لم يكن المستخدم موجودًا محليًا، قم بإنشائه.
      if (localUser == null) {
        print("User not found locally. Creating new local user entry...");
        final newUser = app_user.User.fromFirebase(firebaseUser);
        await _dbHelper.insert(DatabaseHelper.tableUsers, newUser.toMap());
        return newUser; // إرجاع كائن المستخدم الجديد.
      } else {
        print("User found locally. Returning existing local user.");
        // إذا كان موجودًا، قم بتحويله من Map إلى كائن `app_user.User` وأرجعه.
        return app_user.User.fromMap(localUser);
      }

    } on firebase.FirebaseAuthException catch (e) {
      return handleAuthError(e); // معالجة أخطاء المصادقة.
    } catch (e) {
      print("An unexpected error occurred during signInAndSyncUser: $e");
      return "حدث خطأ غير متوقع أثناء مزامنة المستخدم.";
    }
  }

  /// دالة `signInWithGoogle`: تقوم بتسجيل الدخول باستخدام جوجل ومزامنة البيانات.
  Future<dynamic> signInWithGoogle() async {
    try {
      // 1. بدء عملية تسجيل الدخول مع جوجل.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'تم إلغاء عملية تسجيل الدخول.';

      // 2. الحصول على بيانات المصادقة من جوجل.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. إنشاء بيانات اعتماد Firebase من بيانات جوجل.
      final firebase.OAuthCredential credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول إلى Firebase.
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return "فشل تسجيل الدخول باستخدام جوجل.";

      // 5. [مهم] مزامنة المستخدم مع قاعدة البيانات المحلية.
      var localUser = await _dbHelper.queryRow(DatabaseHelper.tableUsers, firebaseUser.uid);
      if (localUser == null) {
        // إذا كان المستخدم جديدًا، أنشئ له سجلاً محليًا.
        final newUser = app_user.User.fromFirebase(firebaseUser);
        await _dbHelper.insert(DatabaseHelper.tableUsers, newUser.toMap());
        return newUser;
      } else {
        // إذا كان المستخدم موجودًا بالفعل، أرجع بياناته المحلية.
        return app_user.User.fromMap(localUser);
      }
    } on firebase.FirebaseAuthException catch (e) {
      return handleAuthError(e);
    } catch (e) {
      print("An unexpected error occurred during Google Sign-In: $e");
      return "حدث خطأ غير متوقع أثناء تسجيل الدخول بجوجل.";
    }
  }

  /// دالة `createUserAccountAndSendVerification`: تنشئ المستخدم، ترسل رابط التفعيل، ثم تسجل الخروج.
  Future<void> createUserAccountAndSendVerification(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        print("AuthService: Verification email sent to ${userCredential.user!.email}.");
      }
      await signOut(); // تسجيل الخروج فورًا لضمان عدم الدخول قبل التفعيل.
      print("AuthService: User signed out immediately after registration.");
    } on firebase.FirebaseAuthException {
      rethrow; // إعادة رمي الخطأ ليتم التعامل معه في الواجهة.
    }
  }

  /// دالة `signOut`: تقوم بتسجيل الخروج من Firebase وجوجل.
  Future<void> signOut() async {
    await GoogleSignIn().signOut(); // تسجيل الخروج من جوجل.
    await _auth.signOut(); // تسجيل الخروج من Firebase.
  }

  /// دالة `handleAuthError`: تترجم رموز أخطاء Firebase إلى رسائل واضحة للمستخدم.
  String handleAuthError(firebase.FirebaseAuthException e) {
    print("Firebase Auth Error: ${e.code} - ${e.message}");
    switch (e.code) {
      case 'weak-password': return 'كلمة المرور ضعيفة جدًا (6 أحرف على الأقل).';
      case 'email-already-in-use': return 'هذا البريد الإلكتروني مستخدم بالفعل.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'network-request-failed': return 'فشل الاتصال بالشبكة. تحقق من اتصالك بالإنترنت.';
      default: return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  // --- دوال المصادقة برقم الهاتف ---

  /// دالة `sendOtpToPhone`: ترسل رمز التحقق إلى رقم هاتف معين.
  Future<void> sendOtpToPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(firebase.FirebaseAuthException e) onVerificationFailed,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async { await _auth.signInWithCredential(credential); },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// دالة `verifyOtpAndSignIn`: تتحقق من صحة الرمز وتسجل دخول المستخدم.
  Future<firebase.User?> verifyOtpAndSignIn(String verificationId, String smsCode) async {
    try {
      final credential = firebase.PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error verifying OTP: $e");
      return null;
    }
  }
}
