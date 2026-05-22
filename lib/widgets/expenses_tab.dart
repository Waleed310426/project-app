// lib/widgets/expenses_tab.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:intl/intl.dart'; // لتنسيق الأرقام (كالعملات) والتواريخ.
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية عند ظهور العناصر.
import 'package:uuid/uuid.dart'; // لإنشاء معرفات فريدة عالميًا (UUIDs) للمصروفات الجديدة.

// --- 2. استيراد ملفات المشروع ---
import '../helpers/database_helper.dart'; // للوصول إلى دوال قاعدة البيانات (جلب، حفظ، حذف).
import '../models/expense_model.dart'; // لاستخدام نموذج البيانات `Expense`.

// =========================================================================
// الفئة الرئيسية: ExpensesTab
// =========================================================================
/// هذه الواجهة (`StatefulWidget`) هي المسؤولة عن عرض تبويب "المصروفات" بالكامل.
/// تم تصميمها لتكون مرنة، حيث يمكنها عرض المصروفات المرتبطة بمشروع (`projectId`)
/// أو بمهمة (`taskId`).
///
/// تستخدم `FutureBuilder` لجلب البيانات بشكل غير متزامن وعرض مؤشر تحميل أثناء ذلك.
class ExpensesTab extends StatefulWidget {
  // --- الخصائص (Properties) ---
  final String? projectId; // معرف المشروع (إذا كانت المصروفات تابعة لمشروع).
  final String? taskId; // معرف المهمة (إذا كانت المصروفات تابعة لمهمة).
  final double? budget; // الميزانية الإجمالية للمشروع/المهمة لعرضها في الملخص المالي.

  // --- المُنشئ (Constructor) ---
  const ExpensesTab({super.key, this.projectId, this.taskId, this.budget})
      // `assert` هو شرط للتحقق أثناء التطوير. يضمن أن أحد المعرفين (projectId أو taskId)
      // قد تم تمريره، وإلا سيطلق خطأ. هذا يمنع استخدام الواجهة بشكل غير صحيح.
      : assert(projectId != null || taskId != null);

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

// =========================================================================
// حالة الفئة الرئيسية: _ExpensesTabState
// =========================================================================
class _ExpensesTabState extends State<ExpensesTab> {
  // --- متغيرات الحالة (State Variables) ---

  // `Future<List<Expense>>` هو متغير سيحتوي على نتيجة عملية جلب المصروفات من قاعدة البيانات.
  // استخدامه مع `FutureBuilder` يسمح ببناء الواجهة بشكل تفاعلي بناءً على حالة الـ Future
  // (قيد الانتظار، مكتمل بنجاح، أو مكتمل بخطأ).
  late Future<List<Expense>> _expensesFuture;

  // --- دورة حياة الواجهة (Lifecycle Methods) ---

  @override
  void initState() {
    super.initState();
    // عند بناء الواجهة لأول مرة، نبدأ عملية جلب المصروفات.
    _expensesFuture = _loadExpenses();
  }

  // --- الدوال المنطقية (Logic Functions) ---

  /// دالة `_loadExpenses`: مسؤولة عن جلب قائمة المصروفات من قاعدة البيانات.
  /// هي دالة `async` لأنها تنتظر نتيجة من قاعدة البيانات.
  /// @returns `Future<List<Expense>>` قائمة بالمصروفات.
  Future<List<Expense>> _loadExpenses() async {
    List<Map<String, dynamic>> expensesData;
    // التحقق من نوع الأب (مشروع أم مهمة) لجلب البيانات الصحيحة.
    if (widget.projectId != null) {
      expensesData = await DatabaseHelper.instance.getExpensesForProject(widget.projectId!);
    } else {
      expensesData = await DatabaseHelper.instance.getExpensesForTask(widget.taskId!);
    }
    // تحويل قائمة الـ `Map` القادمة من قاعدة البيانات إلى قائمة من كائنات `Expense`.
    return expensesData.map((e) => Expense.fromMap(e)).toList();
  }

  /// دالة `_refreshData`: تُستخدم لإعادة تحميل البيانات من جديد.
  /// تقوم بتعيين `_expensesFuture` إلى استدعاء جديد لـ `_loadExpenses()`,
  /// مما يؤدي إلى إعادة بناء `FutureBuilder` وتحديث الواجهة.
  void _refreshData() {
    setState(() {
      _expensesFuture = _loadExpenses();
    });
  }

