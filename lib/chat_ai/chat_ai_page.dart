// lib/chat_ai/chat_ai_page.dart

// استيراد مكتبات خارجية للتحريك والتأثيرات البصرية.
import 'package:animate_do/animate_do.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للتعامل مع حافظة النسخ (Clipboard).
import 'package:get/get.dart'; // لإدارة الحالة والتنقل.
import 'package:intl/intl.dart'; // لتنسيق التاريخ والوقت.
import 'package:task_ly/chat_ai/chat_controller.dart'; // استيراد المتحكم الخاص بالدردشة.
import 'package:task_ly/chat_ai/ai_chat_message.dart'; // استيراد كلاس الرسالة.

/// هذه هي الواجهة الرئيسية لصفحة الدردشة مع الذكاء الاصطناعي.
class ChatAiPage extends StatelessWidget {
  ChatAiPage({super.key});

  // --- تهيئة الـ Controllers ---
  // `chatController` لإدارة بيانات وحالة الدردشة (مثل قائمة الرسائل).
  final ChatController chatController = Get.find<ChatController>();
  // `_textController` للتحكم في حقل إدخال النص.
  final TextEditingController _textController = TextEditingController();
  // `_scrollController` للتحكم في قائمة الرسائل وتحريكها للأسفل.
  final ScrollController _scrollController = ScrollController();

  /// دالة لتحريك القائمة تلقائيًا إلى الأسفل لعرض آخر رسالة.
  void _scrollToBottom() {
    // يتم تنفيذ هذا الكود بعد اكتمال بناء الواجهة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) { // التأكد من أن القائمة جاهزة للتحريك.
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // الانتقال إلى أقصى نقطة في الأسفل.
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scrollToBottom(); // استدعاء دالة التمرير لأسفل مع كل بناء للواجهة.
    final theme = Theme.of(context); // للوصول إلى ألوان وتنسيقات التطبيق الحالية.

    return Scaffold(
      // الشريط العلوي للصفحة.
      appBar: AppBar(
        title: const Text('الدردشة الذكية'),
        actions: [
          // زر لحذف جميع رسائل المحادثة الحالية.
          IconButton(
            tooltip: 'مسح المحادثة',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              // إظهار نافذة تأكيد قبل الحذف.
              Get.defaultDialog(
                title: "تأكيد الحذف",
                middleText: "هل أنت متأكد من رغبتك في حذف هذه المحادثة بالكامل؟",
                textConfirm: "نعم، احذف",
                textCancel: "إلغاء",
                onConfirm: () {
                  chatController.clearConversation(); // استدعاء دالة الحذف من الـ Controller.
                  Get.back(); // إغلاق نافذة التأكيد.
                },
              );
            },
          ),
        ],
      ),
      // جسم الصفحة.
      body: Column(
        children: [
          // الجزء الذي يعرض الرسائل (يأخذ كل المساحة المتاحة).
          Expanded(
            // `Obx` من مكتبة GetX، يقوم بإعادة بناء هذا الجزء فقط عند تغير البيانات التي يراقبها.
            child: Obx(() {
              _scrollToBottom(); // التمرير لأسفل عند إضافة رسالة جديدة.
              // إذا كانت المحادثة فارغة والـ AI لا يكتب، يتم عرض رسالة ترحيبية.
              if (chatController.messages.isEmpty && !chatController.isTyping.value) {
                return const _WelcomeView();
              }
              // بناء قائمة الرسائل.
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                // عدد العناصر هو عدد الرسائل + 1 إذا كان الذكاء الاصطناعي يكتب حاليًا.
                itemCount: chatController.messages.length + (chatController.isTyping.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // إذا كان الذكاء الاصطناعي يكتب، يتم عرض مؤشر الكتابة في آخر القائمة.
                  if (chatController.isTyping.value && index == chatController.messages.length) {
                    return const _TypingIndicator();
                  }
                  // عرض فقاعة الرسالة العادية.
                  final message = chatController.messages[index];
                  return FadeInUp( // تأثير ظهور الرسالة من الأسفل للأعلى.
                    duration: const Duration(milliseconds: 300),
                    child: _MessageBubble(message: message),
                  );
                },
              );
            }),
          ),
          // شريط إدخال النص في الأسفل.
          _InputBar(
            textController: _textController,
            onSend: () {
              // التأكد من أن النص ليس فارغًا قبل الإرسال.
              if (_textController.text.trim().isNotEmpty) {
                chatController.sendMessage(_textController.text); // إرسال الرسالة عبر الـ Controller.
                _textController.clear(); // مسح حقل الإدخال.
                FocusScope.of(context).unfocus(); // إخفاء لوحة المفاتيح.
              }
            },
          ),
        ],
      ),
    );
  }
}

