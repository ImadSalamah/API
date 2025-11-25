// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/secretary_provider.dart';
import '../Doctor/initial_examination.dart';
import '../Doctor/doctor_sidebar.dart';
import '../utils/name_utils.dart';
import '../Secretry/secretary_sidebar.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dcs/config/api_config.dart';

class WaitingListPage extends StatefulWidget {
  final String userRole;
  final List<String>? allowedFeatures;

  const WaitingListPage({super.key, required this.userRole, this.allowedFeatures});

  @override
  State<WaitingListPage> createState() => _WaitingListPageState();
}

class _WaitingListPageState extends State<WaitingListPage> {
  Future<Set<String>> _fetchAllowedFeatures() async {
    if (widget.allowedFeatures != null && widget.allowedFeatures!.isNotEmpty) {
      return widget.allowedFeatures!.toSet();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson != null) {
        final Map<String, dynamic> data = json.decode(userDataJson);
        final features = _processAllowedFeatures(data);
        if (features.isNotEmpty) {
          return features.toSet();
        }
      }
    } catch (e) {
      debugPrint('Error loading allowed features: $e');
    }
    return _getDefaultDoctorFeatures().toSet();
  }

  List<String> _processAllowedFeatures(Map<String, dynamic> data) {
    try {
      if (data['doctor'] is Map && (data['doctor']['ALLOWED_FEATURES'] is List)) {
        return List<String>.from(data['doctor']['ALLOWED_FEATURES']);
      }
      if (data['allowedFeatures'] is List) {
        return List<String>.from(data['allowedFeatures']);
      }
      if (data['ALLOWED_FEATURES'] is List) {
        return List<String>.from(data['ALLOWED_FEATURES']);
      }
      if (data['ALLOWED_FEATURES'] is String) {
        final parsed = json.decode(data['ALLOWED_FEATURES']);
        if (parsed is List) {
          return List<String>.from(parsed);
        }
      }
    } catch (e) {
      debugPrint('Error parsing allowed features: $e');
    }
    return [];
  }

  List<String> _getDefaultDoctorFeatures() {
    return [
      'waiting_list',
      'clinical_procedures_form',
    ];
  }
  final Color primaryColor = const Color(0xFF2A7A94);
  final String apiBaseUrl = ApiConfig.baseUrl;
  List<Map<String, dynamic>> waitingList = [];
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _nightlyCleanupTimer;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredWaitingList = [];
  // No Firebase subscriptions needed

  String? _doctorName;
  String? _doctorImageUrl;

  final Map<String, Map<String, String>> _translations = {
    'waiting_list': {'ar': 'قائمة الانتظار', 'en': 'Waiting List'},
    'name': {'ar': 'الاسم', 'en': 'Name'},
    'phone': {'ar': 'الهاتف', 'en': 'Phone'},
    'age': {'ar': 'العمر', 'en': 'Age'},
    'years': {'ar': 'سنة', 'en': 'years'},
    'months': {'ar': 'شهر', 'en': 'months'},
    'days': {'ar': 'يوم', 'en': 'days'},
    'remove_from_waiting_list': {
      'ar': 'إزالة من الانتظار',
      'en': 'Remove from Waiting List'
    },
    'no_patients': {'ar': 'لا يوجد مرضى', 'en': 'No patients found'},
    'error_loading': {
      'ar': 'خطأ في تحميل البيانات',
      'en': 'Error loading data'
    },
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'age_unknown': {'ar': 'العمر غير معروف', 'en': 'Age unknown'},
    'next_step': {
      'ar': 'انتقل للفحص الأولي',
      'en': 'Go to Initial Examination'
    },
    'all_removed_at_11pm': {
      'ar': 'تم إزالة جميع المرضى في الساعة 11 مساءً',
      'en': 'All patients removed at 11 PM'
    },
    'error_moving': {'ar': 'خطأ في نقل المريض', 'en': 'Error moving patient'},
    'doctor_not_logged_in': {
      'ar': 'يجب تسجيل دخول الطبيب أولاً',
      'en': 'Doctor must be logged in'
    },
    'unknown': {'ar': 'غير معروف', 'en': 'Unknown'},
    'no_number': {'ar': 'بدون رقم', 'en': 'No number'},
    'search_hint': {
      'ar': 'ابحث بالاسم أو رقم الهاتف...',
      'en': 'Search by name or phone...'
    },
    'students_evaluation': {'ar': 'تقييم الطلاب', 'en': 'Students Evaluation'},
    'supervision_groups': {'ar': 'شعب الإشراف', 'en': 'Supervision Groups'},
    'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
    'signing_out': {'ar': 'تسجيل الخروج', 'en': 'Sign out'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'medical_record_no': {'ar': 'رقم الملف الطبي', 'en': 'Medical Record No'},
    'patient_id': {'ar': 'رقم المريض', 'en': 'Patient ID'},
    'appointment_date': {'ar': 'تاريخ الموعد', 'en': 'Appointment Date'},
    'status': {'ar': 'الحالة', 'en': 'Status'},
    'waiting': {'ar': 'في الانتظار', 'en': 'Waiting'},
  };

  @override
  void initState() {
    super.initState();
    _initializeReferences();
    _setupRealtimeListeners();
    _scheduleNightlyCleanup();
    _searchController.addListener(_filterWaitingList);
    if (widget.userRole == 'doctor') {
      _loadDoctorInfo();
    }
  }

  @override
  void dispose() {
  // No Firebase subscriptions to cancel
    _nightlyCleanupTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeReferences() {
    // No Firebase references needed
  }

  void _setupRealtimeListeners() {
    // Fetch waiting list and users from API
    _fetchWaitingListAndUsers();
  }

  Future<void> _fetchWaitingListAndUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final waitingListRes = await http.get(Uri.parse('$apiBaseUrl/waitingList'));
      
      if (waitingListRes.statusCode == 200) {
        final waitingListData = json.decode(waitingListRes.body);
        
        setState(() {
          waitingList = _parseWaitingApi(waitingListData);
          _filteredWaitingList = List.from(waitingList);
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          waitingList = [];
          _filteredWaitingList = [];
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching waiting list/users: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  List<Map<String, dynamic>> _parseWaitingApi(dynamic data) {
    if (data == null) return [];
    List<Map<String, dynamic>> result = [];
    
    if (data is List) {
      for (var item in data) {
        final waitingData = Map<String, dynamic>.from(item);
        
        // 🔥 استخدام البيانات مباشرة من جدول WAITING_LIST
        waitingData['patientName'] = waitingData['PATIENT_NAME']?.toString().trim() ?? '';
        waitingData['medicalRecordNo'] = waitingData['MEDICAL_RECORD_NO']?.toString().trim() ?? '';
        waitingData['patientUid'] = waitingData['PATIENT_UID']?.toString().trim() ?? '';
        waitingData['phone'] = waitingData['PHONE']?.toString().trim() ?? '';
        waitingData['appointmentDate'] = waitingData['APPOINTMENT_DATE']?.toString().trim() ?? '';
        waitingData['status'] = waitingData['STATUS']?.toString().trim() ?? 'WAITING';
        
        result.add(waitingData);
      }
    }
    
    // ترتيب القائمة حسب تاريخ الإنشاء (الأحدث أولاً)
    result.sort((a, b) {
      final aDate = a['CREATED_AT']?.toString() ?? '';
      final bDate = b['CREATED_AT']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });
    
    return result;
  }

  void _filterWaitingList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWaitingList = waitingList.where((patient) {
        final fullName = _getPatientName(patient).toLowerCase();
        final phone = patient['phone']?.toString().toLowerCase() ?? '';
        final medicalRecordNo = patient['medicalRecordNo']?.toString().toLowerCase() ?? '';
        final patientId = patient['patientUid']?.toString().toLowerCase() ?? '';
        
        return fullName.contains(query) || 
               phone.contains(query) ||
               medicalRecordNo.contains(query) ||
               patientId.contains(query);
      }).toList();
    });
  }

  String _getPatientName(Map<String, dynamic> patient) {
    // 🔥 استخدام PATIENT_NAME مباشرة من قاعدة البيانات
    final patientName = patient['patientName']?.toString().trim() ?? 
                       patient['PATIENT_NAME']?.toString().trim() ?? 
                       _translate(context, 'unknown');
    
    return patientName;
  }

  String _translate(BuildContext context, String key) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.currentLocale.languageCode.toLowerCase();
    final normalizedCode = langCode.split('_').first; // handle en_US, ar_SA, etc.

    if (_translations.containsKey(key)) {
      final map = _translations[key]!;
      // حاول مع الكود الكامل ثم المختصر ثم العربية فالإنجليزية ثم أول قيمة متاحة
      return map[langCode] ??
          map[normalizedCode] ??
          map['ar'] ??
          map['en'] ??
          map.values.first;
    }
    return key;
  }

  String _formatAppointmentDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '-';
      final date = DateTime.parse(dateStr.split('T')[0]);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return _translate(context, 'waiting');
      default:
        return status;
    }
  }

  Future<void> _removeFromWaitingList(String waitingId) async {
    try {
      final res = await http.delete(Uri.parse('$apiBaseUrl/waitingList/$waitingId'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translate(context, 'remove_from_waiting_list')),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchWaitingListAndUsers();
      } else {
        throw Exception('Failed to remove');
      }
    } catch (e) {
      debugPrint('Error removing from waiting list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate(context, 'error_loading')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestExamination(String patientId) async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/patientExams?patientUid=$patientId'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List && data.isNotEmpty) {
          // Assuming the API returns a list of exams sorted by timestamp desc
          return Map<String, dynamic>.from(data.first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching latest examination: $e');
      return null;
    }
  }

Future<void> _moveToInitialExamination(Map<String, dynamic> patientData) async {
  try {
    // الحصول على doctorId الحقيقي من LanguageProvider
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    String? doctorId = languageProvider.currentUserId;
    
    if (doctorId == null || doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate(context, 'doctor_not_logged_in'))),
      );
      return;
    }

    String? patientUid = patientData['patientUid']?.toString();
    if (patientUid == null || patientUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد patientUid حقيقي للمريض!')),
      );
      return;
    }

    // جلب بيانات المريض الكاملة من API
    final patientRes = await http.get(Uri.parse('$apiBaseUrl/patients/$patientUid'));
    if (patientRes.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر جلب بيانات المريض الكاملة!')),
      );
      return;
    }

    final fullPatientData = json.decode(patientRes.body);
    
    // إعداد البيانات للمريض
    Map<String, dynamic> patientDataForExam = Map<String, dynamic>.from(fullPatientData);
    patientDataForExam['authUid'] = patientUid;
    patientDataForExam['userId'] = patientUid;
    patientDataForExam['firstName'] = fullPatientData['FIRSTNAME'] ?? '';
    patientDataForExam['familyName'] = fullPatientData['FAMILYNAME'] ?? '';
    patientDataForExam['patientName'] = patientData['patientName'] ?? '';
    patientDataForExam['phone'] = fullPatientData['PHONE'] ?? '';
    patientDataForExam['birthDate'] = fullPatientData['BIRTHDATE'] ?? '';
    patientDataForExam['medicalRecordNo'] = fullPatientData['MEDICAL_RECORD_NO'] ?? '';

    // حساب العمر
    int? ageInYears;
    final birthDateStr = fullPatientData['BIRTHDATE']?.toString();
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr.split('T')[0]);
        final now = DateTime.now();
        ageInYears = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          ageInYears--;
        }
      } catch (e) {
        debugPrint('Error calculating age: $e');
      }
    }

    final latestExam = await _fetchLatestExamination(patientUid);
    if (latestExam != null) {
      patientDataForExam['examData'] = latestExam;
    }

    if (!mounted) return;

    // 🔥 الآن نرسل doctorId الحقيقي و patientUid
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InitialExamination(
          patientData: patientDataForExam,
          age: ageInYears,
          doctorId: doctorId, // ✅ doctorId الحقيقي
          patientId: patientUid, // ✅ patientUid الحقيقي
          isEditMode: false,
        ),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_translate(context, 'next_step')),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('Error moving to initial examination: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_translate(context, 'error_moving')}: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Future<void> _removeAllFromWaitingList() async {
    try {
      // حذف جميع المرضى من قائمة الانتظار
      for (var patient in waitingList) {
        final waitingId = patient['WAITING_ID']?.toString();
        if (waitingId != null) {
          await http.delete(Uri.parse('$apiBaseUrl/waitingList/$waitingId'));
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate(context, 'all_removed_at_11pm')),
          backgroundColor: Colors.green,
        ),
      );
      _fetchWaitingListAndUsers();
    } catch (e) {
      debugPrint('Error removing all from waiting list: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate(context, 'error_loading')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scheduleNightlyCleanup() {
    final now = DateTime.now();
    final elevenPM = DateTime(now.year, now.month, now.day, 23, 0, 0);
    final timeUntilElevenPM = elevenPM.isAfter(now)
        ? elevenPM.difference(now)
        : elevenPM.add(const Duration(days: 1)).difference(now);

    _nightlyCleanupTimer = Timer(
      timeUntilElevenPM,
      () {
        _removeAllFromWaitingList();
        _scheduleNightlyCleanup();
      },
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> patient, BuildContext context) {
    if (widget.userRole == 'secretary') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _removeFromWaitingList(patient['WAITING_ID']?.toString() ?? ''),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            _translate(context, 'remove_from_waiting_list'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    } else if (widget.userRole == 'doctor') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _moveToInitialExamination(patient),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            _translate(context, 'next_step'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildWaitingListCard(
      Map<String, dynamic> patient, BuildContext context) {
    final patientName = _getPatientName(patient); // 🔥 استخدام الاسم مباشرة من قاعدة البيانات
    final phone = patient['phone'] ?? _translate(context, 'no_number');
    final medicalRecordNo = patient['medicalRecordNo'] ?? '-';
    final patientId = patient['patientUid'] ?? '-';
    final appointmentDate = _formatAppointmentDate(patient['appointmentDate'] ?? '');
    final status = _getStatusText(patient['status'] ?? 'WAITING');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    patientName, // 🔥 عرض الاسم الكامل مباشرة
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Patient Information
            _buildInfoRow(Icons.phone, _translate(context, 'phone'), phone),
            const SizedBox(height: 8),
            
            _buildInfoRow(Icons.medical_services, _translate(context, 'medical_record_no'), medicalRecordNo),
            const SizedBox(height: 8),
            
            _buildInfoRow(Icons.person, _translate(context, 'patient_id'), patientId),
            const SizedBox(height: 8),
            
            _buildInfoRow(Icons.calendar_today, _translate(context, 'appointment_date'), appointmentDate),
            
            const SizedBox(height: 18),
            _buildActionButtons(patient, context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _translate(context, 'error_loading'),
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _setupRealtimeListeners();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _translate(context, 'retry'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: _translate(context, 'search_hint'),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> _loadDoctorInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      Map<String, dynamic> cachedData = {};
      if (userDataJson != null) {
        cachedData = json.decode(userDataJson);
      }

      final cachedFullName = (cachedData['FULL_NAME'] ?? '').toString().trim();
      final cachedUid = (cachedData['USER_ID'] ?? '').toString().trim();

      // بناء الاسم من الكاش مباشرة أولاً
      String builtName = extractFullName(Map<String, dynamic>.from(cachedData));
      if (builtName.isEmpty) {
        builtName = cachedFullName;
      }

      // إذا الاسم موجود بالكاش نستخدمه مباشرة
      if (builtName.isNotEmpty) {
        setState(() {
          _doctorName = builtName;
          _doctorImageUrl = null; // الشعار الافتراضي
        });
        return;
      }

      // محاولة جلب الاسم من الـ API باستخدام uid المخزن
      if (cachedUid.isNotEmpty) {
        final res = await http.get(Uri.parse('$apiBaseUrl/users/$cachedUid'));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final fullName = extractFullName(Map<String, dynamic>.from(data));
          setState(() {
            _doctorName = fullName.isNotEmpty ? fullName : null;
            _doctorImageUrl = null; // الشعار الافتراضي دائماً
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading doctor info: $e');
    }
  }

  Widget? _buildSidebar(BuildContext context) {
    if (widget.userRole == 'doctor') {
      return FutureBuilder<Set<String>>(
        future: _fetchAllowedFeatures(),
        builder: (context, snapshot) {
          final allowed = snapshot.data ?? _getDefaultDoctorFeatures().toSet();
          final allowedWithHome = {'home', ...allowed};
          return DoctorSidebar(
            primaryColor: primaryColor,
            accentColor: primaryColor,
            userName: _doctorName ?? "دكتور",
            userImageUrl: _doctorImageUrl,
            parentContext: context,
            translate: _translate,
            onLogout: null,
            doctorUid: 'doctor1',
            allowedFeatures: allowedWithHome.toList(),
          );
        },
      );
    } else if (widget.userRole == 'secretary') {
      final secretaryProvider = Provider.of<SecretaryProvider>(context);
      return SecretarySidebar(
        primaryColor: primaryColor,
        accentColor: primaryColor,
        userName: secretaryProvider.fullName.isNotEmpty ? secretaryProvider.fullName : "سكرتير",
        userImageUrl: secretaryProvider.imageBase64,
        parentContext: context,
        translate: _translate,
        onLogout: null,
        collapsed: false,
        pendingAccountsCount: 0,
        userRole: 'secretary',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Text(_translate(context, 'waiting_list'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      drawer: _buildSidebar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSearchField(),
                    Expanded(
                      child: _filteredWaitingList.isEmpty
                          ? Center(
                              child: Text(
                                _translate(context, 'no_patients'),
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredWaitingList.length,
                              itemBuilder: (context, index) {
                                return _buildWaitingListCard(
                                    _filteredWaitingList[index], context);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
