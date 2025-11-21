import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/instruction_model.dart';

class StorageService {
  static const String _instructionsKey = 'last_applied_instructions';
  static const String _instructionsHashKey = 'instructions_hash';

  /// Save the last applied instructions
  Future<void> saveInstructions(InstructionsResponse instructions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(instructions.toJson());
    await prefs.setString(_instructionsKey, jsonString);
  }

  /// Get the last applied instructions
  Future<InstructionsResponse?> getLastInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_instructionsKey);
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return InstructionsResponse.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Save hash of instructions to detect changes
  Future<void> saveInstructionsHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_instructionsHashKey, hash);
  }

  /// Get the last saved instructions hash
  Future<String?> getLastInstructionsHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_instructionsHashKey);
  }

  /// Clear all stored instructions
  Future<void> clearInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_instructionsKey);
    await prefs.remove(_instructionsHashKey);
  }
}

