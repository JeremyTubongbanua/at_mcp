import 'at_key_manager.dart';

/// Service for handling AT Protocol onboarding operations
class AtOnboardingService {
  /// Onboards an atSign using CRAM authentication (placeholder implementation)
  static Future<void> onboardWithCram({
    required String atSign,
    String? cramKey,
    String rootDomain = 'localhost',
    int rootPort = 64,
    String? keysFilePath,
  }) async {
    try {
      // Get CRAM key if not provided
      final actualCramKey = cramKey ?? AtKeyManager.getCramKey(atSign);
      if (actualCramKey == null) {
        throw Exception('No CRAM key available for $atSign');
      }
      
      // For now, just simulate the onboarding process
      // In a full implementation, this would use the AT Protocol client
      print('Simulating onboarding for $atSign with CRAM key');
      print('Root server: $rootDomain:$rootPort');
      print('Keys file path: ${keysFilePath ?? '${atSign}_key.atKeys'}');
      
      // Download PKAM keys as part of onboarding
      await AtKeyManager.downloadPkamKeys(atSign, targetPath: keysFilePath);
      
      print('Successfully onboarded $atSign');
    } catch (e) {
      throw Exception('Error onboarding $atSign: $e');
    }
  }
  
  /// Checks if an atSign is already onboarded (has keys file)
  static Future<bool> isOnboarded(String atSign, {String? keysFilePath}) async {
    final actualKeysPath = keysFilePath ?? '${atSign}_key.atKeys';
    return await AtKeyManager.validatePkamKeyFile(actualKeysPath);
  }
  
  /// Sets up multiple atSigns for development
  static Future<Map<String, bool>> setupDevelopmentAtSigns({
    List<String>? atSigns,
    String rootDomain = 'localhost',
    int rootPort = 64,
    String? keysDirectory,
  }) async {
    final targetAtSigns = atSigns ?? ['@gary', '@xavier', '@alice', '@bob'];
    final results = <String, bool>{};
    
    // Download keys first
    try {
      await AtKeyManager.downloadAllCommonKeys(targetDirectory: keysDirectory);
    } catch (e) {
      print('Warning: Could not download some keys: $e');
    }
    
    // Process each atSign
    for (final atSign in targetAtSigns) {
      try {
        final keysPath = keysDirectory != null 
            ? '$keysDirectory/${atSign}_key.atKeys'
            : '${atSign}_key.atKeys';
            
        // Check if already has keys
        if (await isOnboarded(atSign, keysFilePath: keysPath)) {
          print('$atSign already has keys');
          results[atSign] = true;
          continue;
        }
        
        // Simulate onboarding
        await onboardWithCram(
          atSign: atSign,
          rootDomain: rootDomain,
          rootPort: rootPort,
          keysFilePath: keysPath,
        );
        
        results[atSign] = true;
        print('Successfully set up $atSign');
      } catch (e) {
        print('Failed to set up $atSign: $e');
        results[atSign] = false;
      }
    }
    
    return results;
  }
}