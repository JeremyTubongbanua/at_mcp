import 'dart:io';
import 'dart:convert';

/// Manager for AT Protocol virtual environment operations
class VirtualenvManager {
  static const String containerName = 'atsign_virtualenv';
  static const String rootDomain = 'vip.ve.atsign.zone';
  static const int rootPort = 64;
  static const String dockerImage = 'atsigncompany/virtualenv:vip';
  
  // Port mappings for the container
  static const Map<int, int> portMappings = {
    64: 64,      // Root server
    9001: 9001,  // Supervisor web interface
  };
  
  /// Checks if Docker is running and available
  static Future<bool> isDockerRunning() async {
    try {
      final result = await Process.run('docker', ['version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if the virtual environment container is running
  static Future<bool> isVirtualenvRunning() async {
    try {
      final result = await Process.run('docker', ['ps', '--filter', 'name=$containerName', '--format', '{{.Names}}']);
      return result.stdout.toString().contains(containerName);
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if container exists (running or stopped)
  static Future<bool> doesContainerExist() async {
    try {
      final result = await Process.run('docker', [
        'ps', '-a', '--filter', 'name=$containerName', '--format', '{{.Names}}'
      ]);
      return result.stdout.toString().contains(containerName);
    } catch (e) {
      return false;
    }
  }
  
  /// Adds vip.ve.atsign.zone to /etc/hosts if not already present
  static Future<bool> setupHostsFile() async {
    try {
      final hostsFile = File('/etc/hosts');
      if (!await hostsFile.exists()) {
        print('Warning: /etc/hosts file not found');
        return false;
      }
      
      final hostsContent = await hostsFile.readAsString();
      if (hostsContent.contains('vip.ve.atsign.zone')) {
        print('vip.ve.atsign.zone already in /etc/hosts');
        return true;
      }
      
      // Try to add the entry
      final process = await Process.run('sudo', [
        'sh', '-c',
        'echo "127.0.0.1 vip.ve.atsign.zone" >> /etc/hosts'
      ]);
      
      if (process.exitCode == 0) {
        print('Added vip.ve.atsign.zone to /etc/hosts');
        return true;
      } else {
        print('Warning: Could not add vip.ve.atsign.zone to /etc/hosts: ${process.stderr}');
        return false;
      }
    } catch (e) {
      print('Error setting up hosts file: $e');
      return false;
    }
  }
  
  /// Starts the virtual environment using direct docker commands
  static Future<ProcessResult> startVirtualenv() async {
    // Setup hosts file first
    await setupHostsFile();
    
    // Check if container already exists
    if (await doesContainerExist()) {
      // Container exists, try to start it
      final startResult = await Process.run('docker', ['start', containerName]);
      if (startResult.exitCode == 0) {
        return startResult;
      }
      // If start failed, remove the container and create a new one
      await Process.run('docker', ['rm', '-f', containerName]);
    }
    
    // Build port mapping arguments
    final portArgs = <String>[];
    for (final entry in portMappings.entries) {
      portArgs.addAll(['-p', '${entry.key}:${entry.value}']);
    }
    
    // Run the container with proper configuration
    return await Process.run('docker', [
      'run',
      '-d',
      '--name', containerName,
      '--add-host', 'vip.ve.atsign.zone:127.0.0.1',
      ...portArgs,
      dockerImage,
    ]);
  }
  
  /// Stops the virtual environment
  static Future<ProcessResult> stopVirtualenv() async {
    if (await doesContainerExist()) {
      return await Process.run('docker', ['stop', containerName]);
    } else {
      // Return a successful result if container doesn't exist
      return ProcessResult(0, 0, 'Container $containerName does not exist', '');
    }
  }
  
  /// Removes the virtual environment container completely
  static Future<ProcessResult> removeVirtualenv() async {
    if (await doesContainerExist()) {
      return await Process.run('docker', ['rm', '-f', containerName]);
    } else {
      return ProcessResult(0, 0, 'Container $containerName does not exist', '');
    }
  }
  
  /// Runs pkamLoad in the virtual environment
  static Future<ProcessResult> runPkamLoad() async {
    return await Process.run('docker', [
      'exec', containerName, 'supervisorctl', 'start', 'pkamLoad'
    ]);
  }
  
  /// Tests if the virtual environment is ready by querying an atSign
  static Future<String?> testAtSignResolution(String atSign) async {
    try {
      final socket = await Socket.connect(rootDomain, rootPort);
      
      // Send the atSign query
      socket.write('$atSign\\n');
      
      // Read the response
      final buffer = StringBuffer();
      await for (final data in socket) {
        buffer.write(utf8.decode(data));
        final response = buffer.toString();
        if (response.contains('\\n') || response.contains('vip.ve.atsign.zone:')) {
          socket.destroy();
          return response.trim();
        }
      }
      
      socket.destroy();
      return buffer.toString().trim();
    } catch (e) {
      return null;
    }
  }
  
  /// Gets the status of all services in the virtual environment
  static Future<Map<String, dynamic>> getVirtualenvStatus() async {
    final status = <String, dynamic>{};
    
    // Check Docker
    status['dockerRunning'] = await isDockerRunning();
    
    // Check container
    status['containerRunning'] = await isVirtualenvRunning();
    
    // Check atSign resolution
    if (status['containerRunning']) {
      final testResult = await testAtSignResolution('gary');
      status['atSignResolution'] = testResult;
      status['rootServerReady'] = testResult?.contains('vip.ve.atsign.zone:') ?? false;
    }
    
    return status;
  }
  
  /// Gets logs from the virtual environment container
  static Future<String> getContainerLogs({int? tail}) async {
    try {
      final args = ['logs'];
      if (tail != null) {
        args.addAll(['--tail', tail.toString()]);
      }
      args.add(containerName);
      
      final result = await Process.run('docker', args);
      return result.stdout.toString();
    } catch (e) {
      return 'Error getting logs: $e';
    }
  }
}