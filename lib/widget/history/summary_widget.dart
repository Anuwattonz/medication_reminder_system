// ไฟล์: lib/widget/summary_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Main Summary Card with beautiful circular chart and statistics
class MainSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summaryData;

  const MainSummaryCard({super.key, required this.summaryData});

  @override
  Widget build(BuildContext context) {
    final total = summaryData['total_reminders'] ?? 0;
    final taken = summaryData['taken_count'] ?? 0;
    final missed = summaryData['missed_count'] ?? 0;
    final rate = summaryData['compliance_rate'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[500]!, // เปลี่ยนจาก purple เป็น indigo
            Colors.indigo[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'สรุปการกินยา',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Main Content with FL Chart
            Row(
              children: [
                // Beautiful Pie Chart
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    children: [
                      // FL Chart Pie Chart
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 35,
                          startDegreeOffset: -90,
                          sections: _createPieChartSections(taken, missed),
                        ),
                      ),
                      // Center Content
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${rate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'สำเร็จ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 32),
                
                // Statistics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow('ทั้งหมด', total, Colors.white, Icons.medication_rounded),
                      const SizedBox(height: 16),
                      _buildStatRow('กินแล้ว', taken, const Color(0xFF10B981), Icons.check_circle_rounded), // เปลี่ยนเป็นสีเขียวเข้ม
                      const SizedBox(height: 16),
                      _buildStatRow('ไม่ได้กิน', missed, const Color(0xFFEF4444), Icons.cancel_rounded), // เปลี่ยนเป็นสีแดงเข้ม
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(int taken, int missed) {
    final total = taken + missed;
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300]!,
          value: 100,
          radius: 25,
          showTitle: false,
        ),
      ];
    }

    return [
      // Taken - Emerald Green
      if (taken > 0)
        PieChartSectionData(
          color: const Color(0xFF10B981), // สีเขียวมรกต
          value: taken.toDouble(),
          radius: 25,
          showTitle: false,
        ),
      // Missed - Bright Red
      if (missed > 0)
        PieChartSectionData(
          color: const Color(0xFFEF4444), // สีแดงสดใส
          value: missed.toDouble(),
          radius: 25,
          showTitle: false,
        ),
    ];
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Period Selector with improved design
class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periodOptions = ['all', 'month', 'week'];
    final periodLabels = {
      'all': 'ทั้งหมด',
      'month': '30 วันล่าสุด',
      'week': '7 วันล่าสุด',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ช่วงเวลา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: periodOptions.map((period) {
              final isSelected = period == selectedPeriod;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: period != periodOptions.last ? 8 : 0,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onPeriodChanged(period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected 
                              ? LinearGradient(
                                  colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.indigo[600]! 
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                          boxShadow: isSelected 
                              ? [
                                  BoxShadow(
                                    color: Colors.indigo.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          periodLabels[period]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Timing Breakdown Card with beautiful bar chart
class TimingBreakdownCard extends StatelessWidget {
  final List<dynamic> timingBreakdown;

  const TimingBreakdownCard({super.key, required this.timingBreakdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)], // สีเหลืองอำพัน/ทอง
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text(
                  'สถิติตามมื้อ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bar Chart
            if (timingBreakdown.isNotEmpty) _buildTimingBarChart(),
            
            const SizedBox(height: 24),
            
            // Timing Items Details
            ...timingBreakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final timing = entry.value;
              final isLast = index == timingBreakdown.length - 1;
              
              return _buildTimingItem(timing, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingBarChart() {
    if (timingBreakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.amber[50]!, Colors.amber[100]!], // เปลี่ยนจาก orange เป็น amber
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= timingBreakdown.length) return const Text('');
                  
                  final timing = timingBreakdown[index];
                  final name = timing['timing'] ?? '';
                  
                  String shortName = '';
                  if (name.contains('เช้า')) {
                    shortName = 'เช้า';
                  } else if (name.contains('กลางวัน')) {
                    shortName = 'เที่ยง';
                  } else if (name.contains('เย็น')) {
                    shortName = 'เย็น';
                  } else if (name.contains('นอน')) {
                    shortName = 'น.';
                  } else {
                    shortName = name.length > 6 ? name.substring(0, 6) : name;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800], // เปลี่ยนเป็นสีเข้มขึ้น
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700], // เปลี่ยนให้เข้มขึ้น
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.transparent,
                strokeWidth: 0,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: timingBreakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final timing = entry.value;
            final rate = timing['compliance_rate'] ?? 0.0;
            final name = timing['timing'] ?? '';
            
            // กำหนดสีตามมื้อ ไม่ใช่ตามเปอร์เซ็นต์
            List<Color> barColors = _getTimingColors(name);
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: rate.toDouble(),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: barColors,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimingItem(Map<String, dynamic> timing, bool isLast) {
    final name = timing['timing'] ?? 'ไม่ระบุ';
    final total = timing['total'] ?? 0;
    final taken = timing['taken'] ?? 0;
    final rate = timing['compliance_rate'] ?? 0.0;
    
    // ใช้สีตามมื้อ ไม่ใช่ตามเปอร์เซ็นต์
    List<Color> timingColors = _getTimingColors(name);
    Color statusColor = timingColors[1]; // ใช้สีเข้ม
    Color bgColor = timingColors[0].withValues(alpha: 0.1);
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Timing Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTimingIcon(name),
                  size: 20,
                  color: statusColor,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Timing Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$taken/$total ครั้ง',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          // Progress Bar
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? taken / total : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันกำหนดสีตามมื้อ
  List<Color> _getTimingColors(String timing) {
    if (timing.contains('เช้า')) {
      // มื้อเช้า - สีส้มอ่อน/แสงแดดยามเช้า
      return [const Color(0xFFFB923C), const Color(0xFFEA580C)];
    } else if (timing.contains('กลางวัน')) {
      // มื้อเที่ยง - สีเหลืองทอง/แสงแดดเที่ยง
      return [const Color(0xFFFBBF24), const Color(0xFFD97706)];
    } else if (timing.contains('เย็น')) {
      // มื้อเย็น - สีส้มแดง/แสงยามเย็น
      return [const Color(0xFFF87171), const Color(0xFFDC2626)];
    } else if (timing.contains('นอน')) {
      // ก่อนนอน - สีม่วงเข้ม/กลางคืน
      return [const Color(0xFFA855F7), const Color(0xFF7C3AED)];
    } else {
      // อื่นๆ - สีน้ำเงิน
      return [const Color(0xFF60A5FA), const Color(0xFF2563EB)];
    }
  }

  IconData _getTimingIcon(String timing) {
    if (timing.contains('เช้า')) return Icons.wb_sunny_rounded;
    if (timing.contains('กลางวัน')) return Icons.wb_sunny_outlined;
    if (timing.contains('เย็น')) return Icons.wb_twilight_rounded;
    if (timing.contains('นอน')) return Icons.bedtime_rounded;
    return Icons.schedule_rounded;
  }
}
/// Weekly Trend Card with beautiful line chart
class WeeklyTrendCard extends StatelessWidget {
  final List<dynamic> weeklyTrend;
  final String? periodName; 

  const WeeklyTrendCard({
    super.key, 
    required this.weeklyTrend,
    this.periodName, // ✅ เพิ่ม parameter นี้
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // สีน้ำเงินสด
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  'แนวโน้ม ${periodName ?? "7 วันล่าสุด"}', // ✅ ใช้ periodName ที่ส่งมา
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Line Chart
            if (weeklyTrend.isNotEmpty && periodName != '30 วัน') 
              _buildWeeklyLineChart(),
            const SizedBox(height: 16),
            
            // Daily Items
            ...weeklyTrend.map((day) => _buildDayItem(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyLineChart() {
    if (weeklyTrend.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.blue[200]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.transparent,
                strokeWidth: 0,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weeklyTrend.length) return const Text('');
                  
                  final day = weeklyTrend[index];
                  final dayName = day['day_name'] ?? '';
                  
                  String shortDay = '';
                  if (dayName.contains('วันจันทร์')) {
                    shortDay = 'จ.';
                  } else if (dayName.contains('วันอังคาร')) {
                    shortDay = 'อ.';
                  } else if (dayName.contains('วันพุธ')) {
                    shortDay = 'พ.';
                  } else if (dayName.contains('วันพฤหัส')) {
                    shortDay = 'พฤ.';
                  } else if (dayName.contains('วันศุกร์')) {
                    shortDay = 'ศ.';
                  } else if (dayName.contains('วันเสาร์')) {
                    shortDay = 'ส.';
                  } else if (dayName.contains('วันอาทิตย์')) {
                    shortDay = 'อา.';
                  } else {
                    shortDay = dayName.length > 3 ? dayName.substring(0, 3) : dayName;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortDay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: weeklyTrend.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final rate = day['compliance_rate'] ?? 0.0;
                return FlSpot(index.toDouble(), rate.toDouble());
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false), // ✅ ซ่อนจุดตามที่ร้องขอ
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> day) {
    final date = day['date'] ?? '';
    final dayName = day['day_name'] ?? '';
    final total = day['total'] ?? 0;
    final taken = day['taken'] ?? 0;
    final rate = day['compliance_rate'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Day Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Stats
          Text(
            '$taken/$total',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Rate
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: total > 0 ? taken / total : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: rate >= 80 ? const Color(0xFF10B981) : 
                         rate >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Text(
            '${rate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: rate >= 80 ? const Color(0xFF059669) : 
                     rate >= 60 ? const Color(0xFFD97706) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
/// Top Medications Card
class TopMedicationsCard extends StatelessWidget {
  final List<dynamic> topMedications;

  const TopMedicationsCard({super.key, required this.topMedications});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF059669), const Color(0xFF047857)], // เขียวมรกตเข้ม
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_liquid_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text(
                  'ยาที่กินบ่อยที่สุด',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Medication Items
            ...topMedications.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              final isLast = index == topMedications.length - 1;
              
              return _buildMedicationItem(med, index + 1, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> med, int rank, bool isLast) {
    final name = med['medication_name'] ?? 'ไม่ระบุ';
    final totalTimes = med['total_times'] ?? 0;
    final takenTimes = med['taken_times'] ?? 0;
    final rate = med['compliance_rate'] ?? 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.1),
            const Color(0xFF047857).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getRankColors(rank),
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _getRankColors(rank)[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: rank <= 3 ? 
                Icon(
                  rank == 1 ? Icons.emoji_events : 
                  rank == 2 ? Icons.military_tech : Icons.workspace_premium,
                  color: Colors.white,
                  size: 18,
                ) : 
                Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Medication Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$takenTimes/$totalTimes ครั้ง',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Rate Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: rate >= 80 ? const Color(0xFF10B981) : 
                     rate >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (rate >= 80 ? const Color(0xFF10B981) : 
                         rate >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getRankColors(int rank) {
    switch (rank) {
      case 1: return [const Color(0xFFF59E0B), const Color(0xFFD97706)]; // ทอง
      case 2: return [const Color(0xFF6B7280), const Color(0xFF4B5563)]; // เงิน  
      case 3: return [const Color(0xFFCD7C2F), const Color(0xFFB45309)]; // ทองแดง
      default: return [const Color(0xFF059669), const Color(0xFF047857)]; // เขียวมรกต
    }
  }
}