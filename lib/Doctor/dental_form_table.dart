import 'package:flutter/material.dart';

typedef DentalFormTableData = Map<String, bool>;

class DentalFormTable extends StatefulWidget {
  final DentalFormTableData? initialData;
  final void Function(DentalFormTableData)? onChanged;

  const DentalFormTable({
    super.key,
    this.initialData,
    this.onChanged,
  });

  @override
  State<DentalFormTable> createState() => _DentalFormTableState();
}

class _DentalFormTableState extends State<DentalFormTable> {
  late bool asa1;
  late bool asa2;

  late bool surgery4, cons4, ortho4, peado4, prostho4, endo4, perio4;
  late bool surgery5, cons5, ortho5, peado5, prostho5, endo5, perio5;

  late bool simple, complex;

  @override
  void initState() {
    super.initState();

    final d = widget.initialData ?? {};

    asa1 = d['asa1'] ?? false;
    asa2 = d['asa2'] ?? false;

    surgery4 = d['surgery4'] ?? false;
    cons4 = d['cons4'] ?? false;
    ortho4 = d['ortho4'] ?? false;
    peado4 = d['peado4'] ?? false;
    prostho4 = d['prostho4'] ?? false;
    endo4 = d['endo4'] ?? d['endodontics4'] ?? false;
    perio4 = d['perio4'] ?? false;

    surgery5 = d['surgery5'] ?? false;
    cons5 = d['cons5'] ?? false;
    ortho5 = d['ortho5'] ?? false;
    peado5 = d['peado5'] ?? false;
    prostho5 = d['prostho5'] ?? false;
    endo5 = d['endo5'] ?? d['endodontics5'] ?? false;
    perio5 = d['perio5'] ?? false;

    simple = d['simple'] ?? false;
    complex = d['complex'] ?? false;
  }

  void _update() {
    widget.onChanged?.call({
      'asa1': asa1,
      'asa2': asa2,
      'surgery4': surgery4,
      'cons4': cons4,
      'ortho4': ortho4,
      'peado4': peado4,
      'prostho4': prostho4,
      'endo4': endo4,
      'perio4': perio4,
      'surgery5': surgery5,
      'cons5': cons5,
      'ortho5': ortho5,
      'peado5': peado5,
      'prostho5': prostho5,
      'endo5': endo5,
      'perio5': perio5,
      'simple': simple,
      'complex': complex,
    });
  }
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2A7A94);

    return Table(
      border: TableBorder.all(color: Colors.grey.shade400),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: [
        _row(
          CheckboxListTile(
            value: asa1,
            onChanged: (v) => setState(() {
              asa1 = v ?? false;
              _update();
            }),
            title: const Text("ASA I",
                style: TextStyle(fontWeight: FontWeight.bold)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: color,
          ),
          CheckboxListTile(
            value: asa2,
            onChanged: (v) => setState(() {
              asa2 = v ?? false;
              _update();
            }),
            title: const Text("ASA II",
                style: TextStyle(fontWeight: FontWeight.bold)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: color,
          ),
        ),

        _row(
          _yearColumn(
            title: "4th Year",
            values: {
              "Surgery": surgery4,
              "Cons": cons4,
              "Ortho": ortho4,
              "Peado": peado4,
              "Prostho": prostho4,
              "Endo": endo4,
              "Perio": perio4,
            },
            onChanged: (name, value) {
              setState(() {
                switch (name) {
                  case "Surgery": surgery4 = value; break;
                  case "Cons": cons4 = value; break;
                  case "Ortho": ortho4 = value; break;
                  case "Peado": peado4 = value; break;
                  case "Prostho": prostho4 = value; break;
                  case "Endo": endo4 = value; break;
                  case "Perio": perio4 = value; break;
                }
                _update();
              });
            },
          ),
          _yearColumn(
            title: "5th Year",
            values: {
              "Surgery": surgery5,
              "Cons": cons5,
              "Ortho": ortho5,
              "Peado": peado5,
              "Prostho": prostho5,
              "Endo": endo5,
              "Perio": perio5,
            },
            onChanged: (name, value) {
              setState(() {
                switch (name) {
                  case "Surgery": surgery5 = value; break;
                  case "Cons": cons5 = value; break;
                  case "Ortho": ortho5 = value; break;
                  case "Peado": peado5 = value; break;
                  case "Prostho": prostho5 = value; break;
                  case "Endo": endo5 = value; break;
                  case "Perio": perio5 = value; break;
                }
                _update();
              });
            },
          ),
        ),

        _row(
          CheckboxListTile(
            value: simple,
            onChanged: (v) => setState(() {
              simple = v ?? false;
              _update();
            }),
            title: const Text("Simple"),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: color,
          ),
          CheckboxListTile(
            value: complex,
            onChanged: (v) => setState(() {
              complex = v ?? false;
              _update();
            }),
            title: const Text("Complex"),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: color,
          ),
        ),
      ],
    );
  }

  TableRow _row(Widget left, Widget right) =>
      TableRow(children: [left, right]);

  Widget _yearColumn({
    required String title,
    required Map<String, bool> values,
    required void Function(String name, bool value) onChanged,
  }) {
    const color = Color(0xFF2A7A94);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            )),
        for (final entry in values.entries)
          CheckboxListTile(
            value: entry.value,
            title: Text(entry.key),
            onChanged: (v) => onChanged(entry.key, v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: color,
          ),
      ],
    );
  }
}
