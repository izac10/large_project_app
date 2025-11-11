import 'package:flutter/material.dart';
import '../models/club.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../Widgets/AuthDialog.dart';
import '../utils/category_helper.dart';
import 'MyOrganization.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  List<Club> _clubs = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  // Get categories from CategoryHelper (add 'All' option)
  List<String> get _categories => ['All', ...CategoryHelper.categories];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> clubsJson = await ApiService.fetchAllOrgs();
      setState(() {
        _clubs = clubsJson.map((json) => Club.fromJson(json)).toList();
        _loading = false;
      });
    } catch (e) {
      // If backend doesn't have /org/all endpoint yet, show helpful message
      setState(() {
        _error = 'Backend endpoint missing. Please update your backend org.js file.';
        _loading = false;
        _clubs = []; // Show empty state instead of crash
      });

      // Log the actual error for debugging
      print('Error loading organizations: $e');
    }
  }

  Future<void> _handleMyOrganization(BuildContext context) async {
    if (!Session.isLoggedIn) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AuthDialog(),
      );
      if (ok != true) return;
    }
    if (!Session.isAdmin) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only officers can manage organizations')),
      );
      return;
    }

    // Navigate to MyOrganization page
    if (!context.mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyOrganizationPage()),
    );

    // Reload clubs if changes were made
    if (result == true) {
      _loadClubs();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((cat) {
            final String? categoryValue = cat == 'All' ? null : cat;
            return RadioListTile<String?>(
              title: Text(cat),
              value: categoryValue,
              groupValue: _selectedCategory,
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Club> get _filteredClubs {
    return _clubs.where((club) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!club.title.toLowerCase().contains(query) &&
            !club.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (club.category != _selectedCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _viewClubDetails(Club club) async {
    // Fetch fresh club data to get updated members list
    try {
      final freshClubData = await ApiService.fetchOrgById(club.id!);
      final freshClub = Club.fromJson(freshClubData);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubDetailPage(club: freshClub),
        ),
      );
    } catch (e) {
      // If fetch fails, use the existing club data
      print('Failed to fetch fresh club data: $e');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubDetailPage(club: club),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredClubs = _filteredClubs;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadClubs,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              const SizedBox(height: 8),
              Text('Student',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              Text('Organizations',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 20),


              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleMyOrganization(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('My Organization'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _showFilterDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Filter'),
                        if (_selectedCategory != null) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.circle, size: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search organizations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 16),

              // Loading/Error/Empty states
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Update your backend routes/org.js file with the new endpoints.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadClubs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3C84C),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredClubs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != null
                                ? 'No organizations match your search'
                                : 'No organizations yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Be the first to create one!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                // Grid of org cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: filteredClubs.length,
                    itemBuilder: (context, i) => _orgCard(filteredClubs[i]),
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _orgCard(Club club) {
    return Card(
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
      child: InkWell(
        onTap: () => _viewClubDetails(club),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: club.category.isNotEmpty
                          ? CategoryHelper.getLightColor(club.category)
                          : Colors.black87,
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
                        size: 40,
                        color: club.category.isNotEmpty
                            ? CategoryHelper.getColor(club.category)
                            : Colors.white54,
                      ),
                    )
                        : null,
                  ),
                  // Category badge overlay
                  if (club.category.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CategoryHelper.getColor(club.category),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          CategoryHelper.getIcon(club.category),
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Title section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                club.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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

// Remove the _handleJoinClub method from the cards since join is now only in detail page
}

// Club Detail Page
class ClubDetailPage extends StatefulWidget {
  final Club club;

  const ClubDetailPage({super.key, required this.club});

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  bool _isJoined = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
  }

  void _checkMembershipStatus() {
    // Check if user is logged in and if their ID is in the members array
    if (Session.isLoggedIn && Session.userId != null) {
      setState(() {
        _isJoined = widget.club.isMember(Session.userId);
      });
    }
  }

  Future<void> _handleJoin() async {
    // Check if user is logged in, if not prompt to login
    if (!Session.isLoggedIn) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AuthDialog(),
      );
      if (ok != true || !mounted) return;
    }

    // After login (or if already logged in), check if user is an officer
    if (Session.isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Officers cannot join organizations. You can create and manage your own organization instead!'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // User is a member, proceed with join
    setState(() => _isLoading = true);

    try {
      // Call actual API endpoint
      final response = await ApiService.joinOrg(widget.club.id!, Session.userId!);

      // Update the club with fresh data from response
      final updatedClub = Club.fromJson(response['club']);

      setState(() {
        _isJoined = updatedClub.isMember(Session.userId);
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${widget.club.title}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      // Handle specific error messages
      String errorMsg = 'Failed to join: $e';
      if (e.toString().contains('Already a member')) {
        errorMsg = 'You are already a member of this organization';
        // If already a member, update the state
        setState(() => _isJoined = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Organization'),
        content: Text('Are you sure you want to leave ${widget.club.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Call actual API endpoint
      final response = await ApiService.leaveOrg(widget.club.id!, Session.userId!);

      // Update the club with fresh data from response
      final updatedClub = Club.fromJson(response['club']);

      setState(() {
        _isJoined = updatedClub.isMember(Session.userId);
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${widget.club.title}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      // Handle specific error messages
      String errorMsg = 'Failed to leave: $e';
      if (e.toString().contains('Not a member')) {
        errorMsg = 'You are not a member of this organization';
        // If not a member, update the state
        setState(() => _isJoined = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club.title),
        backgroundColor: widget.club.category.isNotEmpty
            ? CategoryHelper.getColor(widget.club.category)
            : const Color(0xFFF3C84C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: widget.club.category.isNotEmpty
                    ? CategoryHelper.getLightColor(widget.club.category)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: widget.club.category.isNotEmpty
                    ? Border.all(
                  color: CategoryHelper.getColor(widget.club.category),
                  width: 3,
                )
                    : null,
                image: widget.club.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(widget.club.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.club.imageUrl.isEmpty
                  ? Center(
                child: Icon(
                  widget.club.category.isNotEmpty
                      ? CategoryHelper.getIcon(widget.club.category)
                      : Icons.business_outlined,
                  size: 80,
                  color: widget.club.category.isNotEmpty
                      ? CategoryHelper.getColor(widget.club.category)
                      : Colors.grey[600],
                ),
              )
                  : null,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              widget.club.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Category chip with color
            if (widget.club.category.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: CategoryHelper.buildChip(widget.club.category),
              ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.club.description.isEmpty
                  ? 'No description available.'
                  : widget.club.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Join/Leave button - shown to everyone except officers (after login check)
            // Officers will see a message if they try to join
            _isJoined
                ? ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLeave,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.check),
              label: const Text('Leave Organization'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
                : ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleJoin,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.add),
              label: const Text('Join Organization'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.club.category.isNotEmpty
                    ? CategoryHelper.getColor(widget.club.category)
                    : const Color(0xFFF3C84C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}