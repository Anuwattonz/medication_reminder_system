import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MedicationDetailWidget {
  
  // ✅ Widget สำหรับแสดงรูปภาพยา
  static Widget buildMedicationImage({
    required Map<String, dynamic> medication,
    required String medicationId,
  }) {
    final imageUrl = medication['picture_url'];

    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return _buildNoImagePlaceholder();
    }

    final cleanUrl = imageUrl.toString().trim();
    if (cleanUrl.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      key: ValueKey('detail_page_med_${medicationId}_${cleanUrl.split('?')[0].hashCode}'),
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildImageLoadingState(),
      errorWidget: (context, url, error) {
        return _buildNoImagePlaceholder();
      },
      httpHeaders: {
        'Cache-Control': 'max-age=86400',
      },
    );
  }

  // ✅ Widget สำหรับ Placeholder รูปภาพ (พื้นหลังขาวธรรมดา)
  static Widget _buildNoImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // พื้นหลังขาวธรรมดา
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_rounded,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่มีรูปภาพ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับ Loading State รูปภาพ (พื้นหลังขาวธรรมดา)
  static Widget _buildImageLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // พื้นหลังขาวธรรมดา
      ),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Colors.grey[400],
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // ✅ Widget สำหรับแสดงข้อมูลยาในรูปแบบการ์ด
  static Widget buildMedicationInfoCard({
    required Map<String, dynamic> medication,
    required String medicationId,
    required VoidCallback onEditPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปภาพยา
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey[300]!, // กรอบสีเทาบางๆ
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 240,
                        child: buildMedicationImage(
                          medication: medication,
                          medicationId: medicationId,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // ชื่อยา
                _buildMedicationNameSection(medication),
                
                // ชื่อเล่น
                if (_getDisplayValue(medication['medication_nickname']) != '-') ...[
                  const SizedBox(height: 16),
                  _buildNicknameSection(medication),
                ],
                
                const SizedBox(height: 16),
                
                // รูปแบบยาและหน่วย
                _buildDosageFormSection(medication),
                
                // รายละเอียด
                if (_getDisplayValue(medication['description']) != '-') ...[
                  const SizedBox(height: 16),
                  _buildDescriptionSection(medication),
                ],
              ],
            ),
          ),
          
          // ปุ่มแก้ไขในมุมขวาบน
          Positioned(
            top: 20,
            right: 20,
            child: _buildEditButton(onEditPressed),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับส่วนชื่อยา (สีเขียว)
  static Widget _buildMedicationNameSection(Map<String, dynamic> medication) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3), // เงาสีเขียว
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ชื่อยา',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplayValue(medication['medication_name']),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับส่วนชื่อเล่น (สีเขียวอ่อน)
  static Widget _buildNicknameSection(Map<String, dynamic> medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.1), // สีเขียวอ่อน
            const Color(0xFF2E7D32).withValues(alpha: 0.05), // สีเขียวอ่อนมาก
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3), // เส้นขอบสีเขียวอ่อน
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), // สีเขียว
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.label_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ชื่อเล่น',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2E7D32), // สีเขียวเข้ม
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDisplayValue(medication['medication_nickname']),
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2E7D32), // สีเขียวเข้ม
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับส่วนรูปแบบยา (สีฟ้าเขียว)
  static Widget _buildDosageFormSection(Map<String, dynamic> medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal[100]!.withValues(alpha: 0.7), // สีฟ้าเขียวอ่อน
            Colors.teal[50]!.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal[600], // สีฟ้าเขียว
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication_liquid_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รูปแบบยา',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getDisplayValue(medication['dosage_form'])} • ${_getDisplayValue(medication['unit_type'])}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับส่วนรายละเอียด
  static Widget _buildDescriptionSection(Map<String, dynamic> medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[100]!.withValues(alpha: 0.8),
            Colors.grey[50]!.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รายละเอียด',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplayValue(medication['description']),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับปุ่มแก้ไข (สีเขียว)
  static Widget _buildEditButton(VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4), // เงาสีเขียว
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'แก้ไข',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Widget สำหรับการ์ดเวลารับประทานยา
  static Widget buildMedicationTimingsCard({
    required List<Map<String, dynamic>> timings,
    required VoidCallback onEditPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimingHeader(onEditPressed),
            const SizedBox(height: 24),
            timings.isEmpty ? _buildEmptyTimings() : _buildTimingList(timings),
          ],
        ),
      ),
    );
  }

  // ✅ Widget สำหรับ Header ของส่วนเวลา (สีส้มเขียว)
  static Widget _buildTimingHeader(VoidCallback onEditPressed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[500]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เวลารับประทานยา',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'ตารางเวลาการกินยา',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEditPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.orange[600],
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับแสดงเมื่อไม่มีเวลา
  static Widget _buildEmptyTimings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange[50]!.withValues(alpha: 0.8),
            Colors.orange[100]!.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.access_time_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ยังไม่ได้ตั้งเวลา',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'กดปุ่มแก้ไขเพื่อตั้งเวลารับประทานยา',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับแสดงรายการเวลา (สีเขียวฟ้า)
 static Widget _buildTimingList(List<Map<String, dynamic>> timings) {
    return Column(
      children: timings.map<Widget>((timing) {
        final timeDisplay = timing['timing_name'] ?? timing['timing'] ?? '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.teal[200]!, // สีเขียวฟ้า
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.1), // เงาสีเขียวฟ้า
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[500]!, Colors.teal[700]!], // สีเขียวฟ้า
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  timeDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ✅ Helper function สำหรับแสดงค่า
  static String _getDisplayValue(String? value) {
    if (value == null || value.isEmpty || value == 'null' || value == '-') {
      return '-';
    }
    return value;
  }

  // ✅ Widget สำหรับพื้นหลัง Gradient (สีเขียวอ่อน)
  static Widget buildGradientBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE8F5E8), // สีเขียวอ่อนเป็น background
          ],
        ),
      ),
      child: child,
    );
  }
}