// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'doctor_sidebar.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/name_utils.dart';
import 'package:dcs/config/api_config.dart';

class PrescriptionPage extends StatefulWidget {
  final String uid;
  const PrescriptionPage({super.key, required this.uid});

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final String apiBaseUrl = ApiConfig.baseUrl;
  
  final List<String> medicines = [
    'Amoxicillin',
    'Metronidazole',
    'Ibuprofen',
    'Paracetamol',
    'Clindamycin',
    'Augmentin',
    'Naproxen',
    'Diclofenac',
    'Mefenamic Acid',
    'Chlorhexidine',
    'Aspirin',
    'Ciprofloxacin',
    'Other',
  ];
  
  final List<Map<String, dynamic>> prescriptions = [];
  String? selectedMedicine;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customController = TextEditingController();
  final TextEditingController patientSearchController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> foundPatients = [];
  int? selectedPatientIndex;
  String? patientError;
  bool isSearchingPatient = false;

  List<Map<String, String>> tempMedicines = [];

  String? _doctorName;
  String? _doctorImageUrl;
  List<String>? allowedFeatures;
  bool _isLoading = true;

  bool _isMounted = false;

  // إضافة GlobalKey للـ Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> get filteredMedicines {
    if (searchController.text.isEmpty) return medicines;
    return medicines
        .where((m) => m.toLowerCase().contains(searchController.text.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadInitialData();
  }

  @override
  void dispose() {
    _isMounted = false;
    searchController.dispose();
    customController.dispose();
    patientSearchController.dispose();
    timeController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback callback) {
    if (_isMounted) {
      setState(callback);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (_isMounted && ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _fetchCurrentDoctorName(),
        _loadPatients(),
        _loadAllowedFeatures(),
      ]);
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentDoctorName() async {
    if (widget.uid.isEmpty) {
      if (_isMounted) {
        _setUnknownDoctor();
      }
      return;
    }

    try {
      final doctorResponse = await http.get(Uri.parse('$apiBaseUrl/doctors/${widget.uid}'));
      
      if (doctorResponse.statusCode == 200) {
        final doctorData = json.decode(doctorResponse.body) as Map<String, dynamic>;
        final fullName = _getFullName(doctorData);
        
        if (_isMounted) {
          setState(() {
            _doctorName = fullName;
          });
        }
        return;
      }
      
      final userResponse = await http.get(Uri.parse('$apiBaseUrl/users/${widget.uid}'));
      
      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body) as Map<String, dynamic>;
        final fullName = _getFullName(userData);
        
        if (_isMounted) {
          setState(() {
            _doctorName = fullName;
          });
        }
        return;
      }
      
      if (_isMounted) {
        _setUnknownDoctor();
      }
      
    } catch (e) {
      if (_isMounted) {
        _setUnknownDoctor();
      }
    }
  }

  void _setUnknownDoctor() {
    if (_isMounted) {
      setState(() {
        _doctorName = 'Unknown Doctor';
      });
    }
  }

  String _getFullName(Map<String, dynamic> user) {
    final fullName = extractFullName(user);
    return fullName.isEmpty ? 'Unknown User' : fullName;
  }

  Future<void> _loadPatients() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/patients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (_isMounted) {
          setState(() {
            patients = data.cast<Map<String, dynamic>>();
          });
        }
        
      } else {
      }
    } catch (e) {
    }
  }
