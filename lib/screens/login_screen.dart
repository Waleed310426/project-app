// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:provider/provider.dart'; // للوصول إلى UserProvider.
import 'package:task_ly/models/user_model.dart';
import 'package:task_ly/providers/user_provider.dart';
import 'package:task_ly/screens/otp_screen.dart'; // شاشة إدخال رمز التحقق.
import 'package:task_ly/screens/register_screen.dart'; // شاشة التسجيل.
import 'package:task_ly/services/auth_service.dart'; // خدمة المصادقة.
import 'package:task_ly/taskly_home.dart'; // الشاشة الرئيسية (قد لا تكون مستخدمة مباشرة هنا).

// `enum` لتحديد نوع المدخل الذي أدخله المستخدم (بريد إلكتروني أو هاتف).
enum IdentifierType { none, email, phone }

/// هذه الواجهة (`StatefulWidget`) هي شاشة تسجيل الدخول.
/// تتميز بأنها "ذكية" حيث تتعرف على نوع المدخل (بريد أو هاتف) وتغير الواجهة بناءً عليه.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- وحدات التحكم (Controllers) ---
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحكم في نموذج الإدخال (Form).
  final _identifierController = TextEditingController(); // حقل موحد للبريد أو الهاتف.
  final _passwordController = TextEditingController();

  // --- متغيرات الحالة (State Variables) ---
  IdentifierType _identifierType = IdentifierType.none; // لتخزين نوع المدخل الحالي.
  bool _showPasswordField = false; // للتحكم في إظهار حقل كلمة المرور.
  bool _obscurePassword = true; // لإخفاء/إظهار كلمة المرور.
  bool _isLoading = false; // لتحديد ما إذا كانت عملية تسجيل الدخول قيد التنفيذ.
  String? _errorMessage; // لتخزين أي رسالة خطأ وعرضها للمستخدم.
  bool _isConnected = true; // (مثال) لتتبع حالة الاتصال بالإنترنت.

  // --- الخدمات (Services) ---
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// دالة `_checkIdentifier`: تتحقق من نوع المدخل (بريد أم هاتف) وتغير حالة الواجهة.
  void _checkIdentifier() {
    final input = _identifierController.text.trim();
    // استخدام تعبير نمطي (RegExp) للتحقق مما إذا كان المدخل يطابق صيغة البريد الإلكتروني.
    if (RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input)) {
      setState(() {
        _identifierType = IdentifierType.email;
        _showPasswordField = true; // إظهار حقل كلمة المرور.
        _errorMessage = null;
      });
    } 
    // استخدام تعبير نمطي للتحقق مما إذا كان المدخل يتكون من 9 أرقام أو أكثر.
    else if (RegExp(r'^[0-9]{9,}$').hasMatch(input)) {
      setState(() {
        _identifierType = IdentifierType.phone;
        _showPasswordField = false; // لا حاجة لكلمة المرور مع الهاتف.
        _errorMessage = null;
      });
      // إذا كان هاتفًا، انتقل مباشرة إلى الخطوة التالية (إرسال رمز التحقق).
      _login();
    } else {
      setState(() {
        _identifierType = IdentifierType.none;
        _errorMessage = 'الرجاء إدخال بريد إلكتروني أو رقم هاتف صحيح.';
      });
    }
  }

  /// دالة `_login`: دالة موحدة لتسجيل الدخول بناءً على نوع المدخل.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    if (_identifierType == IdentifierType.email) {
      // --- منطق تسجيل الدخول بالبريد الإلكتروني ---
      final result = await _authService.signInAndSyncUser(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result is User) {
        // إذا نجحت العملية، يتم تحديث `UserProvider` ببيانات المستخدم.
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(result);
          // لا حاجة للانتقال اليدوي، `AuthWrapper` سيستمع للتغيير ويوجه المستخدم تلقائيًا.
        }
      } else if (result is String) {
        // إذا فشلت العملية، يتم عرض رسالة الخطأ.
        setState(() { _errorMessage = result; });
      }
    } else if (_identifierType == IdentifierType.phone) {
      // --- منطق تسجيل الدخول بالهاتف ---
      final fullPhoneNumber = '+967${_identifierController.text.trim()}';
      await _authService.sendOtpToPhone(
        phoneNumber: fullPhoneNumber,
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            // الانتقال إلى شاشة إدخال الرمز.
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => OTPScreen(
                verificationId: verificationId,
                name: '', // لا نحتاج للاسم عند تسجيل الدخول.
                phoneNumber: fullPhoneNumber,
                imageFile: null,
              ),
            ));
          }
        },
        onVerificationFailed: (e) {
          setState(() { _errorMessage = _authService.handleAuthError(e); });
        },
        codeAutoRetrievalTimeout: (id) {},
      );
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  /// دالة لتسجيل الدخول باستخدام جوجل.
  Future<void> _loginWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await _authService.signInWithGoogle();

    if (result is User) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(result);
        // `AuthWrapper` سيتولى الانتقال.
      }
    } else if (result is String) {
      setState(() { _errorMessage = result; });
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                        // ... (شعار التطبيق والنصوص الترحيبية) ...
                        FadeInDown(child: Image.asset('assets/images/tasklyimage.png', height: 200)),
                        const SizedBox(height: 30),
                        FadeInUp(child: Text('أهلاً بعودتك!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium)),
                        const SizedBox(height: 8),
                        FadeInUp(child: Text('سجل الدخول للمتابعة', textAlign: TextAlign.center, style: theme.textTheme.titleMedium)),
                        const SizedBox(height: 40),

                        // حقل الإدخال الموحد للبريد أو الهاتف.
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'البريد الإلكتروني أو رقم الهاتف', prefixIcon: Icon(Icons.person_outline_rounded)),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                            onChanged: (value) {
                              // إخفاء حقل كلمة المرور عند تغيير المدخل لضمان إعادة التحقق.
                              if (_showPasswordField) setState(() => _showPasswordField = false);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // إظهار حقل كلمة المرور بشكل ديناميكي مع تأثير حركة.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) => SizeTransition(sizeFactor: animation, child: child),
                          child: _showPasswordField
                              ? FadeInUp(
                                  key: const ValueKey('password'),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'كلمة المرور',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (_identifierType == IdentifierType.email && (value == null || value.isEmpty)) {
                                        return 'هذا الحقل مطلوب';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('no_password')),
                        ),
                        const SizedBox(height: 10),

                        // عرض رسالة الخطأ إذا وجدت.
                        if (_errorMessage != null)
                          FadeIn(child: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14)))),
                        const SizedBox(height: 20),

                        // زر ديناميكي يتغير نصه ووظيفته.
                        FadeInUp(
                          duration: const Duration(milliseconds: 1000),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _isLoading ? null : (_showPasswordField ? _login : _checkIdentifier),
                            child: _isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text(_showPasswordField ? 'تسجيل الدخول' : 'متابعة', style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // زر تسجيل الدخول بجوجل.
                        FadeInUp(
                          duration: const Duration(milliseconds: 1100),
                          child: OutlinedButton.icon(
                            icon: Image.asset('assets/images/Google-Logo.png', height: 24.0),
                            label: const Text('المتابعة باستخدام جوجل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _isLoading ? null : _loginWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // رابط الانتقال إلى شاشة التسجيل.
                        FadeInUp(
                          duration: const Duration(milliseconds: 1100),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('ليس لديك حساب؟'),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen())),
                                child: const Text('سجل الآن'),
                              ),
                            ],
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
}
