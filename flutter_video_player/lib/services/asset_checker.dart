import 'package:flutter/services.dart';
import 'dart:convert';

class AssetChecker {
  /// List all available assets (for debugging)
  static Future<List<String>> listAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      return manifestMap.keys.toList();
    } catch (e) {
      print('Error loading asset manifest: $e');
      return [];
    }
  }

  /// Check if a specific asset exists
  static Future<bool> assetExists(String path) async {
    try {
      final assets = await listAssets();
      return assets.contains(path);
    } catch (e) {
      return false;
    }
  }
}

