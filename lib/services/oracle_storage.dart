import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dcs/services/auth_http_client.dart' as http;
import 'package:image_picker/image_picker.dart';

const String oracleBaseUrl =
    "https://objectstorage.me-dubai-1.oraclecloud.com/p/EnHC2-XDTUaf5rSyR8HF_X6o0wgOSCHeH0SypAfgNgkWeN61BNF75LV53SYbwzKg/n/ax72nxrgllaw/b/dcs-aauj/o/";

Future<String?> uploadImageToOracle(dynamic image, {String? fileName}) async {
  try {
    final safeFileName =
        fileName ?? 'image-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final url = Uri.parse('$oracleBaseUrl$safeFileName');

    Uint8List? bytes;

    if (image is Uint8List) {
      bytes = image;
    } else if (image is File) {
      bytes = await image.readAsBytes();
    } else if (image is XFile) {
      bytes = await image.readAsBytes();
    } else {
      debugPrint('Unsupported image type for Oracle upload: ${image.runtimeType}');
      return null;
    }

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/octet-stream'},
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return url.toString();
    }

    debugPrint(
      'Oracle upload failed: ${response.statusCode} - ${response.body}',
    );
    return null;
  } catch (e) {
    debugPrint('Oracle upload error: $e');
    return null;
  }
}
