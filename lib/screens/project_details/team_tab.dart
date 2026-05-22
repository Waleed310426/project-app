// lib/screens/project_details/team_tab.dart

import 'package:flutter/material.dart';

/// هذا الكلاس (Widget) يمثل محتوى تبويب "فريق العمل" داخل شاشة تفاصيل المشروع.
/// حاليًا، هو مجرد واجهة مؤقتة (placeholder) تعرض نصًا بسيطًا.
class TeamTab extends StatelessWidget {
  // المُنشئ الخاص بالويدجت.
  const TeamTab({super.key});

  @override
  Widget build(BuildContext context) {
    // `Center` لوضع المحتوى في منتصف الشاشة.
    return const Center(
      // `Text` لعرض رسالة للمطور أو المستخدم.
      child: Text(
        'تبويب فريق العمل - سيتم بناؤه لاحقًا',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
