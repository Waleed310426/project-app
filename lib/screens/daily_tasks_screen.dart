// lib/screens/daily_tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ.
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:provider/provider.dart'; // للوصول إلى بيانات المستخدم.
import 'package:table_calendar/table_calendar.dart'; // لعرض التقويم.
import 'package:task_ly/providers/user_provider.dart';
import '../models/daily_task_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/daily_task_card.dart'; // كرت عرض المهمة.
import '../sheets/add_daily_task_sheet.dart'; // شاشة إضافة مهمة جديدة.
import 'daily_task_details_screen.dart'; // شاشة تفاصيل المهمة.

// `enum` لتعريف أنواع الفلترة المتاحة لتسهيل قراءة الكود.
enum DailyTaskFilter { all, active, completed, favorite, archived, deleted }
// `enum` لتعريف أنواع الترتيب المتاحة.
enum DailyTaskSort { time, name, budget }

/// هذه الواجهة (`StatefulWidget`) هي الشاشة الرئيسية لعرض وإدارة المهام اليومية.
/// تستخدم `StatefulWidget` لأن محتواها (قائمة المهام، اليوم المختار، الفلاتر) يتغير باستمرار.
class DailyTasksScreen extends StatefulWidget {
  // `updateCounter` يُستخدم لإجبار الواجهة على إعادة التحميل عند الحاجة من واجهة خارجية.
  // عندما يتغير هذا الرقم، يتم استدعاء `didUpdateWidget` لإعادة تحميل البيانات.
  final int updateCounter;
  const DailyTasksScreen({super.key, required this.updateCounter});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  // --- إدارة الحالة (State Management) ---
  List<DailyTask> _allTasks = []; // قائمة بجميع المهام التي تم جلبها من قاعدة البيانات لهذا اليوم.
  List<DailyTask> _filteredTasks = []; // القائمة التي يتم عرضها للمستخدم بعد تطبيق الفلترة والترتيب.
  bool _isLoading = true; // متغير لتحديد ما إذا كانت البيانات قيد التحميل لعرض مؤشر الدوران.
  DateTime _focusedDay = DateTime.now(); // اليوم الذي يركز عليه التقويم (يتحكم في الشهر المعروض).
  DateTime _selectedDay = DateTime.now(); // اليوم الذي اختاره المستخدم لعرض مهامه.
  final _searchController = TextEditingController(); // للتحكم في حقل البحث.
  String _searchQuery = ''; // لتخزين نص البحث الحالي.
  DailyTaskFilter _currentFilter = DailyTaskFilter.all; // الفلتر الحالي المطبق على القائمة.
  DailyTaskSort _currentSort = DailyTaskSort.time; // الترتيب الحالي المطبق على القائمة.
  bool _isSelectionMode = false; // هل نحن في وضع التحديد المتعدد للمهام؟
  final Set<String> _selectedTaskIds = {}; // مجموعة لتخزين معرفات المهام المحددة.

