import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_setting/common_widgets.dart';
/// Dialog สำหรับเลือกยา
class MedicationSelectorDialog extends StatefulWidget {
  final List<dynamic> availableMedications;
  final List<dynamic> selectedMedications;
  final int? selectedTimingId;
  final Function(List<dynamic>) onMedicationsSelected;

  const MedicationSelectorDialog({
    super.key,
    required this.availableMedications,
    required this.selectedMedications,
    this.selectedTimingId,
    required this.onMedicationsSelected,
  });

  @override
  State<MedicationSelectorDialog> createState() => _MedicationSelectorDialogState();
}

class _MedicationSelectorDialogState extends State<MedicationSelectorDialog> {
  List<Map<String, dynamic>> tempSelected = [];

  bool _isMedicationAlreadySelected(int medicationId) {
    return widget.selectedMedications.any((selected) => 
      selected['medication_id'] == medicationId);
  }

  void _toggleMedicationSelection(Map<String, dynamic> medication, bool isSelected) {
    final medicationId = medication['medication_id'] ?? 0;
    if (medicationId <= 0) return;

    setState(() {
      if (isSelected) {
        if (!tempSelected.any((m) => m['medication_id'] == medicationId)) {
          tempSelected.add(Map<String, dynamic>.from(medication));
        }
      } else {
        tempSelected.removeWhere((m) => m['medication_id'] == medicationId);
      }
    });
  }

  bool _isMedicationTempSelected(int medicationId) {
    return tempSelected.any((m) => m['medication_id'] == medicationId);
  }

  String _getMedicationUnit(Map<String, dynamic> med) {
    // ลำดับการเช็ค: unit_type_name -> unit_type -> dosage_name -> dosage_form -> default
    for (final key in ['unit_type_name', 'unit_type', 'dosage_name', 'dosage_form']) {
      final value = med[key]?.toString();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return 'เม็ด';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogHeader(),
            const Divider(),
            Expanded(child: _medicationList()),
            const SizedBox(height: 16),
            _actionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _dialogHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.medication, color: Colors.indigo[600], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกรายการยา', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              Text(
                'เลือกยาที่ต้องการเพิ่ม (จำนวนสามารถปรับได้ภายหลัง)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.close)
        ),
      ],
    );
  }

  Widget _medicationList() {
    if (widget.availableMedications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.selectedTimingId != null 
                  ? 'ไม่มียาสำหรับเวลานี้' 
                  : 'ไม่มีรายการยาในระบบ',
              style: TextStyle(
                color: Colors.grey[600], 
                fontSize: 16, 
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.availableMedications.length,
      itemBuilder: (context, index) {
        final medication = widget.availableMedications[index];
        if (medication is! Map) return const SizedBox.shrink();
        
        final medicationMap = Map<String, dynamic>.from(medication);
        final medicationId = medicationMap['medication_id'] ?? 0;
        if (medicationId <= 0) return const SizedBox.shrink();
        
        return _MedicationTile(
          medication: medicationMap,
          isAlreadySelected: _isMedicationAlreadySelected(medicationId),
          isTempSelected: _isMedicationTempSelected(medicationId),
          unit: _getMedicationUnit(medicationMap),
          onToggle: (isSelected) => _toggleMedicationSelection(medicationMap, isSelected),
        );
      },
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: tempSelected.isNotEmpty ? () {
              widget.onMedicationsSelected(tempSelected);
              Navigator.pop(context);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: tempSelected.isNotEmpty ? Colors.indigo[600] : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              tempSelected.isEmpty 
                ? 'เลือกยา' 
                : 'เพิ่ม ${tempSelected.length} รายการ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget สำหรับแสดงแต่ละรายการยาใน list
class _MedicationTile extends StatelessWidget {
  final Map<String, dynamic> medication;
  final bool isAlreadySelected;
  final bool isTempSelected;
  final String unit;
  final Function(bool) onToggle;

  const _MedicationTile({
    required this.medication,
    required this.isAlreadySelected,
    required this.isTempSelected,
    required this.unit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = medication['medication_name']?.toString() ?? 
                 medication['medication_nickname']?.toString() ?? 
                 'ไม่ระบุชื่อ';
    final pictureUrl = medication['picture_url']?.toString();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: MedicationImage(pictureUrl: pictureUrl),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        subtitle: Text(
          'หน่วย: $unit',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildTrailing() {
    // เปลี่ยนจากแสดง "เลือกแล้ว" เป็นใช้ checkbox เหมือนเดิม
    // แต่ปิดการใช้งานและเปลี่ยนสีเมื่อเลือกแล้ว
    return Transform.scale(
      scale: 0.9,
      child: Checkbox(
        value: isAlreadySelected || isTempSelected,
        onChanged: isAlreadySelected 
            ? null // ปิดการใช้งานถ้าเลือกแล้ว
            : (value) => onToggle(value ?? false),
        activeColor: isAlreadySelected 
            ? Colors.grey[400] // สีเทาถ้าเลือกแล้ว
            : Colors.indigo[600], // สีปกติถ้ายังไม่เลือก
      ),
    );
  }
}