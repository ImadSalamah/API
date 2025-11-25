import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import '../providers/language_provider.dart';
import '../utils/name_utils.dart';
import 'package:dcs/config/api_config.dart';

class CbctApprovalsPage extends StatefulWidget {
  const CbctApprovalsPage({super.key});

  @override
  State<CbctApprovalsPage> createState() => _CbctApprovalsPageState();
}

class _CbctApprovalsPageState extends State<CbctApprovalsPage> {
  List<Map<String, dynamic>> cbctRequests = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _deanName = '';

  @override
  void initState() {
    super.initState();
    _loadDeanInfo();
    _loadCbctRequests();
  }

  Future<void> _loadDeanInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        final name = extractFullName(Map<String, dynamic>.from(userData));
        setState(() => _deanName = name);
      }
    } catch (_) {}
  }

  Future<void> _loadCbctRequests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/xray_requests'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> requests = data
            .where((e) => (e['XRAY_TYPE'] ?? '').toString().toLowerCase() == 'cbct')
            .map((e) {
          final mapped = Map<String, dynamic>.from(e);
          return {
            'request_id': mapped['REQUEST_ID'] ?? mapped['id'],
            'patient_name': mapped['PATIENT_NAME'] ?? mapped['patientName'],
            'patient_id': mapped['PATIENT_ID'] ?? mapped['patientId'],
            'student_name': mapped['STUDENT_NAME'],
            'status': mapped['STATUS'] ?? mapped['status'],
            'clinic': mapped['CLINIC'],
            'timestamp': mapped['TIMESTAMP'] ?? mapped['createdAt'],
            'cbct_jaw': mapped['CBCT_JAW'] ?? mapped['jaw'],
            'doctor_name': mapped['DOCTOR_NAME'],
          };
        }).toList();

        setState(() {
          cbctRequests = requests;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final requestId = request['request_id'];
    if (requestId == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/xray_requests/$requestId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'pending',
          'approvedByDean': _deanName,
          'approvedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isArabic ? 'تمت الموافقة على الطلب' : 'Request approved')),
        );
        _loadCbctRequests();
      } else {
        _showErrorSnackBar();
      }
    } catch (_) {
      _showErrorSnackBar();
    }
  }

  void _showErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isArabic ? 'تعذر تحديث الطلب' : 'Could not update request')),
    );
  }

  bool get _isArabic {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.currentLocale.languageCode == 'ar';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'موافقات CBCT' : 'CBCT Approvals'),
          backgroundColor: const Color(0xFF2A7A94),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCbctRequests,
              tooltip: isArabic ? 'تحديث' : 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          isArabic ? 'حدث خطأ أثناء تحميل الطلبات' : 'Failed to load requests',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadCbctRequests,
                          icon: const Icon(Icons.refresh),
                          label: Text(isArabic ? 'إعادة المحاولة' : 'Try again'),
                        ),
                      ],
                    ),
                  )
                : cbctRequests.isEmpty
                    ? Center(
                        child: Text(
                          isArabic ? 'لا يوجد طلبات CBCT حالياً' : 'No CBCT requests for approval',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: cbctRequests.length,
                        itemBuilder: (context, index) => _buildRequestCard(cbctRequests[index], isArabic),
                      ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isArabic) {
    final status = (request['status'] ?? 'pending').toString().toLowerCase();
    final awaitingDean = status == 'awaiting_dean_approval';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: awaitingDean ? Colors.red.shade200 : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF2A7A94)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request['patient_name']?.toString() ?? '—',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: awaitingDean ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    awaitingDean
                        ? (isArabic ? 'بانتظار الموافقة' : 'Waiting approval')
                        : (isArabic ? 'جاهز للتصوير' : 'Ready for imaging'),
                    style: TextStyle(
                      color: awaitingDean ? Colors.red.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (request['student_name'] != null && request['student_name'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${isArabic ? 'الطالب:' : 'Student:'} ${request['student_name']}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            if (request['clinic'] != null && request['clinic'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${isArabic ? 'العيادة:' : 'Clinic:'} ${request['clinic']}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            if (request['cbct_jaw'] != null && request['cbct_jaw'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.architecture, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      request['cbct_jaw'] == 'upper'
                          ? (isArabic ? 'الفك العلوي' : 'Upper jaw')
                          : (isArabic ? 'الفك السفلي' : 'Lower jaw'),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    request['doctor_name'] != null
                        ? '${isArabic ? 'الطبيب المحوِّل:' : 'Referring doctor:'} ${request['doctor_name']}'
                        : (isArabic ? 'طلب CBCT' : 'CBCT request'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: awaitingDean ? () => _approveRequest(request) : null,
                  icon: const Icon(Icons.verified),
                  label: Text(isArabic ? 'موافقة' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: awaitingDean ? const Color(0xFF2A7A94) : Colors.grey.shade300,
                    foregroundColor: awaitingDean ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
