// lib/screens/projects_screen.dart

import 'dart:io'; // للتعامل مع الملفات (لعرض الصور).
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:intl/intl.dart'; // لتنسيق الأرقام (العملة).
import 'package:provider/provider.dart'; // للوصول إلى بيانات المستخدم.
import 'package:task_ly/providers/user_provider.dart';
import '../models/project_model.dart';
import '../helpers/database_helper.dart';
import 'project_details_screen.dart'; // شاشة تفاصيل المشروع.

// `enum` لتحديد نوع الفلترة المتاحة.
enum ProjectFilter { all, favorite, archived, deleted }
// `enum` لتحديد نوع الترتيب المتاح.
enum ProjectSort { modifiedAt, name, endDate }

/// هذه الواجهة (`StatefulWidget`) هي الشاشة الرئيسية لعرض قائمة المشاريع.
class ProjectsScreen extends StatefulWidget {
  final int updateCounter; // لإجبار الواجهة على إعادة التحميل عند الحاجة.
  const ProjectsScreen({super.key, required this.updateCounter});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  // --- إدارة الحالة (State Management) ---
  List<Project> _allProjects = []; // قائمة بجميع المشاريع التي تم جلبها من قاعدة البيانات.
  List<Project> _filteredProjects = []; // القائمة التي يتم عرضها بعد تطبيق الفلترة والترتيب.
  bool _isLoading = true; // لتحديد ما إذا كانت البيانات قيد التحميل.
  String _searchQuery = ''; // لتخزين نص البحث الحالي.
  ProjectFilter _currentFilter = ProjectFilter.all; // الفلتر الحالي.
  ProjectSort _currentSort = ProjectSort.modifiedAt; // الترتيب الحالي.

