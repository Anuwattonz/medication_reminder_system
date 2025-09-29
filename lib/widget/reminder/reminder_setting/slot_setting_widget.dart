import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/slot_settings.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/time_setting_section.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/day_setting_section.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/medication_setting_section.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/common_widgets.dart';


/// Widget หลักสำหรับแสดงส่วนการตั้งค่าต่างๆ ของ slot
class SlotSettingWidget extends StatelessWidget {
  final SlotSettingController controller;
  final VoidCallback onSave;

  const SlotSettingWidget({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimeSettingSection(controller: controller),
          const SizedBox(height: 24),
          DaySettingSection(controller: controller),
          const SizedBox(height: 24),
          MedicationSettingSection(controller: controller),
          const SizedBox(height: 32),
          SaveButton(controller: controller, onSave: onSave),
        ],
      ),
    );
  }
}