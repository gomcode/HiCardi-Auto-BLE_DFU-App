import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dfu_history_item.dart';
import '../../core/constants/dfu_constants.dart';

class PreferencesRepository {
  static Future<void> saveFirmwarePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(DfuConstants.sharedPrefsKeyFirmwarePath, path);
  }

  static Future<String?> loadFirmwarePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(DfuConstants.sharedPrefsKeyFirmwarePath);
  }

  static Future<void> saveDfuHistory(List<DfuHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(history.map((item) => item.toJson()).toList());
    await prefs.setString(DfuConstants.sharedPrefsKeyDfuHistory, historyJson);
  }

  static Future<List<DfuHistoryItem>> loadDfuHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(DfuConstants.sharedPrefsKeyDfuHistory);

    if (historyJson == null) return [];

    final List<dynamic> historyList = jsonDecode(historyJson);
    return historyList.map((item) => DfuHistoryItem.fromJson(item)).toList();
  }

  static Future<void> clearDfuHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(DfuConstants.sharedPrefsKeyDfuHistory);
  }
}