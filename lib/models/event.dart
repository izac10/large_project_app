// models/event.dart
class Event {
  final String? id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String imageUrl;
  final DateTime? dateTime;
  final String? createdBy;
  final String? organizationId; // Link to the organization hosting the event
  final String? organizationName;
  final List<String> attendees; // Array of user IDs who joined
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    this.id,
    required this.title,
    this.category = '',
    this.description = '',
    this.location = '',
    this.imageUrl = '',
    this.dateTime,
    this.createdBy,
    this.organizationId,
    this.organizationName,
    this.attendees = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id']?.toString(),
      title: json['name'] ?? json['title'] ?? '', // Backend uses 'name' field
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['logo'] ?? json['imageUrl'] ?? '', // Backend uses 'logo' field
      dateTime: json['date'] != null || json['dateTime'] != null
          ? DateTime.tryParse(json['date'] ?? json['dateTime'])
          : null,
      createdBy: json['createdBy']?.toString() ?? json['createdById']?.toString(),
      organizationId: json['organizationId']?.toString(),
      organizationName: json['organization']?.toString() ?? json['organizationName']?.toString(),
      attendees: (json['rsvps'] as List<dynamic>?) // Backend uses 'rsvps' not 'attendees'
          ?.map((e) => e.toString())
          .toList() ??
          (json['attendees'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
    };
    if (id != null) map['_id'] = id;
    if (createdBy != null) map['createdBy'] = createdBy;
    if (organizationId != null) map['organizationId'] = organizationId;
    if (dateTime != null) map['dateTime'] = dateTime!.toIso8601String();
    return map;
  }

  // Check if a user is attending this event
  bool isAttending(String? userId) {
    if (userId == null) return false;
    return attendees.contains(userId);
  }

  // Get attendee count
  int get attendeeCount => attendees.length;

  // Get formatted date and time
  String get formattedDate {
    if (dateTime == null) return 'TBA';
    return '${dateTime!.month}/${dateTime!.day}/${dateTime!.year}';
  }

  String get formattedTime {
    if (dateTime == null) return 'TBA';
    final hour = dateTime!.hour > 12 ? dateTime!.hour - 12 : (dateTime!.hour == 0 ? 12 : dateTime!.hour);
    final minute = dateTime!.minute.toString().padLeft(2, '0');
    final period = dateTime!.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Event copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? location,
    String? imageUrl,
    DateTime? dateTime,
    String? createdBy,
    String? organizationId,
    String? organizationName,
    List<String>? attendees,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      dateTime: dateTime ?? this.dateTime,
      createdBy: createdBy ?? this.createdBy,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      attendees: attendees ?? this.attendees,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}