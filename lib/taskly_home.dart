// lib/taskly_home.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart'; // لشريط التنقل السفلي المتحرك.
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // لزر الإضافة العائم متعدد الخيارات.
import 'package:get/get.dart'; // لإدارة التنقل بين الصفحات.
import 'package:provider/provider.dart'; // لإدارة الحالة والوصول للبيانات.

// --- 2. استيراد ملفات المشروع ---
// Controllers
import 'package:task_ly/controllers/theme_controller.dart';
// Screens
import 'package:task_ly/screens/calendar_screen.dart';
import 'package:task_ly/screens/daily_tasks_screen.dart';
import 'package:task_ly/screens/profile_screen.dart';
import 'package:task_ly/screens/projects_screen.dart';
import 'package:task_ly/screens/settings_screen.dart';
import 'package:task_ly/screens/tasks_screen.dart';
// Sheets (الواجهات السفلية)
import 'package:task_ly/sheets/add_daily_task_sheet.dart';
import 'package:task_ly/sheets/add_task_sheet.dart';
import 'package:task_ly/widgets/add_project_sheet.dart';
// Widgets (واجهات مساعدة)
import 'package:task_ly/widgets/drawer_content.dart';
import 'package:task_ly/widgets/home_page_content.dart';
import 'package:task_ly/widgets/placeholder_page_content.dart';
import 'package:task_ly/widgets/search_bar_widget.dart';

// =========================================================================
// الفئة الرئيسية: TasklyHome
// =========================================================================
/// هذه الواجهة (`StatefulWidget`) هي الشاشة الرئيسية للتطبيق.
/// تعمل كـ "حاوية" (Container) تنظم عرض الصفحات المختلفة، شريط التطبيق،
/// القائمة الجانبية (Drawer)، وشريط التنقل السفلي.
///
/// تم تصميمها لتكون `Stateful` لأنها تدير حالة التطبيق الرئيسية، مثل:
/// - الصفحة الحالية المعروضة (`_currentPageTitle`).
/// - الفهرس النشط في شريط التنقل السفلي (`_bottomNavIndex`).
/// - عدادات التحديث (`_updateCounter`) لإجبار الشاشات الفرعية على إعادة تحميل بياناتها.
class TasklyHome extends StatefulWidget {
  const TasklyHome({super.key});

  @override
  State<TasklyHome> createState() => _TasklyHomeState();
}

// =========================================================================
// حالة الفئة الرئيسية: _TasklyHomeState
// =========================================================================
class _TasklyHomeState extends State<TasklyHome> {
  // --- متغيرات الحالة (State Variables) ---

  // مفتاح للتحكم في `Scaffold` (مثل فتح القائمة الجانبية برمجيًا).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  // قوائم ثابتة لبيانات الواجهة.
  final List<DrawerItem> _drawerItems = const [ /* ... قائمة عناصر القائمة الجانبية ... */ ];
  final List<IconData> _bottomNavIcons = [ /* ... أيقونات شريط التنقل السفلي ... */ ];

  // متغيرات لتتبع الحالة الحالية.
  int _bottomNavIndex = 0; // الفهرس النشط في الشريط السفلي.
  String _currentPageTitle = 'الرئيسية'; // عنوان الصفحة الحالية.

  // عدادات التحديث: عند زيادة قيمة أي عداد، يتم إعادة بناء الواجهة التي تستخدمه.
  int _projectUpdateCounter = 0;
  int _taskUpdateCounter = 0;
  int _dailyTaskUpdateCounter = 0;

  // --- دورة حياة الواجهة (Lifecycle Methods) ---
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- الدوال المنطقية (Logic Functions) ---

  /// دالة `_onPageSelected`: تُستدعى عند اختيار عنصر من القائمة الجانبية.
  void _onPageSelected(String title) {
    setState(() {
      _currentPageTitle = title;
      // تحديث فهرس الشريط السفلي ليتوافق مع الصفحة المختارة.
      // ... (منطق تحديد `_bottomNavIndex`) ...
    });
    Navigator.of(context).pop(); // إغلاق القائمة الجانبية.
  }

