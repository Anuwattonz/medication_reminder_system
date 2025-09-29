import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:medication_reminder_system/jwt/auth.dart';
import 'package:medication_reminder_system/api/medication_edit_api.dart';
import 'package:medication_reminder_system/widget/medication/edit/edit_medication_widget.dart';

class EditMedicationInfoDialog extends StatefulWidget {
  final String medicationId;
  final Map<String, dynamic> currentData;
  final Function(Map<String, dynamic>, bool, {bool imageChanged}) onSave;

  const EditMedicationInfoDialog({
    super.key,
    required this.medicationId,
    required this.currentData,
    required this.onSave,
  });

  @override
  State<EditMedicationInfoDialog> createState() => _EditMedicationInfoDialogState();
}

class _EditMedicationInfoDialogState extends State<EditMedicationInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedDosageForm;
  String? _selectedUnitType;
  int? _selectedDosageFormId;
  int? _selectedUnitTypeId;

  List<Map<String, dynamic>> dosageForms = [];
  List<Map<String, dynamic>> unitTypeOptions = [];
  List<Map<String, dynamic>> allUnitTypes = [];

  late Map<String, dynamic> _originalData;
  final GlobalKey _dosageFormKey = GlobalKey();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _unitTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    _originalData = Map<String, dynamic>.from(widget.currentData);
    
    _nameController = TextEditingController(text: widget.currentData['medication_name']);
    _nicknameController = TextEditingController(text: widget.currentData['medication_nickname'] == '-' ? '' : widget.currentData['medication_nickname']);
    _descriptionController = TextEditingController(text: widget.currentData['description'] == '-' ? '' : widget.currentData['description']);

    _selectedDosageForm = widget.currentData['dosage_form'];
    _selectedUnitType = widget.currentData['unit_type'];
    _selectedDosageFormId = widget.currentData['dosage_form_id'];
    _selectedUnitTypeId = widget.currentData['unit_type_id'];

    if (widget.currentData.containsKey('available_dosage_forms') && 
        widget.currentData.containsKey('all_unit_types')) {
      _setupFormDataFromParent();
    } else {
      _loadFormData();
    }

    // เพิ่ม listener สำหรับอัพเดท clear button
    _nameController.addListener(() => setState(() {}));
    _nicknameController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _setupFormDataFromParent() {
    setState(() {
      dosageForms = List<Map<String, dynamic>>.from(widget.currentData['available_dosage_forms'] ?? []);
      allUnitTypes = List<Map<String, dynamic>>.from(widget.currentData['all_unit_types'] ?? []);
      unitTypeOptions = allUnitTypes.where((unit) => 
        unit['dosage_form_id'] == _selectedDosageFormId
      ).toList();
      _isLoading = false;
    });
    
     }

  bool _hasDataChanged() {
    final currentNickname = _nicknameController.text.trim().isEmpty ? '-' : _nicknameController.text.trim();
    final currentDescription = _descriptionController.text.trim().isEmpty ? '-' : _descriptionController.text.trim();
    
    return _nameController.text.trim() != _originalData['medication_name'] ||
           currentNickname != (_originalData['medication_nickname'] ?? '-') ||
           currentDescription != (_originalData['description'] ?? '-') ||
           _selectedDosageFormId != _originalData['dosage_form_id'] ||
           _selectedUnitTypeId != _originalData['unit_type_id'] ||
           _selectedImage != null;
  }

  bool _hasImageChanged() {
    return _selectedImage != null;
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await MedicationInfoApi.getMedication(widget.medicationId);
      
      if (result['success']) {
        final data = result['data']['data'];
        
        setState(() {
          _selectedDosageForm = data['medication']['dosage_form'];
          _selectedDosageFormId = data['medication']['dosage_form_id'];
          _selectedUnitType = data['medication']['unit_type'];
          _selectedUnitTypeId = data['medication']['unit_type_id'];
          
          dosageForms = List<Map<String, dynamic>>.from(data['available_dosage_forms'] ?? []);
          allUnitTypes = List<Map<String, dynamic>>.from(data['all_unit_types'] ?? []);
          unitTypeOptions = List<Map<String, dynamic>>.from(data['available_unit_types'] ?? []);
        });
      } else {
        _showErrorDialog('ไม่สามารถโหลดข้อมูลฟอร์มได้');
      }
    } catch (e) {
       _showErrorDialog('เกิดข้อผิดพลาดในการโหลดข้อมูล');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateUnitTypeOptions() {
    if (_selectedDosageFormId != null) {
      setState(() {
        unitTypeOptions = allUnitTypes.where((unit) => 
          unit['dosage_form_id'] == _selectedDosageFormId
        ).toList();
        
        bool isCurrentUnitValid = unitTypeOptions.any((unit) => 
          unit['unit_type_id'] == _selectedUnitTypeId
        );
        
        if (!isCurrentUnitValid) {
          _selectedUnitTypeId = null;
          _selectedUnitType = null;
        }
      });
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเลือกรูปภาพ');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการถ่ายรูป');
    }
  }

  void _showImagePicker() {
    // ซ่อนแป้นพิมพ์ก่อนเปิด image picker
    FocusManager.instance.primaryFocus?.unfocus();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditMedicationWidget.buildImagePickerBottomSheet(
          onSelectFromGallery: () {
            Navigator.pop(context);
            _selectImage();
          },
          onTakePhoto: () {
            Navigator.pop(context);
            _takePhoto();
          },
          onRemoveImage: _selectedImage != null ? () {
            Navigator.pop(context);
            setState(() {
              _selectedImage = null;
            });
          } : null,
        );
      },
    );
  }

  void _onDosageFormSelected(int dosageFormId, String dosageFormName) {
    setState(() {
      _selectedDosageFormId = dosageFormId;
      _selectedDosageForm = dosageFormName;
    });
    _updateUnitTypeOptions();
  }

  void _onUnitTypeSelected(int unitTypeId, String unitTypeName) {
    setState(() {
      _selectedUnitTypeId = unitTypeId;
      _selectedUnitType = unitTypeName;
    });
  }

  Future<void> _saveChanges() async {
    
    // ซ่อนแป้นพิมพ์ก่อนบันทึก
    FocusManager.instance.primaryFocus?.unfocus();
    
    // ตรวจสอบความถูกต้องของฟอร์ม
    if (!_formKey.currentState!.validate()) {
     // เลื่อนไปที่ช่องแรกที่ผิด (ช่องชื่อยา)
      _scrollToSection(_nameFieldKey);
      return;
    }

    // ตรวจสอบรูปแบบยาและหน่วยยา
    if (_selectedDosageFormId == null) {
     // เลื่อนไปที่ส่วนเลือกรูปแบบยา
      _scrollToSection(_dosageFormKey);
      return;
    }

    if (_selectedUnitTypeId == null) {
      // เลื่อนไปที่ส่วนเลือกหน่วยยา
      _scrollToSection(_unitTypeKey);
      return;
    }

    bool dataChanged = _hasDataChanged();
    bool imageChanged = _hasImageChanged();
    
   
    if (!dataChanged) {
     Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await MedicationInfoApi.updateMedication(
        medicationId: widget.medicationId,
        medicationName: _nameController.text.trim(),
        medicationNickname: _nicknameController.text.trim(),
        description: _descriptionController.text.trim(),
        dosageFormId: _selectedDosageFormId!.toString(),
        unitTypeId: _selectedUnitTypeId!.toString(),
        imageFile: _selectedImage,
      );

      if (result['statusCode'] == 401) {
        final refreshSuccess = await Auth.refreshToken();
        
        if (refreshSuccess && mounted) {
          await _saveChanges();
        } else if (mounted) {
          await Auth.logout(context);
        }
        return;
      }

      if (result['success']) {
        
        final apiData = result['data'];
        String? pictureUrl;
        
        if (apiData != null && apiData['picture_url'] != null) {
          pictureUrl = apiData['picture_url'].toString();
        } else {
          pictureUrl = widget.currentData['picture_url'];
         }

        final updatedData = {
          'medication_name': _nameController.text.trim(),
          'medication_nickname': _nicknameController.text.trim().isEmpty ? '-' : _nicknameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty ? '-' : _descriptionController.text.trim(),
          'dosage_form': _selectedDosageForm,
          'unit_type': _selectedUnitType,
          'dosage_form_id': _selectedDosageFormId,
          'unit_type_id': _selectedUnitTypeId,
          'picture_url': pictureUrl,
        };

        widget.onSave(updatedData, true, imageChanged: imageChanged);
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (result['statusCode'] == 403) {
        _showErrorDialog('ไม่มีสิทธิ์ในการแก้ไขข้อมูลยา');
      } else {
        String errorMessage = 'เกิดข้อผิดพลาดในการบันทึกข้อมูล';
        if (result['data'] != null && result['data']['message'] != null) {
          errorMessage = result['data']['message'];
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเชื่อมต่อ');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              const Text('เกิดข้อผิดพลาด'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: EditMedicationWidget.buildKeyboardDismissWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditMedicationWidget.buildDialogHeader(
                onClose: () {
                  // ซ่อนแป้นพิมพ์ก่อนปิด dialog
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
              ),
              
              Flexible(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                key: _nameFieldKey,
                                child: EditMedicationWidget.buildTextField(
                                  controller: _nameController,
                                  label: 'ชื่อยา *',
                                  hint: 'กรอกชื่อยา',
                                  icon: Icons.medication_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'กรุณากรอกชื่อยา';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              EditMedicationWidget.buildTextField(
                                controller: _nicknameController,
                                label: 'ชื่อเล่น',
                                hint: 'ชื่อเล่นหรือชื่อย่อ (ไม่บังคับ)',
                                icon: Icons.label_outline_rounded,
                              ),
                              const SizedBox(height: 24),

                              EditMedicationWidget.buildTextField(
                                controller: _descriptionController,
                                label: 'รายละเอียด',
                                hint: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                                icon: Icons.description_rounded,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 28),

                              // Header สำหรับรูปภาพ
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
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.image_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'รูปภาพยา',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E7D32),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              EditMedicationWidget.buildImageDisplay(
                                selectedImage: _selectedImage,
                                currentImageUrl: widget.currentData['picture_url'],
                                onTap: _showImagePicker,
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),

                        EditMedicationWidget.buildDosageFormSection(
                          dosageFormKey: _dosageFormKey,
                          isLoading: _isLoading,
                          dosageForms: dosageForms,
                          selectedDosageFormId: _selectedDosageFormId,
                          onDosageFormSelected: _onDosageFormSelected,
                          onRetryLoad: _loadFormData,
                        ),

                        EditMedicationWidget.buildUnitTypeSection(
                          selectedDosageFormId: _selectedDosageFormId,
                          unitTypeOptions: unitTypeOptions,
                          selectedUnitTypeId: _selectedUnitTypeId,
                          onUnitTypeSelected: _onUnitTypeSelected,
                        ),

                        if (_selectedDosageFormId != null && _selectedUnitTypeId != null) ...[
                          const SizedBox(height: 28),
                          EditMedicationWidget.buildSettingSummary(
                            selectedDosageForm: _selectedDosageForm,
                            selectedUnitType: _selectedUnitType,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              EditMedicationWidget.buildDialogFooter(
                isLoading: _isLoading,
                onCancel: () {
                  // ซ่อนแป้นพิมพ์ก่อนยกเลิก
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
                onSave: _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}