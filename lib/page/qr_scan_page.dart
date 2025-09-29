// ไฟล์: lib/page/qr_scan_page.dart - แก้ไขเพื่อแสดง loading หลัง scan
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medication_reminder_system/widget/qr_scan/qr_scan_controller.dart';
import 'package:medication_reminder_system/widget/qr_scan/qr_scan_overlay.dart';
import 'package:medication_reminder_system/page/tabbar_page.dart';
import 'package:medication_reminder_system/jwt/auth.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  late QRScanController _qrController;
  String? _errorMessage;
  bool _showError = false;
  
  // ✅ เพิ่ม state สำหรับการ processing
  bool _isConnecting = false;
  String _connectionStatus = '';

  @override
  void initState() {
    super.initState();
    _qrController = QRScanController(
      onDeviceConnected: _handleDeviceConnected, // ✅ เปลี่ยนเป็น custom handler
      showError: _showErrorMessage,
    );
  }

  // ✅ ฟังก์ชันใหม่: จัดการเมื่อ scan เสร็จ
  Future<void> _handleDeviceConnected() async {
    debugPrint('🎯 QR Scan successful, starting connection process...');
    
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'กำลังเชื่อมต่ออุปกรณ์...';
    });

    try {
      // รอให้ JWT refresh และ connection เสร็จ
      await Future.delayed(const Duration(milliseconds: 1500));
      
      setState(() {
        _connectionStatus = 'กำลังโหลดข้อมูลผู้ใช้...';
      });
      
      // ตรวจสอบว่า connection สำเร็จแล้วจริงๆ
      final hasConnection = await Auth.hasDeviceConnection();
      if (!hasConnection) {
        throw Exception('ไม่สามารถยืนยันการเชื่อมต่อได้');
      }
      
      setState(() {
        _connectionStatus = 'เชื่อมต่อสำเร็จ! กำลังไปหน้าหลัก...';
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      // สร้างข้อมูลสำหรับ TabBar
      final session = await Auth.getCurrentSession();
      final userData = {
        'user_id': session?.userId,
      };
      
      final connections = [{
        'connect_id': session?.connectionId,
        'user_id': session?.userId,
      }];
      
      debugPrint('🎉 Navigating to TabBar with connection...');
      
      if (mounted) {
        // ไปหน้า TabBar แทนการ pop
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomTabBar(
              userData: userData,
              connections: connections,
            ),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Connection process failed: $e');
      setState(() {
        _isConnecting = false;
        _connectionStatus = '';
      });
      _showErrorMessage('เชื่อมต่อไม่สำเร็จ: $e');
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _showError = true;
    });

    // ซ่อน error หลังจาก 4 วินาที
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showError = false;
        });
      }
    });
  }

  void _dismissError() {
    setState(() {
      _showError = false;
    });
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isConnecting ? null : AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'เชื่อมต่ออุปกรณ์',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _qrController.flashOn 
                ? Colors.yellow.withValues(alpha: 0.3) 
                : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _qrController.flashOn ? Icons.flash_on : Icons.flash_off,
                color: _qrController.flashOn ? Colors.yellow : Colors.white,
              ),
              onPressed: _qrController.isProcessing ? null : () {
                setState(() {
                  _qrController.toggleFlash();
                });
              },
            ),
          ),
        ],
      ),
      body: _isConnecting ? _buildConnectionScreen() : _buildScannerScreen(),
    );
  }

  // ✅ หน้าจอ connection loading
  Widget _buildConnectionScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Status Text
            Text(
              'QR Code สแกนสำเร็จ!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Loading with status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _connectionStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'โปรดรอสักครู่...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ หน้าจอ scanner เดิม
  Widget _buildScannerScreen() {
    return Stack(
      children: [
        // Main Content
        Column(
          children: [
            // Header Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สแกน QR Code ที่ตัวเครื่อง',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เพื่อเชื่อมต่ออุปกรณ์เข้ากับแอป',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Camera Scanner
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _qrController.scannerController,
                        onDetect: _qrController.handleScan,
                      ),
                      const QRScanOverlay(),
                    ],
                  ),
                ),
              ),
            ),

            // Controls
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildControlsWidget(),
              ),
            ),
          ],
        ),

        // Error Overlay
        if (_showError)
          _buildErrorOverlay(),
      ],
    );
  }

  Widget _buildControlsWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.center_focus_strong,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'วางกล้องเหนือ QR Code',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Gallery Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.photo_library, size: 22),
            label: const Text(
              'เลือกจากแกลเลอรี่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _qrController.isProcessing ? null : () {
              _qrController.scanFromGallery();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _dismissError,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'เกิดข้อผิดพลาด',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _dismissError,
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}