import 'package:flutter/material.dart';
import 'dart:io';

// ✅ Widget สำหรับส่วน UI ของ EditMedicationInfoDialog
class EditMedicationWidget {
  
  // ✅ Widget สำหรับแสดง placeholder รูปภาพ
  static Widget buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'แตะเพื่อเพิ่มรูปภาพ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ✅ Widget สำหรับแสดงรูปภาพ (เลือกใหม่หรือรูปเดิม)
  static Widget buildImageDisplay({
    required File? selectedImage,
    required String? currentImageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // ซ่อนแป้นพิมพ์ก่อนเปิด image picker
        FocusManager.instance.primaryFocus?.unfocus();
        onTap();
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      selectedImage,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          onTap();
                        },
                      ),
                    ),
                  ),
                ],
              )
            : currentImageUrl != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          currentImageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return buildImagePlaceholder();
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              onTap();
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : buildImagePlaceholder(),
      ),
    );
  }

  // ✅ Widget สำหรับ Header ของ Dialog (สีเขียว)
  static Widget buildDialogHeader({required VoidCallback onClose}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แก้ไขข้อมูลยา',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ปรับปรุงรายละเอียดยาของคุณ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับ Footer ของ Dialog (สีเขียว)
  static Widget buildDialogFooter({
    required bool isLoading,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ยกเลิก'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('บันทึก'),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget สำหรับ Text Field ที่ใช้ทั่วไป (สีเขียว)
  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
          ),
          validator: validator,
          onTap: () {
            // แป้นพิมพ์จะเด้งขึ้นเมื่อแตะช่องกรอกข้อมูลเท่านั้น
          },
        ),
      ],
    );
  }

  // ✅ Widget สำหรับส่วนรูปแบบยา (สีเขียว)
  static Widget buildDosageFormSection({
    required GlobalKey dosageFormKey,
    required bool isLoading,
    required List<Map<String, dynamic>> dosageForms,
    required int? selectedDosageFormId,
    required Function(int, String) onDosageFormSelected,
    required VoidCallback onRetryLoad,
  }) {
    return Container(
      key: dosageFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รูปแบบยา',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'เลือกประเภทและหน่วยของยา',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Content
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          else if (dosageForms.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 32),
                  const SizedBox(height: 8),
                  const Text('ไม่สามารถโหลดข้อมูลรูปแบบยาได้'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onRetryLoad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'ประเภทยา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            // Dosage Form Options
            Row(
              children: dosageForms.map((form) {
                final isSelected = selectedDosageFormId == form['dosage_form_id'];
                final index = dosageForms.indexOf(form);
                
                final formName = form['dosage_name']?.toString() ?? 
                                form['dosage_form_name']?.toString() ?? 
                                'ไม่ระบุ';
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < dosageForms.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // ซ่อนแป้นพิมพ์ก่อนเลือกรูปแบบยา
                        FocusManager.instance.primaryFocus?.unfocus();
                        onDosageFormSelected(
                          form['dosage_form_id'] ?? 0,
                          formName,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [Colors.grey[100]!, Colors.grey[200]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              spreadRadius: 0,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Text(
                          formName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Widget สำหรับส่วนหน่วยยา (สีเขียวฟ้า)
  static Widget buildUnitTypeSection({
    required int? selectedDosageFormId,
    required List<Map<String, dynamic>> unitTypeOptions,
    required int? selectedUnitTypeId,
    required Function(int, String) onUnitTypeSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'หน่วยยา',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        
        if (selectedDosageFormId == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('กรุณาเลือกประเภทยาก่อน'),
                ),
              ],
            ),
          )
        else if (unitTypeOptions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('ไม่มีหน่วยยาสำหรับประเภทนี้'),
                ),
              ],
            ),
          )
        else
          Row(
            children: unitTypeOptions.map((unit) {
              final isSelected = selectedUnitTypeId == unit['unit_type_id'];
              final index = unitTypeOptions.indexOf(unit);
              
              final unitName = unit['unit_type_name']?.toString() ?? 
                              unit['unit_name']?.toString() ?? 
                              'ไม่ระบุ';
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < unitTypeOptions.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // ซ่อนแป้นพิมพ์ก่อนเลือกหน่วยยา
                      FocusManager.instance.primaryFocus?.unfocus();
                      onUnitTypeSelected(
                        unit['unit_type_id'] ?? 0,
                        unitName,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Colors.teal[400]!, Colors.teal[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.grey[100]!, Colors.grey[200]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.teal[600]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.2),
                            spreadRadius: 0,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ] : [],
                      ),
                      child: Text(
                        unitName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ✅ Widget สำหรับสรุปการตั้งค่า (สีเขียว)
  static Widget buildSettingSummary({
    required String? selectedDosageForm,
    required String? selectedUnitType,
  }) {
    final dosageForm = selectedDosageForm ?? 'ไม่ระบุ';
    final unitType = selectedUnitType ?? 'ไม่ระบุ';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.1),
            const Color(0xFF2E7D32).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'การตั้งค่าที่เลือก',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ประเภท: $dosageForm | หน่วย: $unitType',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget Wrapper สำหรับจัดการแป้นพิมพ์
  static Widget buildKeyboardDismissWrapper({required Widget child}) {
    return GestureDetector(
      onTap: () {
        // ซ่อนแป้นพิมพ์เมื่อแตะพื้นที่ว่าง
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
// ส่วนที่ต้องแก้ไขในไฟล์ edit_medication_widget.dart

  // ✅ Bottom Sheet เลือกรูปภาพ - แก้ไขสีให้เหมือน create_medication_widget
  static Widget buildImagePickerBottomSheet({
    required VoidCallback onSelectFromGallery,
    required VoidCallback onTakePhoto,
    required VoidCallback? onRemoveImage,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // ✅ แก้ไขส่วนนี้: ปุ่มเรียงแนวนอนเหมือน create_medication_widget
          Row(
            children: [
              // ปุ่มคลังรูปภาพ - เปลี่ยนเป็นสีเขียว
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSelectFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('คลังรูปภาพ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4CAF50), // เขียวเหมือน create
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // ปุ่มถ่ายรูป - เปลี่ยนเป็นสี teal
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ถ่ายรูป'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal[600], // teal เหมือน create
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // ปุ่มลบรูป (ถ้ามีรูป) - ย้ายลงมาด้านล่าง
          if (onRemoveImage != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRemoveImage,
              icon: const Icon(Icons.delete),
              label: const Text('ลบรูปภาพ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}