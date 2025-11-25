// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../providers/language_provider.dart';
import 'main.dart';
import 'package:dcs/config/api_config.dart';

// ignore: constant_identifier_names
enum UserRole { patient, dental_student, doctor, secretary, nurse, admin, security, radiology }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  
  // قاعدة البيانات الجديدة - Oracle API
  final String _apiBaseUrl = ApiConfig.baseUrl; // تغيير هذا إلى عنوان الخادم الخاص بك

  final Map<String, Map<String, String>> _translations = {
    'login': {'ar': 'دخول', 'en': 'Login'},
    'username': {'ar': 'إسم المستخدم', 'en': 'Username'},
    'password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'remember_me': {'ar': 'تذكرني', 'en': 'Remember Me'},
    'forgot_password': {'ar': 'نسيت كلمة المرور؟', 'en': 'Forgot Password?'},
    'login_button': {'ar': 'تسجيل الدخول', 'en': 'Sign In'},
    'app_name': {
      'ar': 'عيادات أسنان الجامعة العربية الأمريكية',
      'en': 'Arab American University Dental Clinics'
    },
    'login_error': {
      'ar': 'اسم المستخدم أو كلمة المرور غير صحيحة',
      'en': 'Invalid username or password'
    },
    'reset_password_sent': {
      'ar': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      'en': 'Password reset link sent to your email'
    },
    'username_recovery': {
      'ar': 'استعادة اسم المستخدم',
      'en': 'Username Recovery'
    },
    'ok': {'ar': 'موافق', 'en': 'OK'},
    'no_student_account': {
      'ar': 'لا يوجد حساب طالب بهذا الاسم',
      'en': 'No student account found with this username'
    },
    'Please enter username': {
      'ar': 'الرجاء إدخال اسم المستخدم',
      'en': 'Please enter username'
    },
    'Username cannot contain spaces': {
      'ar': 'اسم المستخدم لا يمكن أن يحتوي على مسافات',
      'en': 'Username cannot contain spaces'
    },
    'Please enter password': {
      'ar': 'الرجاء إدخال كلمة المرور',
      'en': 'Please enter password'
    },
    'Password must be at least 6 characters': {
      'ar': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'en': 'Password must be at least 6 characters'
    },
    'Account data inconsistency detected': {
      'ar': 'عدم تطابق في بيانات الحساب',
      'en': 'Account data inconsistency detected'
    },
    'This account has been disabled': {
      'ar': 'هذا الحساب معطل',
      'en': 'This account has been disabled'
    },
    'Too many attempts, try again later': {
      'ar': 'محاولات كثيرة جداً، يرجى المحاولة لاحقاً',
      'en': 'Too many attempts, try again later'
    },
    'Account data problem detected': {
      'ar': 'هناك مشكلة في بيانات الحساب',
      'en': 'Account data problem detected'
    },
    'account_inactive': {
      'ar': 'الحساب غير فعال، يرجى مراجعة الكلية',
      'en': 'Account is inactive, please contact the college'
    },
    'login_general_error': {
      'ar': 'تعذر تسجيل الدخول الآن، يرجى المحاولة لاحقاً',
      'en': 'Unable to sign in right now, please try again later'
    },
    'connection_error': {
      'ar': 'خطأ في الاتصال بالخادم',
      'en': 'Server connection error'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('remembered_username') ?? '';
      }
    });
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('remembered_username', _usernameController.text);
    } else {
      await prefs.remove('remembered_username');
    }
  }

  // دالة لحفظ التوكن ومعلومات المستخدم في SharedPreferences
  Future<void> _saveUserDataAndToken(Map<String, dynamic> userData, String token) async {
    final prefs = await SharedPreferences.getInstance();
    
    // حفظ معلومات المستخدم
    await prefs.setString('userData', json.encode(userData));
    
    // حفظ التوكن
    await prefs.setString('auth_token', token);
    
    // حفظ كل البيانات المهمة
    if (userData['USER_ID'] != null) {
      await prefs.setString('USER_ID', userData['USER_ID'].toString());
    }
    if (userData['FULL_NAME'] != null) {
      await prefs.setString('FULL_NAME', userData['FULL_NAME']);
    }
    if (userData['IS_DEAN'] != null) {
      final isDean = int.tryParse(userData['IS_DEAN'].toString()) ?? 0;
      await prefs.setInt('IS_DEAN', isDean);
    }
    if (userData['EMAIL'] != null) {
      await prefs.setString('EMAIL', userData['EMAIL']);
    }
    if (userData['ROLE'] != null) {
      await prefs.setString('ROLE', userData['ROLE']);
    }
    if (userData['USERNAME'] != null) {
      await prefs.setString('USERNAME', userData['USERNAME']);
    }
    // إذا كان في صورة مستقبلاً
    if (userData['IMAGE'] != null) {
      await prefs.setString('IMAGE', userData['IMAGE']);
    }
  }

  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.isEnglish ? 'en' : 'ar'] ?? key;
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    try {
      await _saveRememberMe();
      await _handleStaffLogin(languageProvider);
    } catch (e) {
      _handleLoginError(context, e, languageProvider);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToDashboard(UserRole role) async {
    if (!mounted) return;

    String route;
    switch (role) {
      case UserRole.patient:
        route = '/patient-dashboard';
        break;
      case UserRole.dental_student:
        route = '/student-dashboard';
        break;
      case UserRole.doctor:
        route = '/doctor-dashboard';
        break;
      case UserRole.secretary:
        route = '/secretary-dashboard';
        break;
      case UserRole.nurse:
        route = '/nurse-dashboard';
        break;
      case UserRole.admin:
        route = '/admin-dashboard';
        break;
      case UserRole.security:
        route = '/security-dashboard';
        break;
      case UserRole.radiology:
        route = '/radiology-dashboard';
        break;
    }
    navigatorKey.currentState?.pushReplacementNamed(route);
  }

  Future<void> _handleStaffLogin(LanguageProvider languageProvider) async {
    final email = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final userData = responseData['user'];
      final token = responseData['token'];

      // إيقاف الدخول للحسابات غير المفعلة
      final rawIsActive = userData['IS_ACTIVE'] ?? userData['is_active'];
      final isActive = rawIsActive is num
          ? rawIsActive.toInt()
          : int.tryParse(rawIsActive?.toString() ?? '');
      if (isActive == 0) {
        throw Exception(_translate(context, 'account_inactive'));
      }

      // 1) حفظ التوكن + بيانات المستخدم كاملة
      await _saveUserDataAndToken(userData, token);

      // 2) تخزين USER_ID داخل Provider
      if (userData['USER_ID'] != null) {
        try {
          languageProvider.setUserId(userData['USER_ID'].toString());
        } catch (_) {}
      }

      // 3) تحديد الـ Role من الـ response
      final roleString = userData['ROLE']?.toString().trim().toLowerCase();
      UserRole userRole;
      
      // استخدم القيم التي تأتي من السيرفر مباشرة
      switch (roleString) {
        case 'admin':
          userRole = UserRole.admin;
          break;
        case 'doctor':
          userRole = UserRole.doctor;
          break;
        case 'secretary':
          userRole = UserRole.secretary;
          break;
        case 'nurse':
          userRole = UserRole.nurse;
          break;
        case 'security':
          userRole = UserRole.security;
          break;
        case 'dental_student':
          userRole = UserRole.dental_student;
          break;
        case 'radiology':
          userRole = UserRole.radiology;
          break;
        case 'patient':
          userRole = UserRole.patient;
          break;
        default:
          throw Exception(_translate(context, 'Account data inconsistency detected'));
      }

      // 4) تخزين الـ Role + الاسم + الصورة داخل Provider
      languageProvider.setUserData(
        role: userRole,
        userId: userData['USER_ID'].toString(),
        userName: userData['FULL_NAME'] ?? '',
        userImage: userData['IMAGE'] ?? '', // إذا كان في صورة في المستقبل
      );

      // 5) الذهاب للداشبورد المناسب
      await _navigateToDashboard(userRole);
    } else if (response.statusCode == 401) {
      throw Exception(_translate(context, 'login_error'));
    } else if (response.statusCode == 403) {
      throw Exception(_translate(context, 'account_inactive'));
    } else if (response.statusCode >= 500) {
      throw Exception(_translate(context, 'connection_error'));
    } else {
      throw Exception(_translate(context, 'login_general_error'));
    }
  }

  void _handleLoginError(BuildContext context, dynamic e, LanguageProvider languageProvider) {
    final errorMessage = _mapFriendlyLoginError(context, e);

    _showErrorSnackbar(context, errorMessage);
  }

  String _mapFriendlyLoginError(BuildContext context, dynamic error) {
    final defaultMessage = _translate(context, 'login_general_error');
    final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
    final lowerMessage = rawMessage.toLowerCase();

    // أخطاء الاتصال أو انقطاع الشبكة
    if (lowerMessage.contains('connection refused') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('timeout')) {
      return _translate(context, 'connection_error');
    }

    final knownMessages = [
      _translate(context, 'account_inactive'),
      _translate(context, 'login_error'),
      _translate(context, 'connection_error'),
    ];

    for (final message in knownMessages) {
      if (rawMessage.contains(message)) return message;
    }

    return defaultMessage;
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 700;
        return Directionality(
          textDirection: languageProvider.isEnglish ? TextDirection.ltr : TextDirection.rtl,
          child: isWeb
              ? Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor,
                            accentColor.withAlpha(179),
                            Colors.white.withAlpha(179),
                          ],
                        ),
                      ),
                    ),
                    Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        title: LayoutBuilder(
                          builder: (context, constraints) {
                            double fontSize;
                            if (constraints.maxWidth > 700) {
                              fontSize = 28;
                            } else if (constraints.maxWidth > 400) {
                              fontSize = 20;
                            } else {
                              fontSize = 16;
                            }
                            return Text(
                              _translate(context, 'app_name'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.language, color: Colors.white),
                            onPressed: () => languageProvider.toggleLanguage(),
                          ),
                        ],
                      ),
                      body: _buildLoginBody(context, constraints, isWeb, languageProvider),
                    ),
                  ],
                )
              : Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: Text(
                      _translate(context, 'app_name'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.language, color: Colors.white),
                        onPressed: () => languageProvider.toggleLanguage(),
                      ),
                    ],
                  ),
                  body: _buildLoginBody(context, constraints, isWeb, languageProvider),
                ),
        );
      },
    );
  }

  Widget _buildLoginBody(BuildContext context, BoxConstraints constraints, bool isWeb, LanguageProvider languageProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 700;
        return SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              width: double.infinity,
              decoration: isWeb ? null : null,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(isWeb ? 40.0 : 24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 420 : double.infinity,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Image.asset(
                                "assets/aauplogo.png",
                                width: isWeb ? 450 : 200,
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                  color: isWeb ? Colors.white : null,
                                  boxShadow: isWeb
                                      ? [
                                          const BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _translate(context, 'login'),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        labelText: _translate(context, 'username'),
                                        prefixIcon: Icon(Icons.person_outline, color: accentColor),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryColor, width: 2),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate(context, 'Please enter username');
                                        }
                                        if (value.contains(' ')) {
                                          return _translate(context, 'Username cannot contain spaces');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      key: const Key('password_field'),
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: _translate(context, 'password'),
                                        prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: accentColor,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryColor, width: 2),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate(context, 'Please enter password');
                                        }
                                        if (value.length < 6) {
                                          return _translate(context, 'Password must be at least 6 characters');
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleLogin(context),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) => setState(() => _rememberMe = value!),
                                          activeColor: primaryColor,
                                        ),
                                        Flexible(
                                          flex: 2,
                                          child: Text(
                                            _translate(context, 'remember_me'),
                                            style: TextStyle(color: primaryColor, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: const Key('login_button'),
                                        onPressed: _isLoading ? null : () => _handleLogin(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : Text(
                                                _translate(context, 'login_button'),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.facebook),
                                    onPressed: () => launchUrl(Uri.parse("https://www.facebook.com/aaup.edu")),
                                    color: Colors.blue[800],
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.linkedin),
                                    onPressed: () => launchUrl(Uri.parse("https://www.linkedin.com/school/arabamericanuniversity")),
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.instagram),
                                    onPressed: () => launchUrl(Uri.parse("https://www.instagram.com/Aaup_edu")),
                                    color: Colors.pinkAccent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
