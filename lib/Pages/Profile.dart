// Pages/Profile.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/club.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../Widgets/AuthDialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // For OFFICERS
  Club? _myOrganization; // The organization they manage
  List<Map<String, dynamic>> _myCreatedEvents = []; // Events they created

  // For MEMBERS
  List<Club> _joinedClubs = []; // Organizations they joined
  List<Map<String, dynamic>> _joinedEvents = []; // Events they're attending

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when page becomes visible
    if (Session.isLoggedIn && !_loading) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    // Check if user is logged in
    if (!Session.isLoggedIn) {
      setState(() {
        _loading = false;
        _myOrganization = null;
        _myCreatedEvents = [];
        _joinedClubs = [];
        _joinedEvents = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (Session.isAdmin) {
        // ========== OFFICER PROFILE ==========
        await _loadOfficerProfile();
      } else {
        // ========== MEMBER PROFILE ==========
        await _loadMemberProfile();
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  // Load profile for OFFICERS
  Future<void> _loadOfficerProfile() async {
    Club? myOrganization;
    List<Map<String, dynamic>> myCreatedEvents = [];

    // Fetch officer's organization
    if (Session.email != null) {
      try {
        final orgJson = await ApiService.fetchOrgByAdminEmail(Session.email!);
        if (orgJson != null) {
          myOrganization = Club.fromJson(orgJson);
          print('✅ Officer organization loaded: ${myOrganization.title}');
        }
      } catch (e) {
        print('❌ Failed to load organization: $e');
      }

      // Fetch officer's created events
      try {
        myCreatedEvents = await ApiService.fetchEventsByAdminEmail(Session.email!);
        print('✅ Officer events loaded: ${myCreatedEvents.length} events');
      } catch (e) {
        print('❌ Failed to load events: $e');
      }
    }

    setState(() {
      _myOrganization = myOrganization;
      _myCreatedEvents = myCreatedEvents;
      _joinedClubs = [];
      _joinedEvents = [];
    });
  }

  // Load profile for MEMBERS
  Future<void> _loadMemberProfile() async {
    List<Club> joinedClubs = [];
    List<Map<String, dynamic>> joinedEvents = [];

    // Fetch all clubs and filter joined ones
    try {
      final allClubsJson = await ApiService.fetchAllOrgs();
      final allClubs = allClubsJson.map((json) => Club.fromJson(json)).toList();

      // Filter clubs where user is a member
      final userId = Session.userId;
      joinedClubs = allClubs.where((club) => club.isMember(userId)).toList();
      print('✅ Member joined clubs: ${joinedClubs.length} clubs');
    } catch (e) {
      print('❌ Failed to load clubs: $e');
    }

    // Fetch all events and filter joined ones
    try {
      final allEventsJson = await ApiService.fetchAllEvents();
      final userId = Session.userId;

      // Filter events where user is attending
      joinedEvents = allEventsJson.where((eventJson) {
        final attendees = eventJson['attendees'] as List<dynamic>? ?? [];
        return attendees.any((id) => id.toString() == userId);
      }).toList();

      print('✅ Member joined events: ${joinedEvents.length} events');
    } catch (e) {
      print('❌ Failed to load events: $e');
    }

    setState(() {
      _myOrganization = null;
      _myCreatedEvents = [];
      _joinedClubs = joinedClubs;
      _joinedEvents = joinedEvents;
    });
  }

  Future<void> _handleLogin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AuthDialog(),
    );

    // Reload profile if user logged in
    if (result == true && mounted) {
      _loadProfile();
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Session.clear();
              Navigator.pop(context);
              setState(() {
                _myOrganization = null;
                _myCreatedEvents = [];
                _joinedClubs = [];
                _joinedEvents = [];
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text(
                'Profile',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // User info card
              _buildUserInfoCard(),
              const SizedBox(height: 24),

              // Content based on login state
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (!Session.isLoggedIn)
                _buildLoginPrompt()
              else if (Session.isAdmin)
                // ========== OFFICER VIEW ==========
                  _buildOfficerView()
                else
                // ========== MEMBER VIEW ==========
                  _buildMemberView(),
            ],
          ),
        ),
      ),
    );
  }

  // ========== OFFICER VIEW ==========
  Widget _buildOfficerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // My Organization section
        _buildSectionHeader('My Organization', _myOrganization != null ? 1 : 0),
        const SizedBox(height: 12),
        if (_myOrganization == null)
          _buildEmptyState(
            icon: Icons.business_outlined,
            message: "You haven't created an organization yet",
            actionLabel: "Go to My Organization",
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Organizations > My Organization'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          )
        else
          _buildMyOrganizationCard(_myOrganization!),
        const SizedBox(height: 24),

        // My Events section
        _buildSectionHeader('My Events', _myCreatedEvents.length),
        const SizedBox(height: 12),
        if (_myCreatedEvents.isEmpty)
          _buildEmptyState(
            icon: Icons.event_outlined,
            message: "You haven't created any events yet",
          )
        else
          _buildEventsList(_myCreatedEvents, isOfficer: true),
        const SizedBox(height: 24),
      ],
    );
  }

  // ========== MEMBER VIEW ==========
  Widget _buildMemberView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Joined Organizations section
        _buildSectionHeader('My Organizations', _joinedClubs.length),
        const SizedBox(height: 12),
        if (_joinedClubs.isEmpty)
          _buildEmptyState(
            icon: Icons.business_outlined,
            message: "You haven't joined any organizations yet",
            actionLabel: "Browse Organizations",
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to Organizations tab to join clubs'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          )
        else
          _buildClubsList(),
        const SizedBox(height: 24),

        // Joined Events section
        _buildSectionHeader('My Events', _joinedEvents.length),
        const SizedBox(height: 12),
        if (_joinedEvents.isEmpty)
          _buildEmptyState(
            icon: Icons.event_outlined,
            message: "You haven't joined any events yet",
            actionLabel: "Browse Events",
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to Events tab to join events'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          )
        else
          _buildEventsList(_joinedEvents, isOfficer: false),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF3C84C),
            const Color(0xFFF3C84C).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Session.isLoggedIn
                  ? (Session.isAdmin ? Icons.person : Icons.person_outline)
                  : Icons.person_outline,
              size: 40,
              color: const Color(0xFFF3C84C),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Session.isLoggedIn
                      ? Session.currentUser?.name ?? 'User'
                      : 'Guest',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Session.isLoggedIn
                      ? Session.currentUser?.email ?? ''
                      : 'Not logged in',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                if (Session.isLoggedIn && Session.isAdmin) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Officer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action button
          IconButton(
            onPressed: Session.isLoggedIn ? _handleLogout : _handleLogin,
            icon: Icon(
              Session.isLoggedIn ? Icons.logout : Icons.login,
              color: Colors.black87,
            ),
            tooltip: Session.isLoggedIn ? 'Logout' : 'Login',
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Please login to view your profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join organizations, attend events, and more!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3C84C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Login / Register',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3C84C).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3C84C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  // For Officer: Shows their created organization
  Widget _buildMyOrganizationCard(Club org) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization image
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: org.imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(org.imageUrl),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
                  : null,
            ),
            child: org.imageUrl.isEmpty
                ? const Center(
              child: Icon(Icons.business, size: 48, color: Colors.grey),
            )
                : null,
          ),

          // Organization info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (org.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3C84C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      org.category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${org.memberCount} members',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // For Member: Shows joined organizations
  Widget _buildClubsList() {
    return Column(
      children: _joinedClubs.map((club) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: club.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(club.imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
                    : null,
              ),
              child: club.imageUrl.isEmpty
                  ? const Icon(Icons.business, color: Colors.grey)
                  : null,
            ),
            title: Text(
              club.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (club.category.isNotEmpty)
                  Text(
                    club.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${club.memberCount} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> events, {required bool isOfficer}) {
    return Column(
      children: events.map((eventJson) {
        final title = eventJson['title'] ?? 'Untitled Event';
        final date = eventJson['date'] != null
            ? DateTime.tryParse(eventJson['date'])
            : null;
        final location = eventJson['location'] ?? '';
        final attendees = eventJson['attendees'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF3C84C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event,
                color: Color(0xFFF3C84C),
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (date != null)
                  Text(
                    '${date.month}/${date.day}/${date.year}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${attendees.length} attending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      }).toList(),
    );
  }
}