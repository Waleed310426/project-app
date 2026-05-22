// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:provider/provider.dart'; // للوصول إلى الـ Providers.
import 'package:task_ly/controllers/theme_controller.dart'; // للتحكم في تغيير الثيم.
import 'package:task_ly/providers/user_provider.dart'; // للوصول إلى بيانات المستخدم.
import 'package:task_ly/screens/auth_wrapper.dart'; // للعودة إليه بعد تسجيل الخروج.
import 'package:task_ly/services/auth_service.dart'; // لتنفيذ عملية تسجيل الخروج.

/// هذه الواجهة (`StatelessWidget`) تمثل شاشة الإعدادات في التطبيق.
/// تعرض خيارات مختلفة للمستخدم مثل تعديل الحساب، تغيير المظهر، وتسجيل الخروج.
class SettingsScreen extends StatelessWidget {
  // `themeController` يتم تمريره من الواجهة الأم للتحكم في حالة الثيم.
  final ThemeController themeController;

  const SettingsScreen({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    // الحصول على بيانات الثيم الحالي وحالة المستخدم والخدمات.
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authService = AuthService();
    // `listen: false` لأننا لا نحتاج إلى إعادة بناء هذه الواجهة عند تغير بيانات المستخدم،
    // نحن فقط نحتاج إلى استدعاء دالة `clearUser` عند تسجيل الخروج.
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= القسم الأول: الحساب =================
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _SettingsSection(
                title: 'الحساب',
                children: [
                  _SettingsTile(icon: Icons.person_outline, title: 'تعديل الملف الشخصي', onTap: () {}),
                  _SettingsTile(icon: Icons.lock_outline, title: 'تغيير كلمة المرور', onTap: () {}),
                  _SettingsTile(icon: Icons.email_outlined, title: 'البريد الإلكتروني', subtitle: userProvider.user?.email ?? 'غير متوفر', onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= القسم الثاني: المظهر والتخصيص =================
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              child: _SettingsSection(
                title: 'المظهر والتخصيص',
                children: [
                  // --- مفتاح تبديل المظهر ---
                  ListTile(
                    contentPadding: const EdgeInsets.only(right: 16, left: 6),
                    leading: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: theme.colorScheme.primary),
                    title: Text('المظهر الداكن', style: theme.textTheme.titleMedium),
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (_) => themeController.toggle(),
                      activeColor: theme.colorScheme.primary,
                    ),
                    onTap: () => themeController.toggle(),
                  ),
                  _SettingsTile(icon: Icons.language_outlined, title: 'اللغة', subtitle: 'العربية', onTap: () {}),
                  _SettingsTile(icon: Icons.notifications_outlined, title: 'الإشعارات', onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= القسم الثالث: حول التطبيق =================
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              child: _SettingsSection(
                title: 'عن التطبيق',
                children: [
                  _SettingsTile(icon: Icons.info_outline, title: 'الإصدار', subtitle: '1.0.0', onTap: () {}),
                  _SettingsTile(icon: Icons.gavel_outlined, title: 'شروط الاستخدام', onTap: () {}),
                  _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'سياسة الخصوصية', onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- زر تسجيل الخروج ---
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              child: Center(
                child: TextButton.icon(
                  onPressed: () async {
                    // 1. استدعاء دالة تسجيل الخروج من AuthService.
                    await authService.signOut();

                    // 2. مسح بيانات المستخدم من الـ Provider لتنظيف الحالة.
                    userProvider.clearUser();

                    // 3. الانتقال إلى شاشة المصادقة مع حذف كل الشاشات السابقة.
                    // `AuthWrapper` سيقوم بهذا تلقائيًا، لكن استخدام `pushAndRemoveUntil`
                    // يضمن انتقالًا سلسًا وفوريًا دون رؤية الشاشة السابقة للحظة.
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت مساعد ومخصص لبناء كل قسم من أقسام الإعدادات.
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم (مثل "الحساب").
        Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        // استخدام `Card` لتجميع عناصر القسم مع تصميم موحد.
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias, // لقص الحواف الدائرية.
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// ويدجت مساعد ومخصص لبناء كل عنصر إعداد داخل القسم.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // بما أن التطبيق كله مغلف بـ `Directionality(textDirection: TextDirection.rtl)`,
    // فإن `ListTile` تلقائيًا تضع الـ `leading` في اليمين والـ `trailing` في اليسار.
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary), // `leading` سيظهر في اليمين.
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16), // `trailing` سيظهر في اليسار.
    );
  }
}
