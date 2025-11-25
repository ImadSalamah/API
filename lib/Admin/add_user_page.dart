// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:flutter/services.dart';
import 'admin_scaffold.dart';
import '../../auth_service.dart'; // تأكد من المسار الصحيح
import 'package:dcs/config/api_config.dart';
import '../utils/friendly_error.dart';

class AddUserPage extends StatefulWidget {
  final String? userName;
  final String? userImageUrl;
  final String Function(BuildContext, String) translate;
  final VoidCallback onLogout;
  final List<Map<String, dynamic>> allUsers;

  const AddUserPage({
    super.key,
    this.userName,
    this.userImageUrl,
    required this.translate,
    required this.onLogout,
    required this.allUsers,
  });

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _role;
  bool _isLoading = false;
  bool _isDean = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);

  final Map<String, Map<String, String>> _translations = {
    'add_user_title': {'ar': 'إضافة مستخدم جديد', 'en': 'Add New User'},
    'full_name': {'ar': 'الاسم الكامل', 'en': 'Full Name'},
    'username': {'ar': 'اسم المستخدم', 'en': 'Username'},
    'user_type': {'ar': 'نوع المستخدم', 'en': 'User Type'},
    'admin': {'ar': 'مدير', 'en': 'Admin'},
    'doctor': {'ar': 'طبيب', 'en': 'Doctor'},
    'nurse': {'ar': 'ممرض', 'en': 'Nurse'},
    'secretary': {'ar': 'سكرتير', 'en': 'Secretary'},
    'security': {'ar': 'أمن', 'en': 'Security'},
    'radiology': {'ar': 'فني أشعة', 'en': 'Radiology Technician'},
    'dean_on': {'ar': 'إلغاء تعيين العميد', 'en': 'Unset Dean'},
    'dean_off': {'ar': 'تعيين كعميد', 'en': 'Set as Dean'},
    'password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'confirm_password': {'ar': 'تأكيد كلمة المرور', 'en': 'Confirm Password'},
    'add_button': {'ar': 'إضافة المستخدم', 'en': 'Add User'},
    'personal_info': {'ar': 'المعلومات الشخصية', 'en': 'Personal Information'},
    'account_info': {'ar': 'معلومات الحساب', 'en': 'Account Information'},
    'required_field': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
    'validation_required': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
    'validation_password_length': {'ar': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل', 'en': 'Password must be at least 6 characters'},
    'validation_password_match': {'ar': 'كلمات المرور غير متطابقة', 'en': 'Passwords do not match'},
    'validation_user_type': {'ar': 'الرجاء اختيار نوع المستخدم', 'en': 'Please select user type'},
    'add_success': {'ar': 'تم إضافة المستخدم بنجاح', 'en': 'User added successfully'},
    'add_error': {'ar': 'حدث خطأ أثناء إضافة المستخدم', 'en': 'Error adding user'},
    'username_taken': {'ar': 'اسم المستخدم محجوز', 'en': 'Username already taken'},
    'show_password': {'ar': 'إظهار كلمة المرور', 'en': 'Show password'},
    'hide_password': {'ar': 'إخفاء كلمة المرور', 'en': 'Hide password'},
    'doctor_add_success': {'ar': 'تم إضافة الطبيب في جدول الأطباء', 'en': 'Doctor added to doctors table'},
    'doctor_add_error': {'ar': 'فشل في إضافة الطبيب في جدول الأطباء', 'en': 'Failed to add doctor to doctors table'},
    'access_denied': {'ar': 'ليس لديك صلاحية لإضافة مستخدمين', 'en': 'You do not have permission to add users'},
    'connection_error': {'ar': 'تعذر الاتصال، يرجى المحاولة مرة أخرى', 'en': 'Unable to connect, please try again'},
  };

  String _translate(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.isEnglish ? 'en' : 'ar';

    final translationMap = _translations[key];
    if (translationMap == null) {
      debugPrint('Missing translation for key: $key');
      return key;
    }

    final translatedText = translationMap[languageCode];
    return translatedText ?? key;
  }

  Future<bool> _isUsernameUnique(String username) async {
    try {
      // 🔥 جلب التوكن من AuthService
      final token = await AuthService.getToken();
      
      if (token == null) {
        debugPrint('⚠️ No token found, skipping username check');
        return true;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final exists = data.any((user) =>
          (user['USERNAME']?.toString().toLowerCase() ?? '') == username.toLowerCase()
        );
        return !exists;
      } else {
        debugPrint('⚠️ Cannot check username uniqueness. Status: ${response.statusCode}');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking username: $e');
      return true;
    }
  }

  // 🔥 NEW FUNCTION: Add doctor to DOCTORS table
  Future<void> _addDoctorToDoctorsTable(String doctorId) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token');
      }

      final doctorData = {
        'DOCTOR_ID': int.parse(doctorId),
        'ALLOWED_FEATURES': [],
        'DOCTOR_TYPE': 'طبيب عام',
        'IS_ACTIVE': 1,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctors'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(doctorData),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        debugPrint('ADD DOCTOR ERROR: statusCode=${response.statusCode}, body=${response.body}');
        throw Exception(_translate('doctor_add_error'));
      }

      debugPrint('✅ تم إضافة الطبيب في جدول الأطباء بنجاح - ID: $doctorId');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة الطبيب في جدول الأطباء: $e');
      throw Exception(_translate('doctor_add_error'));
    }
  }

  Future<void> _addUser() async {
    // 🔥 التحقق من الصلاحيات أولاً
    final userRole = await AuthService.getUserRole();
    if (userRole != 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('access_denied'))),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_password_match'))),
      );
      return;
    }

    if (_role == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_user_type'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 التحقق من أن اسم المستخدم فريد
      final isUnique = await _isUsernameUnique(_usernameController.text.trim());
      if (!isUnique) {
        throw Exception(_translate('username_taken'));
      }

      // جلب التوكن
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      // إنشاء البريد الإلكتروني التلقائي للموظفين
      final email = '${_usernameController.text.trim()}@aaup.edu';

      // إنشاء ID عشوائي للمستخدم
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // تحضير بيانات المستخدم
      final userData = {
        'USER_ID': userId,
        'FULL_NAME': _fullNameController.text.trim(),
        'USERNAME': _usernameController.text.trim(),
        'ROLE': _role,
        'EMAIL': email,
        'IMAGE': null,
        'CREATED_AT': DateTime.now().millisecondsSinceEpoch,
        'IS_ACTIVE': 1,
        'IS_DEAN': _role == 'dental_student' ? 0 : (_isDean ? 1 : 0),
        'PASSWORD': _passwordController.text.trim(), 
      };

      // 1. إضافة المستخدم في جدول users
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        debugPrint('ADD USER ERROR: statusCode=${response.statusCode}, body=${response.body}');
        throw Exception(_translate('add_error'));
      }

      // 2. إذا كان المستخدم طبيب، أضفه في جدول doctors أيضًا
      if (_role == 'doctor') {
        await _addDoctorToDoctorsTable(userId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('add_success'))),
      );

      // تنظيف الحقول بعد الإضافة الناجحة
      _clearForm();

    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = _translate('add_error');
      if (e.toString().contains(_translate('doctor_add_error'))) {
        errorMessage = _translate('doctor_add_error');
      } else if (e.toString().contains(_translate('username_taken'))) {
        errorMessage = _translate('username_taken');
      } else if (e.toString().contains('No authentication token')) {
        errorMessage = 'يرجى تسجيل الدخول أولاً';
      }
      
      final message = friendlyErrorMessage(
        defaultMessage: errorMessage,
        connectionMessage: _translate('connection_error'),
        error: e,
        knownMessages: [errorMessage],
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _role = null;
      _isDean = false;
    });
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    String cleanLabel = labelText.replaceAll(_translate('required_field'), '').trim();
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: cleanLabel,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildUserTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _translate('user_type'),
            style: TextStyle(
              color: primaryColor.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: [
            DropdownMenuItem(
              value: 'doctor',
              child: Text(_translate('doctor')),
            ),
            DropdownMenuItem(
              value: 'nurse',
              child: Text(_translate('nurse')),
            ),
            DropdownMenuItem(
              value: 'secretary',
              child: Text(_translate('secretary')),
            ),
            DropdownMenuItem(
              value: 'security',
              child: Text(_translate('security')),
            ),
            DropdownMenuItem(
              value: 'admin',
              child: Text(_translate('admin')),
            ),
            DropdownMenuItem(
              value: 'radiology',
              child: Text(_translate('radiology')),
            ),
          ],
          onChanged: (value) => setState(() {
            _role = value;
            if (value == 'dental_student') {
              _isDean = false;
            }
          }),
          validator: (value) => value == null ? _translate('validation_user_type') : null,
        ),
        if (_role != null && _role != 'dental_student') ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                foregroundColor: _isDean ? Colors.white : primaryColor,
                backgroundColor: _isDean ? primaryColor : Colors.white,
              ),
              onPressed: () => setState(() => _isDean = !_isDean),
              icon: Icon(_isDean ? Icons.check_circle : Icons.school_outlined),
              label: Text(_translate(_isDean ? 'dean_on' : 'dean_off')),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _translate('add_user_title'),
      userName: widget.userName,
      userImageUrl: widget.userImageUrl,
      primaryColor: primaryColor,
      accentColor: accentColor,
      allUsers: widget.allUsers,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // زر اختبار التوكن (يمكن حذفه لاحقاً)
                    FloatingActionButton.small(
                      onPressed: () async {
                        final token = await AuthService.getToken();
                        final role = await AuthService.getUserRole();
                        debugPrint('🔐 Token: $token');
                        debugPrint('👤 Role: $role');
                        
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Token: ${token != null ? "Exists" : "Missing"}\nRole: $role')),
                        );
                      },
                      child: Icon(Icons.security),
                    ),
                    const SizedBox(height: 10),

                    // قسم المعلومات الشخصية
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _translate('personal_info'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildTextFormField(
                            controller: _fullNameController,
                            labelText: '${_translate('full_name')} ${_translate('required_field')}',
                            prefixIcon: Icon(Icons.person, color: accentColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _translate('validation_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // حقل نوع المستخدم (Dropdown)
                          _buildUserTypeDropdown(),
                          const SizedBox(height: 15),

                          // اسم المستخدم
                          _buildTextFormField(
                            controller: _usernameController,
                            labelText: '${_translate('username')} ${_translate('required_field')}',
                            prefixIcon: Icon(Icons.person_pin, color: accentColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _translate('validation_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // قسم معلومات الحساب
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _translate('account_info'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // كلمة المرور
                          _buildTextFormField(
                            controller: _passwordController,
                            labelText: '${_translate('password')} ${_translate('required_field')}',
                            obscureText: !_showPassword,
                            prefixIcon: Icon(Icons.lock, color: accentColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: accentColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _translate('validation_required');
                              }
                              if (value.length < 6) {
                                return _translate('validation_password_length');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // تأكيد كلمة المرور
                          _buildTextFormField(
                            controller: _confirmPasswordController,
                            labelText: '${_translate('confirm_password')} ${_translate('required_field')}',
                            obscureText: !_showConfirmPassword,
                            prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: accentColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _translate('validation_required');
                              }
                              if (value != _passwordController.text) {
                                return _translate('validation_password_match');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // زر الإضافة
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          _translate('add_button'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
