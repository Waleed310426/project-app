// lib/screens/task_details_screen.dart

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/details_tab.dart'; // تبويب التفاصيل (معاد استخدامه).
import '../widgets/project_tasks_tab.dart'; // تبويب المهام (معاد استخدامه لعرض المهام الفرعية).
import '../widgets/gantt_chart_tab.dart'; // تبويب مخطط جانت.
import '../widgets/expenses_tab.dart'; // تبويب المصروفات.
import '../widgets/attachments_tab.dart'; // تبويب المرفقات.
import '../widgets/chat_tab.dart'; // تبويب الدردشة.
import '../sheets/add_task_sheet.dart'; // ورقة سفلية لإضافة مهمة جديدة.

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض تفاصيل مهمة واحدة.
/// تشبه إلى حد كبير شاشة تفاصيل المشروع، ولكنها تتكيف لعرض بيانات المهمة.
/// تتميز بقدرتها على عرض تبويبات مختلفة بناءً على ما إذا كانت المهمة تحتوي على مهام فرعية أم لا.
class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> with SingleTickerProviderStateMixin {
  // --- إدارة الحالة (State Management) ---
  late TabController _tabController; // للتحكم في التبويبات.
  late Task _currentTask; // نسخة محلية من المهمة لتحديثها عند الحاجة.
  bool _hasSubtasks = false; // لتحديد ما إذا كانت المهمة تحتوي على مهام فرعية.

  @override
  void initState() {
    super.initState();
    // تهيئة المتغيرات المحلية.
    _currentTask = widget.task;
    // التحقق من وجود مهام فرعية بناءً على العدد القادم من نموذج المهمة.
    _hasSubtasks = widget.task.subtaskCount > 0;
    // تحديد عدد التبويبات بناءً على وجود مهام فرعية.
    final tabCount = _hasSubtasks ? 6 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  /// دالة `_handleDetailsUpdate`:
  /// دالة "callback" يتم تمريرها إلى `DetailsTab` لتحديث حالة المهمة في هذه الشاشة.
  void _handleDetailsUpdate(dynamic updatedItem) {
    if (updatedItem is Task) {
      setState(() {
        _currentTask = updatedItem; // تحديث المهمة الحالية، مما يعيد بناء الواجهة.
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // تنظيف الـ controller.
    super.dispose();
  }

  /// دالة `_getTabs`: تقوم ببناء قائمة التبويبات بشكل ديناميكي.
  List<Tab> _getTabs() {
    final tabs = [const Tab(text: 'التفاصيل')];
    // إذا كانت هناك مهام فرعية، أضف تبويبي "المهام الفرعية" و "المخطط".
    if (_hasSubtasks) {
      tabs.addAll([
        const Tab(text: 'المهام الفرعية'),
        const Tab(text: 'المخطط'),
      ]);
    }
    // أضف التبويبات المتبقية دائمًا.
    tabs.addAll([
      const Tab(text: 'المصروفات'),
      const Tab(text: 'المرفقات'),
      const Tab(text: 'الدردشة'),
    ]);
    return tabs;
  }

  /// دالة `_getTabViews`: تقوم ببناء قائمة محتويات التبويبات بشكل ديناميكي.
  List<Widget> _getTabViews() {
    if (_hasSubtasks) {
      // قائمة المحتويات الكاملة في حالة وجود مهام فرعية.
      return [
        DetailsTab(task: _currentTask, onDetailsUpdated: _handleDetailsUpdate),
        ProjectTasksTab(taskId: widget.task.id), // إعادة استخدام نفس الواجهة لعرض المهام الفرعية.
        GanttChartTab(taskId: widget.task.id),
        ExpensesTab(taskId: widget.task.id, budget: widget.task.budget),
        AttachmentsTab(taskId: widget.task.id),
        ChatTab(task: widget.task),
      ];
    } else {
      // قائمة المحتويات المختصرة في حالة عدم وجود مهام فرعية.
      return [
        DetailsTab(task: _currentTask, onDetailsUpdated: _handleDetailsUpdate),
        ExpensesTab(taskId: widget.task.id, budget: widget.task.budget),
        AttachmentsTab(taskId: widget.task.id),
        // عرض زر لإضافة أول مهمة فرعية بدلاً من تبويب الدردشة.
        Center(child: ElevatedButton.icon(onPressed: _showAddTaskSheet, icon: const Icon(Icons.add), label: const Text("إضافة أول مهمة فرعية"))),
      ];
    }
  }

  /// دالة لإظهار ورقة سفلية لإضافة مهمة فرعية جديدة.
  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(
        parentTask: widget.task,
        onTaskAdded: () {
          // TODO: يجب إعادة تحميل بيانات المهمة الرئيسية لتحديث `subtaskCount`
          // ثم إعادة بناء هذه الواجهة بالكامل.
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text(_currentTask.name), // استخدام المتغير المحدث هنا.
                pinned: true,
                floating: true,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: _getTabs(), // بناء التبويبات ديناميكيًا.
                  isScrollable: true,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: _getTabViews(), // بناء محتويات التبويبات ديناميكيًا.
          ),
        ),
        // زر عائم لإضافة مهمة فرعية جديدة.
        floatingActionButton: FloatingActionButton(
          heroTag: 'task_details_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddTaskSheet(
                parentTask: _currentTask,
                onTaskAdded: () {
                  // TODO: تحديث قائمة المهام الفرعية.
                },
              ),
            );
          },
          child: const Icon(Icons.add_task_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}
