// ignore_for_file: deprecated_member_use, use_build_context_synchronously, empty_catches
import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'admin_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import 'package:dcs/config/api_config.dart';
import 'dart:async';

class AdminXrayRequestPage extends StatefulWidget {
  const AdminXrayRequestPage({super.key});

  @override
  State<AdminXrayRequestPage> createState() => _AdminXrayRequestPageState();
}

class _AdminXrayRequestPageState extends State<AdminXrayRequestPage> {
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
  
  List<Map<String, dynamic>> students = [];
  String? _selectedStudentId;
  String? _selectedStudentName;
  
  // البحث عن الطالب
  final TextEditingController _studentSearchController = TextEditingController();
  List<Map<String, dynamic>> foundStudents = [];
  int? selectedStudentIndex;
  String? studentError;
  bool isSearchingStudent = false;
  Timer? _studentSearchDebounce;
  final int _studentResultsLimit = 10;
  int _filteredStudentsCount = 0;
  
  // البحث عن المريض
  final TextEditingController _patientSearchController = TextEditingController();
  String? _selectedPatientId;
  String? _selectedPatientName;
  List<Map<String, dynamic>> foundPatients = [];
  int? selectedPatientIndex;
  String? patientError;
  bool isSearchingPatient = false;
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  List<Map<String, dynamic>> _myPendingRequests = [];
  bool _isLoadingRequests = false;
  String? _editingRequestId;
  String? _editingRequestStatus;

  String _xrayType = 'periapical';
  String? _jaw;
  String? _side;
  List<Map<String, String>> groupTeeth = [];

