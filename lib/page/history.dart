import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/history_api.dart';
import 'package:medication_reminder_system/page/history_detail.dart';
import 'package:medication_reminder_system/page/summary_page.dart'; // ✅ เพิ่มบรรทัดนี้

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  bool isLoading = true;
  String errorMsg = '';
  
  // ✅ ไม่ใช้ Cache - เก็บแค่ที่จำเป็น
  int _currentPage = 1;
  int _totalPages = 1;
  final List<dynamic> _allHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory(1);
  }

  // ✅ ไปหน้าที่ต้องการ
  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && !isLoading) {
      debugPrint('🎯 [Navigation] Going to page $page (total: $_totalPages)');
      _fetchHistory(page);
    } else {
      debugPrint('❌ [Navigation] Invalid page $page (total: $_totalPages, loading: $isLoading)');
    }
  }

  // ✅ ใช้ ReminderHistoryApi - ไม่ใช้ Cache
  Future<void> _fetchHistory(int page, {bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _allHistory.clear();
        page = 1;
      }

      debugPrint('🌐 [API Call] Loading page $page from server... (No Cache)');
      setState(() { isLoading = true; errorMsg = ''; });

      // ✅ ใช้ ReminderHistoryApi แทนการเรียก HTTP โดยตรง
      final apiResponse = await ReminderHistoryApi.getHistory(
        page: page,
        limit: 10,
      );

      // 🛠 Debug: แสดง Raw API Response
      debugPrint('📨 [API Response] Full Response:');
      debugPrint('   Success: ${apiResponse['success']}');
      debugPrint('   Status Code: ${apiResponse['statusCode']}');
      debugPrint('   Message: ${apiResponse['message']}');
      if (apiResponse['rawBody'] != null) {
        final bodyPreview = apiResponse['rawBody'].toString();
        debugPrint('   Raw Body Preview: ${bodyPreview.length > 200 ? '${bodyPreview.substring(0, 200)}...' : bodyPreview}');
      }

      // ✅ ตรวจสอบความสำเร็จ
      if (apiResponse['success'] == true && apiResponse['data'] != null) {
        final responseData = apiResponse['data'];
        
        // 🛠 Debug: แสดงโครงสร้างข้อมูล
        debugPrint('📋 [Data Structure] Response data keys: ${responseData.keys.toList()}');
        
        if (responseData['data'] != null) {
          final actualData = responseData['data'];
          debugPrint('📋 [Nested Data] Actual data keys: ${actualData.keys.toList()}');
          
          final pageData = actualData['history'] ?? [];
          final paginationInfo = actualData['pagination'];
          
          // 🛠 Debug: แสดงข้อมูล pagination
          debugPrint('📊 [Pagination Debug]');
          debugPrint('   Current Page: ${paginationInfo?['current_page']}');
          debugPrint('   Total Pages: ${paginationInfo?['total_pages']}');
          debugPrint('   Total Items: ${paginationInfo?['total_items']}');
          debugPrint('   Items Per Page: ${paginationInfo?['items_per_page']}');
          debugPrint('   Has Next: ${paginationInfo?['has_next']}');
          debugPrint('   Has Previous: ${paginationInfo?['has_prev']}');
          
          // 🛠 Debug: แสดงข้อมูลรายการ
          debugPrint('📋 [History Items] Count: ${pageData.length}');
          for (int i = 0; i < pageData.length && i < 3; i++) {
            final item = pageData[i];
            debugPrint('   Item ${i + 1}: ID=${item['reminder_medical_id']}, Status=${item['status']}, Timing=${item['timing_name']}');
          }
          if (pageData.length > 3) {
            debugPrint('   ... และอีก ${pageData.length - 3} รายการ');
          }
          
          // ✅ อ่านจำนวนหน้าจาก API
          _totalPages = paginationInfo?['total_pages'] ?? 1;
          
          debugPrint('✅ [Updated] totalPages=$_totalPages, currentPage=$page');
          
          // ✅ แสดงผลโดยตรง ไม่เก็บ cache
          _currentPage = page;
          _allHistory.clear();
          _allHistory.addAll(pageData);
          
          debugPrint('📋 [Display] Showing page $page with ${_allHistory.length} items');
          
          setState(() { isLoading = false; });
        } else {
          throw Exception('ไม่พบข้อมูล data ใน response');
        }
      } else {
        // 🛠 Debug: แสดง error จาก API
        debugPrint('❌ [API Error] Message: ${apiResponse['message']}');
        debugPrint('❌ [API Error] Status Code: ${apiResponse['statusCode']}');
        
        throw Exception(apiResponse['message'] ?? 'เกิดข้อผิดพลาดจาก API');
      }
    } catch (e) {
      debugPrint('💥 [Fetch Error] Exception: $e');
      setState(() { 
        errorMsg = 'เกิดข้อผิดพลาด: $e'; 
        isLoading = false;
      });
    }
  }

  Future<void> _refreshHistory() async {
    debugPrint('🔄 [Refresh] Starting refresh...');
    await _fetchHistory(1, isRefresh: true);
  }

  // ✅ helper methods
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'ไม่ระบุเวลา';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      
      if (itemDate == today) {
        return 'วันนี้ $timeStr น.';
      } else if (itemDate == yesterday) {
        return 'เมื่อวาน $timeStr น.';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} $timeStr น.';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'taken': return 'กินแล้ว';
      default: return 'ไม่ได้กินตามเวลา';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'taken': return Colors.green;
      default: return Colors.red;
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status) {
      case 'taken': return Colors.green[50]!;
      default: return Colors.red[50]!;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'taken': return Icons.check_circle;
      default: return Icons.cancel;
    }
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index) {
    final status = item['status']?.toString();
    final timingName = item['timing_name']?.toString() ?? 'ไม่ระบุมื้อ';
    final day = item['day']?.toString() ?? 'ไม่ระบุวัน';
    final time = _formatDateTime(item['time']?.toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final reminderMedicalId = item['reminder_medical_id'];
            if (reminderMedicalId != null) {
              debugPrint('🔍 [Navigation] Opening detail for ID: $reminderMedicalId');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryDetailPage(reminderMedicalId: reminderMedicalId),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(status),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timingName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '$day • $time',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีประวัติการแจ้งเตือน',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ประวัติการกินยาจะแสดงที่นี่',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshHistory,
            icon: Icon(Icons.refresh, size: 18, color: Colors.purple[700]),
            label: Text(
              'ลองมาอีกครั้ง',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.purple[700],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[50],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(errorMsg, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchHistory(1, isRefresh: true),
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }

  // ✅ Pagination แบบไม่ใช้ Cache - เอาข้อความฟ้าๆ ออก
  Widget _buildPaginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 1 ? Colors.purple[600] : Colors.grey[400],
          ),
          
          // Smart Page Numbers Display
          ..._buildSmartPageNumbers(),
          
          // Next
          IconButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < _totalPages ? Colors.purple[600] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  // เพิ่ม method ใหม่สำหรับแสดงหน้าแบบ Smart
  List<Widget> _buildSmartPageNumbers() {
    List<Widget> widgets = [];
    
    if (_totalPages <= 7) {
      // ถ้ามีหน้าน้อย แสดงทั้งหมด
      for (int i = 1; i <= _totalPages; i++) {
        widgets.add(_buildPageButton(i));
      }
    } else {
      // ถ้ามีหน้าเยอะ ใช้ smart display
      if (_currentPage <= 4) {
        // แสดง 1,2,3,4,5 ... last
        for (int i = 1; i <= 5; i++) {
          widgets.add(_buildPageButton(i));
        }
        widgets.add(_buildDots());
        widgets.add(_buildPageButton(_totalPages));
      } else if (_currentPage >= _totalPages - 3) {
        // แสดง 1 ... last-4,last-3,last-2,last-1,last
        widgets.add(_buildPageButton(1));
        widgets.add(_buildDots());
        for (int i = _totalPages - 4; i <= _totalPages; i++) {
          widgets.add(_buildPageButton(i));
        }
      } else {
        // แสดง 1 ... current-1,current,current+1 ... last
        widgets.add(_buildPageButton(1));
        widgets.add(_buildDots());
        for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
          widgets.add(_buildPageButton(i));
        }
        widgets.add(_buildDots());
        widgets.add(_buildPageButton(_totalPages));
      }
    }
    
    return widgets;
  }

  // สร้างปุ่มหน้า - ลดขนาดเพื่อให้พอดีหน้าจอ
  Widget _buildPageButton(int pageNumber) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), // ลดระยะห่าง
      child: Material(
        color: pageNumber == _currentPage ? Colors.purple[600] : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _goToPage(pageNumber),
          child: Container(
            width: 32, // ลดขนาดจาก 36 เป็น 32
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: pageNumber == _currentPage ? Colors.purple[600]! : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                pageNumber.toString(),
                style: TextStyle(
                  color: pageNumber == _currentPage ? Colors.white : Colors.grey[700],
                  fontWeight: pageNumber == _currentPage ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13, // ลดขนาดตัวอักษร
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // สร้าง dots (...) - ปรับขนาดให้เข้ากัน
  Widget _buildDots() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 32, // ขนาดเท่ากับปุ่ม
      height: 32,
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(), // ✅ ใช้ method แยก
      body: Column(
        children: [
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.purple))
              : errorMsg.isNotEmpty
                ? _buildErrorState()
                : _allHistory.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _refreshHistory,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: _buildEmptyState(),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _allHistory.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryCard(_allHistory[index], index);
                        },
                      ),
                    ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  // ✅ แยก AppBar ออกมาเป็น method แยก พร้อมปุ่ม Summary
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'ประวัติการแจ้งเตือน',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[600]!, Colors.purple[800]!],
          ),
        ),
      ),
      // ✅ เพิ่มปุ่มสรุป
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SummaryPage(),
                ),
              );
            },
            tooltip: 'ดูสรุปการกินยา',
          ),
        ),
      ],
    );
  }
}