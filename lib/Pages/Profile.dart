// Pages/Profile.dart
import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../models/club.dart';
import '../models/event.dart';
import '../utils/category_helper.dart';
import '../Widgets/AuthDialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Member data
  List<Club> _myOrganizations = [];
  List<Event> _myEvents = [];

  // Officer data
  Club? _officerOrganization;
  List<Event> _officerEvents = [];

  bool _loadingOrgs = false;
  bool _loadingEvents = false;

  @override
  void initState() {
    super.initState();
    if (Session.isLoggedIn) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (Session.isAdmin) {
      _loadOfficerData();
    } else {
      _loadMemberData();
    }
  }

  Future<void> _loadMemberData() async {
    setState(() {
      _loadingOrgs = true;
      _loadingEvents = true;
    });

    // Load organizations
    try {
      final allOrgsJson = await ApiService.fetchAllOrgs();
      final allOrgs = allOrgsJson.map((json) => Club.fromJson(json)).toList();

      _myOrganizations = allOrgs.where((org) {
        return org.members.contains(Session.userId);
      }).toList();

      setState(() => _loadingOrgs = false);
    } catch (e) {
      print('Error loading organizations: $e');
      setState(() => _loadingOrgs = false);
    }

    // Load events
    try {
      final allEventsJson = await ApiService.fetchAllEvents();
      final allEvents = allEventsJson.map((json) => Event.fromJson(json)).toList();

      _myEvents = allEvents.where((event) {
        return event.attendees.contains(Session.userId);
      }).toList();

      _myEvents.sort((a, b) {
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;
        return a.dateTime!.compareTo(b.dateTime!);
      });

      setState(() => _loadingEvents = false);
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadOfficerData() async {
    setState(() {
      _loadingOrgs = true;
      _loadingEvents = true;
    });

    // Load officer's organization
    try {
      final email = Session.email!;
      final orgJson = await ApiService.fetchOrgByAdminEmail(email);

      if (orgJson != null) {
        _officerOrganization = Club.fromJson(orgJson);
      }

      setState(() => _loadingOrgs = false);
    } catch (e) {
      print('Error loading organization: $e');
      setState(() => _loadingOrgs = false);
    }

    // Load officer's events
    try {
      final email = Session.email!;
      final eventsJson = await ApiService.fetchEventsByAdminEmail(email);

      _officerEvents = eventsJson.map((json) => Event.fromJson(json)).toList();

      _officerEvents.sort((a, b) {
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;
        return a.dateTime!.compareTo(b.dateTime!);
      });

      setState(() => _loadingEvents = false);
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _loadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Session.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoggedIn
          ? (Session.isAdmin ? _buildOfficerProfile() : _buildMemberProfile())
          : _buildLoginPrompt(),
    );
  }

  // ==================== OFFICER PROFILE ====================

  Widget _buildOfficerProfile() {
    final user = Session.currentUser!;

    return RefreshIndicator(
      onRefresh: _loadOfficerData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            _buildHeader(user),

            // Statistics Cards
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Statistics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid
                  if (_loadingOrgs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildStatsGrid(),

                  const SizedBox(height: 32),

                  // Your Organization Section
                  const Text(
                    'Your Organization',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_loadingOrgs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_officerOrganization == null)
                    _buildEmptyState(
                      icon: Icons.business_outlined,
                      message: 'No organization yet',
                      subtitle: 'Create your organization from the Home tab',
                    )
                  else
                    _buildOfficerOrgCard(_officerOrganization!),

                  const SizedBox(height: 32),

                  // Your Events Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Events',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_loadingEvents)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_officerEvents.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_loadingEvents)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_officerEvents.isEmpty)
                    _buildEmptyState(
                      icon: Icons.event_outlined,
                      message: 'No events yet',
                      subtitle: 'Create events from the Events tab',
                    )
                  else
                    Column(
                      children: _officerEvents.map((event) => _buildOfficerEventCard(event)).toList(),
                    ),

                  const SizedBox(height: 32),

                  // Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalMembers = _officerOrganization?.memberCount ?? 0;
    final totalEvents = _officerEvents.length;
    final totalAttendees = _officerEvents.fold<int>(
      0,
          (sum, event) => sum + event.attendeeCount,
    );
    final avgAttendeesPerEvent = totalEvents > 0
        ? (totalAttendees / totalEvents).round()
        : 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Members',
          value: totalMembers.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Events',
          value: totalEvents.toString(),
          icon: Icons.event,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Total Attendees',
          value: totalAttendees.toString(),
          icon: Icons.person_add,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Avg per Event',
          value: avgAttendeesPerEvent.toString(),
          icon: Icons.analytics,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerOrgCard(Club club) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: club.category.isNotEmpty
              ? CategoryHelper.getColor(club.category).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              club.category.isNotEmpty
                  ? CategoryHelper.getLightColor(club.category)
                  : Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Organization Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: club.category.isNotEmpty
                      ? CategoryHelper.getLightColor(club.category)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  image: club.imageUrl.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(club.imageUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                      : null,
                ),
                child: club.imageUrl.isEmpty
                    ? Icon(
                  club.category.isNotEmpty
                      ? CategoryHelper.getIcon(club.category)
                      : Icons.business,
                  size: 40,
                  color: club.category.isNotEmpty
                      ? CategoryHelper.getColor(club.category)
                      : Colors.grey[600],
                )
                    : null,
              ),
              const SizedBox(width: 16),

              // Organization Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (club.category.isNotEmpty)
                      Text(
                        club.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: CategoryHelper.getColor(club.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${club.memberCount} members',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficerEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: event.category.isNotEmpty
              ? CategoryHelper.getColor(event.category).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Event Image/Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: event.category.isNotEmpty
                    ? CategoryHelper.getLightColor(event.category)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                image: event.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(event.imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
                    : null,
              ),
              child: event.imageUrl.isEmpty
                  ? Icon(
                event.category.isNotEmpty
                    ? CategoryHelper.getIcon(event.category)
                    : Icons.event,
                size: 30,
                color: event.category.isNotEmpty
                    ? CategoryHelper.getColor(event.category)
                    : Colors.grey[600],
              )
                  : null,
            ),
            const SizedBox(width: 12),

            // Event Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendeeCount} attending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Attendee count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: event.category.isNotEmpty
                    ? CategoryHelper.getColor(event.category)
                    : const Color(0xFFF3C84C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${event.attendeeCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MEMBER PROFILE ====================

  Widget _buildMemberProfile() {
    final user = Session.currentUser!;

    return RefreshIndicator(
      onRefresh: _loadMemberData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(user),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Organizations Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Organizations',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_loadingOrgs)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_myOrganizations.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_loadingOrgs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_myOrganizations.isEmpty)
                    _buildEmptyState(
                      icon: Icons.group_outlined,
                      message: 'No organizations yet',
                      subtitle: 'Join organizations from the Home tab',
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _myOrganizations.length,
                        itemBuilder: (context, index) => _buildOrgCard(_myOrganizations[index]),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // My Events Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Events',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_loadingEvents)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_myEvents.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_loadingEvents)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_myEvents.isEmpty)
                    _buildEmptyState(
                      icon: Icons.event_outlined,
                      message: 'No events yet',
                      subtitle: 'Join events from the Events tab',
                    )
                  else
                    Column(
                      children: _myEvents.map((event) => _buildEventCard(event)).toList(),
                    ),

                  const SizedBox(height: 32),

                  // Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF3C84C),
            const Color(0xFFF3C84C).withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            children: [
              // Profile Picture
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3C84C),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Email
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: user.isAdmin ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  user.isAdmin ? 'Officer Account' : 'Member Account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrgCard(Club club) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: club.category.isNotEmpty
                ? CategoryHelper.getColor(club.category).withOpacity(0.3)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: club.category.isNotEmpty
                      ? CategoryHelper.getLightColor(club.category)
                      : Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  image: club.imageUrl.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(club.imageUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                      : null,
                ),
                child: club.imageUrl.isEmpty
                    ? Center(
                  child: Icon(
                    club.category.isNotEmpty
                        ? CategoryHelper.getIcon(club.category)
                        : Icons.business,
                    size: 30,
                    color: club.category.isNotEmpty
                        ? CategoryHelper.getColor(club.category)
                        : Colors.grey[600],
                  ),
                )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                club.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: event.category.isNotEmpty
              ? CategoryHelper.getColor(event.category).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: event.category.isNotEmpty
                    ? CategoryHelper.getLightColor(event.category)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                image: event.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(event.imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
                    : null,
              ),
              child: event.imageUrl.isEmpty
                  ? Icon(
                event.category.isNotEmpty
                    ? CategoryHelper.getIcon(event.category)
                    : Icons.event,
                size: 30,
                color: event.category.isNotEmpty
                    ? CategoryHelper.getColor(event.category)
                    : Colors.grey[600],
              )
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (event.organizationName != null && event.organizationName!.isNotEmpty)
                    Text(
                      event.organizationName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (event.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CategoryHelper.getColor(event.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CategoryHelper.getIcon(event.category),
                  size: 20,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
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
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF3C84C).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Color(0xFFF3C84C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not Logged In',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Login to view your profile,\norganizations, and events',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => const AuthDialog(),
                );

                if (result == true && mounted) {
                  setState(() {
                    _loadUserData();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3C84C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Login / Register',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}