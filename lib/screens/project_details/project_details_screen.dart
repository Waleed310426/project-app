// // lib/screens/project_details/project_details_screen.dart

// // =========================================================================
// // شاشة تفاصيل المشروع - المرحلة 1 (نسخة الهيكل المنظم)
// // =========================================================================

// import 'package:flutter/material.dart';
// import '../../models/project_model.dart'; // المسار الجديد لموديل المشروع

// // استيراد صفحات التبويبات من نفس المجلد
// import 'plan_tab.dart';
// import 'tasks_tab.dart';
// import 'team_tab.dart';
// import 'chat_tab.dart';
// import 'files_tab.dart';

// class ProjectDetailsScreen extends StatefulWidget {
//   final Project project;

//   const ProjectDetailsScreen({super.key, required this.project});

//   @override
//   State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
// }

// class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.project.name),
//         actions: [
//           IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
//           const SizedBox(width: 8),
//         ],
//         bottom: TabBar(
//           controller: _tabController,

//           // ======================= التعديل هنا =======================
//           // غير هذه القيمة من true إلى false
//           isScrollable: false,

//           // =========================================================
//           indicatorColor: theme.colorScheme.primary,
//           labelColor: theme.colorScheme.primary,
//           unselectedLabelColor: theme.textTheme.bodySmall?.color,
//           tabs: const [
//             Tab(text: 'المخطط', icon: Icon(Icons.analytics_outlined)),
//             Tab(text: 'المهام', icon: Icon(Icons.check_circle_outline)),
//             Tab(text: 'الفريق', icon: Icon(Icons.groups_outlined)),
//             Tab(text: 'الدردشة', icon: Icon(Icons.chat_bubble_outline)),
//             Tab(text: 'الملفات', icon: Icon(Icons.attach_file_outlined)),
//           ],
//         ),
//       ),

//       body: TabBarView(
//         physics: const NeverScrollableScrollPhysics(),
//         controller: _tabController,
//         children: const [
//           PlanTab(),
//           TasksTab(),
//           TeamTab(),
//           ChatTab(),
//           FilesTab(),
//         ],
//       ),
//     );
//   }
// }
