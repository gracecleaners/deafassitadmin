import 'package:flutter/material.dart';

// Modern color palette
const primaryColor = Color(0xFF6C63FF); // Purple accent
const secondaryColor = Color(0xFFFFFFFF); // White cards
const bgColor = Color(0xFFF5F6FA); // Light gray background
const darkTextColor = Color(0xFF2D3436); // Near-black for headings
const bodyTextColor = Color(0xFF636E72); // Gray for body text
const borderColor = Color(0xFFE0E0E0); // Light border
const successColor = Color(0xFF00B894); // Green
const warningColor = Color(0xFFFFA502); // Orange
const dangerColor = Color(0xFFFF6B6B); // Red
const infoColor = Color(0xFF74B9FF); // Blue

const defaultPadding = 16.0;

// Gradient for sidebar
const sidebarGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
);

// Card shadow
List<BoxShadow> cardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
];

// Rounded card decoration
BoxDecoration cardDecoration = BoxDecoration(
  color: secondaryColor,
  borderRadius: BorderRadius.circular(16),
  boxShadow: cardShadow,
);
