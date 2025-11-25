// ignore_for_file: deprecated_member_use, empty_catches, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'dart:convert';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';
import 'svg.dart';
import 'assign_patients_to_student_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dental_form_table.dart';
import 'ScreeningForm.dart';
import 'package:dcs/config/api_config.dart';

class InitialExamination extends StatefulWidget {
  final Map<String, dynamic>? patientData;
  final int? age;
  final String doctorId;
  final String patientId;
  final Map<String, dynamic>? examinationData;
  final bool isEditMode;
  final String? existingExamId;

  const InitialExamination({
    super.key,
    this.patientData,
    this.age,
    required this.doctorId,
    required this.patientId,
    this.examinationData,
    this.isEditMode = false,
    this.existingExamId,
  });

  @override
  State<InitialExamination> createState() => _InitialExaminationState();
}

class _InitialExaminationState extends State<InitialExamination> with SingleTickerProviderStateMixin {
  Map<String, bool> _dentalFormTableData = {};
  String _dentalChartNotes = '';
  final Map<String, String> _teethConditionNames = {};
  late TabController _tabController;
  final Map<String, dynamic> _examData = {
    'tmj': 'Normal',
    'lymphNode': 'Normal',
    'patientProfile': 'Straight',
    'lipCompetency': 'Competent',
    'incisalClassification': 'Class I',
    'overjet': 'Normal',
    'overbite': 'Normal',
    'hardPalate': 'Normal',
    'buccalMucosa': 'Normal',
    'floorOfMouth': 'Normal',
    'edentulousRidge': 'Well-developed ridge',
    'periodontalRisk': 'Low',
    'periodontalChart': {
      'Upper right posterior': 0,
      'Upper anterior': 0,
      'Upper left posterior': 0,
      'Lower right posterior': 0,
      'Lower anterior': 0,
      'Lower left posterior': 0,
    },
    'dentalChart': {
      'selectedTeeth': <String>[],
      'teethConditions': <String, String>{},
    }
  };

