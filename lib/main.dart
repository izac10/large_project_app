// main.dart
import 'package:flutter/material.dart';
import 'Pages/Events.dart';
import 'Pages/Profile.dart';
import 'Pages/Organizations.dart';
import 'Pages/Calender.dart';
import 'services/session.dart';
import 'Widgets/AuthDialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Organizations',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF3C84C),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 2; // Start at Organizations (Home)

  // List of pages for bottom navigation
  final List<Widget> _pages = const [
    CalendarPage(),        // Index 0: Calendar
    ProfilePage(),         // Index 1: Profile
    OrganizationsPage(),   // Index 2: Home/Organizations
    EventsPage(),          // Index 3: Events
  ];

  void _handleLoginLogout() async {
    if (Session.isLoggedIn) {
      // Show logout confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          Session.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully')),
          );
        }
      }
    } else {
      // Show login dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AuthDialog(),
      );

      if (result == true && mounted) {
        setState(() {}); // Refresh to show logged in state
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully')),
        );
      }
    }
  }

  // This method will be called when pages need to refresh the navigation state
  void _refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.map((page) {
          // Wrap each page to notify navigation of state changes
          return _NavigationStateNotifier(
            onStateChanged: _refreshState,
            child: page,
          );
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Handle login/logout button (index 4)
          if (index == 4) {
            _handleLoginLogout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        backgroundColor: const Color(0xFFF3C84C), // Your yellow accent
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: '',
          ),
          // Dynamic login/logout button
          BottomNavigationBarItem(
            icon: Icon(Session.isLoggedIn ? Icons.logout : Icons.login),
            label: '',
          ),
        ],
      ),
    );
  }
}

// Helper widget to notify navigation of state changes
class _NavigationStateNotifier extends StatefulWidget {
  final Widget child;
  final VoidCallback onStateChanged;

  const _NavigationStateNotifier({
    required this.child,
    required this.onStateChanged,
  });

  @override
  State<_NavigationStateNotifier> createState() => _NavigationStateNotifierState();
}

class _NavigationStateNotifierState extends State<_NavigationStateNotifier>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NotificationListener<_LoginStateChangedNotification>(
      onNotification: (notification) {
        widget.onStateChanged();
        return true;
      },
      child: widget.child,
    );
  }
}

// Notification to inform navigation of login state changes
class _LoginStateChangedNotification extends Notification {}

// Extension to easily trigger state refresh from anywhere
extension NavigationRefresh on BuildContext {
  void refreshNavigation() {
    _LoginStateChangedNotification().dispatch(this);
  }
}