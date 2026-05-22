// lib/widgets/add_project_sheet.dart

// =========================================================================
// واجهة إضافة مشروع متكاملة - الإصدار النهائي والمصحح
// =========================================================================

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:task_ly/providers/user_provider.dart';
import '../helpers/database_helper.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/team_member_model.dart';

class AddProjectSheet extends StatefulWidget {
  
  final VoidCallback onProjectAdded;
  
  const AddProjectSheet({super.key, required this.onProjectAdded});
  @override
  State<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<AddProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final List<File> _attachments = []; // ✅ 2. إضافة قائمة للمرفقات
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  String? _selectedImagePath;
  String? _selectedIconString; // سنخزن الأيقونة كنص
  String? _selectedTeamId;
  bool _createNewTeam = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Set<String> _selectedFriendsIds = {};

  bool _isSaving = false;
  bool _isLoading = true;

  List<Team> _userTeams = [];
  List<User> _userFriends = [];

  final String _currentUserId = 'user_main_001';

  // قائمة الأيقونات المتاحة للاختيار
  final List<IconData> _availableIcons = [
    Icons.folder_special_rounded,
    Icons.work_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.lightbulb_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.palette_rounded,
    Icons.code_rounded,
    Icons.rocket_launch_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIconString = _iconDataToString(_availableIcons.first);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  // ✅ 3. إضافة دالة اختيار المرفقات
  Future<void> _pickAttachments() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isGranted) {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        setState(
          () => _attachments.addAll(result.paths.map((path) => File(path!))),
        );
      }
    }
  }

  Future<void> _fetchInitialData() async {
    // ✅ 5. احصل على معرف المستخدم الحقيقي من Provider
    final String? currentUserId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).user?.id;
    setState(() => _isLoading = true);

    if (currentUserId == null) {
      print("خطأ: لا يمكن جلب البيانات بدون مستخدم.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final teamsData = await DatabaseHelper.instance.getTeamsForUser(
        currentUserId,
      );
      _userTeams = teamsData.map((m) => Team.fromMap(m)).toList();

      // ✅ [تصحيح] جلب الأصدقاء فقط بدلاً من كل المستخدمين
      _userFriends = await DatabaseHelper.instance.getFriendsForUser(
        _currentUserId,
      );
    } catch (e) {
      print("Error fetching initial data for project sheet: $e");
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

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final String? currentUserId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).user?.id;

    // ✅ 9. تحقق مرة أخرى كإجراء أمان فائق
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطأ: جلسة المستخدم غير صالحة. يرجى إعادة تسجيل الدخول.',
          ),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }
    try {
      print("🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄");
      print(currentUserId);
      print("🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄🦄");
       await _dbHelper.printAllUsersInDb(); // اطبع المستخدمين بعد الإضافة
        
      String? finalTeamId = _selectedTeamId;
      if (_createNewTeam) {
        final newTeam = Team.createNew(
          name: 'فريق: ${_nameController.text}',
          ownerId: currentUserId,
        );
        await DatabaseHelper.instance.insert(
          DatabaseHelper.tableTeams,
          newTeam.toMap(),
        );
        finalTeamId = newTeam.id;
        final batch = await DatabaseHelper.instance.database.then(
          (db) => db.batch(),
        );
        batch.insert(
          DatabaseHelper.tableTeamMembers,
          TeamMember(
            teamId: finalTeamId,
            userId: currentUserId,
            role: 'قائد',
            joinedAt: DateTime.now(),
          ).toMap(),
        );
        for (var friendId in _selectedFriendsIds) {
          batch.insert(
            DatabaseHelper.tableTeamMembers,
            TeamMember(
              teamId: finalTeamId,
              userId: friendId,
              role: 'عضو',
              joinedAt: DateTime.now(),
            ).toMap(),
          );
        }
        await batch.commit(noResult: true);
      }

      final newProject = Project.createNew(
        name: _nameController.text,
        ownerId: currentUserId,
        startDate: _startDate,
        endDate: _endDate,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        budget: _budgetController.text.isNotEmpty
            ? double.tryParse(_budgetController.text)
            : null,
        imageUrl: _selectedImagePath ?? _selectedIconString,
        teamId: finalTeamId,
        statusId: 1, // ✅✅✅ تم إضافة هذا السطر المفقود (5 = جديد)
      );

      await DatabaseHelper.instance.insertProjectWithAttachments(
        newProject,
        _attachments,
        currentUserId,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onProjectAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(imageFile.path);
      final savedImagePath = p.join(appDir.path, fileName);
      await imageFile.copy(savedImagePath);
      setState(() {
        _selectedImagePath = savedImagePath;
        _selectedIconString = null;
      });
    }
  }

  void _pickIcon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر أيقونة'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _availableIcons
              .map(
                (icon) => IconButton(
                  icon: Icon(icon, size: 32),
                  onPressed: () {
                    setState(() {
                      _selectedIconString = _iconDataToString(icon);
                      _selectedImagePath = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // دوال مساعدة لتحويل الأيقونة من وإلى نص
  String _iconDataToString(IconData icon) =>
      '${icon.codePoint};${icon.fontFamily}';

  // lib/widgets/add_project_sheet.dart -> داخل كلاس _AddProjectSheetState

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(236, 9, 99, 226),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'إنشاء مشروع جديد',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 16),
                        _buildImageAndIconPicker(),
                        const SizedBox(height: 20),
                        _buildDatePickers(),
                        const SizedBox(height: 16),
                        _buildBudgetField(),
                        const SizedBox(height: 20),
                        _buildTeamSection(),
                        const SizedBox(height: 24),
                        _buildAttachmentsSection(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
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

  // ✅ 6. بناء ويدجت قسم المرفقات
  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("مرفقات المشروع", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickAttachments,
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('اختيار ملفات'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        if (_attachments.isNotEmpty)
          Wrap(
            spacing: 8.0,
            children: _attachments
                .map(
                  (file) => Chip(
                    label: Text(p.basename(file.path)),
                    onDeleted: () => setState(() => _attachments.remove(file)),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildNameField() => TextFormField(
    controller: _nameController,
    decoration: const InputDecoration(
      labelText: 'اسم المشروع *',
      hintText: 'مثال: تصميم واجهات تطبيق تاسكلي',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.label_important_outline),
    ),
    validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'اسم المشروع مطلوب' : null,
  );
  Widget _buildDescriptionField() => TextFormField(
    controller: _descriptionController,
    decoration: const InputDecoration(
      labelText: 'وصف المشروع (اختياري)',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.description_outlined),
    ),
    maxLines: 3,
  );
  Widget _buildBudgetField() => TextFormField(
    controller: _budgetController,
    decoration: const InputDecoration(
      labelText: 'الميزانية (اختياري)',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.attach_money_outlined),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  );
  Widget _buildDatePickers() => Row(
    children: [
      Expanded(
        child: _DateSelector(
          label: 'تاريخ البدء',
          date: _startDate,
          onTap: () async {
            final p = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2101),
            );
            if (p != null) setState(() => _startDate = p);
          },
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _DateSelector(
          label: 'تاريخ الانتهاء',
          date: _endDate,
          onTap: () async {
            final p = await showDatePicker(
              context: context,
              initialDate: _endDate,
              firstDate: _startDate,
              lastDate: DateTime(2101),
            );
            if (p != null) setState(() => _endDate = p);
          },
        ),
      ),
    ],
  );
  Widget _buildSaveButton() => ElevatedButton.icon(
    onPressed: _isSaving ? null : _saveProject,
    icon: _isSaving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.add_task_rounded),
    label: Text(_isSaving ? 'جاري الحفظ...' : 'إنشاء وحفظ المشروع'),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
      ),
    ),
  );

  Widget _buildImageAndIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("شعار المشروع", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPickerBox(
                onTap: _pickImage,
                isSelected: _selectedImagePath != null,
                child: _selectedImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(_selectedImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : _buildPlaceholder(Icons.image_outlined, "اختر صورة"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPickerBox(
                onTap: _pickIcon,
                isSelected: _selectedIconString != null,
                child: _selectedIconString != null
                    ? Icon(
                        Project.parseIconData(_selectedIconString!),
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : _buildPlaceholder(
                        Icons.emoji_emotions_outlined,
                        "اختر أيقونة",
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerBox({
    required VoidCallback onTap,
    required bool isSelected,
    required Widget child,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: child),
    ),
  );
  Widget _buildPlaceholder(IconData icon, String text) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: Colors.grey.shade600),
      const SizedBox(height: 4),
      Text(text, style: TextStyle(color: Colors.grey.shade600)),
    ],
  );

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("الفريق", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'اختر فريقًا حاليًا (اختياري)',
          ),
          value: _selectedTeamId,
          items: _userTeams
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedTeamId = v;
            if (v != null) _createNewTeam = false;
          }),
        ),
        CheckboxListTile(
          title: const Text('إنشاء فريق جديد لهذا المشروع'),
          value: _createNewTeam,
          onChanged: (v) => setState(() {
            _createNewTeam = v ?? false;
            if (_createNewTeam) _selectedTeamId = null;
          }),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (_createNewTeam)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("إضافة أعضاء للفريق الجديد:"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _userFriends.map((friend) {
                    // تم تغيير اسم المتغير
                    final isSelected = _selectedFriendsIds.contains(friend.id);
                    return FilterChip(
                      label: Text(friend.name ?? 'لا يوجد اسم '),
                      selected: isSelected,
                      onSelected: (s) => setState(
                        () => s
                            ? _selectedFriendsIds.add(friend.id)
                            : _selectedFriendsIds.remove(friend.id),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('dd/MM/yyyy', 'ar').format(date)),
          const Icon(Icons.calendar_today_rounded, size: 20),
        ],
      ),
    ),
  );
}
