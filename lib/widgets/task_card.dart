// lib/widgets/task_card.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:intl/intl.dart'; // لتنسيق الأرقام (كالعملات) والتواريخ.
import 'package:percent_indicator/linear_percent_indicator.dart'; // لعرض شريط التقدم الخطي.

// --- 2. استيراد ملفات المشروع ---
import '../helpers/database_helper.dart'; // للوصول إلى دوال قاعدة البيانات.
import '../models/task_model.dart'; // لاستخدام نموذج البيانات `Task`.

// =========================================================================
// الفئة الرئيسية: TaskCard
// =========================================================================
/// هذه الواجهة (`StatefulWidget`) هي المسؤولة عن عرض "بطاقة مهمة" واحدة.
/// تعرض تفاصيل المهمة الرئيسية مثل الاسم، التقدم، التواريخ، والحالة.
///
/// تم تصميمها لتكون `Stateful` لأنها تدير حالة داخلية خاصة بها، مثل:
/// - التحقق مما إذا كانت المهمة تحتوي على مهام فرعية.
/// - تحديث حالة المهمة (مثل المفضلة أو التقدم) بشكل مباشر من البطاقة.
class TaskCard extends StatefulWidget {
  // --- الخصائص (Properties) ---
  final Task task; // كائن المهمة الذي سيتم عرضه.
  final bool isSelected; // هل البطاقة محددة حاليًا (في وضع التحديد المتعدد).
  final Function(Task) onStateChanged; // دالة تُستدعى عند تغيير أي حالة في المهمة.

  // --- المُنشئ (Constructor) ---
  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onStateChanged,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

// =========================================================================
// حالة الفئة الرئيسية: _TaskCardState
// =========================================================================
class _TaskCardState extends State<TaskCard> {
  // --- متغيرات الحالة (State Variables) ---
  late Task _task; // نسخة محلية من المهمة لتسهيل التحديثات داخل البطاقة.
  bool? _isManuallyEditable; // هل يمكن تعديل تقدم المهمة يدويًا؟ (يكون null أثناء التحميل).

  // --- دورة حياة الواجهة (Lifecycle Methods) ---
  @override
  void initState() {
    super.initState();
    _task = widget.task;
    // عند بناء الواجهة، نبدأ بالتحقق مما إذا كانت المهمة لها مهام فرعية.
    _checkIfTaskHasSubtasks();
  }

