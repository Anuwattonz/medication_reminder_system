import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/slot_settings.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/common_widgets.dart';
/// Section สำหรับตั้งค่าวัน
class DaySettingSection extends StatelessWidget {
  final SlotSettingController controller;

  const DaySettingSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SettingSection(
      icon: Icons.calendar_today,
      title: 'วันที่กิน',
      child: Column(
        children: [
          DayGrid(controller: controller),
          const SizedBox(height: 16),
          DayQuickActions(controller: controller),
        ],
      ),
    );
  }
}

/// Widget สำหรับแสดงตาราง grid วัน
class DayGrid extends StatelessWidget {
  final SlotSettingController controller;

  const DayGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // แถวแรก: อาทิตย์ - พุธ (4 วัน)
        Row(
          children: List.generate(4, (i) => 
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                child: DayChip(controller: controller, index: i),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // แถวสอง: พฤหัสบดี - เสาร์ (3 วัน + ช่องว่าง)
        Row(
          children: [
            ...List.generate(3, (i) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: DayChip(controller: controller, index: i + 4),
                ),
              ),
            ),
            const Expanded(child: SizedBox()), // ช่องว่าง
          ],
        ),
      ],
    );
  }
}

/// Widget สำหรับแสดง chip วัน
class DayChip extends StatelessWidget {
  final SlotSettingController controller;
  final int index;

  const DayChip({
    super.key,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dayKey = SlotSettingController.dayNames[index];
    final isSelected = controller.selectedDays[dayKey] ?? false;
    
    return InkWell(
      onTap: () => controller.toggleDay(dayKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[600] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            SlotSettingController.dayLabels[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Widget สำหรับแสดงปุ่มเลือกวันแบบเร็ว
class DayQuickActions extends StatelessWidget {
  final SlotSettingController controller;

  const DayQuickActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: controller.selectAllDays,
            style: TextButton.styleFrom(
              foregroundColor: Colors.indigo[600], 
              padding: const EdgeInsets.symmetric(vertical: 8)
            ),
            child: const Text('ทั้งหมด', style: TextStyle(fontSize: 13)),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: controller.selectWeekdays,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange[600], 
              padding: const EdgeInsets.symmetric(vertical: 8)
            ),
            child: const Text('จ-ศ', style: TextStyle(fontSize: 13)),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: controller.clearAllDays,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600], 
              padding: const EdgeInsets.symmetric(vertical: 8)
            ),
            child: const Text('ล้าง', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}