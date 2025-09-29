import 'package:flutter/material.dart';
import 'package:medication_reminder_system/page/tabbar_page.dart';
import 'package:medication_reminder_system/page/register_page.dart';
import 'package:medication_reminder_system/page/settings_page.dart';
import 'package:medication_reminder_system/api/login_api.dart';
import 'package:medication_reminder_system/page/request_otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const LoginForm(),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // ✅ เปลี่ยน timeout เป็น 5 วินาที
  static const Duration _loginTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    // ✅ ซ่อนแป้นพิมพ์เมื่อโหลดหน้าเสร็จ (แค่ครั้งแรก)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dismissKeyboard();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ ฟังก์ชันล้าง focus ทุกฟิลด์
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) return false;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return false;
    }

    if (!LoginApi.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รูปแบบอีเมลไม่ถูกต้อง')),
      );
      return false;
    }

    return true;
  }

  // ✅ แก้ไขฟังก์ชัน login ให้มี timeout 5 วินาที
  Future<void> _callLoginApi() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // ✅ ใส่ timeout 5 วินาที
      final result = await Future.any([
        LoginApi.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
        // ✅ ถ้าเกิน 5 วินาที ให้ throw TimeoutException
        Future.delayed(_loginTimeout).then((_) => throw TimeoutException()),
      ]);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final userData = data['user'];
        final connections = data['connections'];
        final hasConnection = data['hasConnection'];

        // สร้าง welcome message
        final welcomeMessage = await LoginApi.createWelcomeMessage(userData);

        // ปิด loading และนำทางไปหน้าใหม่
        setState(() => _isLoading = false);

        if (hasConnection && connections.isNotEmpty) {
          // ไปหน้าหลัก
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => _PageWithNotification(
                  message: welcomeMessage,
                  child: CustomTabBar(
                    userData: userData,
                    connections: List<Map<String, dynamic>>.from(connections),
                  ),
                ),
              ),
            );
          }
        } else {
          // ไปหน้า Settings
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => _PageWithNotification(
                  message: welcomeMessage,
                  child: SettingsPage(),
                ),
              ),
            );
          }
        }
      } else {
        // ✅ แสดงข้อความ error แบบปลอดภัย - ไม่เปิดเผยว่ามี email ในระบบหรือไม่
        _showErrorSnackBar('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      }
    } on TimeoutException {
      // ✅ จัดการกรณี timeout - แสดงข้อความเฉพาะสำหรับ timeout
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง');
      }
    } catch (e) {
      // ✅ จัดการ error อื่นๆ - แยกเฉพาะ network error เท่านั้น
      if (mounted) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('HandshakeException') ||
            e.toString().contains('connection') ||
            e.toString().contains('network')) {
          _showErrorSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
        } else {
          // ✅ error อื่นๆ ให้ใช้ข้อความเดียวกับ auth error
          _showErrorSnackBar('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ ฟังก์ชันแสดง error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _login() {
    // ✅ ซ่อนแป้นพิมพ์ก่อนเข้าสู่ระบบ
    _dismissKeyboard();
    
    if (_validateInputs()) {
      _callLoginApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ เพิ่ม GestureDetector เพื่อจับการแตะ
      onTap: _dismissKeyboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          // ✅ ปิด auto validate เพื่อไม่ให้ focus อัตโนมัติ
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'ยินดีต้อนรับ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'เข้าสู่ระบบเตือนการรับประทานยา',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                // ✅ ปิด autofocus เพื่อไม่ให้แป้นพิมพ์ขึ้นอัตโนมัติ
                autofocus: false,
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                // ✅ ปิด text input action เพื่อไม่ให้กระโดดไป field ถัดไปอัตโนมัติ
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
                  if (!LoginApi.isValidEmail(value)) return 'กรุณากรอกอีเมลให้ถูกต้อง';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                // ✅ ปิด autofocus
                autofocus: false,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                  if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  return null;
                },
                // ✅ เมื่อกด Done บนแป้นพิมพ์ให้ทำการ login
                onFieldSubmitted: (_) => _login(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // ✅ ซ่อนแป้นพิมพ์ก่อนไปหน้าใหม่
                    _dismissKeyboard();
                    
                    // ✅ ไปหน้า RequestOtpPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestOtpPage(),
                      ),
                    );
                  },
                  child: const Text('ลืมรหัสผ่าน?'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'กำลังเข้าสู่ระบบ...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ยังไม่มีบัญชีผู้ใช้?'),
                  TextButton(
                    onPressed: () {
                      // ✅ ซ่อนแป้นพิมพ์ก่อนไปหน้าสมัครสมาชิก
                      _dismissKeyboard();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ).then((_) {
                        // ✅ เมื่อกลับมาให้ซ่อนแป้นพิมพ์
                        if (mounted) {
                          _dismissKeyboard();
                        }
                      });
                    },
                    child: const Text('สมัครสมาชิก', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ สร้าง TimeoutException class
class TimeoutException implements Exception {
  final String message;
  
  const TimeoutException([this.message = 'Operation timed out']);
  
  @override
  String toString() => 'TimeoutException: $message';
}

// Wrapper เดียวสำหรับแสดงการแจ้งเตือนหลังโหลดหน้าเสร็จ
class _PageWithNotification extends StatefulWidget {
  final Widget child;
  final String message;

  const _PageWithNotification({
    required this.message,
    required this.child,
  });

  @override
  State<_PageWithNotification> createState() => _PageWithNotificationState();
}

class _PageWithNotificationState extends State<_PageWithNotification> {
  @override
  void initState() {
    super.initState();
    // แสดงการแจ้งเตือนหลังหน้าโหลดเสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showTopNotification();
        }
      });
    });
  }

  void _showTopNotification() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => overlayEntry.remove(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // ลบอัตโนมัติหลัง 3 วินาที
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}