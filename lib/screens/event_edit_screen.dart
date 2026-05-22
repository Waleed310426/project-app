// lib/screens/event_edit_screen.dart

import 'package:flutter/material.dart';
// استيراد مكتبة تقويم جوجل مع اسم مستعار `calendar` لتجنب التعارض.
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:task_ly/services/calendar_service.dart'; // الخدمة التي تتصل بـ Google Calendar API.

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن إنشاء حدث جديد في تقويم جوجل أو تعديل حدث موجود.
class EventEditScreen extends StatefulWidget {
  // `event` هو الحدث الذي سيتم تعديله. إذا كان `null`، فهذا يعني أننا في وضع "إنشاء حدث جديد".
  final calendar.Event? event;

  const EventEditScreen({super.key, this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  // --- إدارة الحالة (State Management) ---
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحكم في نموذج الإدخال (Form).
  final _titleController = TextEditingController(); // للتحكم في حقل عنوان الحدث.
  final CalendarService _calendarService = CalendarService(); // نسخة من خدمة التقويم.

  // متغيرات لتخزين تاريخ ووقت البدء والانتهاء.
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  bool _isLoading = false; // لتحديد ما إذا كانت عملية الحفظ قيد التنفيذ.
  // `getter` بسيط لتحديد ما إذا كنا في وضع التعديل أم الإنشاء.
  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    
    // تهيئة قيم التاريخ والوقت بناءً على ما إذا كنا نعدل حدثًا موجودًا أو ننشئ حدثًا جديدًا.
    if (isEditing) {
      // وضع التعديل: ملء الحقول ببيانات الحدث القادم.
      _titleController.text = widget.event!.summary ?? '';
      _startDate = widget.event!.start?.dateTime?.toLocal() ?? DateTime.now();
      _startTime = TimeOfDay.fromDateTime(_startDate);
      _endDate = widget.event!.end?.dateTime?.toLocal() ?? _startDate.add(const Duration(hours: 1));
      _endTime = TimeOfDay.fromDateTime(_endDate);
    } else {
      // وضع الإنشاء: استخدام الوقت الحالي كقيم افتراضية.
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endDate = DateTime.now().add(const Duration(hours: 1));
      _endTime = TimeOfDay.fromDateTime(_endDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose(); // تنظيف الـ controller عند إغلاق الشاشة.
    super.dispose();
  }

  // --- دوال الواجهة والمنطق ---

  /// دالة لإظهار منتقي التاريخ (DatePicker) وتحديث تاريخ البدء أو الانتهاء.
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// دالة لإظهار منتقي الوقت (TimePicker) وتحديث وقت البدء أو الانتهاء.
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// دالة لحفظ الحدث (سواء كان جديدًا أو تحديثًا لحدث موجود).
  Future<void> _saveEvent() async {
    // التحقق من صحة حقل العنوان.
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; }); // بدء مؤشر التحميل.

    // دمج التاريخ والوقت في كائنات `DateTime` نهائية.
    final finalStartTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final finalEndTime = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

    // التحقق من أن وقت الانتهاء بعد وقت البدء.
    if (finalEndTime.isBefore(finalStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وقت الانتهاء يجب أن يكون بعد وقت البدء'), backgroundColor: Colors.red),
      );
      setState(() { _isLoading = false; });
      return;
    }

    bool success;
    if (isEditing) {
      // في وضع التعديل: تحديث بيانات الحدث الموجود.
      final eventToUpdate = widget.event!;
      eventToUpdate.summary = _titleController.text;
      eventToUpdate.start = calendar.EventDateTime(dateTime: finalStartTime.toUtc()); // يجب تحويل الوقت إلى UTC.
      eventToUpdate.end = calendar.EventDateTime(dateTime: finalEndTime.toUtc());
      
      success = await _calendarService.updateEvent(eventToUpdate);
    } else {
      // في وضع الإنشاء: استدعاء دالة إنشاء حدث جديد.
      success = await _calendarService.createEvent(
        _titleController.text,
        finalStartTime,
        finalEndTime,
      );
    }

    // التعامل مع نتيجة العملية بعد انتهائها.
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تعديل الحدث بنجاح!' : 'تم إنشاء الحدث بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        // العودة إلى الشاشة السابقة مع إرسال `true` لإعلامها بحدوث تغيير.
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'فشل في تعديل الحدث.' : 'فشل في إنشاء الحدث.'), backgroundColor: Colors.red),
        );
      }
      setState(() { _isLoading = false; }); // إيقاف مؤشر التحميل.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل الحدث' : 'إضافة حدث جديد'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveEvent, // تعطيل الزر أثناء التحميل.
              child: _isLoading 
                  // إظهار مؤشر تحميل داخل الزر.
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                  : const Text('حفظ'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView( // للسماح بالتمرير إذا كانت الشاشة صغيرة.
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل إدخال عنوان الحدث.
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الحدث',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 24),
              
              // قسم اختيار وقت البدء.
              const Text('وقت البدء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextButton.icon(icon: const Icon(Icons.calendar_today), label: Text('${_startDate.year}/${_startDate.month}/${_startDate.day}'), onPressed: () => _selectDate(context, true))),
                  Expanded(child: TextButton.icon(icon: const Icon(Icons.access_time), label: Text(_startTime.format(context)), onPressed: () => _selectTime(context, true))),
                ],
              ),
              const SizedBox(height: 16),

              // قسم اختيار وقت الانتهاء.
              const Text('وقت الانتهاء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextButton.icon(icon: const Icon(Icons.calendar_today), label: Text('${_endDate.year}/${_endDate.month}/${_endDate.day}'), onPressed: () => _selectDate(context, false))),
                  Expanded(child: TextButton.icon(icon: const Icon(Icons.access_time), label: Text(_endTime.format(context)), onPressed: () => _selectTime(context, false))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