  Map<String, Color> _teethColors = {};
  Map<String, dynamic>? _screeningData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTabIndex();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _saveTabIndex(_tabController.index);
      }
    });
    _loadLocalExamData();
    _loadPreviousExaminationIfExists();

    if (_dentalFormTableData.isEmpty && widget.examinationData != null) {
      final sourceMap = widget.examinationData!;
      final sourceTable = _extractDentalFormTable(sourceMap['dentalFormTable']) ??
          _extractDentalFormTable(sourceMap['dentalFormData']) ??
          _extractDentalFormTable(sourceMap['dental_form_data']) ??
          _extractDentalFormTableFromMap(sourceMap) ??
          _extractDentalFormTable((sourceMap['examData'] is Map) ? (sourceMap['examData'] as Map)['dentalFormTable'] : null) ??
          _extractDentalFormTable((sourceMap['examData'] is Map) ? (sourceMap['examData'] as Map)['dentalFormData'] : null) ??
          _extractDentalFormTable((sourceMap['examData'] is Map) ? (sourceMap['examData'] as Map)['dental_form_data'] : null) ??
          (sourceMap['examData'] is Map ? _extractDentalFormTableFromMap(sourceMap['examData'] as Map) : null);
      if (sourceTable != null) {
        _dentalFormTableData = sourceTable;
      }
    }

    if (widget.examinationData != null) {
      final Map<String, dynamic> oldExam = widget.examinationData!;
      if (oldExam.isNotEmpty) {
        oldExam.forEach((key, value) {
          if (_examData.containsKey(key)) {
            _examData[key] = value;
          }
        });
        if (oldExam['dentalChart'] != null && oldExam['dentalChart'] is Map) {
          final Map<String, dynamic> chart = Map<String, dynamic>.from(oldExam['dentalChart']);
          List<String> selectedTeeth = [];
          if (chart['selectedTeeth'] != null && chart['selectedTeeth'] is List) {
            selectedTeeth = List<String>.from(chart['selectedTeeth'].map((e) => e.toString()));
          }
          Map<String, String> teethConditions = {};
          if (chart['teethConditions'] != null && chart['teethConditions'] is Map) {
            teethConditions = Map<String, String>.from(chart['teethConditions']);
          }
          final diseaseColorMap = {
            'Mobile Tooth': 0xFF1976D2,
            'Unrestorable Tooth': 0xFFD32F2F,
            'Supernumerary': 0xFF7B1FA2,
            'Tender to Percussion': 0xFFFFA000,
            'Root Canal Therapy': 0xFF388E3C,
            'Over Retained': 0xFF0097A7,
            'Caries': 0xFF795548,
            'Missing Tooth': 0xFF616161,
            'Filling': 0xFFFFD600,
            'Crown': 0xFFFF7043,
            'Implant': 0xFF43A047,
          };
          _teethColors = {};
          teethConditions.forEach((tooth, disease) {
            if (diseaseColorMap.containsKey(disease)) {
              _teethColors[tooth] = Color(diseaseColorMap[disease]!);
            } else if (disease.length == 6 && int.tryParse(disease, radix: 16) != null) {
              _teethColors[tooth] = Color(int.parse(disease, radix: 16) + 0xFF000000);
            }
          });
          _teethConditionNames.clear();
          teethConditions.forEach((tooth, disease) {
            _teethConditionNames[tooth] = disease;
          });
          _examData['dentalChart'] = {
            'selectedTeeth': selectedTeeth,
            'teethConditions': teethConditions,
          };
        }
        if (oldExam['periodontalChart'] != null && oldExam['periodontalChart'] is Map) {
          _examData['periodontalChart'] = Map<String, dynamic>.from(oldExam['periodontalChart']);
        }
      }
    } else if (widget.patientData != null && widget.patientData!['dentalChart'] != null) {
      final dentalChart = widget.patientData!['dentalChart'] as Map<String, dynamic>?;
      if (dentalChart != null) {
        final selectedTeeth = dentalChart['selectedTeeth'] as List<dynamic>?;
        if (selectedTeeth != null) {
          _examData['dentalChart']['selectedTeeth'] = selectedTeeth.map((e) => e.toString()).toList();
        }
        final conditions = dentalChart['teethConditions'] as Map<String, dynamic>?;
        if (conditions != null) {
          _teethColors = conditions.map((key, value) {
            if (value != null) {
              return MapEntry(key, Color(int.parse(value.toString(), radix: 16)));
            }
            return MapEntry(key, Colors.white);
          });
        }
      }
    }
  }

  Future<void> _loadPreviousExaminationIfExists() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/examinations/${widget.patientId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['examData'] != null) {
          final loadedExamData = data['examData'] as Map<String, dynamic>;
          List<String> loadedSelectedTeeth = [];
          Map<String, Color> loadedTeethColors = {};
          if (loadedExamData['dentalChart'] != null && loadedExamData['dentalChart'] is Map) {
            final dentalChart = loadedExamData['dentalChart'] as Map;
            if (dentalChart['selectedTeeth'] is List) {
              loadedSelectedTeeth = (dentalChart['selectedTeeth'] as List).map((e) => e.toString()).toList();
            }
            if (dentalChart['teethConditions'] != null) {
              final teethConds = Map<String, dynamic>.from(dentalChart['teethConditions']);
              final diseaseColorMap = {
                'Mobile Tooth': 0xFF1976D2,
                'Unrestorable Tooth': 0xFFD32F2F,
                'Supernumerary': 0xFF7B1FA2,
                'Tender to Percussion': 0xFFFFA000,
                'Root Canal Therapy': 0xFF388E3C,
                'Over Retained': 0xFF0097A7,
                'Caries': 0xFF795548,
                'Missing Tooth': 0xFF616161,
                'Filling': 0xFFFFD600,
                'Crown': 0xFFFF7043,
                'Implant': 0xFF43A047,
              };
              teethConds.forEach((key, value) {
                if (value is String && diseaseColorMap.containsKey(value)) {
                  loadedTeethColors[key.toString()] = Color(diseaseColorMap[value]!);
                } else if (value is String && value.length == 6 && int.tryParse(value, radix: 16) != null) {
                  loadedTeethColors[key.toString()] = Color(int.parse(value, radix: 16) + 0xFF000000);
                }
              });
              _teethConditionNames.clear();
              teethConds.forEach((key, value) {
                if (value is String) {
                  _teethConditionNames[key] = value;
            }
              });
          }
          }
          if (!mounted) return;
          setState(() {
            _examData.clear();
            loadedExamData['periodontalChart'] =
                loadedExamData['periodontalChart'] is Map<String, dynamic>
                    ? loadedExamData['periodontalChart']
                    : Map<String, dynamic>.from(loadedExamData['periodontalChart'] as Map);
            if (loadedExamData['dentalChart'] != null) {
              loadedExamData['dentalChart'] =
                  loadedExamData['dentalChart'] is Map<String, dynamic>
                      ? loadedExamData['dentalChart']
                      : Map<String, dynamic>.from(loadedExamData['dentalChart'] as Map);
              if (loadedExamData['dentalChart']['teethConditions'] != null) {
                loadedExamData['dentalChart']['teethConditions'] =
                    loadedExamData['dentalChart']['teethConditions'] is Map<String, dynamic>
                        ? loadedExamData['dentalChart']['teethConditions']
                        : Map<String, dynamic>.from(loadedExamData['dentalChart']['teethConditions'] as Map);
              }
              loadedExamData['dentalChart']['selectedTeeth'] = loadedSelectedTeeth;
            }
            _examData.addAll(loadedExamData);
            if (loadedTeethColors.isNotEmpty) {
              _teethColors = loadedTeethColors;
            }
          });
          _onExamChanged();
        }
        if (data['screening'] != null) {
          final screening = data['screening'] as Map<String, dynamic>;
          if (!mounted) return;
          setState(() {
            _screeningData = screening;
          });
          _onExamChanged();
        }
      }
    } catch (e) {
      debugPrint('Error loading previous examination: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalExamData() async {
    final prefs = await SharedPreferences.getInstance();
    final examDataStr = prefs.getString('initial_exam_data');
    final screeningDataStr = prefs.getString('initial_screening_data');
    if (examDataStr != null) {
      setState(() {
        _examData.clear();
        _examData.addAll(jsonDecode(examDataStr));
      });
    }
    if (screeningDataStr != null) {
      setState(() {
        _screeningData = jsonDecode(screeningDataStr);
      });
    }
  }

  Future<void> _saveLocalExamData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('initial_exam_data', jsonEncode(_examData));
    if (_screeningData != null) {
      await prefs.setString('initial_screening_data', jsonEncode(_screeningData));
    }
  }

  void _onExamChanged() {
    _saveLocalExamData();
  }

  Future<void> _saveTabIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('initial_exam_tab_index', index);
  }

  Future<void> _loadTabIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('initial_exam_tab_index');
    if (savedIndex != null && savedIndex >= 0 && savedIndex < _tabController.length) {
      _tabController.index = savedIndex;
    }
  }

  void _updateExamData(String key, dynamic value) {
    setState(() => _examData[key] = value);
    _onExamChanged();
  }

  void _updateChart(String area, int value) {
    setState(() => _examData['periodontalChart'][area] = value);
    _onExamChanged();
  }

  void _updateDentalChart(List<String> selectedTeeth) {
    setState(() {
      if (_examData['dentalChart'] == null || _examData['dentalChart'] is! Map) {
        _examData['dentalChart'] = <String, dynamic>{
          'selectedTeeth': <String>[],
          'teethConditions': <String, String>{},
        };
      } else if (_examData['dentalChart'] is! Map<String, dynamic>) {
        _examData['dentalChart'] = Map<String, dynamic>.from(_examData['dentalChart'] as Map);
      }
      final Map<String, dynamic> dentalChart = _examData['dentalChart'] as Map<String, dynamic>;
      final Set<String> selectedSet = {...selectedTeeth};
      dentalChart['selectedTeeth'] = selectedSet.toList();

      final Map<String, String> oldConditions = (dentalChart['teethConditions'] is Map)
          ? Map<String, String>.from(dentalChart['teethConditions'] as Map)
          : <String, String>{};
      final Map<String, String> teethConditions = {};

      for (final tooth in selectedSet) {
        if (_teethConditionNames.containsKey(tooth)) {
          teethConditions[tooth] = _teethConditionNames[tooth]!;
        } else if (oldConditions.containsKey(tooth)) {
          teethConditions[tooth] = oldConditions[tooth]!;
        }
      }
      _teethColors.removeWhere((key, value) => !selectedSet.contains(key));
      dentalChart['teethConditions'] = teethConditions;
    });
    _onExamChanged();
  }

  Map<String, bool>? _extractDentalFormTable(dynamic source) {
    if (source == null) return null;
    dynamic data = source;
    if (source is String) {
      try {
        data = jsonDecode(source);
      } catch (_) {
        return null;
      }
    }
    if (data is Map) {
      try {
        final raw = Map<String, bool>.from(data.map((k, v) => MapEntry(k.toString(), _toBool(v))));
        final normalized = <String, bool>{};
        raw.forEach((k, v) {
          final lower = k.toLowerCase();
          if (lower == 'endodontics4') {
            normalized['endo4'] = v;
          } else if (lower == 'endodontics5') {
            normalized['endo5'] = v;
          } else {
            normalized[k] = v;
          }
        });
        return normalized;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, bool>? _extractDentalFormTableFromMap(Map<dynamic, dynamic> container) {
    final keysToTry = {
      'dentalformtable',
      'dental_form_table',
      'dentalformdata',
      'dental_form_data',
      'dentalform',
    };
    for (final entry in container.entries) {
      final keyStr = entry.key.toString().toLowerCase();
      if (keysToTry.contains(keyStr)) {
        final table = _extractDentalFormTable(entry.value);
        if (table != null) return table;
      }
    }
    return null;
  }

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  double getResponsiveFontSize(BuildContext context, {double base = 18, double min = 12}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      return min;
    } else if (width < 600) {
      return (base + min) / 2;
    } else {
      return base;
    }
  }

  Widget _buildScreeningFormTab() {
    return ScreeningForm(
      patientData: widget.patientData,
      age: widget.age,
      initialData: _screeningData,
      onSave: (screeningData) {
        setState(() {
          _screeningData = screeningData;
        });
        _onExamChanged();
      },
    );
  }

  Widget _buildClinicalExaminationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.patientData != null)
              Center(child: _buildPatientInfo()),
            _buildSection('Extraoral Examination', [
              _buildRadioGroup(
                title: 'TMJ',
                options: ['Normal', 'Deviation of mandible', 'Tenderness on palpation', 'Clicking sounds'],
                key: 'tmj',
              ),
              _buildRadioGroup(
                title: 'Lymph node of head and neck',
                options: ['Normal', 'Tender', 'Enlarged'],
                key: 'lymphNode',
              ),
              _buildRadioGroup(
                title: 'Patient profile',
                options: ['Straight', 'Convex', 'Concave'],
                key: 'patientProfile',
              ),
              _buildRadioGroup(
                title: 'Lip Competency',
                options: ['Competent', 'Incompetent', 'Potentially competent'],
                key: 'lipCompetency',
              ),
            ]),
            _buildSection('Intraoral Examination', [
              _buildRadioGroup(
                title: 'Incisal classification',
                options: ['Class I', 'Class II Div 1', 'Class II Div 2', 'Class III'],
                key: 'incisalClassification',
              ),
              _buildRadioGroup(
                title: 'Overjet',
                options: ['Normal', 'Increased', 'Decreased'],
                key: 'overjet',
              ),
              _buildRadioGroup(
                title: 'Overbite',
                options: ['Normal', 'Increased', 'Decreased'],
                key: 'overbite',
              ),
            ]),
            _buildSection('Soft Tissue Examination', [
              _buildRadioGroup(
                title: 'Hard Palate',
                options: ['Normal', 'Tori', 'Stomatitis', 'Ulcers', 'Red lesions'],
                key: 'hardPalate',
              ),
              _buildRadioGroup(
                title: 'Buccal mucosa',
                options: ['Normal', 'Pigmentation', 'Ulceration', 'Linea alba'],
                key: 'buccalMucosa',
              ),
              _buildRadioGroup(
                title: 'Floor of mouth',
                options: ['Normal', 'High frenum', 'Wharton\'s duct stenosis'],
                key: 'floorOfMouth',
              ),
              _buildRadioGroup(
                title: 'In full edentulous Arch the ridge is',
                options: ['Flappy', 'Severely resorbed', 'Well-developed ridge'],
                key: 'edentulousRidge',
              ),
            ]),
            _buildSection('Periodontal Chart (BPE)', [
              _buildPeriodontalChart(),
            ]),
            _buildSection('Dental Chart', [
              _buildDentalChart(),
            ]),
            _buildDentalNotesSection(),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dental Form Table',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DentalFormTable(
                        initialData: _dentalFormTableData.isNotEmpty
                            ? _dentalFormTableData
                            : (widget.examinationData != null
                                ? (_extractDentalFormTable(widget.examinationData!['dentalFormTable']) ??
                                    _extractDentalFormTable(widget.examinationData!['dentalFormData']) ??
                                    _extractDentalFormTable(widget.examinationData!['dental_form_data']) ??
                                    _extractDentalFormTableFromMap(widget.examinationData!) ??
                                    _extractDentalFormTable((widget.examinationData!['examData'] is Map)
                                        ? (widget.examinationData!['examData'] as Map)['dentalFormTable']
                                        : null) ??
                                    _extractDentalFormTable((widget.examinationData!['examData'] is Map)
                                        ? (widget.examinationData!['examData'] as Map)['dentalFormData']
                                        : null) ??
                                    _extractDentalFormTable((widget.examinationData!['examData'] is Map)
                                        ? (widget.examinationData!['examData'] as Map)['dental_form_data']
                                        : null) ??
                                    (widget.examinationData!['examData'] is Map
                                        ? _extractDentalFormTableFromMap(
                                            widget.examinationData!['examData'] as Map)
                                        : null))
                                : null),
                        onChanged: (data) {
                          setState(() {
                            _dentalFormTableData = data;
                          });
                          _onExamChanged();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    final p = widget.patientData;
    if (p == null) return const SizedBox.shrink();

    final firstName = (p['firstName'] ?? '').toString().trim();
    final fatherName = (p['fatherName'] ?? '').toString().trim();
    final grandFatherName = (p['grandfatherName'] ?? '').toString().trim();
    final familyName = (p['familyName'] ?? '').toString().trim();
    final fullName = [firstName, fatherName, grandFatherName, familyName].join(' ').replaceAll(RegExp(' +'), ' ').trim();
    final fontSize = getResponsiveFontSize(context, base: 16, min: 11);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fullName.isNotEmpty)
              Text('اسم المريض: $fullName', style: TextStyle(fontSize: fontSize)),
            if (widget.age != null) Text('العمر: ${widget.age}', style: TextStyle(fontSize: fontSize)),
            if (p['gender'] != null) Text('الجنس: ${p['gender']}', style: TextStyle(fontSize: fontSize)),
            if (p['phone'] != null) Text('رقم الهاتف: ${p['phone']}', style: TextStyle(fontSize: fontSize)),
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
              style: TextStyle(fontSize: getResponsiveFontSize(context, base: 18, min: 12), fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
    ),
  );

  Widget _buildRadioGroup({
    required String title,
    required List<String> options,
    required String key,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
      title, 
      style: TextStyle(
        fontWeight: FontWeight.bold, 
        fontSize: getResponsiveFontSize(context, base: 16, min: 11)
      ),
    ),
    const SizedBox(height: 8),
    ...options.map((option) => Container(
      constraints: BoxConstraints(
        minHeight: 48, // Fixed height for consistent touch targets
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateExamData(key, option),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 24, // Fixed width for radio button
                  height: 24,
                  child: Radio<String>(
        value: option,
        groupValue: _examData[key] as String? ?? '',
                    activeColor: const Color(0xFF2A7A94),
                    onChanged: (v) => _updateExamData(key, v!),
                  ),
                ),
                const SizedBox(width: 12), // Consistent spacing
                Expanded( // ← This ensures the text doesn't overflow
                  child: Text(
                    option, 
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, base: 16, min: 11)
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      )),
    ],
  );
 

  Widget _buildPeriodontalChart() => Column(
    children: [
      ...(_examData['periodontalChart'] as Map<String, dynamic>).entries.map((entry) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: TextStyle(fontSize: getResponsiveFontSize(context, base: 16, min: 11))),
              Row(children: List.generate(5, (index) => Expanded(
                child: RadioListTile<int>(
                  title: Text('$index', style: TextStyle(fontSize: getResponsiveFontSize(context, base: 16, min: 11))),
                  value: index,
                  groupValue: entry.value as int? ?? 0,
                  activeColor: const Color(0xFF2A7A94),
                  onChanged: (v) => v != null ? _updateChart(entry.key, v) : null,
                ),
              ))),
            ],
          ),
        ),
      )),
      _buildRadioGroup(
        title: 'The periodontal risk assessment',
        options: ['Low', 'Moderate', 'High'],
        key: 'periodontalRisk',
      ),
    ],
  );

  Widget _buildDentalChart() => Column(
    children: [
      Builder(
        builder: (context) {
          final chart = _examData['dentalChart'];
          List<String> selectedTeeth = <String>[];
          if (chart is Map && chart['selectedTeeth'] is List) {
            selectedTeeth = (chart['selectedTeeth'] as List).map((e) => e.toString()).toList();
          }
          debugPrint('selectedTeeth for chart: $selectedTeeth');
          return SizedBox(
        height: 600,
        child: FittedBox(
          fit: BoxFit.contain,
          child: TeethSelector(
            age: widget.age,
            onChange: (selectedTeeth) {
              _updateDentalChart(selectedTeeth.cast<String>());
            },
                onDiseaseChange: (tooth, disease) {
                  setState(() {
                    if (disease.isEmpty) {
                      _teethConditionNames.remove(tooth);
                    } else {
                      _teethConditionNames[tooth] = disease;
                    }
                    final chart = _examData['dentalChart'];
                    List<String> selectedTeeth = <String>[];
                    if (chart is Map && chart['selectedTeeth'] is List) {
                      selectedTeeth = (chart['selectedTeeth'] as List).map((e) => e.toString()).toList();
                    }
                    _updateDentalChart(selectedTeeth);
                  });
                },
                initiallySelected: selectedTeeth,
            colorized: Map<String, Color>.from(_teethColors),
            onColorUpdate: (colors) {
              setState(() {
                _teethColors = Map<String, Color>.from(colors);
              });
              _onExamChanged();
            },
            textStyle: TextStyle(fontSize: getResponsiveFontSize(context, base: 16, min: 11)),
          ),
        ),
          );
        },
      ),
      const SizedBox(height: 16),
      _buildTeethConditionsLegend(),
      const SizedBox(height: 16),
    ],
  );

  Widget _buildDentalNotesSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dental Chart Notes (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: getResponsiveFontSize(context, base: 15, min: 11)),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 4),
              TextFormField(
                initialValue: _dentalChartNotes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter any notes related to the dental chart...'
                ),
                textAlign: TextAlign.left,
                onChanged: (val) {
                  setState(() {
                    _dentalChartNotes = val;
                    if (_examData['dentalChart'] != null && _examData['dentalChart'] is Map) {
                      (_examData['dentalChart'] as Map<String, dynamic>)['notes'] = val;
                    }
                  });
                  _onExamChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeethConditionsLegend() {
    final conditions = {
      'Mobile Tooth': const Color(0xFF1976D2),
      'Unrestorable Tooth': const Color(0xFFD32F2F),
      'Supernumerary': const Color(0xFF7B1FA2),
      'Tender to Percussion': const Color(0xFFFFA000),
      'Root Canal Therapy': const Color(0xFF388E3C),
      'Over Retained': const Color(0xFF0097A7),
      'Caries': const Color(0xFF795548),
      'Missing Tooth': const Color(0xFF616161),
      'Filling': const Color(0xFFFFD600),
      'Crown': const Color(0xFFFF7043),
      'Implant': const Color(0xFF43A047),
    };
    final fontSize = getResponsiveFontSize(context, base: 14, min: 10);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: conditions.entries.map((entry) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: entry.value,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Text(entry.key, style: TextStyle(fontSize: fontSize)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF2A7A94);
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2A7A94), width: 2),
          ),
          border: OutlineInputBorder(),
          focusColor: Color(0xFF2A7A94),
        ),
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: mainColor),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          foregroundColor: Colors.white,
          title: const Text('Initial Examination', style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Screening Form'),
              Tab(text: 'Clinical Examination'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
              actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _submitExamination,
                ),
              ],
            ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScreeningFormTab(),
            _buildClinicalExaminationTab(),
          ],
            ),
          ),
        );
  }

  void _updateTeethConditions() {
    if (_examData['dentalChart'] != null && _examData['dentalChart'] is Map) {
      final Map<String, dynamic> dentalChart = _examData['dentalChart'];
      final diseaseColorMap = {
        '1976d2': 'Mobile Tooth',
        'd32f2f': 'Unrestorable Tooth',
        '7b1fa2': 'Supernumerary',
        'ffa000': 'Tender to Percussion',
        '388e3c': 'Root Canal Therapy',
        '0097a7': 'Over Retained',
        '795548': 'Caries',
        '616161': 'Missing Tooth',
        'ffd600': 'Filling',
        'ff7043': 'Crown',
        '43a047': 'Implant',
      };
      
      final Map<String, String> teethConditions = {};
      
      _teethConditionNames.forEach((tooth, disease) {
        if (disease.isNotEmpty) {
          teethConditions[tooth] = disease;
        }
      });
      
      _teethColors.forEach((tooth, value) {
        if (!teethConditions.containsKey(tooth)) {
          final hex = value.value.toRadixString(16).padLeft(8, '0').substring(2);
          String disease = diseaseColorMap[hex] ?? hex;
          teethConditions[tooth] = disease;
  }
      });
      
      dentalChart['teethConditions'] = teethConditions;
      dentalChart['notes'] = _dentalChartNotes;
    }
  }

