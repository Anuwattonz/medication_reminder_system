import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/slot_settings.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/common_widgets.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/medication_selector_dialog.dart';
/// Section สำหรับตั้งค่ายา
class MedicationSettingSection extends StatelessWidget {
  final SlotSettingController controller;

  const MedicationSettingSection({super.key, required this.controller});

  Future<void> _showMedicationSelector(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => MedicationSelectorDialog(
        availableMedications: controller.availableMedications,
        selectedMedications: controller.selectedMedications,
        selectedTimingId: controller.selectedTimingId,
        onMedicationsSelected: controller.addSelectedMedications,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingSection(
      icon: Icons.medication,
      title: 'รายการยา',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (controller.selectedTimingId != null) 
                TimingInfo(controller: controller),
              TextButton.icon(
                onPressed: controller.availableMedications.isNotEmpty 
                    ? () => _showMedicationSelector(context) 
                    : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มยา'),
                style: TextButton.styleFrom(
                  foregroundColor: controller.availableMedications.isNotEmpty 
                      ? Colors.indigo[600] 
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MedicationContent(controller: controller),
        ],
      ),
    );
  }
}

/// Widget สำหรับแสดงข้อมูล timing
class TimingInfo extends StatelessWidget {
  final SlotSettingController controller;

  const TimingInfo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue[50],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            'แสดงยาสำหรับ${controller.getTimingName() ?? 'ช่วงเวลาที่เลือก'}',
            style: TextStyle(
              color: Colors.blue[700], 
              fontSize: 12, 
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget สำหรับแสดงเนื้อหายา
class MedicationContent extends StatelessWidget {
  final SlotSettingController controller;

  const MedicationContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // กรณีต่างๆ ตามลำดับความสำคัญ
    if (_shouldShowSelectTimeFirst()) {
      return InfoCard(
        icon: Icons.warning_outlined,
        color: Colors.orange,
        title: 'กรุณาเลือกเวลาก่อน',
        subtitle: 'เมื่อเลือกเวลาแล้ว ระบบจะแสดงยาที่เหมาะสมสำหรับเวลานั้น',
      );
    }
    
    if (_shouldShowNoMedicationForTiming()) {
      return InfoCard(
        icon: Icons.warning_outlined,
        color: Colors.orange,
        title: 'ไม่พบยาที่ตรงกับช่วงเวลา',
        subtitle: controller.getTimingName() ?? 'ช่วงเวลาที่เลือก',
      );
    }
    
    if (_shouldShowNoMedicationInSystem()) {
      return InfoCard(
        icon: Icons.warning_outlined,
        color: Colors.orange,
        title: 'ไม่มีรายการยาในระบบ',
        subtitle: 'กรุณาเพิ่มยาในระบบก่อนเลือกใช้งาน',
      );
    }
    
    if (_shouldShowNoSelectedMedication()) {
      return InfoCard(
        icon: Icons.info_outline,
        color: Colors.blue,
        title: 'ยังไม่มีรายการยาที่เลือก',
        subtitle: 'คุณสามารถบันทึกการตั้งค่าได้โดยไม่ต้องเลือกยา\nหรือสามารถเพิ่มยาได้ตามต้องการ',
        actionButton: controller.availableMedications.isNotEmpty ? 
          ElevatedButton.icon(
            onPressed: () => _showMedicationSelector(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('เลือกยา'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ) : null,
      );
    }
    
    // แสดงรายการยาที่เลือก
    return Column(
      children: controller.selectedMedications.asMap().entries.map((entry) {
        return MedicationItemWithAmount(
          medication: entry.value, 
          index: entry.key, 
          controller: controller
        );
      }).toList(),
    );
  }

  // Helper methods สำหรับตรวจสอบเงื่อนไข
  bool _shouldShowSelectTimeFirst() {
    return controller.availableMedications.isEmpty && 
           !controller.isLoading && 
           controller.selectedTimingId == null;
  }

  bool _shouldShowNoMedicationForTiming() {
    return controller.availableMedications.isEmpty && 
           !controller.isLoading && 
           controller.selectedTimingId != null;
  }

  bool _shouldShowNoMedicationInSystem() {
    return controller.availableMedications.isEmpty && 
           !controller.isLoading &&
           controller.selectedTimingId == null;
  }

  bool _shouldShowNoSelectedMedication() {
    return controller.selectedMedications.isEmpty &&
           controller.availableMedications.isNotEmpty;
  }

  Future<void> _showMedicationSelector(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => MedicationSelectorDialog(
        availableMedications: controller.availableMedications,
        selectedMedications: controller.selectedMedications,
        selectedTimingId: controller.selectedTimingId,
        onMedicationsSelected: controller.addSelectedMedications,
      ),
    );
  }
}
class MedicationItemWithAmount extends StatelessWidget {
  final Map<String, dynamic> medication;
  final int index;
  final SlotSettingController controller;

  const MedicationItemWithAmount({
    super.key,
    required this.medication,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final name = medication['medication_name']?.toString() ?? 
                 medication['medication_nickname']?.toString() ?? 
                 'ไม่ระบุชื่อ';
    final amount = medication['amount'] ?? 1.0;
    final pictureUrl = medication['picture_url']?.toString();
    final unit = controller.getMedicationUnit(medication);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ส่วนหัว - ชื่อยาและปุ่มลบ
          Row(
            children: [
              MedicationImage(pictureUrl: pictureUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  ), 
                  overflow: TextOverflow.ellipsis, 
                  maxLines: 2
                ),
              ),
              IconButton(
                onPressed: () => controller.removeMedication(index),
                icon: Icon(Icons.remove_circle, color: Colors.red[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ส่วนเลือกจำนวน
          AmountSelector(
            amount: amount,
            unit: unit,
            onChanged: (newAmount) => 
              controller.updateMedicationAmount(index, newAmount),
          ),
        ],
      ),
    );
  }
}

/// Widget สำหรับเลือกจำนวนยา - รองรับทศนิยม
class AmountSelector extends StatefulWidget {
  final dynamic amount; // รับได้ทั้ง int และ double
  final String unit;
  final Function(double) onChanged; // ส่งเป็น double

  const AmountSelector({
    super.key,
    required this.amount,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<AmountSelector> createState() => _AmountSelectorState();
}

class _AmountSelectorState extends State<AmountSelector> {
  bool _showMoreOptions = false;

  // ตัวเลือกจำนวนยาพื้นฐาน
  static const List<Map<String, dynamic>> basicAmountOptions = [
    {'value': 0.5, 'label': '1/2'},
    {'value': 1.0, 'label': '1'},
    {'value': 2.0, 'label': '2'},
  ];

  // ตัวเลือกจำนวนยาเพิ่มเติม
  static const List<Map<String, dynamic>> moreAmountOptions = [
    {'value': 0.25, 'label': '1/4'},
    {'value': 1.5, 'label': '1.5'},
    {'value': 2.5, 'label': '2.5'},
    {'value': 3.0, 'label': '3'},
    {'value': 3.5, 'label': '3.5'},
    {'value': 4.0, 'label': '4'},
  ];

  // แปลงจำนวนเป็นข้อความแสดง
  String _getDisplayAmount(dynamic amount) {
    double amountValue = 0.0;
    if (amount is int) {
      amountValue = amount.toDouble();
    } else if (amount is double) {
      amountValue = amount;
    } else if (amount is String) {
      amountValue = double.tryParse(amount) ?? 1.0;
    }
    
    // แสดงเศษส่วนพิเศษ
    if (amountValue == 0.25) return '1/4';
    if (amountValue == 0.5) return 'ครึ่ง';
    if (amountValue <= 0) return '1';
    if (amountValue == amountValue.toInt()) {
      return amountValue.toInt().toString();
    }
    return amountValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount = widget.amount is int ? 
        (widget.amount as int).toDouble() : 
        widget.amount as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'จำนวน:',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.grey[700]
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_getDisplayAmount(widget.amount)} ${widget.unit}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // แสดงปุ่มเลือกจำนวนพื้นฐาน
        Wrap(
          spacing: 4,
          runSpacing: 6,
          children: [
            ...basicAmountOptions.map((option) {
              final value = option['value'] as double;
              final label = option['label'] as String;
              final isSelected = currentAmount == value;
              
              return _buildAmountButton(
                label: label,
                value: value,
                isSelected: isSelected,
                context: context,
              );
            }),
            // ปุ่ม "อื่นๆ"
            _buildOtherButton(),
          ],
        ),
        
        // แสดงตัวเลือกเพิ่มเติมถ้ากดปุ่ม "อื่นๆ"
        if (_showMoreOptions) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตัวเลือกเพิ่มเติม:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: moreAmountOptions.map((option) {
                    final value = option['value'] as double;
                    final label = option['label'] as String;
                    final isSelected = currentAmount == value;
                    
                    return _buildAmountButton(
                      label: label,
                      value: value,
                      isSelected: isSelected,
                      context: context,
                      isCompact: true,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountButton({
    required String label,
    required double value,
    required bool isSelected,
    required BuildContext context,
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: () {
        widget.onChanged(value);
        // ซ่อนตัวเลือกเพิ่มเติมหลังเลือก
        if (_showMoreOptions) {
          setState(() {
            _showMoreOptions = false;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16, 
          vertical: isCompact ? 6 : 8
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[600] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 16 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _showMoreOptions = !_showMoreOptions;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _showMoreOptions ? Colors.orange[600] : Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _showMoreOptions ? Colors.orange[600]! : Colors.orange[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'อื่นๆ',
              style: TextStyle(
                color: _showMoreOptions ? Colors.white : Colors.orange[700],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showMoreOptions ? Icons.expand_less : Icons.expand_more,
              color: _showMoreOptions ? Colors.white : Colors.orange[700],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}