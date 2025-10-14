import 'package:flutter/material.dart';

// Widget สำหรับแสดงข้อมูลผู้ใช้ที่สามารถกดแก้ไขได้ (แก้ไขใหม่)
class UserInfoCard extends StatelessWidget {
  final String username;
  final String connectId;
  final Function(String)? onUsernameChanged;
  final bool isLoading; // เพิ่ม parameter สำหรับ loading state

  const UserInfoCard({
    super.key,
    required this.username,
    required this.connectId,
    this.onUsernameChanged,
    this.isLoading = false, // ค่าเริ่มต้น
  });

void _showEditUsernameDialog(BuildContext context) {
  if (isLoading) return; // ป้องกันไม่ให้เปิด dialog ขณะ loading

  final TextEditingController controller = TextEditingController(text: username);
  final FocusNode focusNode = FocusNode(); // เพิ่ม FocusNode
  bool isKeyboardVisible = false; // ตัวแปรติดตาม keyboard
  
  showDialog(
    context: context,
    barrierDismissible: false, // ปิดการปิด dialog อัตโนมัติ เพื่อให้เราจัดการเอง
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          // ✅ ติดตาม focus changes
          focusNode.addListener(() {
            setState(() {
              isKeyboardVisible = focusNode.hasFocus;
            });
          });

          return PopScope(
            canPop: !isKeyboardVisible, // ถ้ามี keyboard ไม่ให้ pop
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && isKeyboardVisible) {
                // ถ้ามี keyboard ให้ปิด keyboard ก่อน
                focusNode.unfocus();
              }
            },
            child: GestureDetector(
              // จัดการการกดข้างนอก dialog
              onTap: () {
                if (isKeyboardVisible) {
                  // ถ้ามี keyboard ให้ปิด keyboard ก่อน (ไม่ปิด dialog)
                  focusNode.unfocus();
                  // ไม่เรียก Navigator.pop() ที่นี่
                } else {
                  // ถ้าไม่มี keyboard ให้ปิด dialog
                  focusNode.dispose(); //  ทำความสะอาด
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Container(
                color: Colors.transparent,
                child: GestureDetector(
                  // เพิ่ม GestureDetector สำหรับ dialog เพื่อไม่ให้ onTap ด้านบนทำงาน
                  onTap: () {
                    // ถ้ากดใน dialog ให้ปิดแค่ keyboard
                    if (isKeyboardVisible) {
                      focusNode.unfocus();
                    }
                  },
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'แก้ไขชื่อผู้ใช้',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        //  เพิ่มปุ่ม X เพื่อปิด dialog
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            focusNode.unfocus(); // ปิด keyboard ก่อน
                            focusNode.dispose(); // ทำความสะอาด
                            Navigator.of(dialogContext).pop(); // ปิด dialog
                          },
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'กรุณาใส่ชื่อผู้ใช้ใหม่:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode, // ใช้ FocusNode
                            autofocus: false, //  เปลี่ยนเป็น false เพื่อไม่ให้ขึ้น keyboard ทันที
                            style: const TextStyle(fontSize: 16),
                            //  เพิ่ม textInputAction และ onSubmitted
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) {
                              // เมื่อกด Done บน keyboard จะทำการบันทึก
                              final newUsername = value.trim();
                              if (newUsername.isNotEmpty && newUsername != username) {
                                onUsernameChanged?.call(newUsername);
                              }
                              focusNode.unfocus(); // ปิด keyboard
                              focusNode.dispose(); // ทำความสะอาด
                              Navigator.of(dialogContext).pop(); // ปิด dialog
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                              hintText: 'ชื่อผู้ใช้',
                              prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          focusNode.unfocus(); // ปิด keyboard ก่อน
                          focusNode.dispose(); // ทำความสะอาด
                          Navigator.of(dialogContext).pop(); // ปิด dialog
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            final newUsername = controller.text.trim();
                            if (newUsername.isNotEmpty && newUsername != username) {
                              onUsernameChanged?.call(newUsername);
                            }
                            focusNode.unfocus(); // ปิด keyboard ก่อน
                            focusNode.dispose(); // ทำความสะอาด
                            Navigator.of(dialogContext).pop(); // ปิด dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'บันทึก',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _showEditUsernameDialog(context), // ปิดการคลิกขณะ loading
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              spreadRadius: 0,
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวพร้อมไอคอนแก้ไข
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ข้อมูลผู้ใช้',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        )
                      : Icon(
                          Icons.edit,
                          color: Colors.blue[600],
                          size: 18,
                        ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ชื่อผู้ใช้ - ✅ แก้ไขให้ข้อความยาวเป็น ...
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    color: Colors.blue[400],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded( // ✅ ใช้ Expanded เพื่อให้ข้อความใช้พื้นที่ที่เหลือ
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ชื่อผู้ใช้',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1, // ✅ จำกัด 1 บรรทัด
                          overflow: TextOverflow.ellipsis, // แสดง ... เมื่อยาว
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Connect ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Colors.green[600],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connectId,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // สถานะการเชื่อมต่อ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'เชื่อมต่อแล้ว',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // คำแนะนำ
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 14,
                  color: isLoading ? Colors.grey[400] : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  isLoading ? 'กำลังบันทึก...' : 'แตะเพื่อแก้ไขชื่อผู้ใช้',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLoading ? Colors.grey[400] : Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget สำหรับปรับระดับเสียง
class VolumeCard extends StatelessWidget {
  final double volume;
  final Function(double) onVolumeChanged;

  const VolumeCard({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ระดับเสียงของอุปกรณ์',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.volume_down, color: Colors.grey[600], size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    activeTrackColor: Colors.orange,
                    inactiveTrackColor: Colors.orange.withValues(alpha: 0.2),
                    thumbColor: Colors.orange,
                    overlayColor: Colors.orange.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: volume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              Icon(Icons.volume_up, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${volume.round()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget สำหรับตั้งค่าเวลา
class TimeSettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeDisplay;
  final VoidCallback onTap;

  const TimeSettingCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeDisplay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: iconColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeDisplay,
            style: TextStyle(
              fontSize: 14,
              color: iconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: iconColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Widget สำหรับปุ่มต่างๆ
class SettingsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SettingsButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: backgroundColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Widget สำหรับหน้าที่ยังไม่มีการเชื่อมต่ออุปกรณ์
class NoConnectionView extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onLogout;

  const NoConnectionView({
    super.key,
    required this.onConnect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ไอคอนแสดงสถานะ
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange[100]!,
                    Colors.orange[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Colors.orange[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ข้อความแจ้งเตือน
            Text(
              'ยังไม่พบการเชื่อมต่ออุปกรณ์',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'กรุณาเชื่อมต่ออุปกรณ์เพื่อใช้งานระบบ\nและเริ่มตั้งค่าการแจ้งเตือน',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // ปุ่มเชื่อมต่ออุปกรณ์
            SettingsButton(
              icon: Icons.qr_code_scanner,
              label: 'เชื่อมต่ออุปกรณ์',
              backgroundColor: Colors.blue[600]!,
              onPressed: onConnect,
            ),
            
            const SizedBox(height: 16),
            
            // ปุ่มออกจากระบบ
            SettingsButton(
              icon: Icons.logout,
              label: 'ออกจากระบบ',
              backgroundColor: Colors.grey[700]!,
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class สำหรับการแปลงเวลา
class TimeHelper {
  // แปลงจาก seconds เป็น hours, minutes, seconds
  static Map<String, int> parseSecondsToTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    
    return {
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  // แปลงเวลาเป็น String สำหรับแสดงผล - ✅ แก้ไข warning
  static String formatTimeDisplay(int hours, int minutes, int seconds) {
    List<String> parts = [];
    if (hours > 0) parts.add('$hours ชั่วโมง');
    if (minutes > 0) parts.add('$minutes นาที');
    if (seconds > 0) parts.add('$seconds วินาที');
    
    if (parts.isEmpty) return '0 วินาที';
    return parts.join(' ');
  }
}