// // lib/screens/project_details/plan_tab.dart

// // =========================================================================
// // شاشة مخطط جانت - المرحلة 1.2: إصلاح المحاذاة لتبدأ من اليمين.
// // =========================================================================

// import 'package:flutter/material.dart';
// import 'dart:math' as math;
// import '../../models/task_model.dart';

// class PlanTab extends StatefulWidget {
//   const PlanTab({super.key});

//   @override
//   State<PlanTab> createState() => _PlanTabState();
// }

// class _PlanTabState extends State<PlanTab> {
//   final List<Task> _tasks = List.generate(8, (i) {
//     final start = DateTime.now().add(Duration(days: i * 5));
//     return Task(
//       id: 'task_$i',
//       name: 'المهمة الرئيسية رقم ${i + 1}',
//       startDate: start,
//       endDate: start.add(Duration(days: 10 + i * 2)),
//       progress: math.Random().nextDouble(),
//       status: i % 3 == 0 ? 'حرجة' : 'عادية',
//     );
//   });

//   DateTime get _projectStartDate =>
//       _tasks.map((t) => t.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
//   DateTime get _projectEndDate =>
//       _tasks.map((t) => t.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
//   int get _totalDays =>
//       _projectEndDate.difference(_projectStartDate).inDays + 2;

//   // أبعاد ثابتة للمخطط
//   final double _dayWidth = 60.0;
//   final double _rowHeight = 65.0;
//   final double _headerHeight = 50.0;
//   final double _taskNameColumnWidth = 160.0; // عرض ثابت لعمود أسماء المهام

//   @override
//   Widget build(BuildContext context) {
//     // العرض الكلي للمخطط = عرض الأيام + عرض عمود أسماء المهام
//     final totalWidth = (_totalDays * _dayWidth) + _taskNameColumnWidth;
//     final totalHeight = (_tasks.length) * _rowHeight + _headerHeight;

//     // `InteractiveViewer` يسمح بالتكبير والتصغير والتحريك
//     return InteractiveViewer(
//       constrained: false,
//       boundaryMargin: const EdgeInsets.all(20.0),
//       minScale: 0.5,
//       maxScale: 4.0,
//       // ======================= التعديل هنا =======================
//       // تغليف الـ SizedBox بـ Align لضمان المحاذاة إلى اليمين
//       child: Align(
//         alignment: Alignment.topRight,
//         child: SizedBox(
//           width: totalWidth,
//           height: totalHeight,
//           child: Column(
//             children: [
//               // --- 1. رأس المخطط (التواريخ وأسماء المهام) ---
//               SizedBox(
//                 width: totalWidth,
//                 height: _headerHeight,
//                 child: CustomPaint(
//                   painter: _GanttHeaderPainter(
//                     projectStartDate: _projectStartDate,
//                     totalDays: _totalDays,
//                     dayWidth: _dayWidth,
//                     headerHeight: _headerHeight,
//                     taskNameColumnWidth: _taskNameColumnWidth,
//                     theme: Theme.of(context),
//                   ),
//                 ),
//               ),
//               // --- 2. جسم المخطط (المهام والشبكة) ---
//               Expanded(
//                 child: CustomPaint(
//                   painter: _GanttBodyPainter(
//                     tasks: _tasks,
//                     projectStartDate: _projectStartDate,
//                     totalDays: _totalDays,
//                     dayWidth: _dayWidth,
//                     rowHeight: _rowHeight,
//                     taskNameColumnWidth: _taskNameColumnWidth,
//                     theme: Theme.of(context),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       // =========================================================
//     );
//   }
// }

// /// _GanttHeaderPainter: رسام الجزء العلوي (التواريخ).
// class _GanttHeaderPainter extends CustomPainter {
//   final DateTime projectStartDate;
//   final int totalDays;
//   final double dayWidth;
//   final double headerHeight;
//   final double taskNameColumnWidth;
//   final ThemeData theme;

//   _GanttHeaderPainter({
//     required this.projectStartDate,
//     required this.totalDays,
//     required this.dayWidth,
//     required this.headerHeight,
//     required this.taskNameColumnWidth,
//     required this.theme,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final headerPaint = Paint()..color = theme.dividerColor.withOpacity(0.1);
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), headerPaint);

//     // رسم عمود أسماء المهام
//     final taskColumnRect = Rect.fromLTWH(
//       size.width - taskNameColumnWidth,
//       0,
//       taskNameColumnWidth,
//       size.height,
//     );
//     canvas.drawRect(
//       taskColumnRect,
//       headerPaint..color = theme.dividerColor.withOpacity(0.15),
//     );
//     final taskColumnText = TextPainter(
//       text: TextSpan(text: 'المهام', style: theme.textTheme.titleSmall),
//       textDirection: TextDirection.rtl,
//     )..layout();
//     taskColumnText.paint(
//       canvas,
//       Offset(
//         taskColumnRect.center.dx - taskColumnText.width / 2,
//         taskColumnRect.center.dy - taskColumnText.height / 2,
//       ),
//     );

//     for (int i = 0; i < totalDays; i++) {
//       final x = size.width - taskNameColumnWidth - ((i + 1) * dayWidth);
//       if (x < 0) continue; // لا ترسم خارج الحدود

