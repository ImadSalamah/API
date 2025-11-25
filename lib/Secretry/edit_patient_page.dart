// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:dcs/config/api_config.dart';

class EditPatientPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  const EditPatientPage({super.key, required this.patient});

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? birthDate;
  String? gender;
  late TextEditingController firstNameController;
  late TextEditingController fatherNameController;
  late TextEditingController grandfatherNameController;
  late TextEditingController familyNameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController idNumberController;
  bool _isSaving = false;
  Uint8List? patientImage;
  Uint8List? iqrarImageBytes;
  Uint8List? idImageBytes;
  String? idImageUrl;
  String? iqrarImageUrl;
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = const Color(0xFF2A7A94);

  @override
  void initState() {
    // تاريخ الميلاد
    if (widget.patient['birthDate'] != null) {
      try {
        final b = widget.patient['birthDate'];
        if (b is String) {
          birthDate = DateTime.tryParse(b);
        } else if (b is int) {
          birthDate = DateTime.fromMillisecondsSinceEpoch(b);
        } else if (b is double) {
          birthDate = DateTime.fromMillisecondsSinceEpoch(b.toInt());
        }
      } catch (_) {
        birthDate = null;
      }
    }
    // الجنس
    if (widget.patient['gender'] != null && widget.patient['gender'].toString().isNotEmpty) {
      final g = widget.patient['gender'].toString().toLowerCase();
      if (g == 'male' || g == 'ذكر') {
        gender = 'male';
      } else if (g == 'female' || g == 'أنثى') {
        gender = 'female';
      } else {
        gender = null;
      }
    }
    // صورة الهوية
    final idImageValue = widget.patient['idImage'];
    if (idImageValue != null && idImageValue is String && idImageValue.isNotEmpty) {
      if (idImageValue.startsWith('http')) {
        idImageUrl = idImageValue;
      } else {
        try {
          idImageBytes = base64Decode(idImageValue);
        } catch (_) {
          idImageBytes = null;
        }
      }
    }
    super.initState();
    firstNameController = TextEditingController(text: widget.patient['firstName']?.toString() ?? '');
    fatherNameController = TextEditingController(text: widget.patient['fatherName']?.toString() ?? '');
    grandfatherNameController = TextEditingController(text: widget.patient['grandfatherName']?.toString() ?? '');
    familyNameController = TextEditingController(text: widget.patient['familyName']?.toString() ?? '');
    phoneController = TextEditingController(text: widget.patient['phone']?.toString() ?? '');
    addressController = TextEditingController(text: widget.patient['address']?.toString() ?? '');
    idNumberController = TextEditingController(text: widget.patient['idNumber']?.toString() ?? '');
    final imageValue = widget.patient['image'];
    if (imageValue != null && imageValue is String && imageValue.isNotEmpty) {
      try {
        patientImage = base64Decode(imageValue);
      } catch (_) {
        patientImage = null;
      }
    }
    // جلب صورة الإقرار من declaration أو من المرفقات
    String? iqrarBase64;
    final declarationValue = widget.patient['declaration'];
    if (declarationValue != null && declarationValue is String && declarationValue.isNotEmpty) {
      iqrarBase64 = declarationValue;
    } else if (widget.patient['attachments'] != null && widget.patient['attachments'] is Map) {
      final attachments = widget.patient['attachments'] as Map;
      for (final att in attachments.values) {
        if (att is Map && (att['isIqrar'] == true || att['isIqrar'] == 'true')) {
          if (att['base64'] != null && att['base64'].toString().isNotEmpty) {
            iqrarBase64 = att['base64'].toString();
            break;
          } else if (att['url'] != null && att['url'].toString().isNotEmpty) {
            iqrarImageUrl = att['url'].toString();
            break;
          }
        }
      }
    } else if (widget.patient['iqrar'] != null && widget.patient['iqrar'] is String && widget.patient['iqrar'].toString().isNotEmpty) {
      iqrarBase64 = widget.patient['iqrar'];
    }
    if (iqrarBase64 != null && iqrarBase64.isNotEmpty) {
      if (iqrarBase64.startsWith('http')) {
        iqrarImageUrl = iqrarBase64;
      } else {
        try {
          iqrarImageBytes = base64Decode(iqrarBase64);
        } catch (_) {
          iqrarImageBytes = null;
        }
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    fatherNameController.dispose();
    grandfatherNameController.dispose();
    familyNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    idNumberController.dispose();
    super.dispose();
  }

  Future<void> pickPatientImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        patientImage = bytes;
      });
    }
  }

  Future<void> pickIqrarImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        iqrarImageBytes = bytes;
        iqrarImageUrl = null;
      });
    }
  }

  Future<void> savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الجنس')),
      );
      return;
    }
    final idNum = idNumberController.text.trim();
    if (idNum.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهوية يجب أن يكون 9 أرقام')),
      );
      return;
    }
    final phoneNum = phoneController.text.trim();
    if (phoneNum.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف يجب أن يكون 9 أرقام على الأقل')),
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    // حفظ البيانات في قاعدة البيانات عبر API (مسموح فقط بالحقول التي يقبلها السيرفر)
    final patientId = widget.patient['PATIENT_UID'] ??
        widget.patient['patientUid'] ??
        widget.patient['patient_uid'] ??
        widget.patient['id'] ??
        widget.patient['userId'] ??
        widget.patient['USER_ID'] ??
        widget.patient['uid'] ??
        widget.patient['UID'];
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد معرف للمريض!')),
      );
      return;
    }
    // الحقول التي يقبلها السيرفر: firstName, fatherName, grandfatherName, familyName,
    // birthDate (yyyy-MM-dd), gender, address, phone, idImage, iqrar
    Map<String, dynamic> updateData = {
      'firstName': firstNameController.text.trim(),
      'fatherName': fatherNameController.text.trim(),
      'grandfatherName': grandfatherNameController.text.trim(),
      'familyName': familyNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
      'birthDate': birthDate != null
          ? "${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}"
          : null,
      'gender': gender,
    };
    // إضافة الصور فقط إذا تم تعديلها
    if (idImageBytes != null) {
      updateData['idImage'] = base64Encode(idImageBytes!);
    }
    if (iqrarImageBytes != null) {
      updateData['iqrar'] = base64Encode(iqrarImageBytes!);
    }
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات المريض')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل بيانات المريض'),
          backgroundColor: primaryColor,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = isWide ? constraints.maxWidth * 0.12 : 16;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // صور الهوية والإقرار
                    isWide
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildImageCard(
                                title: 'صورة الهوية',
                                imageBytes: idImageBytes,
                                imageUrl: idImageUrl,
                                onTap: _pickIdImage,
                                onPreview: () => _previewImage(idImageBytes, idImageUrl),
                              ),
                              _buildImageCard(
                                title: 'صورة الإقرار',
                                imageBytes: iqrarImageBytes,
                                imageUrl: iqrarImageUrl,
                                onTap: pickIqrarImage,
                                onPreview: () => _previewImage(iqrarImageBytes, iqrarImageUrl),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildImageCard(
                                title: 'صورة الهوية',
                                imageBytes: idImageBytes,
                                imageUrl: idImageUrl,
                                onTap: _pickIdImage,
                                onPreview: () => _previewImage(idImageBytes, idImageUrl),
                              ),
                              const SizedBox(height: 16),
                              _buildImageCard(
                                title: 'صورة الإقرار',
                                imageBytes: iqrarImageBytes,
                                imageUrl: iqrarImageUrl,
                                onTap: pickIqrarImage,
                                onPreview: () => _previewImage(iqrarImageBytes, iqrarImageUrl),
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),
                    // المعلومات الشخصية
                    _buildSection(
                      title: 'المعلومات الشخصية',
                      child: Column(
                        children: [
                          _buildTwoFieldsRow(
                            isWide: isWide,
                            first: _buildTextFormField(
                              controller: firstNameController,
                              label: 'الاسم الأول *',
                              icon: Icons.person,
                              validator: _requiredValidator,
                            ),
                            second: _buildTextFormField(
                              controller: fatherNameController,
                              label: 'اسم الأب *',
                              icon: Icons.person,
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTwoFieldsRow(
                            isWide: isWide,
                            first: _buildTextFormField(
                              controller: grandfatherNameController,
                              label: 'اسم الجد *',
                              icon: Icons.person,
                              validator: _requiredValidator,
                            ),
                            second: _buildTextFormField(
                              controller: familyNameController,
                              label: 'اسم العائلة *',
                              icon: Icons.person,
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTwoFieldsRow(
                            isWide: isWide,
                            first: _buildTextFormField(
                              controller: idNumberController,
                              label: 'رقم الهوية *',
                              icon: Icons.credit_card,
                              keyboardType: TextInputType.number,
                              maxLength: 9,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'هذا الحقل مطلوب';
                                if (val.length < 9) return 'رقم الهوية يجب أن يكون 9 أرقام';
                                return null;
                              },
                            ),
                            second: _buildDatePickerField(),
                          ),
                          const SizedBox(height: 12),
                          _buildGenderSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // معلومات التواصل
                    _buildSection(
                      title: 'معلومات التواصل',
                      child: Column(
                        children: [
                          _buildTwoFieldsRow(
                            isWide: isWide,
                            first: _buildTextFormField(
                              controller: phoneController,
                              label: 'رقم الهاتف *',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'هذا الحقل مطلوب';
                                if (val.length < 10) return 'رقم الهاتف يجب أن يكون 10 أرقام';
                                return null;
                              },
                            ),
                            second: _buildTextFormField(
                              controller: addressController,
                              label: 'العنوان *',
                              icon: Icons.location_on,
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : savePatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text(
                                'حفظ التعديلات',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTwoFieldsRow({required bool isWide, required Widget first, required Widget second}) {
    if (!isWide) {
      return Column(
        children: [
          first,
          const SizedBox(height: 10),
          second,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      validator: validator,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: birthDate ?? DateTime(2000, 1, 1),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => birthDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الميلاد *',
          prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
        child: Text(
          birthDate != null
              ? "${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}"
              : 'اختر التاريخ',
          style: TextStyle(color: birthDate == null ? Colors.grey[600] : Colors.black),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الجنس *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('ذكر'),
                value: 'male',
                groupValue: gender,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => gender = val),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('أنثى'),
                value: 'female',
                groupValue: gender,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => gender = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCard({
    required String title,
    required Uint8List? imageBytes,
    String? imageUrl,
    required VoidCallback onTap,
    required VoidCallback onPreview,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 170,
            height: 170,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageBytes != null || (imageUrl != null && imageUrl.isNotEmpty)
                  ? GestureDetector(
                      onTap: onPreview,
                      child: imageBytes != null
                          ? Image.memory(imageBytes, fit: BoxFit.cover)
                          : Image.network(imageUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          const SizedBox(height: 6),
                          Text('اضغط للإضافة', style: TextStyle(color: primaryColor)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _pickIdImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        idImageBytes = bytes;
        idImageUrl = null;
      });
    }
  }

  void _previewImage(Uint8List? bytes, String? url) {
    if (bytes == null && (url == null || url.isEmpty)) return;
    final Widget content = bytes != null
        ? Image.memory(bytes, fit: BoxFit.contain)
        : Image.network(url!, fit: BoxFit.contain);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(child: content),
      ),
    );
  }
}
