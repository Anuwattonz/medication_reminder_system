import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medication_reminder_system/api/medication_detail_api.dart';
import 'package:medication_reminder_system/widget/medication/edit_medication_timings_dialog.dart';
import 'package:medication_reminder_system/widget/medication/edit_medication.dart';
import 'package:medication_reminder_system/widget/medication/detail/detail_widget.dart';
import 'package:medication_reminder_system/jwt/auth.dart';

class MedicationDetailPage extends StatefulWidget {
  final String medicationId;
  final VoidCallback? onDataChanged;

  const MedicationDetailPage({
    super.key,
    required this.medicationId,
    this.onDataChanged,
  });

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  Map<String, dynamic>? medicationDetail;
  bool _isLoading = false;
  bool _hasDataChanged = false;
  String? _currentImageUrl;

  // เก็บ hash ข้อมูลเพื่อเช็คการเปลี่ยนแปลง
  String? _dataHash;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearUnusedImageCache();
    });

    _loadMedicationDetail();
  }

  @override
  void dispose() {
    if (_currentImageUrl != null) {
      _clearImageCache(_currentImageUrl!);
    }

    if (_hasDataChanged && widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
    super.dispose();
  }

  // สร้าง hash จากข้อมูลเพื่อเช็คการเปลี่ยนแปลง
  String _generateDataHash(Map<String, dynamic> data) {
    final medication = data['medication'];
    final timings = data['medication_timings'] ?? [];

    final hashData = {
      'name': medication['medication_name'],
      'nickname': medication['medication_nickname'],
      'description': medication['description'],
      'dosage_form': medication['dosage_form'],
      'unit_type': medication['unit_type'],
      'picture_url': medication['picture_url'],
      'timings_count': timings.length,
      'timings_data': timings.map((t) => '${t['time']}_${t['dosage']}_${t['status']}').join('|'),
    };

    return hashData.toString();
  }

  // โหลดข้อมูลใหม่จาก API และจัดการ image cache อย่างชาญฉลาด
  Future<void> _loadMedicationDetail() async {
    setState(() => _isLoading = true);

    try {
      final result = await MedicationDetailApi.getMedicationDetail(widget.medicationId);

      if (result['success'] == true) {
        final newData = result['data'];
        final newImageUrl = newData['medication']['picture_url'];
        final newDataHash = _generateDataHash(newData);

        bool dataReallyChanged = _dataHash != null && _dataHash != newDataHash;
        
        // ตรวจสอบว่ารูปภาพเปลี่ยนแปลงจริงหรือไม่
        bool imageActuallyChanged = _hasImageActuallyChanged(_currentImageUrl, newImageUrl);

        // ถ้ารูปภาพเปลี่ยนแปลงจริงๆ เท่านั้นที่จะ clear cache
        if (imageActuallyChanged) {
          debugPrint('🖼️ Image actually changed, clearing cache');
          if (_currentImageUrl != null) {
            await _clearImageCache(_currentImageUrl!);
          }
          if (newImageUrl != null) {
            await _clearImageCache(newImageUrl);
          }
        } else {
          debugPrint('🖼️ Image not changed, keeping cache');
        }

        setState(() {
          medicationDetail = newData;
          _currentImageUrl = newImageUrl;
          _dataHash = newDataHash;
          if (dataReallyChanged) {
            _hasDataChanged = true;
          }
        });

        // Force rebuild เฉพาะเมื่อรูปเปลี่ยนจริง
        if (mounted && imageActuallyChanged) {
          setState(() {});
        }
      } else {
        _handleApiError(result);
      }
    } catch (e) {
      _handleException(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ฟังก์ชันใหม่: ตรวจสอบว่ารูปภาพเปลี่ยนแปลงจริงหรือไม่
  bool _hasImageActuallyChanged(String? oldUrl, String? newUrl) {
    // ถ้าทั้งคู่เป็น null = ไม่เปลี่ยน
    if (oldUrl == null && newUrl == null) return false;
    
    // ถ้าอันใดอันหนึ่งเป็น null = เปลี่ยน
    if (oldUrl == null || newUrl == null) return true;
    
    // เอาเฉพาะ base URL (ไม่รวม timestamp)
    final oldBaseUrl = oldUrl.split('?')[0];
    final newBaseUrl = newUrl.split('?')[0];
    
    // ถ้า base URL ต่างกัน = รูปเปลี่ยนจริง
    final actuallyChanged = oldBaseUrl != newBaseUrl;
    
    debugPrint('🔍 Image change check:');
    debugPrint('  Old: $oldBaseUrl');
    debugPrint('  New: $newBaseUrl');
    debugPrint('  Changed: $actuallyChanged');
    
    return actuallyChanged;
  }

  void _editMedicationInfo() {
    if (medicationDetail?['medication'] == null) return;

    final medication = medicationDetail!['medication'];

    showDialog(
      context: context,
      builder: (context) {
        return EditMedicationInfoDialog(
          medicationId: widget.medicationId,
          currentData: {
            'medication_name': medication['medication_name'] ?? '',
            'medication_nickname': medication['medication_nickname'] ?? '',
            'description': medication['description'] ?? '',
            'picture_url': medication['picture_url'],
            'dosage_form': medication['dosage_form'] ?? '',
            'unit_type': medication['unit_type'] ?? '',
            'dosage_form_id': medication['dosage_form_id'],
            'unit_type_id': medication['unit_type_id'],
          },
          onSave: _handleMedicationInfoUpdate,
        );
      },
    );
  }

  // ✅ แก้ไข: รับข้อมูลว่ารูปเปลี่ยนหรือไม่จาก dialog - ไม่เรียก onDataChanged
  Future<void> _handleMedicationInfoUpdate(Map<String, dynamic> updatedData, bool dataChanged, {bool imageChanged = false}) async {
    if (!dataChanged) return;

    // ถ้ารูปไม่เปลี่ยน ให้อัพเดตข้อมูลโดยไม่โหลดใหม่
    if (!imageChanged) {
      debugPrint('📝 Data changed but image not changed, updating locally');
      
      setState(() {
        // อัพเดตข้อมูลโดยตรงไม่ต้องโหลดจาก API
        medicationDetail!['medication'] = {
          ...medicationDetail!['medication'],
          ...updatedData,
        };
        _hasDataChanged = true;
        _dataHash = _generateDataHash(medicationDetail!);
      });
      
      _showSnackBar('อัปเดตข้อมูลยาสำเร็จ');
    } else {
      debugPrint('🖼️ Image changed, reloading from API');
      // ถ้ารูปเปลี่ยน ให้โหลดข้อมูลใหม่จาก API
      await _loadMedicationDetail();
      _showSnackBar('อัปเดตข้อมูลยาสำเร็จ');
    }
    
    // ✅ ลบการเรียก widget.onDataChanged?.call(); ออก
    // เพราะการแก้ไขข้อมูลยาไม่ส่งผลต่อ reminder
  }

  // ✅ แก้ไข: การแก้ไข timing ก็ไม่ต้องเรียก onDataChanged เช่นกัน  
  void _editMedicationTimings() {
    if (medicationDetail == null) return;
    
    showDialog(
      context: context,
      builder: (context) => EditMedicationTimingsDialog(
        medicationId: widget.medicationId,
        currentTimings: List<Map<String, dynamic>>.from(
          (medicationDetail!['medication_timings'] ?? [])
              .map((e) => Map<String, dynamic>.from(e)),
        ),
        timingUsage: medicationDetail!['timing_usage'], // เพิ่มข้อมูลการใช้งาน
        onSave: (updatedTimings) async {
          final oldHash = _dataHash;

          setState(() {
            medicationDetail!['medication_timings'] = updatedTimings;
            _dataHash = _generateDataHash(medicationDetail!);
          });

          if (oldHash != _dataHash) {
            setState(() => _hasDataChanged = true);
          }

          _showSnackBar('อัปเดตเวลารับประทานยาสำเร็จ');

          // ✅ ลบการเรียก widget.onDataChanged?.call(); ออก
          // เพราะการแก้ไข timing ไม่ส่งผลต่อ reminder
        },
      ),
    );
  }

  void _handleApiError(Map<String, dynamic> result) {
    final message = result['message'] ?? 'เกิดข้อผิดพลาด';
    _showSnackBar(message, isError: true);

    if (result['error'] == 'auth_required' || result['error'] == 'auth_expired') {
      _handleAuthError();
    }
  }

  void _handleException(dynamic e) {
    String errorMessage = 'เกิดข้อผิดพลาด';
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('ใช้เวลานานเกินไป')) {
      errorMessage = 'การเชื่อมต่อใช้เวลานานเกินไป';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      errorMessage = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
    }

    _showSnackBar(errorMessage, isError: true);
  }

  Future<void> _handleAuthError() async {
    if (mounted) {
      await Auth.logout(context);
    }
  }

  // ปรับปรุง _clearImageCache method เพื่อไม่ให้ error 404
  Future<void> _clearImageCache(String imageUrl) async {
    try {
      // Clear cached network image
      await CachedNetworkImage.evictFromCache(imageUrl);
      
      // Clear image ที่มี timestamp ด้วย (ถ้ามี)
      final baseUrl = imageUrl.split('?')[0];
      await CachedNetworkImage.evictFromCache(baseUrl);
      
      debugPrint('🗑️ Cleared image cache for: $imageUrl');
    } catch (e) {
      // แสดง log เฉพาะเมื่อไม่ใช่ 404 error ของรูปเก่า
      if (!e.toString().contains('404') && !e.toString().contains('Invalid statusCode: 404')) {
        debugPrint('❌ Error clearing image cache: $e');
      } else {
        debugPrint('ℹ️ Old image file already removed (expected): $imageUrl');
      }
    }
  }

  void _clearUnusedImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
    } catch (_) {}
  }

  // ==================== SnackBar เหมือน medication_page ====================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 2),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('รายละเอียดยา'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (medicationDetail == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('รายละเอียดยา'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('ไม่พบข้อมูลยา')),
      );
    }

    final medication = Map<String, dynamic>.from(medicationDetail!['medication']);
    final timingsDynamic = medicationDetail!['medication_timings'] ?? [];
    final List<Map<String, dynamic>> timings = timingsDynamic
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(medication['medication_name'] ?? 'รายละเอียดยา'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: MedicationDetailWidget.buildGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // การ์ดข้อมูลยา
              MedicationDetailWidget.buildMedicationInfoCard(
                medication: medication,
                medicationId: widget.medicationId,
                onEditPressed: _editMedicationInfo,
              ),
              const SizedBox(height: 24),
              
              // การ์ดเวลารับประทานยา
              MedicationDetailWidget.buildMedicationTimingsCard(
                timings: timings,
                onEditPressed: _editMedicationTimings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}