// lib/screens/profile_screen.dart

// =========================================================================
// هذا الملف يحتوي على واجهة "شاشة الملف الشخصي".
// تم تصميمه ليكون عصريًا وجذابًا بصريًا، مع مراعاة اتجاه اليمين لليسار (RTL)
// والاستعداد للربط مع قاعدة بيانات مستقبلًا.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// ProfileScreen: الويدجت الرئيسية لصفحة الملف الشخصي.
///
/// تعرض معلومات المستخدم، إحصائياته، وإجراءات مرتبطة بحسابه.
class ProfileScreen extends StatelessWidget {
  // الكونستركتور (Constructor) الخاص بالويدجت.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // نصل إلى بيانات الثيم الحالي (الألوان، الخطوط، إلخ).
    // final theme = Theme.of(context);

    // نستخدم Scaffold كأساس للصفحة.
    // بما أن هذه الصفحة لها تصميمها الخاص، يمكننا إزالة AppBar من `main.dart`
    // عند عرضها، ولكن للتبسيط الآن، سنتركها كما هي.
    return Scaffold(
      body: SingleChildScrollView(
        // `SingleChildScrollView` يسمح للمستخدم بالتمرير.
        child: Column(
          children: [
            // =======================================================
            // 1. الجزء العلوي: بطاقة التعريف (Profile Header)
            // =======================================================
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _ProfileHeader(
                // [DB-Future]: هذه البيانات سيتم جلبها من قاعدة بيانات المستخدم.
                userName: 'اسم المستخدم',
                userEmail: 'user@example.com',
                // [DB-Future]: رابط صورة المستخدم.
                avatarUrl: 'https://example.com/avatar.png', // رابط وهمي
              ),
            ),

            // =======================================================
            // 2. قسم الإحصائيات السريعة
            // =======================================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // [DB-Future]: هذه الأرقام ستكون ديناميكية من قاعدة البيانات.
                    _StatItem(count: '12', label: 'مشاريع مكتملة'),
                    _StatItem(count: '86', label: 'مهام منجزة'),
                    _StatItem(count: '3', label: 'فرق نشطة'),
                  ],
                ),
              ),
            ),

            // =======================================================
            // 3. قائمة الإجراءات والخيارات
            // =======================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                    child: _ActionTile(
                      icon: Icons.groups_outlined,
                      title: 'الفرق والمجموعات',
                      onTap: () {},
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 250),
                    child: _ActionTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'الإنجازات والجوائز',
                      onTap: () {},
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                    child: _ActionTile(
                      icon: Icons.history_outlined,
                      title: 'سجل النشاط',
                      onTap: () {},
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 350),
                    child: _ActionTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'النسخ الاحتياطي للبيانات',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // مساحة إضافية في الأسفل.
          ],
        ),
      ),
    );
  }
}

/// _ProfileHeader: ويدجت مخصصة للجزء العلوي من صفحة الملف الشخصي.
///
/// تعرض صورة المستخدم واسمه وبريده الإلكتروني بتصميم جذاب.
class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String avatarUrl;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // تصميم الخلفية باستخدام تدرج لوني.
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
      child: Column(
        children: [
          // صورة المستخدم.
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            // [DB-Future]: سنستخدم `NetworkImage(avatarUrl)` هنا.
            // حاليًا نستخدم أيقونة كعنصر نائب.
            child: Icon(
              Icons.person,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // اسم المستخدم.
          Text(
            userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // البريد الإلكتروني للمستخدم.
          Text(
            userEmail,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// _StatItem: ويدجت صغيرة لعرض إحصائية واحدة (رقم وتسمية).
class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // الرقم (الإحصائية).
        Text(
          count,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // التسمية (الوصف).
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// _ActionTile: ويدجت مخصصة لعرض عنصر إجراء في القائمة.
///
/// تشبه `_SettingsTile` ولكن بتصميم يتناسب مع هذه الصفحة.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        // `leading` يظهر في اليمين في وضع RTL.
        leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
        // العنوان.
        title: Text(title, style: theme.textTheme.titleMedium),
        // `trailing` يظهر في اليسار في وضع RTL.
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
