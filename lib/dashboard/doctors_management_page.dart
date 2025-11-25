// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../Admin/admin_sidebar.dart';
import 'package:dcs/config/api_config.dart';
import '../utils/friendly_error.dart';

class DoctorsManagementPage extends StatefulWidget {
  final List<Map<String, dynamic>> doctors;
  final String? userName;
  final String? userImageUrl;
  final String Function(BuildContext, String) translate;
  final VoidCallback onLogout;
  final List<Map<String, dynamic>> allUsers;

  const DoctorsManagementPage({
    super.key, 
    required this.doctors,
    this.userName,
    this.userImageUrl,
    required this.translate,
    required this.onLogout,
    required this.allUsers,
  });

  @override
  _DoctorsManagementPageState createState() => _DoctorsManagementPageState();
}

class _DoctorsManagementPageState extends State<DoctorsManagementPage> {
  String doctorSearch = '';
  String doctorTypeFilter = 'all';
  Map<String, String> doctorTypes = {};
  List<Map<String, dynamic>> _currentDoctors = [];
  bool _loadingDoctors = false;
  bool _initialLoading = true;
  bool isSidebarOpen = false;
  bool showSidebarButton = true;
  
  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);

  // ترجمة النصوص
  final Map<String, Map<String, String>> _translations = {
    'doctors_management': {'ar': 'إدارة الأطباء', 'en': 'Doctors Management'},
    'search_doctor_name': {'ar': 'ابحث باسم الطبيب...', 'en': 'Search by doctor name...'},
    'all_types': {'ar': 'جميع الأنواع', 'en': 'All Types'},
    'general_doctor': {'ar': 'طبيب عام', 'en': 'General Doctor'},
    'specialist': {'ar': 'أخصائي', 'en': 'Specialist'},
    'doctors_table': {'ar': 'جدول الأطباء:', 'en': 'Doctors Table:'},
    'doctor': {'ar': 'طبيب', 'en': 'doctor'},
    'doctors': {'ar': 'أطباء', 'en': 'doctors'},
    'doctor_name': {'ar': 'اسم الطبيب', 'en': 'Doctor Name'},
    'doctor_type': {'ar': 'نوع الطبيب', 'en': 'Doctor Type'},
    'individual_selection': {'ar': 'تحديد فردي', 'en': 'Individual Selection'},
    'active_options_doctor': {'ar': 'الخيارات المفعلة لهذا الطبيب:', 'en': 'Active Options for this Doctor:'},
    'select_features_multiple_doctors': {'ar': 'حدد الـ Feature Boxes للأطباء المحددين:', 'en': 'Select Feature Boxes for Selected Doctors:'},
    'save_changes': {'ar': 'حفظ التغييرات', 'en': 'Save Changes'},
    'saving': {'ar': 'جاري الحفظ...', 'en': 'Saving...'},
    'loading_doctors_data': {'ar': 'جاري تحميل بيانات الأطباء...', 'en': 'Loading doctors data...'},
    'refresh_data': {'ar': 'تحديث البيانات من السيرفر', 'en': 'Refresh data from server'},
    'update_success': {'ar': 'تم التحديث بنجاح!', 'en': 'Updated successfully!'},
    'save_success': {'ar': 'تم الحفظ بنجاح!', 'en': 'Saved successfully!'},
    'select_doctors_first': {'ar': 'يرجى اختيار أطباء أولاً', 'en': 'Please select doctors first'},
    'no_valid_doctor_ids': {'ar': 'لا توجد معرفات أطباء صالحة', 'en': 'No valid doctor IDs'},
    'connection_error': {'ar': 'حدث خطأ في الاتصال', 'en': 'Connection error'},
    
    // ميزات الأطباء
    'waiting_list': {'ar': 'قائمة الانتظار', 'en': 'Waiting List'},
    'clinical_procedures_form': {'ar': 'نموذج الإجراءات السريرية', 'en': 'Clinical Procedures Form'},
    'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
    'prescription': {'ar': 'وصفة طبية', 'en': 'Prescription'},
    'xray_request': {'ar': 'طلب أشعة', 'en': 'X-Ray Request'},
  };

  String _tr(String key) {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final locale = languageProvider.currentLocale.languageCode;
      return _translations[key]?[locale] ?? key;
    } catch (e) {
      return key;
    }
  }

  // القيم الثابتة للفلترة
  static const String _allTypesValue = 'all';
  static const String _generalDoctorValue = 'general_doctor';
  static const String _specialistValue = 'specialist';

  // متغيرات إدارة الأطباء
  Set<String> selectedDoctors = {};
  final List<String> featureKeys = [
    'waiting_list',
    'clinical_procedures_form',
    'examined_patients',
    'prescription',
    'xray_request',
  ];

  Set<String> selectedFeatures = {};
  Set<String> singleDoctorFeatures = {};
  bool loadingSingleDoctor = false;
  String? lastSelectedDoctorId;
  bool savingInProgress = false;

  final Map<String, IconData> featureIcons = {
    'waiting_list': Icons.list_alt,
    'clinical_procedures_form': Icons.medical_information,
    'examined_patients': Icons.check_circle,
    'prescription': Icons.medical_services,
    'xray_request': Icons.camera_alt,
  };

  final Map<String, Color> featureColors = {
    'waiting_list': const Color(0xFF2A7A94),
    'clinical_procedures_form': Colors.redAccent,
    'examined_patients': Colors.teal,
    'prescription': Colors.deepPurple,
    'xray_request': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _currentDoctors = List.from(widget.doctors);
    _loadDoctorTypes();
    _printInitialData();
    _loadInitialData();
    
    doctorTypeFilter = _allTypesValue;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
    });
    
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/doctors'));
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsData = json.decode(response.body);
        setState(() {
          _currentDoctors = List<Map<String, dynamic>>.from(doctorsData);
          _loadDoctorTypes();
          _initialLoading = false;
        });
      } else {
        setState(() {
          _initialLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  void _printInitialData() {
    for (var doctor in _currentDoctors) {
      final rawId = doctor['uid'] ?? doctor['id'] ?? doctor['USER_ID'] ?? doctor['user_id'];
      final doctorId = rawId?.toString() ?? '';
      final name = doctor['name'] ?? doctor['fullName'] ?? 'بدون اسم';
      final type = doctor['type'] ?? doctor['DOCTOR_TYPE'] ?? doctor['TYPE'] ?? 'طبيب عام';
    }
  }
  
  void _loadDoctorTypes() {
    doctorTypes.clear();
    
    for (var doctor in _currentDoctors) {
      final rawId = doctor['uid'] ?? doctor['id'] ?? doctor['USER_ID'] ?? doctor['user_id'];
      final doctorId = rawId != null ? rawId.toString() : '';
      
      if (doctorId.isNotEmpty) {
        final type = doctor['type'] ?? doctor['DOCTOR_TYPE'] ?? doctor['TYPE'] ?? 'طبيب عام';
        doctorTypes[doctorId] = type.toString();
      }
    }
  }
  
  Future<void> _reloadDoctorsFromServer() async {
    setState(() {
      _loadingDoctors = true;
    });
    
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/doctors'));
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsData = json.decode(response.body);
        setState(() {
          _currentDoctors = List<Map<String, dynamic>>.from(doctorsData);
          _loadDoctorTypes();
        });
      }
    } finally {
      setState(() {
        _loadingDoctors = false;
      });
    }
  }
  
  Future<void> updateDoctorType(String doctorId, String type) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/type'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'doctorType': type}),
      );
      
      if (response.statusCode == 200) {
        await _reloadDoctorsFromServer();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('update_success'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr('connection_error'))));
      }
    } catch (e) {
      final message = friendlyErrorMessage(
        defaultMessage: _tr('connection_error'),
        connectionMessage: _tr('connection_error'),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _getDoctorType(Map<String, dynamic> doctor, String doctorId) {
    final name = doctor['name'] ?? doctor['fullName'] ?? 'بدون اسم';
    
    String finalType = doctorTypes[doctorId] ?? 
                      doctor['type']?.toString() ?? 
                      doctor['DOCTOR_TYPE']?.toString() ?? 
                      doctor['TYPE']?.toString() ?? 
                      "طبيب عام";
    
    if (finalType == _tr('specialist') || finalType.toLowerCase().contains('specialist')) {
      return "أخصائي";
    } else if (finalType == _tr('general_doctor') || finalType.toLowerCase().contains('general')) {
      return "طبيب عام";
    }
    
    return finalType;
  }

  List<Map<String, dynamic>> _getFilteredDoctors() {
    return _currentDoctors.where((doctor) {
      try {
        final name = (doctor['name'] ?? doctor['fullName'] ?? '').toString();
        final search = doctorSearch.toLowerCase();
        final nameMatches = search.isEmpty || name.toLowerCase().contains(search);
        
        final rawId = doctor['uid'] ?? doctor['id'] ?? doctor['USER_ID'] ?? doctor['user_id'];
        final doctorId = rawId?.toString() ?? '';
        final doctorType = _getDoctorType(doctor, doctorId);
        
        if (doctorTypeFilter == _allTypesValue) {
          return nameMatches;
        } else if (doctorTypeFilter == _generalDoctorValue) {
          return nameMatches && (doctorType == "طبيب عام" || doctorType == 'طبيب عام');
        } else if (doctorTypeFilter == _specialistValue) {
          return nameMatches && (doctorType == "أخصائي" || doctorType == 'أخصائي');
        }
        
        return nameMatches;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        final filteredDoctors = _getFilteredDoctors();
        for (var doctor in filteredDoctors) {
          final rawId = doctor['uid'] ?? doctor['id'] ?? doctor['USER_ID'] ?? doctor['user_id'];
          final doctorId = rawId?.toString() ?? '';
          if (doctorId.isNotEmpty) {
            selectedDoctors.add(doctorId);
          }
        }
      } else {
        selectedDoctors.clear();
      }
      
      if (selectedDoctors.length == 1) {
        _fetchSingleDoctorFeatures(selectedDoctors.first);
      } else {
        singleDoctorFeatures = {};
      }
    });
  }

  Widget buildFeatureBox({
    required String featureKey,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    final icon = featureIcons[featureKey] ?? Icons.extension;
    final color = featureColors[featureKey] ?? primaryColor;
    final label = _tr(featureKey);
    
    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => onChanged(!checked),
        child: Container(
          width: 150,
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: checked ? color : Colors.grey.shade300, width: checked ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fetchSingleDoctorFeatures(String doctorId) async {
    setState(() {
      loadingSingleDoctor = true;
      singleDoctorFeatures = {};
    });
    try {
      final resp = await http.get(Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId'));
      
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        
        final Set<String> features = {};
        dynamic allowed = data['allowedFeatures'] ?? data['ALLOWED_FEATURES'];
        
        if (allowed is List) {
          features.addAll(allowed.whereType<String>());
        } else if (allowed is String && allowed.isNotEmpty) {
          try {
            final parsed = json.decode(allowed);
            if (parsed is List) features.addAll(parsed.whereType<String>());
          } catch (_) {}
        }
        
        setState(() {
          singleDoctorFeatures = features;
          loadingSingleDoctor = false;
        });
      } else {
        setState(() {
          singleDoctorFeatures = {};
          loadingSingleDoctor = false;
        });
      }
    } catch (e) {
      setState(() {
        singleDoctorFeatures = {};
        loadingSingleDoctor = false;
      });
    }
  }

  Future<void> _saveSingleDoctorFeatures() async {
    final doctorId = selectedDoctors.first;
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/features'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'allowedFeatures': singleDoctorFeatures.toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('save_success'))),
        );
        _fetchSingleDoctorFeatures(doctorId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr('connection_error'))));
      }
    } catch (e) {
      final message = friendlyErrorMessage(
        defaultMessage: _tr('connection_error'),
        connectionMessage: _tr('connection_error'),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _saveMultipleDoctorsFeatures() async {
    if (selectedDoctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('select_doctors_first'))),
      );
      return;
    }

    setState(() {
      savingInProgress = true;
    });

    try {
      List<String> validDoctorIds = [];
      for (String doctorId in selectedDoctors) {
        if (doctorId.isNotEmpty && doctorId != 'null') {
          validDoctorIds.add(doctorId);
        }
      }

      if (validDoctorIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr('no_valid_doctor_ids'))),
        );
        return;
      }

      final requestData = {
        'doctorIds': validDoctorIds,
        'allowedFeatures': selectedFeatures.toList(),
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctors/batch/features'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? _tr('save_success'))),
        );
        
        setState(() {
          selectedFeatures.clear();
        });
      } else {
        await _tryAlternativeEndpoint(requestData);
      }
    } catch (e) {
      final message = friendlyErrorMessage(
        defaultMessage: _tr('connection_error'),
        connectionMessage: _tr('connection_error'),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() {
        savingInProgress = false;
      });
    }
  }

  Future<void> _tryAlternativeEndpoint(Map<String, dynamic> requestData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctors/batch/features-simple'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? _tr('save_success'))),
        );
        
        setState(() {
          selectedFeatures.clear();
        });
      } else {
        String errorMessage = _tr('connection_error');
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      final message = friendlyErrorMessage(
        defaultMessage: _tr('connection_error'),
        connectionMessage: _tr('connection_error'),
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ========== السايد بار الجديد ==========
  Widget _buildSidebar(bool isRtl) {
    return Align(
      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: 260,
        child: Stack(
          children: [
            AdminSidebar(
              primaryColor: primaryColor,
              accentColor: accentColor,
              userName: widget.userName,
              userImageUrl: widget.userImageUrl,
              onLogout: widget.onLogout,
              parentContext: context,
              translate: (context, key) => _tr(key),
              allUsers: widget.allUsers,
              userRole: 'admin',
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
                    showSidebarButton = true;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSidebarOverlay(bool isRtl) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isSidebarOpen = false;
          });
        },
        child: Container(
          color: Colors.black.withAlpha(77),
          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: 260,
              height: double.infinity,
              child: Material(
                elevation: 8,
                child: Stack(
                  children: [
                    AdminSidebar(
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      userName: widget.userName,
                      userImageUrl: widget.userImageUrl,
                      onLogout: widget.onLogout,
                      parentContext: context,
                      translate: (context, key) => _tr(key),
                      allUsers: widget.allUsers,
                      userRole: 'admin',
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
    );
  }

  Widget? _buildAppBarLeading(bool isLargeScreen, bool isRtl) {
    if (isLargeScreen) {
      return showSidebarButton && !isSidebarOpen
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() {
                  isSidebarOpen = true;
                  showSidebarButton = false;
                });
              },
            )
          : null;
    } else {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          setState(() {
            isSidebarOpen = !isSidebarOpen;
          });
        },
      );
    }
  }

  Widget _buildMainContent() {
    if (_loadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredDoctors = _getFilteredDoctors();
    final allFilteredSelected = filteredDoctors.isNotEmpty && 
        filteredDoctors.every((doctor) {
          final rawId = doctor['uid'] ?? doctor['id'] ?? doctor['USER_ID'] ?? doctor['user_id'];
          final doctorId = rawId?.toString() ?? '';
          return selectedDoctors.contains(doctorId);
        });

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: _tr('search_doctor_name'),
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              doctorSearch = val.trim();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _getValidDropdownValue(),
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: [
                            DropdownMenuItem(value: _allTypesValue, child: Text(_tr('all_types'))),
                            DropdownMenuItem(value: _generalDoctorValue, child: Text(_tr('general_doctor'))),
                            DropdownMenuItem(value: _specialistValue, child: Text(_tr('specialist'))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              doctorTypeFilter = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_tr('doctors_table'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A7A94))),
                          const SizedBox(width: 10),
                          Text(
                            '(${filteredDoctors.length} ${filteredDoctors.length == 1 ? _tr('doctor') : _tr('doctors')})',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(_tr('doctor_name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(_tr('doctor_type'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                              label: Row(
                                children: [
                                  Text(_tr('individual_selection'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.person, size: 16),
                                ],
                              ),
                            ),
                          ],
                          rows: [
                            DataRow(
                              cells: [
                                DataCell(Text("")),
                                const DataCell(Text('')),
                                DataCell(
                                  Checkbox(
                                    value: allFilteredSelected,
                                    onChanged: _toggleSelectAll,
                                  ),
                                ),
                              ],
                            ),
                            ...filteredDoctors.map((doctor) {
                              final rawId = doctor['uid'] ?? doctor['id'] ?? doctor['USER_ID'] ?? doctor['user_id'];
                              final doctorId = rawId?.toString() ?? '';

                              final nameFromDb = (doctor['name'] ?? doctor['fullName'] ?? doctor['FULL_NAME'] ?? doctor['NAME'] ?? doctor['FIRST_NAME'] ?? doctor['USERNAME'] ?? '').toString();
                              final displayName = nameFromDb.isNotEmpty ? nameFromDb : 'بدون اسم';

                              final doctorType = _getDoctorType(doctor, doctorId);

                              return DataRow(
                                selected: selectedDoctors.contains(doctorId),
                                cells: [
                                  DataCell(Text(displayName)),
                                  DataCell(
                                    DropdownButton<String>(
                                      value: doctorType,
                                      items: [
                                        DropdownMenuItem(value: "أخصائي", child: Text(_tr('specialist'))),
                                        DropdownMenuItem(value: "طبيب عام", child: Text(_tr('general_doctor'))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          updateDoctorType(doctorId, val);
                                        }
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    Checkbox(
                                      value: selectedDoctors.contains(doctorId),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            selectedDoctors.add(doctorId);
                                          } else {
                                            selectedDoctors.remove(doctorId);
                                          }
                                          if (selectedDoctors.length == 1) {
                                            _fetchSingleDoctorFeatures(selectedDoctors.first);
                                          } else {
                                            singleDoctorFeatures = {};
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              if (selectedDoctors.length == 1) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_tr('active_options_doctor'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A7A94))),
                            const SizedBox(width: 10),
                            Chip(
                              label: Text(
                                _getDoctorType(
                                  _currentDoctors.firstWhere(
                                    (doc) {
                                      final rawId = doc['uid'] ?? doc['id'] ?? doc['USER_ID'] ?? doc['user_id'];
                                      return rawId != null && rawId.toString() == selectedDoctors.first;
                                    },
                                    orElse: () => <String, dynamic>{},
                                  ),
                                  selectedDoctors.first
                                ),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (loadingSingleDoctor)
                          const Center(child: CircularProgressIndicator())
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: featureKeys.map((featureKey) {
                              return buildFeatureBox(
                                featureKey: featureKey,
                                checked: singleDoctorFeatures.contains(featureKey),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      singleDoctorFeatures.add(featureKey);
                                    } else {
                                      singleDoctorFeatures.remove(featureKey);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: Text(_tr('save_changes'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: loadingSingleDoctor
                                ? null
                                : () async {
                                    await _saveSingleDoctorFeatures();
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (selectedDoctors.length > 1) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_tr('select_features_multiple_doctors'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A7A94))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: selectedDoctors.map((doctorId) {
                            final doctor = _currentDoctors.firstWhere(
                              (doc) {
                                final rawId = doc['uid'] ?? doc['id'] ?? doc['USER_ID'] ?? doc['user_id'];
                                return rawId != null && rawId.toString() == doctorId;
                              },
                              orElse: () => <String, dynamic>{},
                            );
                            
                            final name = (doctor['name'] ?? doctor['fullName'] ?? 'بدون اسم').toString();
                            final type = _getDoctorType(doctor, doctorId);
                            
                            return Chip(
                              label: Text('$name ($type)'),
                              // ignore: deprecated_member_use
                              backgroundColor: primaryColor.withOpacity(0.1),
                              side: BorderSide(color: primaryColor),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: featureKeys.map((featureKey) {
                            return buildFeatureBox(
                              featureKey: featureKey,
                              checked: selectedFeatures.contains(featureKey),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedFeatures.add(featureKey);
                                  } else {
                                    selectedFeatures.remove(featureKey);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: savingInProgress 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save, color: Colors.white),
                            label: savingInProgress 
                                ? Text(_tr('saving'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                : Text(_tr('save_changes'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: savingInProgress
                                ? null
                                : () async {
                                    await _saveMultipleDoctorsFeatures();
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getValidDropdownValue() {
    final validValues = [_allTypesValue, _generalDoctorValue, _specialistValue];
    if (validValues.contains(doctorTypeFilter)) {
      return doctorTypeFilter;
    } else {
      return _allTypesValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRtl = languageProvider.currentLocale.languageCode == 'ar';

    if (_initialLoading) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FA),
          appBar: AppBar(
            backgroundColor: primaryColor,
            elevation: 3,
            title: Text(
              _tr('doctors_management'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: _buildAppBarLeading(false, isRtl),
          ),
          body: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(_tr('loading_doctors_data'), style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              if (isSidebarOpen)
                _buildMobileSidebarOverlay(isRtl),
            ],
          ),
        ),
      );
    }

    if (selectedDoctors.length == 1) {
      final doctorId = selectedDoctors.first;
      if (lastSelectedDoctorId != doctorId) {
        lastSelectedDoctorId = doctorId;
        _fetchSingleDoctorFeatures(doctorId);
      }
    } else {
      lastSelectedDoctorId = null;
      if (singleDoctorFeatures.isNotEmpty || loadingSingleDoctor) {
        setState(() {
          singleDoctorFeatures = {};
          loadingSingleDoctor = false;
        });
      }
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth >= 900;
          
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(_tr('doctors_management')),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: _buildAppBarLeading(isLargeScreen, isRtl),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadingDoctors ? null : _reloadDoctorsFromServer,
                  tooltip: _tr('refresh_data'),
                ),
              ],
            ),
            body: Row(
              children: [
                if (isLargeScreen && isSidebarOpen)
                  _buildSidebar(isRtl),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMainContent(),
                      if (!isLargeScreen && isSidebarOpen)
                        _buildMobileSidebarOverlay(isRtl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
