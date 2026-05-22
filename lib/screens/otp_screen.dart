// lib/screens/otp_screen.dart

// --- 1. استيراد الحزم الأساسية ---
import 'dart:async'; // للتعامل مع المؤقت (Timer) لإعادة إرسال الرمز.
import 'dart:io';   // للتعامل مع كائن الملف (File) الخاص بصورة المستخدم.
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:animate_do/animate_do.dart'; // لإضافة الحركات الجمالية.
import 'package:pinput/pinput.dart'; // لتصميم حقول إدخال الرمز (OTP) بشكل احترافي.
import 'package:provider/provider.dart'; // لإدارة الحالة والوصول لبيانات المستخدم في كل مكان.

// --- 2. استيراد ملفات المشروع مع أسماء مستعارة واضحة ---

// نستورد نموذج المستخدم الخاص بنا ونعطيه اسمًا مستعارًا "app_user".
// هذا يحل مشكلة التعارض بين `User` الخاص بنا و `User` الخاص بـ Firebase.
import 'package:task_ly/models/user_model.dart' as app_user; 

// نستورد حزمة مصادقة Firebase ونعطيها اسمًا مستعارًا "firebase_auth".
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:task_ly/helpers/database_helper.dart'; // للتعامل مع قاعدة البيانات المحلية SQLite.
import 'package:task_ly/providers/user_provider.dart'; // لتحديث بيانات المستخدم المتاحة للتطبيق.
import 'package:task_ly/services/auth_service.dart'; // للوصول لدوال المصادقة.
import 'package:task_ly/taskly_home.dart'; // الشاشة الرئيسية للانتقال إليها بعد النجاح.

// --- 3. تعريف الواجهة (Widget) ---
class OTPScreen extends StatefulWidget {
  // هذه هي البيانات التي يتم تمريرها من شاشة التسجيل أو تسجيل الدخول إلى هذه الشاشة.
  final String verificationId; // المعرف الذي يرسله Firebase عند إرسال الرمز.
  final String name;           // اسم المستخدم الذي أدخله (يكون فارغًا في حالة تسجيل الدخول).
  final String phoneNumber;    // رقم الهاتف للتحقق منه.
  final File? imageFile;       // الصورة الشخصية التي اختارها (اختياري).

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.name,
    required this.phoneNumber,
    this.imageFile,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

// --- 4. حالة الواجهة (State) ---
class _OTPScreenState extends State<OTPScreen> {
  // وحدات التحكم والمتغيرات الخاصة بالحالة.
  final _otpController = TextEditingController(); // للتحكم في النص داخل حقول Pinput.
  final _authService = AuthService(); // نسخة من خدمة المصادقة للوصول لدوالها.

  bool _isLoading = false; // لتحديد ما إذا كنا نعرض مؤشر تحميل أم لا.
  String? _errorMessage; // لتخزين وعرض أي رسالة خطأ.

  // متغيرات خاصة بمؤقت إعادة الإرسال.
  late Timer _timer; // المؤقت نفسه.
  int _start = 60;   // عدد الثواني للعد التنازلي.
  bool _canResend = false; // هل يمكن للمستخدم الضغط على زر "إعادة الإرسال"؟

  // --- 5. دوال دورة حياة الواجهة (Lifecycle Methods) ---
  @override
  void initState() {
    super.initState();
    startTimer(); // بدء المؤقت فور بناء الواجهة.
  }

  @override
  void dispose() {
    _timer.cancel(); // مهم جدًا: إلغاء المؤقت عند إغلاق الشاشة لمنع تسرب الذاكرة.
    _otpController.dispose(); // تنظيف وحدة التحكم.
    super.dispose();
  }

  // --- 6. الدوال المنطقية (Logic Functions) ---

