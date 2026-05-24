import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static final Map<String, String> environments = {
    'Production': 'http://103.157.27.213/api/v1',
    'Staging': 'https://staging.devora.id/api/v1',
    'Custom': '',
  };

  static String selectedEnv = 'Production';
  static String customIp = '';
  static String customPort = '';
  static String baseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    selectedEnv = prefs.getString('api_env') ?? 'Production';
    customIp = prefs.getString('api_custom_ip') ?? '';
    customPort = prefs.getString('api_custom_port') ?? '8000';
    
    _updateBaseUrl();
  }

  static Future<void> saveSetting(String env, {String ip = '', String port = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    
    selectedEnv = env;
    await prefs.setString('api_env', env);
    
    if (env == 'Custom') {
      customIp = ip;
      customPort = port.isNotEmpty ? port : '8000';
      await prefs.setString('api_custom_ip', customIp);
      await prefs.setString('api_custom_port', customPort);
    }
    
    _updateBaseUrl();
  }

  static void _updateBaseUrl() {
    if (selectedEnv == 'Custom') {
      baseUrl = 'http://$customIp:$customPort/api/v1';
    } else {
      baseUrl = environments[selectedEnv]!;
    }
    debugPrint("🚀 API URL changed to: $baseUrl");
  }
}
