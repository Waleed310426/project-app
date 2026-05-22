import 'dart:convert'; // لاستخدام دوال `json.encode` و `json.decode`.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // لإجراء طلبات الشبكة (API calls ).

// نقطة بداية تشغيل التطبيق.
void main() => runApp(MyApp());

/// هذا الكلاس (Service) مسؤول عن التواصل مع OpenAI API.
/// يحتوي على المنطق الخاص بإرسال الرسائل واستقبال الردود.
class ChatService {
  // مفتاح الـ API الخاص بك من OpenAI. **مهم: يجب استبدال "YOUR_API_KEY" بالمفتاح الفعلي**.
  final String apiKey = "YOUR_API_KEY";

  /// دالة لإرسال رسالة إلى OpenAI والحصول على الرد.
  Future<String> sendMessage(String message) async {
    // رابط الـ API الخاص بنماذج الدردشة في OpenAI.
    final url = Uri.parse('https://api.openai.com/v1/chat/completions' );

    // `headers` تحتوي على معلومات إضافية للطلب،
    // أهمها نوع المحتوى ومفتاح المصادقة (Authorization).
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey', // يجب أن تبدأ بكلمة "Bearer" ثم مسافة ثم المفتاح.
    };

    // `body` هو جسم الطلب الذي يحتوي على البيانات المرسلة إلى الـ API.
    final body = json.encode({
      'model': 'gpt-3.5-turbo', // تحديد نموذج الذكاء الاصطناعي المستخدم.
      'messages': [
        {'role': 'user', 'content': message}, // قائمة الرسائل، هنا نرسل رسالة المستخدم.
      ],
      'max_tokens': 150, // الحد الأقصى لعدد التوكنز (الكلمات تقريبًا) في الرد.
    });

    // إرسال طلب `POST` إلى الـ API مع الـ headers والـ body.
    final response = await http.post(url, headers: headers, body: body );

    // التحقق من حالة الرد. `statusCode == 200` يعني أن الطلب نجح.
    if (response.statusCode == 200) {
      // فك تشفير الرد القادم بصيغة JSON.
      final data = json.decode(response.body);
      // استخلاص نص الرد من داخل بنية البيانات المعقدة.
      final reply = data['choices'][0]['message']['content'];
      return reply;
    } else {
      // إذا فشل الطلب، يتم إلقاء خطأ (Exception).
      throw Exception('فشل الاتصال بـ OpenAI API');
    }
  }
}

/// هذه هي الواجهة الرئيسية لشاشة الدردشة.
/// هي `StatefulWidget` لأنها تحتاج إلى تخزين وتحديث قائمة الرسائل.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // `_controller` للتحكم في حقل إدخال النص.
  final TextEditingController _controller = TextEditingController();
  // `_messages` قائمة لتخزين جميع رسائل المحادثة (من المستخدم والـ AI).
  final List<Map<String, String>> _messages = [];
  // نسخة من خدمة الدردشة.
  final ChatService _chatService = ChatService();

  /// دالة تُستدعى عند الضغط على زر الإرسال.
  void _sendMessage() async {
    // التأكد من أن حقل النص ليس فارغًا.
    if (_controller.text.isEmpty) return;

    // استخدام `setState` لتحديث الواجهة.
    setState(() {
      // إضافة رسالة المستخدم إلى قائمة الرسائل لعرضها فورًا.
      _messages.add({"sender": "user", "message": _controller.text});
    });

    // إرسال الرسالة إلى خدمة OpenAI وانتظار الرد.
    String reply = await _chatService.sendMessage(_controller.text);

    // بعد وصول الرد، يتم إضافته إلى قائمة الرسائل.
    setState(() {
      _messages.add({"sender": "ai", "message": reply});
    });

    // مسح حقل الإدخال ليكون جاهزًا للرسالة التالية.
    _controller.clear();
  }

  /// دالة لبناء "فقاعة" الرسالة الواحدة.
  Widget _buildMessageBubble(String message, String sender) {
    // `Align` لمحاذاة الفقاعة يمينًا للمستخدم ويسارًا للـ AI.
    return Align(
      alignment: sender == "user"
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          // تحديد لون الفقاعة بناءً على المرسل.
          color: sender == "user" ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [ // إضافة ظل خفيف للفقاعة.
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            // تحديد لون النص بناءً على المرسل.
            color: sender == "user" ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('دردشة مع الذكاء الاصطناعي'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // `Expanded` لجعل قائمة الرسائل تأخذ كل المساحة المتاحة.
            Expanded(
              // `ListView.builder` لبناء قائمة الرسائل بكفاءة.
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index]["message"]!;
                  final sender = _messages[index]["sender"]!;
                  return _buildMessageBubble(message, sender);
                },
              ),
            ),
            // `Row` لوضع حقل الإدخال وزر الإرسال بجانب بعضهما.
            Row(
              children: [
                // `Expanded` لجعل حقل النص يأخذ معظم المساحة.
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                // زر الإرسال.
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// الويدجت الجذر (Root Widget) للتطبيق.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // `MaterialApp` هو الويدجت الأساسي الذي يوفر بنية Material Design للتطبيق.
    return MaterialApp(
      debugShowCheckedModeBanner: false, // إخفاء شريط "Debug" في الزاوية.
      theme: ThemeData( // تحديد الثيم العام للتطبيق.
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      home: const ChatScreen(), // تحديد الشاشة الرئيسية للتطبيق.
    );
  }
}
