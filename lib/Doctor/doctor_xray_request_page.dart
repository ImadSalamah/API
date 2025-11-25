// ignore_for_file: deprecated_member_use, use_build_context_synchronously, empty_catches
import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'doctor_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import 'package:dcs/config/api_config.dart';

class DoctorXrayRequestPage extends StatefulWidget {
  const DoctorXrayRequestPage({super.key});

  @override
  State<DoctorXrayRequestPage> createState() => _DoctorXrayRequestPageState();
}

class _DoctorXrayRequestPageState extends State<DoctorXrayRequestPage> {
  // For occlusal selection
  String? _occlusalSelected;
  
  // ترتيب العرض فقط (الشكل)
  final List<String> periapicalGridDisplayLabels = [
    '28','27','26','25','24','23','22','21',
    '11','12','13','14','15','16','17','18',
    '38','37','36','35','34','33','32','31',
    '41','42','43','44','45','46','47','48',
  ];
  
  // ترتيب القيم الحقيقية (FDI)
  final List<String> periapicalGridValueLabels = [
    '18','17','16','15','14','13','12','11',
    '21','22','23','24','25','26','27','28',
    '48','47','46','45','44','43','42','41',
    '31','32','33','34','35','36','37','38',
  ];
  
  List<bool> periapicalGridSelected = List.filled(32, false);

  // Clinic selection
  String? _selectedClinic;
  final List<String> _clinics = [
    'Surgery', 'Pedo', 'Cons', 'Ortho', 'Prosth', 'Perio', 'Endo', 'Other',
  ];
  
  List<String>? allowedFeatures;
  List<Map<String, dynamic>> students = [];
  String? _selectedStudentId;
  String? _selectedStudentName;
  
  // البحث عن الطالب
  final TextEditingController _studentSearchController = TextEditingController();
  List<Map<String, dynamic>> foundStudents = [];
  int? selectedStudentIndex;
  String? studentError;
  bool isSearchingStudent = false;
  
  // البحث عن المريض
  final TextEditingController _patientSearchController = TextEditingController();
  String? _selectedPatientId;
  String? _selectedPatientName;
  List<Map<String, dynamic>> foundPatients = [];
  int? selectedPatientIndex;
  String? patientError;
  bool isSearchingPatient = false;

  String _xrayType = 'periapical';
  String? _jaw;
  String? _side;
  List<Map<String, String>> groupTeeth = [];

