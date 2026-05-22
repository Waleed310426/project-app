// lib/sheets/add_task_sheet.dart

import 'dart:io'; // للتعامل مع كائن الملف (File).
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // لاختيار الملفات.
import 'package:intl/intl.dart'; // لتنسيق التواريخ.
import 'package:percent_indicator/circular_percent_indicator.dart'; // لمؤشر التقدم الدائري.
import 'package:permission_handler/permission_handler.dart'; // لطلب الأذونات.
import 'package:provider/provider.dart'; // للوصول إلى بيانات المستخدم.
import 'package:task_ly/providers/user_provider.dart';
import '../helpers/database_helper.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

/// هذه الواجهة (`StatefulWidget`) هي ورقة سفلية (Bottom Sheet) معقدة تُستخدم لإضافة مهمة جديدة.
/// يمكن ربط المهمة الجديدة بمشروع أو بمهمة أخرى (لتكون مهمة فرعية).
class AddTaskSheet extends StatefulWidget {
  final VoidCallback onTaskAdded; // دالة "callback" تُستدعى بعد إضافة المهمة.
  final Project? parentProject; // المشروع الأب (إذا تم فتح الشاشة من تفاصيل مشروع).
  final Task? parentTask; // المهمة الأم (إذا تم فتح الشاشة من تفاصيل مهمة).

