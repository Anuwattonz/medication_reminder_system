import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/reminder_detail_api.dart';

/// เนื้อหารายการยา
class MedicationListContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<SlotMedicationDetail> medicationLinks;
  final VoidCallback onRetry;

  const MedicationListContent({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.medicationLinks,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MedicationLoadingCard();
    }
    
    if (errorMessage != null) {
      return MedicationErrorCard(
        errorMessage: errorMessage!,
        onRetry: onRetry,
      );
    }
    
    if (medicationLinks.isEmpty) {
      return const MedicationEmptyCard();
    }
    
    return Column(
      children: medicationLinks.map((med) => MedicationItemCard(
        medication: med,
      )).toList(),
    );
  }
}

/// การ์ดแสดง Loading
class MedicationLoadingCard extends StatelessWidget {
  const MedicationLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'กำลังโหลดข้อมูลยา...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// การ์ดแสดง Error
class MedicationErrorCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const MedicationErrorCard({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}

/// การ์ดแสดงเมื่อไม่มียา
class MedicationEmptyCard extends StatelessWidget {
  const MedicationEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'ยังไม่มีรายการยา',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// การ์ดแสดงรายการยาแต่ละตัว
class MedicationItemCard extends StatelessWidget {
  final SlotMedicationDetail medication;

  const MedicationItemCard({
    super.key,
    required this.medication,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // แสดงรูปยาหรือไอคอนเริ่มต้น
          MedicationImage(
            pictureUrl: medication.pictureUrl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แสดงชื่อยาจริงและชื่อเล่นแยกบรรทัด
                MedicationNameDisplay(medication: medication),
                const SizedBox(height: 8),
                // แสดงจำนวนยา
                MedicationAmountDisplay(medication: medication),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget แสดงรูปยา
class MedicationImage extends StatelessWidget {
  final String? pictureUrl;

  const MedicationImage({
    super.key,
    this.pictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: pictureUrl != null ? Colors.grey[100] : Colors.indigo[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: pictureUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                pictureUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo[600]!,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : const Icon(
              Icons.medication,
              color: Colors.white,
              size: 24,
            ),
    );
  }
}

/// Widget แสดงชื่อยา
class MedicationNameDisplay extends StatelessWidget {
  final SlotMedicationDetail medication;

  const MedicationNameDisplay({
    super.key,
    required this.medication,
  });

  @override
  Widget build(BuildContext context) {
    String realName = medication.medicationName.isNotEmpty 
        ? medication.medicationName 
        : 'ยาไม่ระบุชื่อ';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          realName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Widget แสดงจำนวนยา
class MedicationAmountDisplay extends StatelessWidget {
  final SlotMedicationDetail medication;

  const MedicationAmountDisplay({
    super.key,
    required this.medication,
  });

  String _formatAmount(dynamic amount) {
    if (amount == null) return '1';
    
    double amountValue = 0.0;
    if (amount is String) {
      amountValue = double.tryParse(amount) ?? 1.0;
    } else if (amount is num) {
      amountValue = amount.toDouble();
    } else {
      amountValue = 1.0;
    }
    
    if (amountValue == 0.5) return 'ครึ่ง';
    
    if (amountValue == amountValue.toInt()) {
      return amountValue.toInt().toString();
    }
    
    return amountValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    String displayText = medication.amountWithUnit.replaceFirst(
      RegExp(r'^\d+(\.\d+)?'), 
      _formatAmount(medication.amount)
    );

    return Text(
      'จำนวน: $displayText',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}