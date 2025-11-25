// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_types_as_parameter_names, duplicate_ignore, unused_field, unused_element

import 'dental_form_table_readonly.dart';
import 'initial_examination.dart';
import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../utils/name_utils.dart';
import 'dart:ui' as ui;
import '../Doctor/doctor_sidebar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dcs/config/api_config.dart';

class ToothDisease {
  final String number;
  final String? disease;
  ToothDisease({required this.number, this.disease});
}

class DentalChartWidget extends StatelessWidget {
  final List<ToothDisease> upperTeeth;
  final List<ToothDisease> lowerTeeth;
  final double lineSpacing;
  final bool isChildChart;
  
  const DentalChartWidget({
    super.key, 
    required this.upperTeeth, 
    required this.lowerTeeth, 
    this.lineSpacing = 8.0,
    this.isChildChart = false,
  });

  Widget buildToothBox(ToothDisease tooth, bool isUpper, bool isEdge, double boxSize, double fontSize) {
    final numberWidget = Text(
      tooth.number,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      textAlign: TextAlign.center,
    );
    final Color boxColor = tooth.disease != null && tooth.disease!.trim().isNotEmpty
        ? _DoctorExaminedPatientsPageState.primaryColor
        : Colors.grey[200]!;
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: boxColor,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: numberWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
 
    Widget buildDiseaseRow(List<ToothDisease> teeth, bool isUpper, double boxSize, double fontSize) {
      int dividerIndex = isChildChart ? 5 : 8;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(teeth.length + 1, (i) {
          if (i == dividerIndex) {
            return Container(
              width: 8,
              height: boxSize,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: Colors.transparent,
            );
          } else if (i < dividerIndex) {
            final disease = teeth[i].disease;
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                width: boxSize,
                height: boxSize + 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0),
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: (disease != null && disease.trim().isNotEmpty)
                      ? Align(
                          alignment: Alignment.center,
                          child: Text(
                            disease,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: fontSize * 0.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : null,
                ),
              ),
            );
          } else if (i > dividerIndex) {
            final idx = i - 1;
            final disease = teeth[idx].disease;
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                width: boxSize,
                height: boxSize + 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0),
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: (disease != null && disease.trim().isNotEmpty)
                      ? Text(
                          disease,
                          style: TextStyle(color: Colors.red, fontSize: fontSize * 0.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        )
                      : null,
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
      );
    }
    
    Widget buildRow(List<ToothDisease> teeth, bool isUpper, double boxSize, double fontSize) {
      int dividerIndex = isChildChart ? 5 : 8;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(teeth.length + 1, (i) {
            if (i == dividerIndex) {
              return Container(
                width: lineSpacing,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: Colors.black,
              );
            } else if (i < dividerIndex) {
              final isEdge = i == 0 || i == teeth.length - 1;
              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: buildToothBox(teeth[i], isUpper, isEdge, boxSize, fontSize),
              );
            } else if (i > dividerIndex && i <= teeth.length) {
              final idx = i - 1;
              final isEdge = idx == 0 || idx == teeth.length - 1;
              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: buildToothBox(teeth[idx], isUpper, isEdge, boxSize, fontSize),
              );
            } else {
              return const SizedBox.shrink();
            }
        }),
      );
    }
    
    final double screenWidth = MediaQuery.of(context).size.width;
    double boxSize = 80;
    double fontSize = 20;
    if (screenWidth < 350) {
      boxSize = 24;
      fontSize = 12;
    } else if (screenWidth < 420) {
      boxSize = 28;
      fontSize = 14;
    } else if (screenWidth < 500) {
      boxSize = 34;
      fontSize = 16;
    } else if (screenWidth < 700) {
      boxSize = 48;
      fontSize = 18;
    }

    try {
      final inheritedState = context.findAncestorStateOfType<_DoctorExaminedPatientsPageState>();
      if (inheritedState != null && inheritedState.widget.doctorName != null) {
        // Handle inheritance if needed
      }
    } catch (e) {
      // Ignore errors
    }
   
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: GestureDetector(
        onHorizontalDragStart: (_) {},
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              buildDiseaseRow(upperTeeth, true, boxSize, fontSize),
              buildRow(upperTeeth, true, boxSize, fontSize),
             
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: (boxSize * (isChildChart ? 5 : 8)) + (4.0 * (isChildChart ? 5 : 8)) + lineSpacing,
                height: 4,
                color: Colors.black26,
              ),
              buildRow(lowerTeeth, false, boxSize, fontSize),
              buildDiseaseRow(lowerTeeth, false, boxSize, fontSize),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ UPDATED: Better safeConvertMap function
Map<String, dynamic> safeConvertMap(dynamic data) {
  if (data == null) return {};
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    try {
      final converted = Map<String, dynamic>.from(data);
      
      // ✅ Normalize keys to lowercase for consistent access
      final normalized = <String, dynamic>{};
      converted.forEach((key, value) {
        normalized[key.toString().toLowerCase()] = value;
        normalized[key.toString()] = value; // Keep original key too
      });
      
      return normalized;
    } catch (e) {
      debugPrint('❌ Error converting map: $e');
      return {};
    }
  }
  return {};
}

// ✅ Localization Delegate for English only
class _EnglishOnlyDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _EnglishOnlyDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) => 
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_EnglishOnlyDelegate old) => false;
}

class DoctorExaminedPatientsPage extends StatefulWidget {
  final String? doctorName;
  final String? doctorImageUrl;
  final String? currentUserId;
  final List<String>? userAllowedFeatures;

  const DoctorExaminedPatientsPage({
    super.key,
    this.doctorName,
    this.doctorImageUrl,
    this.currentUserId,
    this.userAllowedFeatures,
  });

  @override
  State<DoctorExaminedPatientsPage> createState() => _DoctorExaminedPatientsPageState();
}

class _DoctorExaminedPatientsPageState extends State<DoctorExaminedPatientsPage> {
  // API endpoints for Oracle database
  final String _baseApiUrl = ApiConfig.baseUrl;
  final String _allExaminationsApi = '${ApiConfig.baseUrl}/all-examinations-full';
  final String _examinationFullApi = '${ApiConfig.baseUrl}/examination-full';
  final String _patientsApi = '${ApiConfig.baseUrl}/patients';
  final String _usersApi = '${ApiConfig.baseUrl}/users';
  final String _clinicalProceduresApi = '${ApiConfig.baseUrl}/clinical-procedures';
  final String _prescriptionsApi = '${ApiConfig.baseUrl}/prescriptions';
  final String _xrayImagesApi = '${ApiConfig.baseUrl}/xray-images/patient';
  final String _patientAssignmentsApi = '${ApiConfig.baseUrl}/patient_assignments'; // ✅ NEW: Student assignments API