//       canvas.drawLine(
//         Offset(x, 0),
//         Offset(x, size.height),
//         headerPaint..color = theme.dividerColor.withOpacity(0.2),
//       );

//       final date = projectStartDate.add(Duration(days: i));
//       final dateText = TextPainter(
//         text: TextSpan(
//           text: '${date.day}/${date.month}',
//           style: theme.textTheme.bodySmall,
//         ),
//         textDirection: TextDirection.rtl,
//       )..layout();
//       dateText.paint(
//         canvas,
//         Offset(
//           x + (dayWidth / 2) - (dateText.width / 2),
//           (headerHeight / 2) - (dateText.height / 2),
//         ),
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _GanttHeaderPainter oldDelegate) => false;
// }

// /// _GanttBodyPainter: رسام جسم المخطط (المهام والشبكة).
// class _GanttBodyPainter extends CustomPainter {
//   final List<Task> tasks;
//   final DateTime projectStartDate;
//   final int totalDays;
//   final double dayWidth;
//   final double rowHeight;
//   final double taskNameColumnWidth;
//   final ThemeData theme;
//   final double taskBarHeight = 30.0;

//   _GanttBodyPainter({
//     required this.tasks,
//     required this.projectStartDate,
//     required this.totalDays,
//     required this.dayWidth,
//     required this.rowHeight,
//     required this.taskNameColumnWidth,
//     required this.theme,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     _drawGrid(canvas, size);

//     for (int i = 0; i < tasks.length; i++) {
//       final task = tasks[i];
//       final top = (i * rowHeight) + (rowHeight / 2) - (taskBarHeight / 2);

//       // رسم اسم المهمة في العمود المخصص
//       _drawTaskName(
//         canvas,
//         task.name,
//         size.width - (taskNameColumnWidth / 2),
//         top + (taskBarHeight / 2),
//       );

//       final startOffsetDays = task.startDate
//           .difference(projectStartDate)
//           .inDays;
//       final durationDays = task.endDate.difference(task.startDate).inDays;

//       final right = (startOffsetDays) * dayWidth;
//       final width = (durationDays + 1) * dayWidth;
//       final left = size.width - taskNameColumnWidth - right - width;

//       final rect = Rect.fromLTWH(left, top, width, taskBarHeight);
//       _drawTaskBar(canvas, task, rect);
//     }
//   }

//   void _drawGrid(Canvas canvas, Size size) {
//     final gridPaint = Paint()
//       ..color = theme.dividerColor.withOpacity(0.1)
//       ..strokeWidth = 1.0;

//     // رسم الخطوط العمودية
//     for (int i = 0; i < totalDays; i++) {
//       final x = size.width - taskNameColumnWidth - (i * dayWidth);
//       if (x < 0) continue;
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }

//     // رسم الخطوط الأفقية
//     for (int i = 0; i < tasks.length; i++) {
//       final y = (i + 1) * rowHeight;
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }

//     // رسم الخط الفاصل بين أسماء المهام والمخطط
//     final separatorX = size.width - taskNameColumnWidth;
//     canvas.drawLine(
//       Offset(separatorX, 0),
//       Offset(separatorX, size.height),
//       gridPaint..strokeWidth = 1.5,
//     );
//   }

//   void _drawTaskBar(Canvas canvas, Task task, Rect rect) {
//     final color = task.status == 'حرجة'
//         ? Colors.orange.shade700
//         : theme.colorScheme.primary;
//     final backgroundPaint = Paint()..color = color.withOpacity(0.3);
//     final progressPaint = Paint()..color = color;

//     final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
//     canvas.drawRRect(rrect, backgroundPaint);

//     if (task.progress > 0) {
//       final progressWidth = rect.width * task.progress;
//       final progressRect = Rect.fromLTWH(
//         rect.right - progressWidth,
//         rect.top,
//         progressWidth,
//         rect.height,
//       );
//       final progressRRect = RRect.fromRectAndRadius(
//         progressRect,
//         const Radius.circular(8),
//       );
//       canvas.drawRRect(progressRRect, progressPaint);
//     }

//     final progressText = TextPainter(
//       text: TextSpan(
//         text: '${(task.progress * 100).toInt()}%',
//         style: theme.textTheme.labelSmall?.copyWith(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       textDirection: TextDirection.rtl,
//     )..layout();
//     final textOffset = Offset(
//       rect.center.dx - (progressText.width / 2),
//       rect.center.dy - (progressText.height / 2),
//     );
//     progressText.paint(canvas, textOffset);
//   }

//   void _drawTaskName(
//     Canvas canvas,
//     String name,
//     double xCenter,
//     double yCenter,
//   ) {
//     final nameText = TextPainter(
//       text: TextSpan(text: name, style: theme.textTheme.bodyMedium),
//       textDirection: TextDirection.rtl,
//       maxLines: 2,
//       ellipsis: '...',
//       textAlign: TextAlign.center,
//     )..layout(maxWidth: taskNameColumnWidth - 20);
//     nameText.paint(
//       canvas,
//       Offset(xCenter - (nameText.width / 2), yCenter - (nameText.height / 2)),
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _GanttBodyPainter oldDelegate) {
//     return oldDelegate.tasks != tasks || oldDelegate.theme != theme;
//   }
// }
