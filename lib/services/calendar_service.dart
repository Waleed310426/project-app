// lib/services/calendar_service.dart

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

/// هذا الكلاس (`GoogleAuthClient` ) هو عميل HTTP مخصص.
/// وظيفته هي إضافة هيدر المصادقة (Authentication Header) تلقائيًا إلى كل طلب يتم إرساله إلى Google API.
/// هذا يضمن أن كل طلب نرسله يكون مصادقًا عليه.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client( );

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request ) {
    // إضافة الهيدرز الخاصة بالمصادقة إلى هيدرز الطلب الأصلي.
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// هذا الكلاس (`CalendarService`) هو المسؤول عن كل عمليات التفاعل مع Google Calendar API.
/// يقوم بتغليف منطق المصادقة وجلب وإنشاء وتعديل وحذف الأحداث.
class CalendarService {
  /// نستخدم نسخة واحدة (`static final`) من `GoogleSignIn` مع تحديد صلاحية الوصول للتقويم.
  /// هذا يضمن أننا نطلب الصلاحية الصحيحة من المستخدم.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  /// دالة داخلية (`_getApi`) للحصول على نسخة جاهزة ومصادق عليها من `CalendarApi`.
  /// هذه الدالة هي قلب الخدمة، حيث تضمن أن كل طلب يتم إرساله يكون باستخدام توكن (token) حديث وصالح.
  Future<calendar.CalendarApi?> _getApi() async {
    try {
      // 1. محاولة تسجيل الدخول بصمت (إذا كان المستخدم قد سجل دخوله من قبل).
      var user = await _googleSignIn.signInSilently();
      // 2. إذا فشل تسجيل الدخول الصامت، اطلب من المستخدم تسجيل الدخول بشكل صريح.
      user ??= await _googleSignIn.signIn();

      // إذا رفض المستخدم تسجيل الدخول، أرجع null.
      if (user == null) return null;

      // 3. التأكد من أن المستخدم قد منح صلاحية الوصول للتقويم.
      final hasScope = await _googleSignIn.requestScopes([calendar.CalendarApi.calendarScope]);
      if (!hasScope) return null;

      // 4. الحصول على هيدرز المصادقة الحالية (التي تحتوي على التوكن).
      final headers = await _googleSignIn.currentUser?.authHeaders;
      if (headers == null) return null;

      // 5. إنشاء عميل HTTP مخصص مع هذه الهيدرز.
      final client = GoogleAuthClient(headers);
      // 6. إنشاء وإرجاع نسخة من `CalendarApi` باستخدام العميل المصادق عليه.
      return calendar.CalendarApi(client);
    } catch (e) {
      print("CalendarService._getApi error: $e");
      return null;
    }
  }

  /// دالة `getEvents`: لجلب قائمة الأحداث من التقويم الرئيسي للمستخدم.
  Future<List<calendar.Event>?> getEvents() async {
    final api = await _getApi();
    if (api == null) return null;

    final nowUtc = DateTime.now().toUtc();

    try {
      // استدعاء دالة `list` من API لجلب الأحداث.
      final eventsData = await api.events.list(
        "primary", // "primary" يشير إلى التقويم الرئيسي للمستخدم.
        singleEvents: true, // لعرض الأحداث المتكررة كأحداث فردية.
        orderBy: 'startTime', // ترتيب الأحداث حسب وقت البدء.
        timeMin: nowUtc.subtract(const Duration(days: 1)), // جلب الأحداث التي تبدأ من الأمس.
        maxResults: 100, // زيادة عدد النتائج لضمان ظهور الأحداث الجديدة.
        showDeleted: false, // عدم إظهار الأحداث المحذوفة.
      );
      return eventsData.items;
    } catch (e) {
      print("getEvents error: $e");
      return null;
    }
  }

  /// دالة `createEvent`: لإنشاء حدث جديد في التقويم.
  /// نرسل الوقت بصيغة UTC لتجنب المشاكل المتعلقة بالمناطق الزمنية المختلفة.
  Future<bool> createEvent(String title, DateTime startTime, DateTime endTime) async {
    final api = await _getApi();
    if (api == null) return false;

    // إنشاء كائن `Event` جديد بالبيانات المطلوبة.
    final newEvent = calendar.Event(
      summary: title,
      start: calendar.EventDateTime(dateTime: startTime.toUtc()),
      end: calendar.EventDateTime(dateTime: endTime.toUtc()),
    );

    try {
      // استدعاء دالة `insert` من API لإضافة الحدث.
      await api.events.insert(newEvent, "primary");
      return true; // إرجاع `true` عند النجاح.
    } catch (e) {
      print("createEvent error: $e");
      return false; // إرجاع `false` عند الفشل.
    }
  }

  /// دالة `updateEvent`: لتعديل حدث موجود بالفعل.
  /// يجب أن يحتوي الحدث المراد تعديله على معرف (`id`).
  Future<bool> updateEvent(calendar.Event eventToUpdate) async {
    final api = await _getApi();
    if (api == null || eventToUpdate.id == null) return false;

    try {
      // استدعاء دالة `update` من API لتحديث الحدث.
      await api.events.update(eventToUpdate, "primary", eventToUpdate.id!);
      return true;
    } catch (e) {
      print("updateEvent error: $e");
      return false;
    }
  }

  /// دالة `deleteEvent`: لحذف حدث موجود عبر معرفه (`eventId`).
  Future<bool> deleteEvent(String eventId) async {
    final api = await _getApi();
    if (api == null) return false;

    try {
      // استدعاء دالة `delete` من API لحذف الحدث.
      await api.events.delete("primary", eventId);
      return true;
    } catch (e) {
      print("deleteEvent error: $e");
      return false;
    }
  }
}
