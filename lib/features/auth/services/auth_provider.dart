import 'package:fsm_app/export.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Ensure it extends ChangeNotifier!
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isOnline = false;
  Timer? _presenceTimer;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOnline => _isOnline;

  // NEW: App boot state tracking
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  // NEW: Constructor to trigger the silent login on boot
  AuthProvider() {
    _checkAutoLogin();
  }

  // NEW: Silent Login Logic
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');

      if (email != null && password != null) {
        // Silently attempt to log in to verify credentials are still valid
        final error = await login(email, password);

        if (error != null) {
          // If silent login fails (e.g., admin changed their password), wipe the saved data
          await prefs.setBool('remember_me', false);
        }
      }
    }

    // Initialization complete, tell the app to render the UI
    _isInitializing = false;
    notifyListeners();
  }

  // --- CORE AUTH METHODS (Restored) ---

  Future<String?> login(String email, String password) async {
    try {
      final data = await ApiClient.getTableData(ApiConstants.tableUsers);
      final users = data.map((json) => UserModel.fromJson(json)).toList();
      final matchedUser = users
          .where((u) => u.email.toLowerCase() == email.toLowerCase())
          .toList();

      if (matchedUser.isEmpty) return 'Email not found in the system.';
      final user = matchedUser.first;

      if (user.password.isEmpty) return 'ACCOUNT_NOT_SETUP';
      if (user.password != password) return 'Incorrect password.';

      _currentUser = user;
      notifyListeners();

      startPresenceTracker(); // Start the network tracking after successful login
      return null;
    } catch (e, stackTrace) {
      // Print the ACTUAL error to your debug console so you can read it!
      print('LOGIN CRASH: $e'); 
      print(stackTrace);
      
      return 'Network error. Please try again.';
    }
  }

  Future<String?> signUp(String email, String newPassword) async {
    try {
      final data = await ApiClient.getTableData(ApiConstants.tableUsers);
      final users = data.map((json) => UserModel.fromJson(json)).toList();
      final matchedUser = users
          .where((u) => u.email.toLowerCase() == email.toLowerCase())
          .toList();

      if (matchedUser.isEmpty) return 'Email not found.';
      final user = matchedUser.first;

      if (user.password.isNotEmpty) {
        return 'Account already set up. Please log in.';
      }

      // NEW SAFEGUARD: Ensure the ID actually parsed correctly from the database
      if (user.userId.isEmpty) {
        return 'Database Error: Could not read User_ID. Check your Google Sheet headers.';
      }

      // Use the detailed update method and aggressively trim hidden spaces
      final errorStr = await ApiClient.updateRecordDetailed(
        ApiConstants.tableUsers,
        'User_ID',
        user.userId.trim(),
        {'Password': newPassword},
      );

      if (errorStr == null) {
        _currentUser = UserModel(
          userId: user.userId,
          role: user.role,
          name: user.name,
          alias: user.alias,
          position: user.position,
          email: user.email,
          password: newPassword,
          contact: user.contact,
          address: user.address,
          hireDate: user.hireDate,
          lastOnline: user.lastOnline,
          photo: user.photo,
          emailVerified: user.emailVerified,
        );
        notifyListeners();
        startPresenceTracker();
        return null; // Success!
      } else {
        // This will display the EXACT server error on your screen
        return 'Server Error: $errorStr';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // --- AUTO SYNC / PRESENCE TRACKER ---

  void startPresenceTracker() {
    _checkPresence();
    _presenceTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkPresence();
    });
  }

  Future<void> _checkPresence() async {
    if (_currentUser == null) return;

    try {
      // PING OUR OWN SERVER TO BYPASS CORS
      final uri = Uri.parse(
        '${ApiConstants.scriptUrl}?action=ping&t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      final bool wasOnline = _isOnline;
      _isOnline = response.statusCode == 200 || response.statusCode == 302;

      if (_isOnline) {
        final lastOnlineStr = DateFormat(
          'dd/MM/yyyy HH:mm:ss',
        ).format(DateTime.now());

        // Update database silently
        await ApiClient.updateRecordDetailed(
          ApiConstants.tableUsers,
          'User_ID',
          _currentUser!.userId,
          {'LastOnline': lastOnlineStr},
        );
      }

      if (wasOnline != _isOnline) notifyListeners();
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  // --- IN-MEMORY PROFILE SYNC ---
  void updateCurrentUser({
    String? alias,  
    String? contact,
    String? email,
    String? address,
    String? password,
    String? photo,
  }) {
    if (_currentUser == null) return;

    // Create a fresh user model with the updated fields, keeping the rest the same
    _currentUser = UserModel(
      userId: _currentUser!.userId,
      role: _currentUser!.role,
      name: _currentUser!.name,
      alias: alias ?? _currentUser!.alias,
      position: _currentUser!.position,
      email: email ?? _currentUser!.email,
      password: password ?? _currentUser!.password,
      contact: contact ?? _currentUser!.contact,
      address: address ?? _currentUser!.address,
      hireDate: _currentUser!.hireDate,
      lastOnline: _currentUser!.lastOnline,
      photo: photo ?? _currentUser!.photo,
      emailVerified: _currentUser!.emailVerified,
    );

    notifyListeners();
  }

  // UPDATE: Wipe persistent memory on explicit logout
  Future<void> logout() async {
    _currentUser = null;
    _isOnline = false;
    _presenceTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');

    notifyListeners();
  }
}

final authProvider = AuthProvider();