  String? _adminName;
  String? _adminImageUrl;
  String? _currentAdminId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentAdminId();
  }

  Future<void> _getCurrentAdminId() async {
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

      _currentAdminId = providerId ?? prefsId ?? userDataId;
      _selectedDoctorId = _currentAdminId;
      

      if (_currentAdminId == null) {
        _redirectToLogin();
        return;
      }

      await _loadAdminInfo();
      await _loadStudents();
      await _loadMyPendingRequests();
      
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

  Future<void> _loadAdminInfo() async {
    if (_currentAdminId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$_currentAdminId')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _adminName = data['FULL_NAME']?.toString() ?? data['fullName']?.toString();
          _adminImageUrl = data['IMAGE']?.toString() ?? data['image']?.toString();
          _selectedDoctorName = _adminName;
          _selectedDoctorId ??= _currentAdminId;
        });
      } else {
      }
    } catch (e) {
    }
  }

  // لا يوجد اختيار طبيب؛ سيتم استخدام بيانات الإدمن نفسه

  Future<void> _loadStudents() async {
    try {
      
      // استخدام الـ endpoint الجديد أولاً
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/students-with-users'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        
        setState(() {
          students = data.map((studentData) {
            // تأكد من أن جميع الحقول موجودة
            final mapped = {
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
            mapped['searchBlob'] = _buildStudentSearchBlob(mapped);
            return mapped;
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

  Future<void> _loadMyPendingRequests() async {
    if (_currentAdminId == null) return;

    setState(() => _isLoadingRequests = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/xray_requests'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> mapped = data
            .map<Map<String, dynamic>>((e) => _mapRequest(e))
            .where((req) {
              final doctorUid = req['doctor_uid']?.toString() ?? '';
              final doctorName = req['doctor_name']?.toString() ?? '';
              final belongsToAdmin = doctorUid.isNotEmpty
                  ? doctorUid == _currentAdminId
                  : (_adminName != null && _adminName == doctorName);
              final status = (req['status'] ?? '').toString().toLowerCase();
              final isPending = status != 'completed';
              return belongsToAdmin && isPending;
            })
            .toList();

        setState(() => _myPendingRequests = mapped);
      } else {
        setState(() => _myPendingRequests = []);
      }
    } catch (_) {
      setState(() => _myPendingRequests = []);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
  }

  Map<String, dynamic> _mapRequest(dynamic raw) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(raw as Map);
    return {
      'request_id': data['REQUEST_ID'] ?? data['id'] ?? data['requestId'],
      'patient_id': data['PATIENT_ID'] ?? data['patientId'],
      'patient_name': data['PATIENT_NAME'] ?? data['patientName'],
      'student_id': data['STUDENT_ID'] ?? data['studentId'],
      'student_name': data['STUDENT_NAME'] ?? data['studentName'],
      'student_full_name': data['STUDENT_FULL_NAME'] ?? data['studentFullName'],
      'student_year': data['STUDENT_YEAR'] ?? data['studentYear'],
      'xray_type': data['XRAY_TYPE'] ?? data['xrayType'],
      'jaw': data['JAW'],
      'occlusal_jaw': data['OCCLUSAL_JAW'],
      'cbct_jaw': data['CBCT_JAW'],
      'side': data['SIDE'],
      'tooth': data['TOOTH'],
      'group_teeth': data['GROUP_TEETH'],
      'periapical_teeth': data['PERIAPICAL_TEETH'],
      'bitewing_teeth': data['BITEWING_TEETH'],
      'timestamp': data['TIMESTAMP'] ?? data['createdAt'],
      'status': data['STATUS'] ?? data['status'],
      'doctor_name': data['DOCTOR_NAME'] ?? data['doctorName'],
      'clinic': data['CLINIC'] ?? data['clinic'],
      'doctor_uid': data['DOCTOR_UID'] ?? data['doctorUid'],
    };
  }

  List<String> _parseTeethList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  void _prefillFormFromRequest(Map<String, dynamic> request) {
    final xrayType = (request['xray_type'] ?? '').toString().toLowerCase();
    final periapicalTeeth = _parseTeethList(request['periapical_teeth']);
    final bitewingTeeth = _parseTeethList(request['bitewing_teeth']);
    final groupTeethRaw = request['group_teeth'];
    List<Map<String, String>> parsedGroupTeeth = [];
    if (groupTeethRaw is List) {
      parsedGroupTeeth = groupTeethRaw
          .whereType<Map>()
          .map((e) => e.map((key, value) => MapEntry(key.toString(), value.toString())))
          .toList();
    } else if (groupTeethRaw is String && groupTeethRaw.isNotEmpty) {
      try {
        final decoded = json.decode(groupTeethRaw);
        if (decoded is List) {
          parsedGroupTeeth = decoded
              .whereType<Map>()
              .map((e) => e.map((key, value) => MapEntry(key.toString(), value.toString())))
              .toList();
        }
      } catch (_) {}
    }

    setState(() {
      _editingRequestId = request['request_id']?.toString();
      _editingRequestStatus = request['status']?.toString();
      _selectedPatientId = request['patient_id']?.toString();
      _selectedPatientName = request['patient_name']?.toString();
      selectedPatientIndex = null;
      foundPatients = [];

      _selectedStudentId = request['student_id']?.toString();
      _selectedStudentName = request['student_name']?.toString();
      selectedStudentIndex = null;
      foundStudents = [];

      _selectedClinic = request['clinic']?.toString();
      _selectedDoctorId = request['doctor_uid']?.toString();
      _selectedDoctorName = request['doctor_name']?.toString();

      _xrayType = xrayType.isNotEmpty ? xrayType : 'periapical';
      _jaw = request['jaw']?.toString();
      _side = request['side']?.toString();
      _occlusalSelected = request['occlusal_jaw']?.toString() ??
          request['cbct_jaw']?.toString() ??
          request['jaw']?.toString();
      _toothController.text = request['tooth']?.toString() ?? '';
      groupTeeth = parsedGroupTeeth;

      periapicalGridSelected = List.filled(32, false);
      final selectedTeeth = _xrayType == 'bitewing' ? bitewingTeeth : periapicalTeeth;
      for (final tooth in selectedTeeth) {
        final idx = periapicalGridValueLabels.indexOf(tooth);
        if (idx != -1) {
          periapicalGridSelected[idx] = true;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحميل الطلب للتعديل')),
    );
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
            mapped['searchBlob'] = _buildStudentSearchBlob(mapped);
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
    _studentSearchDebounce?.cancel();
    _studentSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      _performStudentSearch(_studentSearchController.text.trim());
    });
  }

  void _performStudentSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        foundStudents = [];
        studentError = null;
        isSearchingStudent = false;
        _filteredStudentsCount = 0;
      });
      return;
    }

    setState(() { 
      isSearchingStudent = true;
      foundStudents = [];
      studentError = null;
      _filteredStudentsCount = 0;
    });

    final searchQuery = query.toLowerCase();

    final filtered = students.where((student) {
      final blob = student['searchBlob'] as String? ?? '';
      return blob.contains(searchQuery);
    }).toList();

    setState(() {
      _filteredStudentsCount = filtered.length;
      foundStudents = filtered.take(_studentResultsLimit).toList();
      studentError = filtered.isEmpty ? 'لم يتم العثور على طالب' : null;
      isSearchingStudent = false;
    });
  }

  String _buildStudentSearchBlob(Map<String, dynamic> student) {
    final parts = [
      student['fullName'],
      student['firstName'],
      student['fatherName'],
      student['grandfatherName'],
      student['familyName'],
      student['universityId'],
      student['studentUniversityId'],
      student['id'],
      student['userId'],
      student['username'],
      student['idNumber'],
    ].where((e) => e != null && e.toString().isNotEmpty).map((e) => e.toString().toLowerCase());

    return parts.join(' ');
  }

  Future<void> _submitRequest() async {
    if (_currentAdminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم التعرف على هوية المشرف')));
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
      'doctorName': _selectedDoctorName ?? _adminName,
      'clinic': _selectedClinic,
      'doctorUid': _selectedDoctorId ?? _currentAdminId,
      'requiresDeanApproval': requiresDeanApproval,
      'status': _editingRequestStatus ??
          (requiresDeanApproval ? 'awaiting_dean_approval' : 'pending'),
    };


    try {
      final bool isEditing = _editingRequestId != null;
      final uri = isEditing
          ? Uri.parse('${ApiConfig.baseUrl}/xray_requests/$_editingRequestId')
          : Uri.parse('${ApiConfig.baseUrl}/xray_requests');

      final response = isEditing
          ? await http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(requestData),
            )
          : await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(requestData),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final successMessage = responseData['message'] ??
            (isEditing
                ? 'تم تحديث الطلب بنجاح'
                : (_xrayType == 'cbct'
                    ? 'تم إرسال طلب CBCT وبانتظار موافقة العميد'
                    : 'تم إرسال الطلب بنجاح'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)));
        _resetForm();
        await _loadMyPendingRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEditing ? 'فشل تحديث الطلب' : 'فشل إرسال الطلب')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_editingRequestId != null
                ? 'حدث خطأ أثناء تحديث الطلب'
                : 'حدث خطأ أثناء إرسال الطلب')));
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
      _selectedDoctorId = _currentAdminId;
      _selectedDoctorName = _adminName;
      groupTeeth.clear();
      periapicalGridSelected = List.filled(32, false);
      foundPatients = [];
      foundStudents = [];
      _editingRequestId = null;
      _editingRequestStatus = null;
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
  void dispose() {
    _studentSearchDebounce?.cancel();
    _studentSearchController.dispose();
    _patientSearchController.dispose();
    _toothController.dispose();
    super.dispose();
  }

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
        drawer: AdminSidebar(
          primaryColor: primaryColor,
          accentColor: accentColor,
          userName: _adminName,
          userImageUrl: _adminImageUrl,
          parentContext: context,
          collapsed: false,
          translate: (ctx, key) => key,
          userRole: 'admin',
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
                                          'نتائج البحث عن الطلاب (${foundStudents.length}${_filteredStudentsCount > _studentResultsLimit ? '/$_filteredStudentsCount' : ''})',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        if (_filteredStudentsCount > _studentResultsLimit)
                                          Text(
                                            'تم عرض أول $_studentResultsLimit نتائج فقط من أصل $_filteredStudentsCount لتقليل التأخير',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
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

                          if (_editingRequestId != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'تعديل الطلب رقم $_editingRequestId',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),

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

                _buildPendingRequestsSection(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    final normalized = (status ?? '').toLowerCase();
    if (normalized == 'completed') return 'مكتمل';
    if (normalized == 'awaiting_dean_approval') return 'بانتظار موافقة العميد';
    return 'قيد الانتظار';
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request, Color primaryColor) {
    final status = request['status']?.toString();
    final isEditing = _editingRequestId != null &&
        _editingRequestId == request['request_id']?.toString();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isEditing ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: const Icon(Icons.photo_camera_front, color: Color(0xFF2A7A94)),
        ),
        title: Text(request['patient_name']?.toString() ?? 'مريض غير معروف',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نوع الأشعة: ${request['xray_type'] ?? ''}'),
            if (request['clinic'] != null)
              Text('العيادة: ${request['clinic']}'),
            Text('الحالة: ${_statusLabel(status)}'),
          ],
        ),
        trailing: TextButton.icon(
          onPressed: () => _prefillFormFromRequest(request),
          icon: const Icon(Icons.edit),
          label: const Text('تعديل'),
        ),
      ),
    );
  }

  Widget _buildPendingRequestsSection(Color primaryColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'طلبات الأشعة الخاصة بي (غير مصورة)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMyPendingRequests,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingRequests)
              const Center(child: CircularProgressIndicator())
            else if (_myPendingRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('لا يوجد طلبات معلقة حالياً'),
              )
            else
              ..._myPendingRequests
                  .map((req) => _buildPendingRequestCard(req, primaryColor)),
          ],
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