Future<void> _submitExamination() async {
  try {
    setState(() {
      _examData['dentalFormTable'] = _dentalFormTableData;
      if (_examData['dentalChart'] != null && _examData['dentalChart'] is Map) {
        (_examData['dentalChart'] as Map<String, dynamic>)['notes'] = _dentalChartNotes;
      }
      _updateTeethConditions();
    });

    await Future.delayed(const Duration(milliseconds: 100));

    final patientId = widget.patientId;
    if (patientId.isEmpty) {
      throw Exception('Patient ID is required to save examination.');
    }
    final examId = (widget.isEditMode && (widget.existingExamId != null && widget.existingExamId!.isNotEmpty))
        ? widget.existingExamId!
        : 'EXAM_${DateTime.now().millisecondsSinceEpoch}';

    final examRecord = {
      'exam_id': examId,
      'patient_uid': patientId,
      'doctor_id': widget.doctorId,
      'exam_date': DateTime.now().toIso8601String(),
      'exam_data': jsonEncode(_examData),
      'screening_data': jsonEncode(_screeningData ?? {}),
      'dental_form_data': jsonEncode(_dentalFormTableData),
      'notes': _dentalChartNotes,
    };

    debugPrint('Saving examination for patient: $patientId');

    // أغلب الـ APIs الحالية تدعم POST فقط، حتى في التعديل نرسل POST بنفس exam_id
    final uri = Uri.parse('${ApiConfig.baseUrl}/examinations');
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(examRecord));

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ Examination saved successfully!');

      // تحديث حالة المريض
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'EXAMINED'}),
      );

      // 🔥 إزالة المريض من قائمة الانتظار باستخدام WAITING_ID
      try {
        final waitingListRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/waitingList'));
        if (waitingListRes.statusCode == 200) {
          final waitingListData = json.decode(waitingListRes.body);
          
          String? waitingId;
          for (var item in waitingListData) {
            if (item['PATIENT_UID']?.toString() == patientId) {
              waitingId = item['WAITING_ID']?.toString();
              break;
            }
          }
          
          if (waitingId != null && waitingId.isNotEmpty) {
            final deleteRes = await http.delete(Uri.parse('${ApiConfig.baseUrl}/waitingList/$waitingId'));
            if (deleteRes.statusCode == 200 || deleteRes.statusCode == 204) {
              debugPrint('✅ Patient removed from waiting list');
            }
          }
        }
      } catch (e) {
        debugPrint('Note: Error removing from waiting list: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AssignPatientsToStudentPage(
            patientId: patientId,
            patientData: widget.patientData,
          ),
        ),
      );

    } else {
      throw Exception('Failed to save examination: ${response.statusCode}');
    }

      } catch (e) {
    debugPrint('❌ Error saving examination: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
    }
  }
}



