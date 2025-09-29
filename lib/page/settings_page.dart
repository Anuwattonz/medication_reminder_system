import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:medication_reminder_system/page/qr_scan_page.dart';
import 'package:medication_reminder_system/widget/setting/settings_widgets.dart';
import 'package:medication_reminder_system/widget/setting/time_picker_dialog.dart';
import 'package:medication_reminder_system/page/tabbar_page.dart';
import 'package:medication_reminder_system/jwt/auth.dart';
import 'package:medication_reminder_system/api/settings_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _volume = 50.0;
  
  // สำหรับ Duration (แจ้งเตือนติดต่อเป็นเวลา)
  int _durationHours = 0;
  int _durationMinutes = 0;
  int _durationSeconds = 0;
  
  // สำหรับ Frequency (ความถี่การแจ้งเตือน)
  int _frequencyHours = 0;
  int _frequencyMinutes = 0;
  int _frequencySeconds = 0;
  
  String _username = '';
  String _connectId = '';

  bool _isSaving = false;
  bool _hasInitialized = false;

  // ✅ เพิ่มตัวแปรเก็บค่าเดิมเพื่อเปรียบเทียบ
  double _originalVolume = 50.0;
  int _originalDurationHours = 0;
  int _originalDurationMinutes = 0;
  int _originalDurationSeconds = 0;
  int _originalFrequencyHours = 0;
  int _originalFrequencyMinutes = 0;
  int _originalFrequencySeconds = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('⚙️ [SETTINGS] initState called - deferring data load');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LogoutHelper.setGlobalContext(context);
        
        if (!_hasInitialized) {
          _hasInitialized = true;
          _loadInitialDataWithDelay();
        }
      }
    });
  }

  // ✅ ฟังก์ชันตรวจสอบว่ามีการเปลี่ยนแปลงหรือไม่
  bool _hasSettingsChanged() {
    return _volume != _originalVolume ||
           _durationHours != _originalDurationHours ||
           _durationMinutes != _originalDurationMinutes ||
           _durationSeconds != _originalDurationSeconds ||
           _frequencyHours != _originalFrequencyHours ||
           _frequencyMinutes != _originalFrequencyMinutes ||
           _frequencySeconds != _originalFrequencySeconds;
  }

  // ✅ ฟังก์ชันบันทึกค่าเดิมหลังจากโหลดสำเร็จ
  void _saveOriginalValues() {
    _originalVolume = _volume;
    _originalDurationHours = _durationHours;
    _originalDurationMinutes = _durationMinutes;
    _originalDurationSeconds = _durationSeconds;
    _originalFrequencyHours = _frequencyHours;
    _originalFrequencyMinutes = _frequencyMinutes;
    _originalFrequencySeconds = _frequencySeconds;
  }

  // ฟังก์ชันใหม่: โหลดข้อมูลพร้อม delay
  Future<void> _loadInitialDataWithDelay() async {
    // รอให้ UI และ animations settle
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      debugPrint('⚙️ [SETTINGS] Starting delayed data load...');
      _loadInitialData();
    }
  }

  // โหลดข้อมูลเริ่มต้นจาก Auth system
  Future<void> _loadInitialData() async {
    debugPrint('=== LOADING SETTINGS INITIAL DATA ===');

    try {
      await _loadUserDataFromAuth();
      
      if (_connectId.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        await _loadSettingsFromAPI();
      } else {
        debugPrint('❌ No connect_id found, skipping settings load');
      }
    } catch (e) {
      debugPrint('❌ Error loading settings initial data: $e');
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถโหลดข้อมูลได้: $e');
      }
    }
    
    debugPrint('=== SETTINGS INITIAL DATA LOADED ===');
  }

  // โหลดข้อมูลผู้ใช้จาก Auth system
  Future<void> _loadUserDataFromAuth() async {
    debugPrint('=== LOADING SETTINGS USER DATA FROM AUTH ===');
    
    try {
      final userId = await Auth.currentUserId();
      final connectionId = await Auth.currentConnectionId();
      
      debugPrint('Settings auth data loaded:');
      debugPrint('- User ID: $userId');
      debugPrint('- Connect ID: $connectionId');
      
      if (mounted) {
        setState(() {
          _connectId = connectionId ?? '';
        });
      }
      
    } catch (e) {
      debugPrint('❌ Error loading settings user data from auth: $e');
      if (mounted) {
        setState(() {
          _username = 'ไม่พบชื่อผู้ใช้';
          _connectId = '';
        });
      }
    }
  }

  // โหลดการตั้งค่าจาก API ด้วย JWT
  Future<void> _loadSettingsFromAPI() async {
    if (_connectId.isEmpty) {
      debugPrint('❌ No connect_id for loading settings');
      return;
    }

    debugPrint('=== LOADING SETTINGS FROM API ===');
    debugPrint('Connect ID: $_connectId');

    try {
      final response = await SettingsApi.getVolumeSettings(_connectId);

      debugPrint('Settings API response: ${response.statusCode}');
      debugPrint('Settings API body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final data = result['data'] ?? result;
        
        if (result['status'] == 'success' && data['settings'] != null) {
          final settings = data['settings'];
          _username = data['username'];
          
          if (mounted) {
            setState(() {
              _volume = (settings['volume'] ?? 50).toDouble();
              
              final durationTime = _parseSecondsToTime(settings['delay'] ?? 0);
              _durationHours = durationTime['hours']!;
              _durationMinutes = durationTime['minutes']!;
              _durationSeconds = durationTime['seconds']!;
              
              final frequencyTime = _parseSecondsToTime(settings['alert_offset'] ?? 0);
              _frequencyHours = frequencyTime['hours']!;
              _frequencyMinutes = frequencyTime['minutes']!;
              _frequencySeconds = frequencyTime['seconds']!;
              
              _username = data['username'] ?? 'ไม่พบชื่อผู้ใช้';
            });
            
            // ✅ บันทึกค่าเดิมหลังจากโหลดสำเร็จ
            _saveOriginalValues();
          }
          
          debugPrint('✅ Settings and user info loaded successfully');
        } else {
          debugPrint('❌ Settings API returned error: ${result['message']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถโหลดการตั้งค่าได้: $e');
      }
    }
  }

  // ✅ แก้ไขชื่อผู้ใช้พร้อม validation
  Future<void> _updateUsername(String newUsername) async {
    // ✅ ตรวจสอบความยาวก่อนส่ง API
    if (newUsername.trim().isEmpty) {
      _showErrorSnackBar('กรุณาใส่ชื่อผู้ใช้');
      return;
    }
    
    if (newUsername.trim().length > 50) {
      _showErrorSnackBar('ชื่อผู้ใช้ต้องไม่เกิน 50 ตัวอักษร');
      return;
    }
    
    if (newUsername.trim() == _username.trim()) {
      return; // ไม่มีการเปลี่ยนแปลง
    }

    final trimmedUsername = newUsername.trim();
    debugPrint('=== UPDATING USERNAME ===');
    debugPrint('New username: $trimmedUsername');

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final response = await SettingsApi.updateUsername(trimmedUsername);

      debugPrint('Update username API response: ${response.statusCode}');
      debugPrint('Update username API body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['status'] == 'success') {
          if (mounted) {
            setState(() {
              _username = trimmedUsername;
            });
            _showSuccessSnackBar('แก้ไขชื่อผู้ใช้เรียบร้อยแล้ว');
          }
          
          await _loadUserDataFromAuth();
          debugPrint('✅ Username updated successfully');
        } else {
          throw Exception(result['message'] ?? 'ไม่สามารถแก้ไขชื่อผู้ใช้ได้');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error updating username: $e');
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถแก้ไขชื่อผู้ใช้ได้');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // บันทึกการตั้งค่าผ่าน API ด้วย JWT
  Future<void> _saveSettings() async {
    if (_connectId.isEmpty) {
      _showErrorSnackBar('ไม่พบ connect_id กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    // ✅ ตรวจสอบว่ามีการเปลี่ยนแปลงหรือไม่
    if (!_hasSettingsChanged()) {
      _showErrorSnackBar('ไม่มีการเปลี่ยนแปลงที่ต้องบันทึก');
      return;
    }

    debugPrint('=== SAVING SETTINGS ===');

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final durationSeconds = (_durationHours * 3600) + (_durationMinutes * 60) + _durationSeconds;
      final frequencySeconds = (_frequencyHours * 3600) + (_frequencyMinutes * 60) + _frequencySeconds;

      debugPrint('Settings data: volume=${_volume.round()}, delay=$durationSeconds, alertOffset=$frequencySeconds');
      
      final response = await SettingsApi.updateVolumeSettings(
        connectId: _connectId,
        volume: _volume.round(),
        delay: durationSeconds,
        alertOffset: frequencySeconds,
      );

      debugPrint('Save settings API response: ${response.statusCode}');
      debugPrint('Save settings API body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['status'] == 'success') {
          if (mounted) {
            // ✅ บันทึกค่าใหม่เป็นค่าเดิม หลังจากบันทึกสำเร็จ
            _saveOriginalValues();
            _showSuccessSnackBar('บันทึกการตั้งค่าเรียบร้อยแล้ว');
          }
          debugPrint('✅ Settings saved successfully');
        } else {
          throw Exception(result['message'] ?? 'ไม่สามารถบันทึกการตั้งค่าได้');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถบันทึกข้อมูลได้');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ออกจากระบบด้วย LogoutHelper
  Future<void> _logout() async {
    debugPrint('=== LOGOUT FROM SETTINGS ===');
    if (mounted) {
      await LogoutHelper.logoutWithConfirmation(context);
    }
  }

  // ไปหน้า QR Scan โดยไม่ส่ง userData
  Future<void> _goToQRScan() async {
    debugPrint('=== GOING TO QR SCAN ===');
    
    try {
      final isAuthenticated = await Auth.isAuthenticated();
      if (!isAuthenticated) {
        if (mounted) {
          _showErrorSnackBar('กรุณาเข้าสู่ระบบใหม่');
        }
        return;
      }

      if (!mounted) return;

      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScanPage(),
        ),
      );

      debugPrint('QR Scan result: $result');

      if (result == true) {
        debugPrint('✅ QR Scan successful');
        
        if (mounted) {
          _showSuccessSnackBar('เชื่อมต่ออุปกรณ์สำเร็จ!');
        }
        
        await Future.delayed(const Duration(milliseconds: 1500));
        await _loadUserDataFromAuth();
        await _navigateToTabBar();
        
      } else if (result == false) {
        if (mounted) {
          _showErrorSnackBar('การเชื่อมต่ออุปกรณ์ล้มเหลว');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in QR Scan: $e');
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  // นำทางไปหน้า TabBar
  Future<void> _navigateToTabBar() async {
    debugPrint('=== NAVIGATING TO TAB BAR ===');
    
    try {
      final currentUserId = await Auth.currentUserId();
      final connectionId = await Auth.currentConnectionId();
      
      if (currentUserId == null || connectionId == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ใน JWT token');
      }
      
      final userData = {
        'user_id': currentUserId,
      };
      
      final connections = [{
        'connect_id': connectionId,
        'user_id': currentUserId,
      }];
      
      debugPrint('TabBar userData: $userData');
      debugPrint('TabBar connections: $connections');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomTabBar(
              userData: userData,
              connections: connections,
            ),
          ),
        );
        debugPrint('✅ Navigated to TabBar successfully');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to TabBar: $e');
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการนำทาง: $e');
      }
    }
  }

  // Helper: แปลง seconds เป็น hours, minutes, seconds
  Map<String, int> _parseSecondsToTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    return {
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  // Helper: แปลงเวลาเป็น string
  String _formatTimeDisplay(int hours, int minutes, int seconds) {
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Helper: แสดง SnackBar สำเร็จ
  void _showSuccessSnackBar(String message) {
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
                child: const Icon(
                  Icons.check_circle,
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
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
    }
  }

  // Helper: แสดง SnackBar ข้อผิดพลาด
  void _showErrorSnackBar(String message) {
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
                child: const Icon(
                  Icons.error_outline,
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
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
    }
  }

  // แสดง Time Picker สำหรับ Duration
  void _showDurationPicker() {
    showTimePickerDialog(
      context: context,
      title: 'แจ้งเตือนติดต่อเป็นเวลา',
      initialHours: _durationHours,
      initialMinutes: _durationMinutes,
      initialSeconds: _durationSeconds,
      onConfirm: (hours, minutes, seconds) {
        if (mounted) {
          setState(() {
            _durationHours = hours;
            _durationMinutes = minutes;
            _durationSeconds = seconds;
          });
        }
      },
    );
  }

  // แสดง Time Picker สำหรับ Frequency
  void _showFrequencyPicker() {
    showTimePickerDialog(
      context: context,
      title: 'ความถี่การแจ้งเตือน',
      initialHours: _frequencyHours,
      initialMinutes: _frequencyMinutes,
      initialSeconds: _frequencySeconds,
      onConfirm: (hours, minutes, seconds) {
        if (mounted) {
          setState(() {
            _frequencyHours = hours;
            _frequencyMinutes = minutes;
            _frequencySeconds = seconds;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ตั้งค่า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ เอาปุ่มย้อนกลับออก
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF303F9F), Color(0xFF1A237E)], // ✅ เปลี่ยนกลับเป็นสีเดิม
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: _connectId.isEmpty
            ? NoConnectionView(
                onConnect: _goToQRScan,
                onLogout: _logout,
              )
            : _buildFullSettingsView(),
      ),
    );
  }

  // ✅ View สำหรับผู้ใช้ที่มี connect_id - ไม่มี loading
  Widget _buildFullSettingsView() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: const Color(0xFF4CAF50), // ✅ เปลี่ยน refresh indicator เป็นสีเขียว
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงข้อมูลผู้ใช้
            UserInfoCard(
              username: _username,
              connectId: _connectId,
              onUsernameChanged: _updateUsername,
            ),

            // ระดับเสียง
            VolumeCard(
              volume: _volume,
              onVolumeChanged: (value) {
                if (mounted) {
                  setState(() {
                    _volume = value;
                  });
                }
              },
            ),

            // ระยะเวลาการแจ้งเตือน
            TimeSettingCard(
              icon: Icons.timer,
              iconColor: Colors.orange,
              title: 'แจ้งเตือนติดต่อเป็นเวลา',
              timeDisplay: _formatTimeDisplay(
                _durationHours,
                _durationMinutes,
                _durationSeconds,
              ),
              onTap: _showDurationPicker,
            ),

            // ความถี่การแจ้งเตือน
            TimeSettingCard(
              icon: Icons.repeat,
              iconColor: const Color(0xFF4CAF50), // ✅ เปลี่ยนเป็นสีเขียว
              title: 'ความถี่การแจ้งเตือน',
              timeDisplay: _formatTimeDisplay(
                _frequencyHours,
                _frequencyMinutes,
                _frequencySeconds,
              ),
              onTap: _showFrequencyPicker,
            ),

            const SizedBox(height: 16),

            // ✅ ปุ่มบันทึก - เปิด/ปิดตามการเปลี่ยนแปลง
            SettingsButton(
              icon: Icons.save,
              label: _hasSettingsChanged() 
                  ? 'บันทึกการตั้งค่า' 
                  : 'ไม่มีการเปลี่ยนแปลง',
              backgroundColor: _hasSettingsChanged() 
                  ? const Color(0xFF4CAF50) // สีเขียวเมื่อใช้งานได้
                  : Colors.grey[400]!, // สีเทาเมื่อกดไม่ได้
              onPressed: _hasSettingsChanged() ? _saveSettings : null, // ✅ null เมื่อไม่มีการเปลี่ยนแปลง
              isLoading: _isSaving,
            ),

            const SizedBox(height: 16),

            // ปุ่มออกจากระบบ
            SettingsButton(
              icon: Icons.logout,
              label: 'ออกจากระบบ',
              backgroundColor: Colors.grey[800]!,
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }
}