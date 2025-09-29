import 'package:flutter/material.dart';

// ฟังก์ชันแสดง Time Picker Dialog - มีขีดจำกัดต่ำสุด
Future<void> showTimePickerDialog({
  required BuildContext context,
  required String title,
  required int initialHours, // เก็บไว้เพื่อ compatibility แต่ไม่ใช้
  required int initialMinutes,
  required int initialSeconds,
  required Function(int, int, int) onConfirm,
}) async {
  
  // ✅ กำหนดขีดจำกัดต่ำสุดตาม title
  Map<String, int> minLimits = _getMinLimits(title);
  int minMinutes = minLimits['minutes']!;
  int minSeconds = minLimits['seconds']!;
  
  // ✅ ตรวจสอบค่าเริ่มต้นให้อยู่ในขีดจำกัด
  int tempMinutes = initialMinutes;
  int tempSeconds = initialSeconds;
  
  // ถ้าค่าเริ่มต้นต่ำกว่าขีดจำกัด ให้ตั้งเป็นค่าต่ำสุด
  if (tempMinutes < minMinutes || (tempMinutes == minMinutes && tempSeconds < minSeconds)) {
    tempMinutes = minMinutes;
    tempSeconds = minSeconds;
  }

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: Column(
                children: [
                  // แสดงเวลาปัจจุบัน
                  _buildTimeDisplay(tempMinutes, tempSeconds),
                  
                  // Time Picker Wheels
                  Expanded(
                    child: Row(
                      children: [
                        // Minutes
                        _buildTimeWheel(
                          label: 'นาที',
                          maxValue: 60,
                          currentValue: tempMinutes,
                          minValue: minMinutes,
                          onChanged: (value) {
                            setDialogState(() {
                              tempMinutes = value;
                              // ✅ ถ้าเลือกนาทีต่ำสุด ต้องเช็ควินาทีด้วย
                              if (tempMinutes == minMinutes && tempSeconds < minSeconds) {
                                tempSeconds = minSeconds;
                              }
                            });
                          },
                        ),
                        // Seconds
                        _buildTimeWheel(
                          label: 'วินาที',
                          maxValue: 60,
                          currentValue: tempSeconds,
                          minValue: tempMinutes == minMinutes ? minSeconds : 0,
                          onChanged: (value) {
                            setDialogState(() {
                              tempSeconds = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  // ✅ ตรวจสอบขีดจำกัดอีกครั้งก่อนยืนยัน  
                  if (_isValidTime(tempMinutes, tempSeconds, minMinutes, minSeconds)) {
                    onConfirm(0, tempMinutes, tempSeconds);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ✅ ฟังก์ชันกำหนดขีดจำกัดต่ำสุดตาม title
Map<String, int> _getMinLimits(String title) {
  if (title.contains('แจ้งเตือนติดต่อเป็นเวลา')) {
    return {'minutes': 1, 'seconds': 0}; // ต่ำสุด 1 นาที
  } else if (title.contains('ความถี่การแจ้งเตือน')) {
    return {'minutes': 0, 'seconds': 30}; // ต่ำสุด 30 วินาที
  } else {
    return {'minutes': 0, 'seconds': 0}; // ไม่มีขีดจำกัด
  }
}

// ✅ ฟังก์ชันตรวจสอบว่าเวลาที่เลือกถูกต้องหรือไม่
bool _isValidTime(int minutes, int seconds, int minMinutes, int minSeconds) {
  if (minutes > minMinutes) return true;
  if (minutes == minMinutes && seconds >= minSeconds) return true;
  return false;
}

// Widget สำหรับแสดงเวลาปัจจุบัน - ไม่แสดงชั่วโมง
Widget _buildTimeDisplay(int minutes, int seconds) {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    ),
  );
}

// ✅ Widget สำหรับ Time Wheel - เพิ่ม minValue
Widget _buildTimeWheel({
  required String label,
  required int maxValue,
  required int currentValue,
  required int minValue, // ✅ เพิ่ม parameter
  required Function(int) onChanged,
}) {
  return Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.2,
            controller: FixedExtentScrollController(
              initialItem: currentValue - minValue, // ✅ ปรับตำแหน่งเริ่มต้น
            ),
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              onChanged(index + minValue); // ✅ บวก minValue กลับ
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxValue - minValue, // ✅ จำนวนรายการลดลง
              builder: (context, index) {
                final actualValue = index + minValue; // ✅ ค่าจริง
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actualValue == currentValue ? Colors.blue[100] : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      actualValue.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: actualValue == currentValue ? FontWeight.bold : FontWeight.normal,
                        color: actualValue == currentValue ? Colors.blue : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}