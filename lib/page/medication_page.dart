import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/medication_api.dart';
import 'package:medication_reminder_system/widget/medication/medication_create_page.dart';
import 'package:medication_reminder_system/widget/medication/medication_detail_page.dart';
import 'package:medication_reminder_system/widget/medication/medication_delete.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

// ✅ ตัวแปร global callback สำหรับแจ้ง reminder page
VoidCallback? _globalReminderRefreshCallback;

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  // ✅ Static methods สำหรับจัดการ callback
  static void setReminderRefreshCallback(VoidCallback callback) {
    _globalReminderRefreshCallback = callback;
    debugPrint('🔗 [MEDICATION] Reminder refresh callback set');
  }

  static void clearReminderRefreshCallback() {
    _globalReminderRefreshCallback = null;
    debugPrint('🔗 [MEDICATION] Reminder refresh callback cleared');
  }

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedications();
    });
  }

  // ==================== Core Methods ====================

  /// โหลดข้อมูลยาจาก API
  Future<void> _loadMedications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await MedicationApi.getMedications();
      
      if (mounted && response['success']) {
        await _processApiResponse(response['body']);
      } else if (mounted) {
        _setError('ไม่สามารถโหลดข้อมูลยาได้');
      }
    } catch (e) {
      if (mounted) {
        _setError('ไม่สามารถโหลดข้อมูลยาได้: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ประมวลผล API Response
  Future<void> _processApiResponse(String responseBody) async {
    if (!mounted) return;
    
    try {
      final data = jsonDecode(responseBody);
      
      if (data['status'] == 'success' && data['data'] != null) {
        final medicationsRaw = data['data'];
        List<Map<String, dynamic>> medicationsList = [];
        
        if (medicationsRaw is List) {
          medicationsList = medicationsRaw.cast<Map<String, dynamic>>();
        } else if (medicationsRaw is Map<String, dynamic>) {
          medicationsList = medicationsRaw.values.cast<Map<String, dynamic>>().toList();
        }
        
        setState(() {
          _medications = medicationsList;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'ไม่สามารถโหลดข้อมูลยาได้';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล: $e';
      });
    }
  }

  /// Error handling แบบไม่แสดงการแจ้งเตือน
  void _setError(String errorMessage) {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _error = errorMessage;
        });
      }
    });
  }

  // ==================== Action Methods ====================

  /// รีเฟรชข้อมูล
  Future<void> _refreshMedications() async {
    await _loadMedications();
  }

  /// สร้างยาใหม่
  void _createMedication() async {
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMedicationPage()),
    );

    if (result == true && mounted) {
      await _refreshMedications();
    }
  }

  /// แก้ไขข้อมูลยา
  void _editMedication(String medicationId) async {
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationDetailPage(
          medicationId: medicationId,
          onDataChanged: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _refreshMedications();
              }
            });
          },
        ),
      ),
    );
  }

  /// ลบยา
    Future<void> _deleteMedication(String medicationId) async {
      if (!mounted) return;

      try {
        await MedicationDelete.showDeleteDialog(
          context: context,
          medicationId: medicationId,
          onMedicationDeleted: ({required bool hadReminders}) {
            if (mounted) {
              _refreshMedications();

              if (hadReminders) {
                _notifyReminderPageToRefresh();
              }
            }
          },
        );
      } catch (e) {
        debugPrint('❌ Error deleting medication: $e');
      }
    }

  /// ฟังก์ชันแจ้ง reminder page ให้รีเฟรช
  void _notifyReminderPageToRefresh() {
    if (_globalReminderRefreshCallback != null) {
      debugPrint('🔄 [MEDICATION] Notifying reminder page to refresh after medication deletion...');
      try {
        _globalReminderRefreshCallback!();
      } catch (e) {
        debugPrint('❌ [MEDICATION] Error calling reminder refresh callback: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _medications.isNotEmpty ? _buildFloatingActionButton() : null,
    );
  }

  /// สร้าง AppBar สำหรับแอปการกินยา (สีเขียว)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'คลังยา',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50), // สีเขียวหลัก
              Color(0xFF2E7D32), // สีเขียวเข้ม
            ],
          ),
        ),
      ),
      // ✅ เอาปุ่มรีเฟรชออก
    );
  }
  
  /// สร้าง Body หลัก
  Widget _buildBody() {
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
      child: _isLoading && _medications.isEmpty
          ? _buildLoadingWidget()
          : _error != null && _medications.isEmpty
              ? _buildErrorWidget()
              : _medications.isEmpty
                  ? _buildEmptyWidget()
                  : _buildMedicationsList(),
    );
  }

  /// Loading Widget
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)), // สีเขียว
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'กำลังโหลดข้อมูลยา...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Error Widget
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshMedications,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'ลองอีกครั้ง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Widget
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50).withValues(alpha: 0.1), // สีเขียวอ่อน
                    const Color(0xFF2E7D32).withValues(alpha: 0.1), // สีเขียวอ่อน
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_information_outlined,
                size: 64,
                color: const Color(0xFF4CAF50), // สีเขียว
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ยังไม่มีข้อมูลยา',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'เริ่มต้นโดยการเพิ่มยาแรกของคุณ\nเพื่อจัดการการใช้ยาอย่างมีประสิทธิภาพ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _createMedication,
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  'เพิ่มยาใหม่',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// สร้างรายการยา
  Widget _buildMedicationsList() {
    return RefreshIndicator(
      onRefresh: _refreshMedications,
      color: const Color(0xFF4CAF50), // สีเขียว
      child: CustomScrollView(
        slivers: [
          // Header with medication count
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายการยาทั้งหมด',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${_medications.length} รายการ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Medication cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _medications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildMedicationCard(_medications[index]);
                },
                childCount: _medications.length + (_isLoading ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// สร้างการ์ดยาด้วยสีเขียว
  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final medicationId = medication['medication_id']?.toString() ?? '';
    final medicationName = medication['medication_name'] ?? 'ไม่มีชื่อ';
    final medicationNickname = medication['medication_nickname'] ?? '';
    final dosageForm = medication['dosage_form'] ?? '';
    final unitType = medication['unit_type'] ?? '';
    final description = medication['description'] ?? '';
    final pictureUrl = medication['picture_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _editMedication(medicationId),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // รูปภาพยาพร้อม gradient background สีเขียว
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: pictureUrl.isNotEmpty 
                        ? null 
                        : const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3), // เงาสีเขียว
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: pictureUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: pictureUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
                                ),
                              ),
                              child: const Icon(
                                Icons.medical_services_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
                                ),
                              ),
                              child: const Icon(
                                Icons.medical_services_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // ข้อมูลยา
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อยา
                      Text(
                        medicationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // ชื่อเล่น
                      if (medicationNickname.isNotEmpty && medicationNickname != '-')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1), // สีเขียวอ่อน
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              medicationNickname,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32), // สีเขียวเข้ม
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // รูปแบบยาและหน่วย
                      if (dosageForm.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.medication_liquid_rounded,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$dosageForm${unitType.isNotEmpty ? ' ($unitType)' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      
                      // คำอธิบาย
                      if (description.isNotEmpty && description != '-')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // ปุ่มลบ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[600],
                      size: 22,
                    ),
                    onPressed: () => _deleteMedication(medicationId),
                    tooltip: 'ลบยา',
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Floating Action Button สีเขียว
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // สีเขียว
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.4), // เงาสีเขียว
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _createMedication,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
        label: const Text(
          'เพิ่มยา',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}