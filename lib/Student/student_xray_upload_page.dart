// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/oracle_storage.dart';
import 'package:dcs/config/api_config.dart';
import '../Student/student_sidebar.dart';

class StudentXrayUploadPage extends StatefulWidget {
  final String studentId;
  final String? studentName;
  final String? studentImageUrl;
  
  const StudentXrayUploadPage({
    super.key,
    required this.studentId,
    this.studentName,
    this.studentImageUrl,
  });

  @override
  State<StudentXrayUploadPage> createState() => _StudentXrayUploadPageState();
}

class _StudentXrayUploadPageState extends State<StudentXrayUploadPage> {
  XFile? xrayImage;
  Uint8List? xrayImageBytes;
  bool _isUploading = false;
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> _uploadedImagesForRequest = [];
  Map<String, dynamic>? selectedRequest;
  String? _completedRequestId;
  bool _loadingRequests = true;
  bool _loadingUploadedImages = false;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // دالة رفع الصورة إلى Oracle
  Future<String?> _uploadImageToOracleStorage(dynamic image, {String? folder}) async {
    try {
      final prefix = folder != null ? '$folder/' : '';
      final fileName =
          '${prefix}xray-${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb && image is Uint8List) {
        return uploadImageToOracle(image, fileName: fileName);
      } else if (image is XFile) {
        return uploadImageToOracle(image, fileName: fileName);
      } else if (image is Uint8List) {
        return uploadImageToOracle(image, fileName: fileName);
      } else {
        debugPrint('❌ نوع الصورة غير مدعوم');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة إلى Oracle: $e');
      return null;
    }
  }

