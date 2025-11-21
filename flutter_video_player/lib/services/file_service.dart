import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/instruction_model.dart';
import 'asset_checker.dart';

class FileService {
  /// Read instructions.json from assets
  Future<InstructionsResponse?> readInstructionsFromAssets() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/instructions.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return InstructionsResponse.fromJson(json);
    } catch (e) {
      print('Error reading instructions from assets: $e');
      return null;
    }
  }

  /// Read instructions.json from local storage
  Future<InstructionsResponse?> readInstructionsFromLocal() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/instructions.json');
      if (!await file.exists()) {
        return null;
      }
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return InstructionsResponse.fromJson(json);
    } catch (e) {
      print('Error reading instructions from local: $e');
      return null;
    }
  }

  /// Save instructions.json to local storage
  Future<bool> saveInstructionsToLocal(InstructionsResponse instructions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/instructions.json');
      final jsonString = jsonEncode(instructions.toJson());
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      print('Error saving instructions to local: $e');
      return false;
    }
  }

  /// Get video file path
  Future<String?> getVideoPath(String folder, String fileName) async {
    try {
      final assetPath = 'assets/videos/$folder/$fileName';
      print('Checking asset path: $assetPath');
      
      // First check if asset exists in manifest
      final exists = await AssetChecker.assetExists(assetPath);
      if (exists) {
        print('Asset found in manifest: $assetPath');
        // Try to load it to verify
        try {
          final data = await rootBundle.load(assetPath);
          if (data.buffer.lengthInBytes > 0) {
            print('Asset loaded successfully: $assetPath (${data.buffer.lengthInBytes} bytes)');
            return assetPath;
          }
        } catch (e) {
          print('Asset exists in manifest but failed to load: $e');
        }
      } else {
        print('Asset NOT found in manifest: $assetPath');
        // List all video assets for debugging
        final allAssets = await AssetChecker.listAssets();
        final videoAssets = allAssets.where((a) => a.contains('videos')).toList();
        print('Available video assets: $videoAssets');
      }
      
      // If not in assets, try local storage
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/videos/$folder/$fileName');
      print('Checking local file: ${file.path}');
      if (await file.exists()) {
        print('Local file found at: ${file.path}');
        return file.path;
      }
      print('File not found in local storage either');
      return null;
    } catch (e) {
      print('Error getting video path: $e');
      return null;
    }
  }

  /// Check if video file exists
  Future<bool> videoFileExists(String folder, String fileName) async {
    final path = await getVideoPath(folder, fileName);
    return path != null;
  }

  /// Calculate hash of instructions for change detection
  String calculateHash(dynamic jsonData) {
    final jsonString = jsonEncode(jsonData);
    return jsonString.hashCode.toString();
  }
}

