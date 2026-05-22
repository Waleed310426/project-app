import 'dart:convert'; // لتحويل البيانات من وإلى صيغة JSON.
import 'package:flutter/foundation.dart'; // للوصول إلى متغيرات مثل `kDebugMode`.
import 'package:get/get.dart'; // لاستخدام GetX لإدارة الحالة.
import 'package:http/http.dart' as http; // لإجراء طلبات الشبكة (API calls ).

import 'package:task_ly/helpers/database_helper.dart'; // للتعامل مع قاعدة البيانات المحلية.
import 'package:task_ly/chat_ai/ai_chat_message.dart'; // لاستخدام كلاس الرسالة.

/// ----------------------------
/// 1️⃣ تعريف مزودات الذكاء الاصطناعي
/// ----------------------------
// `enum` هو نوع خاص لتعريف مجموعة من الثوابت، هنا نستخدمه لتمثيل مزودي الخدمة.
enum AiProvider { openai, groq, huggingface, deepseek, openrouter }

/// ----------------------------
/// 2️⃣ كلاس الإعدادات العامة
/// ----------------------------
// هذا الكلاس يحتوي على جميع الإعدادات الثابتة المتعلقة بالـ API.
class AiConfig {
  // ترتيب محاولة الاتصال بالمزودين. إذا فشل الأول، يجرب الثاني وهكذا.
  static const providerSequence = [
    AiProvider.openai,
    AiProvider.deepseek,
    AiProvider.groq,
    AiProvider.huggingface,
    AiProvider.openrouter,
  ];

  // مفاتيح الـ API لكل مزود خدمة.
  // ⚠️ تحذير: لا تضع مفاتيح API الحقيقية هنا مباشرة.
  // استخدم متغيرات البيئة (Environment Variables) أو ملف .env آمن.
  static const apiKeys = {
    AiProvider.openai: 'YOUR_OPENAI_API_KEY_HERE',
    AiProvider.groq: 'YOUR_GROQ_API_KEY_HERE',
    AiProvider.huggingface: 'YOUR_HUGGINGFACE_API_KEY_HERE',
    AiProvider.openrouter: 'YOUR_OPENROUTER_API_KEY_HERE',
  };

  // روابط الـ API (Endpoints) التي يتم إرسال الطلبات إليها.
  static const endpoints = {
    AiProvider.openai: 'https://api.openai.com/v1/chat/completions',
    AiProvider.groq: 'https://api.groq.com/openai/v1/chat/completions',
    AiProvider.huggingface: 'https://api-inference.huggingface.co/models/',
    AiProvider.deepseek: 'https://api.deepseek.com/chat/completions',
    AiProvider.openrouter: 'https://openrouter.ai/api/v1/chat/completions',
  };

  // أسماء نماذج الذكاء الاصطناعي المستخدمة من كل مزود.
  static const models = {
    AiProvider.openai: 'gpt-4o-mini',
    AiProvider.groq: 'llama-3.1-70b-versatile',
    AiProvider.huggingface: 'tiiuae/falcon-7b-instruct',
    AiProvider.deepseek: 'deepseek-chat',
    AiProvider.openrouter: 'openai/gpt-4o',
  };
}

/// ----------------------------
/// 3️⃣ ChatController
/// ----------------------------
// هذا هو المتحكم الرئيسي (Controller ) الذي يدير منطق وحالة الدردشة.
class ChatController extends GetxController {
  // `obs` تجعل المتغير "مراقبًا". أي تغيير في قيمته سيؤدي تلقائيًا إلى تحديث الواجهة.
  var messages = <AiChatMessage>[].obs; // قائمة الرسائل في المحادثة.
  var isTyping = false.obs; // متغير لتحديد ما إذا كان الذكاء الاصطناعي "يكتب الآن".

  // الرسالة التوجيهية للنظام التي تحدد شخصية المساعد وسلوكه.
  var systemPrompt = 'أنت مساعد ذكي ومفيد، تجيب بالعربية باختصار وود. اسمك "تاسكلي".'.obs;
  final String conversationId = 'main_ai_chat'; // معرف فريد لهذه المحادثة.

  // هذه الدالة تُستدعى تلقائيًا عند إنشاء الـ Controller لأول مرة.
  @override
  void onInit() {
    super.onInit();
    loadMessages(); // تحميل الرسائل السابقة من قاعدة البيانات عند بدء التشغيل.
  }

  // دالة لتحميل الرسائل من قاعدة البيانات المحلية.
  Future<void> loadMessages() async {
    final dbHelper = DatabaseHelper.instance;
    final messageMaps = await dbHelper.getAiMessages(conversationId);
    // تحويل البيانات من صيغة Map إلى قائمة من كائنات `AiChatMessage`.
    messages.value = messageMaps.map((map) => AiChatMessage.fromMap(map)).toList();
  }

  /// ----------------------------
  /// 4️⃣ إرسال رسالة مع آلية التبديل بين المزودين
  /// ----------------------------
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return; // تجاهل الرسائل الفارغة.

