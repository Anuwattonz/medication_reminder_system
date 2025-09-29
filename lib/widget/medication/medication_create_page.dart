import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:medication_reminder_system/jwt/auth.dart';
import 'package:medication_reminder_system/api/medication_create_api.dart';
import 'package:medication_reminder_system/widget/medication/create/create_medication_widget.dart';

class CreateMedicationPage extends StatefulWidget {
  const CreateMedicationPage({super.key});

  @override
  State<CreateMedicationPage> createState() => _CreateMedicationPageState();
}

class _CreateMedicationPageState extends State<CreateMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _medicationNicknameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // GlobalKey สำหรับแต่ละส่วน
  final _basicInfoKey = GlobalKey();
  final _dosageFormKey = GlobalKey();
  final _unitTypeKey = GlobalKey();
  final _timingKey = GlobalKey();

  // ✅ เพิ่มตัวแปรเก็บสถานะ error
  bool _nameFieldHasError = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingDosageForms = false;

  int? _selectedDosageFormId;
  int? _selectedUnitTypeId;
  List<Map<String, dynamic>> _availableDosageForms = [];
  List<Map<String, dynamic>> _availableUnitTypes = [];

  final Map<int, String> timingOptions = {
    1: 'มื้อเช้าก่อนอาหาร',
    2: 'มื้อเช้าหลังอาหาร',
    3: 'มื้อกลางวันก่อนอาหาร',
    4: 'มื้อกลางวันหลังอาหาร',
    5: 'มื้อเย็นก่อนอาหาร',
    6: 'มื้อเย็นหลังอาหาร',
    7: 'ก่อนนอน',
  };

  Set<int> selectedTimingIds = {};

  @override
  void initState() {
    super.initState();
    _loadDosageForms();
    
    // ✅ เพิ่ม listener สำหรับช่องชื่อยา
    _medicationNameController.addListener(() {
      if (_nameFieldHasError && _medicationNameController.text.trim().isNotEmpty) {
        setState(() {
          _nameFieldHasError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _medicationNicknameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ======================== ส่วนการโหลดข้อมูล ========================

  Future<void> _loadDosageForms() async {
    setState(() {
      _isLoadingDosageForms = true;
      _availableDosageForms.clear();
    });

    try {
      final result = await ApiMedicationCreate.getDosageForms();
      
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _availableDosageForms = List<Map<String, dynamic>>.from(result['data']);
        });
      } else {
        _showSnackBar(result['message'] ?? 'ไม่สามารถโหลดข้อมูลรูปแบบยาได้', isError: true);
        
        if (result['error'] == 'auth_required' || result['error'] == 'auth_expired') {
          if (mounted) {
            final currentContext = context;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Auth.logout(currentContext);
            });
          }
        }
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล', isError: true);
    } finally {
      setState(() {
        _isLoadingDosageForms = false;
      });
    }
  }

  void _onDosageFormChanged(int dosageFormId) {
    setState(() {
      _selectedDosageFormId = dosageFormId;
      _selectedUnitTypeId = null;
      _availableUnitTypes.clear();
    });
    _loadUnitTypesForDosageForm(dosageFormId);
  }

  void _loadUnitTypesForDosageForm(int dosageFormId) {
    try {
      final unitTypes = ApiMedicationCreate.getUnitTypesForDosageForm(_availableDosageForms, dosageFormId);
      
      setState(() {
        _availableUnitTypes = unitTypes;
        if (_availableUnitTypes.length == 1) {
          _selectedUnitTypeId = _availableUnitTypes[0]['unit_type_id'];
        }
      });
      
      if (_availableUnitTypes.isEmpty) {
        _showSnackBar('ไม่พบหน่วยยาสำหรับรูปแบบยานี้', isError: true);
      }
    } catch (e) {
      setState(() {
        _availableUnitTypes.clear();
        _selectedUnitTypeId = null;
      });
      _showSnackBar('เกิดข้อผิดพลาดในการโหลดหน่วยยา', isError: true);
    }
  }

  // ======================== ส่วนการจัดการรูปภาพ ========================

Future<void> _pickImage() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      if (!mounted) return; // ตรวจสอบก่อนเรียก context

      setState(() {
        _selectedImage = File(image.path);
      });

      // ป้องกัน auto focus หลังเลือกรูป
      FocusScope.of(context).unfocus();
    }
  } catch (e) {
    if (!mounted) return; // ป้องกัน context crash
    _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ', isError: true);
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
      if (!mounted) return; // ตรวจสอบก่อนเรียก context

      setState(() {
        _selectedImage = File(image.path);
      });

      // ป้องกัน auto focus หลังถ่ายรูป
      FocusScope.of(context).unfocus();
    }
  } catch (e) {
    if (!mounted) return; // ตรวจสอบ context ก่อนเรียก
    _showSnackBar('เกิดข้อผิดพลาดในการถ่ายรูป', isError: true);
  }
}


  void _showImagePickerDialog() {
    // ซ่อนแป้นพิมพ์ก่อนเปิด Image Picker
    FocusScope.of(context).unfocus();
    
    final currentContext = context;
    showModalBottomSheet(
      context: currentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CreateMedicationWidget.buildImagePickerBottomSheet(
          onSelectFromGallery: () {
            Navigator.pop(context);
            _pickImage();
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
            // ป้องกัน auto focus หลังลบรูป
            FocusScope.of(context).unfocus();
          } : null,
        );
      },
    );
  }

  // ======================== ส่วนการตรวจสอบข้อมูล ========================

  bool _validateRequiredFields() {
    // ตรวจสอบชื่อยา
    if (_medicationNameController.text.trim().isEmpty) {
      setState(() {
        _nameFieldHasError = true; // ✅ ตั้งสถานะ error
      });
      _showSnackBar('กรุณากรอกชื่อยา', isError: true);
      _scrollToSection(_basicInfoKey);
      return false;
    }

    // ตรวจสอบรูปแบบยา
    if (_selectedDosageFormId == null) {
      _showSnackBar('กรุณาเลือกรูปแบบยา', isError: true);
      _scrollToSection(_dosageFormKey);
      return false;
    }

    // ตรวจสอบหน่วยยา
    if (_selectedUnitTypeId == null) {
      _showSnackBar('กรุณาเลือกหน่วยยา', isError: true);
      _scrollToSection(_unitTypeKey);
      return false;
    }

    // ตรวจสอบเวลาการกินยา
    if (selectedTimingIds.isEmpty) {
      _showSnackBar('กรุณาเลือกเวลาการกินยาอย่างน้อย 1 ช่วงเวลา', isError: true);
      _scrollToSection(_timingKey);
      return false;
    }

    return true;
  }

  // ฟังก์ชันเลื่อนหน้าจอไปยังส่วนที่ต้องการ
