// lib/screens/register_screen.dart

import 'dart:io'; // للتعامل مع كائن الملف (File) الخاص بصورة المستخدم.
import 'package:connectivity_plus/connectivity_plus.dart'; // للتحقق من حالة الاتصال بالإنترنت.
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // استيراد مع اسم مستعار.
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:image_picker/image_picker.dart'; // لاختيار الصور من المعرض أو الكاميرا.
import 'package:task_ly/screens/otp_screen.dart'; // شاشة إدخال رمز التحقق.
import 'package:task_ly/services/auth_service.dart'; // خدمة المصادقة.
import 'dart:async'; // للتعامل مع `StreamSubscription`.

// `enum` لتحديد وضع المصادقة الحالي (بريد إلكتروني أو هاتف).
enum AuthMode { email, phone }

/// هذه الواجهة (`StatefulWidget`) هي شاشة إنشاء حساب جديد.
/// تدعم التسجيل عبر البريد الإلكتروني وكلمة المرور، أو عبر رقم الهاتف ورمز التحقق (OTP).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- وحدات التحكم (Controllers) ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // متغير لتتبع اشتراك حالة الاتصال بالإنترنت.
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
 
  // --- متغيرات الحالة (State Variables) ---
  AuthMode _authMode = AuthMode.email; // الوضع الافتراضي هو التسجيل بالبريد.
  File? _selectedImage; // لتخزين الصورة الشخصية التي يختارها المستخدم.
  bool _obscurePassword = true; // لإخفاء/إظهار كلمة المرور.
  bool _obscureConfirmPassword = true; // لإخفاء/إظهار تأكيد كلمة المرور.
  bool _agreeToTerms = false; // هل وافق المستخدم على الشروط؟
  bool _isLoading = false; // لتحديد ما إذا كانت عملية التسجيل قيد التنفيذ.
  String? _errorMessage; // لتخزين أي رسالة خطأ.
  bool _isConnected = true; // لتخزين حالة الاتصال بالإنترنت.

  // --- الخدمات (Services) ---
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // بدء الاستماع لتغيرات حالة الاتصال بالإنترنت.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    // إلغاء الاشتراك عند إغلاق الشاشة لمنع تسرب الذاكرة.
    _connectivitySubscription.cancel();
    // تنظيف جميع وحدات التحكم.
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// دالة `_updateConnectionStatus`: تُستدعى تلقائيًا عند تغير حالة الاتصال.
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // يكفي وجود أي نوع من الاتصال (Wi-Fi أو بيانات الجوال).
    final hasConnection = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
    if (hasConnection != _isConnected) {
      setState(() => _isConnected = hasConnection);
    }
  }

  /// دالة `_pickImage`: لفتح معرض الصور والسماح للمستخدم باختيار صورة.
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  /// دالة `_register`: الدالة الرئيسية لعملية إنشاء الحساب.
  Future<void> _register() async {
    // 1. التحقق من صحة المدخلات والموافقة على الشروط.
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب الموافقة على الشروط أولاً'), backgroundColor: Colors.red));
      return;
    }

    // 2. تفعيل مؤشر التحميل.
    setState(() { _isLoading = true; _errorMessage = null; });

    // 3. التعامل مع وضع المصادقة المحدد.
    if (_authMode == AuthMode.email) {
      // --- منطق التسجيل بالبريد الإلكتروني ---
      try {
        // أ. استدعاء دالة إنشاء الحساب وإرسال رابط التفعيل.
        await _authService.createUserAccountAndSendVerification(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // ب. إذا نجحت العملية، إظهار رسالة نجاح والعودة لشاشة تسجيل الدخول.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب! الرجاء تفعيل بريدك ثم قم بتسجيل الدخول.'), backgroundColor: Colors.green, duration: Duration(seconds: 8)));
          Navigator.of(context).pop(); 
        }
      } on firebase_auth.FirebaseAuthException catch (e) {
        // ج. إذا فشلت العملية، عرض رسالة الخطأ المعالجة.
        if (mounted) setState(() => _errorMessage = _authService.handleAuthError(e));
      } catch (e, s) {
        print("RegisterScreen: [CRITICAL] An unexpected error occurred: $e\n$s");
        if (mounted) setState(() => _errorMessage = 'حدث خطأ غير متوقع: $e');
      }
    } else {
      // --- منطق التسجيل بالهاتف ---
      final fullPhoneNumber = '+967${_phoneController.text.trim()}';
      await _authService.sendOtpToPhone(
        phoneNumber: fullPhoneNumber,
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            // الانتقال إلى شاشة إدخال الرمز مع تمرير البيانات اللازمة.
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => OTPScreen(verificationId: verificationId, name: _nameController.text.trim(), phoneNumber: fullPhoneNumber, imageFile: _selectedImage)));
          }
        },
        onVerificationFailed: (e) {
          if (mounted) setState(() => _errorMessage = _authService.handleAuthError(e));
        },
        codeAutoRetrievalTimeout: (id) {},
      );
    }

    // 4. إيقاف مؤشر التحميل في نهاية العملية.
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmail = _authMode == AuthMode.email;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Stack(
            children: [
              // ... (أيقونة حالة الاتصال) ...
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ... (واجهة اختيار الصورة والنصوص الترحيبية) ...
                        FadeInUp(
                          duration: const Duration(milliseconds: 700),
                          child: Row(children: [
                            Expanded(child: _buildAuthModeToggle(theme, AuthMode.email, 'البريد', Icons.email_outlined)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildAuthModeToggle(theme, AuthMode.phone, 'الهاتف', Icons.phone_outlined)),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(delay: 800, controller: _nameController, label: 'الاسم الكامل', icon: Icons.person_outline_rounded, validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null),
                        const SizedBox(height: 20),
                        // `AnimatedSwitcher` للتبديل بين حقول البريد والهاتف بحركة ناعمة.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: isEmail
                              ? Column(key: const ValueKey('email_fields'), children: [
                                  _buildTextField(delay: 0, controller: _emailController, label: 'البريد الإلكتروني', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress, validator: (v) => (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) ? 'صيغة البريد غير صحيحة' : null),
                                  const SizedBox(height: 20),
                                  _buildTextField(delay: 0, controller: _passwordController, label: 'كلمة المرور', icon: Icons.lock_outline_rounded, isPassword: true, obscure: _obscurePassword, onObscureToggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: (v) => (v == null || v.length < 6) ? 'يجب أن تكون 6 أحرف على الأقل' : null),
                                  const SizedBox(height: 20),
                                  _buildTextField(delay: 0, controller: _confirmPasswordController, label: 'تأكيد كلمة المرور', icon: Icons.lock_outline_rounded, isPassword: true, obscure: _obscureConfirmPassword, onObscureToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), validator: (v) => (v != _passwordController.text) ? 'كلمتا المرور غير متطابقتين' : null),
                                ])
                              : _buildTextField(key: const ValueKey('phone_field'), delay: 0, controller: _phoneController, label: 'رقم الهاتف', icon: Icons.phone_outlined, keyboard: TextInputType.phone, prefixText: '+967 ', validator: (v) => (v == null || v.length < 9) ? 'الرقم غير مكتمل' : null),
                        ),
                        const SizedBox(height: 10),
                        if (_errorMessage != null) FadeIn(child: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14)))),
                        const SizedBox(height: 10),
                        // ... (مربع الموافقة على الشروط وزر إنشاء الحساب) ...
                        FadeInUp(
                          duration: const Duration(milliseconds: 1200),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('إنشاء الحساب', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت مساعد لبناء أزرار التبديل بين وضع البريد والهاتف.
  Widget _buildAuthModeToggle(ThemeData theme, AuthMode mode, String label, IconData icon) {
    final isSelected = _authMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _authMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color), const SizedBox(width: 8), Text(label, style: TextStyle(color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  /// ويدجت مساعد لبناء حقول النص بشكل موحد.
  Widget _buildTextField({Key? key, required int delay, required TextEditingController controller, required String label, required IconData icon, String? Function(String?)? validator, bool isPassword = false, bool obscure = false, VoidCallback? onObscureToggle, TextInputType? keyboard, String? prefixText}) {
    return FadeInUp(
      key: key,
      duration: Duration(milliseconds: delay),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), prefixText: prefixText, suffixIcon: isPassword ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: onObscureToggle) : null),
        validator: validator,
      ),
    );
  }
}
