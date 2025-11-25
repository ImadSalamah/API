// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'doctors_management_page.dart';
import 'package:provider/provider.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import '../loginpage.dart' show UserRole, LoginPage;
import 'role_guard.dart';
import '../Admin/add_user_page.dart';
import '../Admin/edit_user_page.dart';
import '../Admin/add_student.dart';
import '../Admin/admin_sidebar.dart';
import '../Admin/assign_patients_admin_page.dart';
import '../Admin/booking_settings_page.dart';
// ✅ استيراد الصفحة الجديدة للإدمن
import '../Admin/examined_patients_page.dart';
import 'package:dcs/config/api_config.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRole: UserRole.admin,
      child: _AdminDashboardContent(),
    );
  }
}

class _AdminDashboardContent extends StatefulWidget {
  const _AdminDashboardContent();

  @override
  State<_AdminDashboardContent> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboardContent> {
  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  final Color webSidebarColor = const Color(0xFFF5F5F5);
  
  // قاعدة البيانات الجديدة - Oracle API
  final String _apiBaseUrl = ApiConfig.baseUrl; // تغيير هذا إلى عنوان خادم Oracle الخاص بك

  String _userName = '';
  String _userImageUrl = '';
  List<Map<String, dynamic>> allUsers = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool isSidebarOpen = false;
  bool hasNewNotification = false;

  final Map<String, Map<String, String>> _translations = {
  'manage_doctors': {'ar': 'إدارة الأطباء', 'en': 'Manage Doctors'},
  'booking_table': {'ar': 'جدول الحجوزات', 'en': 'Booking Table'},
    'admin_dashboard': {'ar': 'لوحة الإدارة', 'en': 'Admin Dashboard'},
    'manage_users': {'ar': 'إدارة المستخدمين', 'en': 'Manage Users'},
    'add_user': {'ar': 'إضافة مستخدم', 'en': 'Add User'},
    'add_user_student': {'ar': 'إضافة طالب طب اسنان', 'en': 'Add Dental Student'},
    'change_permissions': {'ar': 'تغيير الصلاحيات', 'en': 'Change Permissions'},
    'admin': {'ar': 'مدير النظام', 'en': 'System Admin'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    // ✅ الترجمات الجديدة
    'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
    'all_patients_reports': {'ar': 'تقارير جميع المرضى', 'en': 'All Patients Reports'},
    'app_name': {
      'ar': 'عيادات أسنان الجامعة العربية الأمريكية',
      'en': 'Arab American University Dental Clinics'
    },
    'error_loading_data': {
      'ar': 'حدث خطأ في تحميل البيانات',
      'en': 'Error loading data'
    },
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'logout': {'ar': 'تسجيل الخروج', 'en': 'Logout'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'permissions': {'ar': 'الصلاحيات', 'en': 'Permissions'},
    'save': {'ar': 'حفظ', 'en': 'Save'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'close': {'ar': 'إغلاق', 'en': 'Close'},
    'menu': {'ar': 'القائمة', 'en': 'Menu'},
    'study_groups': {'ar': 'الشعب الدراسية', 'en': 'Study Groups'},
    'manage_study_groups': {
      'ar': 'إدارة الشعب الدراسية',
      'en': 'Manage Study Groups'
    },
    'add_study_group': {'ar': 'إضافة شعبة دراسية', 'en': 'Add Study Group'},
    'edit_study_groups': {
      'ar': 'تعديل الشعب الدراسية',
      'en': 'Edit Study Groups'
    },
  };

  // ✅ دالة مساعدة للحصول على التوكن من SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ✅ دالة مساعدة للحصول على headers مع التوكن
  // ignore: unused_element
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ✅ دالة مساعدة للحصول على ID المستخدم الحالي
  String? _getCurrentUserId() {
    try {
      // حاول الحصول من allUsers إذا كان محمل
      if (allUsers.isNotEmpty && _userName.isNotEmpty) {
        final currentUser = allUsers.firstWhere(
          (user) => 
            (user['FULL_NAME']?.toString().trim() == _userName) ||
            (user['name']?.toString().trim() == _userName),
          orElse: () => {},
        );
        
        if (currentUser.isNotEmpty) {
          return currentUser['USER_UID']?.toString() ?? 
                 currentUser['uid']?.toString() ??
                 currentUser['USER_ID']?.toString();
        }
      }
      
      // أو حاول من SharedPreferences
      return null; // يمكنك تعديل هذا حسب نظامك
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // تعريف قائمة الفيتشرات كمتغير في الكلاس
  List<Map<String, dynamic>> getFeaturesList(BuildContext context) {
    return [
      {
        'icon': Icons.people,
        'title': _translate(context, 'manage_users'),
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditUserPage(
                user: const {},
                usersList: allUsers,
                userName: _userName,
                userImageUrl: _userImageUrl,
                translate: _translate,
                onLogout: _logout,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.person_add,
        'title': _translate(context, 'add_user'),
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUserPage(
                userName: _userName,
                userImageUrl: _userImageUrl,
                translate: _translate,
                onLogout: _logout,
                allUsers: allUsers, // إضافة هذا
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.person_add,
        'title': _translate(context, 'add_user_student'),
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDentalStudentPage(
                userName: _userName,
                userImageUrl: _userImageUrl,
                translate: _translate,
                onLogout: _logout,
                allUsers: allUsers, // إضافة هذا
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.assignment_ind,
        'title': _isArabic(context) ? 'تعيين المرضى للطلاب' : 'Assign Patients to Students',
        'color': Colors.deepPurple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignPatientsAdminPage(
                userName: _userName,
                userImageUrl: _userImageUrl,
                onLogout: _logout,
                allUsers: allUsers,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.medical_services,
        'title': _translate(context, 'manage_doctors'),
        'color': Colors.teal,
        'onTap': () {
          final doctors = allUsers.where((user) =>
            (user['role'] == 'doctor' || user['ROLE'] == 'doctor')
          ).map((e) => Map<String, dynamic>.from(e)).toList();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorsManagementPage(
                doctors: doctors,
                userName: _userName,
                userImageUrl: _userImageUrl,
                translate: _translate,
                onLogout: _logout,
                allUsers: allUsers,
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.table_chart,
        'title': _translate(context, 'booking_table'),
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingSettingsPage(),
            ),
          );
        },
      },
      {
        'icon': Icons.check_circle,
        'title': _translate(context, 'examined_patients'), // ✅ استخدام الترجمة
        'color': Colors.teal,
        'onTap': () {
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          
          // ✅ تأكد أن اللغة إنجليزية للتوافق مع الصفحة الجديدة
          if (!languageProvider.isEnglish) {
            languageProvider.setLocale(const Locale('en'));
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminExaminedPatientsPage(
                adminName: _userName,
                adminImageUrl: _userImageUrl,
                currentUserId: _getCurrentUserId(),
                userAllowedFeatures: ['all_reports', 'all_patients', 'all_users'],
              ),
            ),
          );
        },
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadAllUsers();
  }

  Future<void> _loadAdminData() async {
    try {
      // الحصول على بيانات المستخدم من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');

      if (userDataJson == null) {
      if (!mounted) return;
        setState(() {
          _userName = _translate(context, 'admin');
          _isLoading = false;
        });
        return;
      }

  final userData = json.decode(userDataJson);
  debugPrint('ADMIN DASHBOARD userData: $userData');
      if (!mounted) return;
  _updateUserData(userData);
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ✅ دالة محسنة لتحميل المستخدمين باستخدام التوكن
  Future<void> _loadAllUsers() async {
    try {
      // الحصول على التوكن من SharedPreferences
      final token = await _getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);

      if (!mounted) return;
      setState(() {
          allUsers = users.map((user) => Map<String, dynamic>.from(user)).toList();
        _isLoading = false;
        _hasError = false;
      });
      } else if (response.statusCode == 401) {
        // التوكن غير صالح أو منتهي
        throw Exception('Authentication failed: Invalid or expired token');
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      
      // ✅ إظهار رسالة خطأ للمستخدم
      _showErrorSnackbar(context, e.toString());
    }
  }

  void _updateUserData(Map<String, dynamic> data) {
    final fullName = (data['FULL_NAME'] ?? '').toString().trim();
    String imageData = (data['IMAGE'] ?? '').toString().trim();
    // إذا لم تكن الصورة موجودة في SharedPreferences، ابحث عنها في allUsers
    if (imageData.isEmpty && data['USER_ID'] != null && allUsers.isNotEmpty) {
      final userFromList = allUsers.firstWhere(
        (u) => (u['USER_ID']?.toString() ?? u['uid']?.toString() ?? '') == data['USER_ID'].toString(),
        orElse: () => {},
      );
      if (userFromList.isNotEmpty && userFromList['IMAGE'] != null) {
        imageData = userFromList['IMAGE'].toString();
      }
    }
    setState(() {
      _userName = fullName.isNotEmpty ? fullName : _translate(context, 'admin');
      _userImageUrl = imageData;
      _hasError = false;
    });
  }

  String _translate(BuildContext context, String key) {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  bool _isArabic(BuildContext context) {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.currentLocale.languageCode == 'ar';
  }

  // ✅ دالة مساعدة لعرض رسائل الخطأ
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

  Future<void> _logout() async {
    // مسح بيانات المستخدم من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    await prefs.remove('auth_token'); // ✅ مسح التوكن أيضاً
    await prefs.remove('USER_ID');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Widget _buildLanguageButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isArabic(context) ? Icons.language : Icons.language,
        color: Colors.white,
      ),
      onPressed: () {
        Provider.of<LanguageProvider>(context, listen: false).toggleLanguage();
      },
    );
  }

  void showDashboardBanner(String message, {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).clearMaterialBanners();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
            child: Text(_translate(context, 'close'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // استهلاك LanguageProvider لإعادة بناء الواجهة عند تغيير اللغة
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Directionality(
          textDirection: _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(_translate(context, 'app_name')),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    isSidebarOpen = !isSidebarOpen;
                  });
                },
              ),
              actions: [
             
                _buildLanguageButton(context),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                )
              ],
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasError
                          ? _buildErrorWidget(context)
                          : _buildMainContent(context),
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
                        alignment: _isArabic(context)
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
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
                                    userName: _userName,
                                    userImageUrl: _userImageUrl,
                                    onLogout: _logout,
                                    parentContext: context,
                                    translate: _translate,
                                        allUsers: allUsers,
                                        userRole: 'admin', // إضافة هذا السطر
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: _isArabic(context) ? null : 0,
                                    left: _isArabic(context) ? 0 : null,
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
      },
    );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final isSmallScreen = width < 350;
    final isWide = width > 900;
    final isTablet = width >= 600 && width <= 900;
    final gridCount = isWide ? 4 : (isTablet ? 3 : 2);
    final horizontalPadding = isWide ? 60.0 : (isTablet ? 32.0 : 12.0);
    final gridChildAspectRatio = isWide ? 1.1 : (isTablet ? 1.2 : 1.1);

    // الحصول على قائمة الفيتشرات
    final features = getFeaturesList(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: mediaQuery.padding.bottom + (isSmallScreen ? 10 : 20),
              ),
              child: Column(
                children: [
                  _buildUserInfoCard(context, isSmallScreen, isWide, isTablet),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: features.length, // استخدام length من القائمة المعرفة
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: gridChildAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final feature = features[index];
                        return _buildFeatureBox(
                          context,
                          feature['icon'] as IconData,
                          feature['title'] as String,
                          feature['color'] as Color,
                          onTap: feature['onTap'] as VoidCallback,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoCard(BuildContext context, bool isSmallScreen, bool isWide, bool isTablet) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: isSmallScreen ? 180 : (isWide ? 240 : (isTablet ? 220 : 200)),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/backgrownd.png'),
          fit: BoxFit.cover,
        ),
        color: Color(0x4D000000),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (_userImageUrl.isNotEmpty && (_userImageUrl.startsWith('http://') || _userImageUrl.startsWith('https://')))
                    ? CircleAvatar(
                        radius: isSmallScreen ? 30 : (isWide ? 55 : (isTablet ? 45 : 40)),
                        backgroundColor: Colors.white.withAlpha(204),
                        child: ClipOval(
                          child: Image.network(
                            _userImageUrl,
                            width: isSmallScreen ? 60 : (isWide ? 110 : (isTablet ? 90 : 80)),
                            height: isSmallScreen ? 60 : (isWide ? 110 : (isTablet ? 90 : 80)),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: isSmallScreen ? 30 : (isWide ? 55 : (isTablet ? 45 : 40)),
                        backgroundColor: Colors.white.withAlpha(204),
                        child: Icon(
                          Icons.person,
                          size: isSmallScreen ? 30 : (isWide ? 55 : (isTablet ? 45 : 40)),
                          color: accentColor,
                        ),
                      ),
                SizedBox(height: isWide ? 30 : (isTablet ? 25 : 15)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _userName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : (isWide ? 28 : (isTablet ? 22 : 20)),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _translate(context, 'admin'),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : (isWide ? 18 : (isTablet ? 16 : 16)),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _translate(context, 'error_loading_data'),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _loadAdminData();
              _loadAllUsers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              _translate(context, 'retry'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBox(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 350;
    final isTablet = width >= 600;

    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // ✅ التصحيح هنا
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 18 : 12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 24 : (isTablet ? 40 : 30),
                  color: color,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
