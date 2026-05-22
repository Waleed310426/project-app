// lib/main.dart (النسخة النهائية الكاملة والصحيحة)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// --- استيراد ملفات المشروع ---
import 'package:task_ly/controllers/theme_controller.dart';
import 'package:task_ly/helpers/database_helper.dart';
import 'package:task_ly/providers/user_provider.dart';
import 'package:task_ly/screens/auth_wrapper.dart'; // استيراد AuthWrapper
import 'firebase_options.dart';

void main() async {
  // --- هذا الجزء صحيح 100% ولا يحتاج أي تغيير ---
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await DatabaseHelper.instance.database;
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  
  print("--- App Check activated in debug mode. ---");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام MultiProvider صحيح وممتاز
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (context) => ThemeController()..load(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(),
        ),
      ],
      // استخدام Consumer صحيح وممتاز
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          // بناء MaterialApp
          return MaterialApp(
            title: 'Taskly',
            
            // ✅✅✅ [التصحيح النهائي] ✅✅✅
            // هنا نستخدم الطريقة الصحيحة للتحكم في الثيم بناءً على متغير bool.
            
            // 1. حدد الثيم النهاري (الفاتح)
            theme: ThemeData.light().copyWith(
              // يمكنك إضافة تخصيصات للثيم الفاتح هنا
              // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),

            // 2. حدد الثيم الليلي (الداكن)
            darkTheme: ThemeData.dark().copyWith(
              // يمكنك إضافة تخصيصات للثيم الداكن هنا
              // colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
            ),

            // 3. استخدم متغير 'isDark' من الـ controller لتحديد الوضع الحالي
            // هذا هو السطر الذي يربط كل شيء ببعضه.
            themeMode: themeController.isDark ? ThemeMode.dark : ThemeMode.light,
            
            debugShowCheckedModeBanner: false,

            // نقطة البداية الصحيحة هي AuthWrapper
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
