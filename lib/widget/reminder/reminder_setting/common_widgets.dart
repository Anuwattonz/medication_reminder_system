import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/slot_settings.dart';

/// Widget สำหรับสร้าง section ที่ใช้ร่วมกัน
class SettingSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Widget child;

  const SettingSection({
    super.key,
    required this.icon,
    required this.title,
    this.badge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.indigo[600], size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11, 
                      color: Colors.green[700], 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// ปุ่มบันทึก
class SaveButton extends StatelessWidget {
  final SlotSettingController controller;
  final VoidCallback onSave;

  const SaveButton({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (controller.isLoading || !controller.canSave()) ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.canSave() ? Colors.indigo[600] : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text(
              _getButtonText(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (!controller.canSave()) {
      return 'กรุณากรอกเวลาและวันที่กิน';
    }
    
    return controller.selectedMedications.isEmpty 
        ? 'บันทึกการตั้งค่า (ไม่มียา)' 
        : 'บันทึกการตั้งค่า';
  }
}

/// Widget สำหรับแสดงการ์ดข้อมูล
class InfoCard extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final String title;
  final String subtitle;
  final Widget? actionButton;

  const InfoCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: color[300]!),
        borderRadius: BorderRadius.circular(12),
        color: color[50],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color[400]),
          const SizedBox(height: 8),
          Text(
            title, 
            style: TextStyle(color: color[700], fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 8),
          Text(
            subtitle, 
            style: TextStyle(color: color[600], fontSize: 12), 
            textAlign: TextAlign.center
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 12),
            actionButton!,
          ],
        ],
      ),
    );
  }
}

/// Widget สำหรับแสดงรูปยา
class MedicationImage extends StatelessWidget {
  final String? pictureUrl;
  final double size;

  const MedicationImage({
    super.key,
    this.pictureUrl,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (pictureUrl != null && pictureUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(pictureUrl!),
            fit: BoxFit.cover,
            onError: (_, _) => {},
          ),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.24), // 12/50 = 0.24
      decoration: BoxDecoration(
        color: Colors.indigo[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.medication, 
        color: Colors.indigo[600], 
        size: size * 0.48 // 24/50 = 0.48
      ),
    );
  }
}