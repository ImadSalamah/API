// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../services/oracle_storage.dart';
import '../providers/language_provider.dart';
import 'package:dcs/config/api_config.dart';

class PrimaryExamBookingPage extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final String patientIdNumber;
  const PrimaryExamBookingPage({
    super.key,
    required this.patientUid,
    required this.patientName,
    required this.patientIdNumber,
  });

  @override
  State<PrimaryExamBookingPage> createState() => _PrimaryExamBookingPageState();
}

class _PrimaryExamBookingPageState extends State<PrimaryExamBookingPage> {
  DateTime? selectedDate;
  bool isLoading = false;
  bool declarationUploaded = false;
  String? declarationImageUrl;
  dynamic declarationImage;
  final ImagePicker _picker = ImagePicker();

  // نصوص الترجمة
  Map<String, Map<String, String>> translations = {
    'ar': {
      'appBarTitle': 'حجز موعد للفحص الأولي',
      'patientInfo': 'معلومات المريض',
      'declarationSection': '1. رفع صورة الإقرار',
      'uploadDeclaration': 'رفع الإقرار',
      'changeDeclaration': 'تغيير الإقرار',
      'declarationUploaded': 'تم رفع الإقرار بنجاح',
      'dateSection': '2. اختيار تاريخ الحجز',
      'selectDate': 'اختر تاريخ الحجز',
      'dateSelected': 'تم اختيار التاريخ',
      'confirmBooking': 'تأكيد الحجز',
      'bookingInProgress': 'جاري الحجز...',
      'bookingSuccess': 'تم الحجز بنجاح',
      'successDialogTitle': 'تم الحجز بنجاح',
      'patientLabel': 'المريض:',
      'dateLabel': 'التاريخ:',
      'okButton': 'موافق',
      'noImageSelected': 'لم يتم اختيار صورة',
      'uploadSuccess': 'تم رفع الإقرار بنجاح',
      'uploadFailed': 'فشل رفع الإقرار',
      'uploadError': 'حدث خطأ أثناء رفع الإقرار:',
      'missingFields': 'يرجى رفع الإقرار وتحديد التاريخ',
      'invalidStudentYear': 'لا يمكن الحجز إلا لطلاب سنة رابعة أو خامسة',
      'settingsFailed': 'فشل في جلب إعدادات الحجز',
      'appointmentsFailed': 'فشل في جلب عدد المواعيد',
      'dayLimitReached': 'عدد الحالات المسموح بها لطلاب السنة {year} في هذا اليوم هو {limit} فقط. يرجى اختيار يوم آخر للحجز.',
      'fourthYear': 'رابعة',
      'fifthYear': 'خامسة',
      'declarationUpdateFailed': 'فشل تحديث الإقرار',
      'studentIdError': 'تعذر تحديد هوية الطالب. يرجى تسجيل الدخول مرة أخرى.',
      'bookingFailed': 'فشل حجز الموعد',
      'bookingError': 'حدث خطأ أثناء حجز الموعد:',
    },
    'en': {
      'appBarTitle': 'Primary Exam Booking',
      'patientInfo': 'Patient Information',
      'declarationSection': '1. Upload Declaration Form',
      'uploadDeclaration': 'Upload Declaration',
      'changeDeclaration': 'Change Declaration',
      'declarationUploaded': 'Declaration uploaded successfully',
      'dateSection': '2. Select Booking Date',
      'selectDate': 'Select Booking Date',
      'dateSelected': 'Date selected',
      'confirmBooking': 'Confirm Booking',
      'bookingInProgress': 'Booking in progress...',
      'bookingSuccess': 'Booking completed successfully',
      'successDialogTitle': 'Booking Successful',
      'patientLabel': 'Patient:',
      'dateLabel': 'Date:',
      'okButton': 'OK',
      'noImageSelected': 'No image selected',
      'uploadSuccess': 'Declaration uploaded successfully',
      'uploadFailed': 'Failed to upload declaration',
      'uploadError': 'Error occurred while uploading declaration:',
      'missingFields': 'Please upload declaration and select date',
      'invalidStudentYear': 'Booking is only allowed for 4th or 5th year students',
      'settingsFailed': 'Failed to fetch booking settings',
      'appointmentsFailed': 'Failed to fetch appointments count',
      'dayLimitReached': 'The maximum number of cases allowed for {year} year students on this day is {limit} only. Please choose another day for booking.',
      'fourthYear': 'fourth',
      'fifthYear': 'fifth',
      'declarationUpdateFailed': 'Failed to update declaration',
      'studentIdError': 'Unable to identify student. Please log in again.',
      'bookingFailed': 'Failed to book appointment',
      'bookingError': 'Error occurred while booking appointment:',
    },
  };

