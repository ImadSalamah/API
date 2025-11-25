// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../loginpage.dart';
import '../Secretry/secretary_sidebar.dart';
import '../../providers/secretary_provider.dart';
import '../../providers/language_provider.dart';
import 'package:dcs/config/api_config.dart';
import 'package:dcs/services/oracle_storage.dart';
import '../utils/friendly_error.dart';

class AccountApprovalPage extends StatefulWidget {
  final String? initialUserId;
  const AccountApprovalPage({super.key, this.initialUserId});

  @override
  AccountApprovalPageState createState() => AccountApprovalPageState();
}

class AccountApprovalPageState extends State<AccountApprovalPage> {
  // نافذة تعديل بيانات المستخدم
  Future<void> sendEmailToUser({
    required String email,
    required String fullName,
    required String status,
    String? reason,
  }) async {
    final url = Uri.parse('http://127.0.0.1:5000/send-email');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'status': status,
        if (reason != null) 'reason': reason,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _rejectedUsers = [];
  bool _isLoading = true;
  bool _isRejectedLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  final _rejectionReasonController = TextEditingController();

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  final Color editColor = const Color(0xFFFFA000); // لون كبسة التعديل

  List<String> _selectedFields = [];
  bool _rejectAll = true;

  final Map<String, Map<String, String>> _translations = const {
    'approval_title': {'ar': 'الموافقة على الحسابات', 'en': 'Account Approval'},
    'no_pending_users': {
      'ar': 'لا يوجد حسابات معلقة',
      'en': 'No pending accounts'
    },
    'user_info': {'ar': 'معلومات المستخدم', 'en': 'User Information'},
    'full_name': {'ar': 'الاسم الكامل', 'en': 'Full Name'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'phone': {'ar': 'رقم الهاتف', 'en': 'Phone Number'},
    'address': {'ar': 'مكان السكن', 'en': 'Address'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'approve': {'ar': 'موافقة', 'en': 'Approve'},
    'reject': {'ar': 'رفض', 'en': 'Reject'},
    'edit': {'ar': 'تعديل', 'en': 'Edit'},
    'approval_success': {
      'ar': 'تمت الموافقة بنجاح',
      'en': 'Approval successful'
    },
    'rejection_success': {'ar': 'تم الرفض بنجاح', 'en': 'Rejection successful'},
    'edit_success': {'ar': 'تم التعديل بنجاح', 'en': 'Edit successful'},
    'error': {'ar': 'حدث خطأ', 'en': 'Error occurred'},
    'profile_image': {'ar': 'الصورة الشخصية', 'en': 'Profile Image'},
    'id_image': {'ar': 'صورة الهوية', 'en': 'ID Image'},
    'iqrar_image': {'ar': 'صورة الإقرار', 'en': 'Iqrar Document'},
    'rejection_reason': {'ar': 'سبب الرفض', 'en': 'Rejection Reason'},
    'enter_rejection_reason': {
      'ar': 'الرجاء إدخال سبب الرفض',
      'en': 'Please enter rejection reason'
    },
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'submit_rejection': {'ar': 'إرسال الرفض', 'en': 'Submit Rejection'},
    'not_available': {'ar': 'غير متاح', 'en': 'N/A'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'reject_all': {'ar': 'رفض كامل', 'en': 'Reject All'},
    'select_fields': {
      'ar': 'تحديد بيانات للتعديل',
      'en': 'Select Fields to Edit'
    },
    'close': {'ar': 'إغلاق', 'en': 'Close'},
    'zoom_image': {'ar': 'تكبير الصورة', 'en': 'Zoom Image'},
    'no_image': {'ar': 'لا توجد صورة', 'en': 'No Image'},
    'edit_user': {'ar': 'تعديل بيانات المستخدم', 'en': 'Edit User Data'},
    'save_changes': {'ar': 'حفظ التغييرات', 'en': 'Save Changes'},
    'select_fields_to_edit': {
      'ar': 'اختر الحقول التي تريد تعديلها',
      'en': 'Select fields to edit'
    },
    'select_date': {'ar': 'اختر التاريخ', 'en': 'Select Date'},
    'select': {'ar': 'اختر', 'en': 'Select'},
    'connection_error': {
      'ar': 'تعذر الاتصال، يرجى المحاولة لاحقاً',
      'en': 'Unable to connect, please try again'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSecretaryData(); 
    _loadPendingUsers();
    _loadRejectedUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialUserId != null) {
        final user = _pendingUsers.firstWhere(
          (u) => u['USER_UID'] == widget.initialUserId,
          orElse: () => {},
        );
        if (user.isNotEmpty) {
          _showUserDetailsDialog(user);
        }
      }
    });
  }

  Future<void> _loadRejectedUsers() async {
    try {
      setState(() => _isRejectedLoading = true);
      final url = Uri.parse('${ApiConfig.baseUrl}/pendingUsers');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Pending Users Data (for Rejected): $data');
        final usersList = <Map<String, dynamic>>[];
        for (var user in data) {
          if (user is Map<String, dynamic> && user['STATUS'] == 'rejected') {
            usersList.add(user);
          }
        }
        if (mounted) {
          setState(() {
            _rejectedUsers = usersList;
            _isRejectedLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load rejected users');
      }
    } catch (e) {
      debugPrint('Error loading rejected users: $e');
      if (mounted) {
        setState(() => _isRejectedLoading = false);
        _showErrorSnack(e);
      }
    }
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  String _translate(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.isEnglish ? 'en' : 'ar';
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

  String _friendlyError(dynamic error) {
    return friendlyErrorMessage(
      defaultMessage: _translate('error'),
      connectionMessage: _translate('connection_error'),
      error: error,
    );
  }

  Uint8List? _decodeBase64Image(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final cleaned = value.contains(',')
          ? value.split(',').last
          : value;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  void _showErrorSnack(dynamic error) {
    if (!mounted) return;
    final raw = error?.toString() ?? '';
    final friendly = _friendlyError(error);
    // Show the raw error so the user can understand what went wrong.
    final message = raw.isNotEmpty && raw != friendly
        ? '$friendly\n$raw'
        : friendly;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatBirthDate(dynamic birthDate, bool isEnglish) {
    try {
      if (birthDate == null) return _translate('not_available');
      
      if (birthDate is String) {
        // إذا كان تاريخ ميلاد كنص
        final date = DateTime.tryParse(birthDate);
        if (date != null) {
          // استخدام التنسيق الإنجليزي دائماً
          return DateFormat('yyyy-MM-dd').format(date);
        }
      } else if (birthDate is int) {
        // إذا كان تاريخ ميلاد ك timestamp
        final date = DateTime.fromMillisecondsSinceEpoch(birthDate);
        // استخدام التنسيق الإنجليزي دائماً
        return DateFormat('yyyy-MM-dd').format(date);
      }
      
      return _translate('not_available');
    } catch (e) {
      return _translate('not_available');
    }
  }

  Future<void> _loadPendingUsers() async {
    try {
      setState(() => _isLoading = true);
      final url = Uri.parse('${ApiConfig.baseUrl}/pendingUsers');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Pending Users Data: $data');
        final usersList = <Map<String, dynamic>>[];
        for (var user in data) {
          if (user is Map<String, dynamic> && (user['STATUS'] == null || user['STATUS'] == 'pending')) {
            usersList.add(user);
          }
        }
        if (mounted) {
          setState(() {
            _pendingUsers = usersList;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load pending users');
      }
    } catch (e) {
      debugPrint('Error loading pending users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnack(e);
      }
    }
  }

  Future<void> _approveUser(Map<String, dynamic> userData) async {
    try {
      final userId = userData['USER_UID']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('Missing USER_UID');
      }
      
      // Send approve request to API
      final url = Uri.parse('${ApiConfig.baseUrl}/approveUser');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...userData,
          'STATUS': 'approved',
          'ISACTIVE': 1
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to approve user: ${response.body}');
      }
      
      try {
        await sendEmailToUser(
          email: userData['EMAIL'] ?? '',
          fullName: '${userData['FIRSTNAME'] ?? ''} ${userData['FAMILYNAME'] ?? ''}',
          status: 'approved',
        );
      } catch (e) {
        debugPrint('Email send error: ${e.toString()}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('approval_success'))),
        );
        _loadPendingUsers();
        _loadRejectedUsers();
      }
    } catch (e) {
      debugPrint('Error approving user: $e');
      if (mounted) {
        _showErrorSnack(e);
      }
    }
  }

  void _startRejectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedFields = [];
      _rejectAll = true;
      _rejectionReasonController.clear();
    });
    _showRejectDialog(user);
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final List<String> editableFields = [
      'FIRSTNAME',
      'FATHERNAME',
      'GRANDFATHERNAME',
      'FAMILYNAME',
      'IDNUMBER',
      'BIRTHDATE',
      'GENDER',
      'PHONE',
      'ADDRESS',
    ];
    final Map<String, TextEditingController> controllers = {};
    for (var field in editableFields) {
      if (field != 'BIRTHDATE' && field != 'GENDER') {
        controllers[field] = TextEditingController(text: user[field]?.toString() ?? '');
      }
    }

    DateTime? selectedDate;
    if (user['BIRTHDATE'] != null) {
      if (user['BIRTHDATE'] is String) {
        selectedDate = DateTime.tryParse(user['BIRTHDATE']);
      } else if (user['BIRTHDATE'] is int) {
        selectedDate = DateTime.fromMillisecondsSinceEpoch(user['BIRTHDATE']);
      }
    }

    String birthDateText = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate)
        : '';

    String? selectedGender;
    if (user['GENDER'] != null) {
      final gender = user['GENDER'].toString().toLowerCase();
      if (gender == 'male' || gender == 'ذكر') {
        selectedGender = 'Male';
      } else if (gender == 'female' || gender == 'أنثى') {
        selectedGender = 'Female';
      }
    }

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    Uint8List? profileImageBytes = _decodeBase64Image(user['IMAGE']?.toString());
    Uint8List? idImageBytes = _decodeBase64Image(user['IDIMAGE']?.toString());
    Uint8List? iqrarImageBytes = _decodeBase64Image(user['IQRAR']?.toString());

    String? profileImageUrl = profileImageBytes == null ? user['IMAGE']?.toString() : null;
    String? idImageUrl = idImageBytes == null ? user['IDIMAGE']?.toString() : null;
    String? iqrarImageUrl = iqrarImageBytes == null ? user['IQRAR']?.toString() : null;

    String requiredMessage(String label) {
      return languageProvider.isEnglish
          ? 'Please enter $label'
          : 'يرجى إدخال $label';
    }

    Future<void> pickImage(void Function(Uint8List?) assign) async {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        assign(bytes);
      }
    }

    Widget buildImagePicker({
      required String label,
      Uint8List? imageBytes,
      String? imageUrl,
      required VoidCallback onPick,
      VoidCallback? onView,
    }) {
      final hasImage = (imageBytes != null) || (imageUrl != null && imageUrl.isNotEmpty);
      return Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onPick,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasImage ? primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasImage
                      ? (imageBytes != null
                          ? Image.memory(imageBytes, fit: BoxFit.cover)
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildNoImageIcon(),
                            ))
                      : _buildNoImageIcon(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(languageProvider.isEnglish ? 'Change' : 'تغيير'),
                ),
                if (hasImage)
                  TextButton(
                    onPressed: onView,
                    child: Text(languageProvider.isEnglish ? 'View' : 'عرض'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildTextField(
      String field, {
      int maxLines = 1,
      TextInputType? keyboardType,
      int? maxLength,
      List<TextInputFormatter>? inputFormatters,
    }) {
      final label = _getFieldLabel(field, languageProvider.isEnglish);
      return SizedBox(
        width: 260,
        child: TextFormField(
          controller: controllers[field],
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return requiredMessage(label);
            final trimmed = val.trim();
            if (field == 'IDNUMBER') {
              if (!RegExp(r'^\d{9}$').hasMatch(trimmed)) {
                return languageProvider.isEnglish
                    ? 'ID number must be 9 digits'
                    : 'رقم الهوية يجب أن يتكون من 9 أرقام';
              }
            }
            if (field == 'PHONE') {
              if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
                return languageProvider.isEnglish
                    ? 'Phone number must be 10 digits'
                    : 'رقم الهاتف يجب أن يتكون من 10 أرقام';
              }
            }
            return null;
          },
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translate('edit_user'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    buildImagePicker(
                                      label: _translate('profile_image'),
                                      imageBytes: profileImageBytes,
                                      imageUrl: profileImageUrl,
                                      onPick: () async {
                                        await pickImage((bytes) {
                                          setState(() {
                                            profileImageBytes = bytes;
                                            profileImageUrl = null;
                                          });
                                        });
                                      },
                                      onView: () {
                                        final urlToShow = profileImageUrl;
                                        if (profileImageBytes != null) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child: Image.memory(profileImageBytes!),
                                            ),
                                          );
                                        } else if (urlToShow != null && urlToShow.isNotEmpty) {
                                          _showImageZoomDialog(urlToShow, _translate('profile_image'));
                                        }
                                      },
                                    ),
                                    buildImagePicker(
                                      label: _translate('id_image'),
                                      imageBytes: idImageBytes,
                                      imageUrl: idImageUrl,
                                      onPick: () async {
                                        await pickImage((bytes) {
                                          setState(() {
                                            idImageBytes = bytes;
                                            idImageUrl = null;
                                          });
                                        });
                                      },
                                      onView: () {
                                        if (idImageBytes != null) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child: Image.memory(idImageBytes!),
                                            ),
                                          );
                                        } else if (idImageUrl != null && idImageUrl!.isNotEmpty) {
                                          _showImageZoomDialog(idImageUrl!, _translate('id_image'));
                                        }
                                      },
                                    ),
                                    buildImagePicker(
                                      label: _translate('iqrar_image'),
                                      imageBytes: iqrarImageBytes,
                                      imageUrl: iqrarImageUrl,
                                      onPick: () async {
                                        await pickImage((bytes) {
                                          setState(() {
                                            iqrarImageBytes = bytes;
                                            iqrarImageUrl = null;
                                          });
                                        });
                                      },
                                      onView: () {
                                        if (iqrarImageBytes != null) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child: Image.memory(iqrarImageBytes!),
                                            ),
                                          );
                                        } else if (iqrarImageUrl != null && iqrarImageUrl!.isNotEmpty) {
                                          _showImageZoomDialog(iqrarImageUrl!, _translate('iqrar_image'));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    buildTextField('FIRSTNAME'),
                                    buildTextField('FATHERNAME'),
                                    buildTextField('GRANDFATHERNAME'),
                                    buildTextField('FAMILYNAME'),
                                    buildTextField(
                                      'IDNUMBER',
                                      keyboardType: TextInputType.number,
                                      maxLength: 9,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    ),
                                    FormField<DateTime>(
                                      validator: (_) => selectedDate == null
                                          ? (languageProvider.isEnglish
                                              ? 'Select birth date'
                                              : 'اختر تاريخ الميلاد')
                                          : null,
                                      builder: (field) {
                                        return SizedBox(
                                          width: 260,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getFieldLabel('BIRTHDATE', languageProvider.isEnglish),
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: () async {
                                                  final DateTime? picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: selectedDate ?? DateTime.now(),
                                                    firstDate: DateTime(1900),
                                                    lastDate: DateTime.now(),
                                                  );
                                                  if (picked != null) {
                                                    setState(() {
                                                      selectedDate = picked;
                                                      birthDateText = DateFormat('yyyy-MM-dd').format(picked);
                                                    });
                                                    field.didChange(picked);
                                                  }
                                                },
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    border: const OutlineInputBorder(),
                                                    isDense: true,
                                                    errorText: field.errorText,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        birthDateText.isEmpty
                                                            ? _translate('select_date')
                                                            : birthDateText,
                                                        style: TextStyle(
                                                          color: birthDateText.isEmpty
                                                              ? Colors.grey.shade500
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      const Icon(Icons.calendar_today, size: 18),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    FormField<String>(
                                      validator: (_) => selectedGender == null
                                          ? (languageProvider.isEnglish
                                              ? 'Select gender'
                                              : 'اختر الجنس')
                                          : null,
                                      builder: (field) {
                                        return SizedBox(
                                          width: 260,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getFieldLabel('GENDER', languageProvider.isEnglish),
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: RadioListTile<String>(
                                                      dense: true,
                                                      title: Text(languageProvider.isEnglish ? 'Male' : 'ذكر'),
                                                      value: 'Male',
                                                      groupValue: selectedGender,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          selectedGender = value;
                                                        });
                                                        field.didChange(value);
                                                      },
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: RadioListTile<String>(
                                                      dense: true,
                                                      title: Text(languageProvider.isEnglish ? 'Female' : 'أنثى'),
                                                      value: 'Female',
                                                      groupValue: selectedGender,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          selectedGender = value;
                                                        });
                                                        field.didChange(value);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (field.errorText != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 12),
                                                  child: Text(
                                                    field.errorText!,
                                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    buildTextField(
                                      'PHONE',
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    ),
                                    buildTextField('ADDRESS', maxLines: 3),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                              child: Text(_translate('cancel')),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: editColor),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final form = formKey.currentState;
                                      if (form == null) return;
                                      if (!form.validate()) return;

                                      setState(() => isSaving = true);
                                      try {
                                        final userId = user['USER_UID']?.toString() ?? '';
                                        Future<String?> uploadIfNeeded(Uint8List? bytes, String prefix) async {
                                          if (bytes == null) return null;
                                          final fileName = '$prefix-${userId.isEmpty ? DateTime.now().millisecondsSinceEpoch : userId}-${DateTime.now().millisecondsSinceEpoch}.jpg';
                                          return uploadImageToOracle(bytes, fileName: fileName);
                                        }

                                        final newProfileUrl = await uploadIfNeeded(profileImageBytes, 'profile');
                                        final newIdUrl = await uploadIfNeeded(idImageBytes, 'id');
                                        final newIqrarUrl = await uploadIfNeeded(iqrarImageBytes, 'iqrar');

                                        final updatedData = <String, dynamic>{
                                          'FIRSTNAME': controllers['FIRSTNAME']!.text.trim(),
                                          'FATHERNAME': controllers['FATHERNAME']!.text.trim(),
                                          'GRANDFATHERNAME': controllers['GRANDFATHERNAME']!.text.trim(),
                                          'FAMILYNAME': controllers['FAMILYNAME']!.text.trim(),
                                          'IDNUMBER': controllers['IDNUMBER']!.text.trim(),
                                          'PHONE': controllers['PHONE']!.text.trim(),
                                          'ADDRESS': controllers['ADDRESS']!.text.trim(),
                                          'BIRTHDATE': selectedDate?.toIso8601String(),
                                          'GENDER': selectedGender,
                                        };

                                        final imageToSend = newProfileUrl ?? profileImageUrl;
                                        final idToSend = newIdUrl ?? idImageUrl;
                                        final iqrarToSend = newIqrarUrl ?? iqrarImageUrl;

                                        if (imageToSend != null && imageToSend.isNotEmpty) {
                                          updatedData['IMAGE'] = imageToSend;
                                        }
                                        if (idToSend != null && idToSend.isNotEmpty) {
                                          updatedData['IDIMAGE'] = idToSend;
                                        }
                                        if (iqrarToSend != null && iqrarToSend.isNotEmpty) {
                                          updatedData['IQRAR'] = iqrarToSend;
                                        }

                                        final success = await _updateUserData(user, updatedData);
                                        if (success && mounted) Navigator.of(context).pop();
                                      } finally {
                                        if (mounted) setState(() => isSaving = false);
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(_translate('save_changes')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getFieldLabel(String field, bool isEnglish) {
    final labels = {
      'FIRSTNAME': isEnglish ? 'First Name' : 'الاسم الأول',
      'FATHERNAME': isEnglish ? 'Father Name' : 'اسم الأب',
      'GRANDFATHERNAME': isEnglish ? 'Grandfather Name' : 'اسم الجد',
      'FAMILYNAME': isEnglish ? 'Family Name' : 'اسم العائلة',
      'IDNUMBER': isEnglish ? 'ID Number' : 'رقم الهوية',
      'BIRTHDATE': isEnglish ? 'Birth Date' : 'تاريخ الميلاد',
      'GENDER': isEnglish ? 'Gender' : 'الجنس',
      'PHONE': isEnglish ? 'Phone Number' : 'رقم الهاتف',
      'ADDRESS': isEnglish ? 'Address' : 'مكان السكن',
    };
    return labels[field] ?? field;
  }

  Future<bool> _updateUserData(
    Map<String, dynamic> user, 
    Map<String, dynamic> updatedData
  ) async {
    try {
      final userId = user['USER_UID']?.toString() ?? '';
      if (userId.isEmpty) throw Exception('Missing USER_UID');

      // Send update request to API
      final url = Uri.parse('${ApiConfig.baseUrl}/updateUser');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'USER_UID': userId,
          ...updatedData,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.body}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('edit_success'))),
        );
        _loadPendingUsers();
        _loadRejectedUsers();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      if (mounted) {
        _showErrorSnack(e);
      }
      return false;
    }
  }

  void _showRejectDialog(Map<String, dynamic> user) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final List<String> editableFields = [
      'FIRSTNAME',
      'FATHERNAME',
      'GRANDFATHERNAME',
      'FAMILYNAME',
      'IDNUMBER',
      'BIRTHDATE',
      'GENDER',
      'PHONE',
      'ADDRESS',
      'EMAIL',
      'IMAGE',
      'IDIMAGE',
    ];
    final Map<String, String> fieldLabels = {
      'FIRSTNAME': languageProvider.isEnglish ? 'First Name' : 'الاسم الأول',
      'FATHERNAME': languageProvider.isEnglish ? 'Father Name' : 'اسم الأب',
      'GRANDFATHERNAME': languageProvider.isEnglish ? 'Grandfather Name' : 'اسم الجد',
      'FAMILYNAME': languageProvider.isEnglish ? 'Family Name' : 'اسم العائلة',
      'IDNUMBER': _translate('id_number'),
      'BIRTHDATE': _translate('birth_date'),
      'GENDER': _translate('gender'),
      'PHONE': _translate('phone'),
      'ADDRESS': _translate('address'),
      'EMAIL': _translate('email'),
      'IMAGE': _translate('profile_image'),
      'IDIMAGE': languageProvider.isEnglish ? 'ID Image' : 'صورة الهوية',
    };
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(languageProvider.isEnglish ? 'Reject Account' : 'رفض الحساب'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _rejectAll,
                          onChanged: (val) {
                            setState(() {
                              _rejectAll = true;
                              _selectedFields.clear();
                            });
                          },
                        ),
                        Text(languageProvider.isEnglish ? 'Reject All' : 'رفض كامل'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: false,
                          groupValue: _rejectAll,
                          onChanged: (val) {
                            setState(() {
                              _rejectAll = false;
                            });
                          },
                        ),
                        Text(languageProvider.isEnglish ? 'Select Fields to Edit' : 'تحديد بيانات للتعديل'),
                      ],
                    ),
                    if (!_rejectAll)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...editableFields.map((field) => CheckboxListTile(
                                  value: _selectedFields.contains(field),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedFields.add(field);
                                      } else {
                                        _selectedFields.remove(field);
                                      }
                                    });
                                  },
                                  title: Text(fieldLabels[field] ?? field),
                                )),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rejectionReasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: languageProvider.isEnglish ? 'Rejection Reason' : 'سبب الرفض',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(languageProvider.isEnglish ? 'Cancel' : 'إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final reason = _rejectionReasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageProvider.isEnglish ? 'Please enter a reason' : 'يرجى إدخال سبب')),
                      );
                      return;
                    }
                    if (!_rejectAll && _selectedFields.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageProvider.isEnglish ? 'Please select at least one field' : 'يرجى اختيار حقل واحد على الأقل')),
                      );
                      return;
                    }
                    if (user['USER_UID'] == null || user['USER_UID'].toString().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageProvider.isEnglish ? 'User ID is missing' : 'رقم المستخدم مفقود')),
                      );
                      return;
                    }
                    await _rejectUser(user, reason, fields: _rejectAll ? null : List<String>.from(_selectedFields));
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: Text(languageProvider.isEnglish ? 'Reject' : 'رفض'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rejectUser(Map<String, dynamic> user, String reason, {List<String>? fields}) async {
    try {
      final userId = user['USER_UID']?.toString() ?? '';
      if (userId.isEmpty) throw Exception('Missing USER_UID');
      
      final rejectedUserData = Map<String, dynamic>.from(user);
      rejectedUserData['REJECTIONREASON'] = reason;
      rejectedUserData['REJECTEDAT'] = DateTime.now().millisecondsSinceEpoch;
      rejectedUserData['STATUS'] = 'rejected';
      
      if (fields != null) {
        rejectedUserData['FIELDSTOEDIT'] = fields;
      } else {
        rejectedUserData.remove('FIELDSTOEDIT');
      }
      
      final url = Uri.parse('${ApiConfig.baseUrl}/rejectUser');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(rejectedUserData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to reject user: ${response.body}');
      }
      
      try {
        await sendEmailToUser(
          email: user['EMAIL'] ?? '',
          fullName: '${user['FIRSTNAME'] ?? ''} ${user['FAMILYNAME'] ?? ''}',
          status: 'rejected',
          reason: reason,
        );
      } catch (e) {
        debugPrint('Email send error: ${e.toString()}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('rejection_success'))),
        );
        _loadPendingUsers();
        _loadRejectedUsers();
      }
    } catch (e) {
      debugPrint('Error rejecting user: $e');
      if (mounted) {
        _showErrorSnack(e);
      }
    }
  }

  // دالة لعرض الصورة مكبرة
  void _showImageZoomDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {}, // منع الإغلاق عند الضغط على الصورة نفسها
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 50,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _translate('error'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildZoomableImage(String? imageUrl, String label) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: hasImage ? () {
            _showImageZoomDialog(imageUrl, label);
          } : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasImage ? primaryColor : Colors.grey[300]!,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (hasImage)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrl,
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildNoImageIcon();
                        },
                      ),
                    ),
                  )
                else
                  _buildNoImageIcon(),
                
                // مؤشر ان الصورة قابلة للتكبير
                if (hasImage)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _translate('no_image'),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoImageIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.image_not_supported,
          size: 30,
          color: Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          _translate('no_image'),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    // الصور على اليسار (صورة الهوية وصورة الإقرار)
    final imagesColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // صورة الهوية
        _buildZoomableImage(user['IDIMAGE'], _translate('id_image')),
        const SizedBox(height: 16),
        // صورة الإقرار
        _buildZoomableImage(user['IQRAR'], _translate('iqrar_image')),
      ],
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصور على اليسار
            imagesColumn,
            const SizedBox(width: 16),
            
            // المعلومات في المنتصف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم الكامل في أعمدة
                  _buildNameRow(user),
                  const SizedBox(height: 12),
                  
                  // المعلومات الأخرى
                  _buildUserInfoRow(
                    label: _translate('id_number'),
                    value: user['IDNUMBER']?.toString() ?? _translate('not_available'),
                  ),
                  _buildUserInfoRow(
                    label: _translate('birth_date'),
                    value: _formatBirthDate(user['BIRTHDATE'], languageProvider.isEnglish),
                  ),
                  _buildUserInfoRow(
                    label: _translate('address'),
                    value: user['ADDRESS'] ?? _translate('not_available'),
                  ),
                  _buildUserInfoRow(
                    label: _translate('phone'),
                    value: user['PHONE'] ?? _translate('not_available'),
                  ),
                  _buildUserInfoRow(
                    label: _translate('gender'),
                    value: _getGenderText(user['GENDER'], languageProvider.isEnglish),
                  ),
                ],
              ),
            ),
            
            // الأزرار على اليمين
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _approveUser(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_translate('approve')),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showEditUserDialog(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: editColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_translate('edit')),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _startRejectUser(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_translate('reject')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameRow(Map<String, dynamic> user) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('full_name'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildNameField(
                label: languageProvider.isEnglish ? 'First Name' : 'الاسم الأول',
                value: user['FIRSTNAME'] ?? '',
              ),
              _buildNameField(
                label: languageProvider.isEnglish ? 'Father Name' : 'اسم الأب',
                value: user['FATHERNAME'] ?? '',
              ),
              _buildNameField(
                label: languageProvider.isEnglish ? 'Grandfather Name' : 'اسم الجد',
                value: user['GRANDFATHERNAME'] ?? '',
              ),
              _buildNameField(
                label: languageProvider.isEnglish ? 'Family Name' : 'اسم العائلة',
                value: user['FAMILYNAME'] ?? '',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : _translate('not_available'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderText(dynamic gender, bool isEnglish) {
    if (gender == null) return _translate('not_available');
    final genderStr = gender.toString().toLowerCase();
    if (genderStr == 'male' || genderStr == 'ذكر') {
      return isEnglish ? 'Male' : 'ذكر';
    } else if (genderStr == 'female' || genderStr == 'أنثى') {
      return isEnglish ? 'Female' : 'أنثى';
    }
    return genderStr;
  }

  Future<void> _loadSecretaryData() async {
    // This should be replaced with your authentication logic or API call
    // For now, just skip loading secretary data
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_translate('user_info')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_translate('full_name')}: ${user['FIRSTNAME'] ?? _translate('not_available')} ${user['FAMILYNAME'] ?? ''}'),
                Text('${_translate('id_number')}: ${user['IDNUMBER'] ?? _translate('not_available')}'),
                Text('${_translate('birth_date')}: ${user['BIRTHDATE'] ?? _translate('not_available')}'),
                Text('${_translate('gender')}: ${user['GENDER'] ?? _translate('not_available')}'),
                Text('${_translate('phone')}: ${user['PHONE'] ?? _translate('not_available')}'),
                Text('${_translate('address')}: ${user['ADDRESS'] ?? _translate('not_available')}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_translate('close')),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    // Remove token or session if needed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secretaryProvider = Provider.of<SecretaryProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection:
          languageProvider.isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(_translate('approval_title')),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: accentColor,
              tabs: [
                Tab(text: languageProvider.isEnglish ? 'Pending Accounts' : 'الحسابات المعلقة'),
                Tab(text: languageProvider.isEnglish ? 'Rejected Accounts' : 'الحسابات المرفوضة'),
              ],
            ),
          ),
          drawer: SecretarySidebar(
            primaryColor: primaryColor,
            accentColor: accentColor,
            userName: secretaryProvider.fullName,
            userImageUrl: secretaryProvider.imageBase64,
            onLogout: _logout,
            parentContext: context,
            collapsed: false,
            translate: (ctx, key) => _translate(key),
            pendingAccountsCount: _pendingUsers.length,
            userRole: 'secretary',
          ),
          body: TabBarView(
            children: [
              _buildMainContent(),
              _buildRejectedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedContent() {
    if (_isRejectedLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rejectedUsers.isEmpty) {
      return Center(
        child: Text(
          Provider.of<LanguageProvider>(context).isEnglish
              ? 'No rejected accounts'
              : 'لا يوجد حسابات مرفوضة',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rejectedUsers.length,
      itemBuilder: (context, index) {
        final user = _rejectedUsers[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _translate('user_info'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            Provider.of<LanguageProvider>(context).isEnglish ? 'Rejected' : 'مرفوض',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // الصور في الصف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildZoomableImage(user['IDIMAGE'], _translate('id_image')),
                    _buildZoomableImage(user['IQRAR'], _translate('iqrar_image')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildUserInfoRow(label: _translate('full_name'), value: '${user['FIRSTNAME'] ?? ''} ${user['FATHERNAME'] ?? ''} ${user['GRANDFATHERNAME'] ?? ''} ${user['FAMILYNAME'] ?? ''}'),
                _buildUserInfoRow(label: _translate('id_number'), value: user['IDNUMBER']?.toString() ?? _translate('not_available')),
                _buildUserInfoRow(label: _translate('birth_date'), value: _formatBirthDate(user['BIRTHDATE'], Provider.of<LanguageProvider>(context).isEnglish)),
                _buildUserInfoRow(label: _translate('gender'), value: user['GENDER']?.toString() ?? _translate('not_available')),
                _buildUserInfoRow(label: _translate('phone'), value: user['PHONE']?.toString() ?? _translate('not_available')),
                _buildUserInfoRow(label: _translate('address'), value: user['ADDRESS']?.toString() ?? _translate('not_available')),
                const SizedBox(height: 12),
                if (user['REJECTIONREASON'] != null && user['REJECTIONREASON'].toString().isNotEmpty)
                  _buildUserInfoRow(label: _translate('rejection_reason'), value: user['REJECTIONREASON'].toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Text(
          _translate('no_pending_users'),
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_pendingUsers[index]);
      },
    );
  }

  String userImageSafe(String? imageData) {
    if (imageData == null || imageData.isEmpty) return '';
    try {
      const prefix = 'data:image/jpeg;base64,';
      return imageData.startsWith(prefix)
          ? imageData.substring(prefix.length)
          : imageData;
    } catch (e) {
      return '';
    }
  }

  Widget _buildUserInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class UserDetailsPage extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, Map<String, String>> translations;
  final bool isEnglish;

  const UserDetailsPage({
    super.key,
    required this.user,
    required this.translations,
    required this.isEnglish,
  });

  String _translate(String key) {
    final langCode = isEnglish ? 'en' : 'ar';
    if (translations.containsKey(key)) {
      final translationsForKey = translations[key]!;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${user['FIRSTNAME'] ?? ''} ${user['FAMILYNAME'] ?? ''}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_translate('full_name')}: ${user['FIRSTNAME'] ?? _translate('not_available')} ${user['FAMILYNAME'] ?? ''}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_translate('id_number')}: ${user['IDNUMBER'] ?? _translate('not_available')}'),
            Text('${_translate('birth_date')}: ${user['BIRTHDATE'] ?? _translate('not_available')}'),
            Text('${_translate('gender')}: ${user['GENDER'] ?? _translate('not_available')}'),
            Text('${_translate('phone')}: ${user['PHONE'] ?? _translate('not_available')}'),
            Text('${_translate('address')}: ${user['ADDRESS'] ?? _translate('not_available')}'),
          ],
        ),
      ),
    );
  }
}
