// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../Doctor/doctor_sidebar.dart';
import '../loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/name_utils.dart';
import 'package:dcs/config/api_config.dart';

class ClinicalProceduresForm extends StatefulWidget {
  final String uid;
  const ClinicalProceduresForm({super.key, required this.uid});

  @override
  State<ClinicalProceduresForm> createState() => _ClinicalProceduresFormState();
}

class _ClinicalProceduresFormState extends State<ClinicalProceduresForm> {
  final String apiBaseUrl = ApiConfig.baseUrl; 
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final TextEditingController _dateOfOperationController = TextEditingController();
  final TextEditingController _typeOfOperationController = TextEditingController();
  final TextEditingController _toothNoController = TextEditingController();
  final TextEditingController _dateOfSecondVisitController = TextEditingController();
  final TextEditingController _supervisorNameController = TextEditingController();
  
  // Clinic selection
  String? _selectedClinic;
  final List<String> _clinics = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'
  ];
  
  // Student search
  final TextEditingController _studentSearchController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> foundStudents = [];
  String? _selectedStudentName;
  int? selectedStudentIndex;
  String? studentError;
  bool isSearchingStudent = false;
  Timer? _studentSearchDebounce;
  
  // Patient search
  final TextEditingController _patientSearchController = TextEditingController();
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> foundPatients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedPatientIdNumber;
  int? selectedPatientIndex;
  String? patientError;
  bool isSearchingPatient = false;
  
  // Doctor info
  String? _currentDoctorName;
  bool _isLoading = true;
  List<String> _allowedFeatures = const [];
  static const int _maxStudentsToShow = 30;
  int _studentSearchTotal = 0;
  
  // لمنع الضغط المتعدد
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final featuresFuture = _loadAllowedFeatures();
    try {
      await Future.wait([
        _fetchCurrentDoctorName(),
        _loadStudents(),
        _loadPatients()
      ]);
      final features = await featuresFuture;
      setState(() {
        _allowedFeatures = features;
      });
    } catch (e) {
      setState(() {
        _allowedFeatures = _getDefaultDoctorFeatures();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _loadAllowedFeatures() async {
    // 1) حاول تجيبها من الـ API مباشرة حسب صفحات الطبيب الأخرى
    if (widget.uid.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse('$apiBaseUrl/doctors/${widget.uid}'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final features = _extractAllowedFeatures(data);
          if (features.isNotEmpty) return features;
        }
      } catch (_) {}
    }

    // 2) fallback: جلبها من SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson != null) {
        final data = json.decode(userDataJson) as Map<String, dynamic>;
        final features = _processAllowedFeatures(data);
        if (features.isNotEmpty) return features;
      }
    } catch (_) {}

    // 3) fallback أخير: قائمة افتراضية كاملة للطبيب
    return _getDefaultDoctorFeatures();
  }

  List<String> _processAllowedFeatures(Map<String, dynamic> data) {
    final doctorMap = data['doctor'];
    if (doctorMap is Map<String, dynamic>) {
      final fromDoctor = _extractAllowedFeatures(doctorMap);
      if (fromDoctor.isNotEmpty) return fromDoctor;
    }

    final direct = _extractAllowedFeatures(data);
    if (direct.isNotEmpty) return direct;

    return [];
  }

  List<String> _getDefaultDoctorFeatures() {
    return [
      'waiting_list',
      'clinical_procedures_form',
      'students_evaluation',
      'supervision_groups',
      'examined_patients',
      'prescription',
      'xray_request',
    ];
  }

  List<String> _extractAllowedFeatures(dynamic source) {
    if (source is! Map<String, dynamic>) return [];

    final candidates = [
      source['ALLOWED_FEATURES'],
      source['allowedFeatures'],
    ];

    for (final value in candidates) {
      final normalized = _normalizeFeatures(value);
      if (normalized.isNotEmpty) return normalized;
    }

    return [];
  }

  List<String> _normalizeFeatures(dynamic value) {
    if (value == null) return [];
    try {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _fetchCurrentDoctorName() async {
    if (widget.uid.isEmpty) {
      _setUnknownSupervisor();
      return;
    }

    try {
      // Try doctors endpoint first
      final doctorResponse = await http.get(Uri.parse('$apiBaseUrl/doctors/${widget.uid}'));
      
      if (doctorResponse.statusCode == 200) {
        final doctorData = json.decode(doctorResponse.body) as Map<String, dynamic>;
        final fullName = _getFullName(doctorData);
        
        setState(() {
          _currentDoctorName = fullName;
          _supervisorNameController.text = _currentDoctorName!;
        });
        return;
      }
      
      // Fallback to users endpoint
      final userResponse = await http.get(Uri.parse('$apiBaseUrl/users/${widget.uid}'));
      
      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body) as Map<String, dynamic>;
        final fullName = _getFullName(userData);
        
        setState(() {
          _currentDoctorName = fullName;
          _supervisorNameController.text = _currentDoctorName!;
        });
        return;
      }
      
      _setUnknownSupervisor();
      
    } catch (e) {
      _setUnknownSupervisor();
    }
  }

  void _setUnknownSupervisor() {
    setState(() {
      _currentDoctorName = 'Unknown Supervisor';
      _supervisorNameController.text = _currentDoctorName!;
    });
  }

  String _getFullName(Map<String, dynamic> user) {
    final fullName = extractFullName(user);
    return fullName.isEmpty ? 'Unknown User' : fullName;
  }

  Future<void> _loadStudents() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/students-with-users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          students = data.map((studentData) {
            final searchText = _buildStudentSearchText(studentData);
            return {
              'id': studentData['id']?.toString() ?? studentData['userId']?.toString() ?? '',
              'userId': studentData['userId']?.toString() ?? studentData['id']?.toString() ?? '',
              'firstName': studentData['firstName']?.toString() ?? '',
              'fatherName': studentData['fatherName']?.toString() ?? '',
              'grandfatherName': studentData['grandfatherName']?.toString() ?? '',
              'familyName': studentData['familyName']?.toString() ?? '',
              'fullName': studentData['fullName']?.toString() ?? 'Student without name',
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
              'searchText': searchText,
            };
          }).toList();
        });
        
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _loadPatients() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/patients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          patients = data.cast<Map<String, dynamic>>();
        });
        
      } else {
      }
    } catch (e) {
    }
  }

  // Patient Search
  void searchPatient() {
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

    final filtered = patients.where((patient) {
      final searchQuery = query.toLowerCase();
      
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

      return name.contains(searchQuery) || 
             idNumber.contains(searchQuery) ||
             patientId.contains(searchQuery) ||
             medicalRecord.contains(searchQuery);
    }).toList();

    setState(() {
      foundPatients = filtered;
      patientError = filtered.isEmpty ? 'No patient found' : null;
      isSearchingPatient = false;
    });
  }

  // Student Search
  void searchStudent() {
    final query = _studentSearchController.text.trim();
    _studentSearchDebounce?.cancel();
    
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
      _studentSearchTotal = 0;
    });

    final loweredQuery = query.toLowerCase();
    _studentSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      final filtered = students.where((student) {
        final searchText = student['searchText']?.toString() ?? '';
        return searchText.contains(loweredQuery);
      }).toList();

      final limited = filtered.length > _maxStudentsToShow
          ? filtered.take(_maxStudentsToShow).toList()
          : filtered;

      setState(() {
        foundStudents = limited;
        _studentSearchTotal = filtered.length;
        studentError = filtered.isEmpty ? 'No student found' : null;
        isSearchingStudent = false;
      });
    });
  }

  String _buildStudentSearchText(Map<String, dynamic> studentData) {
    final parts = [
      studentData['fullName'],
      studentData['firstName'],
      studentData['fatherName'],
      studentData['grandfatherName'],
      studentData['familyName'],
      studentData['universityId'],
      studentData['studentUniversityId'],
      studentData['id'],
      studentData['userId'],
      studentData['username'],
      studentData['idNumber'],
      studentData['studentId'],
    ];

    return parts
        .where((element) => element != null && element.toString().isNotEmpty)
        .map((e) => e.toString().toLowerCase())
        .join(' ');
  }

  String _generateProcedureId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'PROC_${timestamp}_$random';
  }

  Future<void> _submitForm() async {
    // منع الضغط المتعدد
    if (_isSubmitting) return;
    
    // التحقق من صحة الفورم أولاً
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientIdNumber == null) {
      _showErrorSnackBar('Please select a valid patient');
      return;
    }

    if (_currentDoctorName == null || _currentDoctorName!.isEmpty || _currentDoctorName == 'Unknown Supervisor') {
      _showErrorSnackBar('Cannot determine supervisor name');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final procedureData = {
      'PROCEDURE_ID': _generateProcedureId(),
      'CLINIC_NAME': _selectedClinic,
      'DATE_OF_OPERATION': _dateOfOperationController.text,
      'DATE_OF_SECOND_VISIT': _dateOfSecondVisitController.text.isNotEmpty 
          ? _dateOfSecondVisitController.text 
          : null,
      'PATIENT_ID': _selectedPatientId,
      'PATIENT_ID_NUMBER': _selectedPatientIdNumber,
      'PATIENT_NAME': _selectedPatientName,
      'STUDENT_NAME': _selectedStudentName,
      'SUPERVISOR_NAME': _supervisorNameController.text,
      'TOOTH_NO': _toothNoController.text,
      'TYPE_OF_OPERATION': _typeOfOperationController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/clinical_procedures'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(procedureData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar('Clinical procedure saved successfully!');
        _resetForm();
      } else {
        _showErrorSnackBar('Failed to save clinical procedure: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving clinical procedure: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _dateOfOperationController.clear();
    _typeOfOperationController.clear();
    _toothNoController.clear();
    _dateOfSecondVisitController.clear();
    _studentSearchController.clear();
    _patientSearchController.clear();
    
    setState(() {
      _selectedClinic = null;
      _selectedPatientId = null;
      _selectedPatientName = null;
      _selectedPatientIdNumber = null;
      _selectedStudentName = null;
      selectedPatientIndex = null;
      selectedStudentIndex = null;
      foundPatients = [];
      foundStudents = [];
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _studentSearchDebounce?.cancel();
    _studentSearchDebounce = null;
    _dateOfOperationController.dispose();
    _typeOfOperationController.dispose();
    _toothNoController.dispose();
    _dateOfSecondVisitController.dispose();
    _supervisorNameController.dispose();
    _studentSearchController.dispose();
    _patientSearchController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  DoctorSidebar _buildSidebar() {
    final resolvedName = (_currentDoctorName?.trim().isNotEmpty ?? false)
        ? _currentDoctorName!.trim()
        : (_supervisorNameController.text.trim().isNotEmpty
            ? _supervisorNameController.text.trim()
            : 'Doctor');

    return DoctorSidebar(
      primaryColor: const Color(0xFF2A7A94),
      accentColor: Colors.teal,
      userName: resolvedName,
      userImageUrl: null,
      onLogout: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
      parentContext: context,
      collapsed: false,
      translate: (ctx, txt) => txt,
      doctorUid: widget.uid,
      allowedFeatures:
          _allowedFeatures.isNotEmpty ? _allowedFeatures : _getDefaultDoctorFeatures(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A7A94);
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 20),
              Text('Loading data...', style: TextStyle(color: primaryColor)),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Clinical Procedures Form', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildSidebar(),
      body: Container(
        color: primaryColor.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Patient Search Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Search',
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
                                  labelText: 'Search patient (name or ID)',
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

                // Patient Search Results
                if (foundPatients.isNotEmpty && selectedPatientIndex == null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Search Results (${foundPatients.length})',
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
                                : patient['FULL_NAME'] ?? 'Patient without name';
                            
                            final idNumber = patient['IDNUMBER'] ?? patient['PATIENT_UID'] ?? 'N/A';
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: selectedPatientIndex == i ? Colors.blue[50] : null,
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(displayName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID Number: $idNumber'),
                                    if (patient['MEDICAL_RECORD_NO'] != null)
                                      Text('Medical Record: ${patient['MEDICAL_RECORD_NO']}'),
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
                                    _selectedPatientIdNumber = patient['IDNUMBER']?.toString();
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

                // Selected Patient
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
                                  'Selected Patient: $_selectedPatientName',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'ID Number: ${foundPatients[selectedPatientIndex!]['IDNUMBER'] ?? ''}',
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
                                _selectedPatientIdNumber = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // Clinical Procedure Form (only show if patient is selected)
                if (_selectedPatientId != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinical Procedure Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date of Operation
                          GestureDetector(
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(), // منع التواريخ السابقة
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateOfOperationController.text = picked.toIso8601String().split('T')[0];
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateOfOperationController,
                                decoration: const InputDecoration(
                                  labelText: 'Date of Operation *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Type of Operation
                          TextFormField(
                            controller: _typeOfOperationController,
                            decoration: const InputDecoration(
                              labelText: 'Type of Operation *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Tooth Number
                          TextFormField(
                            controller: _toothNoController,
                            decoration: const InputDecoration(
                              labelText: 'Tooth Number *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Clinic Name Dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Clinic Name *',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedClinic,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Select Clinic'),
                              ),
                              ..._clinics.map((clinic) => DropdownMenuItem<String>(
                                value: clinic,
                                child: Text('Clinic $clinic'),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedClinic = val),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Student Search Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Responsible Student: *'),
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
                                                labelText: 'Search student (name or university ID)',
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

                              // Student Search Results
                              if (foundStudents.isNotEmpty && selectedStudentIndex == null)
                                Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _studentSearchTotal > _maxStudentsToShow
                                              ? 'Student Search Results (${foundStudents.length} shown of $_studentSearchTotal)'
                                              : 'Student Search Results (${foundStudents.length})',
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
                                          
                                          final fullName = student['fullName']?.toString() ?? 'Student without name';
                                          final universityId = student['universityId']?.toString() ?? student['studentUniversityId']?.toString() ?? 'N/A';
                                          
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
                                                  Text('University ID: $universityId'),
                                                  if (student['idNumber'] != null && student['idNumber'].toString().isNotEmpty)
                                                    Text('ID Number: ${student['idNumber']}'),
                                                ],
                                              ),
                                              trailing: selectedStudentIndex == i
                                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                                              onTap: () {
                                                setState(() {
                                                  selectedStudentIndex = i;
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

                              // Selected Student
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
                                                'Selected Student: $_selectedStudentName',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'University ID: ${foundStudents[selectedStudentIndex!]['universityId'] ?? foundStudents[selectedStudentIndex!]['studentUniversityId'] ?? ''}',
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

                          const SizedBox(height: 16),

                          // Supervisor Name (Auto-filled)
                          TextFormField(
                            controller: _supervisorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Supervisor Name *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.person),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),

                          // Loading/Warning Messages
                          if (_currentDoctorName == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  CircularProgressIndicator(strokeWidth: 2),
                                  SizedBox(width: 12),
                                  Text('Loading supervisor data...'),
                                ],
                              ),
                            )
                          else if (_currentDoctorName == 'Unknown Supervisor')
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Supervisor not recognized', style: TextStyle(color: Colors.orange)),
                                ],
                              ),
                            ),

                          // Date of Second Visit (Optional)
                          GestureDetector(
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              
                              // تحديد التاريخ الأولي بناءً على تاريخ العملية إذا كان محدداً
                              DateTime initialDate = DateTime.now();
                              if (_dateOfOperationController.text.isNotEmpty) {
                                initialDate = DateTime.parse(_dateOfOperationController.text);
                              }
                              
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime.now(), // منع التواريخ السابقة
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateOfSecondVisitController.text = picked.toIso8601String().split('T')[0];
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateOfSecondVisitController,
                                decoration: const InputDecoration(
                                  labelText: 'Date of Second Visit (Optional)',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: (_currentDoctorName == null || 
                                       _currentDoctorName!.isEmpty || 
                                       _currentDoctorName == 'Unknown Supervisor' ||
                                       _selectedStudentName == null ||
                                       _isSubmitting)
                                  ? null
                                  : _submitForm,
                              child: _isSubmitting
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        SizedBox(width: 8),
                                        Text('Saving...', style: TextStyle(fontSize: 16, color: Colors.white)),
                                      ],
                                    )
                                  : (_currentDoctorName == null || 
                                     _currentDoctorName!.isEmpty || 
                                     _currentDoctorName == 'Unknown Supervisor' ||
                                     _selectedStudentName == null)
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        SizedBox(width: 8),
                                        Text('Loading required data...', style: TextStyle(fontSize: 16, color: Colors.white)),
                                      ],
                                    )
                                  : const Text('Submit Form', style: TextStyle(fontSize: 16, color: Colors.white)),
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
}
