import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/otp_api.dart';
import 'package:medication_reminder_system/page/verify_otp_page.dart';

class RequestOtpPage extends StatefulWidget {
  const RequestOtpPage({super.key});

  @override
  State<RequestOtpPage> createState() => _RequestOtpPageState();
}

class _RequestOtpPageState extends State<RequestOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode(); // ✅ เพิ่ม FocusNode
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ ป้องกันการ auto-focus เมื่อกลับมาหน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocusNode.unfocus();
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose(); // ✅ dispose FocusNode
    super.dispose();
  }

  // ✅ ซ่อนแป้นพิมพ์
  void _hideKeyboard() {
    _emailFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  bool _validateEmail() {
    if (!_formKey.currentState!.validate()) return false;
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showErrorSnackBar('กรุณากรอกอีเมล');
      return false;
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      _showErrorSnackBar('รูปแบบอีเมลไม่ถูกต้อง');
      return false;
    }
    
    return true;
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

  Future<void> _requestOtp() async {
    if (!_validateEmail()) return;

    // ✅ ซ่อนแป้นพิมพ์ก่อนส่ง OTP
    _hideKeyboard();

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      
      // ✅ เรียก OTP API จริง
      final result = await OtpApi.generateOTP(email: email);
      
      if (result['success']) {
        // แสดงผลลัพธ์สำเร็จ
        _showSuccessSnackBar(result['message'] ?? 'ส่งรหัส OTP สำเร็จ');
        
        // ✅ ดึงเวลาหมดอายุจาก API response
        int expirySeconds = 15 * 60; // default 15 นาทีถ้าไม่มีข้อมูล
        if (result['data'] != null && result['data']['expires_in'] != null) {
          expirySeconds = result['data']['expires_in'];
        }
        int expiryMinutes = (expirySeconds / 60).round();
        
        // ไปหน้า verify OTP พร้อมส่งเวลาหมดอายุ
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpPage(
                email: email,
                expiryMinutes: expiryMinutes, // ✅ ส่งเวลาหมดอายุจาก API
              ),
            ),
          );
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'เกิดข้อผิดพลาดในการส่ง OTP');
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
          title: const Text('ขอรหัส OTP'),
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
                  const SizedBox(height: 40),
                  
                  // ไอคอนและหัวข้อ
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'ขอรหัส OTP',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'กรุณากรอกอีเมลของคุณเพื่อรับรหัส OTP สำหรับรีเซ็ตรหัสผ่าน',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // ช่องกรอกอีเมล
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode, // ✅ ใช้ FocusNode ที่ควบคุมได้
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'อีเมล',
                      hintText: 'example@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
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
                        return 'กรุณากรอกอีเมล';
                      }
                      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(value.trim())) {
                        return 'รูปแบบอีเมลไม่ถูกต้อง';
                      }
                      return null;
                    },
                    // ✅ ซ่อนแป้นพิมพ์เมื่อกด Done หรือ Enter
                    onFieldSubmitted: (value) {
                      _hideKeyboard();
                      if (_validateEmail()) {
                        _requestOtp();
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // ปุ่มส่ง OTP
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestOtp,
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
                            'ส่งรหัส OTP',
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
                          '• ตรวจสอบอีเมลรวมถึงกล่องขยะ (Spam)\n'
                          '• รหัส OTP จะหมดอายุตามที่กำหนดในระบบ\n'
                          '• ไม่แชร์รหัส OTP กับผู้อื่น',
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