class TeethSelector extends StatefulWidget {
  final void Function(String tooth, String disease)? onDiseaseChange;
  final int? age;
  final bool multiSelect;
  final Color selectedColor;
  final Color unselectedColor;
  final Color tooltipColor;
  final List<String> initiallySelected;
  final Map<String, Color> colorized;
  final Map<String, Color> strokedColorized;
  final Color defaultStrokeColor;
  final Map<String, double> strokeWidth;
  final double defaultStrokeWidth;
  final String leftString;
  final String rightString;
  final bool showPermanent;
  final void Function(List<String> selected) onChange;
  final void Function(Map<String, Color> colors) onColorUpdate;
  final String Function(String isoString)? notation;
  final TextStyle? textStyle;
  final TextStyle? tooltipTextStyle;

  const TeethSelector({
    super.key,
    this.onDiseaseChange,
    this.age,
    this.multiSelect = true,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.tooltipColor = Colors.black,
    this.initiallySelected = const [],
    this.colorized = const {},
    this.strokedColorized = const {},
    this.defaultStrokeColor = Colors.transparent,
    this.strokeWidth = const {},
    this.defaultStrokeWidth = 1,
    this.notation,
    this.showPermanent = true,
    this.leftString = "Left",
    this.rightString = "Right",
    this.textStyle,
    this.tooltipTextStyle,
    required this.onChange,
    required this.onColorUpdate,
  });

