// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:dcs/config/api_config.dart';
import'../dashboard/doctor_dashboard.dart';

class AssignPatientsToStudentPage extends StatefulWidget {
  final String? patientId;
  final Map<String, dynamic>? patientData;
  const AssignPatientsToStudentPage({super.key, this.patientId, this.patientData});

  @override
  State<AssignPatientsToStudentPage> createState() => _AssignPatientsToStudentPageState();
}

class _AssignPatientsToStudentPageState extends State<AssignPatientsToStudentPage> {
  final String _apiBaseUrl = ApiConfig.baseUrl;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _patients = [];
  String? _selectedStudentId;
  Set<String> _selectedPatientIds = {};
  bool _isLoading = true;
  bool _saving = false;
  String _searchQuery = '';
  String _patientSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // إذا كان هناك patientId معطى، أضفه مباشرة للمختارين
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      _selectedPatientIds.add(widget.patientId!);
    }
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; });
    try {
      final studentsResponse = await http.get(Uri.parse('$_apiBaseUrl/students'));
      final patientsResponse = await http.get(Uri.parse('$_apiBaseUrl/patients'));

      
      if (studentsResponse.statusCode == 200 && patientsResponse.statusCode == 200) {
        final students = List<Map<String, dynamic>>.from(json.decode(studentsResponse.body));
        final patients = List<Map<String, dynamic>>.from(json.decode(patientsResponse.body));
        
        
        // 🔍 التحقق من هيكل بيانات الطلاب
        if (students.isNotEmpty) {
        }
        
        // 🔍 التحقق من هيكل بيانات المرضى
        if (patients.isNotEmpty) {
        }
        
    setState(() {
      _students = students;
          _patients = patients;
      _isLoading = false;
    });
      } else {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحميل البيانات')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحميل: $e')),
      );
    }
  }

  Future<void> _loadAssignedPatients(String studentId) async {
    if (studentId.isEmpty || studentId == 'null') {
      setState(() { 
        _selectedPatientIds = {};
        _isLoading = false;
      });
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/student_assignments/$studentId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
    setState(() {
          _selectedPatientIds = data.map((item) => item['patient_uid'].toString()).toSet();
      _isLoading = false;
    });
      } else {
        setState(() { _selectedPatientIds = {}; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _selectedPatientIds = {}; _isLoading = false; });
    }
  }

  Future<void> _saveAssignments() async {
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty || _selectedStudentId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار طالب أولاً')),
      );
      return;
    }

    // تصفية patient_uids من القيم الفارغة
    final validPatientUids = _selectedPatientIds.where((id) => id.isNotEmpty && id != 'null').toList();

    if (validPatientUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار مرضى على الأقل')),
      );
      return;
    }


    setState(() { _saving = true; });
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/student_assignments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': _selectedStudentId,
          'patient_uids': validPatientUids,
        }),
      );
      
    setState(() { _saving = false; });
      
      // ✅ يقبل كلا الـ status codes (200 و 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعيينات بنجاح')),
        );
        // العودة للصفحة السابقة بعد الحفظ
       Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
  (route) => false,
);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في حفظ التعيينات')),
        );
      }
    } catch (e) {
      setState(() { _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
  }
  }

  String _getFullName(Map<String, dynamic> user) {
    String fieldValue(List<String> keys) {
      for (final key in keys) {
        final value = user[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return '';
    }

    final fullName = fieldValue(['FULL_NAME', 'fullName', 'FULLNAME', 'full_name']);
    if (fullName.isNotEmpty) return fullName;

    final nameParts = [
      fieldValue(['FIRSTNAME', 'firstName', 'FIRST_NAME', 'first_name']),
      fieldValue(['FATHERNAME', 'fatherName', 'FATHER_NAME', 'father_name']),
      fieldValue(['GRANDFATHERNAME', 'grandfatherName', 'GRANDFATHER_NAME', 'grandfather_name']),
      fieldValue(['FAMILYNAME', 'familyName', 'FAMILY_NAME', 'family_name']),
    ].where((part) => part.isNotEmpty).toList();

    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }

    return fieldValue(['USERNAME', 'username', 'name']);
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final query = _searchQuery.toLowerCase();
    return _students.where((student) {
      final fullName = _getFullName(student).toLowerCase();
      final universityId = (student['STUDENT_UNIVERSITY_ID'] ?? student['universityId'] ?? student['student_id'] ?? '').toString().toLowerCase();
      return fullName.contains(query) || universityId.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPatients {
    List<Map<String, dynamic>> filtered;
    if (_patientSearchQuery.isEmpty) {
      filtered = List<Map<String, dynamic>>.from(_patients);
    } else {
      final query = _patientSearchQuery.toLowerCase();
      filtered = _patients.where((p) {
        final name = _getFullName(p).toLowerCase();
        final idNumber = (p['IDNUMBER'] ?? '').toString().toLowerCase();
        final patientId = _getPatientId(p).toLowerCase();
        return name.contains(query) || idNumber.contains(query) || patientId.contains(query);
      }).toList();
    }
    
    // ترتيب المختارين أولاً
    filtered.sort((a, b) {
      final aId = _getPatientId(a);
      final bId = _getPatientId(b);
      
      final aSelected = _selectedPatientIds.contains(aId) ? 0 : 1;
      final bSelected = _selectedPatientIds.contains(bId) ? 0 : 1;
      return aSelected.compareTo(bSelected);
    });
    
    return filtered;
  }

  String _getPatientId(Map<String, dynamic> patient) {
    // ✅ استخدام المفتاح الصحيح من البيانات القادمة من API
    final patientId = patient['ID']?.toString() ?? '';
    
    if (patientId.isNotEmpty) {
    }
    
    return patientId;
  }

  String _getStudentId(Map<String, dynamic> student) {
    const keys = [
      'ID',
      'id',
      'USERID',
      'userid',
      'student_id',
      'STUDENT_ID',
      'Student_ID',
      'StudentId',
      'STUDENTID',
      'studentId',
      'STUDENT_UNIVERSITY_ID',
      'UNIVERSITYID',
      'universityId',
    ];

    for (final key in keys) {
      final value = student[key];
      if (value != null) {
        final trimmed = value.toString().trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return '';
  }

  Widget _buildCurrentPatientInfo() {
    if (widget.patientData == null && widget.patientId == null) {
      return const SizedBox.shrink();
    }

    final patientData = widget.patientData ?? {};
    final patientId = widget.patientId ?? patientData['ID'] ?? patientData['id'];
    
    if (patientId == null) return const SizedBox.shrink();

    final firstName = patientData['FIRSTNAME'] ?? '';
    final fatherName = patientData['FATHERNAME'] ?? '';
    final grandFatherName = patientData['GRANDFATHERNAME'] ?? '';
    final familyName = patientData['FAMILYNAME'] ?? '';
    final fullName = [firstName, fatherName, grandFatherName, familyName].where((e) => e.isNotEmpty).join(' ');
    
    final idNumber = patientData['IDNUMBER'] ?? '';

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المريض الحالي من الفحص:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            if (fullName.isNotEmpty) Text('الاسم: $fullName'),
            if (idNumber != null && idNumber.toString().isNotEmpty) Text('رقم الهوية: $idNumber'),
            Text('المعرف: $patientId'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'سيتم إضافة هذا المريض تلقائياً للطالب المختار',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A7A94);
    
    // الحصول على بيانات الطالب المختار
    Map<String, dynamic> getSelectedStudent() {
      return _students.firstWhere(
        (s) => _getStudentId(s) == _selectedStudentId,
      orElse: () => {},
    );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: primaryColor,
          secondary: Colors.green.shade400,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعيين المرضى للطالب'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات المريض الحالي
                    _buildCurrentPatientInfo(),
                    
                    const SizedBox(height: 16),
                    
                    const Text('اختر الطالب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الطالب أو الرقم الجامعي',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          if (_selectedStudentId != null && !_filteredStudents.any((s) => _getStudentId(s) == _selectedStudentId)) {
                            _selectedStudentId = null;
                            _selectedPatientIds.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: _selectedStudentId == null
                          ? _buildStudentsList()
                          : _buildPatientsAssignment(getSelectedStudent()),
                    ),
                    
                    // زر الحفظ
                    if (_selectedStudentId != null) ...[
                      const SizedBox(height: 16),
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return _filteredStudents.isEmpty
        ? const Center(
            child: Text(
              'لا توجد طلاب متاحين',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView(
                              children: _filteredStudents.map((student) {
                                final name = _getFullName(student);
              final universityId = student['STUDENT_UNIVERSITY_ID'] ?? student['universityId'] ?? student['student_id'] ?? '';
              final studentId = _getStudentId(student);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(name.isNotEmpty ? name : 'بدون اسم'),
                  subtitle: universityId != '' ? Text('الرقم الجامعي: $universityId') : null,
                  leading: const Icon(Icons.person, color: Color(0xFF2A7A94)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    setState(() {
                      _selectedStudentId = studentId;
                                    });
                    _loadAssignedStudents(studentId);
                                  },
                ),
                                );
                              }).toList(),
          );
  }

  Future<void> _loadAssignedStudents(String studentId) async {
    await _loadAssignedPatients(studentId);
  }

  Widget _buildPatientsAssignment(Map<String, dynamic> selectedStudent) {
    final studentName = _getFullName(selectedStudent);
    
    return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
        // header مع معلومات الطالب
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _selectedStudentId = null;
                    _selectedPatientIds.clear();
                  }),
                                    ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                    Text(
                        studentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                      if ((selectedStudent['STUDENT_UNIVERSITY_ID'] ?? selectedStudent['universityId'] ?? selectedStudent['student_id']) != null)
                        Text(
                          'الرقم الجامعي: ${selectedStudent['STUDENT_UNIVERSITY_ID'] ?? selectedStudent['universityId'] ?? selectedStudent['student_id']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                ),
              ],
            ),
          ),
        ),
                                const SizedBox(height: 16),
        
        // بحث المرضى
        const Text('اختر المرضى:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: 'ابحث عن مريض بالاسم أو رقم الهوية',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        ),
                                        onChanged: (val) => setState(() => _patientSearchQuery = val),
                                      ),
        const SizedBox(height: 16),
        
        // قائمة المرضى
                                      Expanded(
          child: _buildPatientsList(),
        ),
      ],
    );
  }

  Widget _buildPatientsList() {
    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'لا توجد مرضى متاحين',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'عدد المرضى الأصلي: ${_patients.length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (_patients.isNotEmpty)
              Text(
                'المفاتيح المتاحة: ${_patients[0].keys}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('إعادة تحميل البيانات'),
            ),
          ],
        ),
      );
    }

    return ListView(
                                          children: _filteredPatients.map((patient) {
        final patientId = _getPatientId(patient);
                                            final name = _getFullName(patient);
        final idNumber = patient['IDNUMBER'] ?? '';
        final status = patient['STATUS'] ?? '';
        
        // تحديد إذا كان المريض الحالي من الفحص
        final isCurrentPatient = patientId == (widget.patientId ?? widget.patientData?['ID'] ?? widget.patientData?['id']);
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isCurrentPatient ? Colors.blue[50] : null,
          child: CheckboxListTile(
                                              value: _selectedPatientIds.contains(patientId),
                                              onChanged: (checked) {
                                                setState(() {
                                                  if (checked == true) {
                                                    _selectedPatientIds.add(patientId);
                                                  } else {
                                                    _selectedPatientIds.remove(patientId);
                                                  }
                                                });
                                              },
                                              title: Text(name.isNotEmpty ? name : 'بدون اسم'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (idNumber != null && idNumber.toString().isNotEmpty) 
                  Text('رقم الهوية: $idNumber'),
                if (status != null && status.toString().isNotEmpty)
                  Text('الحالة: $status', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('المعرف: $patientId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
            secondary: const Icon(Icons.person_outline),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _saveAssignments,
                                    style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A7A94),
                                      foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
                                    ),
        child: _saving 
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'حفظ التعيينات (${_selectedPatientIds.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