  // --- دورة حياة الويدجت (Widget Lifecycle) ---
  @override
  void initState() {
    super.initState();
    print("DEBUG (DailyTasksScreen): initState called. Counter: ${widget.updateCounter}");
    // `addPostFrameCallback` يضمن أن الكود سيُنفذ بعد اكتمال بناء أول إطار للواجهة.
    // هذا يمنع الأخطاء التي قد تحدث عند محاولة الوصول إلى `context` قبل أن يكون جاهزًا.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("DEBUG (DailyTasksScreen): First frame callback. Loading initial data.");
      _loadTasksForSelectedDay();
    });
    // إضافة مستمع لحقل البحث لتحديث الواجهة مع كل تغيير في النص.
    _searchController.addListener(() {
      if (mounted) { // التأكد من أن الويدجت لا يزال في شجرة الويدجت.
        setState(() {
          _searchQuery = _searchController.text;
          _applyFilterAndSort();
        });
      }
    });
  }

  // `didUpdateWidget` تُستدعى عندما يتم تحديث الويدجت من الخارج (على سبيل المثال، عند تغيير `updateCounter`).
  @override
  void didUpdateWidget(covariant DailyTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("DEBUG (DailyTasksScreen): didUpdateWidget called. Old counter: ${oldWidget.updateCounter}, New counter: ${widget.updateCounter}");
    // إذا تغير `updateCounter`، فهذا يعني أن هناك طلبًا لإعادة تحميل البيانات.
    if (widget.updateCounter != oldWidget.updateCounter) {
      print("DEBUG (DailyTasksScreen): Counter changed! Reloading data.");
      _loadTasksForSelectedDay();
    }
  }

  @override
  void dispose() {
    print("DEBUG (DailyTasksScreen): dispose called. Widget is being removed.");
    _searchController.dispose(); // تنظيف الـ controller عند إغلاق الشاشة لتجنب تسرب الذاكرة.
    super.dispose();
  }

  // --- دوال البيانات والمنطق ---

  /// دالة `_loadTasksForSelectedDay`: مسؤولة عن جلب المهام من قاعدة البيانات لليوم المحدد.
  Future<void> _loadTasksForSelectedDay() async {
    print("DEBUG (DailyTasksScreen): _loadTasksForSelectedDay: Starting.");
    // جلب معرف المستخدم الحالي من `UserProvider`.
    final String? currentUserId = Provider.of<UserProvider>(context, listen: false).user?.id;

    if (currentUserId == null) {
      print("DEBUG (DailyTasksScreen): _loadTasksForSelectedDay -> FATAL: currentUserId is null. Aborting.");
      if (mounted) setState(() => _isLoading = false);
      return; // إيقاف العملية إذا لم يكن هناك مستخدم مسجل دخوله.
    }

    if (mounted) setState(() => _isLoading = true);
    _clearSelection(); // مسح أي تحديد سابق عند تحميل بيانات جديدة.
    try {
      // استدعاء دالة قاعدة البيانات لجلب المهام.
      _allTasks = await DatabaseHelper.instance.getDailyTasksForUser(currentUserId, _selectedDay);
      print("DEBUG (DailyTasksScreen): _loadTasksForSelectedDay: Fetched ${_allTasks.length} tasks from DB.");
      _applyFilterAndSort(); // تطبيق الفلترة والترتيب على البيانات الجديدة.
    } catch (e) {
      debugPrint("DEBUG (DailyTasksScreen): _loadTasksForSelectedDay -> ERROR: $e");
    } finally {
      if (mounted) {
        print("DEBUG (DailyTasksScreen): _loadTasksForSelectedDay: Finished, setting isLoading to false.");
        setState(() => _isLoading = false); // إيقاف التحميل سواء نجحت العملية أو فشلت.
      }
    }
  }

  /// دالة `_applyFilterAndSort`: تقوم بتصفية وترتيب قائمة المهام بناءً على اختيارات المستخدم.
  void _applyFilterAndSort() {
    List<DailyTask> tempTasks;
    // تطبيق الفلتر الرئيسي (المؤرشفة والمحذوفة لها الأولوية).
    switch (_currentFilter) {
      case DailyTaskFilter.archived: tempTasks = _allTasks.where((t) => t.isArchived && !t.isDeleted).toList(); break;
      case DailyTaskFilter.deleted: tempTasks = _allTasks.where((t) => t.isDeleted).toList(); break;
      default: tempTasks = _allTasks.where((t) => !t.isArchived && !t.isDeleted).toList();
    }
    // تطبيق الفلاتر الفرعية (نشطة، مكتملة، مفضلة) على القائمة المفلترة مسبقًا.
    if (_currentFilter != DailyTaskFilter.archived && _currentFilter != DailyTaskFilter.deleted) {
      switch (_currentFilter) {
        case DailyTaskFilter.completed: tempTasks = tempTasks.where((t) => t.isCompleted).toList(); break;
        case DailyTaskFilter.active: tempTasks = tempTasks.where((t) => !t.isCompleted).toList(); break;
        case DailyTaskFilter.favorite: tempTasks = tempTasks.where((t) => t.isFavorite).toList(); break;
        case DailyTaskFilter.all: default: break;
      }
    }
    // تطبيق البحث على القائمة المفلترة.
    if (_searchQuery.isNotEmpty) {
      tempTasks = tempTasks.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    // تطبيق الترتيب على القائمة النهائية.
    switch (_currentSort) {
      case DailyTaskSort.name: tempTasks.sort((a, b) => a.name.compareTo(b.name)); break;
      case DailyTaskSort.budget: tempTasks.sort((a, b) => (b.budget ?? 0).compareTo(a.budget ?? 0)); break;
      case DailyTaskSort.time: default: tempTasks.sort((a, b) => (a.startTime ?? a.createdAt).compareTo(b.startTime ?? b.createdAt)); break;
    }
    if (mounted) setState(() => _filteredTasks = tempTasks);
  }

  /// دالة للتبديل بين تحديد وإلغاء تحديد مهمة في وضع التحديد المتعدد.
  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _isSelectionMode = false; // الخروج من وضع التحديد إذا لم يتبق أي عنصر.
      } else {
        _selectedTaskIds.add(taskId);
        _isSelectionMode = true; // الدخول في وضع التحديد.
      }
    });
  }

  /// دالة لمسح جميع التحديدات والخروج من وضع التحديد.
  void _clearSelection() {
    if (mounted) setState(() {
      _selectedTaskIds.clear();
      _isSelectionMode = false;
    });
  }

  /// دالة لتنفيذ إجراء جماعي (Bulk Action) على المهام المحددة.
  Future<void> _performBulkAction(Function(DailyTask t) action) async {
    final tasksToUpdate = _allTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
    for (var task in tasksToUpdate) {
      action(task); // تطبيق الإجراء (مثل تغيير الحالة `isFavorite = true`).
      task.modifiedAt = DateTime.now();
      await DatabaseHelper.instance.saveDailyTask(task);
    }
    await _loadTasksForSelectedDay(); // إعادة تحميل البيانات لعرض التغييرات.
  }

  // --- دوال الواجهة (UI) ---

  /// دالة لإظهار ورقة سفلية (Bottom Sheet) تحتوي على التقويم.
  void _showCalendarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          locale: 'ar_SA', // تحديد اللغة العربية للتقويم.
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _loadTasksForSelectedDay(); // تحميل مهام اليوم الجديد المختار.
              });
            }
            Navigator.pop(context); // إغلاق الـ Bottom Sheet.
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// دالة لإظهار ورقة سفلية لإضافة مهمة جديدة.
  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // للسماح للـ Sheet بأخذ مساحة أكبر عند ظهور لوحة المفاتيح.
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => AddDailyTaskSheet(
        selectedDate: _selectedDay,
        onTaskAdded: () {
          Navigator.pop(context);
          _loadTasksForSelectedDay(); // إعادة تحميل المهام بعد إضافة مهمة جديدة.
        },
      ),
    );
  }

  /// دالة لتحديد عنوان الشريط العلوي بناءً على اليوم المختار أو وضع التحديد.
  String _getAppBarTitle() {
    if (_isSelectionMode) return '${_selectedTaskIds.length} تم تحديده';
    final now = DateTime.now();
    if (isSameDay(_selectedDay, now)) return 'مهام اليوم';
    if (isSameDay(_selectedDay, now.add(const Duration(days: 1)))) return 'مهام الغد';
    if (isSameDay(_selectedDay, now.subtract(const Duration(days: 1)))) return 'مهام الأمس';
    return DateFormat.yMMMMd('ar').format(_selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG (DailyTasksScreen): build method called. isLoading: $_isLoading, filteredTasks: ${_filteredTasks.length}");
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeaderControls(), // بناء شريط البحث والفلترة.
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? _buildEmptyState() // عرض واجهة "لا توجد مهام".
                    : _buildTasksList(), // عرض قائمة المهام.
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: null,
        notchMargin: 0,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // IconButton(icon: const Icon(Icons.add_circle_outline), iconSize: 30, tooltip: 'إضافة مهمة', onPressed: _showAddTaskDialog),
            IconButton(icon: const Icon(Icons.calendar_month_outlined), iconSize: 30, tooltip: 'اختيار اليوم', onPressed: _showCalendarPicker),
          ],
        ),
      ),
    );
  }

  /// دالة لبناء الشريط العلوي (AppBar) بناءً على وضع التحديد.
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_getAppBarTitle()),
      // إظهار زر الإغلاق في وضع التحديد، وإخفائه في الوضع العادي.
      leading: _isSelectionMode ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection) : null,
      // تبديل أزرار الإجراءات بناءً على وضع التحديد.
      actions: _isSelectionMode ? _buildSelectionActions() : _buildNormalActions(),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  /// بناء أزرار الإجراءات العادية في الشريط العلوي.
  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        icon: const Icon(Icons.today_rounded),
        tooltip: 'العودة لليوم',
        onPressed: () {
          if (!isSameDay(_selectedDay, DateTime.now())) {
            setState(() {
              _selectedDay = DateTime.now();
              _focusedDay = DateTime.now();
              _loadTasksForSelectedDay();
            });
          }
        },
      ),
    ];
  }

  /// بناء أزرار الإجراءات الجماعية في وضع التحديد.
  List<Widget> _buildSelectionActions() {
    return [
      IconButton(tooltip: 'تفضيل/إلغاء', icon: const Icon(Icons.favorite_border), onPressed: () => _performBulkAction((t) => t.isFavorite = !t.isFavorite)),
      IconButton(tooltip: 'أرشفة', icon: const Icon(Icons.archive_outlined), onPressed: () => _performBulkAction((t) => t.isArchived = true)),
      IconButton(tooltip: 'حذف', icon: const Icon(Icons.delete_outline), onPressed: () => _performBulkAction((t) => t.isDeleted = true)),
    ];
  }

  /// بناء شريط التحكم الذي يحتوي على البحث والفلترة والترتيب.
  Widget _buildHeaderControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث في مهام اليوم...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<DailyTaskSort>(
            onSelected: (sort) => setState(() { _currentSort = sort; _applyFilterAndSort(); }),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: DailyTaskSort.time, child: Text('حسب الوقت')),
              const PopupMenuItem(value: DailyTaskSort.name, child: Text('حسب الاسم')),
              const PopupMenuItem(value: DailyTaskSort.budget, child: Text('حسب الميزانية')),
            ],
          ),
          PopupMenuButton<DailyTaskFilter>(
            onSelected: (filter) => setState(() { _currentFilter = filter; _applyFilterAndSort(); }),
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: DailyTaskFilter.all, child: Text('الكل')),
              const PopupMenuItem(value: DailyTaskFilter.active, child: Text('النشطة')),
              const PopupMenuItem(value: DailyTaskFilter.completed, child: Text('المكتملة')),
              const PopupMenuItem(value: DailyTaskFilter.favorite, child: Text('المفضلة')),
              const PopupMenuItem(value: DailyTaskFilter.archived, child: Text('المؤرشفة')),
              const PopupMenuItem(value: DailyTaskFilter.deleted, child: Text('المحذوفة')),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء قائمة المهام باستخدام `ListView.builder` للأداء الأفضل.
  Widget _buildTasksList() {
    return RefreshIndicator(
      onRefresh: _loadTasksForSelectedDay, // تفعيل السحب للتحديث.
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          return FadeInUp( // تأثير حركة لكل عنصر عند ظهوره.
            from: 20,
            delay: Duration(milliseconds: index * 50),
            child: DailyTaskCard(
              task: task,
              isSelected: _selectedTaskIds.contains(task.id),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(task.id);
                } else {
                  // الانتقال إلى شاشة التفاصيل عند الضغط العادي.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyTaskDetailsScreen(
                        task: task,
                        onTaskUpdated: _loadTasksForSelectedDay, // تمرير دالة إعادة التحميل.
                      ),
                    ),
                  );
                }
              },
              onLongPress: () => _toggleSelection(task.id), // الدخول في وضع التحديد عند الضغط المطول.
              onStatusChanged: (updatedTask) {
                updatedTask.isCompleted = !updatedTask.isCompleted;
                updatedTask.modifiedAt = DateTime.now();
                DatabaseHelper.instance.saveDailyTask(updatedTask).then((_) {
                  if (mounted) setState(() => _applyFilterAndSort());
                });
              },
              onFavoriteChanged: (updatedTask) {
                updatedTask.isFavorite = !updatedTask.isFavorite;
                updatedTask.modifiedAt = DateTime.now();
                DatabaseHelper.instance.saveDailyTask(updatedTask).then((_) {
                  if (mounted) setState(() => _applyFilterAndSort());
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// بناء الواجهة التي تظهر عند عدم وجود مهام تطابق الفلترة أو البحث.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد مهام تطابق بحثك أو فلترتك',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب تغيير اليوم أو أضف مهمة جديدة!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