  @override
  State<TeethSelector> createState() => _TeethSelectorState();
}

class _TeethSelectorState extends State<TeethSelector> {
  late Data data;
  Map<String, Color> localColorized = {};
  Map<String, bool> toothSelection = {};

  @override
  void initState() {
    super.initState();
    data = _loadTeethWithRetry();
    _initializeSelections();
  }

  Data _loadTeethWithRetry() {
    try {
      final loadedData = loadTeeth();
      return loadedData;
    } catch (e) {
      return (size: Size.zero, teeth: {});
    }
  }

  void _initializeSelections() {
    toothSelection = {
      for (var key in data.teeth.keys) key: false
    };

    for (var element in widget.initiallySelected) {
      if (data.teeth.containsKey(element)) {
        toothSelection[element] = true;
      }
    }

    localColorized = Map<String, Color>.from(widget.colorized);
  }

  int _parseToothNumber(String key) => int.tryParse(key) ?? 0;

  bool _isPrimaryTooth(String key) {
    final num = _parseToothNumber(key);
    return (num >= 51 && num <= 55) ||
        (num >= 61 && num <= 65) ||
        (num >= 71 && num <= 75) ||
        (num >= 81 && num <= 85);
  }

  bool _isPermanentTooth(String key) {
    final num = _parseToothNumber(key);
    return (num >= 11 && num <= 18) ||
        (num >= 21 && num <= 28) ||
        (num >= 31 && num <= 38) ||
        (num >= 41 && num <= 48);
  }

