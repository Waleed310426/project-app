// lib/widgets/gantt_chart_tab.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:intl/intl.dart'; // لتنسيق التواريخ.

// --- 2. استيراد ملفات المشروع ---
import '../helpers/database_helper.dart'; // للوصول إلى دوال قاعدة البيانات.
import '../models/task_model.dart'; // لاستخدام نموذج البيانات `Task`.

// =========================================================================
// الفئة الرئيسية: GanttChartTab
// =========================================================================
/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض مخطط "جانت" (Gantt Chart).
/// مخطط جانت هو تمثيل مرئي لجدول زمني للمشروع، يوضح تواريخ البدء والانتهاء للمهام.
/// تم تصميم هذه الواجهة لتكون مرنة، حيث يمكنها عرض المخطط لمشروع (`projectId`)
/// أو لمهمة رئيسية (`taskId`) لعرض مهامها الفرعية.
class GanttChartTab extends StatefulWidget {
  // --- الخصائص (Properties) ---
  final String? projectId; // معرف المشروع (إذا كان المخطط لمشروع).
  final String? taskId; // معرف المهمة (إذا كان المخطط لمهام فرعية).

  // --- المُنشئ (Constructor) ---
  const GanttChartTab({super.key, this.projectId, this.taskId})
      // `assert` يضمن أن أحد المعرفين قد تم تمريره، وإلا سيطلق خطأ أثناء التطوير.
      : assert(projectId != null || taskId != null);

  @override
  State<GanttChartTab> createState() => _GanttChartTabState();
}

// =========================================================================
// حالة الفئة الرئيسية: _GanttChartTabState
// =========================================================================
class _GanttChartTabState extends State<GanttChartTab> {
  // --- متغيرات الحالة (State Variables) ---
  List<Task> _tasks = []; // قائمة المهام التي سيتم عرضها في المخطط.
  bool _isLoading = true; // لتحديد ما إذا كانت البيانات قيد التحميل.
  DateTime? _chartStartDate; // تاريخ بدء المخطط (أقدم تاريخ بدء بين كل المهام).
  int _totalDays = 0; // إجمالي عدد الأيام التي يغطيها المخطط.

  // --- دورة حياة الواجهة (Lifecycle Methods) ---
  @override
  void initState() {
    super.initState();
    // عند بناء الواجهة لأول مرة، نبدأ عملية جلب البيانات وإعدادها.
    _loadAndPrepareData();
  }

  // --- الدوال المنطقية (Logic Functions) ---