  String _getText(String key, String language) {
    return translations[language]?[key] ?? key;
  }

  String _getLanguage({bool listen = false}) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: listen);
    return languageProvider.isEnglish ? 'en' : 'ar';
  }

  String _getTranslatedText(String key, {bool listen = false}) {
    final language = _getLanguage(listen: listen);
    return _getText(key, language);
  }

  Future<void> _pickDate() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: languageProvider.isEnglish ? const Locale('en') : const Locale('ar'),
    );
    if (picked != null) {
      setState(() { selectedDate = picked; });
    }
  }

  Future<String?> _uploadDeclarationToOracle(dynamic image) async {
    final fileName =
        'declaration-${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb && image is Uint8List) {
      return uploadImageToOracle(image, fileName: fileName);
    } else if (image is File) {
      return uploadImageToOracle(image, fileName: fileName);
    } else {
      debugPrint('Unsupported image type for Oracle upload');
      return null;
    }
  }

  Future<void> _uploadDeclaration() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('noImageSelected'))),
        );
        return;
      }

      String? imageUrl;
      if (kIsWeb) {
        final imageBytes = await image.readAsBytes();
        imageUrl = await _uploadDeclarationToOracle(imageBytes);
      } else {
        imageUrl = await _uploadDeclarationToOracle(File(image.path));
      }

      if (imageUrl != null) {
        final imageBytes = kIsWeb ? await image.readAsBytes() : File(image.path);
        setState(() {
          declarationImage = imageBytes;
          declarationImageUrl = imageUrl;
          declarationUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('uploadSuccess'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('uploadFailed'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getTranslatedText('uploadError')} $e')),
      );
    }
  }

  Future<void> _bookAppointment() async {
    if (!declarationUploaded || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTranslatedText('missingFields'))),
      );
      return;
    }

    setState(() { isLoading = true; });

    try {
      int studentYear = 4;
      int maxPerDay = 2;

      if (studentYear != 4 && studentYear != 5) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('invalidStudentYear'))),
        );
        return;
      }

      // ✅ جلب الـ STUDENT_UNIVERSITY_ID الحقيقي من قاعدة البيانات
      final String? studentId = Provider.of<LanguageProvider>(context, listen: false).currentUserId;
      String? universityId;

      if (studentId != null && studentId.isNotEmpty) {
        try {
          final studentInfoUrl = Uri.parse('${ApiConfig.baseUrl}/students/$studentId');
          debugPrint('🔍 جلب الرقم الجامعي للطالب: $studentId');
          
          final studentInfoResponse = await http.get(studentInfoUrl);
          
          if (studentInfoResponse.statusCode == 200) {
            final studentData = json.decode(studentInfoResponse.body);
            universityId = studentData['STUDENT_UNIVERSITY_ID'] ?? studentData['student_university_id'];
            debugPrint('✅ تم جلب الرقم الجامعي: $universityId');
          } else {
            debugPrint('❌ فشل جلب الرقم الجامعي: ${studentInfoResponse.statusCode}');
            debugPrint('❌ تفاصيل الخطأ: ${studentInfoResponse.body}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب الرقم الجامعي: $e');
        }
      }

      // استخدام القيمة الافتراضية إذا فشل الجلب
      debugPrint('📝 الرقم الجامعي المستخدم: $universityId');

      // Fetch booking settings
      final bookingSettingsUrl = Uri.parse('${ApiConfig.baseUrl}/bookingSettings');
      final bookingSettingsResponse = await http.get(bookingSettingsUrl);
      if (bookingSettingsResponse.statusCode != 200) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('settingsFailed'))),
        );
        return;
      }

      final bookingSettings = json.decode(bookingSettingsResponse.body);
      final int fourthYearLimit = bookingSettings['fourthYearLimit'] ?? 0;
      final int fifthYearLimit = bookingSettings['fifthYearLimit'] ?? 0;

      // Check the student's year
      studentYear = 4;
      maxPerDay = studentYear == 4 ? fourthYearLimit : fifthYearLimit;

      // Fetch the number of appointments for the selected day
      final appointmentsUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/count?date=${selectedDate!.toIso8601String()}');
      final appointmentsResponse = await http.get(appointmentsUrl);
      if (appointmentsResponse.statusCode != 200) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('appointmentsFailed'))),
        );
        return;
      }

      final appointmentsData = json.decode(appointmentsResponse.body);
      final int currentAppointments = appointmentsData['count'] ?? 0;

      if (currentAppointments >= maxPerDay) {
        setState(() { isLoading = false; });
        String yearText = studentYear == 4 ? _getTranslatedText('fourthYear') : _getTranslatedText('fifthYear');
        String message = _getTranslatedText('dayLimitReached')
            .replaceAll('{year}', yearText)
            .replaceAll('{limit}', maxPerDay.toString());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Update IQRAR in PENDINGUSERS
      final updateUrl = Uri.parse('${ApiConfig.baseUrl}/pendingUsers/${widget.patientUid}');
      final updateIqrarData = {
        'IQRAR': declarationImageUrl,
      };

      debugPrint('📤 إرسال طلب تحديث الإقرار إلى: $updateUrl');
      debugPrint('📄 بيانات التحديث: $updateIqrarData');

      final updateResponse = await http.put(
        updateUrl, 
        body: json.encode(updateIqrarData), 
        headers: {'Content-Type': 'application/json'}
      );

      debugPrint('📥 استجابة تحديث الإقرار: ${updateResponse.statusCode}');
      debugPrint('📥 تفاصيل الاستجابة: ${updateResponse.body}');

      if (updateResponse.statusCode != 200) {
        throw Exception(_getTranslatedText('declarationUpdateFailed'));
      }

      if (studentId == null || studentId.isEmpty) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('studentIdError'))),
        );
        return;
      }

      // ✅ Create appointment مع البيانات المحدثة (بدون الحقول المحذوفة)
      final appointment = {
        'appointment_date': selectedDate!.toIso8601String(),
        'start_time': '8:00 AM', 
        'end_time': '4:00 PM',   
        'student_id': studentId,
        'patient_name': widget.patientName,
        'patient_id_number': widget.patientIdNumber,
        'student_university_id': universityId, 
        'status': 'pending',
      };
      
      final apptUrl = Uri.parse('${ApiConfig.baseUrl}/appointments');
      debugPrint('📤 إرسال طلب حجز الموعد إلى: $apptUrl');
      debugPrint('📄 بيانات الموعد: $appointment');

      final apptResponse = await http.post(
        apptUrl, 
        body: json.encode(appointment), 
        headers: {'Content-Type': 'application/json'}
      );

      debugPrint('📥 استجابة حجز الموعد: ${apptResponse.statusCode}');
      debugPrint('📥 تفاصيل الاستجابة: ${apptResponse.body}');

      if (apptResponse.statusCode != 201) {
        throw Exception(_getTranslatedText('bookingFailed'));
      }

      setState(() { isLoading = false; });
      if (!mounted) return;
      
      // Show success dialog
      _showSuccessDialog();
      
    } catch (e) {
      setState(() { isLoading = false; });
      debugPrint('❌ خطأ أثناء حجز الموعد: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getTranslatedText('bookingError')} $e')),
      );
    }
  }

  void _showSuccessDialog() {
    final isArabic = _getLanguage(listen: false) == 'ar';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isArabic) Icon(Icons.check_circle, color: Colors.green, size: 28),
              if (!isArabic) SizedBox(width: 10),
              Text(_getTranslatedText('successDialogTitle'), 
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              if (isArabic) SizedBox(width: 10),
              if (isArabic) Icon(Icons.check_circle, color: Colors.green, size: 28),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(_getTranslatedText('patientLabel')),
              SizedBox(height: 8),
              Text(widget.patientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 5),
              Text('${_getTranslatedText('dateLabel')} ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'),
              SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(_getTranslatedText('okButton'), style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = _getLanguage(listen: true);
    final isArabic = currentLanguage == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTranslatedText('appBarTitle')),
        backgroundColor: const Color(0xFF2A7A94),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Info Section
                    Row(
                      children: [
                        if (!isArabic) const Icon(Icons.person, color: Color(0xFF2A7A94)),
                        if (!isArabic) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        if (isArabic) const SizedBox(width: 8),
                        if (isArabic) const Icon(Icons.person, color: Color(0xFF2A7A94)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!isArabic) const Icon(Icons.credit_card, color: Colors.grey),
                        if (!isArabic) const SizedBox(width: 8),
                        Text(widget.patientIdNumber, style: const TextStyle(fontSize: 16)),
                        if (isArabic) const SizedBox(width: 8),
                        if (isArabic) const Icon(Icons.credit_card, color: Colors.grey),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1.2),
                    
                    // Declaration Section
                    Text(
                      _getTranslatedText('declarationSection'), 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue[900], 
                        fontSize: 16
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: Text(
                        declarationUploaded ? _getTranslatedText('changeDeclaration') : _getTranslatedText('uploadDeclaration'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A7A94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _uploadDeclaration,
                    ),
                    if (declarationImage != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.memory(
                                    declarationImage as Uint8List, 
                                    width: 180, 
                                    height: 180, 
                                    fit: BoxFit.cover
                                  )
                                : Image.file(
                                    declarationImage as File, 
                                    width: 180, 
                                    height: 180, 
                                    fit: BoxFit.cover
                                  ),
                          ),
                        ),
                      ),
                    ],
                    if (declarationUploaded) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 5),
                          Text(
                            _getTranslatedText('declarationUploaded'),
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Date Selection Section
                    Text(
                      _getTranslatedText('dateSection'), 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue[900], 
                        fontSize: 16
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      label: Text(
                        selectedDate == null ? _getTranslatedText('selectDate') : '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedDate == null ? Color(0xFF2A7A94) : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickDate,
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, color: Colors.green, size: 18),
                          SizedBox(width: 5),
                          Text(
                            _getTranslatedText('dateSelected'),
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Book Button
                    ElevatedButton.icon(
                      icon: isLoading 
                          ? const SizedBox(
                              height: 22, 
                              width: 22, 
                              child: CircularProgressIndicator(
                                color: Colors.white, 
                                strokeWidth: 2.5
                              ),
                            )
                          : const Icon(Icons.check_circle, color: Colors.white),
                      onPressed: (declarationUploaded && selectedDate != null && !isLoading) 
                          ? _bookAppointment 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (declarationUploaded && selectedDate != null) 
                            ? const Color(0xFF2A7A94) 
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: isLoading
                          ? Text(_getTranslatedText('bookingInProgress'), style: TextStyle(color: Colors.white))
                          : Text(_getTranslatedText('confirmBooking'), style: TextStyle(color: Colors.white)),
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
}
