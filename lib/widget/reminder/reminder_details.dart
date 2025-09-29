import 'package:flutter/material.dart';
import 'dart:convert';
import 'slot_settings_page.dart';
import 'dart:developer' as developer;
import 'package:medication_reminder_system/api/reminder_detail_api.dart';
import 'package:medication_reminder_system/jwt/auth.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_details/details_widgets.dart';

class SlotDetailsDialog extends StatefulWidget {
  final int slot;
  final dynamic slotData; // ใช้ dynamic แทน AppModel
  final String activeDays;

  const SlotDetailsDialog({
    super.key,
    required this.slot,
    required this.slotData,
    required this.activeDays,
  });

  @override
  State<SlotDetailsDialog> createState() => _SlotDetailsDialogState();
}

class _SlotDetailsDialogState extends State<SlotDetailsDialog> {
 List<SlotMedicationDetail> medicationLinks = [];
  AppInfo? appInfo;
  bool isLoading = true;
  String? errorMessage;

  // รายการมื้อยาตาม slot
  static final List<String> _mealNames = [
    'มื้อเช้าก่อนอาหาร',      // slot 1
    'มื้อเช้าหลังอาหาร',     // slot 2
    'มื้อเที่ยงก่อนอาหาร',   // slot 3
    'มื้อเที่ยงหลังอาหาร',   // slot 4
    'มื้อเย็นก่อนอาหาร',     // slot 5
    'มื้อเย็นหลังอาหาร',     // slot 6
    'ก่อนนอน',              // slot 7
  ];

  String get _mealName {
    if (widget.slot >= 1 && widget.slot <= _mealNames.length) {
      return _mealNames[widget.slot - 1];
    }
    return 'กล่องที่ ${widget.slot}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.slotData != null) {
      _loadMedicationLinks();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันดึงข้อมูล medication links จาก API
  Future<void> _loadMedicationLinks() async {
    if (widget.slotData?.appId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'ไม่พบ app_id';
      });
      return;
    }

    try {
      final appId = widget.slotData.appId.toString();

      developer.log('Loading medication links for app_id: $appId');
      
      // Debug JWT token
      final token = await JWTManager.getToken();
      developer.log('JWT Token exists: ${token != null}');
      developer.log('JWT Token length: ${token?.length ?? 0}');

      final response = await ReminderSlotDetailApi.getMedicationLinks(
        appId: appId,
      );

      developer.log('API Response Status: ${response.statusCode}');
      developer.log('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // แก้ปัญหา response ซ้อนกัน - เอาแค่ส่วนแรก
        String responseBody = response.body;
        
        // ถ้ามี { ตัวที่ 2 ให้ตัดออก
        int secondJsonStart = responseBody.indexOf('}{');
        if (secondJsonStart != -1) {
          responseBody = responseBody.substring(0, secondJsonStart + 1);
          developer.log('Fixed duplicate response, using: $responseBody');
        }
        
        final jsonData = json.decode(responseBody);
        
        // Debug ข้อมูล response
        developer.log('Parsed JSON: $jsonData');
        
        if (jsonData['status'] == 'success') {
          final slotDetailsResponse = SlotDetailsResponse.fromJson(jsonData);

          setState(() {
            medicationLinks = slotDetailsResponse.medicationLinks;
            appInfo = slotDetailsResponse.appInfo;
            isLoading = false;
            errorMessage = null;
          });
        } else {
          // แสดง error message จาก API
          final apiError = jsonData['message'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูล';
          developer.log('API Error: $apiError');
          setState(() {
            isLoading = false;
            errorMessage = apiError;
          });
        }
      } else {
        // แสดง HTTP error พร้อมรายละเอียด
        developer.log('HTTP Error ${response.statusCode}: ${response.body}');
        setState(() {
          isLoading = false;
          errorMessage = 'เซิร์ฟเวอร์ตอบสนอง ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      developer.log('Error loading medication links: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  // ฟังก์ชันนำทางไปหน้าตั้งค่า - แก้ไขใหม่
  Future<void> _navigateToSettings(BuildContext context) async {
    // ใช้ JWT system ดึงข้อมูลผู้ใช้
    final userId = await Auth.currentUserId();
    final connectId = await JWTManager.getConnectionId();
    
    if (!context.mounted) return;
    
    // รอผลลัพธ์จากหน้า SlotSettingsPage โดยไม่ปิด dialog ก่อน
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SlotSettingsPage(
          slot: widget.slot,
          slotData: widget.slotData!,
          mealName: _mealName,
          userId: int.tryParse(userId ?? '0'),
          connectId: int.tryParse(connectId ?? '0'),
        ),
      ),
    );
    
    // ถ้าบันทึกสำเร็จ ให้ปิด dialog และส่งสัญญาณกลับไปยังหน้าหลัก
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true); // ส่งค่า true กลับไปยังหน้าหลัก
    }
  }

  // ฟังก์ชันสำหรับแปลงเวลาให้แสดงแค่ชั่วโมง:นาที
  String _formatTime(String time) {
    if (time == 'ไม่ได้ตั้งค่า' || time.isEmpty) {
      return 'ไม่ได้ตั้งค่า';
    }
    
    try {
      // ลองแปลงเวลาที่เป็น HH:mm:ss เป็น HH:mm น.
      if (time.contains(':')) {
        List<String> timeParts = time.split(':');
        if (timeParts.length >= 2) {
          String hours = timeParts[0].padLeft(2, '0');
          String minutes = timeParts[1].padLeft(2, '0');
          return '$hours:$minutes น.';
        }
      }
      
      // ถ้าแปลงไม่ได้ให้คืนค่าเดิม
      return time;
    } catch (e) {
      // ถ้ามีข้อผิดพลาดให้คืนค่าเดิม
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              SlotDialogHeader(
                mealName: _mealName,
                onClose: () => Navigator.of(context).pop(),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.slotData == null) ...[
                      const EmptySlotContent(),
                    ] else ...[
                      // Combined Info Card
                      SlotInfoCard(
                        slotData: widget.slotData,
                        appInfo: appInfo,
                        activeDays: widget.activeDays,
                        formatTime: _formatTime,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Medication List Header
                      const MedicationListHeader(),
                      const SizedBox(height: 16),
                      
                      // Medication Cards
                      MedicationListContent(
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        medicationLinks: medicationLinks,
                        onRetry: _loadMedicationLinks,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    SlotActionButtons(
                      hasSlotData: widget.slotData != null,
                      onSettings: () => _navigateToSettings(context),
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}