  bool _isSelectionMode = false; // هل نحن في وضع التحديد المتعدد؟
  final Set<String> _selectedProjectIds = {}; // مجموعة لتخزين معرفات المشاريع المحددة.

  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback` يضمن أن الكود سيُنفذ بعد اكتمال بناء أول إطار للواجهة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjects();
    });
  }

  @override
  void didUpdateWidget(covariant ProjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إذا تغير `updateCounter`، فهذا يعني أن هناك طلبًا لإعادة تحميل البيانات.
    if (widget.updateCounter != oldWidget.updateCounter) {
      _loadProjects();
    }
  }

  /// دالة `_loadProjects`: مسؤولة عن جلب المشاريع من قاعدة البيانات.
  Future<void> _loadProjects() async {
    // الحصول على معرف المستخدم الحقيقي من `UserProvider`.
    final String? currentUserId = Provider.of<UserProvider>(context, listen: false).user?.id;

    // التحقق من وجود المستخدم قبل المتابعة.
    if (currentUserId == null) {
      print("خطأ فادح: لا يمكن تحميل المشاريع بدون مستخدم مسجل دخوله.");
      if (mounted) setState(() => _isLoading = false);
      return; // إيقاف العملية إذا لم يكن هناك مستخدم.
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      // استدعاء دالة قاعدة البيانات التي تجلب المشاريع مع إحصائياتها.
      final projectsData = await DatabaseHelper.instance.getProjectsWithStats(currentUserId);
      if (mounted) {
        // تحويل قائمة الخرائط (Maps) إلى قائمة كائنات `Project`.
        _allProjects = projectsData.map((map) => Project.fromMap(map)).toList();
        _applyFilterAndSort(); // تطبيق الفلترة والترتيب على البيانات الجديدة.
      }
    } catch (e) {
      print("Error loading projects: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// دالة `_applyFilterAndSort`: تقوم بتصفية وترتيب قائمة المشاريع.
  void _applyFilterAndSort() {
    List<Project> tempProjects;
    // تطبيق الفلترة.
    switch (_currentFilter) {
      case ProjectFilter.favorite: tempProjects = _allProjects.where((p) => p.isFavorite && !p.isArchived && !p.isDeleted).toList(); break;
      case ProjectFilter.archived: tempProjects = _allProjects.where((p) => p.isArchived && !p.isDeleted).toList(); break;
      case ProjectFilter.deleted: tempProjects = _allProjects.where((p) => p.isDeleted).toList(); break;
      case ProjectFilter.all: default: tempProjects = _allProjects.where((p) => !p.isArchived && !p.isDeleted).toList(); break;
    }
    // تطبيق البحث.
    if (_searchQuery.isNotEmpty) {
      tempProjects = tempProjects.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    // تطبيق الترتيب.
    switch (_currentSort) {
      case ProjectSort.name: tempProjects.sort((a, b) => a.name.compareTo(b.name)); break;
      case ProjectSort.endDate: tempProjects.sort((a, b) => a.endDate.compareTo(b.endDate)); break;
      case ProjectSort.modifiedAt: default: tempProjects.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt)); break;
    }
    setState(() => _filteredProjects = tempProjects);
  }

  /// دالة للتبديل بين تحديد وإلغاء تحديد مشروع.
  void _toggleSelection(String projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
        if (_selectedProjectIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedProjectIds.add(projectId);
        _isSelectionMode = true;
      }
    });
  }

  /// دالة لمسح جميع التحديدات.
  void _clearSelection() {
    setState(() {
      _selectedProjectIds.clear();
      _isSelectionMode = false;
    });
  }

  /// دالة لتحديث حالة مشروع واحد في القائمة المحلية (تُستدعى من `ProjectCard`).
  void _updateLocalProjectState(Project updatedProject) {
    final index = _allProjects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      setState(() {
        _allProjects[index] = updatedProject;
        _applyFilterAndSort();
      });
    }
  }

  /// دالة لتنفيذ إجراء جماعي على المشاريع المحددة.
  Future<void> _performBulkAction(Function(Project p) action) async {
    final projectsToUpdate = _allProjects.where((p) => _selectedProjectIds.contains(p.id)).toList();
    for (var project in projectsToUpdate) {
      action(project);
      project.modifiedAt = DateTime.now();
      await DatabaseHelper.instance.updateProject(project);
    }
    setState(() {
      _applyFilterAndSort();
      _clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // تبديل الشريط العلوي بناءً على وضع التحديد.
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProjects.isEmpty
              ? _buildEmptyState()
              : _buildProjectsList(),
    );
  }

  /// بناء الشريط العلوي العادي (مع البحث والفلترة).
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('المشاريع'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) => setState(() { _searchQuery = value; _applyFilterAndSort(); }),
            decoration: InputDecoration(
              hintText: 'ابحث عن مشروع...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<ProjectSort>(/* ... قائمة الترتيب ... */),
        PopupMenuButton<ProjectFilter>(/* ... قائمة الفلترة ... */),
      ],
    );
  }

  /// بناء الشريط العلوي في وضع التحديد (مع أزرار الإجراءات الجماعية).
  AppBar _buildSelectionAppBar() {
    bool isArchivedView = _currentFilter == ProjectFilter.archived;
    return AppBar(
      title: Text('${_selectedProjectIds.length} تم تحديده'),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
      actions: [
        IconButton(tooltip: 'تفضيل', icon: const Icon(Icons.favorite_outline), onPressed: () => _performBulkAction((p) => p.isFavorite = !p.isFavorite)),
        IconButton(
          tooltip: isArchivedView ? 'إلغاء الأرشفة' : 'أرشفة',
          icon: Icon(isArchivedView ? Icons.unarchive_outlined : Icons.archive_outlined),
          onPressed: () => _performBulkAction((p) => p.isArchived = !isArchivedView),
        ),
        IconButton(tooltip: 'حذف', icon: const Icon(Icons.delete_outline), onPressed: () => _performBulkAction((p) => p.isDeleted = true)),
      ],
    );
  }

  /// بناء قائمة المشاريع.
  Widget _buildProjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];
        final isSelected = _selectedProjectIds.contains(project.id);
        return FadeInUp(
          child: GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(project.id);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsScreen(project: project)));
              }
            },
            onLongPress: () => _toggleSelection(project.id),
            child: ProjectCard(project: project, isSelected: isSelected, onStateChanged: _updateLocalProjectState),
          ),
        );
      },
    );
  }

  /// بناء الواجهة التي تظهر عند عدم وجود مشاريع.
  Widget _buildEmptyState() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('لا توجد مشاريع تطابق بحثك')]));
  }
}

// =========================================================================
// ويدجت كرت المشروع (ProjectCard)
// =========================================================================
class ProjectCard extends StatefulWidget {
  final Project project;
  final bool isSelected;
  final Function(Project) onStateChanged; // دالة لتحديث الحالة في الشاشة الأم.

  const ProjectCard({super.key, required this.project, required this.isSelected, required this.onStateChanged});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  @override
  void didUpdateWidget(covariant ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project != oldWidget.project) {
      setState(() => _project = widget.project);
    }
  }

  /// دالة لتحديث حالة المشروع (مثل التفضيل أو الأرشفة) وحفظها في قاعدة البيانات.
  Future<void> _updateProjectState(Function(Project p) action) async {
    action(_project);
    _project.modifiedAt = DateTime.now();
    await DatabaseHelper.instance.updateProject(_project);
    widget.onStateChanged(_project); // إعلام الشاشة الأم بالتغيير.
  }

  /// دالة لتحديد نص ولون حالة المشروع.
  (String, Color) _getProjectStatus(Project project) {
    if (project.progress >= 1.0) return ('مكتمل', Colors.green);
    if (project.endDate.isBefore(DateTime.now())) return ('متأخر', Colors.red);
    return ('نشط', Theme.of(context).colorScheme.primary);
  }

  /// دالة لتحديد نص حالة الوقت المتبقي.
  String _getRemainingTimeStatus(Project project) {
    if (project.progress >= 1.0) return 'مكتمل';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(project.endDate.year, project.endDate.month, project.endDate.day);

    if (endDate.isBefore(today)) {
      final daysLate = today.difference(endDate).inDays;
      return 'متأخر $daysLate يوم';
    } else if (endDate == today) {
      return 'اليوم الأخير';
    } else {
      final daysRemaining = endDate.difference(today).inDays;
      return 'متبقي $daysRemaining يوم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.ي');
    final (statusText, statusColor) = _getProjectStatus(_project);

    return Card(
      elevation: widget.isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: widget.isSelected ? theme.colorScheme.primary : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (كود بناء واجهة الكرت بالتفصيل) ...
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectImage(_project.imageUrl, theme),
                const SizedBox(width: 12),
                Expanded(child: Text(_project.name, style: theme.textTheme.titleLarge)),
                const SizedBox(width: 8),
                _buildActionButtons(context, isArchived: _project.isArchived),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _project.progress, minHeight: 8, backgroundColor: statusColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(statusColor)))),
                const SizedBox(width: 12),
                Text('${(_project.progress * 100).toInt()}%', style: theme.textTheme.bodyMedium?.copyWith(color: statusColor)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _InfoChip(icon: Icons.timelapse_rounded, text: _getRemainingTimeStatus(_project)),
              _InfoChip(icon: Icons.task_alt_rounded, text: '${_project.taskCount} مهام'),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectImage(String? imageUrl, ThemeData theme) { /* ... */ return Container(); }
  Widget _buildActionButtons(BuildContext context, {required bool isArchived}) { /* ... */ return Container(); }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(text, style: Theme.of(context).textTheme.bodySmall)]);
  }
}
