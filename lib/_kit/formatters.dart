import 'package:flutter/material.dart';
import '../data/models/deck.dart';

String formatCompactCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

IconData categoryIconFromName(String? iconName) {
  switch (iconName) {
    case 'school':
      return Icons.school;
    case 'translate':
      return Icons.translate;
    case 'flight':
      return Icons.flight;
    case 'business':
      return Icons.business;
    case 'home':
      return Icons.home;
    case 'menu_book':
      return Icons.menu_book;
    case 'chat_bubble':
      return Icons.chat_bubble;
    case 'more_horiz':
      return Icons.more_horiz;
    default:
      return Icons.category;
  }
}

String formatPublicFieldNames(String fields) {
  return fields.split(',').map((f) {
    switch (f.trim()) {
      case 'word':
        return 'Word';
      case 'phonetic':
        return 'Phonetic';
      case 'meaning':
        return 'Meaning';
      case 'example':
        return 'Example';
      case 'notes':
        return 'Notes';
      default:
        return f.trim();
    }
  }).join(', ');
}

String formatCardFields(List<CardFieldType> fields) {
  return fields.map((f) => f.displayName).join(', ');
}