  @override
  Widget build(BuildContext context) {
    if (data.size == Size.zero) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool showPrimary = widget.age != null && widget.age! < 12;
    final visibleTeeth = data.teeth.entries.where((e) =>
    (showPrimary && _isPrimaryTooth(e.key)) ||
        (widget.showPermanent && _isPermanentTooth(e.key))
    ).toList();

    return FittedBox(
      child: SizedBox.fromSize(
        size: Size(data.size.width * 1.5, data.size.height * 1.5),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: data.size.height * 0.75 - 16,
              child: Text(
                widget.rightString,
                style: widget.textStyle ?? const TextStyle(fontSize: 16),
              ),
            ),
            Positioned(
              right: 20,
              top: data.size.height * 0.75 - 16,
              child: Text(
                widget.leftString,
                style: widget.textStyle ?? const TextStyle(fontSize: 16),
              ),
            ),

            for (final entry in visibleTeeth)
              _ToothWidget(
                key: ValueKey('tooth-${entry.key}-${toothSelection[entry.key]}'),
                toothKey: entry.key,
                tooth: entry.value,
                isSelected: toothSelection[entry.key] ?? false,
                selectedColor: widget.selectedColor,
                unselectedColor: widget.unselectedColor,
                tooltipColor: widget.tooltipColor,
                tooltipTextStyle: widget.tooltipTextStyle,
                notation: widget.notation,
                customColor: localColorized[entry.key],
                strokeColor: widget.strokedColorized[entry.key] ??
                    widget.defaultStrokeColor,
                strokeWidth: widget.strokeWidth[entry.key] ??
                    widget.defaultStrokeWidth,
                onTap: _handleToothTap,
                onDoubleTap: _handleToothDoubleTap,
              ),
        ],
      ),
        ),
      );
  }

  Future<void> _handleToothTap(String key) async {
    final diseaseColors = {
      'Mobile Tooth': const Color(0xFF1976D2),
      'Unrestorable Tooth': const Color(0xFFD32F2F),
      'Supernumerary': const Color(0xFF7B1FA2),
      'Tender to Percussion': const Color(0xFFFFA000),
      'Root Canal Therapy': const Color(0xFF388E3C),
      'Over Retained': const Color(0xFF0097A7),
      'Caries': const Color(0xFF795548),
      'Missing Tooth': const Color(0xFF616161),
      'Filling': const Color(0xFFFFD600),
      'Crown': const Color(0xFFFF7043),
      'Implant': const Color(0xFF43A047),
    };

    String? selectedDisease = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر الحالة للسن $key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: diseaseColors.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: entry.value,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(entry.key),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (selectedDisease == 'Caries') {
      const cariesClasses = [
        'I', 'II', 'III', 'IV', 'V'
      ];
      final selectedClass = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('حدد نوع الكيرز'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: cariesClasses.map((cls) => ListTile(
                title: Text('Class $cls'),
                onTap: () => Navigator.of(context).pop(cls),
              )).toList(),
            ),
          ),
        ),
      );
      if (selectedClass != null) {
        selectedDisease = 'caries-${selectedClass.toLowerCase()}';
      } else {
        return;
      }
    }

    if (selectedDisease != null) {
      setState(() {
        if (!widget.multiSelect) {
          for (var k in toothSelection.keys) {
            toothSelection[k] = false;
          }
        }

        toothSelection[key] = true;
        if (selectedDisease != null && (selectedDisease.startsWith('caries') || selectedDisease == 'Caries')) {
          localColorized[key] = diseaseColors['Caries']!;
        } else if (selectedDisease != null && diseaseColors.containsKey(selectedDisease)) {
        localColorized[key] = diseaseColors[selectedDisease]!;
        }

        if (widget.onDiseaseChange != null) {
          widget.onDiseaseChange!(key, selectedDisease!);
        }

        widget.onChange(
            toothSelection.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList()
        );

        widget.onColorUpdate(localColorized);
      });
    }
  }

  void _handleToothDoubleTap(String key) {
    setState(() {
      toothSelection[key] = false;
      localColorized.remove(key);
    });
    if (widget.onDiseaseChange != null) {
      widget.onDiseaseChange!(key, '');
    }
    widget.onChange(
      toothSelection.entries.where((e) => e.value).map((e) => e.key).toList(),
    );
    widget.onColorUpdate(localColorized);
  }
}

