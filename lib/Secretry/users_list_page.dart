// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/secretary_provider.dart';
import '../Secretry/secretary_sidebar.dart';
import 'package:dcs/config/api_config.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _currentUserRole;

  final Map<String, Map<String, String>> _translations = {
    'users_list': {'ar': 'قائمة المستخدمين', 'en': 'Users List'},
    'edit_user': {'ar': 'تعديل المستخدم', 'en': 'Edit User'},
    'save': {'ar': 'حفظ', 'en': 'Save'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'first_name': {'ar': 'الاسم الأول', 'en': 'First Name'},
    'father_name': {'ar': 'اسم الأب', 'en': 'Father Name'},
    'grandfather_name': {'ar': 'اسم الجد', 'en': 'Grandfather Name'},
    'family_name': {'ar': 'اسم العائلة', 'en': 'Family Name'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
    'phone_number': {'ar': 'رقم الهاتف', 'en': 'Phone Number'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'username': {'ar': 'اسم المستخدم', 'en': 'Username'},
    'address': {'ar': 'مكان السكن', 'en': 'Address'},
    'loading': {'ar': 'جاري التحميل...', 'en': 'Loading...'},
    'error_loading': {'ar': 'خطأ في تحميل البيانات', 'en': 'Error loading data'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'no_users': {'ar': 'لا يوجد مستخدمين', 'en': 'No users found'},
  };

  @override
  void initState() {
    super.initState();
    _loadSecretaryDataToProvider();
    _loadUsers();
  }

  Future<void> _loadSecretaryDataToProvider() async {
    Provider.of<SecretaryProvider>(context, listen: false);
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> users = [];
        for (final user in data) {
          if (user is Map<String, dynamic>) {
            users.add({
              'uid': user['id']?.toString() ?? '',
              ...user,
            });
          }
        }
        setState(() {
          _users = users;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final controllers = {
      'firstName': TextEditingController(text: user['firstName']?.toString() ?? ''),
      'fatherName': TextEditingController(text: user['fatherName']?.toString() ?? ''),
      'grandfatherName': TextEditingController(text: user['grandfatherName']?.toString() ?? ''),
      'familyName': TextEditingController(text: user['familyName']?.toString() ?? ''),
      'birthDate': TextEditingController(text: user['birthDate']?.toString() ?? ''),
      'phoneNumber': TextEditingController(text: user['phoneNumber']?.toString() ?? ''),
      'idNumber': TextEditingController(text: user['idNumber']?.toString() ?? ''),
      'email': TextEditingController(text: user['email']?.toString() ?? ''),
      'username': TextEditingController(text: user['username']?.toString() ?? ''),
      'address': TextEditingController(text: user['address']?.toString() ?? ''),
    };

    String gender = user['gender']?.toString() ?? 'male';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_translate(context, 'edit_user')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(controllers['firstName']!, _translate(context, 'first_name')),
                    _buildTextField(controllers['fatherName']!, _translate(context, 'father_name')),
                    _buildTextField(controllers['grandfatherName']!, _translate(context, 'grandfather_name')),
                    _buildTextField(controllers['familyName']!, _translate(context, 'family_name')),
                    _buildTextField(controllers['birthDate']!, _translate(context, 'birth_date')),
                    _buildTextField(controllers['phoneNumber']!, _translate(context, 'phone_number')),
                    _buildTextField(controllers['idNumber']!, _translate(context, 'id_number')),
                    _buildGenderDropdown(context, gender, (newValue) {
                      setState(() {
                        gender = newValue;
                      });
                    }),
                    _buildTextField(controllers['email']!, _translate(context, 'email')),

                    if (_currentUserRole == 'secretary')
                      _buildTextField(controllers['username']!, _translate(context, 'username')),
                    _buildTextField(controllers['address']!, _translate(context, 'address')),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(_translate(context, 'cancel')),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(_translate(context, 'save')),
                  onPressed: () async {
                    await _updateUser(
                      user['uid'],
                      controllers['firstName']!.text,
                      controllers['fatherName']!.text,
                      controllers['grandfatherName']!.text,
                      controllers['familyName']!.text,
                      controllers['birthDate']!.text,
                      controllers['phoneNumber']!.text,
                      controllers['idNumber']!.text,
                      gender,
                      controllers['email']!.text,
                      _currentUserRole == 'secretary'
                          ? controllers['username']!.text
                          : user['username']?.toString() ?? '',
                      controllers['address']!.text,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(BuildContext context, String currentValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        initialValue: currentValue,
        items: [
          DropdownMenuItem(
            value: 'male',
            child: Text(_translate(context, 'male')),
          ),
          DropdownMenuItem(
            value: 'female',
            child: Text(_translate(context, 'female')),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        decoration: InputDecoration(
          labelText: _translate(context, 'gender'),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _updateUser(
    String uid,
    String firstName,
    String fatherName,
    String grandfatherName,
    String familyName,
    String birthDate,
    String phoneNumber,
    String idNumber,
    String gender,
    String email,
    String username,
    String address,
  ) async {
    try {
      final updateData = {
        'firstName': firstName,
        'fatherName': fatherName,
        'grandfatherName': grandfatherName,
        'familyName': familyName,
        'birthDate': birthDate,
        'phoneNumber': phoneNumber,
        'idNumber': idNumber,
        'gender': gender,
        'email': email,
        'username': username,
        'address': address,
      };
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      if (response.statusCode == 200) {
        final index = _users.indexWhere((user) => user['uid'] == uid);
        if (index != -1) {
          setState(() {
            _users[index] = {
              'uid': uid,
              ...updateData,
              'password': _users[index]['password'] ?? '',
            };
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final secretaryProvider = Provider.of<SecretaryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate(context, 'users_list')),
      ),
      drawer: SecretarySidebar(
        primaryColor: Colors.blue, 
        accentColor: Colors.blueAccent, 
        userName: secretaryProvider.fullName,
        userImageUrl: secretaryProvider.imageBase64,
        onLogout: null,
        parentContext: context,
        collapsed: false,
        translate: (ctx, key) => _translate(context, key),
        pendingAccountsCount: 0,
        userRole: 'secretary',
      ),
      body: _isLoading
          ? Center(child: Text(_translate(context, 'loading')))
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_translate(context, 'error_loading')),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text(_translate(context, 'retry')),
            ),
          ],
        ),
      )
          : _users.isEmpty
          ? Center(child: Text(_translate(context, 'no_users')))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final fullName = [
            user['firstName'],
            user['fatherName'],
            user['grandfatherName'],
            user['familyName'],
          ].where((part) => part != null && part.toString().isNotEmpty).join(' ');

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(fullName.isNotEmpty ? fullName[0] : '?'),
              ),
              title: Text(fullName),
              subtitle: Text(user['email']?.toString() ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditUserDialog(user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}