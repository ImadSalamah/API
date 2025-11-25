// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import 'admin_sidebar.dart';
import 'package:dcs/config/api_config.dart';

class AssignPatientsAdminPage extends StatefulWidget {
  final String? userName;
  final String? userImageUrl;
  final VoidCallback? onLogout;
  final List<Map<String, dynamic>> allUsers;

  const AssignPatientsAdminPage({
    super.key,
    this.userName,
    this.userImageUrl,
    this.onLogout,
    this.allUsers = const [],
  });

  @override
  State<AssignPatientsAdminPage> createState() => _AssignPatientsAdminPageState();
}

class _AssignPatientsAdminPageState extends State<AssignPatientsAdminPage> {
  final String _apiBaseUrl = ApiConfig.baseUrl;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _currentAssignments = [];
  String? _selectedPatientId;
  List<String> _selectedStudentIds = [];
  bool _isLoading = true;
  bool _saving = false;
  bool _clearing = false;
  String _patientSearchQuery = '';
  String _studentSearchQuery = '';
  bool isSidebarOpen = false;

  final Map<String, Map<String, String>> _translations = {
    'manage_patient_assignments': {'ar': 'إدارة تعيين المرضى للطلاب', 'en': 'Manage Patient Assignments'},
    'patients': {'ar': 'المرضى', 'en': 'Patients'},
    'students': {'ar': 'الطلاب', 'en': 'Students'},
    'assignments': {'ar': 'التعيينات', 'en': 'Assignments'},
    'search_patient': {'ar': 'ابحث عن المريض', 'en': 'Search Patient'},
    'search_patient_hint': {'ar': 'ابحث باسم المريض أو رقم الهوية', 'en': 'Search by patient name or ID number'},
    'search_student': {'ar': 'ابحث عن الطالب', 'en': 'Search Student'},
    'search_student_hint': {'ar': 'ابحث باسم الطالب أو الرقم الجامعي', 'en': 'Search by student name or university ID'},
    'select_responsible_students': {'ar': 'اختر الطلاب المسؤولين:', 'en': 'Select Responsible Students:'},
    'selected_patient': {'ar': 'المريض المختار:', 'en': 'Selected Patient:'},
    'id_number': {'ar': 'رقم الهوية:', 'en': 'ID Number:'},
    'currently_assigned_to': {'ar': 'مُعين حالياً لـ', 'en': 'Currently assigned to'},
    'students_assigned': {'ar': 'طالب', 'en': 'students'},
    'assigned_students': {'ar': 'الطلاب المعينين:', 'en': 'Assigned Students:'},
    'currently_assigned': {'ar': 'معين حالياً', 'en': 'Currently Assigned'},
    'add_new_students': {'ar': '✅ يمكنك إضافة طلاب جدد أو إزالة الطلاب الحاليين', 'en': '✅ You can add new students or remove current ones'},
    'selected_students': {'ar': 'تم اختيار', 'en': 'Selected'},
    'students_count': {'ar': 'طالب', 'en': 'students'},
    'add_new': {'ar': 'سيتم إضافة', 'en': 'Will add'},
    'new_students': {'ar': 'طالب جديد', 'en': 'new students'},
    'remove_students': {'ar': 'سيتم إزالة', 'en': 'Will remove'},
    'students_removed': {'ar': 'طالب', 'en': 'students'},
    'no_changes': {'ar': '🔄 لم يتم إجراء أي تغييرات', 'en': '🔄 No changes made'},
    'save_changes': {'ar': 'حفظ التغييرات', 'en': 'Save Changes'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'patients_list': {'ar': 'قائمة المرضى', 'en': 'Patients List'},
    'no_name': {'ar': 'بدون اسم', 'en': 'No Name'},
    'university_id': {'ar': 'الرقم الجامعي:', 'en': 'University ID:'},
    'delete_assignments': {'ar': 'حذف التعيينات', 'en': 'Delete Assignments'},
    'no_search_results': {'ar': 'لا توجد نتائج للبحث', 'en': 'No search results'},
    'no_students_available': {'ar': 'لا توجد طلاب متاحين', 'en': 'No students available'},
    'please_select_patient_and_students': {'ar': 'الرجاء اختيار مريض وطالب واحد على الأقل', 'en': 'Please select a patient and at least one student'},
    'assignment_success': {'ar': 'تم تعيين المريض بنجاح', 'en': 'Patient assigned successfully'},
    'assignment_failed': {'ar': 'حدث خطأ في التعيين', 'en': 'Assignment failed'},
    'remove_assignment_success': {'ar': 'تم إزالة تعيين المريض بنجاح', 'en': 'Patient assignment removed successfully'},
    'remove_assignment_failed': {'ar': 'فشل في إزالة التعيين', 'en': 'Failed to remove assignment'},
    'clear_all_success': {'ar': 'تم إزالة جميع التعيينات بنجاح', 'en': 'All assignments cleared successfully'},
    'clear_all_failed': {'ar': 'فشل إزالة التعيينات', 'en': 'Failed to clear assignments'},
    'confirm_delete_all': {'ar': 'تأكيد الحذف الكلي', 'en': 'Confirm Delete All'},
    'confirm_delete_all_message': {'ar': 'هل أنت متأكد أنك تريد إزالة جميع تعيينات المرضى؟', 'en': 'Are you sure you want to remove all patient assignments?'},
    'delete_options': {'ar': 'خيارات حذف التعيين', 'en': 'Delete Options'},
    'currently_assigned_to_students': {'ar': 'هذا المريض معين حالياً للطلاب:', 'en': 'This patient is currently assigned to students:'},
    'choose_action': {'ar': 'اختر الإجراء المطلوب:', 'en': 'Choose the required action:'},
    'delete_this_assignment_only': {'ar': 'حذف تعيين هذا المريض فقط', 'en': 'Delete this patient assignment only'},
    'delete_all_assignments': {'ar': 'حذف جميع التعيينات', 'en': 'Delete all assignments'},
    'failed_to_load_data': {'ar': 'فشل في تحميل البيانات الأساسية', 'en': 'Failed to load basic data'},
    'server_connection_error': {'ar': 'خطأ في الاتصال بالسيرفر', 'en': 'Server connection error'},
    'refresh_data': {'ar': 'تحديث البيانات', 'en': 'Refresh Data'},
  };

  String _tr(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final headers = await _getAuthHeaders();
      final studentsResponse = await http.get(Uri.parse('$_apiBaseUrl/students'), headers: headers);
      final patientsResponse = await http.get(Uri.parse('$_apiBaseUrl/patients'), headers: headers);
      
      http.Response assignmentsResponse;
      try {
        assignmentsResponse = await http.get(Uri.parse('$_apiBaseUrl/patient_assignments'), headers: headers);
      } catch (e) {
        assignmentsResponse = http.Response('[]', 200);
      }

      if (studentsResponse.statusCode == 200 && patientsResponse.statusCode == 200) {
        
        final students = List<Map<String, dynamic>>.from(json.decode(studentsResponse.body));
        final patients = List<Map<String, dynamic>>.from(json.decode(patientsResponse.body));
        
        List<Map<String, dynamic>> assignments = [];
        if (assignmentsResponse.statusCode == 200) {
          try {
            assignments = List<Map<String, dynamic>>.from(json.decode(assignmentsResponse.body));
          } catch (e) {
            assignments = [];
          }
        }
        
        setState(() {
          _students = students;
          _patients = patients;
          _currentAssignments = assignments;
          _isLoading = false;
        });
        
      } else {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'failed_to_load_data'))),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tr(context, 'server_connection_error')}: $e')),
      );
    }
  }

  Future<void> _assignPatientToStudents() async {
    if (_selectedPatientId == null || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr(context, 'please_select_patient_and_students'))),
      );
      return;
    }

    setState(() { _saving = true; });
    try {
      final headers = await _getAuthHeaders();
      final patientId = _selectedPatientId!;
      final cleared = await _clearAssignmentsForPatient(patientId, headers: headers);
      if (!cleared) {
        setState(() { _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'remove_assignment_failed'))),
        );
        return;
      }
      bool allSuccess = true;
      List<String> newStudentIds = [];
      
      for (String studentId in _selectedStudentIds) {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/assign_patient_to_student'),
          headers: headers,
          body: json.encode({
            'patient_id': patientId,
            'student_id': studentId,
          }),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          newStudentIds.add(studentId);
        } else {
          allSuccess = false;
          json.decode(response.body);
        }
      }
      
      setState(() { _saving = false; });
      
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_tr(context, 'assignment_success')} ${newStudentIds.length} ${_tr(context, 'students_count')}')),
        );
        await _loadData();
        _resetSelections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'assignment_failed'))),
        );
      }
    } catch (e) {
      setState(() { _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tr(context, 'assignment_failed')}: $e')),
      );
    }
  }

  Future<void> _removePatientAssignment(String patientId) async {
    setState(() { _saving = true; });
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/remove_patient_assignment/$patientId'),
        headers: headers,
      );
      
      setState(() { _saving = false; });
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'remove_assignment_success'))),
        );
        await _loadData();
        _resetSelections();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? _tr(context, 'remove_assignment_failed'))),
        );
      }
    } catch (e) {
      setState(() { _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tr(context, 'remove_assignment_failed')}: $e')),
      );
    }
  }

  Future<void> _clearAllAssignments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr(context, 'confirm_delete_all')),
        content: Text(_tr(context, 'confirm_delete_all_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_tr(context, 'delete_all_assignments'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() { _clearing = true; });
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse('$_apiBaseUrl/clear_all_assignments'), headers: headers);
      setState(() { _clearing = false; });
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'clear_all_success'))),
        );
        await _loadData();
        _resetSelections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'clear_all_failed'))),
        );
      }
      } catch (e) {
        setState(() { _clearing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_tr(context, 'clear_all_failed')}: $e')),
        );
      }
    }

  Future<bool> _clearAssignmentsForPatient(String patientId, {Map<String, String>? headers}) async {
    try {
      final authHeaders = headers ?? await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/remove_patient_assignment/$patientId'),
        headers: authHeaders,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _resetSelections() {
    setState(() {
      _selectedPatientId = null;
      _selectedStudentIds.clear();
    });
  }

  String _getFullName(Map<String, dynamic> user) {
    String fieldValue(List<String> keys) {
      for (final key in keys) {
        final value = user[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return '';
    }

    final fullName = fieldValue(['FULL_NAME', 'fullName']);
    if (fullName.isNotEmpty) return fullName;

    final nameParts = [
      fieldValue(['FIRSTNAME', 'firstName']),
      fieldValue(['FATHERNAME', 'fatherName']),
      fieldValue(['GRANDFATHERNAME', 'grandfatherName']),
      fieldValue(['FAMILYNAME', 'familyName']),
    ].where((part) => part.isNotEmpty).toList();

    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }

    return fieldValue(['USERNAME', 'username']);
  }

  String _getPatientId(Map<String, dynamic> patient) {
    return patient['ID']?.toString() ?? '';
  }

  static const List<String> _studentIdentifierKeys = [
    'ID',
    'student_id',
    'STUDENT_ID',
    'studentId',
    'USER_ID',
    'user_id',
    'userId',
    'STUDENT_UID',
    'student_uid',
    'STUDENT_UNIVERSITY_ID',
    'studentUniversityId',
    'USERNAME',
    'username',
    'UNIVERSITYID',
    'universityId',
  ];

  String _getStudentId(Map<String, dynamic> student) {
    return _extractIdentifier(student, _studentIdentifierKeys);
  }

  String _extractIdentifier(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null) {
        final trimmed = value.toString().trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return '';
  }

  Map<String, dynamic>? _findStudentById(String studentId) {
    for (final student in _students) {
      if (_getStudentId(student) == studentId) {
        return student;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_patientSearchQuery.isEmpty) return _patients;
    final query = _patientSearchQuery.toLowerCase();
    return _patients.where((patient) {
      final fullName = _getFullName(patient).toLowerCase();
      final idNumber = (patient['IDNUMBER']?.toString() ?? '').toLowerCase();
      return fullName.contains(query) || idNumber.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_studentSearchQuery.isEmpty) return _students;
    final query = _studentSearchQuery.toLowerCase();
    return _students.where((student) {
      final fullName = _getFullName(student).toLowerCase();
      final universityId = (student['STUDENT_UNIVERSITY_ID']?.toString() ?? student['UNIVERSITYID']?.toString() ?? '').toLowerCase();
      return fullName.contains(query) || universityId.contains(query);
    }).toList();
  }

  String _getAssignmentField(Map<String, dynamic> data, List<String> keys) {
    return _extractIdentifier(data, keys);
  }

  String _getAssignmentPatientId(Map<String, dynamic> assignment) {
    return _getAssignmentField(assignment, [
      'PATIENT_UID',
      'patient_uid',
      'PATIENT_ID',
      'patient_id',
      'PATIENTID',
      'patientId',
    ]);
  }

  String _getAssignmentStudentId(Map<String, dynamic> assignment) {
    return _extractIdentifier(assignment, _studentIdentifierKeys);
  }

  List<Map<String, dynamic>> _getAssignedStudentsForPatient(String patientId) {
    return _currentAssignments.where((assignment) {
      return _getAssignmentPatientId(assignment) == patientId;
    }).toList();
  }

  bool _isPatientAssigned(String patientId) {
    return _currentAssignments.any((assignment) => _getAssignmentPatientId(assignment) == patientId);
  }

  List<String> _getAssignedStudentNames(String patientId) {
    final assignments = _getAssignedStudentsForPatient(patientId);
    List<String> names = [];
    
    for (var assignment in assignments) {
      final studentId = _getAssignmentStudentId(assignment);
      final student = _students.firstWhere(
        (s) => _getStudentId(s) == studentId,
        orElse: () => <String, dynamic>{},
      );
      if (student.isNotEmpty) {
        names.add(_getFullName(student));
      }
    }
    
    return names;
  }

  List<String> _getAssignedStudentIds(String patientId) {
    final assignments = _getAssignedStudentsForPatient(patientId);
    List<String> ids = [];
    
    for (var assignment in assignments) {
      final studentId = _getAssignmentStudentId(assignment);
      if (studentId.isNotEmpty) {
        ids.add(studentId);
      }
    }
    
    return ids;
  }

  void _showAddStudentsDialog(String patientId) {
    final assignedStudentIds = _getAssignedStudentIds(patientId);
    
    setState(() {
      _selectedPatientId = patientId;
      _selectedStudentIds = List.from(assignedStudentIds);
    });
  }

  void _showDeleteOptionsDialog(String patientId) {
    final assignedStudents = _getAssignedStudentsForPatient(patientId);
    final assignedStudentNames = _getAssignedStudentNames(patientId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr(context, 'delete_options')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignedStudents.isNotEmpty) ...[
              Text(_tr(context, 'currently_assigned_to_students')),
              const SizedBox(height: 8),
              ...assignedStudentNames.map((name) => 
                Text('• $name', style: const TextStyle(fontWeight: FontWeight.bold))
              ),
              const SizedBox(height: 16),
            ],
            Text(_tr(context, 'choose_action')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_tr(context, 'cancel')),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removePatientAssignment(patientId);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: Text(_tr(context, 'delete_this_assignment_only')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllAssignments();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_tr(context, 'delete_all_assignments')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final textDirection = languageProvider.currentLocale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
    const primaryColor = Color(0xFF2A7A94);
    const accentColor = Color(0xFF4AB8D8);
    
    return Directionality(
      textDirection: textDirection,
      child: Builder(
        builder: (context) {
          final isRtl = Directionality.of(context) == TextDirection.rtl;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(_tr(context, 'manage_patient_assignments')),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false, // هذا السطر يزيل السهم التلقائي
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    isSidebarOpen = !isSidebarOpen;
                  });
                },
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatsCard(),
                            _buildPatientSearchSection(),
                            if (_selectedPatientId != null)
                              _buildStudentSelectionSection(),
                            _buildPatientsList(),
                          ],
                        ),
                      ),
                
                if (isSidebarOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isSidebarOpen = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withAlpha(77),
                        child: Align(
                          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {},
                            child: SizedBox(
                              width: 260,
                              height: double.infinity,
                              child: SafeArea(
                                child: Material(
                                  elevation: 8,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AdminSidebar(
                                          primaryColor: primaryColor,
                                          accentColor: accentColor,
                                          userName: widget.userName,
                                          userImageUrl: widget.userImageUrl,
                                          onLogout: widget.onLogout,
                                          parentContext: context,
                                          translate: _tr,
                                          allUsers: widget.allUsers,
                                          userRole: 'admin',
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: isRtl ? null : 0,
                                        left: isRtl ? 0 : null,
                                        child: IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              isSidebarOpen = false;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(_tr(context, 'patients'), _patients.length, Icons.people),
            _buildStatItem(_tr(context, 'students'), _students.length, Icons.school),
            _buildStatItem(_tr(context, 'assignments'), _currentAssignments.length, Icons.assignment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2A7A94)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPatientSearchSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(context, 'search_patient'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: _tr(context, 'search_patient_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setState(() => _patientSearchQuery = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelectionSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(context, 'select_responsible_students'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: _tr(context, 'search_student_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setState(() => _studentSearchQuery = val),
            ),
            const SizedBox(height: 12),
            _buildSelectedPatientInfo(),
            const SizedBox(height: 12),
            _buildStudentSelectionList(),
            const SizedBox(height: 12),
            if (_selectedStudentIds.isNotEmpty) ...[
              _buildSelectedStudentChips(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelectionList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _filteredStudents.isEmpty
            ? Center(child: Text(_tr(context, 'no_students_available')))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final studentId = _getStudentId(student);
                  final name = _getFullName(student);
                  final universityId = student['STUDENT_UNIVERSITY_ID']?.toString() ?? student['UNIVERSITYID']?.toString() ?? '';
                  final isSelected = _selectedStudentIds.contains(studentId);
                  
                  final isCurrentlyAssigned = _selectedPatientId != null && 
                      _getAssignedStudentIds(_selectedPatientId!).contains(studentId);
                  
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : _tr(context, 'no_name'),
                            style: TextStyle(
                              fontWeight: isCurrentlyAssigned ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCurrentlyAssigned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              _tr(context, 'currently_assigned'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: universityId.isNotEmpty ? Text('${_tr(context, 'university_id')} $universityId') : null,
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedStudentIds.add(studentId);
                        } else {
                          _selectedStudentIds.remove(studentId);
                        }
                      });
                    },
                );
              },
            ),
      ),
    );
  }

  Widget _buildSelectedStudentChips() {
    if (_selectedPatientId == null || _selectedStudentIds.isEmpty) {
      return const SizedBox();
    }

    final assignedIds = _selectedPatientId != null ? _getAssignedStudentIds(_selectedPatientId!) : [];
    final assignedSet = assignedIds.toSet();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _selectedStudentIds.map((studentId) {
        final student = _findStudentById(studentId);
        final studentName = student != null ? _getFullName(student) : '';
        final name = studentName.isNotEmpty ? studentName : studentId;
        final isAssigned = assignedSet.contains(studentId);

        return Chip(
          label: Text(name),
          backgroundColor: isAssigned ? Colors.green[50] : null,
          avatar: isAssigned
              ? const Icon(Icons.check_circle, size: 18, color: Colors.green)
              : null,
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedStudentIds.remove(studentId);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSelectedPatientInfo() {
    final patient = _patients.firstWhere(
      (p) => _getPatientId(p) == _selectedPatientId,
      orElse: () => <String, dynamic>{},
    );
    
    if (patient.isEmpty) return const SizedBox();
    
    final name = _getFullName(patient);
    final idNumber = patient['IDNUMBER']?.toString() ?? '';
    final assignedStudents = _getAssignedStudentsForPatient(_selectedPatientId!);
    final assignedStudentNames = _getAssignedStudentNames(_selectedPatientId!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_tr(context, 'selected_patient')} ${name.isNotEmpty ? name : _tr(context, 'no_name')}', 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        if (idNumber.isNotEmpty) Text('${_tr(context, 'id_number')} $idNumber'),
        if (assignedStudents.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_tr(context, 'currently_assigned_to')} ${assignedStudents.length} ${_tr(context, 'students_assigned')}',
                      style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (assignedStudentNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_tr(context, 'assigned_students')} ${assignedStudentNames.join("، ")}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _tr(context, 'add_new_students'),
                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildActionButtons() {
    final selectedStudentsCount = _selectedStudentIds.length;
    final assignedStudentIds = _selectedPatientId != null ? _getAssignedStudentIds(_selectedPatientId!) : [];
    final newStudentsCount = _selectedStudentIds.where((id) => !assignedStudentIds.contains(id)).length;
    final removedStudentsCount = assignedStudentIds.where((id) => !_selectedStudentIds.contains(id)).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_tr(context, 'selected_students')} $selectedStudentsCount ${_tr(context, 'students_count')}', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (newStudentsCount > 0) 
              Text('➕ ${_tr(context, 'add_new')} $newStudentsCount ${_tr(context, 'new_students')}',
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
            if (removedStudentsCount > 0)
              Text('➖ ${_tr(context, 'remove_students')} $removedStudentsCount ${_tr(context, 'students_removed')}',
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
            if (newStudentsCount == 0 && removedStudentsCount == 0)
              Text(_tr(context, 'no_changes'),
                  style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: _saving ? null : _assignPatientToStudents,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A7A94),
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_tr(context, 'save_changes')),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _resetSelections,
              child: Text(_tr(context, 'cancel')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientsList() {
    return _filteredPatients.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _tr(context, 'no_search_results'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_tr(context, 'patients_list')} (${_filteredPatients.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      onPressed: _clearing ? null : () => _showDeleteOptionsDialog('all'),
                      icon: _clearing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_forever),
                      label: Text(_tr(context, 'delete_assignments')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = _filteredPatients[index];
                  final patientId = _getPatientId(patient);
                  final name = _getFullName(patient);
                  final idNumber = patient['IDNUMBER']?.toString() ?? '';
                  final isAssigned = _isPatientAssigned(patientId);
                  final assignedStudents = _getAssignedStudentsForPatient(patientId);
                  final assignedStudentNames = _getAssignedStudentNames(patientId);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(name.isNotEmpty ? name : _tr(context, 'no_name')),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (idNumber.isNotEmpty) Text('${_tr(context, 'id_number')} $idNumber'),
                          if (isAssigned) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_tr(context, 'currently_assigned_to')} ${assignedStudents.length} ${_tr(context, 'students_assigned')}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            if (assignedStudentNames.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${_tr(context, 'assigned_students')} ${assignedStudentNames.join("، ")}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ]
                          ]
                        ],
                      ),
                      leading: Icon(
                        isAssigned ? Icons.check_circle : Icons.person_outline,
                        color: isAssigned ? Colors.green : Colors.grey,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAssigned)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _saving ? null : () => _showDeleteOptionsDialog(patientId),
                              tooltip: _tr(context, 'delete_options'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              _showAddStudentsDialog(patientId);
                            },
                            tooltip: _tr(context, 'select_responsible_students'),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showAddStudentsDialog(patientId);
                      },
                    ),
                  );
                },
              ),
            ],
          );
  }
}
