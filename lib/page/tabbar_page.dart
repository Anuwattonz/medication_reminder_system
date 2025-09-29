import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medication_reminder_system/page/reminder_page.dart';
import 'package:medication_reminder_system/page/settings_page.dart';
import 'package:medication_reminder_system/page/medication_page.dart';
import 'package:medication_reminder_system/page/history.dart';

class CustomTabBar extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> connections;

  const CustomTabBar({
    super.key,
    required this.userData,
    required this.connections,
  });

  @override
  CustomTabBarState createState() => CustomTabBarState();
}

class CustomTabBarState extends State<CustomTabBar> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  int _currentIndex = 0;
  
  // ระบบ double back to exit
  DateTime? _lastBackPressed;
  static const Duration _exitWarningDuration = Duration(seconds: 2);
  
  // ✅ Cache สำหรับเก็บหน้าต่างๆ
  final Map<int, Widget> _cachedPages = {};
  
  // ✅ Loading states ใหม่
  bool _isInitializing = true;
  int _currentLoadingPage = 0; // หน้าที่กำลังโหลด (0-3)
  String _currentLoadingPageName = '';

  static const List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
    BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'หน้ายา'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'ประวัติ'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
  ];

  // ✅ ชื่อหน้าสำหรับแสดงใน loading
  static const List<String> _pageNames = [
    'หน้าหลัก',
    'หน้ายา', 
    'ประวัติ',
    'ตั้งค่า'
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // ✅ โหลดทุกหน้าให้เสร็จก่อน ค่อยแสดง TabBar (เริ่มที่หน้าหลัก)
  Future<void> _initializeApp() async {
    debugPrint('🚀 Starting app initialization - preloading ALL pages...');
    
    try {
      // ✅ โหลดทุกหน้าให้เสร็จก่อน (รอให้จบทุกหน้า)
      await _preloadAllPagesCompletely();
      
      // ✅ เสร็จแล้วทุกหน้า ค่อยแสดง TabBar (เริ่มที่หน้าหลัก)
      if (mounted) {
        setState(() {
          _currentIndex = 0; // บังคับให้เริ่มที่หน้าหลัก
          _isInitializing = false;
        });
        debugPrint('✅ ALL PAGES LOADED! TabBar is now ready to use.');
      }
      
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  // ✅ โหลดทุกหน้าแบบเร็ว ไม่รอ
  Future<void> _preloadAllPagesCompletely() async {
    debugPrint('📚 Creating all pages quickly...');
    
    for (int i = 0; i < 4; i++) {
      if (!mounted) break;
      
      // ✅ อัพเดท loading state
      setState(() {
        _currentLoadingPage = i;
        _currentLoadingPageName = _pageNames[i];
      });
      
      debugPrint('📋 Creating page $i: ${_pageNames[i]}...');
      
      // ✅ สร้างหน้าอย่างเดียว
      await _loadAndWaitForPageComplete(i);
      
      debugPrint('✅ Page $i (${_pageNames[i]}) created!');
      
      // รอนิดเดียวเพื่อแสดง progress
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    debugPrint('🎉 ALL PAGES created! TabBar will show now.');
  }

  // ✅ เปลี่ยนกลยุทธ์: สร้างหน้าแต่ไม่รอ - ให้ TabBar แสดงเลย แล้วหน้าค่อยโหลดเอง
  Future<void> _loadAndWaitForPageComplete(int index) async {
    if (_cachedPages.containsKey(index)) {
      debugPrint('Page $index already exists in cache, skipping...');
      return;
    }

    final userId = _getUserId();
    
    switch (index) {
      case 0:
        debugPrint('🏠 Creating Reminder page...');
        _cachedPages[0] = const OptimizedMedicationReminderPage();
        break;
        
      case 1:
        debugPrint('💊 Creating Medication page...');
        _cachedPages[1] = const OptimizedMedicationPage();
        break;
        
      case 2:
        debugPrint('📜 Creating History page...');
        _cachedPages[2] = const OptimizedNotificationPage();
        break;
        
      case 3:
        debugPrint('⚙️ Creating Settings page...');
        _cachedPages[3] = OptimizedSettingsPage(userId: userId);
        break;
    }
    
    // ✅ แค่สร้าง Widget เท่านั้น ไม่ต้องรอ
    if (mounted) {
      setState(() {});
    }
    
    debugPrint('✅ Page $index (${_pageNames[index]}) created and cached!');
  }

  String _getUserId() {
    if (widget.userData['user_id'] != null) {
      return widget.userData['user_id'].toString();
    } else if (widget.userData['id'] != null) {
      return widget.userData['id'].toString();
    }
    return '';
  }

  // ==================== Navigation Management ====================
  
  void _onTabTapped(int index) async {
    _lastBackPressed = null; // Reset back press timer
    
    // ✅ ทุกหน้าโหลดเสร็จแล้ว เปลี่ยนแท็บทันที ไม่ต้องรอ
    debugPrint('🎯 Switching to tab $index (${_pageNames[index]}) - INSTANT switch!');
    setState(() => _currentIndex = index);
  }

  void _handleBackButton() {
    debugPrint('🔙 Back pressed. Current index: $_currentIndex');
    
    // Return to home if not on home tab
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    
    // Double back to exit
    final now = DateTime.now();
    
    if (_lastBackPressed == null || 
        now.difference(_lastBackPressed!) > _exitWarningDuration) {
      _lastBackPressed = now;
      _showExitWarning();
      return;
    }
    
    SystemNavigator.pop();
  }

  void _showExitWarning() {
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
              child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'กดปุ่มย้อนกลับอีกครั้งเพื่อออกจากแอป',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: _exitWarningDuration,
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  // ==================== Public Methods ====================
  
  void refreshTabBar(Map<String, dynamic> newUserData, List<Map<String, dynamic>> newConnections) {
    setState(() {
      _cachedPages.clear(); // Clear cache
      _initializeApp(); // Rebuild with new data
    });
  }

  // ==================== Build Method ====================
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) _handleBackButton();
      },
      child: Scaffold(
        body: _isInitializing
            ? _buildLoadingScreen()
            : _buildContent(),
        // ✅ ซ่อน TabBar ตอนกำลังโหลด
        bottomNavigationBar: _isInitializing 
            ? null 
            : BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                selectedItemColor: Colors.teal,
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                elevation: 8,
                items: _navigationItems,
              ),
      ),
    );
  }

  // ✅ หน้า loading ใหม่ พร้อม progress indicator
  Widget _buildLoadingScreen() {
    double progress = (_currentLoadingPage + 1) / 4; // 0.25, 0.5, 0.75, 1.0
    
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.medical_services_outlined,
              size: 120,
              color: Colors.teal,
            ),
            
            const SizedBox(height: 40),
            
            // ชื่อแอป
            const Text(
              'ระบบเตือนการรับประทานยา',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 60),
            
            // ✅ Progress Ring ใหม่
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.teal[50],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[50]!),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
                // Percentage text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_currentLoadingPage + 1)}/4',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // ✅ Status Message แสดงหน้าที่กำลังสร้าง
            Text(
              'กำลังเตรียม$_currentLoadingPageName...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // ✅ Sub message 
            Text(
              'จะแสดงทันทีเมื่อพร้อม',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ แสดงเนื้อหาหลัก - ง่ายๆ
  Widget _buildContent() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _cachedPages[0] ?? Container(),
        _cachedPages[1] ?? Container(), 
        _cachedPages[2] ?? Container(),
        _cachedPages[3] ?? Container(),
      ],
    );
  }
}

