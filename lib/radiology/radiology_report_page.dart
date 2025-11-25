// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/name_utils.dart';

import '../providers/language_provider.dart';
import 'radiology_sidebar.dart';
import 'xray_request_list_page.dart';
import 'package:dcs/config/api_config.dart';

class RadiologyReportPage extends StatefulWidget {
  const RadiologyReportPage({super.key});

  @override
  State<RadiologyReportPage> createState() => _RadiologyReportPageState();
}

class _RadiologyReportPageState extends State<RadiologyReportPage> {
  DateTime selectedDate = DateTime.now();
  DateTime? customStartDate;
  DateTime? customEndDate;
  String reportType = 'day'; // 'day', 'week', 'month', 'custom'
  bool isLoading = false;
  Map<dynamic, dynamic>? reportData;
  String? errorMsg;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchReport();
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
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userName = 'فني الأشعة';
      });
    }
  }

  // دالة لحساب الفترات الزمنية
  Map<String, String> _calculateDateRange() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    switch (reportType) {
      case 'day':
        // اليوم: من التاريخ المحدد إلى نفس التاريخ
        return {
          'startDate': formatter.format(selectedDate),
          'endDate': formatter.format(selectedDate)
        };

      case 'week':
        // الأسبوع: من التاريخ المحدد إلى +6 أيام
        final endDate = selectedDate.add(Duration(days: 6));
        return {
          'startDate': formatter.format(selectedDate),
          'endDate': formatter.format(endDate)
        };

      case 'month':
        // الشهر: من أول الشهر إلى آخر الشهر
        final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
        return {
          'startDate': formatter.format(startOfMonth),
          'endDate': formatter.format(endOfMonth)
        };

      case 'custom':
        // فترة مخصصة
        if (customStartDate != null && customEndDate != null) {
          return {
            'startDate': formatter.format(customStartDate!),
            'endDate': formatter.format(customEndDate!)
          };
        } else {
          return {
            'startDate': formatter.format(DateTime.now()),
            'endDate': formatter.format(DateTime.now())
          };
        }

      default:
        return {
          'startDate': formatter.format(selectedDate),
          'endDate': formatter.format(selectedDate)
        };
    }
  }

  Future<void> _fetchReport() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      reportData = null;
    });

    try {
      // حساب الفترة الزمنية
      final dateRange = _calculateDateRange();
      final startDate = dateRange['startDate']!;
      final endDate = dateRange['endDate']!;

      // حاول جلب التقرير من جدول XRAY_IMAGES الجديد مع إبقاء مسار قديم كخيار احتياطي
      final endpoints = [
        '${ApiConfig.baseUrl}/xray-images/report?startDate=$startDate&endDate=$endDate',
        '${ApiConfig.baseUrl}/xray_custom_report?startDate=$startDate&endDate=$endDate',
      ];

      String? lastError;
      for (final endpoint in endpoints) {
        final response = await http.get(Uri.parse(endpoint)).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final normalized = _normalizeReportResponse(data);

          setState(() {
            reportData = normalized;
            isLoading = false;
            errorMsg = normalized.isEmpty ? 'لا يوجد بيانات للفترة المختارة' : null;
          });
          return;
        } else {
          lastError = 'خطأ في السيرفر (${response.statusCode})';
        }
      }

      setState(() {
        reportData = {};
        errorMsg = lastError ?? 'تعذر جلب البيانات';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          errorMsg = 'انتهت مهلة الاتصال بالسيرفر';
        } else {
          errorMsg = 'حدث خطأ أثناء جلب البيانات';
        }
        isLoading = false;
      });
    }
  }

  Map<dynamic, dynamic> _normalizeReportResponse(dynamic data) {
    if (data is Map) {
      final map = Map<dynamic, dynamic>.from(data);
      if (map.containsKey('data') && map['data'] is Map) {
        return Map<dynamic, dynamic>.from(map['data'] as Map);
      }
      return map;
    }

    if (data is List) {
      final Map<dynamic, dynamic> grouped = {};
      for (final item in data) {
        if (item is Map) {
          final mapItem = Map<dynamic, dynamic>.from(item);
          final xrayType = (mapItem['xray_type'] ?? mapItem['XRAY_TYPE'] ?? 'غير محدد').toString();
          final clinic = (mapItem['clinic'] ??
                  mapItem['CLINIC'] ??
                  mapItem['clinic_name'] ??
                  mapItem['CLINIC_NAME'] ??
                  'غير محدد')
              .toString();
          final countValue =
              mapItem['count'] ?? mapItem['COUNT'] ?? mapItem['total'] ?? mapItem['TOTAL'] ?? 1;
          final count = _parseCount(countValue);

          final clinicMap = grouped.putIfAbsent(xrayType, () => <String, dynamic>{});
          if (clinicMap is Map) {
            final prev = _parseCount(clinicMap[clinic]);
            clinicMap[clinic] = prev + count;
          }
        }
      }
      return grouped;
    }

    return {};
  }

  int _parseCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _fetchReport();
    }
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (customStartDate ?? DateTime.now()) : (customEndDate ?? DateTime.now()),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          customStartDate = picked;
          if (customEndDate != null && customEndDate!.isBefore(customStartDate!)) {
            customEndDate = customStartDate;
          }
        } else {
          customEndDate = picked;
          if (customStartDate != null && customEndDate!.isBefore(customStartDate!)) {
            customStartDate = customEndDate;
          }
        }
      });
      if (customStartDate != null && customEndDate != null) {
        setState(() {
          reportType = 'custom';
        });
        _fetchReport();
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر نوع التقرير', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر التقرير اليومي
            ListTile(
              leading: const Icon(Icons.today, color: Color(0xFF2A7A94)),
              title: const Text('تقرير يومي'),
              subtitle: Text(_getDateRangeText('day')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  reportType = 'day';
                });
                Navigator.pop(context);
                _fetchReport();
              },
            ),
            
            const Divider(),
            
            // زر التقرير الأسبوعي
            ListTile(
              leading: const Icon(Icons.calendar_view_week, color: Color(0xFF2A7A94)),
              title: const Text('تقرير أسبوعي'),
              subtitle: Text(_getDateRangeText('week')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  reportType = 'week';
                });
                Navigator.pop(context);
                _fetchReport();
              },
            ),
            
            const Divider(),
            
            // زر التقرير الشهري
            ListTile(
              leading: const Icon(Icons.calendar_view_month, color: Color(0xFF2A7A94)),
              title: const Text('تقرير شهري'),
              subtitle: Text(_getDateRangeText('month')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  reportType = 'month';
                });
                Navigator.pop(context);
                _fetchReport();
              },
            ),
            
            const Divider(),
            
            // زر الفترة المحددة
            ListTile(
              leading: const Icon(Icons.date_range, color: Color(0xFF2A7A94)),
              title: const Text('فترة محددة'),
              subtitle: Text(_getDateRangeText('custom')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showCustomDateRangePicker();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showCustomDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('اختر الفترة المحددة', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // تاريخ البداية
              Card(
                child: ListTile(
                  leading: const Icon(Icons.start, color: Colors.green),
                  title: const Text('تاريخ البداية'),
                  subtitle: Text(customStartDate != null 
                      ? DateFormat('yyyy-MM-dd').format(customStartDate!)
                      : 'اختر التاريخ'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: customStartDate ?? DateTime.now(),
                      firstDate: DateTime(2023, 1, 1),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        customStartDate = picked;
                        if (customEndDate != null && customEndDate!.isBefore(customStartDate!)) {
                          customEndDate = customStartDate;
                        }
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 10),
              
              // تاريخ النهاية
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: const Text('تاريخ النهاية'),
                  subtitle: Text(customEndDate != null 
                      ? DateFormat('yyyy-MM-dd').format(customEndDate!)
                      : 'اختر التاريخ'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: customEndDate ?? (customStartDate ?? DateTime.now()),
                      firstDate: customStartDate ?? DateTime(2023, 1, 1),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        customEndDate = picked;
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 15),
              
              // عرض الفترة المختارة
              if (customStartDate != null && customEndDate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A7A94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(customStartDate!),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 16),
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd').format(customEndDate!),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: customStartDate != null && customEndDate != null
                  ? () {
                      setState(() {
                        reportType = 'custom';
                      });
                      Navigator.pop(context);
                      _fetchReport();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A7A94),
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText(String type) {
    final dateRange = _calculateDateRange();
    final startDate = dateRange['startDate']!;
    final endDate = dateRange['endDate']!;
    
    if (type == 'day') {
      return 'يوم $startDate';
    } else if (type == 'week') {
      return 'من $startDate إلى $endDate';
    } else if (type == 'month') {
      final monthName = DateFormat('MMMM yyyy', 'ar').format(selectedDate);
      return 'شهر $monthName';
    } else if (type == 'custom') {
      if (customStartDate != null && customEndDate != null) {
        return 'من ${DateFormat('yyyy-MM-dd').format(customStartDate!)} إلى ${DateFormat('yyyy-MM-dd').format(customEndDate!)}';
      } else {
        return 'اختر الفترة';
      }
    }
    
    return '';
  }

  String _getReportTitle() {
    final dateRange = _calculateDateRange();
    final startDate = dateRange['startDate']!;
    final endDate = dateRange['endDate']!;
    
    switch (reportType) {
      case 'day':
        return 'تقرير يومي - $startDate';
      case 'week':
        return 'تقرير أسبوعي - من $startDate إلى $endDate';
      case 'month':
        final monthName = DateFormat('MMMM yyyy', 'ar').format(selectedDate);
        return 'تقرير شهري - $monthName';
      case 'custom':
        return 'تقرير فترة محددة - من $startDate إلى $endDate';
      default:
        return 'تقرير الأشعة';
    }
  }

  Widget _buildDateSelector() {
    if (reportType == 'custom') {
      return Row(
        children: [
          // زر تاريخ البداية
          ElevatedButton.icon(
            onPressed: () => _pickCustomDate(isStart: true),
            icon: const Icon(Icons.start),
            label: Text(customStartDate != null 
                ? DateFormat('yyyy-MM-dd').format(customStartDate!)
                : 'بداية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // زر تاريخ النهاية
          ElevatedButton.icon(
            onPressed: () => _pickCustomDate(isStart: false),
            icon: const Icon(Icons.flag),
            label: Text(customEndDate != null 
                ? DateFormat('yyyy-MM-dd').format(customEndDate!)
                : 'نهاية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.date_range),
        label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4AB8D8),
          foregroundColor: Colors.white,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context).currentLocale.languageCode;
    const primaryColor = Color(0xFF2A7A94);
    const accentColor = Color(0xFF4AB8D8);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      drawer: RadiologySidebar(
        primaryColor: primaryColor,
        accentColor: accentColor,
        userName: userName,
        onHome: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/radiology-dashboard');
        },
        onWaitingList: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const XrayRequestListPage()));
        },
        onReports: () => Navigator.pop(context),
        onClose: () => Navigator.pop(context),
        collapsed: false,
        lang: lang,
        localizedStrings: const <String, Map<String, String>>{},
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('تقرير الأشعة'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FA),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الفلتر
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان التقرير
                      Text(
                        _getReportTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A7A94),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // أزرار التحكم
                      Row(
                        children: [
                          // زر اختيار التاريخ (يتغير حسب نوع التقرير)
                          _buildDateSelector(),
                          const SizedBox(width: 12),
                          
                          // زر الفلتر
                          ElevatedButton.icon(
                            onPressed: _showFilterDialog,
                            icon: const Icon(Icons.filter_list),
                            label: const Text('تغيير نوع التقرير'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 18),
              
              // حالة التحميل
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل البيانات...'),
                      ],
                    ),
                  ),
                ),
              
              // رسالة الخطأ
              if (!isLoading && errorMsg != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          errorMsg!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // البيانات
              if (!isLoading && reportData != null && reportData!.isNotEmpty)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: _buildReportTable(reportData!, primaryColor, accentColor),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTable(Map<dynamic, dynamic> data, Color primaryColor, Color accentColor) {
    bool hasYear = false;
    for (final entry in data.entries) {
      if (entry.value is Map) {
        final clinicsMap = entry.value as Map<dynamic, dynamic>;
        for (final clinicEntry in clinicsMap.entries) {
          if (clinicEntry.value is Map && (clinicEntry.value as Map).keys.any((k) => k.toString().startsWith('year_'))) {
            hasYear = true;
            break;
          }
        }
      }
      if (hasYear) break;
    }

    if (hasYear) {
      return DataTable(
        headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A7A94)),
        dataRowColor: MaterialStateProperty.all(Colors.white),
        columns: const [
          DataColumn(label: Text('نوع الصورة')),
          DataColumn(label: Text('العيادة')),
          DataColumn(label: Text('سنة رابعة')),
          DataColumn(label: Text('سنة خامسة')),
        ],
        rows: [
          for (final entry in data.entries)
            if (entry.value is Map)
              for (final clinicEntry in (entry.value as Map<dynamic, dynamic>).entries)
                if (clinicEntry.value is Map)
                  DataRow(cells: [
                    DataCell(Text(entry.key.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    DataCell(Text(clinicEntry.key.toString())),
                    DataCell(Text((clinicEntry.value['year_4'] ?? 0).toString(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                    DataCell(Text((clinicEntry.value['year_5'] ?? 0).toString(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  ])
                else
                  DataRow(cells: [
                    DataCell(Text(entry.key.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    DataCell(Text(clinicEntry.key.toString())),
                    DataCell(Text(clinicEntry.value.toString(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                    const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                  ]),
        ],
      );
    } else {
      return DataTable(
        headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A7A94)),
        dataRowColor: MaterialStateProperty.all(Colors.white),
        columns: const [
          DataColumn(label: Text('نوع الصورة')),
          DataColumn(label: Text('العيادة / عدد الطلبات')),
        ],
        rows: data.entries.map<DataRow>((entry) {
          final xrayType = entry.key.toString();
          final clinicsMap = entry.value as Map<dynamic, dynamic>?;
          final List<Widget> clinicsWidgets = clinicsMap != null
              ? clinicsMap.entries.map<Widget>((e) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Text('${e.key}: ${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )
                ).toList()
              : [];
          return DataRow(cells: [
            DataCell(Text(xrayType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            DataCell(
              clinicsWidgets.isNotEmpty
                  ? Wrap(spacing: 4, runSpacing: 2, children: clinicsWidgets)
                  : const Text('-', style: TextStyle(color: Colors.grey)),
            ),
          ]);
        }).toList(),
      );
    }
  }
}
