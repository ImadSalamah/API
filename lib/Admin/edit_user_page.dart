// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/name_utils.dart';
import '../utils/friendly_error.dart';

import '../providers/language_provider.dart';
import 'admin_sidebar.dart';
import 'package:dcs/config/api_config.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> usersList;
  final String? userName;
  final String? userImageUrl;
  final String Function(BuildContext, String)? translate;
  final VoidCallback? onLogout;

  const EditUserPage({
    super.key,
    required this.user,
    required this.usersList,
    this.userName,
    this.userImageUrl,
    this.translate,
    this.onLogout,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentUniversityIdController = TextEditingController();
  final _studyYearController = TextEditingController();

  String? _selectedRole;
  String? _selectedStatus;
  bool _isLoading = false;
  bool _isDean = false;
  bool isSidebarOpen = false;
  bool _showSearchResults = false;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  final String _apiBaseUrl = ApiConfig.baseUrl;
  static const List<String> _allowedRoles = [
    'dental_student',
    'doctor',
    'secretary',
    'nurse',
    'admin',
    'security',
    'radiology',
  ];

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

  Future<void> _loadAllUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        setState(() {
          _allUsers = users.map((user) => Map<String, dynamic>.from(user)).toList();
        });
      } else if (response.statusCode == 401) {
        _showSnackBar(_tr(context, 'no_token_error'));
      } else {
        debugPrint('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      final message = friendlyErrorMessage(
        defaultMessage: _tr(context, 'load_users_error'),
        connectionMessage: _tr(context, 'connection_error'),
        error: e,
      );
      _showSnackBar(message);
    }
  }

  Future<void> _loadStudentUniversityId() async {
    if (_selectedUser == null || _selectedRole != 'dental_student') return;

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/students/${_selectedUser!['USER_ID']}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final studentData = json.decode(response.body);
        setState(() {
          _studentUniversityIdController.text = studentData['STUDENT_UNIVERSITY_ID']?.toString() ?? '';
          final studyYear = studentData['STUDY_YEAR']?.toString();
          if (studyYear != null && studyYear.isNotEmpty) {
            _studyYearController.text = studyYear;
          }
        });
      } else if (response.statusCode == 404) {
        debugPrint('Student record not found, will create one on save');
      }
    } catch (e) {
      debugPrint('Error loading student university ID: $e');
    }
  }

  final Map<String, Map<String, String>> _translations = {
    'edit_user': {'ar': 'تعديل مستخدم', 'en': 'Edit User'},
    'search_user': {'ar': 'ابحث عن مستخدم', 'en': 'Search User'},
    'select_user': {'ar': 'اختر المستخدم', 'en': 'Select User'},
    'personal_info': {'ar': 'المعلومات الشخصية', 'en': 'Personal Information'},
    'account_info': {'ar': 'معلومات الحساب', 'en': 'Account Information'},
    'full_name': {'ar': 'الاسم الكامل', 'en': 'Full Name'},
    'username': {'ar': 'اسم المستخدم', 'en': 'Username'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'student_university_id': {'ar': 'الرقم الجامعي', 'en': 'University ID'},
    'study_year': {'ar': 'السنة الدراسية', 'en': 'Study Year'},
    'study_year_one_digit': {'ar': 'أدخل رقم سنة واحد (1-6)', 'en': 'Enter one digit year (1-6)'},
    'role': {'ar': 'الدور', 'en': 'Role'},
    'patient': {'ar': 'مريض', 'en': 'Patient'},
    'dental_student': {'ar': 'طالب طب أسنان', 'en': 'Dental Student'},
    'doctor': {'ar': 'طبيب', 'en': 'Doctor'},
    'secretary': {'ar': 'سكرتير', 'en': 'Secretary'},
    'nurse': {'ar': 'ممرض', 'en': 'Nurse'},
    'admin': {'ar': 'مدير', 'en': 'Admin'},
    'security': {'ar': 'أمن', 'en': 'Security'},
    'radiology': {'ar': 'فني أشعة', 'en': 'Radiology Technician'},
    'status': {'ar': 'الحالة', 'en': 'Status'},
    'active': {'ar': 'نشط', 'en': 'Active'},
    'inactive': {'ar': 'غير نشط', 'en': 'Inactive'},
    'dean_on': {'ar': 'إلغاء تعيين العميد', 'en': 'Unset Dean'},
    'dean_off': {'ar': 'تعيين كعميد', 'en': 'Set as Dean'},
    'save_changes': {'ar': 'حفظ التغييرات', 'en': 'Save Changes'},
    'update_success': {'ar': 'تم التحديث بنجاح', 'en': 'Updated successfully'},
    'update_failed': {'ar': 'فشل التحديث', 'en': 'Update failed'},
    'no_user_selected': {'ar': 'لم يتم اختيار مستخدم', 'en': 'No user selected'},
    'search_hint': {'ar': 'ابحث بالاسم أو اسم المستخدم...', 'en': 'Search by name or username...'},
    'required_field': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
    'invalid_email': {'ar': 'بريد إلكتروني غير صالح', 'en': 'Invalid email'},
    'no_token_error': {'ar': 'خطأ في المصادقة، يرجى تسجيل الدخول مرة أخرى', 'en': 'Authentication error, please login again'},
    'no_users_found': {'ar': 'لا يوجد مستخدمين', 'en': 'No users found'},
    'search_results': {'ar': 'نتائج البحث', 'en': 'Search Results'},
    'student_id_save_failed': {'ar': 'تم تحديث المستخدم ولكن فشل حفظ الرقم الجامعي', 'en': 'User updated but failed to save university ID'},
    'connection_error': {'ar': 'تعذر الاتصال، يرجى المحاولة مرة أخرى', 'en': 'Unable to connect, please try again'},
    'load_users_error': {'ar': 'تعذر تحميل المستخدمين حالياً', 'en': 'Unable to load users right now'},
    'form_error': {'ar': 'يرجى تصحيح الحقول المطلوبة', 'en': 'Please fix the highlighted fields'},
  };

  String _tr(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _allUsers = widget.usersList;
    _initializeForm();
    _loadAllUsers();
  }

  void _initializeForm() {
    if (widget.user.isNotEmpty) {
      _selectedUser = widget.user;
      _fillFormWithUserData(widget.user);
    }
  }

  void _fillFormWithUserData(Map<String, dynamic> user) {
    _fullNameController.text = extractFullName(user);
    _usernameController.text = user['USERNAME']?.toString() ?? '';
    _emailController.text = user['EMAIL']?.toString() ?? '';
    
    final role = user['ROLE']?.toString();
    _selectedRole = _allowedRoles.contains(role) ? role : null;
    _selectedStatus = user['IS_ACTIVE']?.toString() == '1' ? 'active' : 'inactive';
    _isDean = _selectedRole != null &&
        _selectedRole != 'dental_student' &&
        user['IS_DEAN']?.toString() == '1';

    // Show any existing university id immediately while awaiting API fetch
    final localUniversityId = user['STUDENT_UNIVERSITY_ID']?.toString();
    if (localUniversityId != null && localUniversityId.isNotEmpty) {
      _studentUniversityIdController.text = localUniversityId;
    }
    final localStudyYear = user['STUDY_YEAR']?.toString();
    if (localStudyYear != null && localStudyYear.isNotEmpty) {
      _studyYearController.text = localStudyYear;
    }

    if (_selectedRole == 'dental_student') {
      _loadStudentUniversityId();
    }
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }

    final searchLower = query.toLowerCase();
    
    setState(() {
      _searchResults = _allUsers.where((user) {
        final fullName = extractFullName(user).toLowerCase();
        final firstName = extractFirstName(user).toLowerCase();
        final username = user['USERNAME']?.toString().toLowerCase() ?? '';
        final email = user['EMAIL']?.toString().toLowerCase() ?? '';
        
        return fullName.contains(searchLower) ||
               firstName.contains(searchLower) ||
               username.contains(searchLower) ||
               email.contains(searchLower);
      }).toList();
      
      _showSearchResults = true;
    });
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
      _fillFormWithUserData(user);
      _showSearchResults = false;
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _saveChanges() async {
    if (_selectedUser == null) {
      _showSnackBar(_tr(context, 'no_user_selected'));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar(_tr(context, 'form_error'));
      return;
    }
    if (_selectedStatus == null) {
      _showSnackBar(_tr(context, 'required_field'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar(_tr(context, 'no_token_error'));
        setState(() => _isLoading = false);
        return;
      }

      final isDeanValue = _selectedRole == 'dental_student'
          ? 0
          : (_isDean ? 1 : 0);

      final updatedData = {
        'FULL_NAME': _fullNameController.text.trim(),
        'USERNAME': _usernameController.text.trim(),
        'EMAIL': _emailController.text.trim(),
        'ROLE': _selectedRole,
        'IS_ACTIVE': _selectedStatus == 'active' ? 1 : 0,
        'IS_DEAN': isDeanValue,
        if (_selectedRole == 'dental_student')
          'STUDENT_UNIVERSITY_ID': _studentUniversityIdController.text.trim(),
        if (_selectedRole == 'dental_student')
          'STUDY_YEAR': int.tryParse(_studyYearController.text.trim()) ?? 0,
      };

      debugPrint('Updating user with data: $updatedData');

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/users/${_selectedUser!['USER_ID']}'),
        headers: headers,
        body: json.encode(updatedData),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Student fields are sent with the same request; no extra API call needed
        _showSnackBar(_tr(context, 'update_success'));
        
        final updatedUser = json.decode(response.body);
        setState(() {
          _selectedUser = updatedUser;
          _isDean = _selectedRole != 'dental_student' &&
              updatedUser['IS_DEAN']?.toString() == '1';
        });
        
        await _loadAllUsers();
        
        if (mounted) {
          Navigator.of(context).pop(updatedUser);
        }
      } else if (response.statusCode == 401) {
        _showSnackBar(_tr(context, 'no_token_error'));
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? _tr(context, 'update_failed');
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      debugPrint('Error in save changes: $e');
      final message = friendlyErrorMessage(
        defaultMessage: _tr(context, 'update_failed'),
        connectionMessage: _tr(context, 'connection_error'),
        error: e,
      );
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }




  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains(_tr(context, 'update_success')) ? Colors.green : 
                       message.contains(_tr(context, 'student_id_save_failed')) ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRtl = languageProvider.currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_tr(context, 'edit_user')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
            Positioned.fill(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildUserSearchSection(),
                      const SizedBox(height: 20),
                      
                      if (_selectedUser != null) ...[
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 20),
                        _buildAccountInfoSection(),
                        const SizedBox(height: 30),
                        _buildSaveButton(),
                      ],
                    ],
                  ),
                ),
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
                    alignment: isRtl ? Alignment.topRight : Alignment.topLeft,
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
                                translate: _tr,
                                allUsers: _allUsers,
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(context, 'search_user'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _tr(context, 'search_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _searchUsers,
          ),
          
          if (_showSearchResults) ...[
            const SizedBox(height: 15),
            Text(
              _tr(context, 'search_results'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _searchResults.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _tr(context, 'no_users_found'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isSelected = _selectedUser?['USER_ID'] == user['USER_ID'];
                        
                        final displayName = extractFullName(user);
                        final initial = extractFirstName(user);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Text(
                                initial.isNotEmpty ? initial.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              displayName.isNotEmpty ? displayName : 'غير معروف',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user['USERNAME']?.toString() ?? ''} - ${user['ROLE']?.toString() ?? ''}',
                                ),
                                if (user['EMAIL'] != null)
                                  Text(
                                    user['EMAIL'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
                            onTap: () => _selectUser(user),
                          ),
                        );
                      },
                    ),
            ),
          ],
          
          if (_selectedUser != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المستخدم المحدد:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          _selectedUser!['FULL_NAME']?.toString() ?? 'غير معروف',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${_selectedUser!['USERNAME']?.toString() ?? ''} - ${_selectedUser!['ROLE']?.toString() ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedUser = null;
                        _clearForm();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _clearForm() {
    _fullNameController.clear();
    _usernameController.clear();
    _emailController.clear();
    _studentUniversityIdController.clear();
    _studyYearController.clear();
    _selectedRole = null;
    _selectedStatus = null;
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _tr(context, 'personal_info'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildNameFields(),
          const SizedBox(height: 15),
          _buildContactFields(),
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFormField(
          controller: _fullNameController,
          labelText: _tr(context, 'full_name'),
          validator: (value) => _validateRequired(value),
        ),
      ],
    );
  }

  Widget _buildContactFields() {
    return Column(
      children: [
        _buildTextFormField(
          controller: _emailController,
          labelText: _tr(context, 'email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) => _validateEmail(value),
        ),
        if (_selectedRole == 'dental_student') ...[
          const SizedBox(height: 15),
          _buildTextFormField(
            controller: _studentUniversityIdController,
            labelText: _tr(context, 'student_university_id'),
            validator: (value) => _validateRequired(value),
          ),
          const SizedBox(height: 15),
          _buildTextFormField(
            controller: _studyYearController,
            labelText: _tr(context, 'study_year'),
            keyboardType: TextInputType.number,
            maxLines: 1,
            maxLength: 1,
            validator: (value) => _validateStudyYear(value),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _tr(context, 'account_info'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _usernameController,
            labelText: _tr(context, 'username'),
            validator: (value) => _validateRequired(value),
          ),
          const SizedBox(height: 15),
          _buildRoleDropdown(),
          const SizedBox(height: 10),
          _buildDeanToggle(),
          const SizedBox(height: 15),
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final roleValue = _allowedRoles.contains(_selectedRole) ? _selectedRole : null;

    return DropdownButtonFormField<String>(
      value: roleValue,
      decoration: InputDecoration(
        labelText: _tr(context, 'role'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: _allowedRoles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(_tr(context, role)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
          if (value == 'dental_student') {
            _isDean = false;
            _loadStudentUniversityId();
          } else {
            _studentUniversityIdController.clear();
          }
        });
      },
      validator: (value) => value == null ? _tr(context, 'required_field') : null,
    );
  }

  Widget _buildDeanToggle() {
    if (_selectedRole == null || _selectedRole == 'dental_student') {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor),
          foregroundColor: _isDean ? Colors.white : primaryColor,
          backgroundColor: _isDean ? primaryColor : Colors.white,
        ),
        onPressed: () => setState(() => _isDean = !_isDean),
        icon: Icon(_isDean ? Icons.check_circle : Icons.school_outlined),
        label: Text(_tr(context, _isDean ? 'dean_on' : 'dean_off')),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            _tr(context, 'status'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            _buildStatusToggleButton(
              label: _tr(context, 'active'),
              isSelected: _selectedStatus == 'active',
              onTap: () => setState(() => _selectedStatus = 'active'),
            ),
            const SizedBox(width: 8),
            _buildStatusToggleButton(
              label: _tr(context, 'inactive'),
              isSelected: _selectedStatus == 'inactive',
              onTap: () => setState(() => _selectedStatus = 'inactive'),
            ),
          ],
        ),
        if (_selectedStatus == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _tr(context, 'required_field'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(isSelected ? Icons.toggle_on : Icons.toggle_off,
          color: isSelected ? primaryColor : Colors.grey),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade400),
        foregroundColor: isSelected ? Colors.white : primaryColor,
        backgroundColor: isSelected ? primaryColor : Colors.white,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _tr(context, 'save_changes'),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return _tr(context, 'required_field');
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return _tr(context, 'invalid_email');
    }
    return null;
  }

  String? _validateStudyYear(String? value) {
    if (value == null || value.isEmpty) return _tr(context, 'required_field');
    if (!RegExp(r'^[1-6]$').hasMatch(value)) {
      return _tr(context, 'study_year_one_digit');
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _studentUniversityIdController.dispose();
    _studyYearController.dispose();
    super.dispose();
  }
}
