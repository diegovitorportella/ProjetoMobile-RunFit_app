// lib/data/models/activity_history_entry.dart

import 'package:flutter/material.dart';

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
    this.averagePace, // NOVO CAMPO NO CONSTRUTOR
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
      'averagePace': averagePace, // NOVO CAMPO NO TOJSON
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
      averagePace: json['averagePace'], // NOVO CAMPO NO FROMJSON
    );
  }
}