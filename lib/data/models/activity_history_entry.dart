// lib/data/models/activity_history_entry.dart

import 'package:flutter/material.dart';

// NOVO: Modelo para exercícios registrados em atividades de musculação avulsas
class LoggedExercise {
  final String name;
  final String sets; // Pode ser "3" (séries) ou "3x" (para 3 sets de algo)
  final String reps; // Pode ser "10" (repetições) ou "8-12"
  final String? load; // Ex: "20kg", "DBs 10kg", "BW" (bodyweight)
  final String? notes; // Notas específicas para este exercício

  LoggedExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.load,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'load': load,
      'notes': notes,
    };
  }

  factory LoggedExercise.fromJson(Map<String, dynamic> json) {
    return LoggedExercise(
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      load: json['load'],
      notes: json['notes'],
    );
  }
}


class ActivityHistoryEntry {
  final String id;
  final DateTime date;
  final String modality;
  final String activityType;
  final String? workoutSheetName;
  final String? workoutSheetData;
  final double? durationMinutes;
  final double? distanceKm;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final List<Map<String, double>>? pathCoordinates;
  final String? averagePace; // NOVO CAMPO: Para armazenar o pace médio formatado
  final List<LoggedExercise>? loggedExercises; // NOVO CAMPO: Para detalhes de exercícios de musculação

  ActivityHistoryEntry({
    required this.id,
    required this.date,
    required this.modality,
    required this.activityType,
    this.workoutSheetName,
    this.workoutSheetData,
    this.durationMinutes,
    this.distanceKm,
    this.notes,
    this.latitude,
    this.longitude,
    this.pathCoordinates,
    this.averagePace,
    this.loggedExercises, // Adicione ao construtor
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'modality': modality,
      'activityType': activityType,
      'workoutSheetName': workoutSheetName,
      'workoutSheetData': workoutSheetData,
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'pathCoordinates': pathCoordinates,
      'averagePace': averagePace,
      'loggedExercises': loggedExercises?.map((e) => e.toJson()).toList(), // Adicione ao toJson
    };
  }

  factory ActivityHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      modality: json['modality'],
      activityType: json['activityType'],
      workoutSheetName: json['workoutSheetName'],
      workoutSheetData: json['workoutSheetData'],
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      notes: json['notes'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      pathCoordinates: (json['pathCoordinates'] as List?)
          ?.map((e) => Map<String, double>.from(e as Map))
          .toList(),
      averagePace: json['averagePace'],
      loggedExercises: (json['loggedExercises'] as List?) // Adicione ao fromJson
          ?.map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}