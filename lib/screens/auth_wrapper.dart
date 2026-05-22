// lib/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_ly/models/user_model.dart'; // استيراد نموذج المستخدم

// استيراد الملفات والخدمات والواجهات اللازمة.
import 'package:task_ly/providers/user_provider.dart';
import 'package:task_ly/screens/login_screen.dart';
import 'package:task_ly/services/auth_service.dart';
import 'package:task_ly/taskly_root.dart'; // الواجهة الرئيسية للتطبيق بعد تسجيل الدخول

/// هذا الكلاس (Widget) هو "المُغلّف" أو "المُنظّم" لعملية المصادقة (Authentication).
/// وظيفته الأساسية هي الاستماع لحالة تسجيل دخول المستخدم وتوجيهه إلى الشاشة المناسبة:
/// - إذا كان المستخدم مسجل دخوله، يتم توجيهه إلى الشاشة الرئيسية للتطبيق (`TasklyRoot`).
/// - إذا لم يكن مسجل دخوله، يتم توجيهه إلى شاشة تسجيل الدخول (`LoginScreen`).
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // إنشاء نسخة من خدمة المصادقة التي تتعامل مع Firebase.
    final authService = AuthService();

    // `StreamBuilder` هو ويدجت قوي في Flutter يقوم بإعادة بناء نفسه تلقائيًا
    // عند وصول بيانات جديدة من "Stream" (مجرى بيانات).
    return StreamBuilder<User?>(
      // `authService.user` هو الـ Stream الذي نستمع إليه.
      // هذا الـ Stream يُصدر قيمة جديدة (إما كائن المستخدم أو null) كلما تغيرت حالة المصادقة في Firebase.
      stream: authService.user,
      builder: (context, snapshot) {
        // `snapshot` يحتوي على أحدث قيمة وصلت من الـ Stream وحالة الاتصال.

        // **الحالة الأولى: انتظار البيانات**
        // إذا كان الـ Stream لا يزال يحمل البيانات الأولية.
        if (snapshot.connectionState == ConnectionState.waiting) {
          // يتم عرض شاشة تحميل (دائرة دوارة) في انتظار وصول الحالة النهائية.
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // **الحالة الثانية: المستخدم مسجل دخوله**
        // `snapshot.hasData` تعني أن الـ Stream أرسل قيمة ليست خطأ.
        // `snapshot.data != null` تؤكد أن القيمة هي كائن مستخدم وليست `null`.
        if (snapshot.hasData && snapshot.data != null) {
          // الحصول على بيانات المستخدم من الـ snapshot.
          final user = snapshot.data!;
          
          // تحديث بيانات المستخدم في `UserProvider` لتكون متاحة في جميع أنحاء التطبيق.
          // `listen: false` مهمة هنا لأننا داخل دالة `build` ولا نريد إعادة بناء هذا الويدجت عند تغير الـ Provider.
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          
          // **ملاحظة للمطور:** هنا يجب إضافة كود لجلب بيانات المستخدم الكاملة
          // من قاعدة البيانات المحلية (SQLite) أو السحابية (Firestore) وتمريرها إلى `setUser`.

          // توجيه المستخدم إلى الواجهة الرئيسية للتطبيق.
          return const TasklyRoot();
        } else {
          // **الحالة الثالثة: المستخدم غير مسجل دخوله**
          // إذا كانت البيانات `null`، فهذا يعني أن المستخدم قام بتسجيل الخروج أو لم يسجل دخوله بعد.
          // يتم توجيهه إلى شاشة تسجيل الدخول.
          return const LoginScreen();
        }
      },
    );
  }
}
