import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_details.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_main/reminder_widgets.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_main/reminder_button.dart';
import 'package:medication_reminder_system/jwt/auth.dart';
import 'package:medication_reminder_system/notification/notification_service.dart';
import 'package:medication_reminder_system/page/medication_page.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_main/reminder_models.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_main/reminder_service.dart';

class MedicationReminderPage extends StatefulWidget {
  const MedicationReminderPage({super.key});

  @override
  State<MedicationReminderPage> createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  bool isLoading = true;
  bool isRefreshing = false;
  String errorMsg = '';
  List<AppModel> apps = [];

  String? userId;
  String? connectId;

  Set<int> _selectedSlots = <int>{};
  bool _isFirstLoad = true;

  final Map<int, bool> _toggleButtonEnabled = {};
  final Map<int, Timer?> _toggleTimers = {};

  @override
  void initState() {
    super.initState();
    
    // เริ่มต้น toggle buttons
    for (int i = 0; i < 7; i++) {
      _toggleButtonEnabled[i] = true;
    }

    // ลงทะเบียน callback สำหรับรีเฟรชจาก medication page
    MedicationPage.setReminderRefreshCallback(_refreshReminderData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDataAndFetch();
    });

    // ขอ permission notification แบบเงียบๆ
    _requestNotificationPermission();
  }

  @override
  void dispose() {
    MedicationPage.clearReminderRefreshCallback();
    
    for (var timer in _toggleTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  // ==================== Helper Methods สำหรับ SnackBar (เหมือน medication_page) ====================

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
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
  }

  // ==================== Core Methods ====================

  Future<void> _refreshReminderData() async {
    if (!mounted) return;
    
    try {
      setState(() => isRefreshing = true);
      await _fetchMedicationData(isBackgroundRefresh: true);
      
      if (mounted) {
        _showSnackBar('อัปเดตข้อมูลการแจ้งเตือนแล้ว');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('ไม่สามารถอัปเดตข้อมูลได้', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationService.requestNotificationPermission();
    } catch (e) {
      // เงียบๆ ไม่แสดง error
    }
  }

  Future<void> _loadUserDataAndFetch() async {
    userId = await Auth.currentUserId();
    connectId = await JWTManager.getConnectionId();

    if (userId != null && connectId != null) {
      await _fetchMedicationData();
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = 'ไม่พบข้อมูล user_id หรือ connect_id';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      if (mounted) {
        setState(() {
          errorMsg = '';
          isRefreshing = true;
        });
      }
      await _fetchMedicationData(isBackgroundRefresh: true);
    } catch (e) {
      if (mounted) {
        setState(() => errorMsg = 'ไม่สามารถรีเฟรชข้อมูลได้: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  Future<void> _fetchMedicationData({bool isBackgroundRefresh = false}) async {
    if (userId == null || connectId == null) return;

    final result = await ReminderService.fetchMedicationData(
      userId: userId!,
      connectId: connectId!,
    );

    if (mounted) {
      if (result.success && result.data != null) {
        setState(() {
          apps = List.unmodifiable(result.data!);
          
          if (_isFirstLoad) {
            _selectedSlots = ReminderService.createSmartFilter(apps);
            _isFirstLoad = false;
          }
          
          if (!isBackgroundRefresh) {
            isLoading = false;
          }
          errorMsg = '';
        });

        // อัปเดต notification แบบเงียบๆ
        ReminderService.updateNotificationsInBackground(result.data!);
      } else {
        setState(() {
          if (!isBackgroundRefresh) isLoading = false;
          errorMsg = result.error ?? 'เกิดข้อผิดพลาด';
        });
      }
    }
  }

  // ==================== Slot Management ====================

  Future<void> _toggleSlotStatus(int slot) async {
    final slotData = ReminderService.findSlotData(apps, slot);
    if (slotData == null) return;

    if (_toggleButtonEnabled[slot] != true) return;

    // ตรวจสอบเงื่อนไขการเปิดใช้งาน
    if (slotData.status == '0') {
      if (!ReminderService.canActivateSlot(slotData)) {
        if (mounted) {
          _showSnackBar('ไม่สามารถเปิดใช้งานได้: ต้องมีข้อมูลยาและกำหนดวันใช้งานก่อน', isError: true);
        }
        return;
      }
    }

    // ปิด toggle button ชั่วคราว
    setState(() {
      _toggleButtonEnabled[slot] = false;
    });

    _toggleTimers[slot]?.cancel();
    _toggleTimers[slot] = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _toggleButtonEnabled[slot] = true;
        });
      }
    });

    final newStatus = slotData.status == '1' ? '0' : '1';

    // อัปเดต UI ก่อน
    setState(() {
      final index = apps.indexWhere((app) => app.pillSlot == slot);
      if (index != -1) {
        apps = List<AppModel>.from(apps);
        apps[index] = ReminderService.createUpdatedApp(slotData, newStatus);
      }
    });

    await _updateSlotStatus(slot, newStatus);
  }

  Future<void> _updateSlotStatus(int pillSlot, String newStatus) async {
    if (userId == null || connectId == null) return;

    final result = await ReminderService.updateSlotStatus(
      userId: userId!,
      connectId: connectId!,
      pillSlot: pillSlot,
      status: newStatus,
    );

    if (mounted) {
      if (result.success) {
        _showSnackBar(result.message);

        // อัปเดต notification
        final updatedApp = ReminderService.findSlotData(apps, pillSlot);
        if (updatedApp != null) {
          ReminderService.updateSingleSlotNotification(updatedApp);
        }
      } else {
        await _revertStatusChange(pillSlot, newStatus);
        _showSnackBar(result.message, isError: true);
      }
    }
  }

  Future<void> _revertStatusChange(int pillSlot, String failedStatus) async {
    final slotData = ReminderService.findSlotData(apps, pillSlot);
    if (slotData == null) return;

    final revertedStatus = failedStatus == '1' ? '0' : '1';

    setState(() {
      final index = apps.indexWhere((app) => app.pillSlot == pillSlot);
      if (index != -1) {
        apps = List<AppModel>.from(apps);
        apps[index] = ReminderService.createUpdatedApp(slotData, revertedStatus);
      }
    });
  }

  // ==================== UI Building ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'แจ้งเตือนยา',
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF4CAF50),
        child: _buildContent(),
      ),
      floatingActionButton: ReminderFilterButton(
        selectedSlots: _selectedSlots,
        onSlotsChanged: (newSelectedSlots) {
          setState(() {
            _selectedSlots = newSelectedSlots;
          });
        },
        apps: apps,
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && apps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            SizedBox(height: 16),
            Text('กำลังโหลดข้อมูล...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    if (errorMsg.isNotEmpty && apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadUserDataAndFetch,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (apps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('ยังไม่มีข้อมูลการแจ้งเตือน', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    final filteredApps = ReminderService.filterAppsBySlots(apps, _selectedSlots);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        
        return AnimatedOpacity(
          opacity: isRefreshing ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: MedicationCard(
            app: app,
            index: app.pillSlot - 1,
            isToggleEnabled: _toggleButtonEnabled[app.pillSlot] ?? true,
            onToggle: _toggleSlotStatus,
            onTap: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => SlotDetailsDialog(
                  slot: app.pillSlot,
                  slotData: SlotData.fromAppModel(app),
                  activeDays: app.activeDaysString,
                ),
              );
              
              if (result == true && mounted) {
                await _refreshData();
              }
            },
            displayTime: app.displayTime,
            activeDays: app.activeDaysString,
          ),
        );
      },
    );
  }
}