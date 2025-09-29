import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับ SystemChrome
import 'package:medication_reminder_system/jwt/auth.dart'; // Import JWT Auth System
import 'package:medication_reminder_system/notification/notification_service.dart';

// สร้าง RouteObserver แยกออกมา
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// แก้ไข main() function
void main() async {
  // เพิ่มบรรทัดนี้: จำเป็นสำหรับการใช้ plugins ก่อน runApp
  WidgetsFlutterBinding.ensureInitialized();

  // บังคับให้แอปแสดงผลแนวตั้งอย่างเดียว
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // เริ่มต้น NotificationService
  try {
    await NotificationService.initialize();
  } catch (e) {
    // Handle initialization error silently
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // เพิ่ม NavigatorKey
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Reminder System',
      debugShowCheckedModeBanner: false,

      // เพิ่ม navigatorKey
      navigatorKey: navigatorKey,

      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white, // เพิ่ม: พื้นหลังทั้งแอปเป็นสีขาว
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,         // เพิ่ม: โหมดสว่าง
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      // เพิ่ม RouteObserver สำหรับการจัดการการนำทาง
      navigatorObservers: [
        routeObserver,
      ],
      // แก้ไข builder เพื่อตั้งค่าทั้ง NavigatorKey และ GlobalContext
      builder: (context, child) {
        // ตั้งค่าทั้ง Navigator Key และ Global Context สำหรับ LogoutHelper
        LogoutHelper.setNavigatorKey(navigatorKey);  // เพิ่มบรรทัดนี้
        LogoutHelper.setGlobalContext(context);      // บรรทัดเดิม
        return child!;
      },
      home: const AuthChecker(), // AuthChecker จะ import ได้จาก auth.dart
    );
  }
}