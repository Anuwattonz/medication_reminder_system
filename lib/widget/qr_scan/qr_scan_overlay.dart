import 'package:flutter/material.dart';

class QRScanOverlay extends StatefulWidget {
  const QRScanOverlay({super.key});

  @override
  State<QRScanOverlay> createState() => _QRScanOverlayState();
}

class _QRScanOverlayState extends State<QRScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final overlaySize = screenWidth * 0.75;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // พื้นหลังดำโปร่งใสรอบๆ กรอบ
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha:0.5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // รูตรงกลางสำหรับ QR scanning area
                Container(
                  width: overlaySize,
                  height: overlaySize,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated scanning frame
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: overlaySize,
                height: overlaySize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue.withValues(alpha:_animation.value),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),

          // Corner decorations
          SizedBox(
            width: overlaySize,
            height: overlaySize,
            child: Stack(
              children: [
                // Top Left Corner
                Positioned(
                  top: -2,
                  left: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.blue, width: 4),
                        left: BorderSide(color: Colors.blue, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                // Top Right Corner
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.blue, width: 4),
                        right: BorderSide(color: Colors.blue, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                // Bottom Left Corner
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.blue, width: 4),
                        left: BorderSide(color: Colors.blue, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                // Bottom Right Corner
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.blue, width: 4),
                        right: BorderSide(color: Colors.blue, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Positioned(
            bottom: -60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'วาง QR Code ในกรอบ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRProcessingOverlay extends StatelessWidget {
  const QRProcessingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha:0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue.withValues(alpha:0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'กำลังเชื่อมต่ออุปกรณ์',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'โปรดรอสักครู่...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha:0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi,
                    color: Colors.blue[300],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'กำลังส่งข้อมูล',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// เพิ่ม Custom Painter สำหรับ scanning line effect (ถ้าต้องการ)
class QRScanAnimatedOverlay extends StatefulWidget {
  const QRScanAnimatedOverlay({super.key});

  @override
  State<QRScanAnimatedOverlay> createState() => _QRScanAnimatedOverlayState();
}

class _QRScanAnimatedOverlayState extends State<QRScanAnimatedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final overlaySize = screenWidth * 0.75;

    return Center(
      child: SizedBox(
        width: overlaySize,
        height: overlaySize,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: ScanLinePainter(_animation.value),
              size: Size(overlaySize, overlaySize),
            );
          },
        ),
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double animationValue;

  ScanLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha:0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final lineY = size.height * animationValue;
    
    // วาดเส้น scanning
    canvas.drawLine(
      Offset(20, lineY),
      Offset(size.width - 20, lineY),
      paint,
    );

    // วาด gradient effect
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.blue.withValues(alpha:0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, lineY - 10, size.width, 20));

    canvas.drawRect(
      Rect.fromLTWH(20, lineY - 10, size.width - 40, 20),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}