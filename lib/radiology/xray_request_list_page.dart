// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously, empty_catches, duplicate_ignore

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../radiology/radiology_sidebar.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'radiology_report_page.dart';
import '../utils/name_utils.dart';
import 'package:dcs/config/api_config.dart';

class XrayRequestListPage extends StatefulWidget {
  const XrayRequestListPage({super.key});

  @override
  State<XrayRequestListPage> createState() => _XrayRequestListPageState();
}

class _XrayRequestListPageState extends State<XrayRequestListPage> {
  List<Map<String, dynamic>> xrayWaitingPatients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool _isLoading = true;
  String userName = '';
  String userImageUrl = '';
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  String _selectedXrayTypeFilter = 'all';
  String _selectedClinicFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadXrayWaitingPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson == null) return;

      final userData = jsonDecode(userDataJson);
      final name = extractFullName(Map<String, dynamic>.from(userData));

      if (!mounted) return;
      setState(() {
        userName = name.isNotEmpty ? name : 'فني الأشعة';
        userImageUrl = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userName = 'فني الأشعة';
        userImageUrl = '';
      });
    }
  }

  Future<void> _loadXrayWaitingPatients() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/xray_requests'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        final List<Map<String, dynamic>> patients = data.map((e) {
          final Map<String, dynamic> patient = Map<String, dynamic>.from(e);
          
          return {
            'request_id': patient['REQUEST_ID'],
            'patient_id': patient['PATIENT_ID'],
            'patient_name': patient['PATIENT_NAME'],
            'student_id': patient['STUDENT_ID'],
            'student_name': patient['STUDENT_NAME'],
            'student_full_name': patient['STUDENT_FULL_NAME'],
            'student_year': patient['STUDENT_YEAR'],
            'xray_type': patient['XRAY_TYPE'],
            'jaw': patient['JAW'],
            'occlusal_jaw': patient['OCCLUSAL_JAW'],
            'cbct_jaw': patient['CBCT_JAW'],
            'side': patient['SIDE'],
            'tooth': patient['TOOTH'],
            'group_teeth': patient['GROUP_TEETH'],
            'periapical_teeth': patient['PERIAPICAL_TEETH'],
            'bitewing_teeth': patient['BITEWING_TEETH'],
            'timestamp': patient['TIMESTAMP'],
            'status': patient['STATUS'],
            'doctor_name': patient['DOCTOR_NAME'],
            'clinic': patient['CLINIC'],
            'doctor_uid': patient['DOCTOR_UID'],
            'created_at': patient['CREATED_AT'],
          };
        }).toList();
        
        if (mounted) {
          setState(() {
            xrayWaitingPatients = patients;
            filteredPatients = patients;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          xrayWaitingPatients = [];
          filteredPatients = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = xrayWaitingPatients;

    if (_selectedStatusFilter != 'all') {
      filtered = filtered.where((p) =>
          (p['status'] ?? '').toString().toLowerCase() == _selectedStatusFilter).toList();
    }
    if (_selectedXrayTypeFilter != 'all') {
      filtered = filtered.where((p) =>
          (p['xray_type'] ?? '').toString().toLowerCase() == _selectedXrayTypeFilter).toList();
    }
    if (_selectedClinicFilter != 'all') {
      filtered = filtered.where((p) => p['clinic'] == _selectedClinicFilter).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final term = _searchController.text.toLowerCase();
      filtered = filtered.where((p) =>
        (p['patient_name'] ?? '').toLowerCase().contains(term) ||
        (p['patient_id'] ?? '').toLowerCase().contains(term) ||
        (p['student_name'] ?? '').toLowerCase().contains(term)
      ).toList();
    }

    setState(() => filteredPatients = filtered);
  }

  void _resetFilters() {
    setState(() {
      _selectedStatusFilter = 'all';
      _selectedXrayTypeFilter = 'all';
      _selectedClinicFilter = 'all';
      _searchController.clear();
      filteredPatients = xrayWaitingPatients;
    });
  }

  Future<void> _markRequestAsCompleted(Map<String, dynamic> patient) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/xray_requests/${patient['request_id']}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'completed',
          'completedAt': DateTime.now().toIso8601String(),
          'completedBy': userName
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          xrayWaitingPatients.removeWhere((p) => p['request_id'] == patient['request_id']);
          filteredPatients.removeWhere((p) => p['request_id'] == patient['request_id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إكمال طلب الأشعة للمريض ${patient['patient_name']}'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في الاتصال!'))
      );
    }
  }

  // دالة نسخ اسم المريض
  void _copyPatientName(String patientName) {
    Clipboard.setData(ClipboardData(text: patientName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ اسم المريض: $patientName'),
        duration: const Duration(seconds: 2),
      )
    );
  }

  Widget _buildFilterPanel() {
    final lang = Provider.of<LanguageProvider>(context).currentLocale.languageCode;
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.filter_list, color: Color(0xFF2A7A94)),
              const SizedBox(width: 8),
              Text(lang == 'ar' ? 'تصفية النتائج' : 'Filter Results', 
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: lang == 'ar' ? 'ابحث باسم المريض أو الرقم...' : 'Search by patient name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => _applyFilters(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFilterDropdown(
                  value: _selectedStatusFilter,
                  items: {
                    'all': lang == 'ar' ? 'جميع الحالات' : 'All Status',
                    'pending': lang == 'ar' ? 'قيد الانتظار' : 'Pending', 
                    'awaiting_dean_approval': lang == 'ar' ? 'بانتظار موافقة العميد' : 'Awaiting Dean',
                    'completed': lang == 'ar' ? 'مكتمل' : 'Completed'
                  },
                  onChanged: (v) => setState(() { _selectedStatusFilter = v!; _applyFilters(); }),
                  label: lang == 'ar' ? 'الحالة' : 'Status',
                ),
                _buildFilterDropdown(
                  value: _selectedXrayTypeFilter,
                  items: {
                    'all': lang == 'ar' ? 'جميع الأنواع' : 'All Types',
                    'periapical': 'Periapical',
                    'bitewing': 'Bitewing', 
                    'occlusal': 'Occlusal',
                    'panoramic' : 'Panoramic',
                    'tmj' : 'T.M.J',
                    'cbct': 'CBCT',
                    'cephalometry': 'Cephalometry',
                  },
                  onChanged: (v) => setState(() { _selectedXrayTypeFilter = v!; _applyFilters(); }),
                  label: lang == 'ar' ? 'نوع الأشعة' : 'X-ray Type',
                ),
                _buildFilterDropdown(
                  value: _selectedClinicFilter,
                  items: {
                    'all': lang == 'ar' ? 'جميع العيادات' : 'All Clinics',
                    'Prosth': lang == 'ar' ? 'تعويضات' : 'Prosth',
                    'Ortho': lang == 'ar' ? 'تقويم' : 'Ortho',
                    'Surgery': lang == 'ar' ? 'جراحة' : 'Surgery',
                    'Endo': lang == 'ar' ? 'معالجة لب' : 'Endo',
                  },
                  onChanged: (v) => setState(() { _selectedClinicFilter = v!; _applyFilters(); }),
                  label: lang == 'ar' ? 'العيادة' : 'Clinic',
                ),
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(lang == 'ar' ? 'إعادة التعيين' : 'Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text('${lang == 'ar' ? 'عرض' : 'Showing'} ${filteredPatients.length} ${lang == 'ar' ? 'من أصل' : 'of'} ${xrayWaitingPatients.length} ${lang == 'ar' ? 'طلب' : 'requests'}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
    required String label,
  }) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(e.value, style: const TextStyle(fontSize: 14)),
                  ),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context).currentLocale.languageCode;
    
    return Scaffold(
      drawer: RadiologySidebar(
        primaryColor: const Color(0xFF2A7A94),
        accentColor: const Color(0xFF4AB8D8),
        userName: userName,
        onClose: () => Navigator.pop(context),
        onHome: () => Navigator.pushReplacementNamed(context, '/radiology-dashboard'),
        onWaitingList: () => Navigator.pop(context),
        onReports: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RadiologyReportPage())),
        lang: lang,
        localizedStrings: {},
      ),
      appBar: AppBar(
        title: Text(lang == 'ar' ? 'طلبات انتظار الأشعة' : 'X-ray Waiting Requests'),
        backgroundColor: const Color(0xFF2A7A94),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _loadXrayWaitingPatients,
            tooltip: lang == 'ar' ? 'تحديث' : 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RadiologyReportPage())),
            tooltip: lang == 'ar' ? 'التقارير' : 'Reports',
          ),
        ],
      ),
      body: Column(children: [
        _buildFilterPanel(),
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filteredPatients.isEmpty 
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          xrayWaitingPatients.isEmpty 
                              ? (lang == 'ar' ? 'لا يوجد طلبات حالياً' : 'No requests currently')
                              : (lang == 'ar' ? 'لا توجد نتائج مطابقة' : 'No matching results'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (xrayWaitingPatients.isNotEmpty && filteredPatients.isEmpty)
                          TextButton(
                            onPressed: _resetFilters, 
                            child: Text(lang == 'ar' ? 'إعادة تعيين الفلتر' : 'Reset Filter')
                          ),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) => _buildPatientCard(filteredPatients[index], context, lang),
                    ),
        ),
      ]),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, BuildContext context, String lang) {
    final String status = (patient['status'] ?? '').toString().isNotEmpty
        ? patient['status'].toString().toLowerCase()
        : 'pending';
    final String xrayType = (patient['xray_type'] ?? '').toString().toLowerCase();
    final bool awaitingDeanApproval = xrayType == 'cbct' && status == 'awaiting_dean_approval';
    final bool isCompleted = status == 'completed';
    final Color statusBgColor = isCompleted
        ? Colors.green.shade100
        : awaitingDeanApproval
            ? Colors.red.shade100
            : Colors.orange.shade100;
    final Color statusTextColor = isCompleted
        ? Colors.green.shade800
        : awaitingDeanApproval
            ? Colors.red.shade800
            : Colors.orange.shade800;
    final String statusLabel = isCompleted
        ? (lang == 'ar' ? '🟢 مكتمل' : '🟢 Completed')
        : awaitingDeanApproval
            ? (lang == 'ar' ? '🔴 بانتظار موافقة العميد' : '🔴 Awaiting dean approval')
            : (lang == 'ar' ? '🟠 قيد الانتظار' : '🟠 Pending');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Directionality(
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // التشارت في الأعلى (مركز)
              _buildCompactTeethChart(patient, context, lang),
              
              const SizedBox(height: 16),
              
              // معلومات المريض
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // اسم المريض مع أيقونة النسخ
                        Row(
                          mainAxisAlignment: lang == 'ar' ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                patient['patient_name']?.toString() ?? 'غير معروف',
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.content_copy, size: 20),
                              onPressed: () => _copyPatientName(patient['patient_name'] ?? ''),
                              tooltip: lang == 'ar' ? 'نسخ الاسم' : 'Copy Name',
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // معلومات المريض
                        _buildInfoRow(Icons.person_outline, '${lang == 'ar' ? 'رقم المريض' : 'Patient ID'}: ${patient['patient_id'] ?? 'غير محدد'}', lang),
                        
                        // الطالب
                        if ((patient['student_name'] ?? '').toString().isNotEmpty)
                          _buildInfoRow(Icons.school, '${lang == 'ar' ? 'الطالب' : 'Student'}: ${patient['student_name']}', lang),
                        
                        // السنة الدراسية
                        if (patient['student_year'] != null)
                          _buildInfoRow(Icons.class_, '${lang == 'ar' ? 'السنة' : 'Year'}: ${patient['student_year']}', lang),
                        
                        // الطبيب
                        if ((patient['doctor_name'] ?? '').toString().isNotEmpty)
                          _buildInfoRow(Icons.medical_services, '${lang == 'ar' ? 'الطبيب' : 'Doctor'}: ${patient['doctor_name']}', lang),
                        
                        // العيادة
                        if ((patient['clinic'] ?? '').toString().isNotEmpty)
                          _buildInfoRow(Icons.local_hospital, '${lang == 'ar' ? 'العيادة' : 'Clinic'}: ${patient['clinic']}', lang),
                        
                        // نوع الأشعة
                        _buildInfoRow(Icons.photo_camera, '${lang == 'ar' ? 'نوع الأشعة' : 'X-ray Type'}: ${patient['xray_type'] ?? 'غير محدد'}', lang),
                        
                        // حالة الطلب وزر التصوير
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // حالة الطلب
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // زر تم التصوير
                            if (!isCompleted)
                              ElevatedButton.icon(
                                onPressed: awaitingDeanApproval ? null : () => _markRequestAsCompleted(patient),
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(lang == 'ar' ? 'تم التصوير' : 'Completed'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: awaitingDeanApproval ? Colors.red.shade200 : const Color(0xFF2A7A94),
                                  foregroundColor: awaitingDeanApproval ? Colors.red.shade800 : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        if (awaitingDeanApproval) ...[
                          const SizedBox(height: 8),
                          Text(
                            lang == 'ar'
                                ? 'لا يمكن التصوير قبل موافقة العميد على طلب CBCT.'
                                : 'CBCT request is locked until the dean approves it.',
                            style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: lang == 'ar' ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (lang != 'ar') Icon(icon, size: 16, color: Colors.grey.shade600),
          if (lang != 'ar') const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lang == 'ar') const SizedBox(width: 8),
          if (lang == 'ar') Icon(icon, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildCompactTeethChart(Map<String, dynamic> patient, BuildContext context, String lang) {
    // استخراج الأسنان المطلوبة
    List<String> selectedTeeth = [];
    final xrayType = patient['xray_type']?.toString() ?? '';

    try {
      if (xrayType == 'bitewing' && patient['bitewing_teeth'] != null) {
        if (patient['bitewing_teeth'] is String) {
          final parsed = jsonDecode(patient['bitewing_teeth']);
          if (parsed is List) selectedTeeth = List<String>.from(parsed);
        } else if (patient['bitewing_teeth'] is List) {
          selectedTeeth = List<String>.from(patient['bitewing_teeth']);
        }
      }
      else if (xrayType == 'periapical' && patient['periapical_teeth'] != null) {
        if (patient['periapical_teeth'] is String) {
          final parsed = jsonDecode(patient['periapical_teeth']);
          if (parsed is List) selectedTeeth = List<String>.from(parsed);
        } else if (patient['periapical_teeth'] is List) {
          selectedTeeth = List<String>.from(patient['periapical_teeth']);
        }
      }
      else if (patient['group_teeth'] != null) {
        if (patient['group_teeth'] is List) {
          final group = patient['group_teeth'] as List;
          for (final t in group) {
            if (t is Map && t['tooth'] != null) {
              selectedTeeth.add(t['tooth'].toString());
            } else if (t is String) {
              selectedTeeth.add(t);
            }
          }
        }
      }
    } catch (e) {
    }

    // إذا كان occlusal أو cbct، أظهر مربع الفك فقط
    if (xrayType == 'occlusal' || xrayType == 'cbct') {
      final jaw = patient['occlusal_jaw'] ?? patient['cbct_jaw'] ?? patient['jaw'];
      if (jaw != null && (jaw == 'upper' || jaw == 'lower')) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(
                Icons.architecture,
                size: 50,
                color: jaw == 'upper' ? Colors.blue.shade600 : Colors.brown.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                jaw == 'upper'
                    ? (lang == 'ar' ? 'الفك العلوي' : 'Upper Jaw')
                    : (lang == 'ar' ? 'الفك السفلي' : 'Lower Jaw'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: jaw == 'upper' ? Colors.blue.shade700 : Colors.brown.shade700,
                ),
              ),
              Text(
                '(${xrayType.toUpperCase()})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      }
    }

    // التشارت المضغوط والمركز
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // العنوان
          Text(
            '${lang == 'ar' ? 'خريطة الأسنان' : 'Teeth Chart'} - ${xrayType.toUpperCase()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A7A94),
            ),
          ),
          const SizedBox(height: 16),
          
          // الفك العلوي (معكوس الترتيب)
          _buildCompactJawRow(
            ['18','17','16','15','14','13','12','11','21','22','23','24','25','26','27','28'], 
            selectedTeeth, 
            true,
            lang == 'ar' ? 'الفك العلوي' : 'Upper Jaw',
            isReversed: true
          ),
          
          const SizedBox(height: 12),
          // خط الفاصل
          Container(height: 2, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          
          // الفك السفلي (معكوس الترتيب)
          _buildCompactJawRow(
            ['48','47','46','45','44','43','42','41','31','32','33','34','35','36','37','38'], 
            selectedTeeth, 
            false,
            lang == 'ar' ? 'الفك السفلي' : 'Lower Jaw',
            isReversed: true
          ),
          
          // إحصائيات
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '${lang == 'ar' ? 'الأسنان المطلوبة:' : 'Teeth Required:'} ${selectedTeeth.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactJawRow(List<String> teeth, List<String> selectedTeeth, bool isUpperJaw, String jawLabel, {bool isReversed = false}) {
    // إذا كان مطلوب عكس الترتيب، نعكس القائمة
    final displayTeeth = isReversed ? teeth.reversed.toList() : teeth;
    
    return Column(
      children: [
        Text(
          jawLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: displayTeeth.map((tooth) {
              final isSelected = selectedTeeth.contains(tooth);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    // رقم السن (أكبر)
                    Container(
                      width: 28,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tooth,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    // شكل السن (أكبر)
                    Container(
                      width: 24,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade400 : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
                          width: isSelected ? 2 : 1.5,
                        ),
                        borderRadius: isUpperJaw 
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              )
                            : const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