  /// `didUpdateWidget` تُستدعى عندما يتم إعادة بناء الواجهة الأم (Parent) وتمرير `task` جديدة.
  /// هذا يضمن أن البطاقة تعرض دائمًا أحدث البيانات.
  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != oldWidget.task) {
      setState(() {
        _task = widget.task;
      });
    }
  }

  // --- الدوال المنطقية (Logic Functions) ---

  /// دالة `_checkIfTaskHasSubtasks`: تتحقق من قاعدة البيانات إذا كانت المهمة الحالية لها مهام فرعية.
  /// بناءً على النتيجة، تحدد ما إذا كان شريط التقدم قابلاً للتعديل اليدوي أم لا.
  /// (المنطق: إذا كانت هناك مهام فرعية، يجب أن يُحسب التقدم تلقائيًا منها).
  Future<void> _checkIfTaskHasSubtasks() async {
    final hasSubtasks = await DatabaseHelper.instance.taskHasSubtasks(_task.id);
    if (mounted) {
      setState(() {
        _isManuallyEditable = !hasSubtasks;
      });
    }
  }

  /// دالة `_updateTaskState`: دالة مركزية لتحديث حالة المهمة.
  /// تستقبل "إجراء" (Function) لتطبيقه على المهمة، ثم تحفظ التغييرات في قاعدة البيانات،
  /// وأخيرًا تستدعي `onStateChanged` لإبلاغ الواجهة الأم بالتحديث.
  Future<void> _updateTaskState(Function(Task t) action) async {
    action(_task); // تطبيق الإجراء (مثل `t.isFavorite = !t.isFavorite`).
    _task.modifiedAt = DateTime.now(); // تحديث وقت آخر تعديل.
    await DatabaseHelper.instance.updateTask(_task);
    widget.onStateChanged(_task); // إبلاغ الواجهة الأم.
  }

  /// دوال مساعدة لتحديد حالة المهمة والنص المعروض.
  String _getRemainingTimeStatus() { /* ... */ return 'الوقت المتبقي'; }
  (String, Color) _getTaskStatus() { /* ... */ return ('الحالة', Colors.blue); }

  // --- بناء الواجهة (UI Build Method) ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusText, statusColor) = _getTaskStatus();
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.س');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: widget.isSelected ? theme.colorScheme.primary : Colors.transparent, width: 1.5),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- السطر الأول: اسم المهمة وأزرار الإجراءات ---
            Row(
              children: [
                Expanded(child: Text(_task.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                // زر المفضلة.
                IconButton(icon: Icon(_task.isFavorite ? Icons.favorite : Icons.favorite_border, color: _task.isFavorite ? Colors.amber : null), onPressed: () => _updateTaskState((t) => t.isFavorite = !t.isFavorite), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                // قائمة منسدلة للإجراءات الأخرى (أرشفة، حذف).
                PopupMenuButton<String>(
                  onSelected: (value) { /* ... */ },
                  itemBuilder: (context) => [ /* ... */ ],
                  icon: const Icon(Icons.more_vert_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- شريط التقدم (قابل للتعديل أو للقراءة فقط) ---
            _buildProgressWidget(statusColor),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // --- معلومات إضافية (التواريخ، الميزانية، إلخ) ---
            if (_task.startDate != null && _task.endDate != null) ...[
              Row(children: [ /* ... */ ]),
              const SizedBox(height: 8),
            ],
            Row(children: [
              if (_task.budget != null) Expanded(child: InfoChip(icon: Icons.account_balance_wallet_outlined, text: 'الميزانية: ${currencyFormat.format(_task.budget)}')),
              if (_task.subtaskCount > 0) InfoChip(icon: Icons.splitscreen_rounded, text: '${_task.subtaskCount} مهام فرعية'),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InfoChip(icon: Icons.timelapse_rounded, text: _getRemainingTimeStatus()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            // ... (عرض المصروفات إذا وجدت) ...
          ],
        ),
      ),
    );
  }

  /// ويدجت `_buildProgressWidget`: يقرر أي نوع من مؤشرات التقدم يجب عرضه.
  Widget _buildProgressWidget(Color statusColor) {
    // إذا كنا لا نزال نتحقق من وجود مهام فرعية، اعرض مؤشر تحميل.
    if (_isManuallyEditable == null) {
      return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    
    // إذا كان قابلاً للتعديل اليدوي (لا توجد مهام فرعية)، اعرض شريط التمرير.
    // وإلا، اعرض شريط التقدم للقراءة فقط.
    return _isManuallyEditable!
        ? _buildEditableSlider(statusColor)
        : _buildReadOnlyIndicator(statusColor);
  }

  /// ويدجت `_buildEditableSlider`: لبناء شريط تمرير (Slider) قابل للتعديل.
  Widget _buildEditableSlider(Color statusColor) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _task.progress,
            // `onChanged` يُستدعى أثناء السحب لتحديث الواجهة فورًا.
            onChanged: (newProgress) => setState(() {
              _task.progress = newProgress;
              _task.isCompleted = newProgress >= 1.0;
            }),
            // `onChangeEnd` يُستدعى عند رفع الإصبع لحفظ القيمة النهائية في قاعدة البيانات.
            onChangeEnd: (newProgress) => _updateTaskState((t) {}),
            activeColor: statusColor,
          ),
        ),
        Text('${(_task.progress * 100).toInt()}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// ويدجت `_buildReadOnlyIndicator`: لبناء شريط تقدم للقراءة فقط.
  Widget _buildReadOnlyIndicator(Color statusColor) {
    return Row(
      children: [
        Expanded(
          child: LinearPercentIndicator(
            percent: _task.progress,
            lineHeight: 8.0,
            barRadius: const Radius.circular(4),
            progressColor: statusColor,
            backgroundColor: statusColor.withOpacity(0.2),
            isRTL: true, // لضمان أن الشريط يمتلئ من اليمين لليسار.
          ),
        ),
        const SizedBox(width: 12),
        Text('${(_task.progress * 100).toInt()}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// ويدجت مساعد: InfoChip
// =========================================================================
/// ويدجت بسيط وقابل لإعادة الاستخدام لعرض معلومة صغيرة (أيقونة + نص).
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoChip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
