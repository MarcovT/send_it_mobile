import 'package:shared_preferences/shared_preferences.dart';

class TermsService {
  static const String _termsAcceptedKey = 'terms_accepted';
  
  // Check if user has accepted terms
  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }
  
  // Mark terms as accepted
  static Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, true);
  }
  
  // Reset terms acceptance (for testing purposes)
  static Future<void> resetTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_termsAcceptedKey);
  }
}