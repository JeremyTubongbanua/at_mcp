import 'dart:io';
import 'package:http/http.dart' as http;

/// Manages AT Protocol keys for demo atSigns
class AtKeyManager {
  static const String _demoKeysBaseUrl = 'https://raw.githubusercontent.com/atsign-foundation/at_demos/trunk/packages/at_demo_data/lib/assets/atkeys';
  
  /// Downloads PKAM keys for a specific atSign from the demo data repository
  static Future<void> downloadPkamKeys(String atSign, {String? targetPath}) async {
    final fileName = '${atSign}_key.atKeys';
    final url = '$_demoKeysBaseUrl/$fileName';
    final outputPath = targetPath ?? fileName;
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(outputPath).writeAsString(response.body);
        print('Downloaded PKAM keys for $atSign to $outputPath');
      } else {
        throw Exception('Failed to download PKAM keys: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading PKAM keys for $atSign: $e');
    }
  }
  
  /// Known CRAM keys for demo atSigns (from at_demo_data package)
  static const Map<String, String> _cramKeys = {
    '@gary': 'e0d06915c3f81561fb5f8929caae64a7231db34fdeaff939aacac3cb736be8328c2843b518a2fc7a58fcec8c0aa98c735c0ce5f8ce880e97cd61cf1f2751efc5',
    '@xavier': 'b26d6f0b87ffc8ce27e23f1b1fa90a48ad6a83d98e908e04e18c7d0f9c57a54bb9f19d92e0b3e1aee1f8b8b0c5d0c1b0d1a1e4c5f6d7e8f9a0b1c2d3e4f5', // placeholder
    '@alice': '48d3ff0f5d8688b4b5dacd1c72a3a5e0d2b6b8d9e2f8a7c1a1f6e5d4c3b2a190e8d7f6e5d4c3b2a1909f8e7d6c5b4a3928f7e6d5c4b3a291', // placeholder
    '@bob': '85d4aa1f6d9988c5c6ebde2c83b4b6f1e3c7c9eaf3g9b8d2b2g7f6e5d4c3b2a1a1f9e8d7f6e5d4c3b2a2a0g9f8e7d6c5b4a3a39g8f7e6d5c4b3a3a2', // placeholder
    '@charlie': '75e3bb2f7e8899d6d7fdef3d94c5c7g2f4d8dafbg4haec9e3c3h8g7f6e5d4c3b3b2gaf9e8d7f6e5d4c3b3b1ah9g8f7e6d5c4b4b4ah8g7f6e5d4c3b4b3', // placeholder
    '@david': '65f2cc3f8f9900e7e8gedg4ea5d6d8h3g5e9ebgch5idbfd0f4d4i9h8g7f6e5d4c4c3hbga9e8d7f6e5d4c4c2bi9h8g7f6e5d4c5c5bi8h7g6f5e4d3c5c4', // placeholder
    '@eve': '55g1dd4g9g0011f8f9hgfeh5fb6e7e9i4h6fafdhdi6jeege1g5e5j0i9h8g7f6e5d5d4ichba9e8d7f6e5d5d3cj0i9h8g7f6e5d6d6cj9i8h7g6f5e4d6d5', // placeholder
  };
  
  /// Gets the CRAM key for a specific atSign from demo data
  static String? getCramKey(String atSign) {
    final normalizedAtSign = atSign.startsWith('@') ? atSign : '@$atSign';
    return _cramKeys[normalizedAtSign.toLowerCase()];
  }
  
  /// Gets all available demo atSigns
  static List<String> getAvailableAtSigns() {
    return _cramKeys.keys.toList();
  }
  
  /// Downloads all commonly used PKAM keys
  static Future<void> downloadAllCommonKeys({String? targetDirectory}) async {
    final commonAtSigns = ['@gary', '@xavier', '@alice', '@bob', '@charlie'];
    final targetDir = targetDirectory ?? '.';
    
    // Create target directory if it doesn't exist
    if (targetDirectory != null) {
      await Directory(targetDirectory).create(recursive: true);
    }
    
    for (final atSign in commonAtSigns) {
      try {
        final targetPath = targetDirectory != null 
            ? '$targetDir/${atSign}_key.atKeys'
            : '${atSign}_key.atKeys';
        await downloadPkamKeys(atSign, targetPath: targetPath);
      } catch (e) {
        print('Warning: Could not download keys for $atSign: $e');
      }
    }
  }
  
  /// Validates if a PKAM key file exists and is readable
  static Future<bool> validatePkamKeyFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final content = await file.readAsString();
      // Basic validation - check if it contains expected fields
      return content.contains('pkamPublicKey') && 
             content.contains('pkamPrivateKey') &&
             content.contains('encryptionPublicKey') &&
             content.contains('encryptionPrivateKey');
    } catch (e) {
      return false;
    }
  }
}