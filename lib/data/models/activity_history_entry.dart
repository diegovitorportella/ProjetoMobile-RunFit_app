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
  final String? averagePace;
  final List<LoggedExercise>? loggedExercises;

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
    this.loggedExercises,
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
      'loggedExercises': loggedExercises?.map((e) => e.toJson()).toList(),
    };
  }

  factory ActivityHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Tratamento para pathCoordinates: converter List<dynamic> para List<Map<String, double>>
    final List<dynamic>? rawPathCoordinates = json['pathCoordinates'] as List<dynamic>?;
    final List<Map<String, double>>? parsedPathCoordinates = rawPathCoordinates?.map((e) {
      // Garante que cada item da lista seja um Map<String, dynamic> antes de converter para Map<String, double>
      return Map<String, double>.from(e as Map);
    }).toList();

    // Tratamento para loggedExercises: converter List<dynamic> para List<LoggedExercise>
    final List<dynamic>? rawLoggedExercises = json['loggedExercises'] as List<dynamic>?;
    final List<LoggedExercise>? parsedLoggedExercises = rawLoggedExercises?.map((e) {
      // Garante que cada item da lista seja um Map<String, dynamic> antes de chamar LoggedExercise.fromJson
      return LoggedExercise.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();


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
      // Use os valores parseados aqui:
      pathCoordinates: parsedPathCoordinates, // <--- Use o valor parseado
      averagePace: json['averagePace'],
      loggedExercises: parsedLoggedExercises, // <--- Use o valor parseado
    );
  }
}