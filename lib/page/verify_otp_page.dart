import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medication_reminder_system/api/otp_api.dart';
import 'package:medication_reminder_system/page/reset_password_page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;
  final int expiryMinutes;

  const VerifyOtpPage({
    super.key,
    required this.email,
    this.expiryMinutes = 15,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  bool _isInputDisabled = false;
  int _expiryMinutes = 15;

  @override
  void initState() {
    super.initState();
    _expiryMinutes = widget.expiryMinutes;
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();
  
  bool get _isOtpComplete => _otpCode.length == 6;

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากหน้ากรอก OTP?'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากหน้ากรอก OTP?\nการกรอก OTP จะต้องเริ่มใหม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ออก'),
          ),
        ],
      ),
    );
    return result ?? false;
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

  void _onOtpChanged(int index, String value) {
    if (_isInputDisabled) return;
    
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {
      // เปลี่ยนสถานะปุ่มเมื่อกรอกครบ 6 หลัก
    });
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _isInputDisabled) {
      if (!_isInputDisabled) {
        _showErrorSnackBar('กรุณากรอกรหัส OTP ให้ครบ 6 หลัก');
      }
      return;
    }

    _hideKeyboard();

    setState(() => _isLoading = true);

    try {
      final result = await OtpApi.verifyOTP(
        email: widget.email,
        otpCode: _otpCode,
      );

      if (result['success']) {
        _showSuccessSnackBar(result['message']);

        setState(() {
          _isInputDisabled = true;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(email: widget.email),
              ),
            );
          }
        });
      } else {      
        if (result['message'].contains('เกิน') || 
            result['message'].contains('ครบ') ||
            result['message'].contains('ผิดเกิน') ||
            result['message'].contains('ขอ OTP ใหม่')) {
                   _showErrorSnackBar(result['message']);
          
          setState(() {
            _isInputDisabled = true;
          });
          
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        } else {
            _showErrorSnackBar(result['message']);
          
          setState(() {
            _isInputDisabled = true;
          });
          
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              setState(() {
                _isInputDisabled = false;
              });
            }
          });
          
          _clearOtp();
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการตรวจสอบ OTP');
      _clearOtp();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    _hideKeyboard();
    setState(() => _isResending = true);

    try {
      final result = await OtpApi.generateOTP(email: widget.email);

      if (result['success']) {
        if (result['data'] != null && result['data']['expires_in'] != null) {
          setState(() {
            _expiryMinutes = (result['data']['expires_in'] / 60).round();
          });
        }
        
        _showSuccessSnackBar('ส่งรหัส OTP ใหม่แล้ว');
        _clearOtp();
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation();
        if (shouldExit && mounted) {
          if (mounted && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: GestureDetector(
        onTap: _hideKeyboard,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('ยืนยันรหัส OTP'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final shouldExit = await _showExitConfirmation();
                if (shouldExit && mounted && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'ยืนยันตัวตน',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'กรุณากรอกรหัส OTP 6 หลัก\nที่ส่งไปยัง ${widget.email}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
                        height: 55,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          enabled: !_isInputDisabled,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _isInputDisabled ? Colors.grey[300]! : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _isInputDisabled ? Colors.grey[300]! : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _isInputDisabled ? Colors.grey[300]! : Theme.of(context).primaryColor, 
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: _isInputDisabled ? Colors.grey[100] : Colors.white,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onOtpChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: (_isLoading || !_isOtpComplete || _isInputDisabled) ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: _isOtpComplete && !_isInputDisabled 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[400],
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
                        : Text(
                            'ยืนยันรหัส OTP',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: _isOtpComplete && !_isInputDisabled 
                                  ? Colors.white 
                                  : Colors.grey[600],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ไม่ได้รับรหัส OTP? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: (_isResending || _isInputDisabled) ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'ส่งใหม่',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  TextButton(
                    onPressed: () async {
                      final shouldExit = await _showExitConfirmation();
                      if (shouldExit && mounted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      'กลับ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'รหัส OTP จะหมดอายุใน $_expiryMinutes นาที',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'หากไม่ได้รับอีเมล กรุณาตรวจสอบกล่องขยะ (Spam)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
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