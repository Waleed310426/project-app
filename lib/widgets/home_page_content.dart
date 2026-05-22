// lib/widgets/home_page_content.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية عند ظهور العناصر.

// =========================================================================
// الفئة الرئيسية: HomePageContent
// =========================================================================
/// هذه الواجهة (`StatelessWidget`) هي المسؤولة عن بناء المحتوى الرئيسي للصفحة الرئيسية.
/// تعرض شبكة من بطاقات المشاريع وقائمة بالمهام الحرجة.
///
/// تم تصميمها لتكون واجهة عرض ثابتة (Stateless) لأنها لا تدير أي حالة داخلية،
/// بل تقوم فقط بعرض بيانات وهمية (placeholder data) في هذا الإصدار.
class HomePageContent extends StatelessWidget {
  // --- المُنشئ (Constructor) ---
  const HomePageContent({super.key});

  // --- بناء الواجهة (UI Build Method) ---
  @override
  Widget build(BuildContext context) {
    // --- منطق التكيف مع حجم الشاشة (Responsive Logic) ---
    // الحصول على عرض الشاشة الحالي.
    final screenWidth = MediaQuery.of(context).size.width;
    // تحديد عدد الأعمدة في الشبكة بناءً على عرض الشاشة.
    // - 4 أعمدة للشاشات الكبيرة جدًا (أعرض من 1100 بكسل).
    // - 3 أعمدة للشاشات المتوسطة (أعرض من 720 بكسل).
    // - 2 أعمدة للشاشات الصغيرة (الهواتف).
    final crossAxisCount = screenWidth > 1100 ? 4 : (screenWidth > 720 ? 3 : 2);

    // استخدام `SingleChildScrollView` للسماح للمحتوى بالتمرير إذا تجاوز ارتفاع الشاشة.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر إلى بداية المحور الأفقي (اليمين في RTL).
        children: [
          // --- شبكة المشاريع ---
          // استخدام `FadeInUp` لإضافة تأثير ظهور من الأسفل للأعلى.
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // منع التمرير الداخلي للشبكة.
              shrinkWrap: true, // جعل الشبكة تأخذ الارتفاع الذي تحتاجه فقط.
              itemCount: 8, // عدد العناصر الوهمية.
              // `gridDelegate` يحدد كيفية ترتيب العناصر في الشبكة.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, // عدد الأعمدة.
                crossAxisSpacing: 12, // المسافة الأفقية بين البطاقات.
                mainAxisSpacing: 12, // المسافة الرأسية بين البطاقات.
                childAspectRatio: 1.1, // نسبة العرض إلى الارتفاع لكل بطاقة.
              ),
              // `itemBuilder` يبني كل بطاقة في الشبكة.
              itemBuilder: (context, i) {
                return _ProjectCard(
                  title: 'مشروع #${i + 1}',
                  progress: (i + 1) / 10,
                  subtitle: 'مهام قيد التنفيذ',
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // --- قسم المهام الحرجة ---
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200), // تأخير ظهور هذا القسم.
            child: _SectionHeader(title: 'المهام الحرجة'),
          ),
          const SizedBox(height: 12),
          // استخدام `...List.generate` لإنشاء قائمة من الويدجتس بشكل برمجي.
          ...List.generate(
            4, // إنشاء 4 عناصر وهمية.
            (i) => FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: Duration(milliseconds: 300 + i * 50), // تأخير متزايد لكل عنصر.
              child: _TaskTile(
                title: 'مهمة حرجة #${i + 1}',
                tag: i.isEven ? 'أولوية قصوى' : 'موعد قريب',
              ),
            ),
          ),
          const SizedBox(height: 80), // ترك مساحة في الأسفل للشريط السفلي العائم.
        ],
      ),
    );
  }
}

// =========================================================================
// ويدجتس مساعدة (Helper Widgets)
// =========================================================================

/// ويدجت `_ProjectCard`: مسؤولة عن بناء بطاقة مشروع واحدة في الشبكة.
class _ProjectCard extends StatelessWidget {
  final String title, subtitle;
  final double progress;

  const _ProjectCard({required this.title, required this.subtitle, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias, // لضمان أن تأثير الضغط لا يتجاوز الحواف الدائرية.
      child: InkWell(
        onTap: () {}, // يمكن إضافة منطق الانتقال لتفاصيل المشروع هنا.
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_copy_rounded, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1),
              const Spacer(), // يدفع شريط التقدم إلى أسفل البطاقة.
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ويدجت `_TaskTile`: مسؤولة عن بناء عنصر مهمة واحد في قائمة المهام الحرجة.
class _TaskTile extends StatelessWidget {
  final String title, tag;

  const _TaskTile({required this.title, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          // `Container` لعرض الوسم (Tag) الخاص بالمهمة.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(tag, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

/// ويدجت `_SectionHeader`: مسؤولة عن بناء عنوان لكل قسم مع خط فاصل.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(thickness: 0.5)), // خط فاصل يملأ المساحة المتبقية.
      ],
    );
  }
}
