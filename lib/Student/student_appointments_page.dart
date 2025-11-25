  // ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
// ignore: duplicate_ignore
// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import '../Student/student_sidebar.dart';
import 'package:dcs/config/api_config.dart';
import '../utils/friendly_error.dart';

class StudentAppointmentsPage extends StatefulWidget {
  const StudentAppointmentsPage({super.key});

  @override
  _StudentAppointmentsPageState createState() => _StudentAppointmentsPageState();
}

class _StudentAppointmentsPageState extends State<StudentAppointmentsPage> {
  // قائمة العيادات الخارجية المتاحة (A-K بدون F)
  final List<String> outpatientClinics = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'G',
    'H',
    'I',
    'J',
    'K',
  ];
  String? selectedOutpatientClinic;
  // لا حاجة لمراجع Firebase

  // إضافة موعد للعيادات الخارجية (مفصول)
  Future<void> _addOutpatientAppointment() async {
    setState(() { _isLoading = true; });
    try {
      final appointmentData = {
        'date': selectedDate?.toIso8601String(),
        'start': startTime?.format(context),
        'end': endTime?.format(context),
        'patientUid': selectedPatientUid,
        'patientName': selectedPatientName,
        'clinic': selectedOutpatientClinic,
        'studentId': 'dummyStudentId', // استبدلها بالمعرف الحقيقي للطالب إذا توفر
      };
      final url = Uri.parse('${ApiConfig.baseUrl}/outpatientAppointments');
      final response = await http.post(url, body: json.encode(appointmentData), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          selectedDate = null;
          startTime = null;
          endTime = null;
          selectedPatientName = '';
          selectedPatientUid = '';
          selectedOutpatientClinic = null;
          _patientController.clear();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تم حجز موعد للعيادات الخارجية بنجاح' : 'Outpatient appointment booked successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
        await _fetchOutpatientAppointments();
      } else {
        throw Exception('API error: ${response.body}');
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      final message = friendlyErrorMessage(
        defaultMessage: _bookingErrorMessage(),
        connectionMessage: _connectionMessage(),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<Map<String, dynamic>> appointments = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> outpatientAppointments = <Map<String, dynamic>>[];
  // لا حاجة لمراجع Firebase
  bool _isLoading = false;
  String diseaseName = '';
  List<String> allDiseases = [];
  List<String> filteredDiseases = [];
  // لا حاجة لمراجع Firebase
  String selectedPatientName = '';
  String selectedPatientUid = '';
  List<Map<String, String>> allPatients = [];
  List<Map<String, String>> allPendingPatients = [];
  bool _isPendingPatient = false;
  final TextEditingController _patientController = TextEditingController();
  bool _patientNotFound = false;
  String? _studentName;
  String? _studentImageUrl;

  String _localeText(String arabic, String english) =>
      Localizations.localeOf(context).languageCode == 'ar' ? arabic : english;

  String _connectionMessage() =>
      _localeText('تعذر الاتصال، يرجى التحقق من الشبكة', 'Unable to connect, please check your connection');

  String _bookingErrorMessage() =>
      _localeText('تعذر إتمام الحجز، حاول مرة أخرى', 'Unable to book the appointment, please try again');

  @override
  void initState() {
    super.initState();
    _fetchStudentInfo();
    _fetchPatients();
    _fetchDiseases();
    _fetchStudentAppointments();
    _fetchOutpatientAppointments();
  }

  Future<void> _fetchOutpatientAppointments() async {
    // استبدل userId بقيمة الطالب الحقيقية إذا توفر
    const userId = 'dummyStudentId';
    final url = Uri.parse('${ApiConfig.baseUrl}/outpatientAppointments?studentId=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Map<String, dynamic>> loadedAppointments = data.cast<Map<String, dynamic>>();
      loadedAppointments.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        if (dateA != dateB) {
          return dateA.compareTo(dateB);
        }
        final timeA = a['start'];
        final timeB = b['start'];
        return timeA.compareTo(timeB);
      });
      setState(() {
        outpatientAppointments = loadedAppointments;
      });
    }
  }

  Future<void> _fetchStudentInfo() async {
    // استبدل userId بقيمة الطالب الحقيقية إذا توفر
    const userId = 'dummyStudentId';
    final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final firstName = data['firstName'] ?? '';
      final fatherName = data['fatherName'] ?? '';
      final grandfatherName = data['grandfatherName'] ?? '';
      final familyName = data['familyName'] ?? '';
      final fullName = [firstName, fatherName, grandfatherName, familyName]
          .where((part) => part.toString().isNotEmpty)
          .join(' ');
      setState(() {
        _studentName = fullName.isNotEmpty ? fullName : 'الطالب';
        _studentImageUrl = data['imageUrl'];
      });
    }
  }

  Future<void> _fetchPatients() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users?role=patient');
    final response = await http.get(url);
    final List<Map<String, String>> patients = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      for (final item in data) {
        final fullName = [
          item['firstName'],
          item['fatherName'],
          item['grandfatherName'],
          item['familyName']
        ].where((e) => e != null && e.toString().isNotEmpty).join(' ');
        patients.add({
          'uid': item['uid'].toString(),
          'name': fullName,
          'idNumber': item['idNumber'].toString(),
        });
      }
    }
    // Fetch pending patients
    final pendingUrl = Uri.parse('${ApiConfig.baseUrl}/pendingUsers?role=patient');
    final pendingResp = await http.get(pendingUrl);
    final List<Map<String, String>> pendingPatients = [];
    if (pendingResp.statusCode == 200) {
      final data = json.decode(pendingResp.body) as List;
      for (final item in data) {
        final fullName = [
          item['firstName'],
          item['fatherName'],
          item['grandfatherName'],
          item['familyName']
        ].where((e) => e != null && e.toString().isNotEmpty).join(' ');
        pendingPatients.add({
          'uid': item['uid'].toString(),
          'name': fullName,
          'idNumber': item['idNumber'].toString(),
        });
      }
    }
    setState(() {
      allPatients = patients;
      allPendingPatients = pendingPatients;
    });
  }

  Future<void> _fetchDiseases() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users?diseaseName=exists');
    final response = await http.get(url);
    final Set<String> diseasesSet = {};
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      for (final item in data) {
        if (item['diseaseName'] != null && item['diseaseName'].toString().isNotEmpty) {
          diseasesSet.add(item['diseaseName'].toString());
        }
      }
    }
    setState(() {
      allDiseases = diseasesSet.toList();
      filteredDiseases = allDiseases;
    });
  }

  Future<void> _fetchStudentAppointments() async {
    // استبدل userId بقيمة الطالب الحقيقية إذا توفر
    const userId = 'dummyStudentId';
    final url = Uri.parse('${ApiConfig.baseUrl}/appointments?studentId=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Map<String, dynamic>> loadedAppointments = data.cast<Map<String, dynamic>>();
      loadedAppointments.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        if (dateA != dateB) {
          return dateA.compareTo(dateB);
        }
        final timeA = a['start'];
        final timeB = b['start'];
        return timeA.compareTo(timeB);
      });
      setState(() {
        appointments = loadedAppointments;
      });
    }
  }

  Future<void> _deleteAppointment(String key) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/appointments/$key');
    await http.delete(url);
    await _fetchStudentAppointments();
    await _fetchOutpatientAppointments();
  }


  // إضافة موعد للفحص الأولي (مفصول)
  void _addAppointment() async {
    setState(() { _isLoading = true; });
    try {
      final appointmentData = {
        'date': selectedDate?.toIso8601String(),
        'start': startTime?.format(context),
        'end': endTime?.format(context),
        'patientUid': selectedPatientUid,
        'patientName': selectedPatientName,
        'studentId': 'dummyStudentId', // استبدلها بالمعرف الحقيقي للطالب إذا توفر
      };
      final url = Uri.parse('${ApiConfig.baseUrl}/appointments');
      final response = await http.post(url, body: json.encode(appointmentData), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchStudentAppointments();
        setState(() {
          selectedDate = null;
          startTime = null;
          endTime = null;
          selectedPatientName = '';
          selectedPatientUid = '';
          _patientController.clear();
          _isLoading = false;
        });
      } else {
        throw Exception('API error: ${response.body}');
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      final message = friendlyErrorMessage(
        defaultMessage: _bookingErrorMessage(),
        connectionMessage: _connectionMessage(),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() { selectedDate = picked; });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'مواعيدي' : 'My Appointments'),
        backgroundColor: const Color(0xFF2A7A94),
        centerTitle: true,
        elevation: 2,
      ),
      drawer: StudentSidebar(
        allowedFeatures: <String>[
  'view_examinations',
  'add_patient',
  'upload_xray',
],
        studentName: _studentName,
        studentImageUrl: _studentImageUrl,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 40 : 12,
          vertical: isTablet ? 30 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar' ? 'إضافة موعد جديد' : 'Add New Appointment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 22 : 18,
                        color: const Color(0xFF2A7A94),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _patientController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Localizations.localeOf(context).languageCode == 'ar' ? 'أدخل رقم هوية المريض' : 'Enter patient ID number',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedPatientName = '';
                          selectedPatientUid = '';
                          _patientNotFound = false;
                          _isPendingPatient = false;
                        });
                        if (value.isNotEmpty) {
                          final patient = allPatients.firstWhere(
                            (p) => p['idNumber'] == value,
                            orElse: () => {},
                          );
                          if (patient.isNotEmpty) {
                            setState(() {
                              selectedPatientName = patient['name'] ?? '';
                              selectedPatientUid = patient['uid'] ?? '';
                              _patientNotFound = false;
                              _isPendingPatient = false;
                            });
                            return;
                          }
                          // Check pending patients
                          final pendingPatient = allPendingPatients.firstWhere(
                            (p) => p['idNumber'] == value,
                            orElse: () => {},
                          );
                          if (pendingPatient.isNotEmpty) {
                            setState(() {
                              selectedPatientName = pendingPatient['name'] ?? '';
                              selectedPatientUid = pendingPatient['uid'] ?? '';
                              _patientNotFound = false;
                              _isPendingPatient = true;
                            });
                            return;
                          }
                          setState(() {
                            _patientNotFound = true;
                            _isPendingPatient = false;
                          });
                        }
                      },
                    ),
                    if (selectedPatientName.isNotEmpty && !_patientNotFound && !_isPendingPatient)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'اسم المريض: $selectedPatientName'
                              : 'Patient Name: $selectedPatientName',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (selectedPatientName.isNotEmpty && _isPendingPatient)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'اسم المريض: $selectedPatientName (تحت الموافقة)'
                              : 'Patient Name: $selectedPatientName (Pending Approval)',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_patientNotFound)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'رقم الهوية غير موجود. يرجى إنشاء حساب للمريض.'
                              : 'ID number not found. Please create an account for the patient.',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 400) {
                          // شاشة صغيرة: رتبهم عمودي
                          return Column(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, color: Color(0xFF2A7A94)),
                                label: Text(
                                  selectedDate == null
                                      ? (Localizations.localeOf(context).languageCode == 'ar' ? 'اختر اليوم' : 'Select day')
                                      : '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                                  style: const TextStyle(color: Color(0xFF2A7A94)),
                                ),
                                onPressed: _pickDate,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.access_time, color: Color(0xFF2A7A94)),
                                label: Text(
                                  startTime == null ? (Localizations.localeOf(context).languageCode == 'ar' ? 'من' : 'From') : startTime!.format(context),
                                  style: const TextStyle(color: Color(0xFF2A7A94)),
                                ),
                                onPressed: () => _pickTime(true),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.access_time_filled, color: Color(0xFF2A7A94)),
                                label: Text(
                                  endTime == null ? (Localizations.localeOf(context).languageCode == 'ar' ? 'إلى' : 'To') : endTime!.format(context),
                                  style: const TextStyle(color: Color(0xFF2A7A94)),
                                ),
                                onPressed: () => _pickTime(false),
                              ),
                            ],
                          );
                        } else {
                          // شاشة كبيرة: رتبهم أفقي
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today, color: Color(0xFF2A7A94)),
                                  label: Text(
                                    selectedDate == null
                                        ? (Localizations.localeOf(context).languageCode == 'ar' ? 'اختر اليوم' : 'Select day')
                                        : '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                                    style: const TextStyle(color: Color(0xFF2A7A94)),
                                  ),
                                  onPressed: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.access_time, color: Color(0xFF2A7A94)),
                                  label: Text(
                                    startTime == null ? (Localizations.localeOf(context).languageCode == 'ar' ? 'من' : 'From') : startTime!.format(context),
                                    style: const TextStyle(color: Color(0xFF2A7A94)),
                                  ),
                                  onPressed: () => _pickTime(true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.access_time_filled, color: Color(0xFF2A7A94)),
                                  label: Text(
                                    endTime == null ? (Localizations.localeOf(context).languageCode == 'ar' ? 'إلى' : 'To') : endTime!.format(context),
                                    style: const TextStyle(color: Color(0xFF2A7A94)),
                                  ),
                                  onPressed: () => _pickTime(false),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A7A94),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: TextStyle(fontSize: isTablet ? 18 : 16, color: Colors.white),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _addAppointment,
                                label: Text(
                                  Localizations.localeOf(context).languageCode == 'ar' ? 'إضافة الموعد للفحص الأولي' : 'Add Primary Exam Appointment',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // اختيار العيادة للعيادات الخارجية
                              DropdownButtonFormField<String>(
                                initialValue: selectedOutpatientClinic,
                                decoration: InputDecoration(
                                  labelText: Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'اختر العيادة الخارجية'
                                      : 'Select Outpatient Clinic',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: outpatientClinics
                                    .map((clinic) => DropdownMenuItem<String>(
                                          value: clinic,
                                          child: Text(clinic),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedOutpatientClinic = val;
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return Localizations.localeOf(context).languageCode == 'ar'
                                        ? 'يرجى اختيار العيادة'
                                        : 'Please select a clinic';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.local_hospital, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: TextStyle(fontSize: isTablet ? 18 : 16, color: Colors.white),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _addOutpatientAppointment,
                                label: Text(
                                  Localizations.localeOf(context).languageCode == 'ar' ? 'حجز للعيادات الخارجية' : 'Book Outpatient Appointment',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                // إذا الشاشة صغيرة (موبايل) اعرضهم فوق بعض، إذا كبيرة اعرضهم جنب بعض
                final isWide = constraints.maxWidth > 700;
                final children = [
                  // قائمة الفحص الأولي
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'مواعيد الفحص الأولي' : 'Primary Exam Appointments',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 15,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            if (appointments.isEmpty) {
                              return const Center(child: Text('لا يوجد مواعيد'));
                            }
                            final sortedAppointments = List<Map<String, dynamic>>.from(appointments);
                            sortedAppointments.sort((a, b) {
                              final dateA = DateTime.parse(a['date']);
                              final dateB = DateTime.parse(b['date']);
                              if (dateA != dateB) {
                                return dateB.compareTo(dateA);
                              }
                              final timeA = a['start'];
                              final timeB = b['start'];
                              return timeB.compareTo(timeA);
                            });
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedAppointments.length,
                              itemBuilder: (context, index) {
                                final appt = sortedAppointments[index];
                                final serial = appt['serial'] ?? (index + 1);
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF4AB8D8),
                                      child: Text(
                                        serial.toString(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      (Localizations.localeOf(context).languageCode == 'ar' ? 'اليوم: ' : 'Day: ') + DateTime.parse(appt['date']).toLocal().toString().split(' ')[0]),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("${Localizations.localeOf(context).languageCode == 'ar' ? 'من: ' : 'From: '}${appt['start']}"),
                                        Text("${Localizations.localeOf(context).languageCode == 'ar' ? 'إلى: ' : 'To: '}${appt['end']}"),
                                        Text((Localizations.localeOf(context).languageCode == 'ar' ? 'المريض: ' : 'Patient: ') + (appt['patientName'] ?? '')),
                                         Text(
                                           '${Localizations.localeOf(context).languageCode == 'ar' ? 'العيادة: ' : 'Clinic: '}F',
                                           style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                         ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'حذف الموعد',
                                      onPressed: () async {
                                        final key = appt['key'];
                                        if (key != null) {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تأكيد الحذف' : 'Confirm Deletion'),
                                              content: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'هل أنت متأكد أنك تريد حذف هذا الموعد؟' : 'Are you sure you want to delete this appointment?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'لا' : 'No'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'نعم' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _deleteAppointment(key);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تم حذف الموعد بنجاح' : 'Appointment deleted successfully'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 16),
                  // قائمة العيادات الخارجية
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'مواعيد العيادات الخارجية' : 'Outpatient Appointments',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 15,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            if (outpatientAppointments.isEmpty) {
                              return const Center(child: Text('لا يوجد مواعيد'));
                            }
                            final sortedAppointments = List<Map<String, dynamic>>.from(outpatientAppointments);
                            sortedAppointments.sort((a, b) {
                              final dateA = DateTime.parse(a['date']);
                              final dateB = DateTime.parse(b['date']);
                              if (dateA != dateB) {
                                return dateB.compareTo(dateA);
                              }
                              final timeA = a['start'];
                              final timeB = b['start'];
                              return timeB.compareTo(timeA);
                            });
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedAppointments.length,
                              itemBuilder: (context, index) {
                                final appt = sortedAppointments[index];
                                final serial = appt['serial'] ?? (index + 1);
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 2,
                                  color: Colors.green[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green[700],
                                      child: Text(
                                        serial.toString(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      (Localizations.localeOf(context).languageCode == 'ar' ? 'اليوم: ' : 'Day: ') + DateTime.parse(appt['date']).toLocal().toString().split(' ')[0]),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("${Localizations.localeOf(context).languageCode == 'ar' ? 'من: ' : 'From: '}${appt['start']}"),
                                        Text("${Localizations.localeOf(context).languageCode == 'ar' ? 'إلى: ' : 'To: '}${appt['end']}"),
                                        Text((Localizations.localeOf(context).languageCode == 'ar' ? 'المريض: ' : 'Patient: ') + (appt['patientName'] ?? '')),
                                        Text(
                                          (Localizations.localeOf(context).languageCode == 'ar'
                                              ? 'العيادة: '
                                              : 'Clinic: ') + (appt['clinic'] ?? ''),
                                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          Localizations.localeOf(context).languageCode == 'ar'
                                              ? 'موعد عيادات خارجية'
                                              : 'Outpatient Appointment',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'حذف الموعد',
                                      onPressed: () async {
                                        final key = appt['key'];
                                        if (key != null) {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تأكيد الحذف' : 'Confirm Deletion'),
                                              content: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'هل أنت متأكد أنك تريد حذف هذا الموعد؟' : 'Are you sure you want to delete this appointment?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'لا' : 'No'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'نعم' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            final url = Uri.parse('${ApiConfig.baseUrl}/outpatientAppointments/$key');
                                            await http.delete(url);
                                            await _fetchOutpatientAppointments();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تم حذف الموعد بنجاح' : 'Appointment deleted successfully'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ];
                if (isWide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
                } else {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [children[0], const SizedBox(height: 24), children[1]]);
                }
              },
            ),
// ...existing code...
          ],
        ),
      ),
    );
  }
}
