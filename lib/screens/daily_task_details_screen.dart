// lib/screens/daily_task_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ والأوقات.
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية بسيطة.
import 'package:task_ly/helpers/database_helper.dart'; // للوصول إلى قاعدة البيانات.
import 'package:task_ly/models/daily_task_model.dart'; // استيراد نموذج المهمة اليومية.

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض تفاصيل مهمة يومية واحدة،
/// وتسمح للمستخدم بتعديل هذه التفاصيل.
class DailyTaskDetailsScreen extends StatefulWidget {
  final DailyTask task; // المهمة التي يتم عرضها، قادمة من الشاشة السابقة.
  
  // `onTaskUpdated` هي دالة "callback" تُستدعى بعد حفظ التغييرات،
  // لإعلام الشاشة السابقة بضرورة تحديث قائمتها.
  final VoidCallback onTaskUpdated;

  const DailyTaskDetailsScreen({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<DailyTaskDetailsScreen> createState() => _DailyTaskDetailsScreenState();
}

class _DailyTaskDetailsScreenState extends State<DailyTaskDetailsScreen> {
  // --- إدارة الحالة (State Management) ---

  late DailyTask _editableTask; // نسخة من المهمة قابلة للتعديل.
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحكم في نموذج الإدخال (Form).
  
  // Controllers لحقول النص.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  bool _isEditing = false; // متغير لتحديد ما إذا كانت الشاشة في "وضع التعديل".
  bool _hasChanges = false; // متغير لتتبع ما إذا كان المستخدم قد أجرى أي تغييرات.

  @override
  void initState() {
    super.initState();
    // عند بدء تشغيل الشاشة، يتم إنشاء نسخة قابلة للتعديل من المهمة الأصلية.
    // هذا يضمن أن التغييرات لا تؤثر على المهمة الأصلية إلا بعد الحفظ.
    _editableTask = DailyTask.fromMap(widget.task.toMap());
    _populateControllers(); // ملء حقول النص بالبيانات الحالية.
  }

  // دالة لملء حقول الإدخال ببيانات المهمة.
  void _populateControllers() {
    _nameController.text = _editableTask.name;
    _descriptionController.text = _editableTask.description ?? '';
    _budgetController.text = _editableTask.budget?.toString() ?? '';
  }

  // `dispose` تُستدعى عند إغلاق الشاشة لتنظيف الموارد (الـ Controllers).
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  /// دالة للتبديل بين وضع العرض ووضع التعديل.
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      // إذا خرج المستخدم من وضع التعديل دون حفظ، يتم استرجاع البيانات الأصلية.
      if (!_isEditing && _hasChanges) {
        _editableTask = DailyTask.fromMap(widget.task.toMap());
        _populateControllers();
        _hasChanges = false;
      }
    });
  }

  /// دالة لحفظ التغييرات التي أجراها المستخدم.
  Future<void> _saveChanges() async {
    // التحقق من صحة جميع الحقول في النموذج.
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // حفظ قيم الحقول.
      
      // تحديث بيانات المهمة القابلة للتعديل.
      _editableTask.name = _nameController.text;
      _editableTask.description = _descriptionController.text.isNotEmpty ? _descriptionController.text : null;
      _editableTask.budget = double.tryParse(_budgetController.text);
      _editableTask.modifiedAt = DateTime.now(); // تحديث وقت آخر تعديل.

      // حفظ المهمة المحدثة في قاعدة البيانات.
      await DatabaseHelper.instance.saveDailyTask(_editableTask);
      
      // استدعاء دالة الـ callback لإعلام الشاشة السابقة بحدوث تحديث.
      widget.onTaskUpdated();

      setState(() {
        _isEditing = false; // الخروج من وضع التعديل.
        _hasChanges = false;
        // تحديث بيانات المهمة الأصلية في هذه الشاشة لتعكس التغييرات.
        widget.task.name = _editableTask.name;
        // ... (تحديث باقي الخصائص)
      });

      // إظهار رسالة تأكيد للمستخدم.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التغييرات بنجاح'), backgroundColor: Colors.green),
        );
      }
    }
  }

  /// دالة لإظهار منتقي الوقت (Time Picker) وتحديث وقت البدء أو الانتهاء.
  Future<void> _pickTime(bool isStartTime) async {
    final initialTime = TimeOfDay.fromDateTime((isStartTime ? _editableTask.startTime : _editableTask.endTime) ?? DateTime.now());
    final pickedTime = await showTimePicker(context: context, initialTime: initialTime);

    if (pickedTime != null) {
      setState(() {
        final date = _editableTask.startTime ?? DateTime.now();
        final newDateTime = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
        if (isStartTime) {
          _editableTask.startTime = newDateTime;
        } else {
          _editableTask.endTime = newDateTime;
        }
        _hasChanges = true; // تم إجراء تغيير.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المهمة' : 'تفاصيل المهمة'),
        actions: [
          // إظهار زر الحفظ فقط في وضع التعديل.
          if (_isEditing)
            IconButton(icon: const Icon(Icons.save_alt_rounded), tooltip: 'حفظ', onPressed: _saveChanges),
          // تغيير أيقونة الزر بناءً على وضع التعديل.
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel_outlined : Icons.edit_rounded),
            tooltip: _isEditing ? 'إلغاء التعديل' : 'تعديل',
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: FadeIn( // تأثير ظهور تدريجي للمحتوى.
        child: Form(
          key: _formKey,
          onChanged: () { // تتبع أي تغيير في حقول النموذج.
            if (_isEditing) setState(() => _hasChanges = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // عرض حقل الإدخال (TextFormField) في وضع التعديل، أو عرض المعلومات (InfoTile) في وضع العرض.
              _isEditing
                  ? TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم المهمة'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null)
                  : _buildInfoTile(Icons.title_rounded, 'المهمة', _editableTask.name),
              const SizedBox(height: 20),

              _isEditing
                  ? TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 3)
                  : _buildInfoTile(Icons.description_outlined, 'الوصف', _editableTask.description ?? 'لا يوجد وصف'),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _isEditing ? _buildTimePickerField(true) : _buildInfoTile(Icons.play_arrow_rounded, 'وقت البدء', _formatTime(_editableTask.startTime))),
                  const SizedBox(width: 16),
                  Expanded(child: _isEditing ? _buildTimePickerField(false) : _buildInfoTile(Icons.flag_rounded, 'وقت الانتهاء', _formatTime(_editableTask.endTime))),
                ],
              ),
              const SizedBox(height: 20),

              _isEditing
                  ? TextFormField(controller: _budgetController, decoration: const InputDecoration(labelText: 'الميزانية', prefixText: 'ر.س '), keyboardType: TextInputType.number)
                  : _buildInfoTile(Icons.account_balance_wallet_outlined, 'الميزانية', _editableTask.budget != null ? '${_editableTask.budget} ر.س' : 'لم تحدد'),
              
              const Divider(height: 40),

              // عرض معلومات إضافية (للقراءة فقط).
              _buildInfoTile(Icons.calendar_today_rounded, 'تاريخ الإنشاء', _formatDateTime(_editableTask.createdAt), isSmall: true),
              const SizedBox(height: 12),
              _buildInfoTile(Icons.edit_calendar_rounded, 'آخر تعديل', _formatDateTime(_editableTask.modifiedAt), isSmall: true),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت مساعد لبناء مربع عرض المعلومات (للقراءة فقط).
  Widget _buildInfoTile(IconData icon, String label, String value, {bool isSmall = false}) {
    // ... (كود بناء واجهة عرض المعلومات)
    return Column(/* ... */);
  }

  /// ويدجT مساعد لبناء حقل اختيار الوقت.
  Widget _buildTimePickerField(bool isStartTime) {
    return InkWell(
      onTap: () => _pickTime(isStartTime),
      child: InputDecorator(
        decoration: InputDecoration(labelText: isStartTime ? 'وقت البدء' : 'وقت الانتهاء'),
        child: Text(_formatTime(isStartTime ? _editableTask.startTime : _editableTask.endTime)),
      ),
    );
  }

  // دوال مساعدة لتنسيق الوقت والتاريخ.
  String _formatTime(DateTime? date) {
    if (date == null) return 'لم يحدد';
    return DateFormat.jm('ar').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat.yMMMMd('ar').add_jm().format(date);
  }
}