Future<void> _loadAllowedFeatures() async {
  try {
final response = await http.get(Uri.parse('$apiBaseUrl/doctors/${widget.uid}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (_isMounted) {
        setState(() {
          if (data['allowedFeatures'] is List) {
            allowedFeatures = List<String>.from(data['allowedFeatures']);
          } else if (data['allowedFeatures'] is Map) {
            allowedFeatures = (data['allowedFeatures'] as Map)
                .values
                .map((e) => e.toString())
                .toList();
          } else {
            allowedFeatures = [
              'waiting_list',
              'clinical_procedures_form',
              'students_evaluation',
              'supervision_groups',
              'examined_patients',
              'prescription',
              'xray_request',
            ];
          }
        });
      }
    } else {
      // 👈 مهم جداً: لو مش 200 برضو عبي allowedFeatures
      if (_isMounted) {
        setState(() {
          allowedFeatures = [
            'waiting_list',
            'clinical_procedures_form',
            'students_evaluation',
            'supervision_groups',
            'examined_patients',
            'prescription',
            'xray_request',
          ];
        });
      }
    }
  } catch (e) {
    if (_isMounted) {
      setState(() {
        allowedFeatures = [
          'waiting_list',
          'clinical_procedures_form',
          'students_evaluation',
          'supervision_groups',
          'examined_patients',
          'prescription',
          'xray_request',
        ];
      });
    }
  }
}

  void searchPatient() {
    final query = patientSearchController.text.trim();
    
    if (query.isEmpty) {
      if (_isMounted) {
        setState(() {
          foundPatients = [];
          patientError = null;
        });
      }
      return;
    }

    if (_isMounted) {
      setState(() { 
        isSearchingPatient = true;
        foundPatients = [];
        patientError = null;
      });
    }

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

    if (_isMounted) {
      setState(() {
        foundPatients = filtered;
        patientError = filtered.isEmpty ? 'No patient found' : null;
        isSearchingPatient = false;
      });
    }
  }

  String _getPatientAge(Map<String, dynamic> patient) {
    final birthDateValue = patient['BIRTHDATE'];
    if (birthDateValue == null) return 'Unknown';
    
    try {
      DateTime birthDate;
      if (birthDateValue is String) {
        birthDate = DateTime.parse(birthDateValue);
      } else if (birthDateValue is int) {
        birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateValue);
      } else {
        return 'Unknown';
      }
      
      final now = DateTime.now();
      if (birthDate.isAfter(now)) return 'Unknown';
      
      final age = now.difference(birthDate);
      final years = age.inDays ~/ 365;
      return years > 0 ? years.toString() : 'Less than a year';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getPatientName(Map<String, dynamic> patient) {
    final patientName = [
      patient['FIRSTNAME'] ?? '',
      patient['FATHERNAME'] ?? '',
      patient['GRANDFATHERNAME'] ?? '',
      patient['FAMILYNAME'] ?? ''
    ].where((e) => e != '').join(' ');
    
    return patientName.isNotEmpty 
        ? patientName 
        : patient['FULL_NAME'] ?? 'Patient without name';
  }

  String _getPatientIdNumber(Map<String, dynamic> patient) {
    return patient['IDNUMBER']?.toString() ?? patient['PATIENT_UID']?.toString() ?? '';
  }

  Future<void> addPrescriptionToOracle() async {
    
    if (selectedPatientIndex == null || tempMedicines.isEmpty) return;
    
    final foundPatient = foundPatients[selectedPatientIndex!];
    
    for (final med in tempMedicines) {
      final prescriptionData = {
        'PATIENT_ID': _getPatientIdNumber(foundPatient),
        'PATIENT_NAME': _getPatientName(foundPatient),
        'MEDICINE_NAME': med['medicine'] ?? '',
        'QUANTITY': med['quantity'] ?? '1',
        'USAGE_TIME': med['time'] ?? '',
        'DOCTOR_NAME': _doctorName ?? '',
        'DOCTOR_UID': widget.uid,
        'PRESCRIPTION_DATE': DateTime.now().toIso8601String().split('T')[0],
      };

      
      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/prescriptions'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(prescriptionData),
        );


        if (response.statusCode == 200 || response.statusCode == 201) {
        } else {
          try {
            json.decode(response.body);
          } catch (e) {
          }
        }
        
      } catch (e) {
        _showSnackBar('Network error: ${e.toString()}', isError: true);
      }
    }

    await fetchPatientPrescriptions(_getPatientIdNumber(foundPatient));
    
    if (_isMounted) {
      setState(() {
        tempMedicines.clear();
      });
    }
    
    _showSnackBar('Prescription(s) added successfully');
  }

  Future<void> fetchPatientPrescriptions(String patientId) async {
    
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/prescriptions/patient/$patientId'),
        headers: {'Accept': 'application/json'},
      );

      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        List<Map<String, dynamic>> prescriptionsList = [];
        
        for (var item in data) {
          prescriptionsList.add(_parsePrescriptionData(item));
        }
        
        if (_isMounted) {
          setState(() {
            prescriptions.clear();
            prescriptions.addAll(prescriptionsList);
          });
        }
      } else if (response.statusCode == 404) {
        if (_isMounted) {
          setState(() {
            prescriptions.clear();
          });
        }
        _showSnackBar('No previous prescriptions found for this patient');
      } else {
        _showSnackBar('Error loading patient prescriptions', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error loading patient prescriptions', isError: true);
    }
  }

  Map<String, dynamic> _parsePrescriptionData(dynamic item) {
    try {
      return {
        'prescriptionId': item['PRESCRIPTION_ID']?.toString() ?? '',
        'medicine': item['MEDICINE_NAME']?.toString() ?? '',
        'patientName': item['PATIENT_NAME']?.toString() ?? '',
        'patientId': item['PATIENT_ID']?.toString() ?? '',
        'time': item['USAGE_TIME']?.toString() ?? '',
        'quantity': item['QUANTITY']?.toString() ?? '1',
        'createdAt': item['CREATED_DATE']?.toString() ?? DateTime.now().toString(),
        'doctorName': item['DOCTOR_NAME']?.toString() ?? '',
        'doctorUid': item['DOCTOR_UID']?.toString() ?? '',
      };
    } catch (e) {
      return {
        'prescriptionId': '',
        'medicine': '',
        'patientName': '',
        'patientId': '',
        'time': '',
        'quantity': '1',
        'createdAt': DateTime.now().toString(),
        'doctorName': '',
        'doctorUid': '',
      };
    }
  }

  bool _isPrescriptionOwner(Map<String, dynamic> prescription) {
    final prescriptionDoctorUid = prescription['doctorUid']?.toString() ?? '';
    final currentDoctorUid = widget.uid;
    return prescriptionDoctorUid == currentDoctorUid;
  }

  Future<void> deletePrescriptionFromOracle(String prescriptionId) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/prescriptions/$prescriptionId?doctorUid=${widget.uid}');
      
      final response = await http.delete(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        if (selectedPatientIndex != null) {
          final foundPatient = foundPatients[selectedPatientIndex!];
          await fetchPatientPrescriptions(_getPatientIdNumber(foundPatient));
        }
        _showSnackBar('Prescription deleted successfully');
      } else if (response.statusCode == 403) {
        _showSnackBar('Access denied: You can only delete your own prescriptions', isError: true);
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('Error deleting prescription: ${errorData['message']}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error deleting prescription', isError: true);
    }
  }

  // دالة لتعديل الوصفة الطبية
  Future<void> updatePrescriptionInOracle(Map<String, dynamic> prescription) async {
    
    try {
      final updateData = {
        'PATIENT_ID': prescription['patientId'],
        'PATIENT_NAME': prescription['patientName'],
        'MEDICINE_NAME': prescription['medicine'],
        'QUANTITY': prescription['quantity'],
        'USAGE_TIME': prescription['time'],
        'DOCTOR_NAME': _doctorName ?? '',
        'DOCTOR_UID': widget.uid,
        'PRESCRIPTION_DATE': prescription['createdAt'].split(' ')[0],
      };

      
      final response = await http.put(
        Uri.parse('$apiBaseUrl/prescriptions/${prescription['prescriptionId']}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(updateData),
      );


      if (response.statusCode == 200) {
        _showSnackBar('Prescription updated successfully');
        
        if (selectedPatientIndex != null) {
          final foundPatient = foundPatients[selectedPatientIndex!];
          await fetchPatientPrescriptions(_getPatientIdNumber(foundPatient));
        }
      } else if (response.statusCode == 403) {
        _showSnackBar('Access denied: You can only update your own prescriptions', isError: true);
      } else {
        try {
          final errorData = json.decode(response.body);
          _showSnackBar('Error updating prescription: ${errorData['message']}', isError: true);
        } catch (e) {
          _showSnackBar('Error updating prescription', isError: true);
        }
      }
      
    } catch (e) {
      _showSnackBar('Network error: ${e.toString()}', isError: true);
    }
  }

  // دالة لعرض نافذة التعديل
  void _showEditPrescriptionDialog(Map<String, dynamic> prescription) {
    final medicineController = TextEditingController(text: prescription['medicine'] ?? '');
    final quantityController = TextEditingController(text: prescription['quantity'] ?? '1');
    final timeController = TextEditingController(text: prescription['time'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Prescription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 30 capsules',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Usage Time',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Twice daily after meals',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (medicineController.text.isEmpty || timeController.text.isEmpty) {
                _showSnackBar('Please fill all required fields', isError: true);
                return;
              }
              
              final updatedPrescription = Map<String, dynamic>.from(prescription);
              updatedPrescription['medicine'] = medicineController.text;
              updatedPrescription['quantity'] = quantityController.text.isEmpty ? '1' : quantityController.text;
              updatedPrescription['time'] = timeController.text;
              
              Navigator.pop(context);
              updatePrescriptionInOracle(updatedPrescription);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void addMedicineToTempList() {
    String? med = selectedMedicine == 'Other'
        ? customController.text.trim()
        : selectedMedicine;
    if (med == null || med.isEmpty || timeController.text.isEmpty) return;
    
    if (_isMounted) {
      setState(() {
        tempMedicines.add({
          'medicine': med,
          'time': timeController.text,
          'quantity': quantityController.text.isNotEmpty ? quantityController.text : '1',
        });
        if (selectedMedicine == 'Other' && med.isNotEmpty && !medicines.contains(med)) {
          medicines.insert(medicines.length - 1, med);
        }
        selectedMedicine = null;
        customController.clear();
        timeController.clear();
        quantityController.clear();
      });
    }
  }

  void removeMedicineFromTempList(int index) {
    if (_isMounted) {
      setState(() {
        tempMedicines.removeAt(index);
      });
    }
  }

  Future<void> addPrescription() async {
    await addPrescriptionToOracle();
  }

 // دالة PDF محدثة مع دعم للغة العربية باستخدام خط Cairo
Future<void> _generatePDF() async {
  // تأكد في مريض مختار وفي أدوية مضافة
  if (selectedPatientIndex == null || tempMedicines.isEmpty) return;

  final foundPatient = foundPatients[selectedPatientIndex!];

  try {
    // 1) تحميل خط Cairo من مجلد الأصول
    final cairoFont = pw.Font.ttf(
      await rootBundle.load('assets/Cairo-Regular.ttf'),
    );

    // 2) إنشاء الوثيقة مع تفعيل الخط كـ base و bold
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: cairoFont,
          bold: cairoFont,
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl, // عشان العربي يظهر صح
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'الوصفة الطبية',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    font: cairoFont,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // بيانات المريض
                pw.Text(
                  'المريض: ${_getPatientName(foundPatient)}'
                  '\nالعمر: ${_getPatientAge(foundPatient)}'
                  '\nالرقم: ${_getPatientIdNumber(foundPatient)}',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    font: cairoFont,
                  ),
                ),
                pw.SizedBox(height: 12),

                // عنوان الأدوية
                pw.Text(
                  'الأدوية:',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    font: cairoFont,
                  ),
                ),
                pw.SizedBox(height: 8),

                // قائمة الأدوية
                ...tempMedicines.map(
                  (med) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      '- ${med['medicine']}  |  الكمية: ${med['quantity']}  |  الوقت: ${med['time']}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        font: cairoFont,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 16),

                // اسم الدكتور
                pw.Text(
                  'الطبيب: ${_doctorName ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    font: cairoFont,
                  ),
                ),
                pw.SizedBox(height: 8),

                // التاريخ
                pw.Text(
                  'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: cairoFont,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 3) طباعة / عرض الـ PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  } catch (e) {
    _showSnackBar('Error generating PDF: $e', isError: true);
  }
}

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A7A94);
    const accentColor = Color(0xFF4AB8D8);
    
    // الحصول على language provider
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Loading data...', style: TextStyle(color: primaryColor)),
            ],
          ),
        ),
      );
    }
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: allowedFeatures == null
            ? const Drawer(child: Center(child: CircularProgressIndicator()))
            : DoctorSidebar(
              primaryColor: primaryColor,
              accentColor: accentColor,
              userName: _doctorName ?? '',
              userImageUrl: _doctorImageUrl,
              parentContext: context,
              collapsed: false,
              translate: (ctx, key) => key,
              doctorUid: widget.uid,
              allowedFeatures: allowedFeatures!,
            ),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(isArabic ? 'الوصفات الطبية' : 'Prescription'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'البحث عن المريض بالاسم أو الرقم:' : 'Search patient by name or ID:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: patientSearchController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'اسم المريض أو الرقم' : 'Patient name or ID',
                                prefixIcon: const Icon(Icons.person_search),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => searchPatient(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: isSearchingPatient ? null : searchPatient,
                            icon: isSearchingPatient
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.search, color: Colors.blue),
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
                      
                      if (foundPatients.isNotEmpty && selectedPatientIndex == null)
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              isArabic ? 'المرضى الموجودون:' : 'Found patients:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...foundPatients.asMap().entries.map((entry) {
                              final i = entry.key;
                              final patient = entry.value;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.grey[50],
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.person, color: Colors.blue),
                                  title: Text(
                                    _getPatientName(patient),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${isArabic ? 'الرقم:' : 'ID:'} ${_getPatientIdNumber(patient)}',
                                  ),
                                  selected: selectedPatientIndex == i,
                                  onTap: () {
                                    _safeSetState(() {
                                      selectedPatientIndex = i;
                                    });
                                    final patientId = _getPatientIdNumber(patient);
                                    fetchPatientPrescriptions(patientId);
                                    FocusScope.of(context).unfocus();
                                  },
                                  trailing: selectedPatientIndex == i
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      
                      if (selectedPatientIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? 'المريض المختار:' : 'Selected Patient:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        _getPatientName(foundPatients[selectedPatientIndex!]),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${isArabic ? 'الرقم:' : 'ID:'} ${_getPatientIdNumber(foundPatients[selectedPatientIndex!])}',
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _safeSetState(() {
                                      selectedPatientIndex = null;
                                      prescriptions.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const Divider(height: 30),
                      
                      Text(
                        isArabic ? 'اختر الدواء:' : 'Select medicine:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'ابحث عن الدواء' : 'Search medicine',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => _safeSetState(() {}),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedMedicine,
                        items: filteredMedicines.map((med) {
                          return DropdownMenuItem(
                            value: med,
                            child: Text(med),
                          );
                        }).toList(),
                        onChanged: (val) {
                          _safeSetState(() {
                            selectedMedicine = val;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اختر الدواء' : 'Select medicine',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      if (selectedMedicine == 'Other')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextField(
                            controller: customController,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'اسم الدواء' : 'Medicine name',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الكمية (اختياري)' : 'Quantity (optional)',
                          prefixIcon: const Icon(Icons.format_list_numbered),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: isArabic ? 'مثال: 30 كبسولة' : 'e.g. 30 capsules',
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        isArabic ? 'وقت تناول الدواء:' : 'When to take the medicine:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      TextField(
                        controller: timeController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'مثال: مرتين يومياً بعد الطعام' : 'e.g. Twice daily after meals',
                          prefixIcon: const Icon(Icons.schedule),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              onPressed: ((selectedMedicine != null && selectedMedicine != 'Other') ||
                                      (selectedMedicine == 'Other' && customController.text.isNotEmpty)) &&
                                  timeController.text.isNotEmpty
                                  ? addMedicineToTempList
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: Text(isArabic ? 'إضافة دواء' : 'Add Medicine'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              onPressed: selectedPatientIndex != null && tempMedicines.isNotEmpty
                                  ? addPrescription
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: Text(isArabic ? 'حفظ الوصفة' : 'Save Prescription'),
                            ),
                          ),
                        ],
                      ),
                      
                      if (tempMedicines.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'الأدوية المضافة:' : 'Added medicines:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...tempMedicines.asMap().entries.map((entry) {
                                final index = entry.key;
                                final med = entry.value;
                                return Card(
                                  color: Colors.blue[50],
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: const Icon(Icons.medication, color: Colors.blue),
                                    title: Text(
                                      med['medicine'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (med['quantity'] != null && med['quantity'] != '1')
                                          Text('${isArabic ? 'الكمية:' : 'Quantity:'} ${med['quantity']}'),
                                        Text('${isArabic ? 'الوقت:' : 'Time:'} ${med['time'] ?? ''}'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      onPressed: () => removeMedicineFromTempList(index),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf),
                                  onPressed: _generatePDF,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  label: Text(isArabic ? 'طباعة PDF' : 'Print PDF'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedPatientIndex != null 
                              ? '${isArabic ? 'الوصفات لـ' : 'Prescriptions for'} ${_getPatientName(foundPatients[selectedPatientIndex!])}:'
                              : isArabic ? 'سجل الوصفات' : 'Prescriptions History:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                          if (selectedPatientIndex != null)
                            IconButton(
                              onPressed: () {
                                final patientId = _getPatientIdNumber(foundPatients[selectedPatientIndex!]);
                                fetchPatientPrescriptions(patientId);
                              },
                              icon: const Icon(Icons.refresh),
                              tooltip: isArabic ? 'تحديث' : 'Refresh',
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      if (prescriptions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              isArabic ? 'لا توجد وصفات' : 'No prescriptions found',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      
                      if (prescriptions.isNotEmpty)
                        Text(
                          '${isArabic ? 'إجمالي الوصفات:' : 'Total prescriptions:'} ${prescriptions.length}',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      
                      const SizedBox(height: 10),
                      
                      ...prescriptions.map((prescription) => Card(
                            color: _isPrescriptionOwner(prescription) 
                                ? Colors.blue[50] 
                                : Colors.grey[50],
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.medication, color: Colors.green),
                                  if (_isPrescriptionOwner(prescription))
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Icon(Icons.verified, color: Colors.blue, size: 16),
                                    ),
                                ],
                              ),
                              title: Text(
                                prescription['medicine'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (selectedPatientIndex == null)
                                    Text('${isArabic ? 'لـ:' : 'For:'} ${prescription['patientName']}'),
                                  if (prescription['quantity'] != null && prescription['quantity'] != '1')
                                    Text('${isArabic ? 'الكمية:' : 'Quantity:'} ${prescription['quantity']}'),
                                  Text('${isArabic ? 'الوقت:' : 'Time:'} ${prescription['time']}'),
                                  Text('${isArabic ? 'الطبيب:' : 'Doctor:'} ${prescription['doctorName']}'),
                                  if (_isPrescriptionOwner(prescription))
                                    Text(isArabic ? '(وصفتك)' : '(Your prescription)', style: TextStyle(color: Colors.green, fontSize: 12)),
                                  Text(
                                    '${isArabic ? 'التاريخ:' : 'Date:'} ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(prescription['createdAt']))}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: _isPrescriptionOwner(prescription)
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _showEditPrescriptionDialog(prescription);
                                          },
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          tooltip: isArabic ? 'تعديل الوصفة' : 'Edit Prescription',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(isArabic ? 'حذف الوصفة' : 'Delete Prescription'),
                                                content: Text(isArabic ? 'هل أنت متأكد من حذف هذه الوصفة؟' : 'Are you sure you want to delete this prescription?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      deletePrescriptionFromOracle(prescription['prescriptionId']);
                                                    },
                                                    child: Text(
                                                      isArabic ? 'حذف' : 'Delete',
                                                      style: const TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: isArabic ? 'حذف الوصفة' : 'Delete Prescription',
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
