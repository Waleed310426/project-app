// lib/screens/project_details/tasks_tab.dart

import 'package:flutter/material.dart';

/// هذا الكلاس (Widget) يمثل محتوى تبويب "المهام" داخل شاشة تفاصيل المشروع.
/// حاليًا، هو مجرد واجهة مؤقتة (placeholder) تعرض نصًا بسيطًا.
class TasksTab extends StatelessWidget {
  // المُنشئ الخاص بالويدجت.
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    // `Center` لوضع المحتوى في منتصف الشاشة.
    return const Center(
      // `Text` لعرض رسالة للمطور أو المستخدم.
      child: Text(
        'تبويب قائمة المهام - سيتم بناؤه لاحقًا',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
