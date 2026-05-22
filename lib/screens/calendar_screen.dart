// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
// استيراد مكتبة تقويم جوجل مع اسم مستعار `calendar` لتجنب التعارض.
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart'; // لتنسيق التواريخ والأوقات.
import 'package:task_ly/screens/event_edit_screen.dart'; // شاشة إضافة/تعديل حدث.
import 'package:task_ly/services/calendar_service.dart'; // الخدمة التي تتصل بـ Google Calendar API.

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض قائمة أحداث تقويم جوجل الخاصة بالمستخدم.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // --- إدارة الحالة (State Management) ---

  final CalendarService _calendarService = CalendarService(); // نسخة من خدمة التقويم.
  
  List<calendar.Event>? _events; // قائمة لتخزين الأحداث التي يتم جلبها من الـ API.
  bool _isLoading = true; // متغير لتحديد ما إذا كانت البيانات قيد التحميل لعرض مؤشر تحميل.
  String? _errorMessage; // لتخزين أي رسالة خطأ تحدث أثناء جلب البيانات.

  // `initState` هي أول دالة تُستدعى عند إنشاء الواجهة.
  @override
  void initState() {
    super.initState();
    _fetchEvents(); // بدء عملية جلب الأحداث فورًا عند فتح الشاشة.
  }

  /// دالة `_fetchEvents`: مسؤولة عن جلب قائمة الأحداث من `CalendarService`.
  Future<void> _fetchEvents() async {
    // إذا لم تكن البيانات قيد التحميل بالفعل، يتم تحديث الحالة لبدء التحميل.
    if (!_isLoading) {
      setState(() { _isLoading = true; _errorMessage = null; });
    }

    try {
      // محاولة جلب الأحداث من الخدمة.
      final events = await _calendarService.getEvents();
      // `if (mounted)`: للتأكد من أن الواجهة لا تزال موجودة في شجرة الويدجت قبل تحديث حالتها.
      if (mounted) {
        setState(() {
          _events = events; // تحديث قائمة الأحداث.
          _isLoading = false; // إيقاف مؤشر التحميل.
        });
      }
    } catch (e) {
      // في حالة حدوث خطأ.
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحديث البيانات. حاول مرة أخرى.'; // تعيين رسالة الخطأ.
          _isLoading = false; // إيقاف مؤشر التحميل.
        });
      }
    }
  }

  /// دالة `_refreshEvents`: تُستخدم لتحديث البيانات يدويًا (عند السحب للأسفل أو الضغط على زر التحديث).
  Future<void> _refreshEvents() async {
    await _fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الشريط العلوي للتطبيق.
      appBar: AppBar(
        title: const Text('أحداث تقويم جوجل'),
        actions: [
          // زر لتحديث قائمة الأحداث يدويًا.
          IconButton(
            icon: const Icon(Icons.refresh),
            // يتم تعطيل الزر إذا كانت البيانات قيد التحميل.
            onPressed: _isLoading ? null : _refreshEvents,
          ),
        ],
      ),
      // جسم الشاشة، يتم بناؤه بواسطة دالة `_buildBody`.
      body: _buildBody(),
      // زر عائم في الأسفل لإضافة حدث جديد.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // الانتقال إلى شاشة إضافة حدث جديد.
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const EventEditScreen()),
          );
          // إذا عادت الشاشة بنتيجة `true` (مما يعني أنه تم حفظ حدث جديد)، يتم تحديث القائمة.
          if (result == true) {
            _refreshEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// دالة `_buildBody`: مسؤولة عن بناء محتوى الشاشة بناءً على الحالة الحالية (تحميل، خطأ، بيانات فارغة، وجود بيانات).
  Widget _buildBody() {
    // **الحالة 1: التحميل**
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // **الحالة 2: وجود خطأ**
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('حاول مجدداً'),
            )
          ],
        ),
      );
    }

    // **الحالة 3: لا توجد أحداث**
    if (_events == null || _events!.isEmpty) {
      // `RefreshIndicator` يسمح للمستخدم بالسحب للأسفل لتحديث البيانات.
      return RefreshIndicator(
        onRefresh: _refreshEvents,
        child: ListView( // استخدام ListView للسماح بالسحب حتى لو كانت الشاشة فارغة.
          children: const [
            SizedBox(height: 150),
            Center(child: Text('لا توجد أحداث قادمة في تقويمك.', style: TextStyle(fontSize: 18, color: Colors.grey))),
          ],
        ),
      );
    }

    // **الحالة 4: وجود أحداث**
    final events = _events!;
    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final eventTitle = event.summary ?? ' (بدون عنوان)';
          
          // تنسيق وقت وتاريخ الحدث لعرضه بشكل مقروء.
          String eventTime;
          if (event.start?.dateTime != null) { // إذا كان للحدث وقت محدد.
            final startTime = event.start!.dateTime!.toLocal();
            eventTime = DateFormat('EEEE, d MMMM, hh:mm a', 'ar').format(startTime);
          } else if (event.start?.date != null) { // إذا كان الحدث ليوم كامل.
            final startDate = event.start!.date!.toLocal();
            eventTime = DateFormat('EEEE, d MMMM', 'ar').format(startDate);
          } else {
            eventTime = 'غير محدد';
          }

          // `Dismissible` هو ويدجت يسمح بسحب العنصر لحذفه.
          return Dismissible(
            key: Key(event.id!), // مفتاح فريد لكل عنصر.
            direction: DismissDirection.startToEnd, // السماح بالسحب من اليسار إلى اليمين فقط.
            // الخلفية التي تظهر أثناء السحب.
            background: Container(
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: const Row(children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
            ),
            // `confirmDismiss`: يُستدعى قبل الحذف الفعلي للسماح بعرض نافذة تأكيد.
            confirmDismiss: (direction) async {
              return await showDialog(/* ... نافذة تأكيد الحذف ... */);
            },
            // `onDismissed`: يُستدعى بعد تأكيد الحذف.
            onDismissed: (direction) async {
              final eventIdToDelete = event.id;
              if (eventIdToDelete == null) return;

              // حذف الحدث من القائمة في الواجهة أولاً لتوفير استجابة سريعة.
              final originalEvent = events.removeAt(index);
              setState(() {});

              // محاولة حذف الحدث من Google Calendar API.
              final success = await _calendarService.deleteEvent(eventIdToDelete);
              
              // التعامل مع نتيجة الحذف.
              if (mounted && !success) {
                // إذا فشل الحذف، يتم عرض رسالة خطأ وإرجاع العنصر إلى مكانه.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في حذف الحدث')));
                setState(() { events.insert(index, originalEvent); });
              } else if (mounted && success) {
                // إذا نجح الحذف، يتم عرض رسالة نجاح.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الحدث بنجاح')));
              }
            },
            // العنصر الفعلي الذي يتم عرضه في القائمة.
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.event_note_rounded, color: Colors.blue),
                title: Text(eventTitle),
                subtitle: Text(eventTime),
                // عند الضغط على الحدث، يتم الانتقال إلى شاشة التعديل.
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (context) => EventEditScreen(event: event)),
                  );
                  if (result == true) {
                    _refreshEvents();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