  /// دالة `_loadAndPrepareData`: مسؤولة عن جلب المهام من قاعدة البيانات وإعداد بيانات المخطط.
  /// هي دالة `async` لأنها تنتظر نتيجة من قاعدة البيانات.
  Future<void> _loadAndPrepareData() async {
    List<Map<String, dynamic>> tasksData;
    // منطق ذكي: استدعاء الدالة المناسبة من `DatabaseHelper` بناءً على المعرف الممرر.
    if (widget.projectId != null) {
      tasksData = await DatabaseHelper.instance.getTasksForProject(widget.projectId!);
    } else {
      tasksData = await DatabaseHelper.instance.getTasksForTask(widget.taskId!);
    }

    // فلترة المهام:
    // 1. تحويل قائمة الـ `Map` إلى قائمة من كائنات `Task`.
    // 2. استبعاد أي مهمة ليس لها تاريخ بدء أو انتهاء.
    // 3. استبعاد أي مهمة تاريخ انتهائها قبل تاريخ بدئها.
    final validTasks = tasksData
        .map((map) => Task.fromMap(map))
        .where((task) => task.startDate != null && task.endDate != null && (task.endDate!.isAfter(task.startDate!) || task.endDate!.isAtSameMomentAs(task.startDate!)))
        .toList();

    // إذا لم تكن هناك مهام صالحة للعرض، أوقف التحميل واخرج.
    if (validTasks.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // حساب تاريخ بدء ونهاية المخطط الكلي.
    // نبدأ بافتراض أن تواريخ أول مهمة هي الأقدم والأحدث.
    DateTime minDate = validTasks.first.startDate!;
    DateTime maxDate = validTasks.first.endDate!;
    // ثم نمر على باقي المهام لتحديث هذه القيم.
    for (var task in validTasks) {
      if (task.startDate!.isBefore(minDate)) minDate = task.startDate!;
      if (task.endDate!.isAfter(maxDate)) maxDate = task.endDate!;
    }

    // تحديث حالة الواجهة بالبيانات الجديدة بعد التأكد من أن الواجهة لا تزال موجودة.
    if (mounted) {
      setState(() {
        _tasks = validTasks;
        _chartStartDate = minDate; // أقدم تاريخ هو تاريخ بدء المخطط.
        _totalDays = maxDate.difference(minDate).inDays + 1; // إجمالي الأيام.
        _isLoading = false; // إيقاف مؤشر التحميل.
      });
    }
  }

  // --- بناء الواجهة (UI Build Method) ---

  @override
  Widget build(BuildContext context) {
    // عرض مؤشر التحميل.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // عرض رسالة إذا لم تكن هناك مهام.
    if (_tasks.isEmpty) {
      return const Center(child: Text('لا توجد مهام لها تواريخ محددة لعرضها في المخطط.'));
    }

    // تعريف ثوابت لتسهيل التحكم في أبعاد المخطط.
    const double dayWidth = 50.0; // عرض كل يوم في المخطط.
    const double rowHeight = 50.0; // ارتفاع كل صف (مهمة).
    const double labelWidth = 150.0; // عرض عمود أسماء المهام.

    // استخدام `SingleChildScrollView` للسماح بالتمرير الأفقي للمخطط.
    // `reverse: true` يجعل التمرير يبدأ من اليمين (مناسب للغة العربية).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: SizedBox(
        // حساب العرض الكلي للمخطط.
        width: labelWidth + (_totalDays * dayWidth),
        // استخدام `ListView.builder` لبناء صفوف المخطط بكفاءة.
        child: ListView.builder(
          itemCount: _tasks.length + 1, // عدد المهام + صف الرأس.
          itemBuilder: (context, index) {
            // بناء صف الرأس (التواريخ).
            if (index == 0) {
              return _buildGanttHeader(labelWidth, dayWidth);
            }
            // بناء صف المهمة.
            final task = _tasks[index - 1];
            return _buildGanttRow(task, rowHeight, labelWidth, dayWidth);
          },
        ),
      ),
    );
  }

  /// ويدجت `_buildGanttHeader`: مسؤولة عن بناء صف الرأس الذي يعرض الأيام والتواريخ.
  Widget _buildGanttHeader(double labelWidth, double dayWidth) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          // الجزء الخاص بعنوان "المهام".
          SizedBox(width: labelWidth, child: const Center(child: Text('المهام', style: TextStyle(fontWeight: FontWeight.bold)))),
          // الجزء الخاص بعرض الأيام.
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // منع التمرير الداخلي.
              itemCount: _totalDays,
              itemBuilder: (context, dayIndex) {
                final date = _chartStartDate!.add(Duration(days: dayIndex));
                return Container(
                  width: dayWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
                  ),
                  child: Center(
                    child: Text(DateFormat('d\nMMM', 'ar').format(date), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت `_buildGanttRow`: مسؤولة عن بناء صف واحد في المخطط يمثل مهمة واحدة.
  Widget _buildGanttRow(Task task, double rowHeight, double labelWidth, double dayWidth) {
    // حساب الإزاحة (offset) لشريط المهمة من بداية المخطط.
    final offset = task.startDate!.difference(_chartStartDate!).inDays * dayWidth;
    // حساب عرض شريط المهمة.
    final barWidth = (task.endDate!.difference(task.startDate!).inDays + 1) * dayWidth;
    // حساب عرض شريط التقدم بناءً على نسبة الإنجاز.
    final progressWidth = barWidth * task.progress;
    // التحقق مما إذا كانت المهمة تستغرق يومًا واحدًا فقط.
    final isSameDay = task.startDate!.isAtSameMomentAs(task.endDate!);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5))),
      child: Row(
        children: [
          // الجزء الخاص باسم المهمة.
          SizedBox(width: labelWidth, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(task.name, overflow: TextOverflow.ellipsis))),
          // الجزء الخاص بالشريط الزمني للمهمة.
          Expanded(
            child: Stack(
              children: [
                // الشريط الخلفي الذي يمثل المدة الكاملة للمهمة.
                Positioned(
                  right: offset, // تحديد موقع الشريط من اليمين.
                  top: 10, bottom: 10,
                  child: Container(
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: isSameDay ? Colors.orange.withOpacity(0.4) : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // الشريط الأمامي الذي يمثل التقدم في المهمة.
                Positioned(
                  right: offset,
                  top: 10, bottom: 10,
                  child: Container(
                    width: progressWidth,
                    decoration: BoxDecoration(
                      color: isSameDay ? Colors.orange : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      // عرض نسبة الإنجاز داخل الشريط.
                      child: Text('${(task.progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.clip),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
