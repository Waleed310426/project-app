// lib/widgets/drawer_content.dart

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.

/// كلاس بسيط يمثل عنصرًا واحدًا في القائمة الجانبية.
class DrawerItem {
  final String title;
  final IconData icon;
  const DrawerItem(this.title, this.icon);
}

/// هذه الواجهة (`StatelessWidget`) مسؤولة عن بناء محتوى القائمة الجانبية (Drawer).
/// تم تصميمها لتكون قابلة لإعادة الاستخدام، حيث تأخذ قائمة بالعناصر لعرضها.
class DrawerContent extends StatelessWidget {
  final List<DrawerItem> items; // قائمة العناصر التي سيتم عرضها.
  final String currentPageTitle; // عنوان الصفحة الحالية لتمييزها في القائمة.
  final ValueChanged<String> onItemSelected; // دالة "callback" تُستدعى عند اختيار عنصر.

  const DrawerContent({
    super.key,
    required this.items,
    required this.currentPageTitle,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // نغلف ويدجت الـ Drawer بأكملها بـ Directionality لفرض اتجاه من اليمين لليسار (RTL).
    // هذا يضمن أن كل العناصر داخل القائمة (مثل ListTile) ستتكيف مع هذا الاتجاه.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        // تحديد عرض القائمة ليكون 75% من عرض الشاشة.
        width: MediaQuery.of(context).size.width * 0.75,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- هيدر القائمة (الجزء العلوي) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: FadeInDown(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: Image.asset('assets/images/tasklyimage.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاسكلي',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'إدارة مهامك بذكاء',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- قائمة العناصر ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.title == currentPageTitle; // التحقق مما إذا كان هذا هو العنصر المحدد.

                    return FadeInRight(
                      delay: Duration(milliseconds: 100 + index * 30),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () => onItemSelected(item.title),
                          // بما أننا فرضنا RTL، فإن ListTile ستعمل بشكل صحيح:
                          // `leading` سيظهر في اليمين.
                          leading: Icon(
                            item.icon,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                          // `title` سيظهر في الوسط.
                          title: Center(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          // `trailing` سيظهر في اليسار.
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                          ),
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
