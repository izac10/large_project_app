// utils/category_helper.dart
import 'package:flutter/material.dart';

class CategoryHelper {
  // Available categories with their specific colors
  static const Map<String, Color> categoryColors = {
    'Academic': Color(0xFF4A90E2),           // Blue
    'Community Service': Color(0xFF50C878),  // Green
    'Religious': Color(0xFFB19CD9),          // Purple
    'Social': Color(0xFFFF6B9D),             // Pink
    'Sports & Recreation': Color(0xFFFF8C42), // Orange
    'Technology': Color(0xFF00CED1),         // Cyan
    'Other': Color(0xFF95A5A6),              // Gray
  };

  // Get all category names
  static List<String> get categories => categoryColors.keys.toList();

  // Get color for a specific category
  static Color getColor(String category) {
    return categoryColors[category] ?? const Color(0xFFF3C84C); // Default yellow
  }

  // Get a lighter shade for backgrounds
  static Color getLightColor(String category) {
    final color = getColor(category);
    return color.withOpacity(0.2);
  }

  // Get category icon
  static IconData getIcon(String category) {
    switch (category) {
      case 'Academic':
        return Icons.school;
      case 'Community Service':
        return Icons.volunteer_activism;
      case 'Religious':
        return Icons.church;
      case 'Social':
        return Icons.people;
      case 'Sports & Recreation':
        return Icons.sports_soccer;
      case 'Technology':
        return Icons.computer;
      case 'Other':
        return Icons.category;
      default:
        return Icons.business;
    }
  }

  // Create a category chip widget
  static Widget buildChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getColor(category),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(category), size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}