class _ToothWidget extends StatelessWidget {
  final String toothKey;
  final Tooth tooth;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color tooltipColor;
  final TextStyle? tooltipTextStyle;
  final String Function(String)? notation;
  final Color? customColor;
  final Color strokeColor;
  final double strokeWidth;
  final Function(String) onTap;
  final Function(String) onDoubleTap;

  const _ToothWidget({
    required super.key,
    required this.toothKey,
    required this.tooth,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.tooltipColor,
    this.tooltipTextStyle,
    this.notation,
    this.customColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: Rect.fromLTWH(
        tooth.rect.left * 1.5,
        tooth.rect.top * 1.5,
        tooth.rect.width * 1.5,
        tooth.rect.height * 1.5,
      ),
      child: GestureDetector(
        onTap: () => onTap(toothKey),
        onDoubleTap: () => onDoubleTap(toothKey),
        child: Tooltip(
          message: notation == null ? toothKey : notation!(toothKey),
          textStyle: tooltipTextStyle,
          decoration: BoxDecoration(
            color: tooltipColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: ShapeDecoration(
              color: customColor ?? (isSelected ? selectedColor : unselectedColor),
              shape: ToothBorder(
                tooth.path,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Tooth {
  late final Path path;
  late final Rect rect;

  Tooth(Path originalPath) {
    rect = originalPath.getBounds();
    path = originalPath.shift(-rect.topLeft);
  }
}

class ToothBorder extends ShapeBorder {
  final Path path;
  final double strokeWidth;
  final Color strokeColor;

  const ToothBorder(
      this.path, {
        required this.strokeWidth,
        required this.strokeColor,
      });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return rect.topLeft == Offset.zero ? path : path.shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor;
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

typedef Data = ({Size size, Map<String, Tooth> teeth});

Data loadTeeth() {
  try {
    final doc = XmlDocument.parse(svgString);
    final viewBox = doc.rootElement.getAttribute('viewBox')?.split(' ') ?? ['0','0','0','0'];
    final size = Size(
      double.parse(viewBox[2]),
      double.parse(viewBox[3]),
    );

    final teeth = <String, Tooth>{};
    for (final element in doc.rootElement.findAllElements('path')) {
      final id = element.getAttribute('id');
      final pathData = element.getAttribute('d');
      if (id != null && pathData != null) {
        try {
          teeth[id] = Tooth(parseSvgPathData(pathData));
        } catch (e) {
          debugPrint('Error parsing tooth $id: $e');
        }
      }
    }
    return (size: size, teeth: teeth);
  } catch (e) {
    debugPrint('Error loading SVG: $e');
    return (size: Size.zero, teeth: {});
  }
}
