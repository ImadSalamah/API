// ignore_for_file: use_build_context_synchronously

import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dcs/config/api_config.dart';


class PrimaryExamBooking {
  final List<Map<String, String>> allPatients;
  final List<Map<String, String>> allPendingPatients;

  PrimaryExamBooking({
    required this.allPatients,
    required this.allPendingPatients,
  });

  Future<Map<String, dynamic>?> addAppointment({
    required BuildContext context,
    required DateTime? selectedDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required String selectedPatientUid,
    required String selectedPatientName,
    required TextEditingController patientController,
    required String studentId,
    required String studentEmail,
    required String universityId,
    required int studentYear,
    required int maxPerDay,
    required int currentDayCount,
  }) async {
    if (selectedDate != null && startTime != null && endTime != null && selectedPatientUid.isNotEmpty) {
      if (studentYear != 4 && studentYear != 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن الحجز إلا لطلاب سنة رابعة أو خامسة')));
        return null;
      }
      if (maxPerDay > 0 && currentDayCount >= maxPerDay) {
        String yearText = studentYear == 4 ? 'رابعة' : (studentYear == 5 ? 'خامسة' : studentYear.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عدد الحالات المسموح بها لطلاب السنة $yearText في هذا اليوم هو $maxPerDay فقط. يرجى اختيار يوم آخر للحجز.'),
            duration: const Duration(seconds: 4),
          ),
        );
        return null;
      }
      int serial = currentDayCount + 1;
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
        'serial': serial,
      };
      final url = Uri.parse('${ApiConfig.baseUrl}/primaryExamAppointments');
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
