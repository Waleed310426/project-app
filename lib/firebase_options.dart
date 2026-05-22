// lib/firebase_options.dart

// --- 1. ملاحظات عامة ---
// هذا الملف يتم إنشاؤه تلقائيًا بواسطة FlutterFire CLI (أداة سطر أوامر Firebase لـ Flutter).
// يحتوي هذا الملف على جميع معلومات التكوين اللازمة لربط تطبيق Flutter الخاص بك بمشروع Firebase
// على مختلف المنصات (Android, iOS, Web, macOS, Windows).
// **تحذير: لا تقم بتعديل هذا الملف يدويًا**، لأن أي تغييرات قد يتم الكتابة فوقها عند إعادة تشغيل أداة FlutterFire CLI.
// **تحذير أمني: هذا الملف يحتوي على مفاتيح API ومعرفات حساسة. كن حذرًا عند مشاركة الكود أو رفعه إلى مستودعات عامة.**

// --- 2. استيراد الحزم الأساسية ---
// استيراد حزمة Firebase Core للوصول إلى كلاس `FirebaseOptions`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// استيراد حزمة Flutter Foundation للوصول إلى متغيرات خاصة بالمنصة مثل `kIsWeb` و `defaultTargetPlatform`.
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// --- 3. الكلاس الرئيسي: DefaultFirebaseOptions ---
/// هذا الكلاس يوفر طريقة مركزية للوصول إلى إعدادات Firebase الصحيحة
/// بناءً على المنصة التي يعمل عليها التطبيق حاليًا.
///
/// المثال الموضح في التعليق الرسمي يبين كيفية استخدامه في ملف `main.dart`
/// لتهيئة Firebase عند بدء تشغيل التطبيق:
/// ```dart
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  /// `getter` ثابت (static) يُسمى `currentPlatform`.
  /// وظيفته هي تحديد المنصة الحالية التي يعمل عليها التطبيق وإرجاع
  /// كائن `FirebaseOptions` المناسب لها.
  static FirebaseOptions get currentPlatform {
    // أولاً، تحقق مما إذا كان التطبيق يعمل على الويب.
    if (kIsWeb) {
      return web; // إذا كان ويب، أرجع إعدادات الويب.
    }
    // إذا لم يكن ويب، استخدم `switch` على `defaultTargetPlatform` لتحديد المنصة.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android; // أرجع إعدادات أندرويد.
      case TargetPlatform.iOS:
        return ios; // أرجع إعدادات iOS.
      case TargetPlatform.macOS:
        return macos; // أرجع إعدادات macOS.
      case TargetPlatform.windows:
        return windows; // أرجع إعدادات Windows.
      case TargetPlatform.linux:
        // إذا كانت المنصة هي لينكس ولم يتم تكوينها، أطلق خطأ واضحًا.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        // لأي منصة أخرى غير مدعومة، أطلق خطأ عام.
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- 4. كائنات إعدادات Firebase لكل منصة ---

  /// `web`: كائن ثابت يحتوي على إعدادات Firebase الخاصة بمنصة الويب.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4u9jo1SdESd9XbWyk7RofWRJaWrXCxro', // مفتاح API لمصادقة الطلبات.
    appId: '1:741138206025:web:2fba01dea94ea57d95de98', // المعرف الفريد لتطبيق الويب داخل مشروع Firebase.
    messagingSenderId: '741138206025', // معرف مرسل الرسائل لخدمات مثل FCM (Firebase Cloud Messaging).
    projectId: 'taskly2-9707d', // المعرف الفريد لمشروع Firebase الخاص بك.
    authDomain: 'taskly2-9707d.firebaseapp.com', // النطاق المستخدم لمصادقة Firebase.
    storageBucket: 'taskly2-9707d.firebasestorage.app', // عنوان سحابة التخزين (Firebase Storage).
    measurementId: 'G-HN0T07D12P', // معرف القياس لـ Google Analytics.
  );

  /// `android`: كائن ثابت يحتوي على إعدادات Firebase الخاصة بمنصة أندرويد.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4xdVcXhKRXWkV90DNWTyGtEUQqBxhKrs', // مفتاح API الخاص بأندرويد.
    appId: '1:741138206025:android:e581d2c97a29ac6295de98', // المعرف الفريد لتطبيق أندرويد.
    messagingSenderId: '741138206025',
    projectId: 'taskly2-9707d',
    storageBucket: 'taskly2-9707d.firebasestorage.app',
  );

  /// `ios`: كائن ثابت يحتوي على إعدادات Firebase الخاصة بمنصة iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBkrErRKxI8_uMNOIZZwTwSOvUq2jNyRA8', // مفتاح API الخاص بـ iOS.
    appId: '1:741138206025:ios:f8638be506934aa295de98', // المعرف الفريد لتطبيق iOS.
    messagingSenderId: '741138206025',
    projectId: 'taskly2-9707d',
    storageBucket: 'taskly2-9707d.firebasestorage.app',
    iosBundleId: 'com.example.taskLy', // معرف الحزمة (Bundle ID) الخاص بتطبيقك على iOS.
  );

  /// `macos`: كائن ثابت يحتوي على إعدادات Firebase الخاصة بمنصة macOS.
  /// غالبًا ما تكون مشابهة لإعدادات iOS.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBkrErRKxI8_uMNOIZZwTwSOvUq2jNyRA8',
    appId: '1:741138206025:ios:f8638be506934aa295de98',
    messagingSenderId: '741138206025',
    projectId: 'taskly2-9707d',
    storageBucket: 'taskly2-9707d.firebasestorage.app',
    iosBundleId: 'com.example.taskLy',
  );

  /// `windows`: كائن ثابت يحتوي على إعدادات Firebase الخاصة بمنصة Windows.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB4u9jo1SdESd9XbWyk7RofWRJaWrXCxro',
    appId: '1:741138206025:web:16108e4d023ca17595de98',
    messagingSenderId: '741138206025',
    projectId: 'taskly2-9707d',
    authDomain: 'taskly2-9707d.firebaseapp.com',
    storageBucket: 'taskly2-9707d.firebasestorage.app',
    measurementId: 'G-Z9FG5MEMBR',
  );
}