// ==================== Wrapper Classes for Optimized Pages ====================

// ✅ Wrapper แบบง่ายๆ
class OptimizedMedicationReminderPage extends StatefulWidget {
  const OptimizedMedicationReminderPage({super.key});

  @override
  State<OptimizedMedicationReminderPage> createState() => _OptimizedMedicationReminderPageState();
}

class _OptimizedMedicationReminderPageState extends State<OptimizedMedicationReminderPage> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const MedicationReminderPage();
  }
}

class OptimizedMedicationPage extends StatefulWidget {
  const OptimizedMedicationPage({super.key});

  @override
  State<OptimizedMedicationPage> createState() => _OptimizedMedicationPageState();
}

class _OptimizedMedicationPageState extends State<OptimizedMedicationPage> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const MedicationPage();
  }
}

class OptimizedNotificationPage extends StatefulWidget {
  const OptimizedNotificationPage({super.key});

  @override
  State<OptimizedNotificationPage> createState() => _OptimizedNotificationPageState();
}

class _OptimizedNotificationPageState extends State<OptimizedNotificationPage> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const NotificationPage();
  }
}

// ✅ Wrapper สำหรับ SettingsPage - แบบธรรมดา
class OptimizedSettingsPage extends StatefulWidget {
  final String userId;
  
  const OptimizedSettingsPage({super.key, required this.userId});

  @override
  State<OptimizedSettingsPage> createState() => _OptimizedSettingsPageState();
}

class _OptimizedSettingsPageState extends State<OptimizedSettingsPage> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SettingsPage();
  }
}