// lib/chat_ai/chat_binding.dart

import 'package:get/get.dart';
import 'package:task_ly/chat_ai/chat_controller.dart';

/// هذا الكلاس هو "رابط" (Binding) خاص بوحدة الدردشة.
/// وظيفته هي إعداد وتجهيز الـ "Controllers" التي ستحتاجها واجهة الدردشة قبل عرضها.
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // `Get.lazyPut` هي طريقة "ذكية" لتسجيل الـ Controller في ذاكرة التطبيق.
    // "Lazy" (كسول) تعني أن `ChatController` لن يتم إنشاؤه فعليًا إلا عند أول مرة يتم استخدامه فيها
    // (على سبيل المثال، عند فتح صفحة الدردشة).
    // هذا يوفر من استهلاك الذاكرة، خاصة في التطبيقات الكبيرة.
    Get.lazyPut<ChatController>(() => ChatController());
  }
}
