// ignore_for_file: deprecated_member_use

import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../services/oracle_storage.dart';
import '../../providers/language_provider.dart';
import 'package:flutter/services.dart';
import 'package:dcs/config/api_config.dart';
import '../utils/friendly_error.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  AddPatientPageState createState() => AddPatientPageState();
}

class AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  dynamic _idImage;
  dynamic _agreementImage;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  final ImagePicker _picker = ImagePicker();

  final Map<String, Map<String, String>> _translations = {
    'add_patient_title': {'ar': 'إضافة مريض جديد', 'en': 'Add New Patient'},
    'first_name': {'ar': 'الاسم الأول', 'en': 'First Name'},
    'father_name': {'ar': 'اسم الأب', 'en': 'Father Name'},
    'grandfather_name': {'ar': 'اسم الجد', 'en': 'Grandfather Name'},
    'family_name': {'ar': 'اسم العائلة', 'en': 'Family Name'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'phone': {'ar': 'رقم الهاتف', 'en': 'Phone Number'},
    'address': {'ar': 'مكان السكن', 'en': 'Address'},
    'add_patient_button': {'ar': 'إضافة المريض', 'en': 'Add Patient'},
    'add_id_photo': {'ar': 'إضافة صورة الهوية', 'en': 'Add ID Photo'},
    'add_agreement_photo': {'ar': 'إضافة صورة الإقرار', 'en': 'Add Agreement Photo'},
    'id_photo_title': {'ar': 'صورة الهوية', 'en': 'ID Photo'},
    'agreement_photo_title': {'ar': 'صورة الإقرار', 'en': 'Agreement Photo'},
    'personal_info': {'ar': 'المعلومات الشخصية', 'en': 'Personal Information'},
    'contact_info': {'ar': 'معلومات التواصل', 'en': 'Contact Information'},
    'required_field': {'ar': '*', 'en': '*'},
    'select_date': {'ar': 'اختر التاريخ', 'en': 'Select date'},
    'validation_required': {
      'ar': 'هذا الحقل مطلوب',
      'en': 'This field is required'
    },
    'validation_id_length': {
      'ar': 'رقم الهوية يجب أن يكون 9 أرقام',
      'en': 'ID must be 9 digits'
    },
    'validation_phone_length': {
      'ar': 'رقم الهاتف يجب أن يكون 10 أرقام',
      'en': 'Phone must be 10 digits'
    },
    'validation_gender': {
      'ar': 'الرجاء اختيار الجنس',
      'en': 'Please select gender'
    },
    'validation_id_image': {
      'ar': 'صورة الهوية مطلوبة',
      'en': 'ID image is required'
    },
    'validation_agreement_image': {
      'ar': 'صورة الإقرار مطلوبة',
      'en': 'Agreement image is required'
    },
    'add_success': {
      'ar': 'تمت إضافة المريض بنجاح',
      'en': 'Patient added successfully'
    },
    'add_error': {
      'ar': 'حدث خطأ أثناء إضافة المريض',
      'en': 'Error adding patient'
    },
    'image_error': {
      'ar': 'حدث خطأ في تحميل الصورة',
      'en': 'Image upload error'
    },
    'connection_error': {
      'ar': 'تعذر الاتصال، يرجى المحاولة مرة أخرى',
      'en': 'Unable to connect, please try again'
    },
    'uploading_image': {
      'ar': 'جاري رفع الصورة...',
      'en': 'Uploading image...'
    },
  };

  String _translate(String key, BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.isEnglish ? 'en' : 'ar';
    if (_translations.containsKey(key)) {
      final translationsForKey = _translations[key]!;
      if (translationsForKey.containsKey(langCode)) {
        return translationsForKey[langCode]!;
      } else if (translationsForKey.containsKey('en')) {
        return translationsForKey['en']!;
      } else {
        return key;
      }
    } else {
      return key;
    }
  }

  Future<void> _pickImage({required bool isId}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            if (isId) {
              _idImage = bytes;
            } else {
              _agreementImage = bytes;
            }
          });
        } else {
          if (!mounted) return;
          setState(() {
            if (isId) {
              _idImage = File(image.path);
            } else {
              _agreementImage = File(image.path);
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      final message = friendlyErrorMessage(
        defaultMessage: _translate('image_error', context),
        connectionMessage: _translate('connection_error', context),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  Future<String?> _uploadImageToOracleStorage(dynamic image, String prefix) async {
    if (image == null) return null;

    try {
      Uint8List imageBytes;
      
      if (kIsWeb) {
        imageBytes = image as Uint8List;
      } else {
        imageBytes = await (image as File).readAsBytes();
      }

      // Compress image first
      final compressedImage = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      final fileName = '$prefix-${DateTime.now().millisecondsSinceEpoch}.jpg';

      return uploadImageToOracle(
        Uint8List.fromList(compressedImage),
        fileName: fileName,
      );
    } catch (e) {
      if (!mounted) return null;
      final message = friendlyErrorMessage(
        defaultMessage: _translate('image_error', context),
        connectionMessage: _translate('connection_error', context),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return null;
    }
  }

  Future<void> _addPatient() async {
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_gender', context))),
      );
      return;
    }

    if (_idImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_id_image', context))),
      );
      return;
    }

    if (_agreementImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_agreement_image', context))),
      );
      return;
    }

    final idNumber = _idNumberController.text.trim();
    
    // التحقق من وجود رقم الهوية
    bool idExists = false;
    try {
      final checkResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients/check-id/$idNumber')
      );
      if (checkResponse.statusCode == 200) {
        final result = jsonDecode(checkResponse.body);
        idExists = result['exists'] == true;
      }
    } catch (e) {
      // تجاهل الخطأ والمتابعة
    }
    
    if (idExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهوية مسجل مسبقاً')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // رفع الصور إلى Oracle Object Storage
      String? idImageUrl = await _uploadImageToOracleStorage(_idImage, 'id');
      String? agreementImageUrl = await _uploadImageToOracleStorage(_agreementImage, 'agreement');

      if (idImageUrl == null || agreementImageUrl == null) {
        throw Exception('فشل في رفع الصور');
      }

      final patientData = {
        'firstName': _firstNameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'grandfatherName': _grandfatherNameController.text.trim(),
        'familyName': _familyNameController.text.trim(),
        'idNumber': idNumber,
        'birthDate': _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
        'gender': _gender,
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'idImage': idImageUrl,
        'agreementImage': agreementImageUrl,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/patients'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patientData),
      );
      
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('add_success', context))),
        );
        _resetForm();
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      final message = friendlyErrorMessage(
        defaultMessage: _translate('add_error', context),
        connectionMessage: _translate('connection_error', context),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _idImage = null;
      _agreementImage = null;
      _birthDate = null;
      _gender = null;
    });
  }

  Widget _buildImageWidget({required bool isId, required BuildContext context}) {
    final image = isId ? _idImage : _agreementImage;
    if (image == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            isId ? _translate('add_id_photo', context) : _translate('add_agreement_photo', context),
            style: TextStyle(color: primaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return kIsWeb
        ? Image.memory(image as Uint8List,
            width: 150, height: 150, fit: BoxFit.cover)
        : Image.file(image as File,
            width: 150, height: 150, fit: BoxFit.cover);
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderRadioButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            '${_translate('gender', context)} ${_translate('required_field', context)}',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(_translate('male', context)),
                value: 'male',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(_translate('female', context)),
                value: 'female',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSecretaryData();
  }

  Future<void> _loadSecretaryData() async {
    // هنا يمكنك جلب بيانات السكرتير من Provider أو SharedPreferences
    // هذا مثال افتراضي
    await Future.delayed(Duration.zero);
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection:
          languageProvider.isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_translate('add_patient_title', context)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                languageProvider.toggleLanguage();
              },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final double horizontalPadding = isWide ? constraints.maxWidth * 0.15 : 16;
            
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Images Row - الهوية والإقرار فقط
                    isWide
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // صورة الهوية
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(isId: true),
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: primaryColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildImageWidget(isId: true, context: context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _translate('id_photo_title', context),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              // صورة الإقرار
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(isId: false),
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: primaryColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildImageWidget(isId: false, context: context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _translate('agreement_photo_title', context),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // صورة الهوية
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(isId: true),
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: primaryColor),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _buildImageWidget(isId: true, context: context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _translate('id_photo_title', context),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // صورة الإقرار
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(isId: false),
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: primaryColor),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _buildImageWidget(isId: false, context: context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _translate('agreement_photo_title', context),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 30),

                    // المعلومات الشخصية
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _translate('personal_info', context),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // الصف الأول: الاسم الأول واسم الأب
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _firstNameController,
                                          labelText: '${_translate('first_name', context)} ${_translate('required_field', context)}',
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _fatherNameController,
                                          labelText: '${_translate('father_name', context)} ${_translate('required_field', context)}',
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _firstNameController,
                                        labelText: '${_translate('first_name', context)} ${_translate('required_field', context)}',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _fatherNameController,
                                        labelText: '${_translate('father_name', context)} ${_translate('required_field', context)}',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 15),

                          // الصف الثاني: اسم الجد واسم العائلة
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _grandfatherNameController,
                                          labelText: '${_translate('grandfather_name', context)} ${_translate('required_field', context)}',
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _familyNameController,
                                          labelText: '${_translate('family_name', context)} ${_translate('required_field', context)}',
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _grandfatherNameController,
                                        labelText: '${_translate('grandfather_name', context)} ${_translate('required_field', context)}',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _familyNameController,
                                        labelText: '${_translate('family_name', context)} ${_translate('required_field', context)}',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 15),

                          // الصف الثالث: رقم الهوية وتاريخ الميلاد
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _idNumberController,
                                          labelText: '${_translate('id_number', context)} ${_translate('required_field', context)}',
                                          keyboardType: TextInputType.number,
                                          maxLength: 9,
                                          prefixIcon: Icon(Icons.credit_card, color: accentColor),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                          ],
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            if (value.length < 9) {
                                              return _translate('validation_id_length', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: InkWell(
                                          onTap: _selectBirthDate,
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: '${_translate('birth_date', context)} ${_translate('required_field', context)}',
                                              labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
                                              prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                            ),
                                            child: Text(
                                              _birthDate == null
                                                  ? _translate('select_date', context)
                                                  : DateFormat('yyyy-MM-dd').format(_birthDate!),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: _birthDate == null ? Colors.grey[600] : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _idNumberController,
                                        labelText: '${_translate('id_number', context)} ${_translate('required_field', context)}',
                                        keyboardType: TextInputType.number,
                                        maxLength: 9,
                                        prefixIcon: Icon(Icons.credit_card, color: accentColor),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          if (value.length < 9) {
                                            return _translate('validation_id_length', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: InkWell(
                                        onTap: _selectBirthDate,
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: '${_translate('birth_date', context)} ${_translate('required_field', context)}',
                                            labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
                                            prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                          ),
                                          child: Text(
                                            _birthDate == null
                                                ? _translate('select_date', context)
                                                : DateFormat('yyyy-MM-dd').format(_birthDate!),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _birthDate == null ? Colors.grey[600] : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 15),

                          _buildGenderRadioButtons(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // معلومات التواصل
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _translate('contact_info', context),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _phoneController,
                                          labelText: '${_translate('phone', context)} ${_translate('required_field', context)}',
                                          keyboardType: TextInputType.phone,
                                          maxLength: 10,
                                          prefixIcon: Icon(Icons.phone, color: accentColor),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                          ],
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            if (value.length < 10) {
                                              return _translate('validation_phone_length', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _addressController,
                                          labelText: '${_translate('address', context)} ${_translate('required_field', context)}',
                                          prefixIcon: Icon(Icons.location_on, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required', context);
                                            }
                                            return null;
                                          },
                                          context: context,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _phoneController,
                                        labelText: '${_translate('phone', context)} ${_translate('required_field', context)}',
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        prefixIcon: Icon(Icons.phone, color: accentColor),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          if (value.length < 10) {
                                            return _translate('validation_phone_length', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _addressController,
                                        labelText: '${_translate('address', context)} ${_translate('required_field', context)}',
                                        prefixIcon: Icon(Icons.location_on, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required', context);
                                          }
                                          return null;
                                        },
                                        context: context,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // زر إضافة المريض
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _translate('add_patient_button', context),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _familyNameController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
