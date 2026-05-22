// lib/screens/project_details_screen.dart

import 'package:flutter/material.dart';
import 'package:task_ly/models/project_model.dart';
import 'package:task_ly/sheets/add_task_sheet.dart'; // ورقة سفلية لإضافة مهمة جديدة.
import 'package:task_ly/widgets/attachments_tab.dart'; // تبويب المرفقات.
import 'package:task_ly/widgets/chat_tab.dart'; // تبويب الدردشة.
import 'package:task_ly/widgets/details_tab.dart'; // تبويب التفاصيل.
import 'package:task_ly/widgets/expenses_tab.dart'; // تبويب المصروفات.
import 'package:task_ly/widgets/gantt_chart_tab.dart'; // تبويب مخطط جانت.
import 'package:task_ly/widgets/project_tasks_tab.dart'; // تبويب المهام.

/// هذه الواجهة (`StatefulWidget`) هي الشاشة الرئيسية لعرض تفاصيل مشروع واحد.
/// تحتوي على نظام تبويبات (Tabs) لعرض الجوانب المختلفة للمشروع (تفاصيل، مهام، دردشة، إلخ).
class ProjectDetailsScreen extends StatefulWidget {
  // `project`: كائن المشروع الذي يتم عرضه، يتم تمريره من الشاشة السابقة.
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

// استخدام `SingleTickerProviderStateMixin` ضروري لعمل الـ `TabController`
// الذي يحتاج إلى "Ticker" لإدارة حركات التبديل بين التبويبات.
class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with SingleTickerProviderStateMixin {
  // --- إدارة الحالة (State Management) ---
  late TabController _tabController; // للتحكم في التبويبات.
  late Project _currentProject; // نسخة محلية من المشروع لتحديثها عند الحاجة.

  // قائمة التبويبات التي ستظهر في الشريط العلوي.
  final List<Tab> _tabs = const [
    Tab(text: 'التفاصيل'),
    Tab(text: 'المهام'),
    Tab(text: 'المخطط'),
    Tab(text: 'المصروفات'),
    Tab(text: 'المرفقات'),
    Tab(text: 'الدردشة'),
  ];

  @override
  void initState() {
    super.initState();
    // تهيئة المتغير المحلي بنسخة المشروع القادمة من الـ widget.
    _currentProject = widget.project;
    // تهيئة الـ TabController بعدد التبويبات.
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    // تنظيف الـ TabController عند إغلاق الشاشة لمنع تسرب الذاكرة.
    _tabController.dispose();
    super.dispose();
  }

  /// دالة `_handleDetailsUpdate`:
  /// هذه دالة "callback" يتم تمريرها إلى تبويب التفاصيل (`DetailsTab`).
  /// عندما يقوم المستخدم بتعديل تفاصيل المشروع في `DetailsTab`، يتم استدعاء هذه الدالة
  /// لتحديث حالة المشروع في هذه الشاشة الرئيسية.
  void _handleDetailsUpdate(dynamic updatedItem) {
    // التحقق من أن العنصر المحدث هو من نوع `Project`.
    if (updatedItem is Project) {
      setState(() {
        // تحديث `_currentProject` بالبيانات الجديدة، مما يؤدي إلى إعادة بناء الواجهة
        // وعرض الاسم المحدث في الشريط العلوي على سبيل المثال.
        _currentProject = updatedItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // `NestedScrollView` يسمح بوجود شريط علوي (AppBar) قابل للتمرير
        // مع محتوى قابل للتمرير أيضًا (مثل قائمة المهام).
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // `SliverAppBar` هو شريط علوي مرن يمكن تثبيته أو إخفاؤه أثناء التمرير.
              SliverAppBar(
                title: Text(_currentProject.name), // استخدام المتغير المحدث هنا لعرض اسم المشروع.
                pinned: true, // تثبيت الشريط العلوي في الأعلى.
                floating: true, // جعل الشريط يظهر بمجرد التمرير لأعلى.
                // `bottom` هو الجزء السفلي من الشريط العلوي، وهنا نضع شريط التبويبات.
                bottom: TabBar(
                  controller: _tabController,
                  tabs: _tabs, // استخدام قائمة التبويبات المعرفة مسبقًا.
                  isScrollable: true, // السماح بتمرير التبويبات أفقيًا إذا كانت كثيرة.
                ),
              ),
            ];
          },
          // `body` الخاص بـ `NestedScrollView` يحتوي على `TabBarView`.
          body: TabBarView(
            controller: _tabController,
            // قائمة الواجهات (Widgets) التي تمثل محتوى كل تبويب.
            // يجب أن يكون ترتيبها مطابقًا لترتيب التبويبات في `TabBar`.
            children: [
              // 1. تبويب التفاصيل: تمرير المشروع الحالي ودالة التحديث.
              DetailsTab(project: _currentProject, onDetailsUpdated: _handleDetailsUpdate),
              // 2. تبويب المهام: تمرير معرف المشروع لجلب مهامه.
              ProjectTasksTab(projectId: _currentProject.id),
              // 3. تبويب مخطط جانت.
              GanttChartTab(projectId: _currentProject.id),
              // 4. تبويب المصروفات: تمرير الميزانية أيضًا لعرض معلومات المقارنة.
              ExpensesTab(projectId: _currentProject.id, budget: _currentProject.budget),
              // 5. تبويب المرفقات.
              AttachmentsTab(projectId: _currentProject.id),
              // 6. تبويب الدردشة.
              ChatTab(project: _currentProject),
            ],
          ),
        ),
        // زر عائم لإضافة مهمة جديدة.
        floatingActionButton: FloatingActionButton(
          heroTag: 'project_details_fab', // `heroTag` فريد لمنع التعارض مع أزرار أخرى.
          onPressed: () {
            // إظهار ورقة سفلية لإضافة مهمة جديدة.
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // للسماح للورقة بأخذ مساحة أكبر.
              backgroundColor: Colors.transparent,
              builder: (context) => AddTaskSheet(
                parentProject: _currentProject, // تمرير المشروع الحالي كأب للمهمة الجديدة.
                onTaskAdded: () {
                  // TODO: هنا يجب إضافة كود لتحديث قائمة المهام في `ProjectTasksTab`.
                },
              ),
            );
          },
          child: const Icon(Icons.add_task_rounded),
        ),
        // تحديد موقع الزر العائم في أسفل يسار الشاشة.
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}