  /// دالة `_onBottomNavTapped`: تُستدعى عند الضغط على أيقونة في الشريط السفلي.
  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      // تحديث عنوان الصفحة ليتوافق مع الأيقونة المختارة.
      switch (index) {
        case 0: _currentPageTitle = 'الرئيسية'; break;
        // ... (باقي الحالات) ...
      }
    });
  }

  /// دالة `_navigateToProjectsPage`: للانتقال إلى صفحة المشاريع برمجيًا.
  void _navigateToProjectsPage() { /* ... */ }

  // --- بناء الواجهة (UI Build Method) ---

  @override
  Widget build(BuildContext context) {
    // الوصول إلى `ThemeController` للاستماع للتغييرات وتبديل المظهر.
    final themeController = context.watch<ThemeController>();
    final theme = Theme.of(context);
    final isDark = themeController.isDark;

    return Scaffold(
      key: _scaffoldKey,
      // --- شريط التطبيق (AppBar) ---
      appBar: AppBar(
        title: FadeInDown(child: Text(_currentPageTitle)),
        actions: [ /* ... أزرار الإشعارات، تبديل المظهر، القائمة ... */ ],
        automaticallyImplyLeading: false, // إخفاء زر الرجوع التلقائي.
      ),
      // --- القائمة الجانبية (Drawer) ---
      endDrawer: DrawerContent(items: _drawerItems, currentPageTitle: _currentPageTitle, onItemSelected: _onPageSelected),
      // --- زر الإضافة العائم متعدد الخيارات (SpeedDial) ---
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        // ... (خصائص التصميم والحركة) ...
        children: [
          // زر إضافة مهمة يومية.
          SpeedDialChild(
            child: const Icon(Icons.check_circle_outline),
            label: 'مهمة يومية',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => AddDailyTaskSheet(
                  selectedDate: DateTime.now(),
                  onTaskAdded: () {
                    // عند إضافة مهمة بنجاح:
                    setState(() {
                      _currentPageTitle = 'المهام اليومية'; // انتقل إلى صفحة المهام اليومية.
                      _dailyTaskUpdateCounter++; // زد العداد لإجبار الصفحة على التحديث.
                      _bottomNavIndex = -1; // إلغاء تحديد أي أيقونة في الشريط السفلي.
                    });
                  },
                ),
              );
            },
          ),
          // زر إضافة مهمة كبيرة.
          SpeedDialChild(child: const Icon(Icons.assignment_outlined), label: 'مهمة كبيرة', onTap: () { /* ... */ }),
          // زر إضافة مشروع.
          SpeedDialChild(child: const Icon(Icons.create_new_folder_outlined), label: 'مشروع', onTap: () { /* ... */ }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // --- شريط التنقل السفلي (BottomNavigationBar) ---
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _bottomNavIcons.length,
        tabBuilder: (int index, bool isActive) { /* ... بناء كل أيقونة ... */ return Container(); },
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center, // تحديد مكان الفتحة للزر العائم.
        // ... (خصائص التصميم والظل) ...
        onTap: _onBottomNavTapped,
      ),
      // --- محتوى الصفحة الرئيسي ---
      body: Column(
        children: [
          // عرض شريط البحث فقط في الصفحة الرئيسية.
          if (_currentPageTitle == 'الرئيسية')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FadeInDown(child: SearchBarWidget(controller: _searchController, hint: 'ابحث في المشاريع والمهام...')),
            ),
          // استخدام `AnimatedSwitcher` لإضافة تأثير تلاشي عند التبديل بين الصفحات.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _buildPageContent(), // بناء محتوى الصفحة الحالية.
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت `_buildPageContent`: يقرر أي واجهة يجب عرضها بناءً على `_currentPageTitle`.
  Widget _buildPageContent() {
    Widget pageWidget;
    // استخدام `if-else if` لتحديد الواجهة المناسبة.
    if (_currentPageTitle == 'المشاريع') {
      // تمرير عداد التحديث إلى شاشة المشاريع.
      pageWidget = ProjectsScreen(updateCounter: _projectUpdateCounter);
    } else if (_currentPageTitle == 'المهام اليومية') {
      // تمرير عداد التحديث إلى شاشة المهام اليومية.
      pageWidget = DailyTasksScreen(updateCounter: _dailyTaskUpdateCounter);
    } 
    // ... (باقي الصفحات) ...
    else {
      // إذا لم تكن الصفحة مبنية بعد، اعرض واجهة العنصر النائب.
      final item = _drawerItems.firstWhere((item) => item.title == _currentPageTitle, orElse: () => _drawerItems.first);
      pageWidget = PlaceholderPageContent(key: ValueKey(_currentPageTitle), pageTitle: item.title, icon: item.icon);
    }
    // تغليف الواجهة بـ `Directionality` لضمان اتجاه RTL الصحيح.
    return Directionality(textDirection: TextDirection.rtl, child: pageWidget);
  }
}
