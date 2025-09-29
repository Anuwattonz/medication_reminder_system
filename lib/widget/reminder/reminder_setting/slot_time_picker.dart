import 'package:flutter/material.dart';

class ModernTimePicker extends StatefulWidget {
  final TimeOfDay? initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const ModernTimePicker({
    super.key,
    this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<ModernTimePicker> createState() => _ModernTimePickerState();
}

class _ModernTimePickerState extends State<ModernTimePicker> {
  late int selectedHour;
  late int selectedMinute;
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime?.hour ?? 8;
    selectedMinute = widget.initialTime?.minute ?? 0;
    
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    // อัพเดทเฉพาะเมื่อกด "ตกลง"
    widget.onTimeChanged(TimeOfDay(hour: selectedHour, minute: selectedMinute));
  }

  void _onHourChanged(int newHour) {
    setState(() {
      selectedHour = newHour;
    });
    // ไม่อัพเดท parent ทันที แค่อัพเดท UI ในนี้
  }

  void _onMinuteChanged(int newMinute) {
    setState(() {
      selectedMinute = newMinute;
    });
    // ไม่อัพเดท parent ทันที แค่อัพเดท UI ในนี้
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.indigo[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'เลือกเวลา',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Time Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'น.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.indigo[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Scroll Wheel Pickers
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Hour Picker
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          'ชั่วโมง',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // Selection Highlight
                            Center(
                              child: Container(
                                height: 50,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.indigo[200]!,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            // Hour Wheel
                            ListWheelScrollView.useDelegate(
                              controller: hourController,
                              itemExtent: 50,
                              perspective: 0.003,
                              diameterRatio: 2.0,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: _onHourChanged,
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 24,
                                builder: (context, index) {
                                  final isSelected = index == selectedHour;
                                  return Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: isSelected ? 24 : 18,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.indigo[700] : Colors.grey[600],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Separator
                Container(
                  width: 1,
                  height: double.infinity,
                  color: Colors.grey[200],
                ),
                
                // Minute Picker
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          'นาที',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // Selection Highlight
                            Center(
                              child: Container(
                                height: 50,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.indigo[200]!,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            // Minute Wheel
                            ListWheelScrollView.useDelegate(
                              controller: minuteController,
                              itemExtent: 50,
                              perspective: 0.003,
                              diameterRatio: 2.0,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: _onMinuteChanged,
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  final isSelected = index == selectedMinute;
                                  return Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: isSelected ? 24 : 18,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.indigo[700] : Colors.grey[600],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Time Buttons
          Text(
            'เวลาแนะนำ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickTimeButton('06:00', 6, 0, Icons.wb_sunny, '6 โมงเช้า'),
              _buildQuickTimeButton('08:00', 8, 0, Icons.wb_sunny, '8 โมงเช้า'),
              _buildQuickTimeButton('12:00', 12, 0, Icons.wb_sunny_outlined, 'เที่ยง'),
              _buildQuickTimeButton('18:00', 18, 0, Icons.wb_twilight, '6 โมงเย็น'),
              _buildQuickTimeButton('20:00', 20, 0, Icons.nights_stay, '2 ทุ่ม'),
              _buildQuickTimeButton('22:00', 22, 0, Icons.bedtime, 'ก่อนนอน'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _confirmSelection(); // อัพเดทเมื่อกดตกลง
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTimeButton(String label, int hour, int minute, IconData icon, String tooltip) {
    final isSelected = selectedHour == hour && selectedMinute == minute;
    
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedHour = hour;
            selectedMinute = minute;
          });
          
          // Animate to the new positions
          hourController.animateToItem(
            hour,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          minuteController.animateToItem(
            minute,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          // ไม่อัพเดท parent ทันที แค่อัพเดท UI ในนี้
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo[600] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.indigo[200]!,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}