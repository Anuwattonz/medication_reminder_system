import 'package:flutter/material.dart';

/// Widget สำหรับปุ่มกรองช่องยาและ Bottom Sheet
class ReminderFilterButton extends StatelessWidget {
  final Set<int> selectedSlots;
  final Function(Set<int>) onSlotsChanged;
  final List<dynamic> apps; // รายการ AppModel
  
  // ข้อมูลช่องยาที่ปรับปรุงใหม่ - ใช้สีที่ชัดและเข้มกว่า
  static final List<Map<String, dynamic>> _slotInfo = [
    {
      'name': 'มื้อเช้าก่อนอาหาร',
      'shortName': 'เช้าก่อน',
      'color': Color(0xFF2E7D32), // เขียวเข้ม
      'slot': 1,
    },
    {
      'name': 'มื้อเช้าหลังอาหาร',
      'shortName': 'เช้าหลัง',
      'color': Color(0xFF388E3C), // เขียวเข้มกว่า
      'slot': 2,
    },
    {
      'name': 'มื้อเที่ยงก่อนอาหาร',
      'shortName': 'เที่ยงก่อน',
      'color': Color(0xFFE65100), // ส้มเข้ม
      'slot': 3,
    },
    {
      'name': 'มื้อเที่ยงหลังอาหาร',
      'shortName': 'เที่ยงหลัง',
      'color': Color(0xFFD84315), // ส้มแดงเข้ม
      'slot': 4,
    },
    {
      'name': 'มื้อเย็นก่อนอาหาร',
      'shortName': 'เย็นก่อน',
      'color': Color(0xFF7B1FA2), // ม่วงเข้ม
      'slot': 5,
    },
    {
      'name': 'มื้อเย็นหลังอาหาร',
      'shortName': 'เย็นหลัง',
      'color': Color(0xFF512DA8), // ม่วงเข้มกว่า
      'slot': 6,
    },
    {
      'name': 'ก่อนนอน',
      'shortName': 'ก่อนนอน',
      'color': Color(0xFF1565C0), // น้ำเงินเข้ม
      'slot': 7,
    },
  ];

  const ReminderFilterButton({
    super.key,
    required this.selectedSlots,
    required this.onSlotsChanged,
    required this.apps,
  });

  // ค้นหาข้อมูลยาตาม slot
  dynamic _getSlotData(int slot) {
    try {
      return apps.firstWhere((app) => app.pillSlot == slot);
    } catch (e) {
      return null;
    }
  }

  // แสดง Filter Dialog
  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(context),
    );
  }

  Widget _buildFilterBottomSheet(BuildContext context) {
    Set<int> tempSelectedSlots = Set.from(selectedSlots);
    
    // เพิ่มช่องที่เปิดใช้งานเข้าไปใน tempSelectedSlots เสมอ
    for (var app in apps) {
      if (app.status == '1') {
        tempSelectedSlots.add(app.pillSlot);
      }
    }
    
    return StatefulBuilder(
      builder: (context, setBottomSheetState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue[200]!, width: 1),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'เลือกช่องยาที่ต้องการแสดง',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'เลือก ${tempSelectedSlots.length} จาก ${_slotInfo.length} ช่อง',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            label: 'เลือกทั้งหมด',
                            color: Colors.blue,
                            onPressed: () {
                              setBottomSheetState(() {
                                tempSelectedSlots = {1, 2, 3, 4, 5, 6, 7};
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            label: 'เฉพาะที่เปิด',
                            color: Colors.green,
                            onPressed: () {
                              setBottomSheetState(() {
                                Set<int> activeSlotsWithMeds = {};
                                for (var app in apps) {
                                  bool isActive = app.status == '1';
                                  if (isActive) {
                                    activeSlotsWithMeds.add(app.pillSlot);
                                  }
                                }
                                tempSelectedSlots = activeSlotsWithMeds.isNotEmpty 
                                    ? activeSlotsWithMeds 
                                    : {1, 2, 3, 4, 5, 6, 7};
                                
                                // ตรวจสอบให้แน่ใจว่าช่องที่เปิดใช้งานยังอยู่
                                for (var app in apps) {
                                  if (app.status == '1') {
                                    tempSelectedSlots.add(app.pillSlot);
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              
              // Slot checkboxes
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    children: _slotInfo.map((slotInfo) {
                      final slot = slotInfo['slot'];
                      final isSelected = tempSelectedSlots.contains(slot);
                      final slotData = _getSlotData(slot);
                      final hasData = slotData != null;
                      final isActive = slotData?.status == '1';
                      final hasMedications = hasData && slotData.medicationLinks.isNotEmpty;
                      final isLocked = isActive; // ช่องที่เปิดใช้งานจะถูก lock
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? slotInfo['color'].withOpacity(0.15)
                              : Colors.grey[50],
                          border: Border.all(
                            color: isSelected 
                                ? slotInfo['color']
                                : Colors.grey[300]!,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isLocked ? null : () {
                              setBottomSheetState(() {
                                if (isSelected) {
                                  tempSelectedSlots.remove(slot);
                                } else {
                                  tempSelectedSlots.add(slot);
                                }
                              });
                            },
                            child: Opacity(
                              opacity: isLocked ? 0.9 : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // สีประจำช่อง
                                    Container(
                                      width: 5,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: slotInfo['color'],
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: slotInfo['color'].withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // เนื้อหาหลัก
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  slotInfo['name'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: isSelected 
                                                        ? slotInfo['color']
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              if (isLocked)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, 
                                                    vertical: 4
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.orange[200]!, 
                                                      width: 1
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'เปิดอยู่',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.orange[800],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              // สถานะ
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, 
                                                  vertical: 4
                                                ),
                                                decoration: BoxDecoration(
                                                  color: hasData 
                                                      ? (isActive ? Colors.green[50] : Colors.orange[50])
                                                      : Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: hasData 
                                                        ? (isActive ? Colors.green[200]! : Colors.orange[200]!)
                                                        : Colors.grey[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: hasData 
                                                            ? (isActive ? Colors.green[600] : Colors.orange[600])
                                                            : Colors.grey[400],
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      hasData 
                                                          ? (isActive ? 'เปิดใช้งาน' : 'ปิดใช้งาน')
                                                          : 'ไม่มีข้อมูล',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: hasData 
                                                            ? (isActive ? Colors.green[800] : Colors.orange[800])
                                                            : Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // จำนวนยา
                                              if (hasMedications) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, 
                                                    vertical: 4
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.blue[200]!, 
                                                      width: 1
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${slotData.medicationLinks.length} ยา',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.blue[800],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Checkbox
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected 
                                              ? slotInfo['color']
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: isSelected 
                                            ? slotInfo['color']
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Apply button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: tempSelectedSlots.isNotEmpty ? () {
                      onSlotsChanged(tempSelectedSlots);
                      Navigator.pop(context);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tempSelectedSlots.isNotEmpty 
                          ? Colors.blue[600] 
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: tempSelectedSlots.isNotEmpty ? 2 : 0,
                    ),
                    child: Text(
                      tempSelectedSlots.isNotEmpty 
                          ? 'แสดง ${tempSelectedSlots.length} ช่องยา'
                          : 'กรุณาเลือกอย่างน้อย 1 ช่อง',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Safe area bottom
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required MaterialColor color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showFilterDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'กรอง (${selectedSlots.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}