    // 1. إنشاء رسالة المستخدم وإضافتها للواجهة ول قاعدة البيانات.
    final userMessage = AiChatMessage(
      conversationId: conversationId,
      content: text.trim(),
      isFromUser: true,
    );
    messages.add(userMessage);
    await DatabaseHelper.instance.insertAiMessage(userMessage.toMap());

    isTyping.value = true; // 2. إظهار مؤشر "يكتب الآن...".

    try {
      // 3. محاولة الحصول على رد من الذكاء الاصطناعي باستخدام آلية التبديل.
      final aiReply = await _sendMessageWithFallback(text.trim());

      // 4. عند وصول الرد، يتم إنشاء رسالة الـ AI وإضافتها للواجهة وقاعدة البيانات.
      final aiMessage = AiChatMessage(
        conversationId: conversationId,
        content: aiReply,
        isFromUser: false,
      );
      messages.add(aiMessage);
      await DatabaseHelper.instance.insertAiMessage(aiMessage.toMap());
    } catch (e) {
      // في حالة فشل جميع المزودين، يتم عرض رسالة خطأ.
      final errorMessage = AiChatMessage(
        conversationId: conversationId,
        content: '⚠️ عذرًا، حدث خطأ: $e',
        isFromUser: false,
      );
      messages.add(errorMessage);
    } finally {
      // 5. إخفاء مؤشر "يكتب الآن..." سواء نجح الطلب أو فشل.
      isTyping.value = false;
    }
  }

  /// ----------------------------
  /// 5️⃣ المحاولة مع المزودين بالتتابع (Fallback)
  /// ----------------------------
  Future<String> _sendMessageWithFallback(String userMessage) async {
    // حلقة `while` تجرب كل مزود في قائمة `providerSequence`.
    for (var provider in AiConfig.providerSequence) {
      try {
        // محاولة الحصول على رد من المزود الحالي.
        return await _getAiReply(provider, userMessage);
      } catch (e) {
        // إذا فشل، يتم طباعة الخطأ (في وضع التطوير) والانتقال للمزود التالي.
        if (kDebugMode) {
          print("⚠️ خطأ مع $provider: $e. المحاولة مع المزود التالي...");
        }
      }
    }
    // إذا فشلت جميع المحاولات، يتم إلقاء خطأ نهائي.
    throw Exception("🚫 جميع مزودي الخدمة غير متاحين حاليًا.");
  }

  /// ----------------------------
  /// 6️⃣ دالة الاتصال بالذكاء الاصطناعي (API Call)
  /// ----------------------------
  Future<String> _getAiReply(AiProvider provider, String userMessage) async {
    // جلب الإعدادات الخاصة بالمزود المحدد (مفتاح، رابط، موديل).
    final apiKey = AiConfig.apiKeys[provider];
    final endpoint = AiConfig.endpoints[provider];
    final model = AiConfig.models[provider];

    if (apiKey == null) throw Exception("🚫 لم يتم ضبط مفتاح API الخاص بـ $provider.");

    try {
      http.Response response;

      // HuggingFace له بنية طلب مختلفة قليلاً.
      if (provider == AiProvider.huggingface ) {
        response = await http.post(
          Uri.parse('$endpoint$model' ),
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode({"inputs": userMessage}),
        );
      } else {
        // بقية المزودين يتبعون بنية OpenAI القياسية.
        final body = {
          "model": model,
          "messages": [
            {"role": "system", "content": systemPrompt.value},
            {"role": "user", "content": userMessage},
          ],
        };
        final headers = {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'};
        
        // OpenRouter يتطلب Headers إضافية (اختيارية).
        if (provider == AiProvider.openrouter) {
          headers['HTTP-Referer'] = 'https://taskly.app'; // مثال
          headers['X-Title'] = 'Taskly App'; // مثال
        }

        response = await http.post(Uri.parse(endpoint! ), headers: headers, body: jsonEncode(body));
      }

      // تحليل الرد من الخادم.
      if (response.statusCode == 200) { // 200 يعني نجاح الطلب.
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        // كل مزود له بنية رد مختلفة، لذا نستخرج النص بناءً على المزود.
        switch (provider) {
          case AiProvider.openai:
          case AiProvider.groq:
          case AiProvider.deepseek:
          case AiProvider.openrouter:
            return decoded['choices'][0]['message']['content'].toString().trim();
          case AiProvider.huggingface:
            return decoded[0]['generated_text'].toString().trim();
        }
      } else {
        // التعامل مع أخطاء HTTP الشائعة.
        throw Exception("❌ خطأ من الخادم (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      // التقاط أي أخطاء أخرى قد تحدث أثناء الاتصال أو تحليل البيانات.
      rethrow; // إعادة إلقاء الخطأ ليتم التعامل معه في دالة `_sendMessageWithFallback`.
    }
  }

  /// ----------------------------
  /// 7️⃣ مسح المحادثة
  /// ----------------------------
  Future<void> clearConversation() async {
    // حذف الرسائل من قاعدة البيانات.
    await DatabaseHelper.instance.deleteAiConversation(conversationId);
    // مسح قائمة الرسائل من الذاكرة لتحديث الواجهة.
    messages.clear();
  }
}
