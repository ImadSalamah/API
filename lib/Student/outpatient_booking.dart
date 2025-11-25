import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dcs/config/api_config.dart';


class OutpatientBooking {
  final List<Map<String, String>> allPatients;
  final List<Map<String, String>> allPendingPatients;

  OutpatientBooking({
    required this.allPatients,
    required this.allPendingPatients,
  });

  Future<Map<String, dynamic>?> addOutpatientAppointment({
    required BuildContext context,
    required DateTime? selectedDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required String selectedPatientUid,
    required String selectedPatientName,
    required String? selectedOutpatientClinic,
    required TextEditingController patientController,
    required String studentId,
    required String studentEmail,
    required String universityId,
  }) async {
    if (selectedDate != null && startTime != null && endTime != null && selectedPatientUid.isNotEmpty && selectedOutpatientClinic != null && selectedOutpatientClinic.isNotEmpty) {
      // جلب بيانات المريض المختار
      String patientIdNumber = '';
      if (selectedPatientUid.isNotEmpty) {
        final patient = allPatients.firstWhere(
          (p) => p['uid'] == selectedPatientUid,
          orElse: () => {},
        );
        if (patient.isNotEmpty) {
          patientIdNumber = patient['idNumber'] ?? '';
        } else {
          // تحقق من pending
          final pendingPatient = allPendingPatients.firstWhere(
            (p) => p['uid'] == selectedPatientUid,
            orElse: () => {},
          );
          if (pendingPatient.isNotEmpty) {
            patientIdNumber = pendingPatient['idNumber'] ?? '';
          }
        }
      }
      final appointment = {
        'date': selectedDate.toIso8601String(),
        'start': startTime.format(context),
        'end': endTime.format(context),
        'studentId': studentId,
        'studentEmail': studentEmail,
        'patientUid': selectedPatientUid,
        'patientName': selectedPatientName,
        'patientIdNumber': patientIdNumber,
        'studentUniversityId': universityId,
        'clinic': selectedOutpatientClinic,
      };
      final url = Uri.parse('${ApiConfig.baseUrl}/outpatientAppointments');
      final response = await http.post(url, body: json.encode(appointment), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200 || response.statusCode == 201) {
        patientController.clear();
        return appointment;
      }
      return null;
    }
    return null;
  }
}
