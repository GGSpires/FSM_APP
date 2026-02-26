import 'package:fsm_app/export.dart';

// Create a global key so the AppBar can trigger the fetch function inside the child screen
final GlobalKey<JobCardListScreenState> jobCardListKey =
    GlobalKey<JobCardListScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    JobCardListScreen(key: jobCardListKey), // Attach the key here

    const StockInventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;
    // Listen to AuthProvider for Drawer data
    return ListenableBuilder(
      listenable: authProvider,
      builder: (context, child) {
        final user = authProvider.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppInfo.appDescription),
            actions: [
              // Network Status Indicator
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Icon(
                    authProvider.isOnline ? Icons.wifi : Icons.wifi_off,
                    color: authProvider.isOnline
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),

              // New Resync Button
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync Data',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing data from server...'),
                    ),
                  );
                  // Triggers the API call inside the Job Card list
                  jobCardListKey.currentState?.fetchJobCards();
                },
              ),

              // Theme Toggle
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
              ),
            ],
          ),
          // Side Drawer Implementation
          drawer: Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  accountName: Text(
                    user?.name ?? 'Not Logged In',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    '${user?.position ?? 'Role'} | ID: ${user?.userId ?? 'N/A'}',
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    // 1. Attempt to display the image background
                    backgroundImage: (user != null && user.photo.isNotEmpty)
                        ? () {
                            try {
                              // Clean up potential Google Sheet artifacts
                              String cleanBase64 = user.photo.replaceAll(
                                RegExp(r'\s+'),
                                '',
                              );

                              // Basic check to ignore placeholders like "CellImage"
                              if (cleanBase64.length > 100) {
                                // Safety padding fix just in case
                                while (cleanBase64.length % 4 != 0) {
                                  cleanBase64 += '=';
                                }
                                return MemoryImage(base64Decode(cleanBase64));
                              }
                            } catch (e) {
                              // If decoding fails, return null so the fallback child shows
                              return null;
                            }
                            return null;
                          }()
                        : null,

                    // 2. Fallback Child: Show Initials if no valid image exists
                    child:
                        (user == null ||
                            user.photo.isEmpty ||
                            user.photo.length <= 100)
                        ? Text(
                            user?.alias.isNotEmpty == true
                                ? user!.alias[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null, // Child must be null if backgroundImage is showing
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context); // Close the side drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserSettingsScreen(),
                      ),
                    );
                  },
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    authProvider.logout();
                    // Will route back to Login Screen later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully.')),
                    );
                    Navigator.pop(context); // Close drawer
                  },
                ),
                //Small footer with app version
                Divider(color: Colors.grey[400], thickness: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${AppInfo.appName}\n${AppInfo.appVersion}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Job Cards',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'Stock',
              ),
            ],
          ),
        );
      },
    );
  }
}
