// lib/widgets/details_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ والعملات.
import '../helpers/database_helper.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض تبويب "التفاصيل".
/// تم تصميمها لتكون قابلة لإعادة الاستخدام، حيث يمكنها عرض تفاصيل مشروع أو مهمة.
/// تتميز بوجود وضعين: وضع القراءة فقط، ووضع التعديل.
class DetailsTab extends StatefulWidget {
  final Project? project;
  final Task? task;
  // دالة "callback" لإبلاغ الشاشة الأم (مثل `ProjectDetailsScreen`) بحدوث تغييرات.
  final Function(dynamic) onDetailsUpdated;

  const DetailsTab({
    super.key,
    this.project,
    this.task,
    required this.onDetailsUpdated,
  }) : assert(project != null || task != null); // التأكد من تمرير مشروع أو مهمة.

  @override
  State<DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  // --- إدارة الحالة (State Management) ---
  bool _isEditing = false; // لتحديد ما إذا كنا في وضع التعديل.
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;

  // متغيرات محلية لتخزين وعرض البيانات الحالية.
  late Project? _currentProject;
  late Task? _currentTask;

  @override
  void initState() {
    super.initState();
    // تهيئة المتغيرات المحلية بالبيانات القادمة من الـ widget.
    _currentProject = widget.project;
    _currentTask = widget.task;
    _initializeControllers();
  }

  /// دالة `_initializeControllers`: لتهيئة وحدات التحكم بنصوص البيانات الحالية.
  void _initializeControllers() {
    _nameController = TextEditingController(text: _currentProject?.name ?? _currentTask?.name);
    _descriptionController = TextEditingController(text: _currentProject?.description ?? _currentTask?.description);
    _budgetController = TextEditingController(text: (_currentProject?.budget ?? _currentTask?.budget)?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  /// دالة `_saveChanges`: لحفظ التغييرات التي تم إجراؤها في وضع التعديل.
  Future<void> _saveChanges() async {
    dynamic updatedItem;
    if (_currentProject != null) {
      // إنشاء نسخة جديدة من المشروع مع البيانات المحدثة.
      final updatedProject = _currentProject!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        budget: double.tryParse(_budgetController.text),
        modifiedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.updateProject(updatedProject);
      updatedItem = updatedProject;
    } else if (_currentTask != null) {
      // إنشاء نسخة جديدة من المهمة مع البيانات المحدثة.
      final updatedTask = _currentTask!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        budget: double.tryParse(_budgetController.text),
        modifiedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.updateTask(updatedTask);
      updatedItem = updatedTask;
    }

    // تحديث الحالة المحلية وإبلاغ الشاشة الأم بالتغيير.
    setState(() {
      if (updatedItem is Project) _currentProject = updatedItem;
      if (updatedItem is Task) _currentTask = updatedItem;
      _isEditing = false; // الخروج من وضع التعديل.
    });
    widget.onDetailsUpdated(updatedItem); // استدعاء الـ callback.
  }

  @override
  Widget build(BuildContext context) {
    final isProject = _currentProject != null;
    final imageUrl = _currentProject?.imageUrl;

    return Scaffold(
      // زر عائم للتبديل بين وضع التعديل والحفظ.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'details_fab',
        onPressed: () {
          if (_isEditing) {
            _saveChanges();
          } else {
            setState(() => _isEditing = true);
          }
        },
        label: Text(_isEditing ? 'حفظ التغييرات' : 'تعديل البيانات'),
        icon: Icon(_isEditing ? Icons.save_outlined : Icons.edit_outlined),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // عرض رأس المشروع (صورة أو أيقونة) إذا كان العنصر مشروعًا.
            if (isProject && imageUrl != null) _buildProjectHeader(imageUrl),
            Padding(
              padding: const EdgeInsets.all(16.0),
              // استخدام `AnimatedSwitcher` للانتقال بسلاسة بين وضع العرض ووضع التعديل.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isEditing ? _buildEditingView() : _buildReadOnlyView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ويدجت `_buildProjectHeader`: لبناء رأس المشروع.
  Widget _buildProjectHeader(String imageUrl) {
    final iconData = Project.parseIconData(imageUrl);
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: iconData == null
          ? Image.file(File(imageUrl), fit: BoxFit.cover)
          : Icon(iconData, size: 80, color: Theme.of(context).colorScheme.primary),
    );
  }

  /// ويدجت `_buildReadOnlyView`: لبناء واجهة العرض (القراءة فقط).
  Widget _buildReadOnlyView() {
    final title = _currentProject?.name ?? _currentTask!.name;
    final description = _currentProject?.description ?? _currentTask?.description;
    final startDate = _currentProject?.startDate ?? _currentTask?.startDate;
    final endDate = _currentProject?.endDate ?? _currentTask?.endDate;
    final budget = _currentProject?.budget ?? _currentTask?.budget;

    return Column(
      key: const ValueKey('readOnly'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(description ?? 'لا يوجد وصف.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        const Divider(height: 40),
        _buildInfoRow(Icons.play_arrow_rounded, 'تاريخ البدء', startDate != null ? DateFormat.yMMMMd('ar').format(startDate) : 'غير محدد'),
        const SizedBox(height: 20),
        _buildInfoRow(Icons.flag_rounded, 'تاريخ الانتهاء', endDate != null ? DateFormat.yMMMMd('ar').format(endDate) : 'غير محدد'),
        const SizedBox(height: 20),
        _buildInfoRow(Icons.account_balance_wallet_outlined, 'الميزانية', budget != null ? NumberFormat.currency(locale: 'ar', symbol: 'ر.س').format(budget) : 'غير محددة'),
      ],
    );
  }

  /// ويدجت `_buildEditingView`: لبناء واجهة التعديل (حقول الإدخال).
  Widget _buildEditingView() {
    return Column(
      key: const ValueKey('editing'),
      children: [
        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()), maxLines: 5, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        const SizedBox(height: 20),
        TextFormField(controller: _budgetController, decoration: const InputDecoration(labelText: 'الميزانية', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('إلغاء التعديل')),
      ],
    );
  }

  /// ويدجت `_buildInfoRow`: لبناء صف معلومات (أيقونة، عنوان، قيمة).
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
