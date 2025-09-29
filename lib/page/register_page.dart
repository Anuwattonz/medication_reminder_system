import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/register_api.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: const SafeArea(
        child: RegisterForm(),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // ✅ เพิ่ม timeout 5 วินาที เหมือนหน้า login
  static const Duration _registerTimeout = Duration(seconds: 5);

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// ฟังก์ชันซ่อนแป้นพิมพ์
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  /// ลงทะเบียนโดยใช้ RegisterApi พร้อม timeout
  Future<void> _register() async {
    // ✅ ซ่อนแป้นพิมพ์ก่อน
    _dismissKeyboard();
    
    if (_formKey.currentState!.validate()) {
      // ตรวจสอบรหัสผ่านตรงกันหรือไม่
      if (_passwordController.text != _confirmController.text) {
        _showErrorSnackBar('รหัสผ่านไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final username = _usernameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // ✅ เพิ่ม timeout 5 วินาที
        final result = await Future.any([
          RegisterApi.registerWithRetry(
            username: username,
            email: email,
            password: password,
            maxRetries: 3,
          ),
          // ✅ ถ้าเกิน 5 วินาที ให้ throw TimeoutException
          Future.delayed(_registerTimeout).then((_) => throw TimeoutException()),
        ]);

        if (!mounted) return;

        if (result['success'] == true) {
          // สมัครสมาชิกสำเร็จ
          _showSuccessSnackBar(result['message'] ?? 'ลงทะเบียนสำเร็จ กรุณาเข้าสู่ระบบ');
          
          // กลับไปหน้าเข้าสู่ระบบ
          Navigator.of(context).pop();
        } else {
          // ✅ แสดงข้อความ error แบบปลอดภัย - เช็คเฉพาะ email ซ้ำ
          String errorMessage = 'ข้อมูลไม่ถูกต้อง';
          
          // ตรวจสอบเฉพาะ email ซ้ำ (ไม่เช็ค username เลย)
          final message = result['message']?.toString().toLowerCase() ?? '';
          if (message.contains('อีเมลนี้ถูกใช้ไปแล้ว') || 
              message.contains('email') && (message.contains('exist') || message.contains('ใช้'))) {
            errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่น';
          }
          // ✅ ลบการเช็ค username ออกไปแล้ว - ไม่แจ้งเตือนว่า username ซ้ำ
          
          _showErrorSnackBar(errorMessage);
        }

      } on TimeoutException {
        // ✅ จัดการกรณี timeout
        if (mounted) {
          _showErrorSnackBar('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
        }
      } catch (e) {
        // ✅ จัดการ error อื่นๆ
        if (!mounted) return;
        
        if (e.toString().contains('SocketException') || 
            e.toString().contains('HandshakeException') ||
            e.toString().contains('connection') ||
            e.toString().contains('network')) {
          _showErrorSnackBar('ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต');
        } else {
          _showErrorSnackBar('การสมัครสมาชิกล้มเหลว กรุณาลองใหม่อีกครั้ง');
        }
        
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// แสดง SnackBar สำหรับข้อความสำเร็จ
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// แสดง SnackBar สำหรับข้อความข้อผิดพลาด
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ กดที่ไหนก็ได้แล้วแป้นพิมพ์หาย
      onTap: _dismissKeyboard,
      child: FadeTransition(
        opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _dismissKeyboard();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'สร้างบัญชีใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                  const Text(
                    'กรุณากรอกข้อมูลเพื่อสมัครสมาชิก',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                      // ฟิลด์ชื่อผู้ใช้
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'ชื่อผู้ใช้',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: RegisterApi.validateUsername,
                      ),
                      const SizedBox(height: 16),
                      
                      // ฟิลด์อีเมล
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'อีเมล',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: RegisterApi.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      
                      // ฟิลด์รหัสผ่าน
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword1,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword1 ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword1 = !_obscurePassword1;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: RegisterApi.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      
                      // ฟิลด์ยืนยันรหัสผ่าน
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscurePassword2,
                        decoration: InputDecoration(
                          labelText: 'ยืนยันรหัสผ่าน',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword2 ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword2 = !_obscurePassword2;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => RegisterApi.validateConfirmPassword(value, _passwordController.text),
                      ),
                      const SizedBox(height: 24),
                      
                      // ข้อมูลเงื่อนไข
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withAlpha(77)),
                        ),
                        child: const Text(
                          'การสมัครสมาชิกเป็นการยอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ปุ่มสมัครสมาชิก
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                  Text(
                                    'กำลังสมัครสมาชิก...',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : const Text(
                                'สมัครสมาชิก',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ลิงก์ไปหน้าเข้าสู่ระบบ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('มีบัญชีอยู่แล้ว?'),
                          TextButton(
                            onPressed: () {
                              _dismissKeyboard();
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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

// ✅ สร้าง TimeoutException class เหมือนหน้า login
class TimeoutException implements Exception {
  final String message;
  
  const TimeoutException([this.message = 'Operation timed out']);
  
  @override
  String toString() => 'TimeoutException: $message';
}