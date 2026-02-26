import 'package:fsm_app/export.dart';
import 'package:intl/intl.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  late TextEditingController _aliasCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;

  bool _isLoading = false;
  String _base64Image = '';
  String? _stagedNewPassword; // Holds the new password if changed via the popup

  @override
  void initState() {
    super.initState();
    final user = authProvider.currentUser;
    _aliasCtrl = TextEditingController(text: user?.alias ?? '');
    _contactCtrl = TextEditingController(text: user?.contact ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _base64Image = user?.photo ?? '';
  }

  // IMAGE PICKER LOGIC
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 15, // Aggressive compression
      maxWidth: 200, // Scaled down
      maxHeight: 200,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);

      // Safety check: Is it too big for Google Sheets?
      if (b64.length > 49000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image is too large for the database. Please pick a simpler photo.',
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _base64Image = b64;
      });
    }
  }

  // PASSWORD POPUP LOGIC
  void _showPasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (localError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  TextField(
                    controller: currentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final currentUser = authProvider.currentUser;
                    if (currentCtrl.text != currentUser?.password) {
                      setDialogState(
                        () => localError = 'Current password is incorrect.',
                      );
                      return;
                    }
                    if (newCtrl.text.isEmpty ||
                        newCtrl.text != confirmCtrl.text) {
                      setDialogState(
                        () => localError =
                            'New passwords do not match or are empty.',
                      );
                      return;
                    }

                    // Stage the password to be saved when the main "Update Profile" button is pressed
                    setState(() => _stagedNewPassword = newCtrl.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password change staged. Press Update Profile to save.',
                        ),
                      ),
                    );
                  },
                  child: const Text('CONFIRM'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // SAVE TO DATABASE
  Future<void> _updateProfile() async {
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> updateData = {
      'Alias': _aliasCtrl.text,
      'Contact': _contactCtrl.text,
      'Email': _emailCtrl.text,
      'Address': _addressCtrl.text,
      'Photo': _base64Image,
    };

    if (_stagedNewPassword != null) {
      updateData['Password'] = _stagedNewPassword;
    }

    // Call the detailed update so we bypass CORS and get exact errors if it fails
    final errorStr = await ApiClient.updateRecordDetailed(
      ApiConstants.tableUsers,
      'User_ID',
      user.userId,
      updateData,
    );

    setState(() => _isLoading = false);

    if (errorStr == null && mounted) {
      // 1. UPDATE LOCAL MEMORY SO THE PASSWORD CHECKER WORKS IMMEDIATELY
      authProvider.updateCurrentUser(
        alias: _aliasCtrl.text,
        contact: _contactCtrl.text,
        email: _emailCtrl.text,
        address: _addressCtrl.text,
        password: _stagedNewPassword, // Pushes the new password into memory
        photo: _base64Image,
      );

      // 2. Clear the staged password so it doesn't get re-submitted accidentally
      _stagedNewPassword = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $errorStr')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        backgroundImage: () {
                          try {
                            // 1. Strip all whitespaces/newlines
                            String cleanBase64 = _base64Image.replaceAll(
                              RegExp(r'\s+'),
                              '',
                            );

                            // Ignore the literal "CellImage" text if you manually inserted an image in Sheets
                            if (cleanBase64.length > 100) {
                              // 2. REPAIR GOOGLE SHEETS TRUNCATION: Add missing padding '='
                              while (cleanBase64.length % 4 != 0) {
                                cleanBase64 += '=';
                              }

                              return MemoryImage(base64Decode(cleanBase64));
                            }
                          } catch (e) {
                            print('Image Decode Error: $e');
                            return null;
                          }
                          return null;
                        }(),
                        // Only show the default Icon if there is no valid image string
                        child:
                            (_base64Image.isEmpty || _base64Image.length < 100)
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).primaryColor,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  // ignore: unnecessary_non_null_assertion
                  '${user?.position} | Hired: ${user?.hireDate != null ? DateFormat('yyyy-MM-dd').format(user!.hireDate!) : "N/A"}\nID: ${user?.userId}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Personal Info Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _aliasCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Alias (Display Name)',
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Home Address',
                            prefixIcon: Icon(Icons.home),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Security Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock),
                          title: const Text('Change Password'),
                          subtitle: Text(
                            _stagedNewPassword != null
                                ? 'Password change pending save'
                                : 'Tap to update your password',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: _showPasswordDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _updateProfile,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'UPDATE PROFILE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
