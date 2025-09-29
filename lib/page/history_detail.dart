import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/history_api.dart';

class HistoryDetailPage extends StatefulWidget {
  final int reminderMedicalId;
  const HistoryDetailPage({super.key, required this.reminderMedicalId});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  bool isLoading = true;
  String errorMsg = '';
  Map<String, dynamic>? historyItem;
  List<dynamic> medications = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      setState(() { isLoading = true; errorMsg = ''; });

      final result = await ReminderHistoryApi.getHistoryDetail(widget.reminderMedicalId);

      // 🐛 Debug: แสดงข้อมูลที่ได้รับ
      debugPrint('🔍 [HISTORY_DETAIL] Raw API Response:');
      debugPrint('   Success: ${result['success']}');
      debugPrint('   Data keys: ${result['data']?.keys.toList()}');
      
      if (result['data'] != null) {
        final responseData = result['data'];
        debugPrint('   Response data keys: ${responseData.keys.toList()}');
        
        if (responseData['data'] != null) {
          final actualData = responseData['data'];
          debugPrint('   Actual data keys: ${actualData.keys.toList()}');
          debugPrint('   History detail: ${actualData['history_detail'] != null ? "YES" : "NO"}');
          debugPrint('   Medications: ${actualData['medications']}');
          debugPrint('   Medications count: ${actualData['medications']?.length ?? 0}');
        }
      }

      if (result['success'] && result['data'] != null) {
        final apiData = result['data'];
        
        // ✅ แก้ไข: ตรวจสอบโครงสร้างข้อมูลและแกะข้อมูลให้ถูกต้อง
        Map<String, dynamic>? historyDetail;
        List<dynamic> medicationsList = [];
        
        // ตรวจสอบโครงสร้างข้อมูล
        if (apiData['data'] != null) {
          // โครงสร้างแบบ nested
          final actualData = apiData['data'];
          historyDetail = actualData['history_detail'];
          medicationsList = actualData['medications'] ?? [];
        } else {
          // โครงสร้างแบบ flat
          historyDetail = apiData['history_detail'];
          medicationsList = apiData['medications'] ?? [];
        }
        
        // 🐛 Debug: แสดงข้อมูลที่แกะได้
        debugPrint('✅ [HISTORY_DETAIL] Parsed Data:');
        debugPrint('   History Detail: ${historyDetail != null ? "Found" : "Not Found"}');
        debugPrint('   Medications Count: ${medicationsList.length}');
        
        if (medicationsList.isNotEmpty) {
          debugPrint('   First Medication: ${medicationsList[0]}');
        }
        
        setState(() {
          historyItem = historyDetail;
          medications = medicationsList;
          isLoading = false;
        });
        
      } else {
        throw Exception(result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      debugPrint('❌ [HISTORY_DETAIL] Error: $e');
      setState(() { errorMsg = e.toString(); isLoading = false; });
    }
  }

  // สำหรับแสดงช่องวันที่ - แสดงวัน วันที่ เดือน ปี
  String _formatDateOnly(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'ไม่ระบุ';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final months = [
        '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      
      final weekdays = ['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'];
      final weekday = weekdays[dateTime.weekday % 7];
      
      return 'วัน$weekday ที่ ${dateTime.day} ${months[dateTime.month]} ${dateTime.year}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  // สำหรับแสดงช่องเวลาที่กำหนด และ เวลาที่รับประทาน - แสดงแค่เวลา
  String _formatTimeOnly(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'ไม่ระบุ';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.';
    } catch (e) {
      return dateTimeStr;
    }
  }
    String _getReceiveTimeLabel(String? status) {
    switch (status) {
      case 'taken':
        return 'เวลารับประทาน';  // ถ้ากินยาแล้ว
      default:
        return 'หมดเวลาการแจ้งเตือน';  // ถ้าไม่ได้กินยา
    }
  }


  String _getStatusText(String? status) {
    switch (status) {
      case 'taken':
        return 'กินแล้ว';
      default:
        return 'ไม่ได้กินตามเวลา';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'taken':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFFF44336);
    }
  }

  LinearGradient _getStatusGradient(String? status) {
    switch (status) {
      case 'taken':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }

  String _getPictureUrl(String? picture) {
    return historyItem?['picture_url'] ?? '';
  }

  String _getAmountDisplay(String? amount) {
    if (amount == null || amount.isEmpty) return 'ไม่ระบุจำนวน';
    return amount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'รายละเอียดประวัติ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
        ? _buildLoadingState()
        : errorMsg.isNotEmpty
          ? _buildErrorState()
          : historyItem == null
            ? _buildNoDataState()
            : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          SizedBox(height: 16),
          Text(
            'กำลังโหลดข้อมูล...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบข้อมูล',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Status Card
          _buildHeroStatusCard(),
          
          const SizedBox(height: 20),
          
          // Time Information Card
          _buildTimeInfoCard(),
          
          const SizedBox(height: 20),
          
          // Medications Card
          _buildMedicationsCard(),
          
          const SizedBox(height: 20),
          
          // Picture Card
          _buildPictureCard(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroStatusCard() {
    final status = historyItem!['status'];
    final timingName = historyItem!['timing_name'] ?? 'ไม่ระบุมื้อ';
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _getStatusGradient(status),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusText(status),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timingName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildTimeInfoCard() {
  final status = historyItem!['status'];  // ดึงสถานะมาใช้
  
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ข้อมูลเวลา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimeInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'วันที่',
            value: _formatDateOnly(historyItem!['time']),
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildTimeInfoRow(
            icon: Icons.schedule_rounded,
            label: 'เวลาที่กำหนด',
            value: _formatTimeOnly(historyItem!['time']),
            color: const Color(0xFF3B82F6),
          ),
          if (historyItem!['receive_time'] != null) ...[
            const SizedBox(height: 16),
            _buildTimeInfoRow(
              icon: Icons.medication_rounded,
              label: _getReceiveTimeLabel(status),  // ใช้ฟังก์ชันใหม่แทน
              value: _formatTimeOnly(historyItem!['receive_time']),
              color: const Color(0xFFEF4444),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildTimeInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'รายการยา',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (medications.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(
                      'ไม่มีข้อมูลรายการยา',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...medications.asMap().entries.map((entry) {
                final index = entry.key;
                final med = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: index < medications.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.05),
                        const Color(0xFF059669).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication_liquid_rounded,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['medication_name'] ?? 'ไม่ระบุชื่อยา',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'จำนวน: ${_getAmountDisplay(med['amount_taken'])}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureCard() {
    final hasPicture = historyItem!['picture'] != null && 
                     historyItem!['picture'].toString().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'รูปภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasPicture)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 180,
                  ),
                  child: Image.network(
                    _getPictureUrl(historyItem!['picture']),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 36,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.no_photography_rounded,
                      size: 36,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ไม่มีรูปภาพสำหรับการแจ้งเตือนนี้',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}