// lib/sheets/add_daily_task_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق الوقت.
import 'package:provider/provider.dart'; // للوصول إلى بيانات المستخدم.
import 'package:task_ly/helpers/database_helper.dart';
import 'package:task_ly/models/daily_task_model.dart';
import 'package:task_ly/providers/user_provider.dart';

/// هذه الواجهة (`StatefulWidget`) هي ورقة سفلية (Bottom Sheet) تُستخدم لإضافة مهمة يومية جديدة.
/// تظهر عندما يضغط المستخدم على زر إضافة مهمة في شاشة المهام اليومية.
class AddDailyTaskSheet extends StatefulWidget {
  final DateTime selectedDate; // التاريخ الذي تم اختياره لإضافة المهمة فيه.
  final Function onTaskAdded; // دالة "callback" تُستدعى بعد إضافة المهمة بنجاح.

  const AddDailyTaskSheet({
    super.key,
    required this.selectedDate,
    required this.onTaskAdded,
  });

  @override
  State<AddDailyTaskSheet> createState() => _AddDailyTaskSheetState();
}

class _AddDailyTaskSheetState extends State<AddDailyTaskSheet> {
  // --- إدارة الحالة (State Management) ---
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحكم في نموذج الإدخال.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startTime; // وقت بدء المهمة.
  DateTime? _endTime; // وقت انتهاء المهمة.
  bool _isSaving = false; // لتحديد ما إذا كانت عملية الحفظ قيد التنفيذ.

  @override
  void initState() {
    super.initState();
    // تهيئة وقت البدء الافتراضي.
    // يتم ضبطه على التاريخ المختار مع تقريب الدقائق الحالية لأقرب 5 دقائق للأعلى.
    final now = DateTime.now();
    _startTime = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, now.hour, (now.minute ~/ 5 + 1) * 5);
  }

  @override
  void dispose() {
    // تنظيف جميع وحدات التحكم عند إغلاق الشاشة.
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  /// دالة `_pickTime`: لإظهار منتقي الوقت (TimePicker) وتحديث وقت البدء أو الانتهاء.
  Future<void> _pickTime(bool isStartTime) async {
    final initialTime = TimeOfDay.fromDateTime((isStartTime ? _startTime : _endTime) ?? DateTime.now());
    final pickedTime = await showTimePicker(context: context, initialTime: initialTime);

    if (pickedTime != null) {
      setState(() {
        final date = widget.selectedDate;
        final newDateTime = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
        if (isStartTime) {
          _startTime = newDateTime;
          // إذا كان وقت الانتهاء قبل وقت البدء الجديد، يتم تعديله تلقائيًا.
          if (_endTime != null && _endTime!.isBefore(_startTime!)) {
            _endTime = _startTime!.add(const Duration(hours: 1));
          }
        } else {
          _endTime = newDateTime;
        }
      });
    }
  }

  /// دالة `_saveTask`: الدالة الرئيسية لحفظ المهمة الجديدة.
  Future<void> _saveTask() async {
    // التحقق من صحة المدخلات في النموذج.
    if (!_formKey.currentState!.validate()) {
      print("DEBUG (AddDailyTaskSheet): _saveTask -> Form is invalid. Aborting.");
      return;
    }
    
    setState(() => _isSaving = true);
    print("DEBUG (AddDailyTaskSheet): _saveTask -> Starting save process.");

    // الحصول على معرف المستخدم الحالي من `UserProvider`.
    final String? currentUserId = Provider.of<UserProvider>(context, listen: false).user?.id;

    if (currentUserId == null) {
      print("DEBUG (AddDailyTaskSheet): _saveTask -> FATAL: currentUserId is null. Aborting.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: جلسة المستخدم غير صالحة.')));
        setState(() => _isSaving = false);
      }
      return;
    }

    // إنشاء كائن `DailyTask` جديد بالبيانات المدخلة.
    final newTask = DailyTask.createNew(
      name: _nameController.text,
      ownerId: currentUserId,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      startTime: _startTime,
      endTime: _endTime,
      budget: double.tryParse(_budgetController.text),
    );

    try {
      // حفظ المهمة الجديدة في قاعدة البيانات.
      await DatabaseHelper.instance.saveDailyTask(newTask);
      print("DEBUG (AddDailyTaskSheet): _saveTask -> Task saved to DB successfully.");

      // إغلاق الـ Bottom Sheet بعد الحفظ.
      if (mounted) {
        print("DEBUG (AddDailyTaskSheet): _saveTask -> Popping the sheet.");
        Navigator.pop(context);
      }
      
      // استدعاء دالة الـ "callback" لإعلام الشاشة السابقة بحدوث تغيير.
      print("DEBUG (AddDailyTaskSheet): _saveTask -> Calling onTaskAdded callback.");
      widget.onTaskAdded();
      print("DEBUG (AddDailyTaskSheet): _saveTask -> onTaskAdded callback finished.");

    } catch (e) {
      debugPrint("DEBUG (AddDailyTaskSheet): _saveTask -> FATAL ERROR during save: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm('ar'); // تنسيق الوقت (مثل 10:30 ص).

    // استخدام `Padding` مع `viewInsets` لرفع المحتوى فوق لوحة المفاتيح عند ظهورها.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إضافة مهمة يومية جديدة', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              // حقل اسم المهمة.
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المهمة', icon: Icon(Icons.title)),
                validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال اسم للمهمة' : null,
              ),
              const SizedBox(height: 16),
              // حقل الوصف.
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف (اختياري)', icon: Icon(Icons.description_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // حقول اختيار الوقت.
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'وقت البدء', icon: Icon(Icons.play_circle_outline)),
                        child: Text(_startTime != null ? timeFormat.format(_startTime!) : 'حدد الوقت'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'وقت الانتهاء', icon: Icon(Icons.check_circle_outline)),
                        child: Text(_endTime != null ? timeFormat.format(_endTime!) : 'حدد الوقت'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // حقل الميزانية.
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'الميزانية (اختياري)', icon: Icon(Icons.attach_money), prefixText: 'ر.س '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 32),
              // زر الحفظ.
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTask,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ المهمة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
