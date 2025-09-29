import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/slot_settings.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/slot_setting_widget.dart';
import 'package:medication_reminder_system/notification/notification_service.dart';

class SlotSettingsPage extends StatefulWidget {
  final int slot;
  final dynamic slotData;
  final String mealName;
  final int? userId;
  final int? connectId;

  const SlotSettingsPage({
    super.key,
    required this.slot,
    required this.slotData,
    required this.mealName,
    this.userId,
    this.connectId,
  });

  @override
  State<SlotSettingsPage> createState() => _SlotSettingsPageState();
}

class _SlotSettingsPageState extends State<SlotSettingsPage> {
  late SlotSettingController controller;
  late Future<String?> _loadDataFuture;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    controller = SlotSettingController(
      onStateChanged: () {
        if (!_isDisposed && mounted) {
          setState(() {});
        }
      },
    );
    
    controller.initializeData(
      userId: widget.userId,
      connectId: widget.connectId,
      slotData: widget.slotData,
    );
    
    _loadDataFuture = controller.loadAllData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    controller.dispose();
    super.dispose();
  }

  // ==================== SnackBar เหมือน medication_page ====================

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted && context.mounted) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: isError ? 4 : 2),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
    }
  }

  void _showWarningSnackBar(String message) {
    if (mounted && context.mounted) {
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
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    // Check if confirmation is needed
    final completionCheck = controller.checkSettingsCompletion();
    if (completionCheck['needsConfirmation'] == true) {
      bool shouldContinue = await _showConfirmDialog(
        completionCheck['title'],
        completionCheck['message'],
      );
      if (!shouldContinue) return;
    }

    // Save settings
    final result = await controller.saveSettings();
    
    if (!mounted) return;
    
    if (result['success']) {
      final isWarning = result['isWarning'] ?? false;
      
      if (isWarning) {
        _showWarningSnackBar(result['message']);
      } else {
        _showSnackBar(result['message']);
      }
      
      // อัปเดตการแจ้งเตือนหลังบันทึกสำเร็จ
      try {
        final mockApp = _createMockAppModel();
        await NotificationService.updateSingleSlotNotification(mockApp);
        debugPrint('✅ อัปเดตการแจ้งเตือนหลังบันทึก Slot ${widget.slot} สำเร็จ');
      } catch (e) {
        debugPrint('❌ ไม่สามารถอัปเดตการแจ้งเตือนหลังบันทึก: $e');
        if (mounted) {
          _showWarningSnackBar('บันทึกสำเร็จ แต่ไม่สามารถอัปเดตการแจ้งเตือนได้');
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  MockAppModel _createMockAppModel() {
    bool hasMedications = controller.selectedMedications.isNotEmpty;
    bool hasValidDays = controller.selectedDays.values.any((v) => v == true);
    bool hasValidTime = controller.selectedTime != null;
    
    String status = (hasMedications && hasValidDays && hasValidTime) ? '1' : '0';
    
    String timing = '';
    if (hasValidTime) {
      timing = '${controller.selectedTime!.hour.toString().padLeft(2, '0')}:${controller.selectedTime!.minute.toString().padLeft(2, '0')}';
    }
    
    List<MockMedicationLink> medicationLinks = controller.selectedMedications.map((med) => 
      MockMedicationLink(
        medicationName: med['medication_name']?.toString() ?? '',
        medicationNickname: med['medication_nickname']?.toString() ?? '',
        amount: (med['amount'] as num?)?.toDouble() ?? 1.0,
      ),
    ).toList();
    
    Map<String, dynamic> days = {};
    controller.selectedDays.forEach((key, value) {
      days[key] = value ? '1' : '0';
    });
    
    return MockAppModel(
      appId: widget.slot.toString(),
      status: status,
      timing: timing,
      pillSlot: widget.slot,
      days: days,
      medicationLinks: medicationLinks,
      canToggle: true,
      medicationCount: medicationLinks.length,
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('ยืนยัน'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'ตั้งค่า${widget.mealName}', 
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white
          )
        ),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            );
          }
          
          if (snapshot.hasError || snapshot.data != null) {
            return ErrorScreen(
              errorMessage: snapshot.data ?? 
                'ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่อีกครั้ง',
              onRetry: () {
                setState(() {
                  _loadDataFuture = controller.loadAllData();
                });
              },
            );
          }
          
          return SlotSettingWidget(
            controller: controller,
            onSave: _saveSettings,
          );
        },
      ),
    );
  }
}

// ==================== Mock Classes สำหรับ Notification ====================

class MockAppModel {
  final String appId;
  final String status;
  final String timing;
  final int pillSlot;
  final Map<String, dynamic> days;
  final List<MockMedicationLink> medicationLinks;
  final bool canToggle;
  final int medicationCount;

  MockAppModel({
    required this.appId,
    required this.status,
    required this.timing,
    required this.pillSlot,
    required this.days,
    required this.medicationLinks,
    required this.canToggle,
    required this.medicationCount,
  });
}

class MockMedicationLink {
  final String medicationName;
  final String medicationNickname;
  final double amount;

  MockMedicationLink({
    required this.medicationName,
    required this.medicationNickname,
    required this.amount,
  });
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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