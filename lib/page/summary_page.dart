// ไฟล์: lib/page/summary_page.dart
import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/summary_api.dart';
import 'package:medication_reminder_system/widget/history/summary_widget.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool isLoading = true;
  String errorMsg = '';
  
  // Summary data
  Map<String, dynamic>? summaryData;
  List<dynamic> timingBreakdown = [];
  List<dynamic> weeklyTrend = [];
  List<dynamic> topMedications = [];
  
  String selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      setState(() { 
        isLoading = true; 
        errorMsg = ''; 
      });

      debugPrint('🌐 [SUMMARY_PAGE] Loading summary data...');
      
      final apiResponse = await SummaryApi.getSummary(period: selectedPeriod);

      if (apiResponse['success'] == true && apiResponse['data'] != null) {
        final responseData = apiResponse['data'];
        
        if (responseData['data'] != null) {
          final actualData = responseData['data'];
          
          setState(() {
            summaryData = actualData['summary'];
            timingBreakdown = actualData['timing_breakdown'] ?? [];
            weeklyTrend = actualData['weekly_trend'] ?? [];
            topMedications = actualData['top_medications'] ?? [];
            isLoading = false;
          });
          
        } else {
          throw Exception('ไม่พบข้อมูล data ใน response');
        }
      } else {
        throw Exception(apiResponse['message'] ?? 'เกิดข้อผิดพลาดจาก API');
      }
    } catch (e) {
      debugPrint('💥 [SUMMARY_PAGE] Error: $e');
      setState(() { 
        errorMsg = 'เกิดข้อผิดพลาด: $e'; 
        isLoading = false;
      });
    }
  }

  void _changePeriod(String newPeriod) {
    if (newPeriod != selectedPeriod) {
      setState(() {
        selectedPeriod = newPeriod;
      });
      _fetchSummary();
    }
  }

  // ✅ เพิ่ม Helper method สำหรับแปลงชื่อ period
  String _getPeriodDisplayName() {
    switch (selectedPeriod) {
      case 'week':
        return '7 วัน';
      case 'month':
        return '30 วัน';
      case 'all':
      default:
        return 'ทั้งหมด';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[400]!,
              Colors.purple[700]!,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'สรุปการกินยา',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple[400]!,
                  Colors.purple[700]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMsg.isNotEmpty) {
      return _buildErrorState();
    }

    if (summaryData == null) {
      return _buildNoDataState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        
        // Period Selector
        PeriodSelector(
          selectedPeriod: selectedPeriod,
          onPeriodChanged: _changePeriod,
        ),
        
        // Main Summary Card
        MainSummaryCard(summaryData: summaryData!),
        
        // Timing Breakdown
        if (timingBreakdown.isNotEmpty)
          TimingBreakdownCard(timingBreakdown: timingBreakdown),
        
        // Weekly Trend - ✅ ซ่อนเมื่อเลือก "ทั้งหมด"
        if (weeklyTrend.isNotEmpty && selectedPeriod != 'all')
          WeeklyTrendCard(
            weeklyTrend: weeklyTrend,
            periodName: _getPeriodDisplayName(), // ✅ ส่งชื่อ period ที่ถูกต้อง
          ),
        
        // Top Medications
        if (topMedications.isNotEmpty)
          TopMedicationsCard(topMedications: topMedications),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.purple[600]!],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'กำลังโหลดสรุปข้อมูล...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'กำลังวิเคราะห์ข้อมูลการกินยาของคุณ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            errorMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.purple[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _fetchSummary,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'ลองอีกครั้ง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
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
    );
  }

  Widget _buildNoDataState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[400]!, Colors.grey[600]!],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'ไม่มีข้อมูลสรุป',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'ยังไม่มีข้อมูลการกินยาในช่วงเวลาที่เลือก\nลองเปลี่ยนช่วงเวลาหรือเพิ่มข้อมูลการกินยา',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}