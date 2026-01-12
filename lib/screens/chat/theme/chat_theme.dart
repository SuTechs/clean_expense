import 'package:flutter/material.dart';

/// Theme configuration for the chat screen.
/// Independent of the main app theme to allow custom chat aesthetics.
class ChatTheme {
  final String id;
  final String name;
  final String emoji;

  // Background
  final List<Color> backgroundGradient;
  final Color patternColor;

  // App Bar
  final Color appBarBg;
  final Color appBarText;
  final Color statusDot;

  // Bubbles - Incoming (Income)
  final Color incomingBg;
  final Color incomingAccent;
  final Color incomingBorder;

  // Bubbles - Outgoing (Expense)
  final Color outgoingBg;
  final Color outgoingAccent;
  final Color outgoingBorder;

  // Bubbles - Invested
  final Color investedBg;
  final Color investedAccent;
  final Color investedBorder;

  // Input Field
  final Color inputContainerBg;
  final Color inputFieldBg;
  final Color inputBorder;

  // Text
  final Color primaryText;
  final Color secondaryText;
  final Color dateText;

  const ChatTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.backgroundGradient,
    required this.patternColor,
    required this.appBarBg,
    required this.appBarText,
    required this.statusDot,
    required this.incomingBg,
    required this.incomingAccent,
    required this.incomingBorder,
    required this.outgoingBg,
    required this.outgoingAccent,
    required this.outgoingBorder,
    required this.investedBg,
    required this.investedAccent,
    required this.investedBorder,
    required this.inputContainerBg,
    required this.inputFieldBg,
    required this.inputBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.dateText,
  });
}

/// All available chat themes using color theory principles.
class ChatThemes {
  ChatThemes._();

  /// Ocean Theme - Cool blues and teals (Default)
  /// Analogous color scheme with blue as primary
  static const ocean = ChatTheme(
    id: 'ocean',
    name: 'Ocean',
    emoji: '🌊',
    backgroundGradient: [
      Color(0xFFD5DCE8), // Cool blue-gray
      Color(0xFFCBD5E3),
      Color(0xFFDAE2ED),
    ],
    patternColor: Color(0x082D3250),
    appBarBg: Color(0x142D3250),
    appBarText: Color(0xFF2D3250),
    statusDot: Color(0xFF2ECC71),
    // Incoming - Green (complementary)
    incomingBg: Color(0x1A2ECC71),
    incomingAccent: Color(0xFF2ECC71),
    incomingBorder: Color(0x402ECC71),
    // Outgoing - Blue (primary)
    outgoingBg: Color(0x1A4A90E2),
    outgoingAccent: Color(0xFF4A90E2),
    outgoingBorder: Color(0x404A90E2),
    // Invested - Purple (analogous)
    investedBg: Color(0x1A6C63FF),
    investedAccent: Color(0xFF6C63FF),
    investedBorder: Color(0x406C63FF),
    inputContainerBg: Color(0xFFE8E9ED),
    inputFieldBg: Color(0xFFD1D3DC),
    inputBorder: Color(0x4D2D3250),
    primaryText: Color(0xFF1A1C29),
    secondaryText: Color(0xFF9095A1),
    dateText: Color(0x802D3250),
  );

  /// Sunset Theme - Warm oranges and corals
  /// Triadic color scheme with orange as primary
  static const sunset = ChatTheme(
    id: 'sunset',
    name: 'Sunset',
    emoji: '🌅',
    backgroundGradient: [
      Color(0xFFFDE8E0), // Warm peach
      Color(0xFFFCE4D8),
      Color(0xFFFEEDE6),
    ],
    patternColor: Color(0x08C45C26),
    appBarBg: Color(0x14C45C26),
    appBarText: Color(0xFF8B4513),
    statusDot: Color(0xFF14B8A6),
    // Incoming - Teal (complementary)
    incomingBg: Color(0x1A14B8A6),
    incomingAccent: Color(0xFF14B8A6),
    incomingBorder: Color(0x4014B8A6),
    // Outgoing - Orange (primary)
    outgoingBg: Color(0x1AF59E0B),
    outgoingAccent: Color(0xFFD97706),
    outgoingBorder: Color(0x40F59E0B),
    // Invested - Magenta (triadic)
    investedBg: Color(0x1ADB2777),
    investedAccent: Color(0xFFDB2777),
    investedBorder: Color(0x40DB2777),
    inputContainerBg: Color(0xFFFFF7ED),
    inputFieldBg: Color(0xFFFED7AA),
    inputBorder: Color(0x4DD97706),
    primaryText: Color(0xFF431407),
    secondaryText: Color(0xFF9A8478),
    dateText: Color(0x80431407),
  );

