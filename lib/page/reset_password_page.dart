import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/otp_api.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode(); // ✅ เพิ่ม FocusNode
  final _confirmPasswordFocusNode = FocusNode(); // ✅ เพิ่ม FocusNode
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // ✅ ป้องกันการ auto-focus เมื่อเข้าหน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.unfocus();
      _confirmPasswordFocusNode.unfocus();
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose(); // ✅ dispose FocusNode
    _confirmPasswordFocusNode.dispose(); // ✅ dispose FocusNode
    super.dispose();
  }

  // ✅ ซ่อนแป้นพิมพ์
  void _hideKeyboard() {
    _passwordFocusNode.unfocus();
    _confirmPasswordFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
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

  bool _validatePasswords() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showErrorSnackBar('กรุณากรอกรหัสผ่านใหม่');
      return false;
    }

    if (password.length < 6) {
      _showErrorSnackBar('รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร');
      return false;
    }

    if (confirmPassword.isEmpty) {
      _showErrorSnackBar('กรุณายืนยันรหัสผ่าน');
      return false;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar('รหัสผ่านไม่ตรงกัน');
      return false;
    }

    return true;
  }

  Future<void> _resetPassword() async {
    if (!_validatePasswords()) return;

    // ✅ ซ่อนแป้นพิมพ์ก่อนรีเซ็ต
    _hideKeyboard();

    setState(() => _isLoading = true);

    try {
      final newPassword = _passwordController.text;
      
      // ✅ เรียกใช้ API ที่มีอยู่แล้ว
      final result = await OtpApi.resetPassword(
        email: widget.email,
        newPassword: newPassword,
      );

      if (result['success']) {
        _showSuccessSnackBar(result['message'] ?? 'รีเซ็ตรหัสผ่านสำเร็จ');
        
        // รอ 2 วินาทีแล้วกลับไปหน้า login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // กลับไปหน้าแรก (login page)
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'เกิดข้อผิดพลาดในการรีเซ็ตรหัสผ่าน');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ ซ่อนแป้นพิมพ์เมื่อกดนอกพื้นที่
      onTap: _hideKeyboard,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('รีเซ็ตรหัสผ่าน'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // ไอคอนและหัวข้อ
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'สร้างรหัสผ่านใหม่',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'กรุณาสร้างรหัสผ่านใหม่สำหรับบัญชี\n${widget.email}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // ช่องกรอกรหัสผ่านใหม่
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode, // ✅ ใช้ FocusNode ที่ควบคุมได้
                    obscureText: !_isPasswordVisible,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่านใหม่',
                      hintText: 'อย่างน้อย 6 ตัวอักษร',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกรหัสผ่านใหม่';
                      }
                      if (value.length < 6) {
                        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                    // ✅ เมื่อกด Done ให้ไปช่องถัดไป
                    onFieldSubmitted: (value) {
                      _confirmPasswordFocusNode.requestFocus();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // ช่องยืนยันรหัสผ่าน
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode, // ✅ ใช้ FocusNode ที่ควบคุมได้
                    obscureText: !_isConfirmPasswordVisible,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่านใหม่',
                      hintText: 'กรอกรหัสผ่านใหม่อีกครั้ง',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณายืนยันรหัสผ่าน';
                      }
                      if (value != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                    // ✅ เมื่อกด Done ให้ซ่อนแป้นพิมพ์และรีเซ็ต
                    onFieldSubmitted: (value) {
                      _hideKeyboard();
                      if (_validatePasswords()) {
                        _resetPassword();
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // ปุ่มรีเซ็ตรหัสผ่าน
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'รีเซ็ตรหัสผ่าน',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  // ปุ่มกลับ
                  TextButton(
                    onPressed: () {
                      _hideKeyboard(); // ✅ ซ่อนแป้นพิมพ์ก่อนกลับ
                      Navigator.pop(context);
                    },
                    child: Text(
                      'กลับ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // ข้อมูลเพิ่มเติม
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ข้อมูลสำคัญ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร\n'
                          '• แนะนำให้ใช้รหัสผ่านที่ปลอดภัย\n'
                          '• หลังจากเปลี่ยนรหัสผ่านแล้ว จะต้องเข้าสู่ระบบใหม่',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
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