  /// دالة لبدء العد التنازلي لمؤقت إعادة الإرسال.
  void startTimer() {
    setState(() => _canResend = false); // في البداية، لا يمكن إعادة الإرسال.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        // إذا انتهى الوقت.
        if (mounted) { // التأكد من أن الواجهة لا تزال موجودة.
          setState(() => _canResend = true); // الآن يمكن إعادة الإرسال.
        }
        timer.cancel(); // إيقاف المؤقت.
      } else {
        // إذا لم ينته الوقت.
        if (mounted) {
          setState(() => _start--); // إنقاص ثانية واحدة.
        }
      }
    });
  }

  /// دالة لإعادة إرسال رمز التحقق.
  Future<void> _resendOTP() async {
    // TODO: استدعاء دالة إرسال الرمز من AuthService مرة أخرى.
    print("طلب إعادة إرسال الرمز إلى ${widget.phoneNumber}");
    setState(() {
      _start = 60; // إعادة ضبط المؤقت.
      _canResend = false;
    });
    startTimer(); // بدء المؤقت من جديد.
  }

  // --- 7. الدالة الرئيسية: التحقق من الرمز وحفظ المستخدم ---
  Future<void> _verifyOTP() async {
    // التحقق من أن المستخدم أدخل 6 أرقام.
    if (_otpController.text.length != 6) {
      setState(() => _errorMessage = 'الرجاء إدخال الرمز المكون من 6 أرقام.');
      return; // الخروج من الدالة.
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    // استدعاء دالة التحقق من AuthService.
    // نعلن صراحة أننا نتوقع كائنًا من نوع "User" من حزمة "firebase_auth".
    final firebase_auth.User? firebaseUser = await _authService.verifyOtpAndSignIn(
      widget.verificationId,
      _otpController.text,
    );

    if (firebaseUser != null) {
      // --- نجح التحقق مع Firebase ---

      // التحقق مما إذا كانت هذه عملية "تسجيل" جديدة (عن طريق التحقق من وجود اسم).
      if (widget.name.isNotEmpty) {
        // --- هذه عملية تسجيل مستخدم جديد ---

        // 1. إنشاء كائن من نموذجنا الخاص (app_user.User).
        final newUser = app_user.User.createNew(
          id: firebaseUser.uid,
          name: widget.name,
          email: firebaseUser.email,
          phoneNumber: widget.phoneNumber,
          avatarUrl: null, // سيتم تحديث هذا لاحقًا بعد رفع الصورة.
        );

        // 2. حفظ المستخدم الجديد في قاعدة البيانات المحلية SQLite.
        await DatabaseHelper.instance.insert(DatabaseHelper.tableUsers, newUser.toMap());
        print("✅ المستخدم الجديد تم حفظه في قاعدة البيانات المحلية بنجاح!");

        // 3. تحديث الـ Provider ببيانات المستخدم الجديد لتكون متاحة لكل التطبيق.
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(newUser);
        }
      } else {
        // --- هذه عملية تسجيل دخول لمستخدم موجود مسبقًا ---
        print("ℹ️ المستخدم قام بتسجيل الدخول (موجود مسبقًا).");
        // TODO: هنا يجب جلب بيانات المستخدم الكاملة من SQLite باستخدام "firebaseUser.uid"
        // ثم تحديث الـ Provider بها.
      }

      // 4. الانتقال إلى الشاشة الرئيسية بعد نجاح العملية.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التحقق بنجاح! مرحبًا بك.'), backgroundColor: Colors.green),
        );
        // استخدام pushAndRemoveUntil لإزالة كل شاشات المصادقة من المكدس (stack).
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TasklyHome()),
          (route) => false,
        );
      }
    } else {
      // --- فشل التحقق مع Firebase ---
      setState(() => _errorMessage = "رمز التحقق غير صحيح أو انتهت صلاحيته.");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- 8. بناء واجهة المستخدم (build) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // إعدادات التصميم الافتراضية لحقول Pinput.
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- الشعار أو الصورة العلوية ---
                  FadeInDown(child: Image.asset('assets/images/Tt.png', height: 180)),
                  const SizedBox(height: 30),

                  // --- عنوان الصفحة ---
                  FadeInUp(child: Text('التحقق من رقم الهاتف', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  FadeInUp(child: Text('أدخل الرمز المكون من 6 أرقام الذي تم إرساله إلى الرقم:\n${widget.phoneNumber}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600, height: 1.5))),
                  const SizedBox(height: 40),

                  // --- حقول إدخال الرمز (Pinput) ---
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Pinput(
                      length: 6,
                      controller: _otpController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: theme.colorScheme.primary))),
                      errorPinTheme: defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: Colors.red))),
                      onCompleted: (pin) => _verifyOTP(), // استدعاء دالة التحقق تلقائيًا عند اكتمال الإدخال.
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- عرض رسالة الخطأ (إذا وجدت) ---
                  if (_errorMessage != null)
                    FadeIn(child: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14)))),
                  const SizedBox(height: 30),

                  // --- زر التحقق ---
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _isLoading ? null : _verifyOTP,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('تحقق', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- زر ومؤقت إعادة الإرسال ---
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('لم تستلم الرمز؟', style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: _canResend ? _resendOTP : null, // الزر يكون مفعلاً فقط إذا كان _canResend = true.
                          child: Text(
                            _canResend ? 'أعد الإرسال' : 'أعد الإرسال بعد $_start ثانية',
                            style: TextStyle(color: _canResend ? theme.colorScheme.primary : Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
