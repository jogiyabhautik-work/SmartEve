import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';

class CloudinaryService {
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

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

      final Uint8List bytes = await file.readAsBytes();
      final String base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final res = await _apiClient.post('/upload/image', {
        'image': base64Image,
        'folder': 'smarteve/speakers',
      });

      if (res.success && res.data != null) {
        return res.data['url'] as String?;
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }
}
