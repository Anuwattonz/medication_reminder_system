import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/medication_api.dart';
import 'dart:convert';

/// Widget สำหรับจัดการการลบยา
class MedicationDelete {
  
  /// แสดง Dialog สำหรับลบยา
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String medicationId,
    Function({required bool hadReminders})? onMedicationDeleted,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => _MedicationDeleteDialog(
        medicationId: medicationId,
        onMedicationDeleted: onMedicationDeleted,
      ),
    );
  }
}

/// Dialog สำหรับลบยา
class _MedicationDeleteDialog extends StatefulWidget {
  final String medicationId;
  final Function({required bool hadReminders})? onMedicationDeleted;

  const _MedicationDeleteDialog({
    required this.medicationId,
    this.onMedicationDeleted,
  });

  @override
  State<_MedicationDeleteDialog> createState() => _MedicationDeleteDialogState();
}

class _MedicationDeleteDialogState extends State<_MedicationDeleteDialog> {
  bool _isLoading = false;

  /// ลบยา - ตรวจสอบการใช้งานใน reminder
  Future<void> _deleteMedication() async {
    try {
      setState(() => _isLoading = true);
      
      // เรียก API ลบยา (ครั้งแรกเพื่อตรวจสอบ) - ไม่บังคับลบ
      final response = await MedicationApi.deleteMedication(
        widget.medicationId,
        forceDelete: false,
      );
      
      if (response['statusCode'] == 409) {
        try {
          // มีการใช้งานใน reminder ให้แสดง dialog เตือน
          final jsonResponse = jsonDecode(response['body']);
          
          final data = jsonResponse['data'];
          
          if (data != null) {
            final reminderCount = data['reminder_count'] ?? 0;
            final medicationName = data['medication_name'] ?? 'ยานี้';
            final reminders = List<Map<String, dynamic>>.from(data['reminders'] ?? []);
            
            final shouldDelete = await _showDeleteWithRemindersDialog(
              medicationName: medicationName,
              reminderCount: reminderCount,
              reminders: reminders,
            );
            
            if (shouldDelete) {
              // ยืนยันลบ ให้เรียก API อีกครั้งพร้อม force_delete = true
              final forceResponse = await MedicationApi.deleteMedication(
                widget.medicationId,
                forceDelete: true,
              );
              
              if (forceResponse['success']) {
                if (mounted) {
                  _showSnackBar('ลบยาสำเร็จ');
                  // เรียก callback และระบุว่ามีการลบ reminder
                  if (widget.onMedicationDeleted != null) {
                    widget.onMedicationDeleted!(hadReminders: true);
                  }
                  Navigator.of(context).pop(true);
                }
              } else {
                if (mounted) {
                  String errorMessage = 'ไม่สามารถลบยาได้';
                  try {
                    final errorData = jsonDecode(forceResponse['body']);
                    if (errorData['message'] != null) {
                      errorMessage = errorData['message'];
                    }
                  } catch (e) {
                    // Error parsing response
                  }
                  _showSnackBar(errorMessage, isError: true);
                }
              }
            }
          } else {
            _showSnackBar(jsonResponse['message'] ?? 'ยาที่เลือกมีการตั้งแจ้งเตือนอยู่', isError: true);
          }
        } catch (e) {
          _showSnackBar('ยาที่เลือกมีการตั้งแจ้งเตือนอยู่ กรุณาปิดการแจ้งเตือนก่อนลบ', isError: true);
        }
      } else if (response['success']) {
        // ลบสำเร็จ (ไม่มีการใช้งานใน reminder)
        if (mounted) {
          _showSnackBar('ลบยาสำเร็จ');
          // เรียก callback และระบุว่าไม่มี reminder
          if (widget.onMedicationDeleted != null) {
            widget.onMedicationDeleted!(hadReminders: false);
          }
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          String errorMessage = 'ไม่สามารถลบยาได้';
          try {
            final errorData = jsonDecode(response['body']);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            // Error parsing response
          }
          
          _showSnackBar(errorMessage, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// แสดง Dialog เตือนเมื่อยามีการใช้งานใน reminder
Future<bool> _showDeleteWithRemindersDialog({
  required String medicationName,
  required int reminderCount,
  required List<Map<String, dynamic>> reminders,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false, // ป้องกันการปิด dialog โดยการแตะนอก dialog
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      
      // Header พร้อมไอคอนเตือน
      title: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'ยืนยันการลบยา',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ข้อความหลัก
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: [
                const TextSpan(text: 'ยา '),
                TextSpan(
                  text: '"$medicationName"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const TextSpan(text: ' มีการตั้งแจ้งเตือนอยู่ '),
                TextSpan(
                  text: '$reminderCount รายการ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // แสดงรายการ reminders
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'รายการแจ้งเตือน:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...reminders.take(3).map((reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${reminder['timing_name'] ?? 'ไม่ระบุ'} เวลา ${reminder['timing'] ?? 'ไม่ระบุ'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (reminders.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '... และอีก ${reminders.length - 3} รายการ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // คำเตือน
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'หากลบยา การแจ้งเตือนทั้งหมดจะถูกปิดการใช้งานโดยอัตโนมัติ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      actions: [
        // ปุ่มยกเลิก
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            'ยกเลิก',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // ปุ่มยืนยันลบ
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: const Text(
            'ลบยาและปิดการแจ้งเตือน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  ) ?? false;
}

  /// แสดง SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delete_outline, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text(
            'ยืนยันการลบยา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'คุณต้องการลบยานี้ใช่หรือไม่?\nการลบจะไม่สามารถย้อนกลับได้',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop(false);
          },
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () {
            _deleteMedication();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('ลบยา'),
        ),
      ],
    );
  }
}