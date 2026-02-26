import 'package:fsm_app/export.dart'; // Ensure this points to your barrel file

final themeProvider = ThemeProvider();

void main() async {
  // Required when reading SharedPreferences and PackageInfo on app boot
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize App Info before the app starts
  await AppInfo.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: authProvider,
          builder: (context, _) {
            return MaterialApp(
              // Use the bio loaded from AppInfo
              title: AppInfo.appDescription,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: _getInitialScreen(),
            );
          },
        );
      },
    );
  }

  Widget _getInitialScreen() {
    if (authProvider.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// --- FIXED APP INFO CLASS ---
class AppInfo {
  static String appVersion = 'Loading Version...';
  static String appDescription = 'Loading Description...';
  static String appName = 'Loading Name...';

  static Future<void> init() async {
    try {
      //  final info = await PackageInfo.fromPlatform();

      // 1. Load the file as a string
      final String yamlString = await rootBundle.loadString('pubspec.yaml');

      // 2. Parse the YAML content
      final dynamic yamlMap = loadYaml(yamlString);

      // 3. Store the variables
      appDescription = yamlMap['description'] ?? 'No description';
      appName = yamlMap['name'] ?? 'No name';
      appVersion = yamlMap['version'] ?? '0.0.0';
    } catch (e) {
      print('Error initializing AppInfo: $e');
      appVersion = 'Mock - Version 1.0.0';
      appDescription = 'Mock - FSM App';
      appName = 'Mock - FSM';
    }
  }
}
