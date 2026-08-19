import 'package:flutter/material.dart';

IconData personaMaterialIcon(String name, String chatMode) {
  final mapped = _icons[name.trim()];
  if (mapped != null) {
    return mapped;
  }
  return switch (chatMode) {
    'doctor' => Icons.smart_toy_rounded,
    'ai_doctor' => Icons.medical_services_rounded,
    'patient' => Icons.healing_rounded,
    _ => Icons.volunteer_activism_rounded,
  };
}

const _icons = <String, IconData>{
  'smart_toy_rounded': Icons.smart_toy_rounded,
  'psychology_rounded': Icons.psychology_rounded,
  'self_improvement_rounded': Icons.self_improvement_rounded,
  'spa_rounded': Icons.spa_rounded,
  'volunteer_activism_rounded': Icons.volunteer_activism_rounded,
  'favorite_rounded': Icons.favorite_rounded,
  'mood_rounded': Icons.mood_rounded,
  'sentiment_satisfied_alt_rounded': Icons.sentiment_satisfied_alt_rounded,
  'support_agent_rounded': Icons.support_agent_rounded,
  'chat_rounded': Icons.chat_rounded,
  'forum_rounded': Icons.forum_rounded,
  'record_voice_over_rounded': Icons.record_voice_over_rounded,
  'medical_services_rounded': Icons.medical_services_rounded,
  'local_hospital_rounded': Icons.local_hospital_rounded,
  'healing_rounded': Icons.healing_rounded,
  'health_and_safety_rounded': Icons.health_and_safety_rounded,
  'monitor_heart_rounded': Icons.monitor_heart_rounded,
  'medication_rounded': Icons.medication_rounded,
  'emergency_rounded': Icons.emergency_rounded,
  'bloodtype_rounded': Icons.bloodtype_rounded,
  'accessibility_new_rounded': Icons.accessibility_new_rounded,
  'elderly_rounded': Icons.elderly_rounded,
  'child_care_rounded': Icons.child_care_rounded,
  'family_restroom_rounded': Icons.family_restroom_rounded,
  'groups_rounded': Icons.groups_rounded,
  'handshake_rounded': Icons.handshake_rounded,
  'person_rounded': Icons.person_rounded,
  'face_rounded': Icons.face_rounded,
  'nightlight_rounded': Icons.nightlight_rounded,
  'wb_sunny_rounded': Icons.wb_sunny_rounded,
  'park_rounded': Icons.park_rounded,
  'eco_rounded': Icons.eco_rounded,
  'water_drop_rounded': Icons.water_drop_rounded,
  'coffee_rounded': Icons.coffee_rounded,
  'music_note_rounded': Icons.music_note_rounded,
  'auto_awesome_rounded': Icons.auto_awesome_rounded,
  'lightbulb_rounded': Icons.lightbulb_rounded,
  'menu_book_rounded': Icons.menu_book_rounded,
  'school_rounded': Icons.school_rounded,
  'assignment_rounded': Icons.assignment_rounded,
  'checklist_rounded': Icons.checklist_rounded,
  'flag_rounded': Icons.flag_rounded,
  'balance_rounded': Icons.balance_rounded,
  'privacy_tip_rounded': Icons.privacy_tip_rounded,
  'shield_rounded': Icons.shield_rounded,
  'home_rounded': Icons.home_rounded,
  'pets_rounded': Icons.pets_rounded,
  'sports_esports_rounded': Icons.sports_esports_rounded,
  'palette_rounded': Icons.palette_rounded,
};
