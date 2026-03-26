import 'package:flutter/material.dart';

/// Visual style for a mood emotion tag chip.
class TagStyle {
  final Color background;
  final Color foreground;
  const TagStyle(this.background, this.foreground);
}

/// Shared tag color map used by both the add-mood page and analytics charts.
const kTagStyles = <String, TagStyle>{
  'anxious': TagStyle(Color(0xFFFFF0D4), Color(0xFF8B6914)),
  'calm': TagStyle(Color(0xFFD4E8F7), Color(0xFF1A5276)),
  'angry': TagStyle(Color(0xFFFFCCCC), Color(0xFF8B1A1A)),
  'lonely': TagStyle(Color(0xFFE4D6F0), Color(0xFF5B2D8E)),
  'grateful': TagStyle(Color(0xFFD4EDDA), Color(0xFF1E6B35)),
  'happy': TagStyle(Color(0xFFFFF6CC), Color(0xFF7A6400)),
  'sad': TagStyle(Color(0xFFD6DEE8), Color(0xFF34495E)),
  'stressed': TagStyle(Color(0xFFFFE0D0), Color(0xFF8B4513)),
  'hopeful': TagStyle(Color(0xFFD0F0ED), Color(0xFF0E6655)),
  'tired': TagStyle(Color(0xFFE8DDD4), Color(0xFF5D4E37)),
  'focused': TagStyle(Color(0xFFD8DCF0), Color(0xFF2C3E7A)),
  'excited': TagStyle(Color(0xFFF5D6E8), Color(0xFF8B2252)),
};

/// Mood level definitions shared across the app.
class MoodOption {
  final String emoji;
  final String label;
  final int value; // 1 (awful) – 5 (great)
  final Color color;
  const MoodOption(this.emoji, this.label, this.value, this.color);
}

const kMoods = [
  MoodOption('😫', 'awful', 1, Color(0xFFFFCCCC)),
  MoodOption('☹️', 'bad', 2, Color(0xFFFFE0D0)),
  MoodOption('😐', 'okay', 3, Color(0xFFFFF6CC)),
  MoodOption('🙂', 'good', 4, Color(0xFFD4EDDA)),
  MoodOption('😄', 'great', 5, Color(0xFFD4E8F7)),
];

/// Numeric value for a mood label (for charting).
int moodToValue(String mood) {
  final m = kMoods.cast<MoodOption?>().firstWhere(
        (m) => m!.label == mood,
        orElse: () => null,
      );
  return m?.value ?? 3;
}

/// Energy level colors.
const kEnergyColors = <String, Color>{
  'low': Color(0xFFE8DDD4),
  'medium': Color(0xFFFFF0D4),
  'high': Color(0xFFD4EDDA),
};
