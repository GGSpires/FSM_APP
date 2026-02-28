import 'package:fsm_app/export.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light mode

  ThemeProvider() {
    _loadThemeFromStorage();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // READ FROM LOCAL STORAGE ON STARTUP
  Future<void> _loadThemeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false (light mode) if no preference is found
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // WRITE TO LOCAL STORAGE ON TOGGLE
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

      

    // Save the new choice to permanent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);

    notifyListeners(); // Tells the app to rebuild with the new theme
  }
}
