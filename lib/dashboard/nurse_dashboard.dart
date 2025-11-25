import 'package:flutter/material.dart';
import 'dart:convert';
import '../loginpage.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'role_guard.dart';
import '../nurse/examined_patients_page.dart';
import '../nurse/nurse_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/name_utils.dart';

final class NurseDashboard extends StatelessWidget {
  const NurseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRole: UserRole.nurse,
      child: _NurseDashboardContent(),
    );
  }
}

final class _NurseDashboardContent extends StatefulWidget {
  const _NurseDashboardContent();

  @override
  State<_NurseDashboardContent> createState() => _NurseDashboardContentState();
}

class _NurseDashboardContentState extends State<_NurseDashboardContent> {
  static const Color primaryColor = Color(0xFF2A7A94);
  static const Color accentColor = Color(0xFF4AB8D8);
  
  String _userName = '';
  bool _isLoading = true;
  bool _hasError = false;

  static const Map<String, Map<String, String>> _translations = {
    'nurse_dashboard': {
      'ar': 'لوحة الممرض',
      'en': 'Nurse Dashboard'
    },
    'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
    'nurse': {'ar': 'ممرض', 'en': 'Nurse'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
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
    'welcome': {'ar': 'مرحباً', 'en': 'Welcome'},
  };

  @override
  void initState() {
    super.initState();
    _loadNurseData();
  }

  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.currentLocale.languageCode;
    
    if (_translations[key] case final translations?) {
      if (translations[langCode] case final localized?) return localized;
      if (translations['en'] case final fallback?) return fallback;
    }
    return key;
  }

  bool _isArabic(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.currentLocale.languageCode == 'ar';
  }

  String _getErrorMessage() {
    if (_hasError) {
      return _translate(context, 'server_error');
    }
    return _translate(context, 'error_loading_data');
  }

  void _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('جاري تسجيل الخروج...'),
              ],
            ),
          );
        },
      );

      await Future.delayed(const Duration(milliseconds: 500));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userData');
      await prefs.remove('token');
      
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 350;
    final isLargeScreen = mediaQuery.size.width >= 800;

    return Directionality(
      textDirection: _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
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
              tooltip: languageProvider.isEnglish ? 'Change Language' : 'تغيير اللغة',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut,
              tooltip: languageProvider.isEnglish ? 'Sign Out' : 'تسجيل الخروج',
            ),
          ],
        ),
        drawer: NurseSidebar(
          allowedFeatures: const <String>[
            'view_examinations',
          ],
          primaryColor: primaryColor,
          accentColor: accentColor,
          userName: _userName.isNotEmpty ? _userName : _translate(context, 'nurse'),
          userImageUrl: '',
          onLogout: _signOut,
          parentContext: context, 
          userRole: 'nurse',
        ),
        body: _buildBody(context, isLargeScreen: isLargeScreen),
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
              onPressed: _loadNurseData,
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
                            CircleAvatar(
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
                              _translate(context, 'nurse'),
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
                      
                      // Using Records for features
                      final features = <({IconData icon, String title, Color color, VoidCallback onTap})>[
                        (
                          icon: Icons.check_circle,
                          title: _translate(context, 'examined_patients'),
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NurseExaminedPatientsPage(),
                              ),
                            );
                          }
                        ),
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
                          return _FeatureBox(
                            icon: feature.icon,
                            title: feature.title,
                            color: feature.color,
                            onTap: feature.onTap,
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

  Future<void> _loadNurseData() async {
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
          _userName = _translate(context, 'nurse');
          _isLoading = false;
        });
        return;
      }
      final userData = json.decode(userDataJson);
      
      final name = extractFullName(Map<String, dynamic>.from(userData));

      if (!mounted) return;
      setState(() {
        _userName = name.isNotEmpty ? name : _translate(context, 'nurse');
        _isLoading = false;
        _hasError = false;
      });
      
    } catch (e) {
      debugPrint('Error loading nurse data: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
}

class _FeatureBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureBox({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
