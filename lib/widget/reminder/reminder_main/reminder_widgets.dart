import 'package:flutter/material.dart';

// Forward declaration สำหรับ AppModel และ MedicationLink
// (จะใช้จากไฟล์ reminder_main.dart)

// Error View Widget
class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Empty Data View Widget
class EmptyDataView extends StatelessWidget {
  const EmptyDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ไม่มีข้อมูลการเตือนยา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ดึงลงเพื่อรีเฟรชข้อมูล',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Medication Card Widget
class MedicationCard extends StatelessWidget {
  final dynamic app; // เปลี่ยนจาก AppModel เป็น dynamic
  final int index;
  final bool isToggleEnabled;
  final Function(int) onToggle;
  final VoidCallback onTap;
  final String displayTime;
  final String activeDays;

  const MedicationCard({
    super.key,
    required this.app,
    required this.index,
    required this.isToggleEnabled,
    required this.onToggle,
    required this.onTap,
    required this.displayTime,
    required this.activeDays,
  });

  static final List<Map<String, dynamic>> _mealData = [
    {
      'name': 'มื้อเช้าก่อนอาหาร',
      'icon': Icons.wb_sunny,
      'colors': [Color(0xFFE65100), Color(0xFFBF360C)],
    },
    {
      'name': 'มื้อเช้าหลังอาหาร',
      'icon': Icons.free_breakfast,
      'colors': [Color(0xFF388E3C), Color(0xFF2E7D32)],
    },
    {
      'name': 'มื้อเที่ยงก่อนอาหาร',
      'icon': Icons.wb_sunny_outlined,
      'colors': [Color(0xFFF57C00), Color(0xFFEF6C00)],
    },
    {
      'name': 'มื้อเที่ยงหลังอาหาร',
      'icon': Icons.lunch_dining,
      'colors': [Color(0xFF0097A7), Color(0xFF00838F)],
    },
    {
      'name': 'มื้อเย็นก่อนอาหาร',
      'icon': Icons.wb_twilight,
      'colors': [Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
    },
    {
      'name': 'มื้อเย็นหลังอาหาร',
      'icon': Icons.dinner_dining,
      'colors': [Color(0xFF303F9F), Color(0xFF283593)],
    },
    {
      'name': 'ก่อนนอน',
      'icon': Icons.bedtime,
      'colors': [Color(0xFF512DA8), Color(0xFF4527A0)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isActive = app.status == '1';
    final mealData = index < _mealData.length ? _mealData[index] : _mealData[0];
    final colors = mealData['colors'] as List<Color>;
    final icon = mealData['icon'] as IconData;
    final mealName = mealData['name'] as String;

    String dayText = activeDays.isNotEmpty && activeDays != 'ไม่มีกำหนด'
        ? activeDays
        : 'ยังไม่กำหนด';

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.0),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MedicationCardHeader(
                    icon: icon,
                    mealName: mealName,
                  ),
                  const SizedBox(height: 20),
                  MedicationCardTime(displayTime: displayTime),
                  const SizedBox(height: 20),
                  MedicationCardFooter(
                    dayText: dayText,
                    isActive: isActive,
                    isToggleEnabled: isToggleEnabled,
                    onToggle: () => onToggle(app.pillSlot),
                    medicationCount: app.medicationLinks.length,
                    canToggle: app.canToggle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Medication Card Header Widget
class MedicationCardHeader extends StatelessWidget {
  final IconData icon;
  final String mealName;

  const MedicationCardHeader({
    super.key,
    required this.icon,
    required this.mealName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            mealName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Medication Card Time Widget
class MedicationCardTime extends StatelessWidget {
  final String displayTime;

  const MedicationCardTime({
    super.key,
    required this.displayTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          displayTime.contains('ไม่ระบุเวลา') 
              ? displayTime 
              : '$displayTime นาที',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Medication Card Footer Widget
class MedicationCardFooter extends StatelessWidget {
  final String dayText;
  final bool isActive;
  final bool isToggleEnabled;
  final VoidCallback onToggle;
  final int medicationCount;
  final bool canToggle;

  const MedicationCardFooter({
    super.key,
    required this.dayText,
    required this.isActive,
    required this.isToggleEnabled,
    required this.onToggle,
    required this.medicationCount,
    required this.canToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dayText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MedicationToggleSwitch(
              isActive: isActive,
              isEnabled: isToggleEnabled,
              canToggle: canToggle,
              onToggle: onToggle,
            ),
          ],
        ),
        if (medicationCount > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.medication,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$medicationCount รายการยา',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (!canToggle) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange[200],
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ต้องมีข้อมูลยาและกำหนดวันใช้งานก่อน',
                  style: TextStyle(
                    color: Colors.orange[200],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Medication Toggle Switch Widget
class MedicationToggleSwitch extends StatelessWidget {
  final bool isActive;
  final bool isEnabled;
  final bool canToggle;
  final VoidCallback onToggle;

  const MedicationToggleSwitch({
    super.key,
    required this.isActive,
    required this.isEnabled,
    required this.canToggle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractable = isEnabled && (canToggle || isActive);
    
    return GestureDetector(
      onTap: isInteractable ? onToggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        width: 70,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive 
              ? [
                  const Color(0xFF4CAF50),
                  const Color(0xFF388E3C),
                ]
              : !canToggle
              ? [
                  Colors.grey[400]!,
                  Colors.grey[500]!,
                ]
              : [
                  Colors.grey[300]!,
                  Colors.grey[400]!,
                ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive 
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      colors: [
                        Colors.green.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              alignment: isActive 
                ? Alignment.centerRight 
                : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isActive 
                      ? Icons.check_rounded 
                      : !canToggle 
                        ? Icons.lock_outline 
                        : Icons.close_rounded,
                    key: ValueKey(isActive ? 'active' : !canToggle ? 'locked' : 'inactive'),
                    color: isActive 
                      ? const Color(0xFF4CAF50)
                      : !canToggle
                        ? Colors.grey[600]
                        : Colors.grey[500],
                    size: 18,
                  ),
                ),
              ),
            ),
            if (!isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}