  Future<void> _fetchRequests() async {
    setState(() { _loadingRequests = true; });
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/student-xray-requests/${widget.studentId}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final requestsData = List<Map<String, dynamic>>.from(data['data']);
          // طبيع المفاتيح لتتوافق مع الواجهة سواء رجعت الحقول بحروف كبيرة أو صغيرة
          final normalized = requestsData.map((req) {
            String? status = req['status'] ?? req['STATUS'];
            status = status?.toString().toLowerCase();

            final cloudinaryUrl = req['cloudinary_url'] ?? req['CLOUDINARY_URL'];
            final cleanedCloudinaryUrl = (cloudinaryUrl == null || cloudinaryUrl.toString().isEmpty || cloudinaryUrl.toString() == 'null')
                ? null
                : cloudinaryUrl;

            return {
              'request_id': req['request_id'] ?? req['REQUEST_ID'],
              'patient_id': req['patient_id'] ?? req['PATIENT_ID'],
              'patient_name': req['patient_name'] ?? req['PATIENT_NAME'],
              'student_id': req['student_id'] ?? req['STUDENT_ID'],
              'student_name': req['student_name'] ?? req['STUDENT_NAME'],
              'xray_type': req['xray_type'] ?? req['XRAY_TYPE'],
              'jaw': req['jaw'] ?? req['JAW'],
              'side': req['side'] ?? req['SIDE'],
              'tooth': req['tooth'] ?? req['TOOTH'],
              'created_at': req['created_at'] ?? req['CREATED_AT'],
              'status': status,
              'cloudinary_url': cleanedCloudinaryUrl,
            };
          }).toList();
          
          // طباعة عينة من البيانات للتأكد
          if (requestsData.isNotEmpty) {
            
            // طباعة جميع المفاتيح للتأكد
          }
          
          setState(() { 
            requests = normalized; 
            _loadingRequests = false; 
          });
        } else {
          setState(() { 
            requests = []; 
            _loadingRequests = false; 
          });
        }
      } else {
        setState(() { 
          requests = []; 
          _loadingRequests = false; 
        });
      }
    } catch (e) {
      setState(() { 
        requests = []; 
        _loadingRequests = false; 
      });
    }
  }

  Future<void> _fetchUploadedImagesForRequest(String requestId) async {
    setState(() {
      _loadingUploadedImages = true;
      _uploadedImagesForRequest = [];
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/xray-images/request/$requestId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final listData = () {
          if (data is List) return data;
          if (data is Map && data['data'] is List) return data['data'] as List;
          return null;
        }();

        if (listData != null) {
          final normalized = listData.whereType<Map>().map((item) {
            String? pick(Map map, List<String> keys) {
              for (final key in keys) {
                if (map.containsKey(key)) return map[key]?.toString();
              }
              return null;
            }

            final mapItem = Map<String, dynamic>.from(item);
            final imageUrl = pick(mapItem, ['image_url', 'IMAGE_URL']) ??
                pick(mapItem, ['cloudinary_url', 'CLOUDINARY_URL']) ??
                '';

            return {
              'image_id': pick(mapItem, ['image_id', 'IMAGE_ID']),
              'request_id': pick(mapItem, ['request_id', 'REQUEST_ID']),
              'patient_id': pick(mapItem, ['patient_id', 'PATIENT_ID']),
              'patient_name': pick(mapItem, ['patient_name', 'PATIENT_NAME']),
              'student_id': pick(mapItem, ['student_id', 'STUDENT_ID']),
              'student_name': pick(mapItem, ['student_name', 'STUDENT_NAME']),
              'xray_type': pick(mapItem, ['xray_type', 'XRAY_TYPE']),
              'image_url': imageUrl,
              'cloudinary_url': pick(mapItem, ['cloudinary_url', 'CLOUDINARY_URL']),
              'uploaded_at': pick(mapItem, ['uploaded_at', 'UPLOADED_AT', 'created_at', 'CREATED_AT']),
            };
          }).toList();

          setState(() {
            _uploadedImagesForRequest = normalized;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ فشل في تحميل صور الطلب $requestId: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingUploadedImages = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        
        if (bytes.length > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حجم الصورة كبير جداً. الحد الأقصى 10MB'))
          );
          return;
        }
        
        setState(() {
          xrayImage = picked;
          xrayImageBytes = bytes;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم اختيار الصورة بنجاح'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في اختيار الصورة'))
      );
    }
  }

  void _removeImage() {
    setState(() {
      xrayImage = null;
      xrayImageBytes = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إزالة الصورة'))
    );
  }

  Future<void> _uploadXrayImage() async {
    if (xrayImageBytes == null || selectedRequest == null) return;
    
    final requestId = selectedRequest!['request_id']?.toString() ?? '';
    if (requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الطلب غير متوفر'))
      );
      return;
    }

    setState(() { _isUploading = true; });
    
    try {
      // 1. رفع الصورة إلى Oracle Object Storage
      debugPrint('☁️ جاري رفع الصورة إلى Oracle...');
      String? uploadedUrl = await _uploadImageToOracleStorage(
        xrayImageBytes!,
        folder: 'dental_xrays'
      );

      if (uploadedUrl != null) {
        debugPrint('✅ تم الرفع إلى Oracle: $uploadedUrl');
        
        // 2. إرسال البيانات للسيرفر لإنشاء سجل في XRAY_IMAGES
        debugPrint('📤 جاري إنشاء سجل الأشعة عبر POST /xray_images...');
        final createUrl = Uri.parse('${ApiConfig.baseUrl}/xray_images');

        final payload = {
          'request_id': requestId,
          'xray_type': selectedRequest!['xray_type'],
          'image_url': uploadedUrl,
          // يفضل تمرير البيانات المتوفرة
          'patient_id': selectedRequest!['patient_id'],
          'patient_name': selectedRequest!['patient_name'],
          'student_id': selectedRequest!['student_id'] ?? widget.studentId,
          'cloudinary_url': uploadedUrl,
        }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

        debugPrint('📄 بيانات الإرسال: $payload');

        final response = await http.post(
          createUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ تم إنشاء سجل الأشعة وحذف الطلب');

          setState(() { 
            _isUploading = false; 
            selectedRequest = selectedRequest; 
            _completedRequestId = requestId;
            xrayImage = null; 
            xrayImageBytes = null; 
          });
          
          // إعادة تحميل قائمة الطلبات (سيتوقف ظهور الطلب لأنه حُذف)
          await _fetchRequests();
          await _fetchUploadedImagesForRequest(requestId);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ تم رفع صورة الأشعة وإنشاء السجل بنجاح'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            )
          );
        } else {
          throw Exception('فشل في الاتصال بالخادم: ${response.statusCode}');
        }
      } else {
        throw Exception('فشل في رفع الصورة إلى Oracle');
      }
    } catch (e) {
      setState(() { _isUploading = false; });
      debugPrint('❌ خطأ في الرفع: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    const Color primaryColor = Color(0xFF2A7A94);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('رفع صورة الأشعة'),
        backgroundColor: primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
            tooltip: 'تحديث',
          ),
        ],
      ),
      drawer: StudentSidebar(
        studentId: widget.studentId,
        studentName: widget.studentName,
        studentImageUrl: widget.studentImageUrl,
        allowedFeatures: const ['examined_patients', 'add_patient', 'upload_xray'],
      ),
      body: _loadingRequests
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد طلبات أشعة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : selectedRequest == null
                  ? _buildRequestsList()
                  : _buildUploadForm(),
    );
  }

 Widget _buildRequestsList() {
  // الطلبات قبل الرفع تأتي من XRAY_REQUESTS، لذلك نعرض كل ما يصل من السيرفر
  // مع استبعاد أي طلب يحتوي بالفعل على صورة احتياطياً.
  final pendingRequests = requests.where((req) {
    final cloudinaryUrl = req['cloudinary_url'];
    final imageUrl = req['image_url'] ?? req['IMAGE_URL'];
    return (cloudinaryUrl == null || cloudinaryUrl.toString().isEmpty) &&
           (imageUrl == null || imageUrl.toString().isEmpty);
  }).toList();

  debugPrint('📋 عدد الطلبات المعلقة (XRAY_REQUESTS): ${pendingRequests.length}');

  if (pendingRequests.isEmpty && _uploadedImagesForRequest.isNotEmpty) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUploadedImagesSection(Theme.of(context).textTheme),
      ],
    );
  }

  if (pendingRequests.isEmpty && _uploadedImagesForRequest.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'لا توجد طلبات أشعة معلقة',
            style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'جميع طلباتك تم رفع صورها بنجاح',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    itemCount: pendingRequests.length,
    itemBuilder: (context, idx) {
      final req = pendingRequests[idx];
      final patientName = req['patient_name'] ?? 'غير محدد';
      final xrayType = req['xray_type'] ?? 'غير محدد';
      final jaw = req['jaw'];
      final tooth = req['tooth'];
      final side = req['side'];
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: const Icon(
            Icons.warning_amber,
            color: Colors.red,
          ),
          title: Text(
            'المريض: $patientName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نوع الأشعة: $xrayType'),
              if (jaw != null && jaw.toString().isNotEmpty) 
                Text('الفك: $jaw'),
              if (side != null && side.toString().isNotEmpty) 
                Text('الجهة: $side'),
              if (tooth != null && tooth.toString().isNotEmpty) 
                Text('السن: $tooth'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ناقص صورة',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() { 
              selectedRequest = req; 
              xrayImage = null; 
              xrayImageBytes = null; 
              _completedRequestId = null;
              _uploadedImagesForRequest = [];
              _loadingUploadedImages = false;
            });
          },
        ),
      );
    },
  );
}
  
  Widget _buildUploadForm() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;
    const Color primaryColor = Color(0xFF2A7A94);

    // استخراج البيانات مع قيم افتراضية
    final patientName = selectedRequest!['patient_name'] ?? 'غير محدد';
    final xrayType = selectedRequest!['xray_type'] ?? 'غير محدد';
    final jaw = selectedRequest!['jaw'];
    final side = selectedRequest!['side'];
    final tooth = selectedRequest!['tooth'];
    final createdAt = selectedRequest!['created_at'];
    final uploadCompleted = _uploadedImagesForRequest.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06 > 32 ? 32 : size.width * 0.06,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الطلب
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل طلب الأشعة', 
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('المريض:', patientName),
                    _buildInfoRow('نوع الأشعة:', xrayType),
                    if (jaw != null && jaw.toString().isNotEmpty) 
                      _buildInfoRow('الفك:', jaw.toString()),
                    if (side != null && side.toString().isNotEmpty) 
                      _buildInfoRow('الجهة:', side.toString()),
                    if (tooth != null && tooth.toString().isNotEmpty) 
                      _buildInfoRow('رقم السن:', tooth.toString()),
                    _buildInfoRow('تاريخ الطلب:', _formatDate(createdAt)),
                    
                    // حالة الطلب
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: uploadCompleted ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: uploadCompleted ? Colors.green : Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            uploadCompleted ? Icons.check_circle : Icons.pending,
                            color: uploadCompleted ? Colors.green[700] : Colors.orange[700],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            uploadCompleted ? 'تم رفع الصورة وحفظها' : 'بانتظار رفع الصورة',
                            style: TextStyle(
                              color: uploadCompleted ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // معاينة الصورة
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'صورة الأشعة', 
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: xrayImageBytes != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    xrayImageBytes!, 
                                    height: size.height * 0.25, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: size.height * 0.25,
                                        color: Colors.grey[200],
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.red),
                                            SizedBox(height: 8),
                                            Text('خطأ في تحميل الصورة'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.photo, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              height: size.height * 0.25,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'لم يتم اختيار صورة', 
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // أزرار التحكم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('اختيار من المعرض'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (xrayImageBytes != null)
                          ElevatedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete),
                            label: const Text('إزالة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_loadingUploadedImages)
              const Center(child: CircularProgressIndicator())
            else if (_uploadedImagesForRequest.isNotEmpty)
              _buildUploadedImagesSection(textTheme),
            
            // زر الرفع
            Center(
              child: SizedBox(
                width: size.width * 0.7,
                height: 50,
                child: ElevatedButton(
                  onPressed: (!uploadCompleted && xrayImageBytes != null && !_isUploading) ? _uploadXrayImage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (!uploadCompleted && xrayImageBytes != null) ? primaryColor : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2, 
                                color: Colors.white
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('جاري رفع الصورة...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text('رفع الصورة'),
                          ],
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() { 
                    selectedRequest = null; 
                    xrayImage = null; 
                    xrayImageBytes = null; 
                    _uploadedImagesForRequest = [];
                    _completedRequestId = null;
                    _loadingUploadedImages = false;
                  });
                },
                child: const Text('رجوع إلى قائمة الطلبات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImagesSection(TextTheme textTheme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, color: Color(0xFF2A7A94)),
                const SizedBox(width: 8),
                Text(
                  'الصور المسجلة لهذا الطلب',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_completedRequestId != null)
                  Chip(
                    label: Text('رقم الطلب: $_completedRequestId'),
                    backgroundColor: Colors.green[50],
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _uploadedImagesForRequest.length,
              itemBuilder: (context, idx) {
                final image = _uploadedImagesForRequest[idx];
                return _buildUploadedImageCard(image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImageCard(Map<String, dynamic> image) {
    final imageUrl = (image['image_url'] ?? image['cloudinary_url'] ?? '').toString();
    final xrayType = image['xray_type']?.toString() ?? 'غير محدد';
    final uploadedAt = image['uploaded_at']?.toString() ?? '';
    final studentName = image['student_name']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.photo, color: Colors.grey),
                ),
        ),
        title: Text('نوع الأشعة: $xrayType'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studentName.isNotEmpty) Text('الطالب: $studentName'),
            if (uploadedAt.isNotEmpty) Text('تاريخ الرفع: ${_formatDate(uploadedAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'غير محدد'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'غير محدد';
    
    try {
      final dateStr = date.toString();
      if (dateStr.contains('T')) {
        return dateStr.split('T').first;
      }
      return dateStr.split(' ').first;
    } catch (e) {
      return date.toString();
    }
  }
}
