// ไฟล์: lib/widget/qr_scan/qr_scan_controller.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:medication_reminder_system/api/qrscan_api.dart';
import 'package:medication_reminder_system/jwt/auth.dart';

class QRScanController {
  final MobileScannerController scannerController = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  final VoidCallback onDeviceConnected;
  final Function(String message) showError;

  bool isProcessing = false;
  bool flashOn = false;

  QRScanController({
    required this.onDeviceConnected,
    required this.showError,
  });

  bool get isDesktopOrWeb => kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  void dispose() {
    scannerController.dispose();
    _barcodeScanner.close();
  }

  void toggleFlash() {
    flashOn = !flashOn;
    scannerController.toggleTorch();
  }

  String _getFormattedErrorMessage(String originalError) {
    final lowerError = originalError.toLowerCase();
    
    if (lowerError.contains('ไม่พบผู้ใช้') || lowerError.contains('no user')) {
      return 'ไม่พบข้อมูลผู้ใช้\nกรุณาเข้าสู่ระบบใหม่';
    }
    
    if (lowerError.contains('เครื่องนี้ถูกเชื่อมต่อ') || lowerError.contains('already connected')) {
      return 'อุปกรณ์นี้ถูกเชื่อมต่อแล้ว\nกับบัญชีอื่น';
    }
    
    if (lowerError.contains('ไม่พบเครื่อง') || lowerError.contains('machine not found')) {
      return 'ไม่พบอุปกรณ์ในระบบ\nโปรดตรวจสอบ QR Code';
    }
    
    if (lowerError.contains('qr') && lowerError.contains('invalid')) {
      return 'QR Code ไม่ถูกต้อง\nโปรดลองสแกนใหม่';
    }
    
    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('internet')) {
      return 'ปัญหาการเชื่อมต่ออินเทอร์เน็ต\nโปรดตรวจสอบสัญญาณ';
    }
    
    if (lowerError.contains('timeout')) {
      return 'การเชื่อมต่อหมดเวลา\nโปรดลองใหม่อีกครั้ง';
    }
    
    if (lowerError.contains('permission')) {
      return 'ไม่มีสิทธิ์เข้าถึง\nโปรดตรวจสอบการตั้งค่า';
    }
    
    if (lowerError.contains('server') || lowerError.contains('500')) {
      return 'เซิร์ฟเวอร์มีปัญหา\nโปรดลองใหม่ในภายหลัง';
    }
    
    if (originalError.length > 80) {
      return 'เกิดข้อผิดพลาด\nโปรดลองใหม่อีกครั้ง';
    }
    
    return originalError;
  }

  void _showFormattedError(String error) {
    final formattedError = _getFormattedErrorMessage(error);
    showError(formattedError);
  }

  Future<void> handleScan(BarcodeCapture capture) async {
    if (isProcessing) {
      return;
    }
    
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        await _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processQRCode(String code) async {
    isProcessing = true;
    
    try {
      await scannerController.stop();
    } catch (e) {
      // Silent error handling
    }

    await _processQRCodeData(code);
  }

  Future<void> _processQRCodeData(String code) async {
    try {
      final currentUserId = await Auth.currentUserId();
      
      if (currentUserId == null || currentUserId.isEmpty) {
        _showFormattedError('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
        restartScanner();
        return;
      }

      final machineSN = QRScanApi.processScanedQRCode(code);

      final apiResponse = await QRScanApi.connectDevice(
        userId: currentUserId,
        machineSN: machineSN,
      );

      final result = await QRScanApi.processConnectDeviceResponse(
        statusCode: apiResponse['statusCode'],
        responseBody: apiResponse['body'],
      );

      if (result['success']) {
        onDeviceConnected();
      } else {
        _showFormattedError(result['message'] ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ');
        restartScanner();
      }
      
    } catch (e) {
      _showFormattedError('ผิดพลาด: $e');
      restartScanner();
    } finally {
      isProcessing = false;
    }
  }

  Future<void> _restartScannerAfterGallery() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!isProcessing) {
      try {
        await scannerController.start();
      } catch (e) {
        // Silent error handling
      }
    }
  }

  Future<void> restartScanner() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!isProcessing) {
      try {
        await scannerController.start();
      } catch (e) {
        // Silent error handling
      }
    }
  }

  Future<void> scanFromGallery() async {
    if (isProcessing) {
      return;
    }
    
    bool wasScannerRunning = false;
    try {
      if (scannerController.value.isRunning) {
        wasScannerRunning = true;
        await scannerController.stop();
      }
    } catch (e) {
      // Silent error handling
    }
    
    try {
      final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        await _processPickedImage(pickedImage, wasScannerRunning);
      } else {
        if (wasScannerRunning && !isProcessing) {
          await _restartScannerAfterGallery();
        }
      }
    } catch (e) {
      _showFormattedError('ไม่สามารถเลือกรูปภาพได้');
      
      if (wasScannerRunning && !isProcessing) {
        await _restartScannerAfterGallery();
      }
    }
  }

  Future<void> _processPickedImage(XFile imageFile, bool shouldRestartScanner) async {
    isProcessing = true;
    bool imageProcessedSuccessfully = false;
    
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        if (barcodes.first.rawValue != null && barcodes.first.rawValue!.isNotEmpty) {
          imageProcessedSuccessfully = true;
          await _processQRCodeData(barcodes.first.rawValue!);
          return;
        } else {
          _showFormattedError('ไม่พบ QR Code ที่ถูกต้องในรูปภาพ');
        }
      } else {
        _showFormattedError('ไม่พบ QR Code ในรูปภาพ\nโปรดเลือกรูปที่มี QR Code ชัดเจน');
      }
    } catch (e) {
      _showFormattedError('อ่านรูปภาพผิดพลาด\nโปรดลองเลือกรูปใหม่');
    } finally {
      isProcessing = false;
      
      if (!imageProcessedSuccessfully && shouldRestartScanner) {
        await _restartScannerAfterGallery();
      }
    }
  }
}