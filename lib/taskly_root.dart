// lib/taskly_root.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:flutter/services.dart'; // للتحكم في واجهة المستخدم الخاصة بالنظام (شريط الحالة، شريط التنقل).
import 'package:get/get_navigation/src/root/get_material_app.dart'; // استبدال `MaterialApp` بـ `GetMaterialApp` للاستفادة من ميزات GetX.
import 'package:get/get_navigation/src/routes/get_route.dart'; // لتعريف الصفحات التي يديرها GetX.
import 'package:provider/provider.dart'; // للوصول إلى `ThemeController`.

// --- 2. استيراد ملفات المشروع ---
import 'package:task_ly/chat_ai/chat_ai_page.dart'; // شاشة الدردشة مع الذكاء الاصطناعي.
import 'package:task_ly/chat_ai/chat_binding.dart'; // ملف الربط (Binding) الخاص بشاشة الدردشة.
import 'package:task_ly/controllers/theme_controller.dart'; // للتحكم في مظهر التطبيق (داكن/فاتح).
import 'package:task_ly/taskly_home.dart'; // الشاشة الرئيسية للتطبيق.

// =========================================================================
// الفئة الرئيسية: TasklyRoot
// =========================================================================
/// هذه الواجهة (`StatelessWidget`) هي "جذر" التطبيق بعد تسجيل الدخول.
/// وظيفتها الأساسية هي:
/// 1. إعداد المظهر العام للتطبيق (Theme) بناءً على اختيار المستخدم (داكن/فاتح).
/// 2. التحكم في مظهر أشرطة النظام (شريط الحالة العلوي وشريط التنقل السفلي).
/// 3. استخدام `GetMaterialApp` بدلاً من `MaterialApp` لتمكين نظام التنقل وإدارة الحالة الخاص بـ GetX.
/// 4. تعريف الصفحات التي سيتم إدارتها بواسطة GetX (مثل شاشة الدردشة) وربطها بالـ `Bindings` الخاصة بها.
class TasklyRoot extends StatelessWidget {
  // --- المُنشئ (Constructor) ---
  const TasklyRoot({super.key});

  // --- بناء الواجهة (UI Build Method) ---
  @override
  Widget build(BuildContext context) {
    // --- إعداد المظهر وأشرطة النظام ---

    // 1. الوصول إلى `ThemeController` باستخدام `Provider`.
    // `context.watch` تجعل هذه الواجهة "تستمع" لأي تغييرات في `ThemeController`
    // وتعيد بناء نفسها عند حدوث تغيير (مثل تبديل المظهر).
    final themeController = context.watch<ThemeController>();
    final isDark = themeController.isDark;

    // 2. تحديث مظهر أشرطة النظام (شريط الحالة وشريط التنقل).
    // نحدد نمطًا مختلفًا لكل من المظهر الداكن والفاتح.
    final style = isDark
        ? SystemUiOverlayStyle.light.copyWith( // للمظهر الداكن: أيقونات فاتحة.
            statusBarColor: Colors.transparent, // شريط الحالة شفاف.
            systemNavigationBarColor: const Color(0xFF1A1C20), // لون شريط التنقل السفلي.
            systemNavigationBarIconBrightness: Brightness.light, // أيقونات شريط التنقل فاتحة.
          )
        : SystemUiOverlayStyle.dark.copyWith( // للمظهر الفاتح: أيقونات داكنة.
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          );
    // تطبيق النمط على النظام.
    SystemChrome.setSystemUIOverlayStyle(style);

    // --- بناء الواجهة الرئيسية للتطبيق ---

    // 3. استخدام `Directionality` لفرض اتجاه التطبيق من اليمين لليسار (RTL).
    return Directionality(
      textDirection: TextDirection.rtl,
      // 4. استخدام `GetMaterialApp` بدلاً من `MaterialApp`.
      // هذا لا يتعارض مع `Provider`، بل يضيف طبقة من الإمكانيات فوقه،
      // خصوصًا لإدارة التبعيات (Dependency Injection) والتنقل المتقدم.
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false, // إخفاء شريط "Debug" في الزاوية.
        title: 'تاسكلي',
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light, // تحديد وضع المظهر.
        theme: _buildTheme(Brightness.light), // تعريف المظهر الفاتح.
        darkTheme: _buildTheme(Brightness.dark), // تعريف المظهر الداكن.
        home: const TasklyHome(), // تحديد الشاشة الرئيسية التي تظهر عند بدء التشغيل.

        // 5. إضافة قائمة الصفحات التي يديرها GetX (`getPages`).
        // هذا هو المكان الذي نُعرّف فيه "المسارات" (Routes) للتطبيق.
        getPages: [
          GetPage(
            name: '/chatAI', // الاسم أو المسار الذي سنستخدمه للانتقال إلى هذه الصفحة.
            page: () => ChatAiPage(), // الدالة التي تقوم ببناء واجهة الصفحة.

            // `binding`: هذا هو الجزء الأقوى في GetX. الـ `Binding` هو بمثابة "فريق تجهيز"
            // يتم استدعاؤه **قبل** بناء الصفحة. مهمته هي تجهيز كل ما تحتاجه الصفحة لتعمل،
            // وأهمها هو الـ `Controller`.
            // عندما تنتقل إلى مسار `/chatAI`، سيقوم GetX تلقائيًا بإنشاء `ChatController`
            // ووضعه في الذاكرة ليكون جاهزًا للاستخدام فورًا داخل `ChatAiPage`.
            // هذا يسمى "حقن التبعيات" (Dependency Injection).
            binding: ChatBinding(),
          ),
          // يمكنك إضافة صفحات أخرى تستخدم GetX هنا في المستقبل.
        ],
      ),
    );
  }

  /// دالة `_buildTheme`: دالة مساعدة لبناء `ThemeData` (بيانات المظهر).
  /// تستقبل `Brightness` لتحديد ما إذا كان المظهر المطلوب فاتحًا أم داكنًا.
  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true, // تفعيل تصميم Material 3 الحديث.
      brightness: brightness,
      colorSchemeSeed: const Color(0xFF6366F1), // اللون الأساسي الذي سيتم توليد باقي الألوان منه.
      scaffoldBackgroundColor: isDark ? const Color(0xFF1A1C20) : const Color(0xFFF8F9FA),
      fontFamily: 'Tajawal', // تحديد الخط الافتراضي للتطبيق.
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1A1C20) : const Color(0xFFF8F9FA),
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
