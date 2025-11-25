import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'clinical_procedures_form.dart';
import '../Shared/waiting_list_page.dart';
import '../Doctor/examined_patients_page.dart';
import '../dashboard/doctor_dashboard.dart';
import 'prescription_page.dart';
import 'doctor_xray_request_page.dart';
import 'cbct_approvals_page.dart';
import '../utils/name_utils.dart';

class DoctorSidebar extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final String? userName;
  final String? userImageUrl;
  final VoidCallback? onLogout;
  final BuildContext parentContext;
  final bool collapsed;
  final String Function(BuildContext, String) translate;
  final String doctorUid;
  final List<String> allowedFeatures;

  const DoctorSidebar({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.userName,
    this.userImageUrl,
    this.onLogout,
    required this.parentContext,
    this.collapsed = false,
    required this.translate,
    required this.doctorUid,
    required this.allowedFeatures,
  });

  @override
  State<DoctorSidebar> createState() => _DoctorSidebarState();
}

class _DoctorSidebarState extends State<DoctorSidebar> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _loadDoctorNameIfNeeded();
  }

  Future<void> _loadDoctorNameIfNeeded() async {
    if (_displayName != null && _displayName!.trim().isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson == null) return;
      final Map<String, dynamic> data = jsonDecode(userDataJson);
      final builtName = extractFullName(Map<String, dynamic>.from(data));
      if (!mounted) return;
      setState(() {
        _displayName = builtName.isNotEmpty ? builtName : null;
      });
    } catch (_) {
      // ignore parsing errors; fallback handled in build
    }
  }

  // ترجمة افتراضية عند غياب ترجمة الأب
  String _defaultTranslate(BuildContext context, String key) {
    final Map<String, Map<String, String>> translations = {
      'home': {'ar': 'الرئيسية', 'en': 'Dashboard'},
      'waiting_list': {'ar': 'قائمة الانتظار', 'en': 'Waiting List'},
      'clinical_procedures_form': {
        'ar': 'نموذج الإجراءات السريرية',
        'en': 'Clinical Procedures Form'
      },
      'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
      'prescription': {'ar': 'وصفة طبية', 'en': 'Prescription'},
      'xray_request': {'ar': 'طلب أشعة', 'en': 'X-Ray Request'},
      'cbct_approvals': {'ar': 'موافقات CBCT', 'en': 'CBCT Approvals'},
      'doctor': {'ar': 'دكتور', 'en': 'Doctor'},
    };

    final langCode = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ar';
    return translations[key]?[langCode] ??
        translations[key]?['en'] ??
        translations[key]?['ar'] ??
        key;
  }

  String _getTranslation(BuildContext context, String key) {
    final result = widget.translate(widget.parentContext, key);
    if (result.trim().isEmpty || result == key) {
      return _defaultTranslate(context, key);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
  final resolvedName = _displayName?.trim().isNotEmpty == true
      ? _displayName!.trim()
      : _getTranslation(context, 'doctor');

  // Define all possible features (بدون dashboard)
  final allFeatureBoxes = [
    {
      'key': 'waiting_list',
      'icon': Icons.list_alt,
      'title': _getTranslation(context, 'waiting_list'),
      'onTap': () {
        Navigator.pop(context);
        Navigator.push(
          widget.parentContext,
          MaterialPageRoute(
            builder: (_) => WaitingListPage(
              userRole: 'doctor',
              allowedFeatures: widget.allowedFeatures,
            ),
          ),
        );
      }
    },
      {
        'key': 'clinical_procedures_form',
        'icon': Icons.medical_information,
        'title': _getTranslation(context, 'clinical_procedures_form'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(builder: (_) => ClinicalProceduresForm(uid: widget.doctorUid)),
          );
        }
      },
    
    {
  'key': 'examined_patients',
  'icon': Icons.check_circle,
  'title': _getTranslation(context, 'examined_patients'),
  'onTap': () {
    Navigator.pop(context);
    Navigator.push(
      widget.parentContext,
      MaterialPageRoute(builder: (_) => DoctorExaminedPatientsPage(
        doctorName: resolvedName,
        doctorImageUrl: widget.userImageUrl,
        currentUserId: widget.doctorUid,
        userAllowedFeatures: widget.allowedFeatures,
      )),
    );
  }
},
      {
        'key': 'prescription',
        'icon': Icons.medical_services,
        'title': _getTranslation(context, 'prescription'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(builder: (_) => PrescriptionPage( uid: widget.doctorUid)),
          );
        }
      },
      {
        'key': 'xray_request',
        'icon': Icons.camera_alt,
        'title': _getTranslation(context, 'xray_request'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(builder: (_) => const DoctorXrayRequestPage()),
          );
        }
      },
      {
        'key': 'cbct_approvals',
        'icon': Icons.verified,
        'title': _getTranslation(context, 'cbct_approvals'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(builder: (_) => const CbctApprovalsPage()),
          );
        }
      },
    ];


  // Filter features by allowedFeatures فقط (بدون dashboard)
  final Set<String> featuresSet = Set<String>.from(widget.allowedFeatures);
  final sidebarFeatures = allFeatureBoxes.where((f) => featuresSet.contains(f['key'])).toList();

    double sidebarWidth = widget.collapsed ? 60 : 260;
    if (MediaQuery.of(context).size.width < 700 && !widget.collapsed) {
      sidebarWidth = 200;
    }

    return Drawer(
      child: Container(
        width: sidebarWidth,
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: widget.primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: widget.collapsed ? 18 : 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: widget.collapsed ? 18 : 32, color: widget.accentColor),
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(height: 10),
                    Text(
                      resolvedName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getTranslation(context, 'doctor'),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            // زر الرئيسية الثابت
            _buildSidebarItem(
              context,
              icon: Icons.home,
              label: _getTranslation(context, 'home'),
              onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                widget.parentContext,
                MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
                (route) => false,
              );
              },
            ),
            // باقي العناصر حسب الصلاحيات
            for (final feature in sidebarFeatures)
              _buildSidebarItem(
                context,
                icon: feature['icon'] as IconData,
                label: feature['title'] as String,
                onTap: feature['onTap'] as VoidCallback,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? widget.primaryColor),
      title: widget.collapsed ? null : Text(label),
      onTap: onTap,
      contentPadding: widget.collapsed ? const EdgeInsets.symmetric(horizontal: 12) : null,
      minLeadingWidth: 0,
      horizontalTitleGap: widget.collapsed ? 0 : null,
    );
  }
}
