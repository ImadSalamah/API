// ignore_for_file: use_build_context_synchronously, empty_catches, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../providers/language_provider.dart';
import '../../providers/secretary_provider.dart';
import '../Secretry/secretary_sidebar.dart';
import 'package:dcs/config/api_config.dart';

class PatientFilesPage extends StatefulWidget {
  final String userRole;
  const PatientFilesPage({super.key, required this.userRole});

  @override
  State<PatientFilesPage> createState() => _PatientFilesPageState();
}

class _PatientFilesPageState extends State<PatientFilesPage> {
  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);

  List<Map<String, dynamic>> allPatients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // بيانات تجريبية للتأكد من أن الواجهة تعمل
  final List<Map<String, dynamic>> _mockPatients = [
    {
      'id': '429449042',
      'patient_uid': '429449042',
      'firstName': 'سيف الدين',
      'fatherName': 'محمد',
      'grandfatherName': 'عبد اللطيف',
      'familyName': 'سليمان',
      'idNumber': '429449042',
      'birthDate': '2006-10-31T22:00:00.000Z',
      'gender': 'MALE',
      'address': 'قلقيلية',
      'phone': '0599595656',
      'createdAt': '2025-11-02T08:02:17.000Z',
      'status': 'EXAMINED',
      'iqrar': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1762077696/a5raliyxggcwvpaoacao.png',
      'image': 'https://example.com/default-image.png',
      'idImage': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1762077674/kw6mhypurfpttmf0cun3.png',
      'approvedDate': '2025-11-02T08:02:17.000Z',
      'approvedBy': 'system',
      'medicalRecordNo': 'MR737928',
    },
    {
      'id': '403493495',
      'patient_uid': '403493495',
      'firstName': 'بيوتي',
      'fatherName': 'بيوتي',
      'grandfatherName': 'بيوتي',
      'familyName': 'بيوتي',
      'idNumber': '403493495',
      'birthDate': '2018-10-26T21:00:00.000Z',
      'gender': 'MALE',
      'address': 'j2e1',
      'phone': '1111331313',
      'createdAt': '2025-10-28T08:52:26.000Z',
      'status': 'EXAMINED',
      'iqrar': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1761646908/myyvahps8dybmyqezxv5.png',
      'image': 'https://example.com/default-image.png',
      'idImage': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1761646902/uqwwufszaabzm44ezakv.png',
      'approvedDate': '2025-10-28T08:52:26.000Z',
      'approvedBy': 'system',
      'medicalRecordNo': 'MR746339',
    },
    {
      'id': '409349439',
      'patient_uid': '409349439',
      'firstName': 'سمير',
      'fatherName': 'سامح',
      'grandfatherName': 'محمد',
      'familyName': 'غنام',
      'idNumber': '409349439',
      'birthDate': '2000-10-26T22:00:00.000Z',
      'gender': 'MALE',
      'address': 'عقابا',
      'phone': '0596586586',
      'createdAt': '2025-10-28T08:17:28.000Z',
      'status': 'EXAMINED',
      'iqrar': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1761646609/ix45rv6bhxnnxcnonmpx.png',
      'image': 'https://example.com/default-image.png',
      'idImage': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1761646603/zmleobbgzqe3n4rchcqj.png',
      'approvedDate': '2025-10-28T08:17:28.000Z',
      'approvedBy': 'system',
      'medicalRecordNo': 'MR648599',
    },
    {
      'id': '409584723',
      'patient_uid': '409584723',
      'firstName': 'احمد',
      'fatherName': 'روحي',
      'grandfatherName': 'احمد',
      'familyName': 'صالح',
      'idNumber': '409584723',
      'birthDate': '2003-10-22T22:00:00.000Z',
      'gender': 'MALE',
      'address': 'aqpkwq',
      'phone': '0954854786',
      'createdAt': '2025-10-24T05:51:56.000Z',
      'status': 'EXAMINED',
      'iqrar': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1761295661/d5fpuhtqhszcwf3ux27k.png',
      'image': 'https://example.com/default-image.png',
      'idImage': 'https://res.cloudinary.com/dgc3hbhva/image/upload/v1761295654/inyqqjsu4qbz0y1prjpr.png',
      'approvedDate': '2025-10-24T05:51:56.000Z',
      'approvedBy': 'system',
      'medicalRecordNo': 'MR916222',
    }
  ];

  final Map<String, Map<String, String>> _translations = {
    'patient_files': {'ar': 'ملفات المرضى', 'en': 'Patient Files'},
    'all_patients': {'ar': 'جميع المرضى', 'en': 'All Patients'},
    'name': {'ar': 'الاسم', 'en': 'Name'},
    'phone': {'ar': 'الهاتف', 'en': 'Phone'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'medical_record': {'ar': 'رقم الملف الطبي', 'en': 'Medical Record'},
    'view_details': {'ar': 'عرض التفاصيل', 'en': 'View Details'},
    'no_patients': {'ar': 'لا يوجد مرضى', 'en': 'No patients found'},
    'error_loading': {'ar': 'خطأ في تحميل البيانات', 'en': 'Error loading data'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'search_hint': {'ar': 'ابحث بالاسم أو رقم الهوية...', 'en': 'Search by name or ID...'},
    'id_image': {'ar': 'صورة الهوية', 'en': 'ID Image'},
    'iqrar_image': {'ar': 'صورة الإقرار', 'en': 'IQRAR Image'},
    'patient_details': {'ar': 'تفاصيل المريض', 'en': 'Patient Details'},
    'add_to_waiting_list': {'ar': 'إضافة إلى قائمة الانتظار', 'en': 'Add to Waiting List'},
    'select_date': {'ar': 'اختر التاريخ', 'en': 'Select Date'},
    'add_notes': {'ar': 'إضافة ملاحظات', 'en': 'Add Notes'},
    'add': {'ar': 'إضافة', 'en': 'Add'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'added_to_waiting': {'ar': 'تمت الإضافة إلى قائمة الانتظار', 'en': 'Added to waiting list'},
    'close': {'ar': 'إغلاق', 'en': 'Close'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'address': {'ar': 'العنوان', 'en': 'Address'},
    'status': {'ar': 'الحالة', 'en': 'Status'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
  };

  @override
  void initState() {
    super.initState();
    // استخدام البيانات التجريبية أولاً للتأكد من أن الواجهة تعمل
    _loadWithMockData();
    // ثم محاولة تحميل البيانات الحقيقية
    _loadPatientsData();
    _searchController.addListener(_filterPatients);
    if (widget.userRole == 'secretary') {
      _loadSecretaryDataToProvider();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadWithMockData() {
    setState(() {
      allPatients = _mockPatients;
      filteredPatients = List.from(_mockPatients);
      _isLoading = false;
    });
  }

  Future<void> _loadPatientsData() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/all-patients'));
      
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is List && responseData.isNotEmpty) {
          final patientsList = List<Map<String, dynamic>>.from(responseData);
          
          
          setState(() {
            allPatients = patientsList;
            filteredPatients = List.from(patientsList);
            _isLoading = false;
          });
        } else {
        }
      } else {
      }
    } catch (e) {
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredPatients = allPatients.where((patient) {
        final fullName = _getFullName(patient).toLowerCase();
        final idNumber = patient['idNumber']?.toString().toLowerCase() ?? '';
        final phone = patient['phone']?.toString().toLowerCase() ?? '';
        final medicalRecord = patient['medicalRecordNo']?.toString().toLowerCase() ?? '';

        return fullName.contains(query) ||
            idNumber.contains(query) ||
            phone.contains(query) ||
            medicalRecord.contains(query);
      }).toList();
    });
    
  }

  String _getFullName(Map<String, dynamic> patient) {
    final firstName = patient['firstName']?.toString().trim() ?? '';
    final fatherName = patient['fatherName']?.toString().trim() ?? '';
    final grandfatherName = patient['grandfatherName']?.toString().trim() ?? '';
    final familyName = patient['familyName']?.toString().trim() ?? '';

    return [
      if (firstName.isNotEmpty) firstName,
      if (fatherName.isNotEmpty) fatherName,
      if (grandfatherName.isNotEmpty) grandfatherName,
      if (familyName.isNotEmpty) familyName,
    ].join(' ');
  }

  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.currentLocale.languageCode;
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showIDImage(String imageUrl) {
    if (imageUrl.isEmpty || imageUrl == 'null') {
      _showErrorSnackBar('لا توجد صورة هوية');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translate(context, 'id_image')),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('تعذر تحميل الصورة'),
                ],
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_translate(context, 'close')),
          ),
        ],
      ),
    );
  }

  void _showIqrarImage(String imageUrl) {
    if (imageUrl.isEmpty || imageUrl == 'null') {
      _showErrorSnackBar('لا توجد صورة إقرار');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translate(context, 'iqrar_image')),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('تعذر تحميل الصورة'),
                ],
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_translate(context, 'close')),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _translate(context, 'patient_details'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الاسم', _getFullName(patient)),
              _buildDetailRow('رقم الهوية', patient['idNumber']?.toString() ?? ''),
              _buildDetailRow('رقم الملف الطبي', patient['medicalRecordNo']?.toString() ?? ''),
              _buildDetailRow('الجنس', patient['gender']?.toString() ?? ''),
              _buildDetailRow('الهاتف', patient['phone']?.toString() ?? ''),
              _buildDetailRow('العنوان', patient['address']?.toString() ?? ''),
              _buildDetailRow('الحالة', patient['status']?.toString() ?? 'active'),
              if (patient['birthDate'] != null) 
                _buildDetailRow('تاريخ الميلاد', _formatDate(patient['birthDate'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_translate(context, 'close')),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        return date.split('T')[0];
      }
      return date.toString().split(' ')[0];
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            value.isNotEmpty ? value : 'غير محدد',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _addToWaitingList(Map<String, dynamic> patient) async {
    DateTime? selectedDate = DateTime.now();
    String notes = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            _translate(context, 'add_to_waiting_list'),
            style: TextStyle(color: primaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getFullName(patient),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
              ),
              const SizedBox(height: 16),
              
              Text(_translate(context, 'select_date')),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate!,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${selectedDate!.toLocal()}".split(' ')[0],
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, size: 20, color: primaryColor),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(_translate(context, 'add_notes')),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) => notes = value,
                decoration: InputDecoration(
                  hintText: _translate(context, 'add_notes'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_translate(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null) {
                  Navigator.pop(context);
                  await _performAddToWaitingList(patient, selectedDate!, notes);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(_translate(context, 'add')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAddToWaitingList(
      Map<String, dynamic> patient, DateTime appointmentDate, String notes) async {
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/waitingList'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'PATIENT_UID': patient['id'],
          'PATIENT_NAME': _getFullName(patient),
          'APPOINTMENT_DATE': appointmentDate.toIso8601String(),
          'STATUS': 'WAITING',
          'PHONE': patient['phone'] ?? '',
          'NOTES': notes.isNotEmpty ? notes : 'تمت الإضافة من قبل السكرتيرة',
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessSnackBar(_translate(context, 'added_to_waiting'));
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(errorData['message'] ?? 'فشل الإضافة إلى قائمة الانتظار');
      }
    } catch (e) {
      debugPrint('Error adding to waiting list: $e');
      _showErrorSnackBar('خطأ في الإضافة إلى قائمة الانتظار: $e');
    }
  }

  Future<void> _loadSecretaryDataToProvider() async {
    // Implementation depends on your provider structure
  }

  Widget _buildSidebar(BuildContext context) {
    if (widget.userRole == 'secretary') {
      final secretaryProvider = Provider.of<SecretaryProvider>(context, listen: false);
      return SecretarySidebar(
        primaryColor: primaryColor,
        accentColor: accentColor,
        parentContext: context,
        translate: _translate,
        userRole: widget.userRole,
        userName: secretaryProvider.fullName,
        userImageUrl: secretaryProvider.imageBase64,
      );
    }
    return const SizedBox.shrink();
  }

  void _handlePopupMenuSelection(String value, Map<String, dynamic> patient) {
    switch (value) {
      case 'add_to_waiting':
        _addToWaitingList(patient);
        break;
      case 'view_details':
        _showPatientDetails(patient);
        break;
      case 'view_id_image':
        _showIDImage(patient['idImage'] ?? '');
        break;
      case 'view_iqrar_image':
        _showIqrarImage(patient['iqrar'] ?? '');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl, // تأكد من اتجاه النص
      child: Scaffold(
        appBar: AppBar(
          title: Text(_translate(context, 'patient_files'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: primaryColor,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPatientsData,
              tooltip: _translate(context, 'retry'),
            ),
          ],
        ),
        drawer: _buildSidebar(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: _translate(context, 'search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Results count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${filteredPatients.length} ${_translate(context, 'all_patients')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Patients List
                    Expanded(
                      child: filteredPatients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _translate(context, 'no_patients'),
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchController.text.isNotEmpty)
                                    Column(
                                      children: [
                                        Text(
                                          'لم يتم العثور على نتائج للبحث: "${_searchController.text}"',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            _filterPatients();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('مسح البحث'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = filteredPatients[index];
                                return _buildPatientCard(patient);
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Name and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFullName(patient),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (patient['medicalRecordNo'] != null && patient['medicalRecordNo'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'الملف الطبي: ${patient['medicalRecordNo']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePopupMenuSelection(value, patient),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'add_to_waiting',
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(_translate(context, 'add_to_waiting_list')),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'view_details',
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(_translate(context, 'view_details')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_id_image',
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card, size: 20),
                          const SizedBox(width: 8),
                          Text(_translate(context, 'id_image')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_iqrar_image',
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Text(_translate(context, 'iqrar_image')),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: primaryColor),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Patient Details
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (patient['idNumber'] != null && patient['idNumber'].toString().isNotEmpty)
                  _buildInfoChip(
                    Icons.credit_card,
                    '${_translate(context, 'id_number')}: ${patient['idNumber']}',
                  ),
                if (patient['phone'] != null && patient['phone'].toString().isNotEmpty)
                  _buildInfoChip(
                    Icons.phone,
                    '${_translate(context, 'phone')}: ${patient['phone']}',
                  ),
                if (patient['gender'] != null && patient['gender'].toString().isNotEmpty)
                  _buildInfoChip(
                    Icons.person,
                    '${_translate(context, 'gender')}: ${patient['gender']}',
                  ),
                if (patient['status'] != null && patient['status'].toString().isNotEmpty)
                  _buildInfoChip(
                    Icons.circle,
                    '${_translate(context, 'status')}: ${patient['status']}',
                    color: patient['status'] == 'active' ? Colors.green : Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color ?? primaryColor),
      label: Text(
        text,
        style: TextStyle(fontSize: 12, color: color ?? Colors.black87),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey[50],
      side: BorderSide(color: Colors.grey[300]!),
    );
  }
}