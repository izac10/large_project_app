// models/club.dart
class Club {
  final String? id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final String? createdBy;
  final List<String> members; // Array of user IDs who joined
  final List<String> officers; // Array of officer user IDs
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Club({
    this.id,
    required this.title,
    this.category = '',
    this.description = '',
    this.imageUrl = '',
    this.createdBy,
    this.members = const [],
    this.officers = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['_id']?.toString(),
      title: json['title'] ?? json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdBy: json['createdBy']?.toString(),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      officers: (json['officers'] as List<dynamic>?)
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
      'imageUrl': imageUrl,
    };
    if (id != null) map['_id'] = id;
    if (createdBy != null) map['createdBy'] = createdBy;
    return map;
  }

  // Check if a user is a member of this club
  bool isMember(String? userId) {
    if (userId == null) return false;
    return members.contains(userId);
  }

  // Get member count
  int get memberCount => members.length;

  Club copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? imageUrl,
    String? createdBy,
    List<String>? members,
    List<String>? officers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Club(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      officers: officers ?? this.officers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}