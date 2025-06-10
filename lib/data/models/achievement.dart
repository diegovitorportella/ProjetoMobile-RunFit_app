// lib/data/models/achievement.dart

import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  bool isUnlocked;
  DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  // Converte um objeto Achievement para um mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint, // Salva o código do ícone
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  // Cria um objeto Achievement a partir de um mapa JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      isUnlocked: json['isUnlocked'] as bool,
      unlockedDate: json['unlockedDate'] != null ? DateTime.parse(json['unlockedDate']) : null,
    );
  }

  // Para facilitar a clonagem e modificação do estado (ex: ao desbloquear)
  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}