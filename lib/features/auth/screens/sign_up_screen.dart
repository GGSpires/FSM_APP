import 'package:fsm_app/export.dart';

class SignUpScreen extends StatefulWidget {
  final String? prefilledEmail;
  const SignUpScreen({super.key, this.prefilledEmail});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 1;
  late TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefilledEmail ?? '');
  }

  Future<void> _sendVerificationEmail() async {
    final emailInput = _emailCtrl.text.trim();
    if (emailInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter an email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiClient.getTableData(ApiConstants.tableUsers);
      final users = data.map((json) => UserModel.fromJson(json)).toList();
      final matchedUsers = users
          .where((u) => u.email.toLowerCase() == emailInput.toLowerCase())
          .toList();

      if (matchedUsers.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Email not found in the database. Your admin must add you first.';
        });
        return;
      }

      final user = matchedUsers.first;

      if (user.password.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'An account with this email already has a password. Please go back and log in.';
        });
        return;
      }

      final errorStr = await ApiClient.requestEmailVerification(emailInput);

      setState(() => _isLoading = false);

      if (errorStr == null) {
        setState(() => _currentStep = 2);
      } else {
        setState(() => _errorMessage = 'Failed to send email: $errorStr');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Could not connect to the database.';
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    final data = await ApiClient.getTableData(ApiConstants.tableUsers);
    final users = data.map((json) => UserModel.fromJson(json)).toList();
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == _emailCtrl.text.trim().toLowerCase(),
    );

    setState(() => _isLoading = false);

    // ADDED .toUpperCase() for safety
    if (user.emailVerified.toUpperCase() == 'ALLOW') {
      setState(() {
        _currentStep = 3;
        _errorMessage = null;
      });
    } else if (user.emailVerified.toUpperCase() == 'DENY') {
      setState(() {
        _errorMessage = 'Verification was denied. Contact Admin.';
        _currentStep = 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status is currently: ${user.emailVerified}. Waiting for ALLOW...',
          ),
        ),
      );
    }
  }

  Future<void> _savePassword() async {
    if (_passwordCtrl.text.length < 4) {
      setState(() => _errorMessage = 'Password must be at least 4 characters.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final error = await authProvider.signUp(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    setState(() => _isLoading = false);

    if (error == null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password created! Please log in.')),
      );
    } else {
      setState(() => _errorMessage = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_currentStep == 1) ...[
                const Text(
                  'Step 1: Verify Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Registered Email',
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _sendVerificationEmail,
                        child: const Text('SEND VERIFICATION LINK'),
                      ),
              ],

              if (_currentStep == 2) ...[
                const Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Check your Inbox',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a secure link to ${_emailCtrl.text}. Click ALLOW in the email, then return here.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _checkVerificationStatus,
                        child: const Text('I HAVE VERIFIED MY EMAIL'),
                      ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Text('Use a different email'),
                ),
              ],

              if (_currentStep == 3) ...[
                const Text(
                  'Step 3: Create Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'New Password (Min 4 chars)',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _savePassword(),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _savePassword,
                        child: const Text('SAVE PASSWORD'),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