  /// دالة `_showAddEditExpenseSheet`: مسؤولة عن إظهار الورقة السفلية (Bottom Sheet).
  /// يمكنها إظهار الورقة فارغة (لإضافة مصروف جديد) أو مع بيانات مصروف موجود (لتعديله).
  /// @param expense (اختياري): المصروف الذي سيتم تعديله.
  void _showAddEditExpenseSheet({Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // يسمح للورقة بأخذ ارتفاع الشاشة الكامل إذا لزم الأمر.
      backgroundColor: Colors.transparent, // لجعل زوايا الورقة دائرية.
      builder: (context) => AddEditExpenseSheet(
        projectId: widget.projectId,
        taskId: widget.taskId,
        expenseToEdit: expense, // تمرير المصروف للتعديل.
        onSaved: _refreshData, // تمرير دالة التحديث ليتم استدعاؤها بعد الحفظ.
      ),
    );
  }

  // --- بناء الواجهة (UI Build Method) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // زر عائم لإضافة مصروف جديد.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditExpenseSheet(),
        child: const Icon(Icons.add),
      ),
      // استخدام `FutureBuilder` لبناء الواجهة بناءً على حالة جلب البيانات.
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          // الحالة 1: البيانات لا تزال قيد التحميل.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // الحالة 2: حدث خطأ أثناء جلب البيانات.
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          // الحالة 3: البيانات تم جلبها بنجاح.
          final expenses = snapshot.data ?? []; // إذا كانت البيانات null، استخدم قائمة فارغة.
          // حساب إجمالي المصروفات باستخدام `fold`.
          final totalExpenses = expenses.fold<double>(0.0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              // عرض بطاقة الملخص المالي في الأعلى.
              _buildFinancialSummary(totalExpenses),
              // عرض قائمة المصروفات أو رسالة "لا توجد مصروفات".
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('لا توجد مصروفات مسجلة.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          // استخدام `FadeInUp` لإضافة تأثير ظهور تدريجي للبطاقات.
                          return FadeInUp(
                            from: 20,
                            delay: Duration(milliseconds: index * 50),
                            child: _buildExpenseCard(expense),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ويدجت `_buildFinancialSummary`: مسؤولة عن بناء بطاقة الملخص المالي.
  /// @param totalExpenses: إجمالي المصروفات المحسوب.
  Widget _buildFinancialSummary(double totalExpenses) {
    final budget = widget.budget ?? 0.0;
    final remaining = budget - totalExpenses;
    // حساب نسبة المصروفات من الميزانية (بين 0 و 1).
    final progress = budget > 0 ? (totalExpenses / budget).clamp(0.0, 1.0) : 0.0;
    // إعداد تنسيق العملة.
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.س');

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الملخص المالي', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // عرض شريط التقدم فقط إذا كانت هناك ميزانية محددة.
            if (budget > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.green.withOpacity(0.2),
                  // تغيير لون الشريط إلى الأحمر إذا تجاوزت المصروفات 85% من الميزانية.
                  valueColor: AlwaysStoppedAnimation<Color>(progress > 0.85 ? Colors.red : Colors.green),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (budget > 0) _InfoColumn('الميزانية', currencyFormat.format(budget), Colors.blue),
                _InfoColumn('المصروفات', currencyFormat.format(totalExpenses), Colors.red),
                if (budget > 0) _InfoColumn('المتبقي', currencyFormat.format(remaining), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ويدجت `_buildExpenseCard`: مسؤولة عن بناء بطاقة مصروف واحد.
  /// @param expense: كائن المصروف الذي سيتم عرضه.
  Widget _buildExpenseCard(Expense expense) {
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.س');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          // عرض صورة الفاتورة إذا كان الرابط موجودًا.
          backgroundImage: expense.receiptUrl != null ? NetworkImage(expense.receiptUrl!) : null,
          // عرض أيقونة إذا لم يكن هناك رابط.
          child: expense.receiptUrl == null ? const Icon(Icons.receipt_long) : null,
        ),
        title: Text(expense.description),
        subtitle: Text(DateFormat.yMMMd('ar').format(expense.date)),
        trailing: Text(currencyFormat.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        // عند الضغط على البطاقة، تفتح ورقة التعديل.
        onTap: () => _showAddEditExpenseSheet(expense: expense),
      ),
    );
  }
}

// =========================================================================
// ويدجت مساعد: _InfoColumn
// =========================================================================
/// ويدجت بسيط وقابل لإعادة الاستخدام لعرض معلومة (عنوان وقيمة) بشكل عمودي.
class _InfoColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _InfoColumn(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

// =========================================================================
// الفئة الثانية: AddEditExpenseSheet
// =========================================================================
/// ورقة سفلية (`StatefulWidget`) لإضافة أو تعديل مصروف.
/// تحتوي على نموذج (Form) للتحقق من صحة المدخلات.
class AddEditExpenseSheet extends StatefulWidget {
  final String? projectId;
  final String? taskId;
  final Expense? expenseToEdit; // المصروف الحالي للتعديل (يكون null عند الإضافة).
  final VoidCallback onSaved; // دالة تُستدعى بعد الحفظ لإعادة تحميل البيانات في الشاشة الأم.

  const AddEditExpenseSheet({super.key, this.projectId, this.taskId, this.expenseToEdit, required this.onSaved});

  @override
  State<AddEditExpenseSheet> createState() => _AddEditExpenseSheetState();
}

// =========================================================================
// حالة الفئة الثانية: _AddEditExpenseSheetState
// =========================================================================
class _AddEditExpenseSheetState extends State<AddEditExpenseSheet> {
  // --- متغيرات الحالة (State Variables) ---
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحكم في النموذج والتحقق من صحته.
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptUrlController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final String _currentUserId = 'user_main_001'; // TODO: يجب أن يأتي هذا من Provider.

  @override
  void initState() {
    super.initState();
    // إذا كان هناك مصروف للتعديل، قم بملء الحقول ببياناته الحالية.
    if (widget.expenseToEdit != null) {
      _descriptionController.text = widget.expenseToEdit!.description;
      _amountController.text = widget.expenseToEdit!.amount.toString();
      _receiptUrlController.text = widget.expenseToEdit!.receiptUrl ?? '';
      _selectedDate = widget.expenseToEdit!.date;
    }
  }

  /// دالة `_saveExpense`: لحفظ المصروف (سواء كان جديدًا أو معدلاً).
  Future<void> _saveExpense() async {
    // التحقق من صحة جميع الحقول في النموذج.
    if (!_formKey.currentState!.validate()) return;

    // إنشاء كائن `Expense` بالبيانات الجديدة.
    final expenseToSave = Expense(
      id: widget.expenseToEdit?.id ?? const Uuid().v4(), // استخدام المعرف القديم أو إنشاء جديد.
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      projectId: widget.projectId,
      taskId: widget.taskId,
      recordedByUserId: _currentUserId,
      receiptUrl: _receiptUrlController.text.isNotEmpty ? _receiptUrlController.text : null,
      createdAt: widget.expenseToEdit?.createdAt ?? DateTime.now(),
      isSynced: false,
    );

    // حفظ الكائن في قاعدة البيانات.
    await DatabaseHelper.instance.saveExpense(expenseToSave);
    
    // إغلاق الورقة السفلية.
    Navigator.pop(context);
    // استدعاء دالة التحديث في الشاشة الأم.
    widget.onSaved();
  }
  
  /// دالة `_deleteExpense`: لحذف المصروف.
  Future<void> _deleteExpense() async {
    if (widget.expenseToEdit != null) {
      await DatabaseHelper.instance.deleteExpense(widget.expenseToEdit!.id);
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      // استخدام `Padding` مع `viewInsets` يضمن أن الواجهة ترتفع فوق لوحة المفاتيح.
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // لجعل العمود يأخذ أقل ارتفاع ممكن.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.expenseToEdit == null ? 'إضافة مصروف' : 'تعديل المصروف', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                validator: (v) => v!.isEmpty ? 'الوصف مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'المبلغ مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiptUrlController,
                decoration: const InputDecoration(labelText: 'رابط صورة الفاتورة (اختياري)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveExpense,
                icon: const Icon(Icons.save),
                label: const Text('حفظ'),
              ),
              // عرض زر الحذف فقط في وضع التعديل.
              if (widget.expenseToEdit != null)
                TextButton.icon(
                  onPressed: _deleteExpense,
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  label: Text('حذف المصروف', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