  // Colors
  static const Color primaryColor = Color(0xFF2A7A94);
  static const Color backgroundColor = Color(0xFFF3F5F7);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFEEEEEE);
  static const Color errorColor = Color(0xFFE53935);

  // State variables
  List<Map<String, dynamic>> _examinedPatients = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredExaminations = [];
  int _searchResultsTotal = 0;
  static const int _maxExaminationsToShow = 10;

  String? _doctorName;
  String? _doctorImageUrl;
  List<String>? _allowedFeatures;
  String? _currentUserId;

  final GlobalKey _dentalChartKey = GlobalKey();
  final GlobalKey _dentalFormTableKey = GlobalKey();

  // نظام الصلاحيات للدكتور فقط
  final Map<String, Map<String, dynamic>> _userPermissions = {
    'doctor': {
      'canView': ['all_reports', 'all_patients'],
      'canEdit': ['own_reports'],
      'canDelete': [],
      'canManageUsers': false,
    },
  };

  // دالة التحقق من الصلاحيات للدكتور
  bool _hasPermission(String permissionType, {String? resourceType, Map<String, dynamic>? examination}) {
    final userRole = 'doctor'; // دكتور فقط
    final permissions = _userPermissions[userRole];
    
    if (permissions == null) return false;
    
    switch (permissionType) {
      case 'view':
        final canView = permissions['canView'] as List<String>? ?? [];
        return canView.contains('all_$resourceType') || 
               canView.contains('${resourceType}s');
      
      case 'edit':
        final canEdit = permissions['canEdit'] as List<String>? ?? [];
        
        // Doctor يمكنه تعديل تقاريره فقط
        if (examination != null) {
          final doctorId = examination['examination']['DOCTOR_ID']?.toString();
          final currentUserId = _currentUserId;
          return canEdit.contains('own_reports') && doctorId == currentUserId;
        }
        return canEdit.contains('own_reports');
      
      case 'delete':
        return false; // ✅ لا أحد يستطيع الحذف
      
      default:
        return false;
    }
  }

  // English translations only
  final Map<String, String> _englishTranslations = {
    'examined_patients': 'Examined Patients',
    'name': 'Name',
    'phone': 'Phone',
    'age': 'Age',
    'no_patients': 'No examined patients',
    'error_loading': 'Error loading data',
    'retry': 'Retry',
    'examination_date': 'Examination Date',
    'examining_doctor': 'Examining Doctor',
    'examination_details': 'Examination Details',
    'back': 'Back',
    'gender': 'Gender',
    'patient_information': 'Patient Information',
    'examination_information': 'Examination Information',
    'extraoral_examination': 'Extraoral Examination',
    'intraoral_examination': 'Intraoral Examination',
    'soft_tissue_examination': 'Soft Tissue Examination',
    'periodontal_chart': 'Periodontal Chart',
    'dental_chart': 'Dental Chart',
    'search_hint': 'Search by name or phone...',
    'years': 'years',
    'months': 'months',
    'days': 'days',
    'age_unknown': 'Age unknown',
    'unknown': 'Unknown',
    'no_number': 'No number',
    'prescriptions': 'Prescriptions',
    'clinical_procedures': 'Clinical Procedures',
    'medicine_name': 'Medicine Name',
    'quantity': 'Quantity',
    'usage_time': 'Usage Time',
    'prescribing_doctor': 'Prescribing Doctor',
    'prescription_date': 'Prescription Date',
    'no_prescriptions': 'No prescriptions available',
    'no_clinical_procedures': 'No clinical procedures available',
    'edit_examination': 'Edit Examination',
    'child_dental_chart': 'Child Dental Chart (Primary Teeth)',
    'xray_images': 'X-ray Images',
    'no_xray_images': 'No X-ray images available',
    'xray_type': 'X-ray Type',
    'uploaded_by': 'Uploaded By',
    'uploaded_at': 'Uploaded At',
    'assigned_students': 'Assigned Students', // ✅ NEW
    'no_assigned_students': 'No students assigned', // ✅ NEW
    'student_name': 'Student Name', // ✅ NEW
    'student_id': 'Student ID', // ✅ NEW
    'university_id': 'University ID', // ✅ NEW
    'assignment_date': 'Assignment Date', // ✅ NEW
  };

  @override
  void initState() {
    super.initState();
    _loadAllExaminationsDirect();
    _searchController.addListener(_filterExaminations);
    _initializeUserInfo();
  }

  void _initializeUserInfo() {
    // Set current user ID
    _currentUserId = widget.currentUserId;
    
    // تحميل معلومات الدكتور
      setState(() {
      _doctorName = widget.doctorName ?? 'Doctor';
      _doctorImageUrl = widget.doctorImageUrl;
      _allowedFeatures = widget.userAllowedFeatures ?? ['examined_patients', 'prescription'];
    });
  }

  // =============================================
  // 🔥 DATA LOADING METHODS
  // =============================================

  Future<void> _loadAllExaminationsDirect() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _examinedPatients = [];
        _filteredExaminations = [];
        _searchResultsTotal = 0;
      });

      debugPrint('🔄 Loading all examinations directly from API...');

      // الدكتور يرى جميع التقارير
      String apiUrl = _allExaminationsApi;
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Server response: ${response.statusCode}');
      debugPrint('📦 Data size: ${response.body.length} characters');

      if (response.statusCode == 200) {
        final List<dynamic> examsData = json.decode(response.body);
        debugPrint('✅ Fetched ${examsData.length} examinations from database');

        if (examsData.isEmpty) {
          setState(() {
            _isLoading = false;
            _examinedPatients = [];
            _filteredExaminations = [];
            _searchResultsTotal = 0;
          });
          return;
        }

        List<Map<String, dynamic>> completeExams = [];

        for (var examData in examsData) {
          try {
            final completeExam = _processExaminationData(examData);
            if (completeExam != null) {
              completeExams.add(completeExam);
            }
          } catch (e) {
            debugPrint('❌ Error processing exam ${examData['EXAM_ID']}: $e');
          }
        }

        debugPrint('📊 Final processed examinations count: ${completeExams.length}');

        setState(() {
          _examinedPatients = completeExams;
          _isLoading = false;
        });
        _filterExaminations();

        // ✅ Debug patient data
        _debugPatientData();

        if (completeExams.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fetched ${examsData.length} exams but no complete data'),
              backgroundColor: Colors.orange,
            ),
          );
        }
    } else {
        throw Exception('Failed to load examinations: ${response.statusCode}');
    }
    } catch (e) {
      debugPrint('❌ Error loading examinations: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _filteredExaminations = [];
        _searchResultsTotal = 0;
      });
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic>? _processExaminationData(Map<String, dynamic> examData) {
    try {
      debugPrint('🔍 Processing examination data: ${examData['EXAM_ID']}');
      
      // Convert date
      DateTime examDate;
      if (examData['EXAM_DATE'] != null) {
        try {
          if (examData['EXAM_DATE'] is String) {
            examDate = DateTime.parse(examData['EXAM_DATE'].toString());
          } else {
            examDate = DateTime.now();
          }
        } catch (e) {
          examDate = DateTime.now();
        }
      } else {
        examDate = DateTime.now();
      }

      // Get patient and doctor data
      final patientData = safeConvertMap(examData['PATIENT_DATA'] ?? {});
      final doctorData = safeConvertMap(examData['DOCTOR_DATA'] ?? {});

      // ✅ Data is directly in the response
      final examDataProcessed = safeConvertMap(examData['EXAM_DATA'] ?? {});
      final screeningDataProcessed = safeConvertMap(examData['SCREENING_DATA'] ?? {});
      final dentalFormDataProcessed = safeConvertMap(examData['DENTAL_FORM_DATA'] ?? {});

      // ✅ Extract image URLs directly from PATIENT_DATA
      final String? idImage = patientData['IDIMAGE']?.toString();
      final String? iqrarImage = patientData['IQRAR']?.toString();
      final String? patientImage = patientData['IMAGE']?.toString();

      // Create complete examination object
      return {
        'exam_id': examData['EXAM_ID'],
        'patient': {
          ...patientData,
          'id': patientData['PATIENT_UID'] ?? examData['PATIENT_UID'],
          'firstName': patientData['FIRSTNAME'] ?? '',
          'fatherName': patientData['FATHERNAME'] ?? '',
          'grandfatherName': patientData['GRANDFATHERNAME'] ?? '',
          'familyName': patientData['FAMILYNAME'] ?? '',
          'idNumber': patientData['IDNUMBER'] ?? '',
          'birthDate': patientData['BIRTHDATE'] ?? '',
          'gender': patientData['GENDER'] ?? '',
          'phone': patientData['PHONE'] ?? '',
          'medicalRecordNo': patientData['MEDICAL_RECORD_NO'] ?? '',
          // ✅ CORRECTED: Use the extracted image URLs directly
          'idImage': idImage,
          'iqrar': iqrarImage,
          'image': patientImage,
          // ✅ Add original fields for backup
          'IDIMAGE': idImage,
          'IQRAR': iqrarImage,
          'IMAGE': patientImage,
        },
        'examination': {
          'timestamp': examDate.millisecondsSinceEpoch,
          'examData': examDataProcessed,
          'screening': screeningDataProcessed,
          'dentalFormData': dentalFormDataProcessed,
          'notes': examData['NOTES'],
          'DOCTOR_ID': examData['DOCTOR_ID'],
          'EXAM_ID': examData['EXAM_ID'],
          'EXAM_DATE': examData['EXAM_DATE'],
        },
        'doctor': {
          ...doctorData,
          'name': doctorData['FULL_NAME'] ?? 'Unknown Doctor',
          'id': examData['DOCTOR_ID'],
        },
      };
    } catch (e) {
      debugPrint('❌ Error processing examination data: $e');
      return null;
    }
  }

  // ✅ NEW: دالة لجلب الطلاب المعينين للمريض
  Future<List<Map<String, dynamic>>> _getAssignedStudentsForPatient(String? patientId) async {
    try {
      debugPrint('🔄 جلب الطلاب المعينين للمريض: $patientId');
      
      if (patientId == null || patientId.isEmpty) {
        debugPrint('❌ patientId فارغ');
        return [];
      }
      
      final Uri uri = Uri.parse('$_baseApiUrl/patient_assignments/$patientId');
      debugPrint('🔗 رابط الطلاب المعينين: ${uri.toString()}');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 استجابة السيرفر للطلاب المعينين: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> assignedStudents = [];
        
        debugPrint('🔍 نوع بيانات الاستجابة للطلاب: ${data.runtimeType}');
        
          if (data is List) {
            debugPrint('📋 البيانات هي قائمة تحتوي على ${data.length} طالب');
            for (var item in data) {
              if (item is Map) {
                final fullName = extractFullName(Map<String, dynamic>.from(item));
                final studentData = {
                  'student_id': item['STUDENT_ID']?.toString() ?? '',
                  'full_name': fullName,
                  'first_name': extractFirstName(Map<String, dynamic>.from(item)),
                  'student_university_id': item['STUDENT_UNIVERSITY_ID']?.toString() ?? '',
                  'assigned_date': item['ASSIGNED_DATE']?.toString() ?? '',
                  'assignment_id': item['ASSIGNMENT_ID']?.toString() ?? '',
                };
              
              debugPrint('👨‍🎓 الطالب: ${studentData['full_name']}');
              debugPrint('   - الجامعة: ${studentData['student_university_id']}');
              debugPrint('   - تاريخ التعيين: ${studentData['assigned_date']}');
              
              assignedStudents.add(studentData);
            }
          }
        } else {
          debugPrint('❌ تنسيق البيانات غير متوقع للطلاب: ${data.runtimeType}');
        }
        
        debugPrint('✅ تم جلب ${assignedStudents.length} طالب معين للمريض');
        return assignedStudents;
      } else {
        debugPrint('❌ فشل في جلب الطلاب المعينين: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلاب المعينين: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadFullExaminationData(String examId) async {
    try {
      debugPrint('🔄 Loading full examination data: $examId');
      
      final response = await http.get(
        Uri.parse('$_baseApiUrl/examination-full/$examId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final fullData = json.decode(response.body);
        debugPrint('✅ Successfully loaded full data');
        
        return {
          'examData': safeConvertMap(fullData['EXAM_DATA'] ?? {}),
          'screening': safeConvertMap(fullData['SCREENING_DATA'] ?? {}),
          'dentalFormData': safeConvertMap(fullData['DENTAL_FORM_DATA'] ?? {}),
          'notes': fullData['NOTES'],
        };
      } else {
        debugPrint('❌ Failed to load data: ${response.statusCode}');
      return {};
    }
    } catch (e) {
      debugPrint('❌ Error loading full examination data: $e');
      return {};
  }
  }

  // ✅ دالة محسنة لجلب الوصفات الطبية للمريض
  Future<List<Map<String, dynamic>>> _getPrescriptionsForPatient(String? patientId) async {
    try {
      debugPrint('🔄 جلب الوصفات الطبية للمريض: $patientId');
      
      if (patientId == null || patientId.isEmpty) {
        debugPrint('❌ patientId فارغ');
        return [];
      }
      
      final Uri uri = Uri.parse('$_prescriptionsApi/patient/$patientId');
      debugPrint('🔗 الرابط: ${uri.toString()}');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 استجابة السيرفر: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> prescriptions = [];
        
        if (data is List) {
          for (var item in data) {
            if (item is Map) {
              prescriptions.add({
                'prescription_id': item['PRESCRIPTION_ID'] ?? '',
                'patient_id': item['PATIENT_ID'] ?? '',
                'patient_name': item['PATIENT_NAME'] ?? '',
                'medicine_name': item['MEDICINE_NAME'] ?? '',
                'quantity': item['QUANTITY'] ?? '',
                'usage_time': item['USAGE_TIME'] ?? '',
                'doctor_name': item['DOCTOR_NAME'] ?? '',
                'doctor_uid': item['DOCTOR_UID'] ?? '',
                'created_date': item['CREATED_DATE'] ?? '',
                'prescription_date': item['PRESCRIPTION_DATE'] ?? '',
            });
          }
        }
        }
        
        debugPrint('✅ تم جلب ${prescriptions.length} وصفة طبية للمريض');
        return prescriptions;
      } else {
        debugPrint('❌ فشل في جلب الوصفات الطبية: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الوصفات الطبية: $e');
      return [];
    }
  }

  // ✅ دالة محسنة لجلب الإجراءات السريرية للمريض
  Future<List<Map<String, dynamic>>> _getClinicalProceduresForPatient(String? patientId, String? patientIdNumber) async {
    try {
      debugPrint('🔄 جلب الإجراءات السريرية للمريض: $patientId / $patientIdNumber');
      
      if ((patientId == null || patientId.isEmpty) && (patientIdNumber == null || patientIdNumber.isEmpty)) {
        debugPrint('❌ patientId و patientIdNumber فارغان');
        return [];
      }
      
      // البحث باستخدام patientId أولاً
      Uri uri;
      if (patientId != null && patientId.isNotEmpty) {
        uri = Uri.parse('$_baseApiUrl/clinical_procedures/patient/$patientId');
      } else {
        uri = Uri.parse('$_baseApiUrl/clinical_procedures/patient/$patientIdNumber');
      }
      
      debugPrint('🔗 الرابط: ${uri.toString()}');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 استجابة السيرفر: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> procedures = [];
        
        if (data is List) {
          for (var item in data) {
            if (item is Map) {
              procedures.add({
                'procedure_id': item['PROCEDURE_ID'] ?? '',
                'clinic_name': item['CLINIC_NAME'] ?? '',
                'date_of_operation': item['DATE_OF_OPERATION'] ?? '',
                'date_of_second_visit': item['DATE_OF_SECOND_VISIT'] ?? '',
                'patient_id': item['PATIENT_ID'] ?? '',
                'patient_id_number': item['PATIENT_ID_NUMBER'] ?? '',
                'patient_name': item['PATIENT_NAME'] ?? '',
                'student_name': item['STUDENT_NAME'] ?? '',
                'supervisor_name': item['SUPERVISOR_NAME'] ?? '',
                'tooth_no': item['TOOTH_NO'] ?? '',
                'type_of_operation': item['TYPE_OF_OPERATION'] ?? '',
                'created_at': item['CREATED_AT'] ?? '',
        });
            }
          }
        }
        
        debugPrint('✅ تم جلب ${procedures.length} إجراء سريري للمريض');
        return procedures;
      } else {
        debugPrint('❌ فشل في جلب الإجراءات السريرية: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإجراءات السريرية: $e');
      return [];
    }
  }

  // ✅ NEW: Normalize and collect patient identifiers for X-ray fetch
  List<String> _collectPatientIdentifiers(Map<String, dynamic> patient) {
    final ids = <String>{};
    
    void addId(dynamic value) {
      final normalized = _normalizePatientIdentifier(value);
      if (normalized != null) ids.add(normalized);
    }

    addId(patient['PATIENT_UID'] ?? patient['id']);
    addId(patient['patient_uid']);
    addId(patient['PATIENT_ID']);
    addId(patient['patient_id']);
    addId(patient['patientid']);
    addId(patient['idNumber'] ?? patient['IDNUMBER']);
    addId(patient['idnumber']);
    addId(patient['PATIENT_ID_NUMBER']);
    addId(patient['patient_id_number']);
    addId(patient['medicalRecordNo'] ?? patient['MEDICAL_RECORD_NO']);
    addId(patient['medical_record_no']);

    return ids.toList();
  }

  String? _normalizePatientIdentifier(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') return null;
    return normalized;
  }

  // ✅ NEW: Try multiple patient identifiers to avoid 500 errors
  Future<List<Map<String, dynamic>>> _getXrayImagesForPatient(List<String> patientIdentifiers) async {
    if (patientIdentifiers.isEmpty) {
      debugPrint('❌ لا يوجد معرف صالح للمريض لجلب صور الأشعة');
      return [];
    }

    List<Map<String, dynamic>> lastResult = [];

    for (int i = 0; i < patientIdentifiers.length; i++) {
      final patientId = patientIdentifiers[i];
      debugPrint('🆔 محاولة جلب صور الأشعة باستخدام المعرف: $patientId (${i + 1}/${patientIdentifiers.length})');

      final images = await _fetchXrayImagesById(patientId);
      lastResult = images;

      // إذا وجدنا صورًا نوقف المحاولة
      if (images.isNotEmpty) {
        return images;
      }
    }

    return lastResult;
  }

  Future<List<Map<String, dynamic>>> _fetchXrayImagesById(String patientId) async {
    try {
      debugPrint('🔄 جلب صور الأشعة للمريض: $patientId');

      final Uri uri = Uri.parse('$_xrayImagesApi/$patientId');
      debugPrint('🔗 رابط صور الأشعة: ${uri.toString()}');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('📡 استجابة السيرفر لصور الأشعة ($patientId): ${response.statusCode}');
      debugPrint('📦 بيانات الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> xrayImages = [];
        dynamic pick(Map<String, dynamic> map, List<String> keys) {
          for (final k in keys) {
            if (map.containsKey(k)) return map[k];
          }
          return null;
        }
        
        debugPrint('🔍 نوع بيانات الاستجابة: ${data.runtimeType}');
        
        // السماح بالاستجابة كقائمة مباشرة أو كائن يحتوي على data
        final listData = () {
          if (data is List) return data;
          if (data is Map && data.containsKey('data') && data['data'] is List) return data['data'] as List;
          if (data is Map && data.containsKey('images') && data['images'] is List) return data['images'] as List;
          return null;
        }();

        if (listData != null) {
          debugPrint('📋 البيانات هي قائمة تحتوي على ${listData.length} عنصر');
          for (var i = 0; i < listData.length; i++) {
            if (listData[i] is! Map) continue;
            var item = Map<String, dynamic>.from(listData[i] as Map);
            // دعم المفاتيح بحروف كبيرة أو صغيرة مع تفضيل IMAGE_URL على cloudinary
            final primaryImageUrl = pick(item, ['IMAGE_URL', 'image_url']);
            final fallbackImageUrl = pick(item, ['CLOUDINARY_URL', 'cloudinary_url', 'url']);
            final studentName = (pick(item, ['STUDENT_NAME', 'student_name']) ?? 'Unknown').toString();
            final xrayType = (pick(item, ['XRAY_TYPE', 'xray_type']) ?? 'Unknown').toString();
            final uploadedAt = (pick(item, ['UPLOADED_AT', 'uploaded_at', 'created_at']) ?? '').toString();
            final imageUrl = primaryImageUrl?.toString().trim().isNotEmpty == true
                ? primaryImageUrl.toString()
                : (fallbackImageUrl?.toString() ?? '');
            final cleanedUrl = (imageUrl.toLowerCase() == 'null' || imageUrl.isEmpty) ? '' : imageUrl;

            debugPrint('📸 الصورة $i: $imageUrl');
            debugPrint('   - الطالب: $studentName');
            debugPrint('   - النوع: $xrayType');
            debugPrint('   - التاريخ: $uploadedAt');
            
            if (cleanedUrl.isNotEmpty) {
              xrayImages.add({
                'image_url': cleanedUrl,
                'student_name': studentName,
                'xray_type': xrayType,
                'uploaded_at': uploadedAt,
              });
            } else {
              debugPrint('⚠️ رابط الصورة فارغ للعنصر $i');
            }
          }
        } else {
          debugPrint('❌ تنسيق البيانات غير متوقع: ${data.runtimeType}');
        }
        
        debugPrint('✅ تم جلب ${xrayImages.length} صورة أشعة للمريض');
        return xrayImages;
      } else {
        debugPrint('❌ فشل في جلب صور الأشعة للمريض $patientId: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب صور الأشعة للمريض $patientId: $e');
      return [];
    }
  }
  // =============================================
  // 🔥 HELPER METHODS
  // =============================================

  Widget _buildErrorSection(String message) {
    return _buildDetailSection(
      title: 'Error',
      children: [
        Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllExaminationsDirect,
                child: Text(_translate('retry')),
              ),
            ],
          ),
        ),
      ],
    );
      }

  // ✅ NEW: Build assigned students section
  Widget _buildAssignedStudentsCard(Map<String, dynamic> patientExam, BuildContext context) {
    final patient = safeConvertMap(patientExam['patient']);
    final String? patientId = patient['PATIENT_UID']?.toString() ?? patient['id']?.toString();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAssignedStudentsForPatient(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          debugPrint('❌ Error loading assigned students: ${snapshot.error}');
          return _buildErrorSection('Failed to load assigned students');
        }
        
        final assignedStudents = snapshot.data ?? [];
        if (assignedStudents.isEmpty) {
          return _buildDetailSection(
            title: _translate('assigned_students'),
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.school, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      _translate('no_assigned_students'),
                      style: TextStyle(
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return _buildDetailSection(
          title: '${_translate('assigned_students')} (${assignedStudents.length})',
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildAssignedStudentsTable(assignedStudents);
          } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildAssignedStudentsTable(assignedStudents),
                  );
          }
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Build assigned students table
  Widget _buildAssignedStudentsTable(List<Map<String, dynamic>> assignedStudents) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 8,
      dataRowMaxHeight: 60,
      headingRowHeight: 50,
      columns: const [
        DataColumn(
          label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Full name of assigned student',
        ),
       
        DataColumn(
          label: Text('Assignment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Date when student was assigned to patient',
        ),
      ],
      rows: assignedStudents.map((student) {
        final fullName = (student['full_name'] ?? '').toString().trim();
        final fallbackName = (student['first_name'] ?? '').toString().trim();
        final displayName = fullName.isNotEmpty ? fullName : fallbackName;
        
        return DataRow(
          cells: [
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 120),
                child: Text(
                  displayName.isNotEmpty ? displayName : 'Unknown Student',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
    
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  _formatAssignmentDate(student['assigned_date']),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ✅ NEW: Format assignment date
  String _formatAssignmentDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not specified';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // ✅ NEW: Build X-ray images section
  Widget _buildXrayImagesCard(Map<String, dynamic> patientExam, BuildContext context) {
    final patient = safeConvertMap(patientExam['patient']);
    final patientIdentifiers = _collectPatientIdentifiers(patient);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getXrayImagesForPatient(patientIdentifiers),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
          }
        
        if (snapshot.hasError) {
          debugPrint('❌ Error loading X-ray images: ${snapshot.error}');
          return _buildErrorSection('Failed to load X-ray images');
        }
        
        final xrayImages = snapshot.data ?? [];
        if (xrayImages.isEmpty) {
          return _buildDetailSection(
            title: _translate('xray_images'),
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      _translate('no_xray_images'),
                      style: TextStyle(
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return _buildDetailSection(
          title: '${_translate('xray_images')} (${xrayImages.length})',
          children: [
            _buildXrayImagesGrid(xrayImages, context),
          ],
        );
      },
    );
  }

  // ✅ NEW: Build X-ray images grid
  Widget _buildXrayImagesGrid(List<Map<String, dynamic>> xrayImages, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: xrayImages.length,
      itemBuilder: (context, index) {
        final image = xrayImages[index];
        return _buildXrayImageCard(image, context);
      },
    );
  }

  // ✅ NEW: Build individual X-ray image card
  Widget _buildXrayImageCard(Map<String, dynamic> image, BuildContext context) {
    final String imageUrl = image['image_url']?.toString() ?? '';
    final String xrayType = image['xray_type']?.toString() ?? 'Unknown';
    final String uploadedAt = image['uploaded_at']?.toString() ?? '';
    final String studentName = image['student_name']?.toString() ?? '';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showXrayImageDialog(context, imageUrl, xrayType);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  color: Colors.grey[100],
                ),
                child: _buildXrayImageWithFallback(imageUrl),
              ),
            ),
            
            // Info section
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    xrayType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (studentName.isNotEmpty) ...[
                    Text(
                      'الطالب: $studentName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  
                  Text(
                    _formatXrayDate(uploadedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build X-ray image with fallback
  Widget _buildXrayImageWithFallback(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
        }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                  loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 30, color: Colors.red[300]),
              const SizedBox(height: 4),
              Text(
                'Load Failed',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// ✅ NEW: Show X-ray image in dialog without pinch restrictions
void _showXrayImageDialog(BuildContext context, String imageUrl, String title) {
  if (imageUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No image available')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Image with InteractiveViewer for natural zooming
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[900],
              child: InteractiveViewer(
                panEnabled: true, // Allow panning
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5, // Minimum zoom level
                maxScale: 4.0, // Maximum zoom level
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading X-ray Image...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load X-ray image',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Footer with zoom instructions
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: const Column(
              children: [
                Text(
                  'Pinch to zoom • Drag to pan',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Double tap to reset zoom',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  // ✅ NEW: Format X-ray date
  String _formatXrayDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getFullName(Map<String, dynamic> patient) {
    final firstName = patient['firstName'] ?? patient['FIRSTNAME'] ?? '';
    final fatherName = patient['fatherName'] ?? patient['FATHERNAME'] ?? '';
    final grandfatherName = patient['grandfatherName'] ?? patient['GRANDFATHERNAME'] ?? '';
    final familyName = patient['familyName'] ?? patient['FAMILYNAME'] ?? '';
    
    return '$firstName $fatherName $grandfatherName $familyName'.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _translate(String key) {
    return _englishTranslations[key] ?? key;
  }

  // ✅ دالة محسنة لحساب العمر مع تحديد إذا كان طفل (<= 12 سنة)
  String _calculateAge(dynamic birthDateValue) {
    if (birthDateValue == null) return _translate('age_unknown');
    
    final DateTime? birthDate;
    if (birthDateValue is String) {
      birthDate = DateTime.tryParse(birthDateValue);
    } else if (birthDateValue is int) {
      birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateValue);
    } else {
      birthDate = null;
    }
    
    if (birthDate == null) return _translate('age_unknown');
    
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return _translate('age_unknown');
    
    final age = now.difference(birthDate);
    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;
    final days = (age.inDays % 365) % 30;
    
    if (years > 0) {
      return '$years ${_translate('years')}';
    } else if (months > 0) {
      return '$months ${_translate('months')}';
    } else {
      return '$days ${_translate('days')}';
    }
  }

  // ✅ Function to check if patient is a child (12 years or younger)
  bool _isChildPatient(Map<String, dynamic> patient) {
    final birthDateValue = patient['birthDate'] ?? patient['BIRTHDATE'];
    if (birthDateValue == null) {
      debugPrint('❌ No birth date available for child check');
      return false;
    }
    
    final DateTime? birthDate;
    if (birthDateValue is String) {
      birthDate = DateTime.tryParse(birthDateValue);
    } else if (birthDateValue is int) {
      birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateValue);
    } else {
      birthDate = null;
    }
    
    if (birthDate == null) {
      debugPrint('❌ Could not parse birth date: $birthDateValue');
      return false;
    }
    
    final now = DateTime.now();
    final ageInYears = now.difference(birthDate).inDays ~/ 365;
    
    debugPrint('🎂 Age calculation: $ageInYears years - Child: ${ageInYears <= 12}');
    
    return ageInYears <= 12;
  }

  void _filterExaminations() {
    final query = _searchController.text.toLowerCase();
    final filtered = _examinedPatients.where((exam) {
      final patient = exam['patient'] as Map<String, dynamic>;
      final fullName = _getFullName(patient).toLowerCase();
      final phone = patient['phone']?.toString().toLowerCase() ?? 
                   patient['PHONE']?.toString().toLowerCase() ?? '';
      return fullName.contains(query) || phone.contains(query);
    }).toList();

    setState(() {
      _searchResultsTotal = filtered.length;
      _filteredExaminations = _limitExaminationResults(filtered);
    });
  }

  List<Map<String, dynamic>> _limitExaminationResults(List<Map<String, dynamic>> exams) {
    if (exams.length <= _maxExaminationsToShow) return exams;
    return exams.take(_maxExaminationsToShow).toList();
  }

  // =============================================
  // 🔥 PERMISSION CHECK METHODS
  // =============================================

  // ✅ Check if current user can edit the examination
  bool _canEditExamination(Map<String, dynamic> examination) {
    final doctorId = examination['examination']['DOCTOR_ID']?.toString();
    final currentUserId = _currentUserId;
    
    debugPrint('🔐 Permission Check:');
    debugPrint('   - Current User ID: $currentUserId');
    debugPrint('   - Exam Doctor ID: $doctorId');
    debugPrint('   - Can Edit: ${doctorId == currentUserId}');
    
    // الدكتور يمكنه تعديل تقاريره فقط
    return doctorId == currentUserId;
  }

  // ✅ Function to navigate to edit examination page
  void _navigateToEditExamination(Map<String, dynamic> patientExam) {
    final patient = safeConvertMap(patientExam['patient']);
    final exam = safeConvertMap(patientExam['examination']);

    // Merge top-level exam fields with nested examData so the edit screen
    // receives everything (including dentalFormData) in one map.
    final dynamic nestedExamData = exam['examData'] ?? exam['examdata'];
    final Map<String, dynamic> mergedExamData = {};
    if (exam.isNotEmpty) {
      mergedExamData.addAll(Map<String, dynamic>.from(exam));
    }
    if (nestedExamData is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedExamData);
      mergedExamData.addAll(nestedMap);
      mergedExamData['examData'] = nestedMap;
    }
    
    debugPrint('✏️ Navigating to edit examination:');
    debugPrint('   - Patient: ${_getFullName(patient)}');
    debugPrint('   - Exam ID: ${exam['EXAM_ID']}');
    debugPrint('   - Doctor ID: ${exam['DOCTOR_ID']}');
    
    // التنقل إلى صفحة InitialExamination مع بيانات الفحص الحالية
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InitialExamination(
          patientData: patient,
          examinationData: mergedExamData,
          isEditMode: true,
          existingExamId: exam['EXAM_ID']?.toString(),
          doctorId: _currentUserId ?? '',
          patientId: (patient['PATIENT_UID'] ?? patient['id'] ?? '').toString(),
        ),
      ),
    ).then((result) {
      // عند العودة من صفحة التعديل، قم بتحديث البيانات
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Examination updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllExaminationsDirect(); // إعادة تحميل البيانات
      }
    });
  }

  // =============================================
  // 🔥 ID IMAGE METHODS
  // =============================================

  // ✅ Function to fix Cloudinary URL timestamp issues
  String? _fixCloudinaryUrl(String url) {
    try {
      if (url.contains('res.cloudinary.com')) {
        final regex = RegExp(r'/v(\d+)/');
        final match = regex.firstMatch(url);
        
        if (match != null) {
          final timestamp = match.group(1);
          if (timestamp != null && timestamp.length > 10) {
            final validTimestamp = timestamp.substring(0, 10);
            final fixedUrl = url.replaceFirst('/v$timestamp/', '/v$validTimestamp/');
            debugPrint('🔄 Fixed Cloudinary timestamp: $timestamp -> $validTimestamp');
            return fixedUrl;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fixing Cloudinary URL: $e');
      return null;
    }
  }

  // ✅ Helper function to validate image URLs
  bool _isValidImageUrl(dynamic value) {
    if (value == null) return false;
    
    final stringValue = value.toString().trim();
    
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'null') {
      return false;
    }
    
    if (stringValue.length < 10) {
      return false;
    }
    
    if (stringValue.startsWith('http://') || stringValue.startsWith('https://')) {
      return true;
    }
    
    if (stringValue.contains('res.cloudinary.com')) {
      return true;
    }
    
    return false;
  }

  // ✅ Function to check and display ID image with better field detection
  Widget _buildIdImageWithValidation(Map<String, dynamic> patient) {
    try {
      debugPrint('=== 🖼️ ID IMAGE DEBUG START ===');
      
      String? idImageUrl;
      String? foundInField;
      
      final possibleFields = [
        'IDIMAGE', 'idImage', 'ID_IMAGE', 'id_image',
        'IQRAR', 'iqrar', 
      
      ];
      
      for (var field in possibleFields) {
        final value = patient[field];
        debugPrint('🔍 Checking field $field: "$value" (type: ${value?.runtimeType})');
        
        if (_isValidImageUrl(value)) {
          idImageUrl = value.toString().trim();
          foundInField = field;
          debugPrint('✅ FOUND VALID IMAGE in $field: $idImageUrl');
          break;
        } else {
          debugPrint('❌ Field $field is empty or invalid: "$value"');
        }
      }
      
      if (idImageUrl == null) {
        debugPrint('❌ NO VALID ID IMAGE URL FOUND in any field');
        return _buildIdImagePlaceholderWithHelp(
          'No valid image URL found in patient data',
          showHelp: true
        );
      }
      
      debugPrint('🎯 Using Image URL from $foundInField: $idImageUrl');
      
      if (!idImageUrl.startsWith('http')) {
        debugPrint('⚠️ URL does not start with http: $idImageUrl');
        if (idImageUrl.startsWith('/')) {
          idImageUrl = '${ApiConfig.baseUrl}$idImageUrl';
          debugPrint('🔄 Trying constructed URL: $idImageUrl');
        }
      }
      
      final String? fixedUrl = _fixCloudinaryUrl(idImageUrl);
      if (fixedUrl != null) {
        idImageUrl = fixedUrl;
        debugPrint('🔄 Using fixed Cloudinary URL: $idImageUrl');
      }
      
      return Column(
        children: [
          Text(
            foundInField == 'IQRAR' || foundInField == 'iqrar' ? 'Iqrar Document' : 'ID Image',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Found in: $foundInField',
                  style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          
          GestureDetector(
            onTap: () {
              _showIdImageDialog(context, idImageUrl!, 
                  foundInField == 'IQRAR' || foundInField == 'iqrar' ? 'Iqrar Document' : 'ID Image');
            },
            child: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    _buildImageWithFallbacks(idImageUrl),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        color: Colors.black54,
                        child: Text(
                          foundInField == 'IQRAR' || foundInField == 'iqrar' ? 'IQRAR' : 'ID CARD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            'Tap to view full image',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      );
    } catch (e) {
      debugPrint('❌ ERROR in _buildIdImageWithValidation: $e');
      return _buildIdImagePlaceholderWithHelp('Error: $e', showHelp: true);
    } finally {
      debugPrint('=== 🖼️ ID IMAGE DEBUG END ===');
    }
  }

  Widget _buildImageWithFallbacks(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('✅ Image loaded successfully: $imageUrl');
          return child;
        }
        
        debugPrint('🔄 Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                  loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image network error: $error');
        debugPrint('❌ URL that failed: $imageUrl');
        
        return Container(
          color: Colors.grey[200],
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 40, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                'Load Failed',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to retry',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
      
      headers: const {
        'User-Agent': 'Flutter App',
        'Accept': 'image/*',
      },
    );
  }

  Widget _buildIdImagePlaceholderWithHelp(String message, {bool showHelp = true}) {
    return Column(
      children: [
        const Text(
          'ID Image',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: showHelp ? () {
            _showIdImageHelpDialog(context);
          } : null,
          child: Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.perm_identity, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'ID Image\nNot Available',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (showHelp) ...[
                    SizedBox(height: 4),
                    Text(
                      'Tap for info',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ],
                  SizedBox(height: 4),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange, fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showIdImageHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ID Image Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Why is the ID image not showing?'),
            SizedBox(height: 12),
            Text('• No image uploaded for this patient'),
            Text('• Image path not stored in database'),
            Text('• Network connection issue'),
            Text('• Invalid image URL format'),
            SizedBox(height: 12),
            Text('Contact administrator if this is unexpected.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showIdImageDialog(BuildContext context, String imageUrl, String title) {
    debugPrint('🖼️ Opening Image Dialog: $title - $imageUrl');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
                  children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
                    Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[900],
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration: BoxDecoration(color: Colors.grey[900]),
                  loadingBuilder: (context, event) {
                    if (event == null || event.expectedTotalBytes == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text(
                              'Loading Image...',
                              style: TextStyle(color: Colors.white),
                        ),
                          ],
                    ),
                      );
                    }
                    
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading... ${(event.cumulativeBytesLoaded / event.expectedTotalBytes! * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ PhotoView image error: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showIdImageDialog(context, imageUrl, title);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black,
              child: const Column(
                children: [
                  Text(
                    'Pinch to zoom • Drag to pan',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Double tap to reset',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPatientImages(Map<String, dynamic> patient) {
    final List<Map<String, String>> availableImages = [];
    
    if (_isValidImageUrl(patient['IDIMAGE']) || _isValidImageUrl(patient['idImage'])) {
      final url = patient['IDIMAGE'] ?? patient['idImage'];
      availableImages.add({'title': 'ID Card', 'url': url.toString()});
    }
    
    if (_isValidImageUrl(patient['IQRAR']) || _isValidImageUrl(patient['iqrar'])) {
      final url = patient['IQRAR'] ?? patient['iqrar'];
      availableImages.add({'title': 'Iqrar Document', 'url': url.toString()});
    }
    
  
    
    if (availableImages.isEmpty) {
      return _buildIdImagePlaceholderWithHelp('No images available for this patient', showHelp: true);
    }
    
    return Column(
      children: [
        Text(
          'Patient Documents & Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: availableImages.map((image) {
            return _buildImageThumbnail(image['title']!, image['url']!, context);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String title, String imageUrl, BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _showIdImageDialog(context, imageUrl, title);
          },
          child: Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWithFallbacks(imageUrl),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ],
    );
  }

  void _debugRawPatientData(Map<String, dynamic> patientExam) {
    debugPrint('=== 🔍 RAW PATIENT DATA DEBUG ===');
    final patient = patientExam['patient'];
    
    if (patient is Map) {
      debugPrint('📦 Raw patient data structure:');
      patient.forEach((key, value) {
        debugPrint('   "$key": "$value" (type: ${value?.runtimeType})');
      });
    } else {
      debugPrint('❌ Patient data is not a Map: ${patient.runtimeType}');
    }
    
    debugPrint('🎯 Specific ID image field checks:');
    debugPrint('   - IDIMAGE: "${patient['IDIMAGE']}"');
    debugPrint('   - idImage: "${patient['idImage']}"');
    debugPrint('   - IMAGE: "${patient['IMAGE']}"');
    debugPrint('   - IQRAR: "${patient['IQRAR']}"');
    
    debugPrint('=== 🔍 END RAW DEBUG ===');
  }

  // =============================================
  // 🔥 DENTAL CHART SECTION
  // =============================================

  Widget _buildDentalChartSection(Map<String, dynamic> dentalChart, Map<String, dynamic> patient) {
    final Map<String, String> teethConditions = dentalChart['teethConditions'] is Map
        ? Map<String, String>.from(dentalChart['teethConditions'])
        : {};

    final bool isChild = _isChildPatient(patient);
    
    List<String> upperNumbersAdult = [
      ...List.generate(8, (i) => '1${8 - i}'),
      ...List.generate(8, (i) => '2${i + 1}'),
    ];
    
    List<String> lowerNumbersAdult = [
      ...List.generate(8, (i) => '4${8 - i}'),
      ...List.generate(8, (i) => '3${i + 1}'),
    ];

    List<String> upperNumbersChild = [];
    List<String> lowerNumbersChild = [];

    if (isChild) {
      upperNumbersChild = [
        '55', '54', '53', '52', '51',
        '61', '62', '63', '64', '65'
      ];
      
      lowerNumbersChild = [
        '85', '84', '83', '82', '81',
        '71', '72', '73', '74', '75'
      ];
    }

    final upperTeethAdult = upperNumbersAdult.map((num) =>
      ToothDisease(number: num, disease: teethConditions[num])
    ).toList();
    
    final lowerTeethAdult = lowerNumbersAdult.map((num) =>
      ToothDisease(number: num, disease: teethConditions[num])
    ).toList();

    return _buildDetailSection(
      title: _translate('dental_chart'),
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
      child: Row(
        children: [
                  Icon(Icons.people, color: Colors.green[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                      'Adult Dental Chart (Permanent Teeth) - 16 upper, 16 lower teeth',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
          ),
        ],
      ),
            ),
            RepaintBoundary(
              child: DentalChartWidget(
                upperTeeth: upperTeethAdult,
                lowerTeeth: lowerTeethAdult,
                isChildChart: false,
              ),
            ),
          ],
        ),

        if (isChild && upperNumbersChild.isNotEmpty && lowerNumbersChild.isNotEmpty) ...[
          const SizedBox(height: 20),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.child_care, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Child Dental Chart (Primary Teeth) - 10 upper, 10 lower teeth',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              RepaintBoundary(
                child: DentalChartWidget(
                  upperTeeth: upperNumbersChild.map((num) =>
                    ToothDisease(number: num, disease: teethConditions[num])
                  ).toList(),
                  lowerTeeth: lowerNumbersChild.map((num) =>
                    ToothDisease(number: num, disease: teethConditions[num])
                  ).toList(),
                  isChildChart: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // =============================================
  // 🔥 DENTAL FORM DATA
  // =============================================

  Widget _buildDentalFormDataTable(Map<String, dynamic> dentalFormData) {
    if (dentalFormData.isEmpty) {
      return const SizedBox();
    }

    final Map<String, bool> dentalFormMap = _convertToDentalFormMap(dentalFormData);

    if (dentalFormMap.isEmpty) {
      return const SizedBox();
    }

    return Card(
            elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dental Form Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),
            DentalFormTableReadOnly(data: dentalFormMap),
          ],
              ),
      ),
    );
  }

  Map<String, bool> _convertToDentalFormMap(Map<String, dynamic> dentalFormData) {
    final Map<String, bool> result = {};

    final Map<String, String> fieldMapping = {
      'asa1': 'asa1',
      'asa2': 'asa2',
      'surgery4': 'surgery4',
      'cons4': 'cons4',
      'ortho4': 'ortho4',
      'peado4': 'peado4',
      'prostho4': 'prostho4',
      'endo4': 'endo4',
      'perio4': 'perio4',
      'oral_medicine4': 'oral_medicine4',
      'oral_surgery4': 'oral_surgery4',
      'endodontics4': 'endo4',
      'surgery5': 'surgery5',
      'cons5': 'cons5',
      'ortho5': 'ortho5',
      'peado5': 'peado5',
      'prostho5': 'prostho5',
      'endo5': 'endo5',
      'perio5': 'perio5',
      'oral_medicine5': 'oral_medicine5',
      'oral_surgery5': 'oral_surgery5',
      'endodontics5': 'endo5',
      'simple': 'simple',
      'complex': 'complex',
    };

    dentalFormData.forEach((key, value) {
      final keyStr = key.toString();
      final lower = keyStr.toLowerCase();

      if (fieldMapping.containsKey(lower)) {
        final mappedKey = fieldMapping[lower]!;
        result[mappedKey] = _convertToBool(value);
      }
    });

    return result;
  }

  bool _convertToBool(dynamic value) {
    if (value == null) return false;
    
    if (value is bool) {
      return value;
    }
    
    if (value is num) {
      return value == 1;
    }
    
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    
    return false;
  }

  // =============================================
  // 🔥 SCREENING DATA METHODS
  // =============================================

  Widget _buildScreeningDataTable(Map<String, dynamic> screeningData) {
    if (screeningData.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              'Screening Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (screeningData['chiefComplaint'] != null)
              _buildScreeningItem('Chief Complaint', screeningData['chiefComplaint'].toString()),
            
            if (screeningData['healthProblems'] != null)
              _buildHealthProblems(screeningData['healthProblems']),
            
            if (screeningData['categories'] != null)
              _buildCategories(screeningData['categories']),
            
            if (screeningData['dentalHistory'] is Map && screeningData['dentalHistory'] != null)
              _buildDentalHistoryTable(screeningData['dentalHistory'] as Map<String, dynamic>),
            
            if (screeningData['medicalHistory'] is Map && screeningData['medicalHistory'] != null)
              _buildMedicalHistoryTable(screeningData['medicalHistory'] as Map<String, dynamic>),
            
            if (screeningData['oralHygiene'] != null)
              _buildScreeningItem('Oral Hygiene', screeningData['oralHygiene'].toString()),
            
            if (screeningData['brushingFrequency'] != null)
              _buildScreeningItem('Brushing Frequency', screeningData['brushingFrequency'].toString()),
            
            if (screeningData['flossing'] != null)
              _buildScreeningItem('Flossing', _convertToYesNo(screeningData['flossing'])),
            
            if (screeningData['diet'] != null)
              _buildScreeningItem('Diet', screeningData['diet'].toString()),
            
            if (screeningData['totalScore'] != null)
              _buildScreeningItem('Total Score', screeningData['totalScore'].toString()),
            
            ..._getAdditionalScreeningFields(screeningData),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthProblems(dynamic healthProblems) {
    if (healthProblems == null) return const SizedBox();
    
    List<String> problemsList = [];

    if (healthProblems is String) {
      String cleanedString = healthProblems.replaceAll('[', '').replaceAll(']', '');
      
      if (cleanedString.contains(',')) {
        problemsList = cleanedString.split(',').map((problem) => problem.trim()).toList();
      } else {
        problemsList = [cleanedString.trim()];
      }
    } else if (healthProblems is List) {
      problemsList = healthProblems.map((item) => item.toString().trim()).toList();
    }
    
    problemsList = problemsList
        .where((problem) => problem.isNotEmpty && problem != '[' && problem != ']')
        .map((problem) => problem.replaceAll('[', '').replaceAll(']', '').trim())
        .where((problem) => problem.isNotEmpty)
        .toList();

    if (problemsList.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          const Text(
            'Health Problems',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...problemsList.map((problem) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    problem,
                    style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCategories(dynamic categories) {
    if (categories == null) return const SizedBox();
    
    List<Map<String, dynamic>> categoriesList = [];

    if (categories is List) {
      for (var item in categories) {
        if (item is Map && item['name'] != null) {
          categoriesList.add({
            'name': item['name'].toString(),
            'score': item['score']?.toString() ?? '0'
          });
        }
      }
    } else if (categories is String) {
      try {
        final parsed = json.decode(categories);
        if (parsed is List) {
          for (var item in parsed) {
            if (item is Map && item['name'] != null) {
              categoriesList.add({
                'name': item['name'].toString(),
                'score': item['score']?.toString() ?? '0'
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing categories: $e');
      }
    }

    if (categoriesList.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          const Text(
            'Categories',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...categoriesList.map((category) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    '${category['name']}: ${category['score']}',
                    style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                  ),
                ),
                    ],
                  ),
          )),
        ],
      ),
    );
  }

  Widget _buildScreeningItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getAdditionalScreeningFields(Map<String, dynamic> screeningData) {
    final List<Widget> additionalFields = [];
    final excludedFields = [
      'chiefComplaint', 'healthProblems', 'categories', 'dentalHistory', 'medicalHistory', 'oralHygiene',
      'brushingFrequency', 'flossing', 'diet', 'totalScore', 'timestamp'
    ];

    screeningData.forEach((key, value) {
      if (!excludedFields.contains(key) && value != null) {
        additionalFields.add(_buildScreeningItem(
          _formatFieldName(key),
          value.toString()
        ));
      }
    });

    return additionalFields;
  }

  Widget _buildDentalHistoryTable(Map<String, dynamic> dentalHistory) {
    if (dentalHistory.isEmpty) {
      return const SizedBox();
    }

    final List<Map<String, String>> questions = _getDentalHistoryQuestions(dentalHistory);

    if (questions.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Text(
              'Dental History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildSplitDentalHistoryTable(questions);
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildDentalHistoryTableContent(questions),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitDentalHistoryTable(List<Map<String, String>> questions) {
    final half = (questions.length / 2).ceil();
    final firstHalf = questions.sublist(0, half);
    final secondHalf = questions.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDentalHistoryTableContent(firstHalf),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDentalHistoryTableContent(secondHalf),
                    ),
      ],
    );
  }

  Widget _buildDentalHistoryTableContent(List<Map<String, String>> questions) {
    return DataTable(
      columnSpacing: 20,
      horizontalMargin: 0,
      columns: const [
        DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Answer', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: questions.map((q) {
        return DataRow(cells: [
          DataCell(Container(
            constraints: const BoxConstraints(minWidth: 200),
            child: Text(
              q['question']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
          )),
          DataCell(Text(
            q['answer']!,
            style: TextStyle(
              color: q['answer'] == 'Yes' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          )),
        ]);
      }).toList(),
    );
  }

  List<Map<String, String>> _getDentalHistoryQuestions(Map<String, dynamic> dentalHistory) {
    final Map<String, String> questionMap = {
      'bleedingGums': 'Do you have bleeding gums?',
      'sensitiveTeeth': 'Do you have sensitive teeth?',
      'badBreath': 'Do you have bad breath?',
      'painfulTeeth': 'Do you have painful teeth?',
      'clickingSound': 'Do you have clicking sound in jaw joint?',
      'mouthUlcers': 'Do you have mouth ulcers?',
      'previousExtraction': 'Have you had previous tooth extraction?',
      'previousRCT': 'Have you had root canal treatment?',
      'previousDentures': 'Do you have dentures?',
      'previousCrowns': 'Do you have crowns?',
      'previousFillings': 'Do you have fillings?',
      'orthodonticTreatment': 'Have you had orthodontic treatment?',
      'dryMouth': 'Do you ever feel like you have a dry mouth?',
      'localAnestheticReaction': 'Have you ever had an unusual reaction to local anesthetic?',
      'teethClenching': 'Do you clench your teeth?',
      'other': 'Other dental issues?',
    };

    final List<Map<String, String>> questions = [];

    dentalHistory.forEach((key, value) {
      if (value != null && questionMap.containsKey(key)) {
        final answer = _convertToYesNo(value);
        if (answer == 'Yes' || key == 'other') {
          questions.add({
            'question': questionMap[key]!,
            'answer': key == 'other' && value.toString().isNotEmpty ? value.toString() : answer,
          });
        }
      }
    });

    return questions;
  }

  String _convertToYesNo(dynamic value) {
    if (value == null) return 'No';
    
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    
    if (value is num) {
      return value == 1 ? 'Yes' : 'No';
    }
    
    if (value is String) {
      if (value.toLowerCase() == 'true' || value == '1') {
        return 'Yes';
      }
      if (value.toLowerCase() == 'false' || value == '0') {
        return 'No';
                    }
      return value.isNotEmpty ? value : 'No';
    }
    
    return 'No';
  }

  Widget _buildMedicalHistoryTable(Map<String, dynamic> medicalHistory) {
    if (medicalHistory.isEmpty) {
      return const SizedBox();
    }

    final List<Map<String, String>> questions = _getMedicalHistoryQuestions(medicalHistory);

    if (questions.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
            Text(
              'Medical History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
                              const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildSplitMedicalHistoryTable(questions);
                } else {
                  return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                    child: _buildMedicalHistoryTableContent(questions),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitMedicalHistoryTable(List<Map<String, String>> questions) {
    final half = (questions.length / 2).ceil();
    final firstHalf = questions.sublist(0, half);
    final secondHalf = questions.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMedicalHistoryTableContent(firstHalf),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMedicalHistoryTableContent(secondHalf),
        ),
      ],
    );
  }

  Widget _buildMedicalHistoryTableContent(List<Map<String, String>> questions) {
    return DataTable(
      columnSpacing: 20,
      horizontalMargin: 0,
      columns: const [
        DataColumn(label: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
      rows: questions.map((q) {
        return DataRow(cells: [
          DataCell(Container(
            constraints: const BoxConstraints(minWidth: 150),
            child: Text(
              q['question']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          )),
          DataCell(Text(
            q['answer']!,
            style: TextStyle(
              color: q['answer'] == 'Yes' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          )),
        ]);
      }).toList(),
    );
  }

  List<Map<String, String>> _getMedicalHistoryQuestions(Map<String, dynamic> medicalHistory) {
    final Map<String, String> questionMap = {
      'diabetes': 'Diabetes',
      'hypertension': 'Hypertension',
      'heartDisease': 'Heart Disease',
      'bleedingDisorders': 'Bleeding Disorders',
      'respiratoryDiseases': 'Respiratory Diseases',
      'kidneyDisease': 'Kidney Disease',
      'liverDisease': 'Liver Disease',
      'rheumaticFever': 'Rheumatic Fever',
      'allergies': 'Allergies',
      'asthma': 'Asthma',
      'pregnant': 'Pregnant',
      'breastFeeding': 'Breast Feeding',
      'other': 'Other Medical Conditions',
    };

    final List<Map<String, String>> questions = [];

    medicalHistory.forEach((key, value) {
      if (value != null && questionMap.containsKey(key)) {
        final answer = _convertToYesNo(value);
        if (answer == 'Yes' || key == 'other') {
          questions.add({
            'question': questionMap[key]!,
            'answer': key == 'other' && value.toString().isNotEmpty ? value.toString() : answer,
          });
        }
      }
    });

    return questions;
  }

  // =============================================
  // 🔥 EXAM DATA TABLE METHODS
  // =============================================

  Widget _buildExamDataTable(Map<String, dynamic> examData) {
    if (examData.isEmpty) {
      return Center(
        child: Text(
          'No examination data available',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: [
        _buildExtraoralExaminationSection(examData),
        _buildIntraoralExaminationSection(examData),
        _buildSoftTissueExaminationSection(examData),
        _buildOtherExamDataSection(examData),
      ],
    );
  }

  Widget _buildExtraoralExaminationSection(Map<String, dynamic> examData) {
    final extraoralFields = {
      'patientProfile': 'Patient Profile',
      'tmj': 'TMJ',
      'lymphNode': 'Lymph Node',
      'lipCompetency': 'Lip Competency',
      'facialSymmetry': 'Facial Symmetry',
    };

    final extraoralData = <String, dynamic>{};
    extraoralFields.forEach((key, label) {
      if (examData.containsKey(key) && examData[key] != null) {
        extraoralData[label] = examData[key];
      }
    });

    if (extraoralData.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extraoral Examination',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return _buildLargeScreenExtraoralLayout(extraoralData);
                } else if (constraints.maxWidth > 600) {
                  return _buildMediumScreenExtraoralLayout(extraoralData);
                } else {
                  return _buildSmallScreenExtraoralLayout(extraoralData);
                }
              },
                              ),
                            ],
                          ),
                        ),
    );
  }

  Widget _buildLargeScreenExtraoralLayout(Map<String, dynamic> extraoralData) {
    final entries = extraoralData.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = entries.sublist(0, half);
    final secondHalf = entries.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildExtraoralColumn(firstHalf),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildExtraoralColumn(secondHalf),
        ),
      ],
    );
  }

  Widget _buildMediumScreenExtraoralLayout(Map<String, dynamic> extraoralData) {
    final entries = extraoralData.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = entries.sublist(0, half);
    final secondHalf = entries.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildExtraoralColumn(firstHalf),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildExtraoralColumn(secondHalf),
        ),
      ],
    );
  }

  Widget _buildSmallScreenExtraoralLayout(Map<String, dynamic> extraoralData) {
    return _buildExtraoralColumn(extraoralData.entries.toList());
  }

  Widget _buildExtraoralColumn(List<MapEntry<String, dynamic>> entries) {
    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
            ),
          ),
        ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.value?.toString() ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntraoralExaminationSection(Map<String, dynamic> examData) {
    final intraoralFields = {
      'incisalClassification': 'Incisal Classification',
      'overjet': 'Overjet',
      'overbite': 'Overbite',
      'crossbite': 'Crossbite',
      'openBite': 'Open Bite',
    };

    final intraoralData = <String, dynamic>{};
    intraoralFields.forEach((key, label) {
      if (examData.containsKey(key) && examData[key] != null) {
        intraoralData[label] = examData[key];
  }
    });

    if (intraoralData.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intraoral Examination',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return _buildLargeScreenIntraoralLayout(intraoralData);
                } else if (constraints.maxWidth > 600) {
                  return _buildMediumScreenIntraoralLayout(intraoralData);
    } else {
                  return _buildSmallScreenIntraoralLayout(intraoralData);
    }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeScreenIntraoralLayout(Map<String, dynamic> intraoralData) {
    final entries = intraoralData.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = entries.sublist(0, half);
    final secondHalf = entries.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildIntraoralColumn(firstHalf),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildIntraoralColumn(secondHalf),
        ),
      ],
    );
  }

  Widget _buildMediumScreenIntraoralLayout(Map<String, dynamic> intraoralData) {
    final entries = intraoralData.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = entries.sublist(0, half);
    final secondHalf = entries.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildIntraoralColumn(firstHalf),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIntraoralColumn(secondHalf),
        ),
      ],
    );
  }

  Widget _buildSmallScreenIntraoralLayout(Map<String, dynamic> intraoralData) {
    return _buildIntraoralColumn(intraoralData.entries.toList());
  }

  Widget _buildIntraoralColumn(List<MapEntry<String, dynamic>> entries) {
    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.value?.toString() ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSoftTissueExaminationSection(Map<String, dynamic> examData) {
    final softTissueFields = {
      'hardPalate': 'Hard Palate',
      'buccalMucosa': 'Buccal Mucosa',
      'floorOfMouth': 'Floor of Mouth',
      'edentulousRidge': 'Edentulous Ridge',
      'tongue': 'Tongue',
    };

    final softTissueData = <String, dynamic>{};
    softTissueFields.forEach((key, label) {
      if (examData.containsKey(key) && examData[key] != null) {
        softTissueData[label] = examData[key];
      }
    });

    if (softTissueData.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soft Tissue Examination',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return _buildLargeScreenSoftTissueLayout(softTissueData);
                } else if (constraints.maxWidth > 600) {
                  return _buildMediumScreenSoftTissueLayout(softTissueData);
                } else {
                  return _buildSmallScreenSoftTissueLayout(softTissueData);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeScreenSoftTissueLayout(Map<String, dynamic> softTissueData) {
    final entries = softTissueData.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = entries.sublist(0, half);
    final secondHalf = entries.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSoftTissueColumn(firstHalf),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildSoftTissueColumn(secondHalf),
        ),
      ],
    );
  }

  Widget _buildMediumScreenSoftTissueLayout(Map<String, dynamic> softTissueData) {
    final entries = softTissueData.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = entries.sublist(0, half);
    final secondHalf = entries.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSoftTissueColumn(firstHalf),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSoftTissueColumn(secondHalf),
        ),
      ],
    );
  }

  Widget _buildSmallScreenSoftTissueLayout(Map<String, dynamic> softTissueData) {
    return _buildSoftTissueColumn(softTissueData.entries.toList());
  }

  Widget _buildSoftTissueColumn(List<MapEntry<String, dynamic>> entries) {
    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.value?.toString() ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOtherExamDataSection(Map<String, dynamic> examData) {
    final excludedFields = [
      'tmj', 'lymphNode', 'lipCompetency', 'facialSymmetry', 'patientProfile',
      'incisalClassification', 'overjet', 'overbite', 'crossbite', 'openBite',
      'hardPalate', 'buccalMucosa', 'floorOfMouth', 'edentulousRidge', 'tongue',
      'dentalChart', 'periodontalChart', 'dentalFormTable', 'periodontalRisk'
    ];

    final otherData = <String, dynamic>{};
    examData.forEach((key, value) {
      if (!excludedFields.contains(key) && value != null) {
        otherData[key] = value;
      }
    });

    if (otherData.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Other Examination Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildExamDataTableContent(otherData),
          ],
        ),
      ),
    );
  }

  Widget _buildExamDataTableContent(Map<String, dynamic> examData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 0,
        columns: const [
          DataColumn(label: Text('Field', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        rows: examData.entries.map((entry) {
          return DataRow(cells: [
            DataCell(Container(
              constraints: const BoxConstraints(minWidth: 150),
              child: Text(
                _formatExamFieldName(entry.key),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            )),
            DataCell(Text(
              entry.value?.toString() ?? 'Not specified',
              style: TextStyle(color: Colors.blue[700]),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatExamFieldName(String key) {
    final Map<String, String> nameMap = {
      'tmj': 'TMJ',
      'lymphNode': 'Lymph Nodes',
      'patientProfile': 'Patient Profile',
      'lipCompetency': 'Lip Competency',
      'incisalClassification': 'Incisal Classification',
      'overjet': 'Overjet',
      'overbite': 'Overbite',
      'hardPalate': 'Hard Palate',
      'buccalMucosa': 'Buccal Mucosa',
      'floorOfMouth': 'Floor of Mouth',
      'edentulousRidge': 'Edentulous Ridge',
      'periodontalRisk': 'Periodontal Risk',
      'facialSymmetry': 'Facial Symmetry',
      'crossbite': 'Crossbite',
      'openBite': 'Open Bite',
      'tongue': 'Tongue',
    };
    
    return nameMap[key] ?? _formatFieldName(key);
  }

  // =============================================
  // 🔥 PERIODONTAL CHART METHODS
  // =============================================

  Widget _buildPeriodontalChartTable(Map<String, dynamic> periodontalChart) {
    if (periodontalChart.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              'Periodontal Chart (BPE)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildSplitPeriodontalTable(periodontalChart);
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildPeriodontalChartTableContent(periodontalChart),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitPeriodontalTable(Map<String, dynamic> periodontalChart) {
    final entries = periodontalChart.entries.toList();
    final half = (entries.length / 2).ceil();
    final firstHalf = Map.fromEntries(entries.sublist(0, half));
    final secondHalf = Map.fromEntries(entries.sublist(half));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Expanded(
          child: _buildPeriodontalChartTableContent(firstHalf),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPeriodontalChartTableContent(secondHalf),
        ),
      ],
    );
  }

  Widget _buildPeriodontalChartTableContent(Map<String, dynamic> periodontalChart) {
    return DataTable(
      columnSpacing: 20,
      horizontalMargin: 0,
      columns: const [
        DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: [
        ...periodontalChart.entries.map((entry) {
          if (entry.key == 'periodontalRisk') return const DataRow(cells: []);
          
          final score = entry.value?.toString() ?? '0';
          return DataRow(cells: [
            DataCell(Container(
              constraints: const BoxConstraints(minWidth: 120),
              child: Text(_formatPeriodontalArea(entry.key)),
            )),
            DataCell(Text(score, style: TextStyle(fontWeight: FontWeight.bold, color: _getScoreColor(score)))),
          ]);
        }),
        if (periodontalChart.containsKey('periodontalRisk') || periodontalChart['periodontalRisk'] != null)
          DataRow(cells: [
            DataCell(Container(
              constraints: const BoxConstraints(minWidth: 120),
              child: const Text('Periodontal Risk', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
            DataCell(Text(
              periodontalChart['periodontalRisk']?.toString() ?? 'Not specified',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getPeriodontalRiskColor(periodontalChart['periodontalRisk']),
              ),
            )),
          ]),
        ],
    );
  }

  Color _getPeriodontalRiskColor(dynamic risk) {
    if (risk == null) return Colors.grey;
    
    final riskStr = risk.toString().toLowerCase();
    if (riskStr.contains('high') || riskStr.contains('3')) return Colors.red;
    if (riskStr.contains('medium') || riskStr.contains('2')) return Colors.orange;
    if (riskStr.contains('low') || riskStr.contains('1')) return Colors.green;
    
    return Colors.blue;
  }

  String _formatPeriodontalArea(String area) {
    final Map<String, String> areaMap = {
      'Upper right posterior': 'Upper Right Posterior',
      'Upper anterior': 'Upper Anterior', 
      'Upper left posterior': 'Upper Left Posterior',
      'Lower right posterior': 'Lower Right Posterior',
      'Lower anterior': 'Lower Anterior',
      'Lower left posterior': 'Lower Left Posterior'
    };
    
    return areaMap[area] ?? area;
  }

  Color _getScoreColor(String score) {
    switch (score) {
      case '0': return Colors.green;
      case '1': return Colors.blue;
      case '2': return Colors.orange;
      case '3': return Colors.orangeAccent;
      case '4': return Colors.red;
      default: return Colors.grey;
    }
  }

  // =============================================
  // 🔥 PRESCRIPTIONS SECTION
  // =============================================

  Widget _buildPrescriptionsCard(Map<String, dynamic> patientExam, BuildContext context) {
    final patient = safeConvertMap(patientExam['patient']);
    final String? patientId = patient['PATIENT_UID']?.toString() ?? patient['id']?.toString();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPrescriptionsForPatient(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          debugPrint('❌ Error loading prescriptions: ${snapshot.error}');
          return _buildErrorSection('Failed to load prescriptions');
        }
        
        final prescriptions = snapshot.data ?? [];
        if (prescriptions.isEmpty) {
          return _buildDetailSection(
            title: _translate('prescriptions'),
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.medication, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      _translate('no_prescriptions'),
                      style: TextStyle(
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return _buildDetailSection(
          title: '${_translate('prescriptions')} (${prescriptions.length})',
          children: [
            LayoutBuilder(
          builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildPrescriptionsTable(prescriptions);
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildPrescriptionsTable(prescriptions),
                  );
                }
              },
                            ),
          ],
                          );
                        },
                      );
  }

  Widget _buildPrescriptionsTable(List<Map<String, dynamic>> prescriptions) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 8,
      dataRowMaxHeight: 60,
      headingRowHeight: 50,
      columns: const [
        DataColumn(
          label: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Name of the prescribed medicine',
        ),
        DataColumn(
          label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Quantity of medicine',
        ),
        DataColumn(
          label: Text('Usage Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'How to use the medicine',
        ),
        DataColumn(
          label: Text('Prescribing Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Doctor who prescribed the medicine',
        ),
        DataColumn(
          label: Text('Prescription Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Date when prescription was created',
        ),
      ],
      rows: prescriptions.map((prescription) {
        return DataRow(
          cells: [
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 120),
                child: Text(
                  prescription['medicine_name']?.toString() ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 60),
                child: Text(
                  prescription['quantity']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  prescription['usage_time']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  prescription['doctor_name']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  _formatPrescriptionDate(prescription['prescription_date']),
                  style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatPrescriptionDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not specified';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
                } catch (e) {
      return dateString;
    }
  }

  // =============================================
  // 🔥 CLINICAL PROCEDURES SECTION
  // =============================================

  Widget _buildClinicalProceduresCard(Map<String, dynamic> patientExam, BuildContext context) {
    final patient = safeConvertMap(patientExam['patient']);
    final String? patientId = patient['PATIENT_UID']?.toString() ?? patient['id']?.toString();
    final String? patientIdNumber = patient['idNumber']?.toString() ?? patient['IDNUMBER']?.toString();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getClinicalProceduresForPatient(patientId, patientIdNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          debugPrint('❌ خطأ في تحميل الإجراءات السريرية: ${snapshot.error}');
          return _buildErrorSection('Failed to load clinical procedures');
        }
        
        final procedures = snapshot.data ?? [];
        if (procedures.isEmpty) {
          return _buildDetailSection(
            title: _translate('clinical_procedures'),
                    children: [
              Center(
                        child: Column(
                          children: [
                    Icon(Icons.medical_services, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      _translate('no_clinical_procedures'),
                                style: TextStyle(
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return _buildDetailSection(
          title: '${_translate('clinical_procedures')} (${procedures.length})',
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildClinicalProceduresTable(procedures);
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildClinicalProceduresTable(procedures),
                  );
                }
              },
                              ),
          ],
        );
      },
    );
  }

  Widget _buildClinicalProceduresTable(List<Map<String, dynamic>> procedures) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 8,
      dataRowMaxHeight: 60,
      headingRowHeight: 50,
      columns: const [
        DataColumn(
          label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Date of procedure',
        ),
        DataColumn(
          label: Text('Next Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Scheduled next visit date',
        ),
        DataColumn(
          label: Text('Procedure Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Type of procedure performed',
        ),
        DataColumn(
          label: Text('Tooth No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Tooth number treated',
        ),
        DataColumn(
          label: Text('Clinic Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Name of clinic where procedure was performed',
        ),
        DataColumn(
          label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Name of responsible student',
        ),
        DataColumn(
          label: Text('Supervisor Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          tooltip: 'Name of procedure supervisor',
        ),
      ],
      rows: procedures.map((procedure) {
        return DataRow(
          cells: [
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  _formatProcedureDate(procedure['date_of_operation']),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 110),
                child: Text(
                  _formatProcedureDate(procedure['date_of_second_visit']),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
                              Container(
                constraints: const BoxConstraints(minWidth: 120),
                child: Text(
                  procedure['type_of_operation']?.toString() ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                              ),
            ),
            DataCell(
                              Container(
                constraints: const BoxConstraints(minWidth: 60),
                child: Text(
                  procedure['tooth_no']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 80),
                child: Text(
                  procedure['clinic_name']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  procedure['student_name']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  procedure['supervisor_name']?.toString() ?? 'Not specified',
                  style: const TextStyle(fontSize: 12),
                ),
                        ),
                      ),
                    ],
                );
              }).toList(),
            );
  }

  String _formatProcedureDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not specified';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // =============================================
  // 🔥 PATIENT DETAILS
  // =============================================

  void _showPatientDetails(BuildContext context, Map<String, dynamic> patientExam) async {
    final patient = safeConvertMap(patientExam['patient']);
    final exam = safeConvertMap(patientExam['examination']);
    final doctor = safeConvertMap(patientExam['doctor']);

    _debugRawPatientData(patientExam);

    debugPrint('🔍 Starting patient details display:');
    debugPrint('   - patient: ${patient.keys}');
    debugPrint('   - exam: ${exam.keys}');
    debugPrint('   - examData type: ${exam['examData']?.runtimeType}');

    Map<String, dynamic> fullExamData = {};
    if ((exam['examData'] == null || (exam['examData'] is Map && (exam['examData'] as Map).isEmpty)) && 
        exam['EXAM_ID'] != null) {
      fullExamData = await _loadFullExaminationData(exam['EXAM_ID']);
      debugPrint('🔄 Loaded full data: ${fullExamData.isNotEmpty}');
    }

    final completeExamData = {
      ...exam,
      'examData': fullExamData['examData'] ?? exam['examData'] ?? {},
      'screening': fullExamData['screening'] ?? exam['screening'] ?? {},
      'dentalFormData': fullExamData['dentalFormData'] ?? exam['dentalFormData'] ?? {},
      'notes': fullExamData['notes'] ?? exam['notes'],
    };

    final examData = safeConvertMap(completeExamData['examData'] ?? {});
    final screeningData = safeConvertMap(completeExamData['screening'] ?? {});
    final dentalFormData = safeConvertMap(completeExamData['dentalFormData'] ?? {});

    debugPrint('📊 Final data for display:');
    debugPrint('   - examData: ${examData.length} items - ${examData.keys}');
    debugPrint('   - screening: ${screeningData.length} items - ${screeningData.keys}');
    debugPrint('   - dentalFormData: ${dentalFormData.length} items - ${dentalFormData.keys}');

    if (examData.isEmpty) {
      debugPrint('🔍 Searching for data in other levels...');
      
      final directExamData = exam.cast<String, dynamic>();
      debugPrint('   - exam directly: ${directExamData.keys.where((k) => k != 'examData' && k != 'screening' && k != 'dentalFormData').toList()}');
      
      final directKeys = directExamData.keys.where((k) => 
        k != 'examData' && k != 'screening' && k != 'dentalFormData' && 
        k != 'timestamp' && k != 'notes' && k != 'EXAM_ID' && k != 'EXAM_DATE' && k != 'DOCTOR_ID'
      ).toList();
      
      if (directKeys.isNotEmpty) {
        debugPrint('   ✅ Found direct data in exam: $directKeys');
        for (var key in directKeys) {
          examData[key] = directExamData[key];
        }
      }
    }

    final fullName = _getFullName(patient);
    final examDate = exam['timestamp'] != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(exam['timestamp']))
        : (exam['EXAM_DATE'] ?? _translate('unknown'));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(_translate('examination_details')),
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (_canEditExamination(patientExam))
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _navigateToEditExamination(patientExam),
                    tooltip: _translate('edit_examination'),
                  ),
                ),
            ],
          ),
          body: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: _buildPatientDetailsBody(
              context: context,
              patient: patient,
              doctor: doctor,
              fullName: fullName,
              examDate: examDate,
              examData: examData,
              screeningData: screeningData,
              dentalFormData: dentalFormData,
              completeExamData: completeExamData,
              patientExam: patientExam,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDetailsBody({
    required BuildContext context,
    required Map<String, dynamic> patient,
    required Map<String, dynamic> doctor,
    required String fullName,
    required String examDate,
    required Map<String, dynamic> examData,
    required Map<String, dynamic> screeningData,
    required Map<String, dynamic> dentalFormData,
    required Map<String, dynamic> completeExamData,
    required Map<String, dynamic> patientExam,
  }) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            title: _translate('patient_information'),
            children: [
              _buildAllPatientImages(patient),
              _buildDetailItem(_translate('name'), fullName),
              _buildDetailItem(_translate('age'), _calculateAge(patient['birthDate'] ?? patient['BIRTHDATE'])),
              _buildDetailItem(_translate('gender'), 
                  (patient['gender'] ?? patient['GENDER'] ?? _translate('unknown')).toString()),
              _buildDetailItem(_translate('phone'), 
                  (patient['phone'] ?? patient['PHONE'] ?? _translate('no_number')).toString()),
            ],
          ),

          _buildDetailSection(
            title: _translate('examination_information'),
            children: [
              _buildDetailItem(_translate('examining_doctor'),
                  (doctor['name'] ?? doctor['FULL_NAME'] ?? _translate('unknown')).toString()),
              _buildDetailItem(_translate('examination_date'), examDate),
            ],
          ),

          // ✅ NEW: Assigned Students Section - Added right after Examination Information
          _buildAssignedStudentsCard(patientExam, context),

          if (examData.isNotEmpty)
            _buildExamDataTable(examData),

          if (screeningData.isNotEmpty)
            _buildScreeningDataTable(screeningData),

          if (examData['periodontalChart'] != null && examData['periodontalChart'] is Map)
            _buildPeriodontalChartTable(examData['periodontalChart'] as Map<String, dynamic>),

          if (dentalFormData.isNotEmpty)
            _buildDentalFormDataTable(dentalFormData),

          if (examData['dentalChart'] != null)
            _buildDentalChartSection(examData['dentalChart'], patient),

          _buildPrescriptionsCard(patientExam, context),

          _buildClinicalProceduresCard(patientExam, context),

          // ✅ X-ray Images Section
          _buildXrayImagesCard(patientExam, context),

          if (examData.isEmpty && screeningData.isEmpty && dentalFormData.isEmpty)
            _buildDetailSection(
              title: 'Examination Data',
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No detailed examination data available',
                        style: TextStyle(
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data might be in different format',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
     ) );
  }

  // =============================================
  // 🔥 DEBUG METHODS
  // =============================================

  void _debugPatientData() {
    if (_examinedPatients.isNotEmpty) {
      debugPrint('=== 🔍 DEBUG PATIENT DATA ===');
      for (int i = 0; i < _examinedPatients.length; i++) {
        final patient = _examinedPatients[i]['patient'];
        debugPrint('Patient $i:');
        debugPrint('  - Name: ${_getFullName(patient)}');
        debugPrint('  - idImage: ${patient['idImage']}');
        debugPrint('  - IDIMAGE: ${patient['IDIMAGE']}');
        debugPrint('  - Has ID Image: ${(patient['idImage'] != null && patient['idImage'].toString().isNotEmpty) || (patient['IDIMAGE'] != null && patient['IDIMAGE'].toString().isNotEmpty)}');
        debugPrint('  - Is Child: ${_isChildPatient(patient)}');
      }
      debugPrint('=== 🏁 END DEBUG ===');
    }
  }

  // =============================================
  // 🔥 MAIN BUILD METHOD
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Localizations(
        locale: const Locale('en', 'US'),
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          _EnglishOnlyDelegate(),
        ],
        child: Scaffold(
      appBar: AppBar(
            title: Text(_translate('examined_patients')),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAllExaminationsDirect,
          ),
        ],
      ),
          drawer: _buildSidebar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return DoctorSidebar(
              primaryColor: primaryColor,
              accentColor: const Color(0xFF4AB8D8),
      userName: _doctorName ?? 'Doctor',
              userImageUrl: _doctorImageUrl,
      translate: (BuildContext context, String key) => _translate(key),
              parentContext: context,
      doctorUid: _currentUserId ?? '',
      allowedFeatures: _allowedFeatures ?? ['examined_patients', 'prescription'],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasError) {
      return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
            Text(_translate('error_loading')),
                      const SizedBox(height: 16),
                      ElevatedButton(
              onPressed: _loadAllExaminationsDirect,
              child: Text(_translate('retry')),
                      ),
                    ],
                  ),
      );
    }

    return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
              hintText: _translate('search_hint'),
              prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchResultsTotal > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _searchResultsTotal > _maxExaminationsToShow
                                ? 'Showing first ${_filteredExaminations.length} of $_searchResultsTotal results'
                                : 'Results: $_searchResultsTotal',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
            child: _filteredExaminations.isEmpty
                ? Center(child: Text(_translate('no_patients')))
                : RefreshIndicator(
                    onRefresh: _loadAllExaminationsDirect,
                        child: ListView.builder(
                          itemCount: _filteredExaminations.length,
                          itemBuilder: (context, index) {
                        return _buildPatientCard(_filteredExaminations[index], context);
                          },
                        ),
                      ),
          ),
                    ],
                  ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patientExam, BuildContext context) {
    final patient = safeConvertMap(patientExam['patient']);
    final exam = safeConvertMap(patientExam['examination']);
    final doctor = safeConvertMap(patientExam['doctor']);

    final fullName = _getFullName(patient);
    final phone = patient['phone'] ?? patient['PHONE'] ?? _translate('no_number');
    final age = _calculateAge(patient['birthDate'] ?? patient['BIRTHDATE']);
    final examDate = exam['timestamp'] != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(exam['timestamp']))
        : _translate('unknown');

    return SizedBox(
      width: double.infinity,
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        elevation: 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
      ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPatientDetails(context, patientExam),
          child: Padding(
            padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fullName.isNotEmpty ? fullName : _translate('unknown'),
            style: const TextStyle(
                          fontSize: 18,
              fontWeight: FontWeight.bold,
                          color: textPrimary,
            ),
          ),
                    ),
                    
                    if (_canEditExamination(patientExam))
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit, color: primaryColor, size: 20),
                          onPressed: () => _navigateToEditExamination(patientExam),
                          tooltip: _translate('edit_examination'),
                  ),
                ),
                    
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, '${_translate('age')}: $age'),
                _buildInfoRow(Icons.phone, '${_translate('phone')}: $phone'),
                _buildInfoRow(Icons.calendar_today, '${_translate('examination_date')}: $examDate'),
                _buildInfoRow(Icons.medical_services, 
                  '${_translate('examining_doctor')}: ${doctor['name'] ?? doctor['FULL_NAME'] ?? _translate('unknown')}'),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),);
  }

  String _formatFieldName(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(^| )[a-z]'), (Match m) => m[0]!.toUpperCase())
        .trim();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
