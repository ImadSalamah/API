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
  DateTime? birthDate;
  String? gender;
  late TextEditingController firstNameController;
  late TextEditingController fatherNameController;
  late TextEditingController grandfatherNameController;
  late TextEditingController familyNameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController idNumberController;
  late TextEditingController emailController;
  Uint8List? patientImage;
  Uint8List? iqrarImage;
  Uint8List? idImage;
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = const Color(0xFF2A7A94);

  @override
  void initState() {
    // تاريخ الميلاد
    if (widget.patient['birthDate'] != null) {
      try {
        birthDate = DateTime.fromMillisecondsSinceEpoch(widget.patient['birthDate']);
      } catch (_) {
        birthDate = null;
      }
    }
    // الجنس
    if (widget.patient['gender'] != null && widget.patient['gender'].toString().isNotEmpty) {
      gender = widget.patient['gender'].toString();
    }
    // صورة الهوية
    final idImageValue = widget.patient['idImage'];
    if (idImageValue != null && idImageValue is String && idImageValue.isNotEmpty) {
      try {
        idImage = base64Decode(idImageValue);
      } catch (_) {
        idImage = null;
      }
    }
    super.initState();
    firstNameController = TextEditingController(text: widget.patient['firstName'] ?? '');
    fatherNameController = TextEditingController(text: widget.patient['fatherName'] ?? '');
    grandfatherNameController = TextEditingController(text: widget.patient['grandfatherName'] ?? '');
    familyNameController = TextEditingController(text: widget.patient['familyName'] ?? '');
    phoneController = TextEditingController(text: widget.patient['phone'] ?? '');
    addressController = TextEditingController(text: widget.patient['address'] ?? '');
    idNumberController = TextEditingController(text: widget.patient['idNumber'] ?? '');
    emailController = TextEditingController(text: widget.patient['email'] ?? '');
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
          }
        }
      }
    } else if (widget.patient['iqrar'] != null && widget.patient['iqrar'] is String && widget.patient['iqrar'].toString().isNotEmpty) {
      iqrarBase64 = widget.patient['iqrar'];
    }
    if (iqrarBase64 != null && iqrarBase64.isNotEmpty) {
      try {
        iqrarImage = base64Decode(iqrarBase64);
      } catch (_) {
        iqrarImage = null;
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
    emailController.dispose();
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
        iqrarImage = bytes;
      });
    }
  }

  Future<void> savePatient() async {
    // حفظ البيانات في قاعدة البيانات عبر API
    final patientId = widget.patient['id'] ?? widget.patient['userId'];
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد معرف للمريض!')),
      );
      return;
    }
    Map<String, dynamic> updateData = {
      'firstName': firstNameController.text.trim(),
      'fatherName': fatherNameController.text.trim(),
      'grandfatherName': grandfatherNameController.text.trim(),
      'familyName': familyNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
      'idNumber': idNumberController.text.trim(),
      'email': emailController.text.trim(),
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'gender': gender,
    };
    // حفظ صورة الإقرار الجديدة في المرفقات
    Map<String, dynamic> attachments = {};
    if (widget.patient['attachments'] != null && widget.patient['attachments'] is Map) {
      attachments = Map<String, dynamic>.from(widget.patient['attachments']);
    }
    if (iqrarImage != null) {
      bool updated = false;
      attachments.forEach((key, value) {
        if (value is Map && (value['isIqrar'] == true || value['isIqrar'] == 'true')) {
          attachments[key] = {
            'base64': base64Encode(iqrarImage!),
            'isIqrar': true,
          };
          updated = true;
        }
      });
      if (!updated) {
        attachments['iqrar'] = {
          'base64': base64Encode(iqrarImage!),
          'isIqrar': true,
        };
      }
    }
    if (attachments.isNotEmpty) {
      updateData['attachments'] = attachments;
    }
    // حفظ صورة الهوية إذا تم تعديلها
    if (idImage != null) {
      updateData['idImage'] = base64Encode(idImage!);
    }
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/$patientId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات المريض')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل بيانات المريض'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
           
              Center(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: idImage != null
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.memory(idImage!, fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: idImage != null
                              ? Image.memory(
                                  idImage!,
                                  width: 180,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.credit_card, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () async {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              idImage = bytes;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit, size: 20, color: primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // صورة الإقرار
              Center(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: iqrarImage != null
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.memory(iqrarImage!, fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: iqrarImage != null
                              ? Image.memory(
                                  iqrarImage!,
                                  width: 180,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.description, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: pickIqrarImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                             
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit, size: 20, color: primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // حقل تاريخ الميلاد
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: birthDate ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => birthDate = picked);
                },
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: birthDate != null
                          ? "${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}"
                          : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // حقل الجنس
              DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: InputDecoration(
                  labelText: 'الجنس',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('ذكر')),
                  DropdownMenuItem(value: 'female', child: Text('أنثى')),
                ],
                onChanged: (val) => setState(() => gender = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'الاسم الأول', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: 'اسم الأب', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grandfatherNameController,
                decoration: InputDecoration(labelText: 'اسم الجد', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: familyNameController,
                decoration: InputDecoration(labelText: 'اسم العائلة', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'رقم الهاتف', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'العنوان', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idNumberController,
                decoration: InputDecoration(labelText: 'رقم الهوية', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'البريد الإلكتروني', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: savePatient,
                child: const Text('حفظ', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
