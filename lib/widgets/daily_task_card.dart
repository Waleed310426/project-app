// lib/widgets/daily_task_card.dart

import 'dart:async'; // للتعامل مع المؤقت (Timer).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق الوقت والعملة.
import 'package:percent_indicator/circular_percent_indicator.dart'; // لمؤشر التقدم الدائري.

import '../models/daily_task_model.dart';

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض بطاقة مهمة يومية واحدة.
/// تعرض تفاصيل المهمة مثل الاسم، الوقت، الميزانية، وحالة الإنجاز.
/// تحتوي على مؤقت للعد التنازلي للوقت المتبقي.
class DailyTaskCard extends StatefulWidget {
  final DailyTask task;
  final bool isSelected; // هل البطاقة محددة في وضع التحديد المتعدد؟
  final VoidCallback onLongPress; // دالة تُستدعى عند الضغط المطول.
  final VoidCallback onTap; // دالة تُستدعى عند الضغط العادي.
  final Function(DailyTask) onStatusChanged; // دالة لتغيير حالة الإنجاز.
  final Function(DailyTask) onFavoriteChanged; // دالة لتغيير حالة المفضلة.

  const DailyTaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onLongPress,
    required this.onTap,
    required this.onStatusChanged,
    required this.onFavoriteChanged,
  });

  @override
  State<DailyTaskCard> createState() => _DailyTaskCardState();
}

class _DailyTaskCardState extends State<DailyTaskCard> {
  Timer? _timer; // المؤقت لتحديث الوقت المتبقي.
  Duration _remainingTime = Duration.zero; // لتخزين الوقت المتبقي.

  @override
  void initState() {
    super.initState();
    // بدء المؤقت فقط إذا كانت المهمة لها وقت انتهاء وغير مكتملة.
    if (widget.task.endTime != null && !widget.task.isCompleted) {
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingTime();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DailyTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تشغيل المؤقت إذا تغيرت المهمة (وقت الانتهاء أو حالة الإنجاز).
    if (widget.task.endTime != oldWidget.task.endTime || widget.task.isCompleted != oldWidget.task.isCompleted) {
      _timer?.cancel();
      if (widget.task.endTime != null && !widget.task.isCompleted) {
        _updateRemainingTime();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateRemainingTime());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف المؤقت عند إغلاق الواجهة لمنع تسرب الذاكرة.
    super.dispose();
  }

  /// دالة `_updateRemainingTime`: لحساب وتحديث الوقت المتبقي كل ثانية.
  void _updateRemainingTime() {
    final now = DateTime.now();
    if (widget.task.endTime != null && now.isBefore(widget.task.endTime!)) {
      if (mounted) setState(() => _remainingTime = widget.task.endTime!.difference(now));
    } else {
      if (mounted) setState(() => _remainingTime = Duration.zero);
      _timer?.cancel(); // إيقاف المؤقت إذا انتهى الوقت.
    }
  }

  /// دالة `_getTaskStatus`: لتحديد نص ولون حالة المهمة.
  (String, Color) _getTaskStatus() {
    if (widget.task.isCompleted) return ('مكتملة', Colors.green.shade600);
    if (widget.task.endTime != null && DateTime.now().isAfter(widget.task.endTime!)) {
      return ('متأخرة', Colors.red.shade600);
    }
    return ('نشطة', Theme.of(context).colorScheme.primary);
  }

  /// دالة `_formatRemainingTime`: لتنسيق الوقت المتبقي في شكل نصي.
  String _formatRemainingTime() {
    if (_remainingTime.isNegative || _remainingTime.inSeconds == 0) return "انتهى الوقت";
    if (_remainingTime.inDays > 0) return 'باقي: ${_remainingTime.inDays} يوم و ${_remainingTime.inHours.remainder(24)} ساعة';
    
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusText, statusColor) = _getTaskStatus();
    final timeFormat = DateFormat.jm('ar');
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.س');

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.isSelected ? theme.colorScheme.primary : Colors.transparent, width: 2),
        ),
        elevation: widget.isSelected ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
          child: Row(
            children: [
              // --- مؤشر التقدم الدائري ---
              CircularPercentIndicator(
                radius: 35.0,
                lineWidth: 8.0,
                percent: widget.task.isCompleted ? 1.0 : 0.0,
                center: IconButton(
                  icon: Icon(widget.task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: statusColor, size: 30),
                  onPressed: () => widget.onStatusChanged(widget.task),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: statusColor.withOpacity(0.2),
                progressColor: statusColor,
              ),
              const SizedBox(width: 16),
              // --- تفاصيل المهمة ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- السطر الأول: الاسم وأيقونة المفضلة ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.task.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(widget.task.isFavorite ? Icons.favorite : Icons.favorite_border, color: widget.task.isFavorite ? Colors.amber : theme.iconTheme.color),
                          onPressed: () => widget.onFavoriteChanged(widget.task),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // --- السطر الثاني: الوقت والميزانية ---
                    Row(
                      children: [
                        if (widget.task.startTime != null) ...[
                          Icon(Icons.access_time_rounded, size: 16, color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 6),
                          Text('${timeFormat.format(widget.task.startTime!)}${widget.task.endTime != null ? ' - ${timeFormat.format(widget.task.endTime!)}' : ''}', style: theme.textTheme.bodySmall),
                          const SizedBox(width: 12),
                        ],
                        if (widget.task.budget != null && widget.task.budget! > 0) ...[
                          Icon(Icons.account_balance_wallet_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 6),
                          Text(currencyFormat.format(widget.task.budget), style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // --- السطر الثالث: الحالة والوقت المتبقي ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                        ),
                        if (widget.task.endTime != null && !widget.task.isCompleted)
                          Text(
                            _formatRemainingTime(),
                            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: _remainingTime.inHours < 1 ? Colors.red.shade700 : theme.colorScheme.primary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