  String? _doctorName;
  String? _doctorImageUrl;
  String? _currentDoctorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentDoctorId();
  }

  Future<void> _getCurrentDoctorId() async {
    try {
      
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      String? providerId = languageProvider.currentUserId;
      
      final prefs = await SharedPreferences.getInstance();
      String? prefsId = prefs.getString('USER_ID');
      
      String? userDataString = prefs.getString('userData');
      String? userDataId;
      if (userDataString != null) {
        try {
          Map<String, dynamic> userData = json.decode(userDataString);
          userDataId = userData['USER_ID']?.toString();
        } catch (e) {
        }
      }

      _currentDoctorId = providerId ?? prefsId ?? userDataId;
      

      if (_currentDoctorId == null) {
        _redirectToLogin();
        return;
      }

      await _loadDoctorInfo();
      await _loadAllowedFeatures();
      await _loadStudents();
      
      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> _loadDoctorInfo() async {
    if (_currentDoctorId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$_currentDoctorId')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _doctorName = data['FULL_NAME']?.toString();
          _doctorImageUrl = data['IMAGE']?.toString();
        });
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _loadStudents() async {
    try {
      
      // استخدام الـ endpoint الجديد أولاً
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/students-with-users'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        
        setState(() {
          students = data.map((studentData) {
            // تأكد من أن جميع الحقول موجودة
            return {
              'id': studentData['id']?.toString() ?? studentData['userId']?.toString() ?? '',
              'userId': studentData['userId']?.toString() ?? studentData['id']?.toString() ?? '',
              'firstName': studentData['firstName']?.toString() ?? '',
              'fatherName': studentData['fatherName']?.toString() ?? '',
              'grandfatherName': studentData['grandfatherName']?.toString() ?? '',
              'familyName': studentData['familyName']?.toString() ?? '',
              'fullName': studentData['fullName']?.toString() ?? 'طالب بدون اسم',
              'username': studentData['username']?.toString() ?? '',
              'email': studentData['email']?.toString() ?? '',
              'phone': studentData['phone']?.toString() ?? '',
              'role': studentData['role']?.toString() ?? '',
              'isActive': studentData['isActive'] ?? 1,
              'idNumber': studentData['idNumber']?.toString() ?? '',
              'gender': studentData['gender']?.toString() ?? '',
              'birthDate': studentData['birthDate']?.toString() ?? '',
              'address': studentData['address']?.toString() ?? '',
              'image': studentData['image']?.toString() ?? '',
              'studentId': studentData['studentId']?.toString() ?? '',
              'universityId': studentData['universityId']?.toString() ?? studentData['studentUniversityId']?.toString() ?? '',
              'studentUniversityId': studentData['studentUniversityId']?.toString() ?? studentData['universityId']?.toString() ?? '',
              'studyYear': studentData['studyYear'] ?? studentData['STUDY_YEAR'],
            };
          }).toList();
        });

        // طباعة بيانات الطلاب للديبق
        for (var i = 0; i < students.length; i++) {
        }
        
      } else {
        
        // استخدام الطريقة القديمة كبديل
        await _loadStudentsFallback();
      }
    } catch (e) {
      // استخدام الطريقة القديمة كبديل
      await _loadStudentsFallback();
    }
  }

  // الطريقة البديلة إذا فشل الـ endpoint الجديد
  Future<void> _loadStudentsFallback() async {
    try {
      
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/students'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          students = data.map((student) {
            final mapped = Map<String, dynamic>.from(student);
            mapped['studyYear'] = student['studyYear'] ?? student['STUDY_YEAR'];
            return mapped;
          }).toList();
        });
        
        
        // طباعة بيانات الطلاب للديبق
        for (var i = 0; i < students.length; i++) {
          // ignore: unused_local_variable
          var student = students[i];
        }
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _loadAllowedFeatures() async {
    if (_currentDoctorId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$_currentDoctorId')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> features = [];
        
        try {
          if (data['ALLOWED_FEATURES'] != null) {
            if (data['ALLOWED_FEATURES'] is String) {
              features = List<String>.from(json.decode(data['ALLOWED_FEATURES']));
            } else if (data['ALLOWED_FEATURES'] is List) {
              features = List<String>.from(data['ALLOWED_FEATURES']);
            }
          }
        } catch (e) {
        }
        
        setState(() {
          allowedFeatures = features.isNotEmpty ? features : _getDefaultDoctorFeatures();
        });
        
      }
    } catch (e) {
      setState(() {
        allowedFeatures = _getDefaultDoctorFeatures();
      });
    }
  }

  List<String> _getDefaultDoctorFeatures() {
    return [
      'waiting_list',
      'clinical_procedures_form',
    ];
  }

  // البحث عن المريض
  Future<void> searchPatient() async {
    final query = _patientSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        foundPatients = [];
        patientError = null;
      });
      return;
    }

    setState(() { 
      isSearchingPatient = true;
      foundPatients = [];
      patientError = null;
    });

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/patients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final filtered = data.where((patient) {
          final firstName = patient['FIRSTNAME']?.toString().toLowerCase() ?? '';
          final fatherName = patient['FATHERNAME']?.toString().toLowerCase() ?? '';
          final grandfatherName = patient['GRANDFATHERNAME']?.toString().toLowerCase() ?? '';
          final familyName = patient['FAMILYNAME']?.toString().toLowerCase() ?? '';
          final fullName = patient['FULL_NAME']?.toString().toLowerCase() ?? '';
          
          final name = [
            firstName, fatherName, grandfatherName, familyName, fullName
          ].where((e) => e.isNotEmpty).join(' ');

          final idNumber = patient['IDNUMBER']?.toString().toLowerCase() ?? '';
          final patientId = patient['PATIENT_UID']?.toString().toLowerCase() ?? '';
          final medicalRecord = patient['MEDICAL_RECORD_NO']?.toString().toLowerCase() ?? '';

          final searchQuery = query.toLowerCase();
          
          return name.contains(searchQuery) || 
                 idNumber.contains(searchQuery) ||
                 patientId.contains(searchQuery) ||
                 medicalRecord.contains(searchQuery);
        }).toList();

        setState(() {
          foundPatients = filtered.cast<Map<String, dynamic>>();
          patientError = filtered.isEmpty ? 'لم يتم العثور على مريض' : null;
        });
      } else {
        setState(() { 
          patientError = 'خطأ في الخادم: ${response.statusCode}'; 
        });
      }
    } catch (e) {
      setState(() { 
        patientError = 'خطأ في الاتصال: $e'; 
      });
    } finally {
      setState(() { 
        isSearchingPatient = false; 
      });
    }
  }

  // البحث عن الطالب - المحسنة
  void searchStudent() {
    final query = _studentSearchController.text.trim();
    
    
    if (query.isEmpty) {
      setState(() {
        foundStudents = [];
        studentError = null;
        isSearchingStudent = false;
      });
      return;
    }

    setState(() { 
      isSearchingStudent = true;
      foundStudents = [];
      studentError = null;
    });

    // البحث في جميع الحقول النصية للطالب
    final filtered = students.where((student) {
      final searchQuery = query.toLowerCase();
      
      // البحث في جميع الحقول النصية
      final fieldsToSearch = [
        student['fullName']?.toString().toLowerCase() ?? '',
        student['firstName']?.toString().toLowerCase() ?? '',
        student['fatherName']?.toString().toLowerCase() ?? '',
        student['grandfatherName']?.toString().toLowerCase() ?? '',
        student['familyName']?.toString().toLowerCase() ?? '',
        student['universityId']?.toString().toLowerCase() ?? '',
        student['studentUniversityId']?.toString().toLowerCase() ?? '',
        student['id']?.toString().toLowerCase() ?? '',
        student['userId']?.toString().toLowerCase() ?? '',
        student['username']?.toString().toLowerCase() ?? '',
        student['idNumber']?.toString().toLowerCase() ?? '',
      ];
      
      bool found = fieldsToSearch.any((field) => field.contains(searchQuery));
      
      if (found) {
      }
      
      return found;
    }).toList();


    setState(() {
      foundStudents = filtered;
      studentError = filtered.isEmpty ? 'لم يتم العثور على طالب' : null;
      isSearchingStudent = false;
    });
  }

  Future<void> _submitRequest() async {
    if (_currentDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم التعرف على هوية الدكتور')));
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المريض أولاً')));
      return;
    }

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الطالب المسؤول عن الحالة')));
      return;
    }

    // التحقق من اختيار العيادة (إجباري)
    if (_selectedClinic == null || _selectedClinic!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العيادة')));
      return;
    }

    // التحقق من نوع الأشعة والحقول المطلوبة
    bool isValidRequest = true;
    String errorMessage = '';

    switch (_xrayType) {
      case 'periapical':
      case 'bitewing':
        final selectedTeeth = periapicalGridSelected.where((e) => e).length;
        if (selectedTeeth == 0) {
          isValidRequest = false;
          errorMessage = 'يرجى تحديد الأسنان المطلوبة';
        }
        break;
      case 'occlusal':
      case 'cbct':
        if (_occlusalSelected == null) {
          isValidRequest = false;
          errorMessage = 'يرجى اختيار الفك العلوي أو السفلي';
        }
        break;
    }

    if (!isValidRequest) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    // تجهيز البيانات للإرسال
    final bool requiresDeanApproval = _xrayType == 'cbct';
    final requestData = {
      'patientId': _selectedPatientId,
      'patientName': _selectedPatientName,
      'studentId': _selectedStudentId,
      'studentName': _selectedStudentName,
      'studentFullName': _selectedStudentName,
      'studentYear': _calculateStudentYear(),
      'xrayType': _xrayType,
      'jaw': _getJawValue(),
      'occlusalJaw': _xrayType == 'occlusal' ? _occlusalSelected : null,
      'cbctJaw': _xrayType == 'cbct' ? _occlusalSelected : null,
      'side': _side,
      'tooth': _toothController.text.isNotEmpty ? _toothController.text : null,
      'groupTeeth': groupTeeth.isNotEmpty ? groupTeeth : null,
      'periapicalTeeth': _getSelectedTeeth('periapical'),
      'bitewingTeeth': _getSelectedTeeth('bitewing'),
      'doctorName': _doctorName,
      'clinic': _selectedClinic,
      'doctorUid': _currentDoctorId,
      'requiresDeanApproval': requiresDeanApproval,
      'status': requiresDeanApproval ? 'awaiting_dean_approval' : 'pending',
    };


    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/xray_requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final successMessage = responseData['message'] ??
            (_xrayType == 'cbct'
                ? 'تم إرسال طلب CBCT وبانتظار موافقة العميد'
                : 'تم إرسال الطلب بنجاح');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)));
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الطلب')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب')));
    }
  }

  int? _calculateStudentYear() {
    if (_selectedStudentId == null) return null;
    
    // البحث عن الطالب المختار
    final student = students.firstWhere(
      (s) => (s['id'] ?? s['userId'])?.toString() == _selectedStudentId, 
      orElse: () => {},
    );
    
    // استخدم السنة المخزنة مباشرة إن وجدت
    final rawStudyYear = student['studyYear'] ?? student['STUDY_YEAR'];
    if (rawStudyYear != null) {
      final parsedYear = int.tryParse(rawStudyYear.toString());
      if (parsedYear != null && parsedYear > 0) {
        return parsedYear;
      }
    }
    
    // استخدام universityId أو studentUniversityId
    final universityId = student['universityId'] ?? student['studentUniversityId'];
    if (universityId == null) return null;
    
    final universityIdStr = universityId.toString();
    if (universityIdStr.length < 4) return null;
    
    try {
      final startYear = int.tryParse(universityIdStr.substring(0, 4));
      if (startYear == null) return null;
      
      final now = DateTime.now();
      int year = now.year - startYear + 1;
      if (now.month < 11) year -= 1;
      
      return year > 0 ? year : 1;
    } catch (e) {
      return null;
    }
  }

  List<String> _getSelectedTeeth(String type) {
    if ((type == 'periapical' && _xrayType != 'periapical') ||
        (type == 'bitewing' && _xrayType != 'bitewing')) {
      return [];
    }
    
    List<String> selected = [];
    for (int i = 0; i < periapicalGridSelected.length; i++) {
      if (periapicalGridSelected[i]) {
        selected.add(periapicalGridValueLabels[i]);
      }
    }
    return selected;
  }

  String? _getJawValue() {
    switch (_xrayType) {
      case 'single': return _jaw;
      case 'occlusal': return _occlusalSelected;
      case 'cbct': return _occlusalSelected;
      default: return null;
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPatientId = null;
      _selectedPatientName = null;
      selectedPatientIndex = null;
      _selectedStudentId = null;
      _selectedStudentName = null;
      selectedStudentIndex = null;
      _patientSearchController.clear();
      _studentSearchController.clear();
      _toothController.clear();
      _xrayType = 'periapical';
      _jaw = null;
      _side = null;
      _occlusalSelected = null;
      _selectedClinic = null;
      groupTeeth.clear();
      periapicalGridSelected = List.filled(32, false);
      foundPatients = [];
      foundStudents = [];
    });
  }

  Widget _buildToothBox(int index) {
    final label = periapicalGridDisplayLabels[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          periapicalGridSelected[index] = !periapicalGridSelected[index];
        });
      },
      child: Container(
        alignment: Alignment.center,
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: periapicalGridSelected[index] ? Colors.blue : Colors.grey[200],
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: periapicalGridSelected[index] ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  final TextEditingController _toothController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A7A94);
    const accentColor = Color(0xFF4AB8D8);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 20),
              Text('جاري تحميل البيانات...', style: TextStyle(color: primaryColor)),
            ],
          ),
        ),
      );
    }
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: allowedFeatures == null
            ? const Drawer(child: Center(child: CircularProgressIndicator()))
            : DoctorSidebar(
                primaryColor: primaryColor,
                accentColor: accentColor,
                userName: _doctorName,
                userImageUrl: _doctorImageUrl,
                parentContext: context,
                collapsed: false,
                translate: (ctx, key) => key,
                doctorUid: _currentDoctorId ?? '',
                allowedFeatures: allowedFeatures!,
              ),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(isArabic ? 'طلب أشعة' : 'Radiology Request'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بحث عن المريض
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بحث عن المريض',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _patientSearchController,
                                decoration: InputDecoration(
                                  labelText: isArabic ? 'ابحث عن المريض (اسم أو رقم هوية)' : 'Search patient (name or ID)',
                                  prefixIcon: const Icon(Icons.person_search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (_) => searchPatient(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: isSearchingPatient
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.search),
                              onPressed: isSearchingPatient ? null : searchPatient,
                            ),
                          ],
                        ),
                        if (patientError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              patientError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // نتائج البحث عن المريض
                if (foundPatients.isNotEmpty && selectedPatientIndex == null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نتائج البحث عن المرضى (${foundPatients.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...foundPatients.asMap().entries.map((entry) {
                            final i = entry.key;
                            final patient = entry.value;
                            
                            final patientName = [
                              patient['FIRSTNAME'] ?? '',
                              patient['FATHERNAME'] ?? '',
                              patient['GRANDFATHERNAME'] ?? '',
                              patient['FAMILYNAME'] ?? ''
                            ].where((e) => e != '').join(' ');
                            
                            final displayName = patientName.isNotEmpty 
                                ? patientName 
                                : patient['FULL_NAME'] ?? 'مريض بدون اسم';
                            
                            final idNumber = patient['IDNUMBER'] ?? patient['PATIENT_UID'] ?? 'لا يوجد';
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: selectedPatientIndex == i ? Colors.blue[50] : null,
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(displayName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('رقم الهوية: $idNumber'),
                                    if (patient['MEDICAL_RECORD_NO'] != null)
                                      Text('رقم الملف: ${patient['MEDICAL_RECORD_NO']}'),
                                  ],
                                ),
                                trailing: selectedPatientIndex == i
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  setState(() {
                                    selectedPatientIndex = i;
                                    _selectedPatientId = patient['PATIENT_UID'] ?? patient['IDNUMBER']?.toString();
                                    _selectedPatientName = displayName;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                // المريض المختار
                if (selectedPatientIndex != null && foundPatients.isNotEmpty && selectedPatientIndex! < foundPatients.length)
                  Card(
                    elevation: 2,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المريض المختار: $_selectedPatientName',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'رقم الهوية: ${foundPatients[selectedPatientIndex!]['IDNUMBER'] ?? ''}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                selectedPatientIndex = null;
                                _selectedPatientId = null;
                                _selectedPatientName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // نموذج طلب الأشعة
                if (_selectedPatientId != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بيانات طلب الأشعة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // اختيار العيادة (إجباري)
                          DropdownButtonFormField<String>(
                            value: _selectedClinic,
                            decoration: InputDecoration(
                              labelText: 'اختر العيادة *',
                              labelStyle: TextStyle(
                                color: _selectedClinic == null ? Colors.red : null,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _selectedClinic == null ? Colors.red : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _selectedClinic == null ? Colors.red : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: const Icon(Icons.star, color: Colors.red, size: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'العيادة مطلوبة';
                              }
                              return null;
                            },
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('اختر العيادة', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._clinics.map((clinic) => DropdownMenuItem<String>(
                                value: clinic,
                                child: Text(clinic),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedClinic = val;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // بحث عن الطالب
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اختر الطالب المسؤول عن الحالة:'),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _studentSearchController,
                                              decoration: InputDecoration(
                                                labelText: 'ابحث عن الطالب (اسم أو رقم جامعي)',
                                                prefixIcon: const Icon(Icons.school),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onChanged: (_) => searchStudent(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: isSearchingStudent
                                                ? const CircularProgressIndicator()
                                                : const Icon(Icons.search),
                                            onPressed: isSearchingStudent ? null : searchStudent,
                                          ),
                                        ],
                                      ),
                                      if (studentError != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            studentError!,
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // نتائج البحث عن الطالب
                              if (foundStudents.isNotEmpty && selectedStudentIndex == null)
                                Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'نتائج البحث عن الطلاب (${foundStudents.length})',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...foundStudents.asMap().entries.map((entry) {
                                          final i = entry.key;
                                          final student = entry.value;
                                          
                                          final fullName = student['fullName']?.toString() ?? 'طالب بدون اسم';
                                          final universityId = student['universityId']?.toString() ?? student['studentUniversityId']?.toString() ?? 'لا يوجد';
                                          
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            color: selectedStudentIndex == i ? Colors.blue[50] : null,
                                            child: ListTile(
                                              leading: const Icon(Icons.school),
                                              title: Text(
                                                fullName,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('الرقم الجامعي: $universityId'),
                                                  if (student['idNumber'] != null && student['idNumber'].toString().isNotEmpty)
                                                    Text('رقم الهوية: ${student['idNumber']}'),
                                                ],
                                              ),
                                              trailing: selectedStudentIndex == i
                                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                                              onTap: () {
                                                setState(() {
                                                  selectedStudentIndex = i;
                                                  _selectedStudentId = student['id']?.toString() ?? student['userId']?.toString();
                                                  _selectedStudentName = fullName;
                                                });
                                                FocusScope.of(context).unfocus();
                                              },
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),

                              // الطالب المختار
                              if (selectedStudentIndex != null && foundStudents.isNotEmpty && selectedStudentIndex! < foundStudents.length)
                                Card(
                                  elevation: 2,
                                  color: Colors.blue[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'الطالب المختار: $_selectedStudentName',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'الرقم الجامعي: ${foundStudents[selectedStudentIndex!]['universityId'] ?? foundStudents[selectedStudentIndex!]['studentUniversityId'] ?? ''}',
                                                style: TextStyle(color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              selectedStudentIndex = null;
                                              _selectedStudentId = null;
                                              _selectedStudentName = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // نوع الأشعة
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('نوع الأشعة:'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildXrayTypeButton('periapical', 'Periapical'),
                                  _buildXrayTypeButton('bitewing', 'Bitewing'),
                                  _buildXrayTypeButton('occlusal', 'Occlusal'),
                                  _buildXrayTypeButton('panoramic', 'Panoramic'),
                                  _buildXrayTypeButton('tmj', 'T.M.J.'),
                                  _buildXrayTypeButton('cbct', 'CBCT'),
                                  _buildXrayTypeButton('cephalometry', 'Cephalometry'),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // حسب نوع الأشعة المختار
                          _buildXrayTypeForm(),

                          const SizedBox(height: 20),

                          // زر الإرسال
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'إرسال الطلب',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXrayTypeButton(String type, String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _xrayType = type;
          if (type != 'periapical' && type != 'bitewing') {
            periapicalGridSelected = List.filled(32, false);
          }
          if (type != 'occlusal' && type != 'cbct') {
            _occlusalSelected = null;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _xrayType == type ? Colors.blue : Colors.grey[300],
        foregroundColor: _xrayType == type ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildXrayTypeForm() {
    switch (_xrayType) {
      case 'periapical':
      case 'bitewing':
        return _buildPeriapicalBitewingForm();
      case 'occlusal':
      case 'cbct':
        return _buildOcclusalCbctForm();
      case 'panoramic':
      case 'tmj':
      case 'cephalometry':
        return _buildSimpleTypeForm();
      default:
        return Container();
    }
  }

  Widget _buildPeriapicalBitewingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _xrayType == 'periapical' ? 'اختر الأسنان المطلوبة (Periapical)' : 'اختر الأسنان المطلوبة (Bitewing)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ...List.generate(8, (i) => _buildToothBox(i)),
                          const SizedBox(width: 8),
                          ...List.generate(8, (i) => _buildToothBox(i+8)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(8, (i) => _buildToothBox(i+16)),
                          const SizedBox(width: 8),
                          ...List.generate(8, (i) => _buildToothBox(i+24)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final selectedTeeth = [
                      for (int i = 0; i < periapicalGridSelected.length; i++)
                        if (periapicalGridSelected[i]) periapicalGridDisplayLabels[i]
                    ];
                    if (selectedTeeth.isEmpty) {
                      return Text(
                        'لم يتم تحديد أي أسنان بعد',
                        style: TextStyle(color: Colors.orange[700]),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الأسنان المحددة:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedTeeth.map((t) => Chip(
                            label: Text(t),
                            backgroundColor: Colors.blue[100],
                          )).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOcclusalCbctForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _xrayType == 'occlusal' ? 'اختر الفك (Occlusal)' : 'اختر الفك (CBCT)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _occlusalSelected = 'upper';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _occlusalSelected == 'upper' ? Colors.blue : Colors.grey[300],
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(60),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  child: const Text('Upper Jaw - الفك العلوي', style: TextStyle(fontSize: 16)),
                ),
              ),
              Container(
                width: double.infinity,
                height: 2,
                color: Colors.grey[400],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _occlusalSelected = 'lower';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _occlusalSelected == 'lower' ? Colors.blue : Colors.grey[300],
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(60),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  child: const Text('Lower Jaw - الفك السفلي', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        if (_occlusalSelected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _occlusalSelected == 'upper'
                  ? '✓ تم اختيار الفك العلوي'
                  : '✓ تم اختيار الفك السفلي',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleTypeForm() {
    String typeName = '';
    switch (_xrayType) {
      case 'panoramic':
        typeName = 'Panoramic';
        break;
      case 'tmj':
        typeName = 'T.M.J.';
        break;
      case 'cephalometry':
        typeName = 'Cephalometry';
        break;
    }

    return Card(
      elevation: 2,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'طلب أشعة $typeName - لا يحتاج إلى تحديد أسنان إضافية',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