// --- ويدجتات مساعدة للواجهة ---

/// ويدجت لعرض رسالة ترحيبية عندما تكون المحادثة فارغة.
class _WelcomeView extends StatelessWidget {
  const _WelcomeView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn( // تأثير ظهور بسيط.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('مرحباً بك في الدردشة الذكية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('اسألني أي شيء يخطر في بالك!'),
          ],
        ),
      ),
    );
  }
}

/// ويدجت يمثل فقاعة الرسالة الواحدة (إما من المستخدم أو من الذكاء الاصطناعي).
class _MessageBubble extends StatelessWidget {
  final AiChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser; // هل الرسالة من المستخدم؟

    // تحديد الألوان والمحاذاة بناءً على مرسل الرسالة.
    final bubbleColor = isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final textColor = isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    // `GestureDetector` لإضافة تفاعل مع الفقاعة (هنا: النسخ عند الضغط المطول).
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.content)); // نسخ محتوى الرسالة.
        Get.snackbar('تم النسخ', 'تم نسخ نص الرسالة بنجاح.'); // إظهار رسالة تأكيد.
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          // محاذاة الفقاعة يمينًا للمستخدم ويسارًا للـ AI.
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // عرض أيقونة الذكاء الاصطناعي على اليسار.
            if (!isUser) ...[
              CircleAvatar(child: Icon(Icons.smart_toy_outlined, size: 20)),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: alignment,
                children: [
                  // جسم الفقاعة الفعلي.
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      // تحديد شكل حواف الفقاعة لتبدو كفقاعة دردشة.
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                    ),
                    // `SelectableText` يسمح للمستخدم بتحديد ونسخ النص.
                    child: SelectableText(message.content, style: TextStyle(color: textColor, fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  // عرض وقت إرسال الرسالة.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      DateFormat('hh:mm a', 'ar').format(message.createdAt), // تنسيق الوقت (مثال: 09:30 ص).
                      style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            // عرض أيقونة المستخدم على اليمين.
            if (isUser) ...[
              const SizedBox(width: 10),
              CircleAvatar(child: Icon(Icons.person_outline_rounded, size: 20)),
            ],
          ],
        ),
      ),
    );
  }
}

/// ويدجت شريط الإدخال السفلي الذي يحتوي على حقل النص وزر الإرسال.
class _InputBar extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSend; // دالة يتم استدعاؤها عند الضغط على زر الإرسال.

  const _InputBar({required this.textController, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // إضافة ظل خفيف فوق الشريط لتمييزه.
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
      ]),
      child: SafeArea( // لضمان عدم تداخل الواجهة مع عناصر النظام في أسفل الشاشة.
        child: Row(
          children: [
            // حقل إدخال النص.
            Expanded(
              child: TextField(
                controller: textController,
                minLines: 1,
                maxLines: 5, // السماح بتمدد الحقل لـ 5 أسطر.
                decoration: const InputDecoration.collapsed(hintText: 'اكتب رسالتك هنا...'),
                onSubmitted: (_) => onSend(), // الإرسال عند الضغط على "تم" في لوحة المفاتيح.
              ),
            ),
            const SizedBox(width: 8),
            // زر الإرسال.
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت لعرض مؤشر "يكتب الآن..." بشكل متحرك.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = theme.colorScheme.surfaceContainerHighest;
    final textColor = theme.colorScheme.onSurfaceVariant;

    return FadeIn( // تأثير ظهور بسيط.
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          // نفس تصميم فقاعة رسالة الذكاء الاصطناعي.
          children: [
            CircleAvatar(child: Icon(Icons.smart_toy_outlined, size: 20)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              // استخدام `AnimatedTextKit` لإنشاء تأثير كتابة متحرك.
              child: AnimatedTextKit(
                animatedTexts: [
                  WavyAnimatedText(
                    'يكتب الآن',
                    textStyle: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
                    speed: const Duration(milliseconds: 200),
                  ),
                ],
                isRepeatingAnimation: true, // تكرار الحركة باستمرار.
              ),
            ),
          ],
        ),
      ),
    );
  }
}
