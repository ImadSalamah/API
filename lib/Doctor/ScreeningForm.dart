// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:dcs/config/api_config.dart';

class ScreeningForm extends StatefulWidget {
  final Map<String, dynamic>? patientData;
  final int? age;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> data)? onSave;

  const ScreeningForm({
    super.key,
    this.patientData,
    this.age,
    this.initialData,
    this.onSave,
  });

  @override
  _ScreeningFormState createState() => _ScreeningFormState();
}

class _ScreeningFormState extends State<ScreeningForm> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _chiefComplaintController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _positiveAnswersExplanationController = TextEditingController();
  final TextEditingController _preventiveAdviceController = TextEditingController();

  late Map<String, int> medicalHistory;
  late Map<String, bool> healthProblems;
  late Map<String, int> dentalHistory;
  late List<Map<String, dynamic>> categories;
  late int _medicationRequiredBeforeDental;
  late int _smokeOrTobacco;
  final TextEditingController _smokeKindController = TextEditingController();
  final TextEditingController _smokeFrequencyController = TextEditingController();

  String get _localKey => 'screening_form_data_${widget.patientData?['patient_uid'] ?? widget.patientData?['id'] ?? ''}';
  String get _scrollKey => 'screening_form_scroll_offset_${widget.patientData?['patient_uid'] ?? widget.patientData?['id'] ?? ''}';

  dynamic deepConvertToStringKeyedMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(
        key.toString(),
        deepConvertToStringKeyedMap(value),
      ));
    } else if (data is List) {
      return data.map((item) => deepConvertToStringKeyedMap(item)).toList();
    } else {
      return data;
    }
  }

  @override
  void initState() {
    super.initState();

  medicalHistory = {
      'Have there been any changes in your health in the past year?': 0,
      'Are you under the care of a physician?': 0,
      'Have you had any serious illnesses or operations?': 0,
    };

    healthProblems = {
      'Heart Failure': false,
      'Heart Attack': false,
      'Angina': false,
      'Pacemaker': false,
      'Congenital Heart Disease': false,
      'Other Heart Disease': false,
      'Anemia': false,
      'Hemophilia': false,
      'Leukaemia': false,
      'Blood Transfusion': false,
      'Other Blood Disease': false,
      'Asthma': false,
      'Chronic Obstructive Pulmonary Disease': false,
      'Gastro-oesophageal reflux': false,
      'Hepatitis': false,
      'Liver disease': false,
      'Epilepsy': false,
      'Parkinson\'s Disease': false,
      'Kidney Failure': false,
      'Dialysis': false,
      'Drug Allergy': false,
      'Food Allergy': false,
      'Cancer': false,
      'Breast Cancer': false,
      'Lung Cancer': false,
      'Prostate Cancer': false,
      'Colon Cancer': false,
      'Other Cancer': false,
    };

    dentalHistory = {
      'Have you had any serious problem(s) with any previous dental treatment?': 0,
      'Have you ever had an injury to your face, jaw, or teeth?': 0,
      'Do you ever feel like you have a dry mouth?': 0,
      'Have you ever had an unusual reaction to local anesthetic?': 0,
      'Do you clench your teeth?': 0,
    };

    categories = [
      {'name': 'Lips', 'score': 0},
      {'name': 'Tongue', 'score': 0},
      {'name': 'Gums and Tissues', 'score': 0},
      {'name': 'Saliva', 'score': 0},
      {'name': 'Natural Teeth', 'score': 0},
      {'name': 'Denture(s)', 'score': 0},
      {'name': 'Oral Cleanliness', 'score': 0},
      {'name': 'Dental Pain', 'score': 0},
    ];

    _medicationRequiredBeforeDental = 0;
    _smokeOrTobacco = 0;

    if (widget.initialData != null) {
      final safeData = deepConvertToStringKeyedMap(widget.initialData!);
      _loadInitialData(safeData);
    }

    _loadLocalFormData();
    _restoreScrollPosition();
    _scrollController.addListener(_saveScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    _smokeKindController.dispose();
    _smokeFrequencyController.dispose();
    super.dispose();
  }

  void _loadInitialData(Map<String, dynamic> data) {
    _chiefComplaintController.text = data['chiefComplaint'] ?? '';
    _medicationsController.text = data['medications'] ?? '';
    _positiveAnswersExplanationController.text = data['positiveAnswersExplanation'] ?? '';
    _preventiveAdviceController.text = data['preventiveAdvice'] ?? '';

    if (data['medicalHistory'] != null) {
      final raw = data['medicalHistory'];
      if (raw is Map<String, dynamic>) {
        medicalHistory = raw.map((k, v) => MapEntry(k.toString(), v is int ? v : int.tryParse(v.toString()) ?? 0));
      } else if (raw is Map) {
        medicalHistory = Map<String, int>.fromEntries(
          raw.entries.map((e) => MapEntry(e.key.toString(), e.value is int ? e.value : int.tryParse(e.value.toString()) ?? 0)),
        );
      }
    }
    if (data['healthProblems'] != null) {
      final raw = data['healthProblems'];
      if (raw is Map<String, dynamic>) {
        healthProblems = raw.map((k, v) => MapEntry(k.toString(), v == true));
      } else if (raw is Map) {
        healthProblems = Map<String, bool>.fromEntries(
          raw.entries.map((e) => MapEntry(e.key.toString(), e.value == true)),
        );
      }
    }
    if (data['dentalHistory'] != null) {
      final raw = data['dentalHistory'];
      if (raw is Map<String, dynamic>) {
        dentalHistory = raw.map((k, v) => MapEntry(k.toString(), v is int ? v : int.tryParse(v.toString()) ?? 0));
      } else if (raw is Map) {
        dentalHistory = Map<String, int>.fromEntries(
          raw.entries.map((e) => MapEntry(e.key.toString(), e.value is int ? e.value : int.tryParse(e.value.toString()) ?? 0)),
        );
      }
    }
    if (data['categories'] != null) {
      final raw = data['categories'];
      if (raw is List) {
        categories = raw.map((e) {
          if (e is Map<String, dynamic>) {
            return Map<String, dynamic>.fromEntries(
              e.entries.map((kv) => MapEntry(kv.key.toString(), kv.value)),
            );
          } else if (e is Map) {
            return Map<String, dynamic>.fromEntries(
              e.entries.map((kv) => MapEntry(kv.key.toString(), kv.value)),
            );
          } else {
            return <String, dynamic>{};
          }
        }).toList();
      }
    }
    _medicationRequiredBeforeDental = data['medicationRequiredBeforeDental'] ?? 0;
    _smokeOrTobacco = data['smokeOrTobacco'] ?? 0;
    _smokeKindController.text = data['smokeKind'] ?? '';
    _smokeFrequencyController.text = data['smokeFrequency'] ?? '';
  }

  @override
  void didUpdateWidget(covariant ScreeningForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData && widget.initialData != null) {
      final safeData = deepConvertToStringKeyedMap(widget.initialData!);
      _loadInitialData(safeData);
      setState(() {}); 
    }
  }

  Future<void> _loadLocalFormData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_localKey);
    if (savedData != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        (savedData.isNotEmpty) ? Map<String, dynamic>.from(jsonDecode(savedData)) : {},
      );
      _loadInitialData(data);
    }
  }

  Future<void> _saveLocalFormData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(data));
  }

  void _onFormChanged() {
    final formData = _collectFormData();
    _saveLocalFormData(formData);
  }

  Map<String, dynamic> _collectFormData() {
    return {
      'chiefComplaint': _chiefComplaintController.text,
      'medicalHistory': medicalHistory,
      'healthProblems': healthProblems.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList(),
      'positiveAnswersExplanation': _positiveAnswersExplanationController.text,
      'medications': _medicationsController.text,
      'medicationRequiredBeforeDental': _medicationRequiredBeforeDental,
      'smokeOrTobacco': _smokeOrTobacco,
      'smokeKind': _smokeKindController.text,
      'smokeFrequency': _smokeFrequencyController.text,
      'dentalHistory': dentalHistory,
      'categories': categories,
      'preventiveAdvice': _preventiveAdviceController.text,
      'totalScore': getTotalScore(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  int getTotalScore() {
    return categories.fold(0, (sum, item) => sum + (item['score'] as int));
  }

  Widget _buildPatientInfo() {
    final p = widget.patientData;
    if (p == null) return const SizedBox.shrink();

    final firstName = (p['FIRSTNAME'] ?? p['firstName'] ?? '').toString().trim();
    final fatherName = (p['FATHERNAME'] ?? p['fatherName'] ?? '').toString().trim();
    final grandFatherName = (p['GRANDFATHERNAME'] ?? p['grandFatherName'] ?? p['grandfatherName'] ?? '').toString().trim();
    final familyName = (p['FAMILYNAME'] ?? p['familyName'] ?? '').toString().trim();
    final fullName = [firstName, fatherName, grandFatherName, familyName].join(' ').replaceAll(RegExp(' +'), ' ').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fullName.isNotEmpty)
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                      text: 'اسم المريض: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: fullName),
                  ],
                ),
              ),
            if (widget.age != null)
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                      text: 'العمر: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${widget.age}'),
                  ],
                ),
              ),
            if (p['GENDER'] != null || p['gender'] != null)
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                      text: 'الجنس: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${p['GENDER'] ?? p['gender']}'),
                  ],
                ),
              ),
            if (p['PHONE'] != null || p['phone'] != null)
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                      text: 'الهاتف: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${p['PHONE'] ?? p['phone']}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                ...children,
              ],
            ),
          ),
        ),
      );

  Future<void> _submitForm() async {
    try {
      final formData = _collectFormData();
      final patientUid = widget.patientData?['patient_uid'] ?? widget.patientData?['PATIENT_UID'] ?? widget.patientData?['id'] ?? '';
      
      if (patientUid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: لا يوجد معرف للمريض')),
        );
        return;
      }

      // ✅ حفظ في الداتا بيز
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/screening'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patient_uid': patientUid,
          'screening_data': formData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      // ✅ التعديل الرئيسي: يقبل كلا الـ status codes (200 و 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ نجح الحفظ في الداتا بيز
        await _saveLocalFormData(formData);
        
        if (widget.onSave != null) {
          widget.onSave!(formData);
          await _clearLocalData(); 
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الفحص المبدئي بنجاح')),
        );
      } else {
        throw Exception('فشل في الحفظ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving screening form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    }
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey);
    await prefs.remove(_scrollKey);
  }

  Future<void> _saveScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    if (_scrollController.hasClients) {
      await prefs.setDouble(_scrollKey, _scrollController.offset);
    }
  }

  Future<void> _restoreScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getDouble(_scrollKey) ?? 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      } catch (e) {
        debugPrint('ScrollController error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF2A7A94);
    final inputDecorationTheme = InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: mainColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      border: const OutlineInputBorder(),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: inputDecorationTheme,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.patientData != null) _buildPatientInfo(),
            _buildSection('Chief Complaint', [
              TextField(
                controller: _chiefComplaintController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter chief complaint...',
                ),
                maxLines: 3,
                onChanged: (value) {
                  _onFormChanged();
                },
              ),
            ]),
            _buildSection('Medical History', [
              ...medicalHistory.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('Yes'),
                              value: 1,
                              groupValue: entry.value,
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  medicalHistory[entry.key] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('No'),
                              value: 0,
                              groupValue: entry.value,
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  medicalHistory[entry.key] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
            ]),
            _buildSection('Health Problems', [
              LayoutBuilder(
                builder: (context, constraints) {
                  final entries = healthProblems.entries.toList();
                  final half = (entries.length / 2).ceil();
                  final col1 = entries.sublist(0, half);
                  final col2 = entries.sublist(half);
                  const mainColor = Color(0xFF2A7A94);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: col1
                              .map((entry) => CheckboxListTile(
                                    title: Text(entry.key),
                                    value: entry.value,
                                    activeColor: mainColor,
                                    checkColor: Colors.white,
                                    onChanged: (value) {
                                      setState(() {
                                        healthProblems[entry.key] = value!;
                                        _onFormChanged();
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: col2
                              .map((entry) => CheckboxListTile(
                                    title: Text(entry.key),
                                    value: entry.value,
                                    activeColor: mainColor,
                                    checkColor: Colors.white,
                                    onChanged: (value) {
                                      setState(() {
                                        healthProblems[entry.key] = value!;
                                        _onFormChanged();
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ]),
            _buildSection('Please Explain any Positive Answers', [
              TextField(
                controller: _positiveAnswersExplanationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Explain any positive answers...',
                ),
                maxLines: 3,
                onChanged: (value) {
                  _onFormChanged();
                },
              ),
            ]),
            _buildSection('List any Medications you are Currently Taking', [
              TextField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'List your current medications...',
                ),
                maxLines: 3,
                onChanged: (value) {
                  _onFormChanged();
                },
              ),
            ]),
            _buildSection(
                'Are you taking any medication required before dental treatment?',
                [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('Yes'),
                          value: 1,
                          groupValue: _medicationRequiredBeforeDental,
                          activeColor: const Color(0xFF2A7A94),
                          onChanged: (value) {
                            setState(() {
                              _medicationRequiredBeforeDental = value!;
                              _onFormChanged();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('No'),
                          value: 0,
                          groupValue: _medicationRequiredBeforeDental,
                          activeColor: const Color(0xFF2A7A94),
                          onChanged: (value) {
                            setState(() {
                              _medicationRequiredBeforeDental = value!;
                              _onFormChanged();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ]),
            _buildSection('Do you smoke or use tobacco in any form?', [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text('Yes'),
                      value: 1,
                      groupValue: _smokeOrTobacco,
                      activeColor: const Color(0xFF2A7A94),
                      onChanged: (value) {
                        setState(() {
                          _smokeOrTobacco = value!;
                          _onFormChanged();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text('No'),
                      value: 0,
                      groupValue: _smokeOrTobacco,
                      activeColor: const Color(0xFF2A7A94),
                      onChanged: (value) {
                        setState(() {
                          _smokeOrTobacco = value!;
                          _onFormChanged();
                          if (_smokeOrTobacco == 0) {
                            _smokeKindController.clear();
                            _smokeFrequencyController.clear();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_smokeOrTobacco == 1) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _smokeKindController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'What kind?',
                    hintText: 'Type of tobacco or smoking',
                  ),
                  onChanged: (value) {
                    _onFormChanged();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _smokeFrequencyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'How frequently?',
                    hintText: 'e.g. 5 times/day',
                  ),
                  onChanged: (value) {
                    _onFormChanged();
                  },
                ),
              ],
            ]),
            _buildSection('Dental History', [
              ...dentalHistory.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('Yes'),
                              value: 1,
                              groupValue: entry.value,
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  dentalHistory[entry.key] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('No'),
                              value: 0,
                              groupValue: entry.value,
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  dentalHistory[entry.key] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
            ]),
            _buildSection('Oral Health Assessment', [
              ...categories.map((category) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category['name']),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('0 health'),
                              value: 0,
                              groupValue: category['score'],
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  category['score'] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('1 changes'),
                              value: 1,
                              groupValue: category['score'],
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  category['score'] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('2 unhealthy'),
                              value: 2,
                              groupValue: category['score'],
                              activeColor: const Color(0xFF2A7A94),
                              onChanged: (value) {
                                setState(() {
                                  category['score'] = value!;
                                  _onFormChanged();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Score: ${getTotalScore()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
            _buildSection('Preventive Advice', [
              TextField(
                controller: _preventiveAdviceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter preventive advice...',
                ),
                maxLines: 3,
                onChanged: (value) {
                  _onFormChanged();
                },
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A7A94),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: _submitForm,
                child: const Text('Save Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}