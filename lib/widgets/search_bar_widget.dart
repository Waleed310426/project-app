// lib/widgets/search_bar_widget.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.

// =========================================================================
// الفئة الرئيسية: SearchBarWidget
// =========================================================================
/// هذه الواجهة (`StatelessWidget`) هي عبارة عن "شريط بحث" قابل لإعادة الاستخدام.
/// تم تصميمها لتكون مرنة بحيث يمكن استخدامها في أي مكان في التطبيق يحتاج إلى وظيفة بحث.
///
/// تم تصميمها لتكون `Stateless` لأنها لا تدير أي حالة داخلية بنفسها،
/// بل تعتمد على `TextEditingController` الذي يتم تمريره من الخارج لإدارة النص.
class SearchBarWidget extends StatelessWidget {
  // --- الخصائص (Properties) ---

  /// `controller`: وحدة التحكم في النص. يتم تمريرها من الواجهة الأم (Parent Widget)
  /// للتحكم في النص داخل حقل البحث (قراءة النص، مسحه، إلخ).
  final TextEditingController controller;

  /// `hint`: النص التلميحي الذي يظهر داخل حقل البحث قبل أن يبدأ المستخدم في الكتابة.
  final String hint;

  /// `onSubmitted`: دالة اختيارية (`ValueChanged<String>`) تُستدعى عندما يضغط المستخدم
  /// على زر "تم" أو "إرسال" في لوحة المفاتيح. تمرر هذه الدالة النص الحالي في الحقل.
  final ValueChanged<String>? onSubmitted;

  // --- المُنشئ (Constructor) ---
  const SearchBarWidget({
    super.key,
    required this.controller, // `required` تضمن أن هذه القيمة يجب تمريرها.
    required this.hint,
    this.onSubmitted, // اختياري.
  });

  // --- بناء الواجهة (UI Build Method) ---
  @override
  Widget build(BuildContext context) {
    // الحصول على بيانات الثيم الحالي (الألوان، الخطوط، إلخ) لتكييف الواجهة.
    final theme = Theme.of(context);

    // استخدام ويدجت `TextField` كأساس لشريط البحث.
    return TextField(
      controller: controller, // ربط وحدة التحكم بالحقل.
      onSubmitted: onSubmitted, // ربط دالة الإرسال.

      // --- [التعديل الرئيسي] ---
      // تحديد اتجاه النص داخل الحقل ليكون من اليمين لليسار (RTL).
      // هذا يضمن أن مؤشر الكتابة يبدأ من اليمين وأن النص المكتوب يكون محاذيًا لليمين.
      textDirection: TextDirection.rtl,

      // `decoration` هو المسؤول عن مظهر الحقل (الأيقونات، الحواف، الألوان، إلخ).
      decoration: InputDecoration(
        // النص التلميحي.
        hintText: hint,
        // أيقونة تظهر في بداية الحقل (في اليمين في وضع RTL).
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        // تحديد أن الحقل يجب أن يكون له لون خلفية.
        filled: true,
        // لون خلفية الحقل.
        fillColor: theme.cardColor,
        // هوامش داخلية للمحتوى.
        contentPadding: const EdgeInsets.symmetric(vertical: 14),

        // --- تخصيص الحواف (Borders) ---

        // 1. `border`: الإطار الافتراضي للحقل في كل الحالات.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
        // 2. `enabledBorder`: الإطار عندما يكون الحقل مفعلاً ولكن ليس في حالة التركيز.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
        // 3. `focusedBorder`: الإطار عندما يكون الحقل في حالة التركيز (عندما يضغط عليه المستخدم).
        // نستخدم هنا اللون الأساسي للثيم لتمييزه.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