void _scrollToSection(GlobalKey key) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        alignment: 0.2,
      );
    }
  });
}


  // ======================== ส่วนการจัดการฟอร์ม ========================

  void _toggleTiming(int timingId) {
    setState(() {
      if (selectedTimingIds.contains(timingId)) {
        selectedTimingIds.remove(timingId);
      } else {
        selectedTimingIds.add(timingId);
      }
    });
  }

  Future<void> _submitForm() async {
    // ✅ ตรวจสอบข้อมูลที่จำเป็นก่อน form validation
    if (!_validateRequiredFields()) {
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiMedicationCreate.createMedication(
        medicationName: _medicationNameController.text.trim(),
        medicationNickname: _medicationNicknameController.text.trim().isEmpty 
            ? null 
            : _medicationNicknameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        dosageFormId: _selectedDosageFormId!,
        unitTypeId: _selectedUnitTypeId!,
        timingIds: selectedTimingIds,
        picture: _selectedImage,
      );

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'สร้างข้อมูลยาสำเร็จ!');
        _clearForm();
        
        if (mounted) {
          final currentContext = context;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(currentContext)) {
              Navigator.pop(currentContext, true);
            }
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'เกิดข้อผิดพลาด', isError: true);
        
        if (result['error'] == 'auth_required' || result['error'] == 'auth_expired') {
          if (mounted) {
            final currentContext = context;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Auth.logout(currentContext);
            });
          }
        }
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการบันทึกข้อมูล', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _medicationNameController.clear();
    _medicationNicknameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImage = null;
      selectedTimingIds.clear();
      _selectedDosageFormId = null;
      _selectedUnitTypeId = null;
      _availableUnitTypes.clear();
      _nameFieldHasError = false; // ✅ ล้างสถานะ error ด้วย
    });
  }

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

  // ======================== ส่วน UI ========================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ซ่อนแป้นพิมพ์เมื่อแตะที่พื้นที่ว่าง
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent, // เพิ่มบรรทัดนี้
      child: Scaffold(
        body: CreateMedicationWidget.buildGradientBackground(
          child: CustomScrollView(
            slivers: [
              // App Bar
              CreateMedicationWidget.buildSliverAppBar(
                onRefresh: _loadDosageForms,
                isLoading: _isLoadingDosageForms,
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), // ✅ ลด top padding จาก 100 เป็น 20 ให้พอดีกับแถบ
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // การ์ดข้อมูลพื้นฐาน
                        Container(
                          key: _basicInfoKey,
                          child: CreateMedicationWidget.buildBasicInfoCard(
                            nameController: _medicationNameController,
                            nicknameController: _medicationNicknameController,
                            descriptionController: _descriptionController,
                            nameFieldHasError: _nameFieldHasError, // ✅ ส่ง error state
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // การ์ดรูปภาพ
                        CreateMedicationWidget.buildImageCard(
                          selectedImage: _selectedImage,
                          onTap: _showImagePickerDialog,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // การ์ดรูปแบบยา
                        Container(
                          key: _dosageFormKey,
                          child: CreateMedicationWidget.buildDosageFormCard(
                            isLoading: _isLoadingDosageForms,
                            dosageForms: _availableDosageForms,
                            selectedDosageFormId: _selectedDosageFormId,
                            onDosageFormChanged: _onDosageFormChanged,
                            onRetryLoad: _loadDosageForms,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // การ์ดหน่วยยา
                        if (_selectedDosageFormId != null)
                          Container(
                            key: _unitTypeKey,
                            child: CreateMedicationWidget.buildUnitTypeCard(
                              unitTypes: _availableUnitTypes,
                              selectedUnitTypeId: _selectedUnitTypeId,
                              onUnitTypeChanged: (unitTypeId) {
                                setState(() {
                                  _selectedUnitTypeId = unitTypeId;
                                });
                              },
                            ),
                          ),
                        
                        if (_selectedDosageFormId != null)
                          const SizedBox(height: 24),
                        
                        // การ์ดเวลาการกินยา
                        Container(
                          key: _timingKey,
                          child: CreateMedicationWidget.buildTimingCard(
                            timingOptions: timingOptions,
                            selectedTimingIds: selectedTimingIds,
                            onTimingToggle: _toggleTiming,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // ปุ่มบันทึกและล้างข้อมูล
                        CreateMedicationWidget.buildActionButtons(
                          isLoading: _isLoading,
                          isLoadingDosageForms: _isLoadingDosageForms,
                          onSubmit: _submitForm,
                          onClear: _clearForm,
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}