  const AddTaskSheet({
    super.key,
    required this.onTaskAdded,
    this.parentProject,
    this.parentTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  // --- إدارة الحالة (State Management) ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;
  double _progress = 0.0;
  User? _selectedAssignee; // المستخدم المسؤول عن المهمة.
  final List<File> _attachments = []; // قائمة بالملفات المرفقة.

  String _parentType = 'project'; // نوع الأب الافتراضي (مشروع أو مهمة).
  Project? _selectedProject; // المشروع المختار كأب.
  Task? _selectedParentTask; // المهمة المختارة كأم.

  List<Project> _availableProjects = []; // قائمة المشاريع المتاحة للاختيار.
  List<Task> _availableParentTasks = []; // قائمة المهام المتاحة للاختيار.
  List<User> _teamMembers = []; // قائمة أعضاء الفريق (أو الأصدقاء) لتعيين المهمة لهم.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  /// دالة `_loadInitialData`: لجلب البيانات الأولية اللازمة للنموذج.
  Future<void> _loadInitialData() async {
    final String? currentUserId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (currentUserId == null) {
      print("خطأ فادح: لا يمكن تحميل البيانات بدون مستخدم.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // جلب البيانات من قاعدة البيانات.
      _teamMembers = await DatabaseHelper.instance.getFriendsForUser(currentUserId);
      _availableProjects = await DatabaseHelper.instance.getAllProjectsForUser(currentUserId);
      _availableParentTasks = await DatabaseHelper.instance.getAllTasksForUser(currentUserId);

      // تحديد الأب المختار مسبقًا إذا تم تمريره للواجهة.
      if (widget.parentProject != null) {
        _parentType = 'project';
        _selectedProject = _availableProjects.firstWhere((p) => p.id == widget.parentProject!.id, orElse: () => null);
      } else if (widget.parentTask != null) {
        _parentType = 'task';
        _selectedParentTask = _availableParentTasks.firstWhere((t) => t.id == widget.parentTask!.id, orElse: () => null);
      }
      
      _updateDatesFromParent(); // تحديث تواريخ المهمة بناءً على تواريخ الأب.
    } catch (e) {
      print("Error loading initial data for AddTaskSheet: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  /// دالة `_updateDatesFromParent`: لتحديث تواريخ البدء والانتهاء المقترحة بناءً على الأب المختار.
  void _updateDatesFromParent() {
    if (_parentType == 'project' && _selectedProject != null) {
      setState(() { _startDate = _selectedProject!.startDate; _endDate = _selectedProject!.endDate; });
    } else if (_parentType == 'task' && _selectedParentTask != null) {
      setState(() { _startDate = _selectedParentTask!.startDate; _endDate = _selectedParentTask!.endDate; });
    } else {
      setState(() { _startDate = null; _endDate = null; });
    }
  }

  /// دالة `_pickDate`: لإظهار منتقي التاريخ ضمن النطاق المسموح به من الأب.
  Future<void> _pickDate(bool isStart) async {
    if ((_parentType == 'project' && _selectedProject == null) || (_parentType == 'task' && _selectedParentTask == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد مشروع أو مهمة رئيسية أولاً')));
      return;
    }
    // ... (منطق تحديد النطاق الزمني) ...
    final date = await showDatePicker(/* ... */);
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = _startDate;
        } else {
          _endDate = date;
        }
      });
    }
  }

  /// دالة `_pickFiles`: لطلب صلاحية الوصول للملفات وفتح منتقي الملفات.
  Future<void> _pickFiles() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();
    if (status.isGranted) {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) setState(() => _attachments.addAll(result.paths.map((path) => File(path!))));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض صلاحية الوصول للملفات.')));
    }
  }

  /// دالة `_saveTask`: الدالة الرئيسية لحفظ المهمة الجديدة.
  Future<void> _saveTask() async {
    final String? currentUserId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (currentUserId == null) { /* ... معالجة الخطأ ... */ return; }
    if (!_formKey.currentState!.validate()) return;
    if ((_parentType == 'project' && _selectedProject == null) || (_parentType == 'task' && _selectedParentTask == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد مشروع أو مهمة رئيسية لربط المهمة بها')));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد تاريخ البدء والانتهاء للمهمة')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newTask = Task.createNew(
        name: _nameController.text,
        ownerId: currentUserId,
        assigneeId: (_selectedAssignee?.id) ?? currentUserId,
        projectId: _parentType == 'project' ? _selectedProject!.id : null,
        parentTaskId: _parentType == 'task' ? _selectedParentTask!.id : null,
        startDate: _startDate,
        endDate: _endDate,
        description: _descriptionController.text,
        budget: double.tryParse(_budgetController.text),
        progress: _progress,
        statusId: 1,
      );
      await DatabaseHelper.instance.insertTaskWithAttachments(newTask, _attachments, currentUserId);
      if (mounted) Navigator.pop(context);
      widget.onTaskAdded();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color.fromARGB(255, 7, 135, 233), borderRadius: BorderRadius.circular(12))),
                      const SizedBox(height: 12),
                      Text('إضافة مهمة جديدة', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            _buildTextField(_nameController, 'اسم المهمة', Icons.title_rounded, isRequired: true),
                            const SizedBox(height: 16),
                            _buildTextField(_descriptionController, 'وصف المهمة (اختياري)', Icons.description_outlined, maxLines: 3),
                            const SizedBox(height: 20),
                            _buildParentSelector(),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(child: _buildAssigneeDropdown()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(_budgetController, 'الميزانية (اختياري)', Icons.attach_money_rounded, isNumeric: true)),
                            ]),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(child: _buildDatePicker('تاريخ البدء', _startDate, () => _pickDate(true))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDatePicker('تاريخ الانتهاء', _endDate, () => _pickDate(false))),
                            ]),
                            const SizedBox(height: 20),
                            _buildProgressSlider(),
                            const SizedBox(height: 20),
                            _buildAttachmentsSection(),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(onPressed: _saveTask, icon: const Icon(Icons.add_task_rounded), label: const Text('إنشاء وحفظ المهمة')),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// ويدجت مساعد لبناء قسم اختيار الأب (مشروع أو مهمة).
  Widget _buildParentSelector() {
    final isParentPreselected = widget.parentProject != null || widget.parentTask != null;
    return AbsorbPointer(
      absorbing: isParentPreselected,
      child: Opacity(
        opacity: isParentPreselected ? 0.6 : 1.0,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text('ربط المهمة بـ:', style: Theme.of(context).textTheme.titleMedium)),
              Row(children: [
                Expanded(child: RadioListTile<String>(title: const Text('مشروع'), value: 'project', groupValue: _parentType, onChanged: (v) => setState(() { _parentType = v!; _selectedProject = null; _selectedParentTask = null; _updateDatesFromParent(); }))),
                Expanded(child: RadioListTile<String>(title: const Text('مهمة أخرى'), value: 'task', groupValue: _parentType, onChanged: (v) => setState(() { _parentType = v!; _selectedProject = null; _selectedParentTask = null; _updateDatesFromParent(); }))),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _parentType == 'project'
                    ? DropdownButtonFormField<Project>(decoration: const InputDecoration(labelText: 'اختر المشروع', border: OutlineInputBorder()), items: _availableProjects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(), onChanged: (p) { setState(() => _selectedProject = p); _updateDatesFromParent(); }, value: _selectedProject)
                    : DropdownButtonFormField<Task>(decoration: const InputDecoration(labelText: 'اختر المهمة الرئيسية', border: OutlineInputBorder()), items: _availableParentTasks.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (t) { setState(() => _selectedParentTask = t); _updateDatesFromParent(); }, value: _selectedParentTask),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت مساعد لبناء حقول النص.
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isRequired = false, int maxLines = 1, bool isNumeric = false}) =>
      TextFormField(controller: controller, maxLines: maxLines, keyboardType: isNumeric ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()), validator: (value) => (isRequired && (value == null || value.trim().isEmpty)) ? 'هذا الحقل مطلوب' : null);

  /// ويدجت مساعد لبناء حقول اختيار التاريخ.
  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
          child: Text(date == null ? 'لم يحدد' : DateFormat.yMMMd('ar').format(date), style: TextStyle(color: date == null ? Colors.grey[600] : null)),
        ),
      );

  /// ويدجت مساعد لبناء القائمة المنسدلة لاختيار المسؤول عن المهمة.
  Widget _buildAssigneeDropdown() {
    return DropdownButtonFormField<User>(
      decoration: const InputDecoration(labelText: 'المسؤول', border: OutlineInputBorder()),
      items: _teamMembers.map((user) => DropdownMenuItem(value: user, child: Row(children: [CircleAvatar(radius: 14, child: Text(user.name?.substring(0, 1) ?? '?')), const SizedBox(width: 8), Text(user.name ?? 'مستخدم غير معروف')]))).toList(),
      onChanged: (user) => setState(() => _selectedAssignee = user),
    );
  }

  /// ويدجت مساعد لبناء شريط تحديد نسبة الإنجاز.
  Widget _buildProgressSlider() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('نسبة الإنجاز:', style: Theme.of(context).textTheme.titleMedium),
        Row(children: [
          Expanded(child: Slider(value: _progress, onChanged: (val) => setState(() => _progress = val), label: '${(_progress * 100).toInt()}%', divisions: 10)),
          CircularPercentIndicator(radius: 25.0, lineWidth: 5.0, percent: _progress, center: Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), progressColor: Theme.of(context).colorScheme.primary),
        ]),
      ]);

  /// ويدجت مساعد لبناء قسم المرفقات.
  Widget _buildAttachmentsSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('المرفقات', style: Theme.of(context).textTheme.titleMedium),
          TextButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.attach_file), label: const Text('إضافة ملفات')),
        ]),
        if (_attachments.isNotEmpty)
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final file = _attachments[index];
                return Padding(padding: const EdgeInsets.only(left: 8.0), child: Chip(avatar: const Icon(Icons.insert_drive_file), label: Text(file.path.split(Platform.pathSeparator).last, overflow: TextOverflow.ellipsis), onDeleted: () => setState(() => _attachments.removeAt(index))));
              },
            ),
          ),
      ]);
}
