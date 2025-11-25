import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/language_provider.dart';
import '../loginpage.dart' show UserRole, LoginPage;
import 'role_guard.dart';
import '../Shared/waiting_list_page.dart';
import '../Shared/add_patient_page.dart';
import '../Secretry/account_approv.dart';
import '../Secretry/secretary_sidebar.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Secretry/all_patients_page.dart';
import '../Admin/booking_settings_page.dart';
import '../utils/name_utils.dart';

class SecretaryDashboard extends StatelessWidget {
  const SecretaryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRole: UserRole.secretary,
      child: _SecretaryDashboardContent(),
    );
  }
}

class _SecretaryDashboardContent extends StatefulWidget {
  const _SecretaryDashboardContent();

  @override
  State<_SecretaryDashboardContent> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<_SecretaryDashboardContent> {
  bool _notificationBannerShown = false;
  Widget _buildFeatureBox(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    int badgeCount = 0,
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
          child: Stack(
            children: [
              // المحتوى الرئيسي - متمركز بالكامل
              Center(
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
                        size: isSmallScreen
                            ? 24
                            : (isTablet ? 40 : 30),
                        color: color,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen
                              ? 14
                              : (isTablet ? 18 : 16),
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
              if (badgeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  String _userName = '';
  String _userImageUrl = '';
  List<Map<String, dynamic>> waitingList = [];
  List<Map<String, dynamic>> pendingAccounts = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool hasNewNotification = false;

  final Map<String, Map<String, String>> _translations = {
    'secretary_dashboard': {
      'ar': 'لوحة السكرتارية',
      'en': 'Secretary Dashboard'
    },
    'patient_files': {'ar': 'ملفات المرضى', 'en': 'Patient Files'},
    'add_patient': {'ar': 'إضافة مريض', 'en': 'Add Patient'},
    'approve_accounts': {
      'ar': 'الموافقة على الحسابات',
      'en': 'Approve Accounts'
    },
    'waiting_list': {'ar': 'قائمة الانتظار', 'en': 'Waiting List'},
    'secretary': {'ar': 'سكرتير', 'en': 'Secretary'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    'app_name': {
      'ar': 'عيادات أسنان الجامعة العربية الأمريكية',
      'en': 'Arab American University Dental Clinics'
    },
    'error_loading_data': {
      'ar': 'حدث خطأ في تحميل البيانات',
      'en': 'Error loading data'
    },
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'no_internet': {
      'ar': 'لا يوجد اتصال بالإنترنت',
      'en': 'No internet connection'
    },
    'server_error': {'ar': 'خطأ في السيرفر', 'en': 'Server error'},
  'all_patients': {'ar': 'سجل المرضى', 'en': 'Patients Registry'},
  'bookings': {'ar': 'الحجوزات', 'en': 'Bookings'},
  };

  @override
  void initState() {
    super.initState();
    _loadSecretaryData();
    _loadData();
    _checkNotificationBannerShown();
  }

  Future<void> _checkNotificationBannerShown() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationBannerShown = prefs.getBool('notificationBannerShown') ?? false;
    });
  }

  Future<void> _loadData() async {
    // تم إلغاء جلب بيانات المرضى والحسابات المعلقة مؤقتاً حتى يتم تفعيل المسارات في السيرفر
      if (mounted) {
        setState(() {
        waitingList = [];
        pendingAccounts = [];
          _hasError = false;
        });
      }
  }


  String _translate(BuildContext context, String key) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.currentLocale.languageCode;
    if (_translations.containsKey(key)) {
      final translationsForKey = _translations[key]!;
      if (translationsForKey.containsKey(langCode)) {
        return translationsForKey[langCode]!;
      } else if (translationsForKey.containsKey('en')) {
        return translationsForKey['en']!;
      } else {
        return key;
      }
    } else {
      return key;
    }
  }

  bool _isArabic(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.currentLocale.languageCode == 'ar';
  }

  String _getErrorMessage() {
    if (_hasError) {
      return _translate(context, 'server_error');
    }
    return _translate(context, 'error_loading_data');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void showDashboardBanner(String message, {Color backgroundColor = Colors.green}) {
    if (_notificationBannerShown) return;
    _notificationBannerShown = true;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('notificationBannerShown', true);
    });
    ScaffoldMessenger.of(context).clearMaterialBanners();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Row(
          children: [
         
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).clearMaterialBanners();
            },
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            label: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        ScaffoldMessenger.of(context).clearMaterialBanners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 350;
    final isLargeScreen = mediaQuery.size.width >= 800 || kIsWeb;

    return Directionality(
      textDirection: _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
      // ignore: deprecated_member_use
      child: WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).clearMaterialBanners();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(
              _translate(context, 'app_name'),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : (isLargeScreen ? 24 : 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () => languageProvider.toggleLanguage(),
              ),
              Stack(
                children: [
                 
                  if (hasNewNotification)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          drawer: SecretarySidebar(
            primaryColor: primaryColor,
            accentColor: accentColor,
            userName: _userName.isNotEmpty ? _userName : _translate(context, 'secretary'),
            userImageUrl: _userImageUrl,
            onLogout: _logout,
            parentContext: context,
            collapsed: false, 
            translate: (ctx, key) => _translate(context, key),
            pendingAccountsCount: pendingAccounts.length,
            userRole: 'secretary',
          ),
          body: _buildBody(context, isLargeScreen: isLargeScreen),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {bool isLargeScreen = false}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _getErrorMessage(),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadSecretaryData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.width < 600 ? 180 : 200,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/backgrownd.png'),
                      fit: BoxFit.cover,
                    ),
                    color: Color(0x4D000000),
                    borderRadius: BorderRadius.all(Radius.circular(15)),
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
                            _userImageUrl.isNotEmpty
                                ? CircleAvatar(
                                    radius: MediaQuery.of(context).size.width < 600 ? 30 : 40,
                                    backgroundColor: Colors.white.withAlpha(204),
                                    backgroundImage: NetworkImage(_userImageUrl),
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // سيتم عرض الأيقونة الافتراضية تلقائياً إذا فشل تحميل الصورة
                                    },
                                    child: _userImageUrl.isNotEmpty ? null : Icon(
                                      Icons.person,
                                      size: MediaQuery.of(context).size.width < 600 ? 30 : 40,
                                      color: accentColor,
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: MediaQuery.of(context).size.width < 600 ? 30 : 40,
                                    backgroundColor: Colors.white.withAlpha(204),
                                    child: Icon(
                                      Icons.person,
                                      size: MediaQuery.of(context).size.width < 600 ? 30 : 40,
                                      color: accentColor,
                                    ),
                                  ),
                            const SizedBox(height: 15),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                _userName,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 20,
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
                              _translate(context, 'secretary'),
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isWide = width > 900;
                      final isTablet = width >= 600 && width <= 900;
                      final crossAxisCount = isWide ? 4 : (isTablet ? 3 : 2);
                      final gridChildAspectRatio = isWide ? 1.1 : (isTablet ? 1.2 : 1.1);
                      final features = [
                        {
                          'icon': Icons.person_add,
                          'title': _translate(context, 'add_patient'),
                          'color': Colors.green,
                          'onTap': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AddPatientPage()),
                            );
                          }
                        },
                        {
                          'icon': Icons.verified_user,
                          'title': _translate(context, 'approve_accounts'),
                          'color': Colors.orange,
                          'badgeCount': pendingAccounts.length,
                          'onTap': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AccountApprovalPage()),
                            );
                          }
                        },
                        {
                          'icon': Icons.list_alt,
                          'title': _translate(context, 'waiting_list'),
                          'color': primaryColor,
                          'onTap': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WaitingListPage(userRole: 'secretary'),
                              ),
                            );
                          }
                        },
                        {
                          'icon': Icons.calendar_today,
                          'title': _translate(context, 'bookings'),
                          'color': Colors.purple,
                          'onTap': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingSettingsPage(),
                              ),
                            );
                          }
                        },
                        {
                          'icon': Icons.people,
                          'title': _translate(context, 'patient_files'),
                          'color': Colors.blue,
                          'onTap': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>PatientFilesPage(userRole: 'secretary'),
                              ),
                            );
                          }
                        },
                        
                      ];
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
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
                            badgeCount: (feature['badgeCount'] as int?) ?? 0,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
        }   

  Future<void> _loadSecretaryData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson == null) {
        if (!mounted) return;
        setState(() {
          _userName = _translate(context, 'secretary');
          _userImageUrl = '';
          _isLoading = false;
        });
        return;
      }
      final userData = json.decode(userDataJson);
      
      final name = extractFullName(Map<String, dynamic>.from(userData));

      final imageData = userData['IMAGE']?.toString().trim() ?? '';
      String imageUrl = '';
      if (imageData.isNotEmpty && (imageData.startsWith('http://') || imageData.startsWith('https://'))) {
        imageUrl = imageData;
      }

      if (!mounted) return;
      setState(() {
        _userName = name.isNotEmpty ? name : _translate(context, 'secretary');
        _userImageUrl = imageUrl;
        _isLoading = false;
        _hasError = false;
      });
      
      // طباعة للتصحيح
      
    } catch (e) {
      debugPrint('Error loading secretary data: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
    }
