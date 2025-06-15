// lib/data/models/workout_sheet.dart

import 'package:flutter/material.dart'; // Necessário para IconData
import 'package:runfit_app/utils/app_constants.dart'; // Para os enums

class Exercise {
  final String name;
  final String setsReps;
  final String? notes;
  final String? imageUrl; // URL ou path para uma imagem/GIF de demonstração
  final String? load; // NOVO CAMPO: Para armazenar a carga (ex: "20kg", "5lb", "BW" (bodyweight))
  bool isCompleted;

  Exercise({
    required this.name,
    required this.setsReps,
    this.notes,
    this.imageUrl,
    this.load, // Adicione ao construtor
    this.isCompleted = false,
  });

  // NOVO: Método copyWith para Exercise
  Exercise copyWith({
    String? name,
    String? setsReps,
    String? notes,
    String? imageUrl,
    String? load, // Adicione ao copyWith
    bool? isCompleted,
  }) {
    return Exercise(
      name: name ?? this.name,
      setsReps: setsReps ?? this.setsReps,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      load: load ?? this.load, // Adicione ao copyWith
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'setsReps': setsReps,
    'notes': notes,
    'imageUrl': imageUrl,
    'load': load, // Adicione ao toJson
    'isCompleted': isCompleted,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    name: json['name'],
    setsReps: json['setsReps'],
    notes: json['notes'],
    imageUrl: json['imageUrl'],
    load: json['load'], // Adicione ao fromJson
    isCompleted: json['isCompleted'] ?? false,
  );
}

class WorkoutSheet {
  final String id;
  final String name;
  final String description;
  final WorkoutModality modality;
  final WorkoutLevel level;
  final List<Exercise> exercises;
  final int? icon; // Novo campo para o codePoint do IconData
  bool isActive;
  final String? userId; // NOVO CAMPO: Para associar a ficha ao usuário

  WorkoutSheet({
    required this.id,
    required this.name,
    required this.description,
    required this.modality,
    required this.level,
    required this.exercises,
    this.icon,
    this.isActive = false,
    this.userId, // Adicione ao construtor
  });

  // NOVO: Método copyWith para WorkoutSheet
  WorkoutSheet copyWith({
    String? id,
    String? name,
    String? description,
    WorkoutModality? modality,
    WorkoutLevel? level,
    List<Exercise>? exercises,
    int? icon,
    bool? isActive,
    String? userId, // Adicione ao copyWith
  }) {
    return WorkoutSheet(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      modality: modality ?? this.modality,
      level: level ?? this.level,
      exercises: exercises ?? this.exercises,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId, // Adicione ao copyWith
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'modality': modality.name,
    'level': level.name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'icon': icon,
    'isActive': isActive,
    'userId': userId, // Adicione ao toJson
  };

  factory WorkoutSheet.fromJson(Map<String, dynamic> json) {
    List<Exercise> exercisesList = (json['exercises'] as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return WorkoutSheet(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      modality: WorkoutModality.values.byName(json['modality']),
      level: WorkoutLevel.values.byName(json['level']),
      exercises: exercisesList,
      icon: json['icon'],
      isActive: json['isActive'] ?? false,
      userId: json['userId'], // Adicione ao fromJson
    );
  }
}