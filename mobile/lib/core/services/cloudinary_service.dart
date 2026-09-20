import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';

/// Service to handle uploading speaker photos and event visuals directly to Cloudinary CDN
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  /// Default Cloudinary cloud configuration for unsigned uploads
  static const String _cloudName = 'dppwz5bll';

  /// Upload an XFile (from gallery or camera) directly to Cloudinary CDN
  /// Returns the secure Cloudinary HTTPS URL (e.g. `https://res.cloudinary.com/...`)
  Future<String?> uploadImage(XFile imageFile, {String folder = 'smarteve/speakers'}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // 1. Direct Cloudinary upload via HTTP REST API using 'unsigned' preset
      try {
        final response = await http.post(
          Uri.parse('https://api.cloudinary.com/v1_1/demo/image/upload'),
          body: {
            'file': base64Image,
            'upload_preset': 'unsigned',
            'folder': folder,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final secureUrl = data['secure_url'] as String?;
          if (secureUrl != null && secureUrl.isNotEmpty) {
            debugPrint("☁️ [Cloudinary CDN Direct] Image uploaded to folder '$folder': $secureUrl");
            return secureUrl;
          }
        } else {
          debugPrint("⚠️ [Cloudinary CDN Direct] API returned status ${response.statusCode}: ${response.body}");
        }
      } catch (e) {
        debugPrint("⚠️ [Cloudinary CDN Direct] Upload attempt error: $e");
      }

      // 2. Secondary Cloudinary endpoint attempt with custom cloud name
      try {
        final response = await http.post(
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
          body: {
            'file': base64Image,
            'upload_preset': 'unsigned',
            'folder': folder,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final secureUrl = data['secure_url'] as String?;
          if (secureUrl != null && secureUrl.isNotEmpty) {
            debugPrint("☁️ [Cloudinary CDN Secondary] Image uploaded successfully: $secureUrl");
            return secureUrl;
          }
        }
      } catch (e) {
        debugPrint("⚠️ [Cloudinary CDN Secondary] Upload error: $e");
      }

      // 3. Fallback to local Node backend API if running
      try {
        final res = await _apiClient.post('/upload/image', {
          'image': base64Image,
          'folder': folder,
        });

        if (res.success && res.data != null && res.data['url'] != null) {
          final url = res.data['url'] as String;
          debugPrint("☁️ [Backend Cloudinary] Image uploaded via backend: $url");
          return url;
        }
      } catch (e) {
        debugPrint("⚠️ [Backend Cloudinary] Upload fallback error: $e");
      }
    } catch (e) {
      debugPrint("⚠️ [CloudinaryService] Fatal error reading image file: $e");
    }

    return null;
  }

  /// Prompts user to pick an image from gallery or camera and uploads to Cloudinary
  Future<String?> pickAndUploadSpeakerPhoto({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file == null) return null;
      return await uploadImage(file);
    } catch (e) {
      debugPrint("⚠️ Error picking and uploading photo: $e");
    }
    return null;
  }
}
