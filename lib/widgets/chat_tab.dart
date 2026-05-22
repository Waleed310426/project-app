// lib/widgets/chat_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق الوقت.
import '../helpers/database_helper.dart';
import '../models/message_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض تبويب "الدردشة".
/// يمكنها عرض الدردشة لمشروع معين أو لمهمة معينة.
class ChatTab extends StatefulWidget {
  final Project? project;
  final Task? task;

  const ChatTab({super.key, this.project, this.task})
      : assert(project != null || task != null); // التأكد من تمرير أحد المعرفين على الأقل.

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  // --- إدارة الحالة (State Management) ---
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  final String _currentUserId = 'user_main_001'; // معرف المستخدم الحالي (يجب أن يأتي من Provider).

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  /// دالة `_loadMessages`: لجلب الرسائل من قاعدة البيانات.
  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> data;
    if (widget.project != null) {
      data = await DatabaseHelper.instance.getMessagesForProject(widget.project!.id);
    } else {
      data = await DatabaseHelper.instance.getMessagesForTask(widget.task!.id);
    }
    setState(() {
      _messages = data.map((map) => Message.fromMap(map)).toList();
      _isLoading = false;
    });
    _scrollToBottom(); // التمرير للأسفل بعد تحميل الرسائل.
  }

  /// دالة `_sendMessage`: لإرسال رسالة جديدة.
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // إنشاء كائن رسالة جديد.
    final newMessage = Message.createNew(
      content: _messageController.text.trim(),
      senderId: _currentUserId,
      projectId: widget.project?.id,
      taskId: widget.task?.id,
    );

    // حفظ الرسالة في قاعدة البيانات.
    await DatabaseHelper.instance.saveMessage(newMessage.toMap());
    _messageController.clear();
    _loadMessages(); // إعادة تحميل الرسائل لعرض الرسالة الجديدة.
  }

  /// دالة `_deleteMessage`: لحذف رسالة (حذف ناعم).
  void _deleteMessage(Message message) async {
    // إنشاء نسخة من الرسالة مع تغيير المحتوى وحالة الحذف.
    final updatedMessage = Message(
      id: message.id,
      content: "تم حذف هذه الرسالة",
      senderId: message.senderId,
      projectId: message.projectId,
      createdAt: message.createdAt,
      isDeletedForSender: true,
    );
    // حفظ الرسالة المحدثة (سيتم استبدال القديمة).
    await DatabaseHelper.instance.saveMessage(updatedMessage.toMap());
    _loadMessages(); // إعادة تحميل الرسائل.
  }

  /// دالة `_scrollToBottom`: للتمرير التلقائي إلى أسفل القائمة.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(child: Text('لا توجد رسائل. ابدأ المحادثة!'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == _currentUserId;
                        return _buildMessageBubble(message, isMe);
                      },
                    ),
        ),
        _buildMessageComposer(), // حقل إدخال الرسالة.
      ],
    );
  }

  /// ويدجت `_buildMessageBubble`: لبناء فقاعة رسالة واحدة.
  Widget _buildMessageBubble(Message message, bool isMe) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface;
    final textColor = isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color;
    final isDeleted = message.isDeletedForSender;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        // إظهار خيار الحذف عند الضغط المطول على رسائل المستخدم.
        onLongPress: () {
          if (isMe && !isDeleted) {
            showModalBottomSheet(
              context: context,
              builder: (context) => ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف الرسالة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
            ),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content ?? '',
                style: TextStyle(
                  color: textColor,
                  fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal, // تغيير نمط الخط للرسائل المحذوفة.
                ),
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat('h:mm a', 'ar').format(message.createdAt), // تنسيق الوقت.
                style: TextStyle(fontSize: 10, color: textColor?.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت `_buildMessageComposer`: لبناء حقل إدخال الرسالة.
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () { /* TODO: إضافة منطق رفع الملفات */ },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
