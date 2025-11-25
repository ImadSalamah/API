import 'package:flutter/material.dart';

class PatientProvider extends ChangeNotifier {
  String _uid = '';
  String _fullName = '';
  String _imageBase64 = '';
  String _phone = '';
  String _email = '';
  String _idNumber = '';
  String _birthDate = '';
  String _gender = '';
  String _address = '';

  String get uid => _uid;
  String get fullName => _fullName;
  String get imageBase64 => _imageBase64;
  String get phone => _phone;
  String get email => _email;
  String get idNumber => _idNumber;
  String get birthDate => _birthDate;
  String get gender => _gender;
  String get address => _address;

  void setPatientData(Map<String, dynamic> data) {
    _uid = data['uid']?.toString() ?? '';
    final firstName = data['firstName']?.toString().trim() ?? '';
    final fatherName = data['fatherName']?.toString().trim() ?? '';
    final grandfatherName = data['grandfatherName']?.toString().trim() ?? '';
    final familyName = data['familyName']?.toString().trim() ?? '';
    _fullName = [firstName, fatherName, grandfatherName, familyName].where((e) => e.isNotEmpty).join(' ');
    final imageData = data['image']?.toString() ?? '';
    if (imageData.isNotEmpty) {
      if (imageData.startsWith('data:image')) {
        final commaIdx = imageData.indexOf(',');
        if (commaIdx != -1) {
          _imageBase64 = imageData.substring(commaIdx + 1);
        } else {
          _imageBase64 = imageData;
        }
      } else {
        _imageBase64 = imageData;
      }
    } else {
      _imageBase64 = '';
    }
    _phone = data['phone']?.toString() ?? '';
    _email = data['email']?.toString() ?? '';
    _idNumber = data['idNumber']?.toString() ?? '';
    _birthDate = data['birthDate']?.toString() ?? '';
    _gender = data['gender']?.toString() ?? '';
    _address = data['address']?.toString() ?? '';
    notifyListeners();
  }

  void clear() {
    _uid = '';
    _fullName = '';
    _imageBase64 = '';
    _phone = '';
    _email = '';
    _idNumber = '';
    _birthDate = '';
    _gender = '';
    _address = '';
    notifyListeners();
  }
}