  /// Forest Theme - Natural greens and earth tones
  /// Analogous with green as primary
  static const forest = ChatTheme(
    id: 'forest',
    name: 'Forest',
    emoji: '🌲',
    backgroundGradient: [
      Color(0xFFDCEDDC), // Sage green
      Color(0xFFD4E7D4),
      Color(0xFFE4F0E4),
    ],
    patternColor: Color(0x08166534),
    appBarBg: Color(0x14166534),
    appBarText: Color(0xFF166534),
    statusDot: Color(0xFF10B981),
    // Incoming - Emerald (primary)
    incomingBg: Color(0x1A10B981),
    incomingAccent: Color(0xFF10B981),
    incomingBorder: Color(0x4010B981),
    // Outgoing - Amber (complementary)
    outgoingBg: Color(0x1AF59E0B),
    outgoingAccent: Color(0xFFB45309),
    outgoingBorder: Color(0x40F59E0B),
    // Invested - Violet (triadic)
    investedBg: Color(0x1A8B5CF6),
    investedAccent: Color(0xFF7C3AED),
    investedBorder: Color(0x408B5CF6),
    inputContainerBg: Color(0xFFE8F5E8),
    inputFieldBg: Color(0xFFD0E7D0),
    inputBorder: Color(0x4D166534),
    primaryText: Color(0xFF14532D),
    secondaryText: Color(0xFF6B8B6B),
    dateText: Color(0x80166534),
  );

  /// Lavender Theme - Soft purples and pinks
  /// Analogous with purple as primary
  static const lavender = ChatTheme(
    id: 'lavender',
    name: 'Lavender',
    emoji: '💜',
    backgroundGradient: [
      Color(0xFFE8E0F0), // Soft lavender
      Color(0xFFE4D8EC),
      Color(0xFFEDE6F4),
    ],
    patternColor: Color(0x086B21A8),
    appBarBg: Color(0x146B21A8),
    appBarText: Color(0xFF581C87),
    statusDot: Color(0xFF22C55E),
    // Incoming - Green (complementary)
    incomingBg: Color(0x1A22C55E),
    incomingAccent: Color(0xFF22C55E),
    incomingBorder: Color(0x4022C55E),
    // Outgoing - Indigo (analogous)
    outgoingBg: Color(0x1A6366F1),
    outgoingAccent: Color(0xFF4F46E5),
    outgoingBorder: Color(0x406366F1),
    // Invested - Pink (analogous)
    investedBg: Color(0x1AEC4899),
    investedAccent: Color(0xFFDB2777),
    investedBorder: Color(0x40EC4899),
    inputContainerBg: Color(0xFFF3E8F8),
    inputFieldBg: Color(0xFFE9D5F5),
    inputBorder: Color(0x4D6B21A8),
    primaryText: Color(0xFF3B0764),
    secondaryText: Color(0xFF8B7798),
    dateText: Color(0x80581C87),
  );

  /// Midnight Theme - Dark mode with vibrant accents
  /// High contrast with dark background
  static const midnight = ChatTheme(
    id: 'midnight',
    name: 'Midnight',
    emoji: '🌙',
    backgroundGradient: [
      Color(0xFF1A1C2E), // Deep navy
      Color(0xFF151725),
      Color(0xFF1E2130),
    ],
    patternColor: Color(0x0AFFFFFF),
    appBarBg: Color(0x20FFFFFF),
    appBarText: Color(0xFFE2E8F0),
    statusDot: Color(0xFF10B981),
    // Incoming - Emerald (vibrant on dark)
    incomingBg: Color(0x2A10B981),
    incomingAccent: Color(0xFF34D399),
    incomingBorder: Color(0x5010B981),
    // Outgoing - Cyan (bright on dark)
    outgoingBg: Color(0x2A06B6D4),
    outgoingAccent: Color(0xFF22D3EE),
    outgoingBorder: Color(0x5006B6D4),
    // Invested - Magenta (vibrant)
    investedBg: Color(0x2AEC4899),
    investedAccent: Color(0xFFF472B6),
    investedBorder: Color(0x50EC4899),
    inputContainerBg: Color(0xFF252840),
    inputFieldBg: Color(0xFF2D3250),
    inputBorder: Color(0x40FFFFFF),
    primaryText: Color(0xFFF1F5F9),
    secondaryText: Color(0xFF94A3B8),
    dateText: Color(0x80CBD5E1),
  );

  /// All available themes
  static const List<ChatTheme> all = [
    ocean,
    sunset,
    forest,
    lavender,
    midnight,
  ];

  /// Get theme by ID
  static ChatTheme getById(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => ocean);
  }
}
