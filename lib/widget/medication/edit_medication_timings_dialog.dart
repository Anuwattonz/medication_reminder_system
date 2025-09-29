import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/medication_timing_api.dart';
import 'package:medication_reminder_system/jwt/auth.dart';

// Dialog สำหรับแก้ไขเวลารับประทานยา
class EditMedicationTimingsDialog extends StatefulWidget {
  final String medicationId;
  final List<dynamic> currentTimings;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;
  final Map<String, dynamic>? timingUsage;

  const EditMedicationTimingsDialog({
    super.key,
    required this.medicationId,
    required this.currentTimings,
    required this.onSave,
    this.timingUsage,
  });

  @override
  State<EditMedicationTimingsDialog> createState() =>
      _EditMedicationTimingsDialogState();
}

class _EditMedicationTimingsDialogState
    extends State<EditMedicationTimingsDialog> {
  final Map<int, String> timingOptions = {
    1: 'เช้าก่อนอาหาร',
    2: 'เช้าหลังอาหาร',
    3: 'กลางวันก่อนอาหาร',
    4: 'กลางวันหลังอาหาร',
    5: 'เย็นก่อนอาหาร',
    6: 'เย็นหลังอาหาร',
    7: 'ก่อนนอน',
  };

  late Set<int> selectedTimingIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedTimingIds = widget.currentTimings
        .map((timing) => timing['timing_id'] as int)
        .toSet();
  }

  /// ตรวจสอบว่า timing นี้ถูกใช้งานใน reminder หรือไม่
  bool _isTimingUsedInReminder(int timingId) {
    if (widget.timingUsage == null) return false;
    
    final usage = widget.timingUsage![timingId.toString()];
    if (usage == null) return false;
    
    return usage['is_used'] == true;
  }

  Future<void> _saveChanges() async {
    // ซ่อนแป้นพิมพ์ก่อนบันทึก (ถ้ามี)
    FocusManager.instance.primaryFocus?.unfocus();
    
    if (selectedTimingIds.isEmpty) {
      _showErrorDialog('กรุณาเลือกเวลาอย่างน้อย 1 ช่วงเวลา');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📋 [TIMING] Updating timings for medication: ${widget.medicationId}');
      debugPrint('📋 [TIMING] Selected timing IDs: ${selectedTimingIds.toList()}');

      final result = await MedicationTimingApi.updateMedicationTimings(
        medicationId: widget.medicationId,
        timingIds: selectedTimingIds.toList(),
      );

      if (result['statusCode'] == 401) {
        debugPrint('🔄 [TIMING] Token expired, trying to refresh...');
        final refreshSuccess = await Auth.refreshToken();

        if (refreshSuccess && mounted) {
          await _saveChanges();
        } else if (mounted) {
          await Auth.logout(context);
        }
        return;
      }

      if (result['success']) {
        debugPrint('✅ [TIMING] Medication timings updated successfully');

        final jsonResponse = result['data'];
        List<Map<String, dynamic>> updatedTimings = [];

        if (jsonResponse['data'] != null &&
            jsonResponse['data']['medication_timings'] != null) {
          updatedTimings =
              (jsonResponse['data']['medication_timings'] as List)
                  .map<Map<String, dynamic>>((timing) => {
                        'timing_id': timing['timing_id'],
                        'timing_name': timing['timing_name'],
                      })
                  .toList();
        } else {
          updatedTimings = selectedTimingIds
              .map<Map<String, dynamic>>((timingId) => {
                    'timing_id': timingId,
                    'timing_name': timingOptions[timingId] ?? '',
                  })
              .toList();
        }

        await widget.onSave(updatedTimings);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (result['statusCode'] == 403) {
        debugPrint('🚫 [TIMING] Forbidden - No permission');
        _showErrorDialog('ไม่มีสิทธิ์ในการแก้ไขข้อมูลยา');
      } else {
        debugPrint('❌ [TIMING] API Error: ${result['data']['message']}');
        String errorMessage = result['data']['message'] ?? 'เกิดข้อผิดพลาด';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      debugPrint('💥 [TIMING] Exception: $e');
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              const Text('เกิดข้อผิดพลาด'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ซ่อนแป้นพิมพ์เมื่อแตะพื้นที่ว่าง
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header สีเขียว
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'แก้ไขเวลารับประทานยา',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'เลือกช่วงเวลาที่เหมาะสม',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              const Color(0xFF2E7D32).withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เลือกได้หลายช่วงเวลา',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedTimingIds.length} รายการที่เลือก',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Timing Options
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: timingOptions.entries.map((entry) {
                              int timingId = entry.key;
                              String timingName = entry.value;
                              bool isSelected = selectedTimingIds.contains(timingId);
                              bool isUsedInReminder = _isTimingUsedInReminder(timingId);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isUsedInReminder 
                                        ? Colors.red[300]!
                                        : isSelected 
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey[300]!,
                                    width: isSelected || isUsedInReminder ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: isUsedInReminder 
                                        ? null
                                        : () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedTimingIds.remove(timingId);
                                              } else {
                                                selectedTimingIds.add(timingId);
                                              }
                                            });
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isUsedInReminder
                                                  ? Colors.red[100]
                                                  : isSelected
                                                      ? const Color(0xFF4CAF50)
                                                      : Colors.transparent,
                                              border: Border.all(
                                                color: isUsedInReminder
                                                    ? Colors.red[400]!
                                                    : isSelected
                                                        ? const Color(0xFF4CAF50)
                                                        : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: isSelected && !isUsedInReminder
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : isUsedInReminder
                                                    ? Icon(
                                                        Icons.lock,
                                                        size: 14,
                                                        color: Colors.red[600],
                                                      )
                                                    : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  timingName,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    fontSize: 16,
                                                    color: isUsedInReminder
                                                        ? Colors.red[600]
                                                        : isSelected
                                                            ? const Color(0xFF2E7D32)
                                                            : Colors.black87,
                                                  ),
                                                ),
                                                if (isUsedInReminder) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.warning_amber_rounded,
                                                        size: 16,
                                                        color: Colors.red[500],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'มีการตั้งแจ้งเตือนอยู่',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.red[500],
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('บันทึก'),
                      ),
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