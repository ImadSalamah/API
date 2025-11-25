import 'package:flutter/material.dart';

class DentalFormTableReadOnly extends StatelessWidget {
  final Map<String, bool>? data;
  const DentalFormTableReadOnly({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final d = data ?? {};
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            _cell('ASA I', d['asa1'] ?? false),
            _cell('ASA II', d['asa2'] ?? false),
          ],
        ),
        TableRow(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("4th year"),
                _cell('Surgery', d['surgery4'] ?? false),
                _cell('Cons', d['cons4'] ?? false),
                _cell('Ortho', d['ortho4'] ?? false),
                _cell('Peado', d['peado4'] ?? false),
                _cell('Prostho', d['prostho4'] ?? false),
                _cell('Endo', d['endo4'] ?? false),
                _cell('Perio', d['perio4'] ?? false),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("5th year"),
                _cell('Surgery', d['surgery5'] ?? false),
                _cell('Cons', d['cons5'] ?? false),
                _cell('Ortho', d['ortho5'] ?? false),
                _cell('Peado', d['peado5'] ?? false),
                _cell('Prostho', d['prostho5'] ?? false),
                _cell('Endo', d['endo5'] ?? false),
                _cell('Perio', d['perio5'] ?? false),
              ],
            ),
          ],
        ),
        TableRow(
          children: [
            _cell('Simple', d['simple'] ?? false),
            _cell('Complex', d['complex'] ?? false),
          ],
        ),
      ],
    );
  }

  Widget _cell(String label, bool checked) {
    return Row(
      children: [
        Checkbox(value: checked, onChanged: null, activeColor: const Color(0xFF2A7A94)),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
