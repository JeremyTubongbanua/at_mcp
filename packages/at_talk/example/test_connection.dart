import 'package:at_talk/at_talk.dart';

Future<void> main() async {
  print('Testing AT Talk connectivity...');
  
  try {
    // Test with @gary
    final garyClient = AtTalkClient('@gary');
    print('Initializing @gary client...');
    await garyClient.initialize();
    print('✓ @gary client initialized successfully');
    
    // Test with @xavier
    final xavierClient = AtTalkClient('@xavier');
    print('Initializing @xavier client...');
    await xavierClient.initialize();
    print('✓ @xavier client initialized successfully');
    
    print('\nAll clients connected successfully!');
    print('You can now run the interactive AT Talk application.');
    
  } catch (e) {
    print('❌ Error during initialization: $e');
  }
}