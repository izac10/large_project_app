// Pages/Events.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../Widgets/AuthDialog.dart';
import '../utils/category_helper.dart';
import 'MyEvents.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> _events = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  // Get categories from CategoryHelper (add 'All' option)
  List<String> get _categories => ['All', ...CategoryHelper.categories];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> eventsJson = await ApiService.fetchAllEvents();
      final events = eventsJson.map((json) => Event.fromJson(json)).toList();

      // ✨ NEW: Sort by date/createdAt (newest first)
      events.sort((a, b) {
        // First try to sort by event date
        if (a.dateTime != null && b.dateTime != null) {
          return b.dateTime!.compareTo(a.dateTime!); // Newest events first
        }
        // Fallback to createdAt if available
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        // If one has date and other doesn't, prioritize the one with date
        if (a.dateTime != null) return -1;
        if (b.dateTime != null) return 1;
        return 0;
      });

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load events: $e';
        _loading = false;
        _events = [];
      });
      print('Error loading events: $e');
    }
  }

  Future<void> _handleAddEditEvent(BuildContext context) async {
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
        const SnackBar(content: Text('Only officers can create/edit events')),
      );
      return;
    }

    // Navigate to MyEvents page
    if (!context.mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyEventsPage()),
    );

    // Reload events if changes were made
    if (result == true) {
      _loadEvents();
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

  List<Event> get _filteredEvents {
    return _events.where((event) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.title.toLowerCase().contains(query) &&
            !event.description.toLowerCase().contains(query) &&
            !event.location.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (event.category != _selectedCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _viewEventDetails(Event event) async {
    // Fetch fresh event data to get updated attendees list
    try {
      final freshEventData = await ApiService.fetchEventById(event.id!);
      final freshEvent = Event.fromJson(freshEventData);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailPage(event: freshEvent),
        ),
      );
    } catch (e) {
      print('Failed to fetch fresh event data: $e');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailPage(event: event),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEvents = _filteredEvents;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              const SizedBox(height: 8),
              Text(
                'Events',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search events...',
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

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleAddEditEvent(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Add/Edit'),
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEvents,
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
              else if (filteredEvents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != null
                                ? 'No events match your search'
                                : 'No events yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Check back later for upcoming events!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                // Grid of event cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75, // Reduced from 0.85 to give more height
                    ),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, i) => _eventCard(filteredEvents[i]),
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard(Event event) {
    return Card(
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
      child: InkWell(
        onTap: () => _viewEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: event.category.isNotEmpty
                          ? CategoryHelper.getLightColor(event.category)
                          : Colors.black87,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      image: event.imageUrl.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(event.imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                          : null,
                    ),
                    child: event.imageUrl.isEmpty
                        ? Center(
                      child: Icon(
                        event.category.isNotEmpty
                            ? CategoryHelper.getIcon(event.category)
                            : Icons.event,
                        size: 40,
                        color: event.category.isNotEmpty
                            ? CategoryHelper.getColor(event.category)
                            : Colors.white54,
                      ),
                    )
                        : null,
                  ),
                  // Category badge overlay
                  if (event.category.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CategoryHelper.getColor(event.category),
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
                          CategoryHelper.getIcon(event.category),
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Organization name (if available)
                    if (event.organizationName != null && event.organizationName!.isNotEmpty) ...[
                      Text(
                        event.organizationName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Date and Attendee count on same row
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendeeCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Event Detail Page
class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isAttending = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAttendanceStatus();
  }

  void _checkAttendanceStatus() {
    if (Session.isLoggedIn && Session.userId != null) {
      setState(() {
        _isAttending = widget.event.isAttending(Session.userId);
      });
    }
  }

  Future<void> _handleJoin() async {
    if (!Session.isLoggedIn) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AuthDialog(),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.joinEvent(widget.event.id!, Session.userId!);
      final updatedEvent = Event.fromJson(response['event']);

      setState(() {
        _isAttending = updatedEvent.isAttending(Session.userId);
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${widget.event.title}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      String errorMsg = 'Failed to join: $e';
      if (e.toString().contains('Already attending')) {
        errorMsg = 'You are already attending this event';
        setState(() => _isAttending = true);
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
        title: const Text('Leave Event'),
        content: Text('Are you sure you want to leave ${widget.event.title}?'),
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
      final response = await ApiService.leaveEvent(widget.event.id!, Session.userId!);
      final updatedEvent = Event.fromJson(response['event']);

      setState(() {
        _isAttending = updatedEvent.isAttending(Session.userId);
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${widget.event.title}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      String errorMsg = 'Failed to leave: $e';
      if (e.toString().contains('Not attending')) {
        errorMsg = 'You are not attending this event';
        setState(() => _isAttending = false);
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
        title: Text(widget.event.title),
        backgroundColor: widget.event.category.isNotEmpty
            ? CategoryHelper.getColor(widget.event.category)
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
                color: widget.event.category.isNotEmpty
                    ? CategoryHelper.getLightColor(widget.event.category)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: widget.event.category.isNotEmpty
                    ? Border.all(
                  color: CategoryHelper.getColor(widget.event.category),
                  width: 3,
                )
                    : null,
                image: widget.event.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(widget.event.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.event.imageUrl.isEmpty
                  ? Center(
                child: Icon(
                  widget.event.category.isNotEmpty
                      ? CategoryHelper.getIcon(widget.event.category)
                      : Icons.event_outlined,
                  size: 80,
                  color: widget.event.category.isNotEmpty
                      ? CategoryHelper.getColor(widget.event.category)
                      : Colors.grey[600],
                ),
              )
                  : null,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Organization name
            if (widget.event.organizationName != null && widget.event.organizationName!.isNotEmpty)
              Text(
                'Hosted by ${widget.event.organizationName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),

            // Category chip
            if (widget.event.category.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: CategoryHelper.buildChip(widget.event.category),
              ),
            const SizedBox(height: 20),

            // Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  widget.event.formattedDate,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 20),
                Icon(Icons.access_time, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  widget.event.formattedTime,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location
            if (widget.event.location.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.event.location,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Attendee count
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  '${widget.event.attendeeCount} attendee${widget.event.attendeeCount != 1 ? 's' : ''} registered',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description.isEmpty
                  ? 'No description available.'
                  : widget.event.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Join/Leave button
            _isAttending
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
              label: const Text('Leave Event'),
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
              label: const Text('Join Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.event.category.isNotEmpty
                    ? CategoryHelper.getColor(widget.event.category)
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