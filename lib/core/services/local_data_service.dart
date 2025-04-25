import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appp/features/reports/data/reports_data_provider.dart';

class LocalDataService {
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    const keepKeys = {'theme_mode'};
    for (final key in prefs.getKeys()) {
      if (!keepKeys.contains(key)) await prefs.remove(key);
    }

    ReportsDataProvider.clearCache();
  }
}