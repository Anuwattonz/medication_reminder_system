import 'package:flutter/material.dart';

/// การ์ดแสดงข้อมูลของ Slot
class SlotInfoCard extends StatelessWidget {
  final dynamic slotData;
  final dynamic appInfo;
  final String activeDays;
  final String Function(String) formatTime;

  const SlotInfoCard({
    super.key,
    required this.slotData,
    required this.appInfo,
    required this.activeDays,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    // ใช้ข้อมูลจาก API ถ้ามี ไม่งั้นใช้ข้อมูลเดิม
    String rawTiming = appInfo?.timing ?? slotData?.timing ?? 'ไม่ได้ตั้งค่า';
    
    // แปลงเวลาให้แสดงแค่ชั่วโมง:นาที
    String displayTiming = formatTime(rawTiming);
    
    final status = appInfo?.status ?? slotData?.status ?? '0';
    final statusText = status == '1' ? 'เปิดใช้งาน' : 'ปิดใช้งาน';
    final statusIcon = status == '1' ? Icons.check_circle : Icons.cancel;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SlotDetailRow(
            icon: Icons.schedule,
            label: 'เวลาที่ตั้ง',
            value: displayTiming,
          ),
          Divider(color: Colors.grey[300], height: 1),
          SlotDetailRow(
            icon: Icons.calendar_today,
            label: 'วันที่กิน',
            value: activeDays,
          ),
          Divider(color: Colors.grey[300], height: 1),
          SlotDetailRow(
            icon: statusIcon,
            label: 'สถานะ',
            value: statusText,
          ),
        ],
      ),
    );
  }
}

/// แถวแสดงรายละเอียดข้อมูล
class SlotDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SlotDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}