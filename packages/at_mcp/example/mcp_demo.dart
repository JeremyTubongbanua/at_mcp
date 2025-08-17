import 'package:at_mcp/at_mcp.dart';

/// Demo script showing AT MCP library functionality
Future<void> main() async {
  print('=== AT MCP Library Demo ===\n');
  
  // Demo 1: AT Key Manager
  print('1. AT Key Manager Demo');
  print('Available atSigns: ${AtKeyManager.getAvailableAtSigns()}');
  
  final garyCramKey = AtKeyManager.getCramKey('@gary');
  print('CRAM key for @gary: ${garyCramKey?.substring(0, 20)}...');
  
  print('Downloading PKAM keys for @gary...');
  try {
    await AtKeyManager.downloadPkamKeys('@gary', targetPath: 'demo_gary_key.atKeys');
    print('✓ Successfully downloaded @gary keys');
  } catch (e) {
    print('✗ Error downloading keys: $e');
  }
  
  // Demo 2: Virtual Environment Manager
  print('\n2. Virtual Environment Manager Demo');
  
  final dockerRunning = await VirtualenvManager.isDockerRunning();
  print('Docker running: $dockerRunning');
  
  final containerRunning = await VirtualenvManager.isVirtualenvRunning();
  print('Virtual environment running: $containerRunning');
  
  final status = await VirtualenvManager.getVirtualenvStatus();
  print('Full status: $status');
  
  // Demo 3: Onboarding Service
  print('\n3. Onboarding Service Demo');
  
  final isOnboarded = await AtOnboardingService.isOnboarded('@gary');
  print('@gary onboarded: $isOnboarded');
  
  if (!isOnboarded) {
    print('Simulating onboarding for @gary...');
    try {
      await AtOnboardingService.onboardWithCram(atSign: '@gary');
      print('✓ Onboarding simulation completed');
    } catch (e) {
      print('✗ Onboarding simulation failed: $e');
    }
  }
  
  print('\n=== Demo Complete ===');
}