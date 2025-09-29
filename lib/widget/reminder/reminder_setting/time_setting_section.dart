import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/slot_settings.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/slot_time_picker.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/common_widgets.dart';

/// Section สำหรับตั้งค่าเวลา
class TimeSettingSection extends StatelessWidget {
  final SlotSettingController controller;

  const TimeSettingSection({super.key, required this.controller});

  Future<void> _selectTime(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ModernTimePicker( // ✅ หรือเปลี่ยนเป็น class ที่อยู่ใน slot_time_picker.dart
          initialTime: controller.selectedTime,
          onTimeChanged: controller.selectTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? timingInfo;
    if (controller.selectedTimingId != null) {
      final timingName = controller.getTimingName();
      if (timingName != null) timingInfo = ' ($timingName)';
    }

    return SettingSection(
      icon: Icons.access_time,
      title: 'เวลาที่ตั้ง',
      badge: timingInfo,
      child: Column(
        children: [
          TimeDisplay(
            selectedTime: controller.selectedTime,
            onTap: () => _selectTime(context),
          ),
          if (controller.selectedTime == null) ...[
            const SizedBox(height: 16),
            QuickTimeOptions(controller: controller),
          ],
        ],
      ),
    );
  }
}

/// Widget สำหรับแสดงเวลาที่เลือก
class TimeDisplay extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;

  const TimeDisplay({
    super.key,
    required this.selectedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selectedTime != null 
                ? [Colors.indigo[50]!, Colors.indigo[100]!]
                : [Colors.grey[50]!, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedTime != null ? Colors.indigo[200]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: selectedTime != null ? _buildSelectedTime() : _buildPlaceholderTime(),
      ),
    );
  }

  Widget _buildSelectedTime() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                  fontFamily: 'monospace',
                ),
              ),
              TextSpan(
                text: ' น.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 16, color: Colors.indigo[500]),
            const SizedBox(width: 4),
            Text(
              'แตะเพื่อแก้ไข',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.indigo[500], 
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderTime() {
    return Column(
      children: [
        Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'แตะเพื่อเลือกเวลา', 
          style: TextStyle(
            fontSize: 16, 
            color: Colors.grey[600], 
            fontWeight: FontWeight.w500
          )
        ),
        const SizedBox(height: 4),
        Text(
          'กำหนดเวลาที่ต้องการกินยา', 
          style: TextStyle(fontSize: 12, color: Colors.grey[500])
        ),
      ],
    );
  }
}

/// Widget สำหรับแสดงตัวเลือกเวลาที่แนะนำ
class QuickTimeOptions extends StatelessWidget {
  final SlotSettingController controller;

  const QuickTimeOptions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const timeOptions = [
      (label: '06:00 น.', hour: 6, minute: 0, period: 'เช้า'),
      (label: '08:00 น.', hour: 8, minute: 0, period: 'เช้า'),
      (label: '12:00 น.', hour: 12, minute: 0, period: 'เที่ยง'),
      (label: '18:00 น.', hour: 18, minute: 0, period: 'เย็น'),
      (label: '20:00 น.', hour: 20, minute: 0, period: 'เย็น'),
      (label: '22:00 น.', hour: 22, minute: 0, period: 'ก่อนนอน'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เวลาแนะนำ', 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: Colors.grey[700]
          )
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeOptions.map((option) => 
            QuickTimeChip(
              label: option.label,
              period: option.period,
              onTap: () => controller.selectQuickTime(option.hour, option.minute),
            )
          ).toList(),
        ),
      ],
    );
  }
}

/// Widget สำหรับแสดง chip เวลาแนะนำ
class QuickTimeChip extends StatelessWidget {
  final String label;
  final String period;
  final VoidCallback onTap;

  const QuickTimeChip({
    super.key,
    required this.label,
    required this.period,
    required this.onTap,
  });

  IconData _getTimeIcon(String period) {
    switch (period) {
      case 'เช้า': return Icons.wb_sunny;
      case 'เที่ยง': return Icons.wb_sunny_outlined;
      case 'เย็น': return Icons.wb_twilight;
      case 'ก่อนนอน': return Icons.bedtime;
      default: return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.indigo[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getTimeIcon(period), size: 14, color: Colors.indigo[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.indigo[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}