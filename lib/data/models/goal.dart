// lib/data/models/goal.dart

import 'package:flutter/material.dart'; // Para IconData, se usarmos ícones para os tipos de meta
import 'package:uuid/uuid.dart'; // Para gerar IDs únicos
import 'package:runfit_app/utils/app_constants.dart'; // Para os enums de modalidade, etc.

// Enum para os tipos de meta
enum GoalType {
  distance,   // Distância (ex: correr X km)
  duration,   // Duração (ex: treinar X minutos)
  weight,     // Peso (ex: levantar X kg, ou perder X kg)
  frequency,  // Frequência (ex: treinar X vezes por semana/mês)
  workoutSheetCompletion, // Concluir uma ficha de treino específica
  // Adicione outros tipos de meta conforme necessário
}

// Enum para as unidades das metas
enum GoalUnit {
  km,
  meters,
  miles,
  minutes,
  hours,
  kg,
  lbs,
  times, // Para frequência
  none, // Para metas sem unidade específica (ex: concluir ficha)
}

class Goal {
  final String id;
  final String name; // Nome descritivo da meta (ex: "Correr minha primeira 5K")
  final GoalType type;
  final double targetValue; // Valor alvo da meta (ex: 5.0 para 5km)
  final GoalUnit unit;
  double currentValue; // Progresso atual da meta
  DateTime? deadline; // Prazo opcional para a meta
  DateTime createdAt;
  DateTime? completedAt; // Data de conclusão da meta
  bool isCompleted;
  String? notes; // Notas adicionais sobre a meta
  String? relatedItemId; // ID de item relacionado (ex: id da ficha de treino para GoalType.workoutSheetCompletion)


  Goal({
    String? id,
    required this.name,
    required this.type,
    required this.targetValue,
    required this.unit,
    this.currentValue = 0.0,
    this.deadline,
    DateTime? createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.notes,
    this.relatedItemId,
  }) : this.id = id ?? const Uuid().v4(), // Gera ID se não for fornecido
        this.createdAt = createdAt ?? DateTime.now();

  // Converte um objeto Goal para um mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name, // Salva o nome do enum
      'targetValue': targetValue,
      'unit': unit.name, // Salva o nome do enum
      'currentValue': currentValue,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'notes': notes,
      'relatedItemId': relatedItemId,
    };
  }

  // Cria um objeto Goal a partir de um mapa JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      type: GoalType.values.byName(json['type']),
      targetValue: (json['targetValue'] as num).toDouble(),
      unit: GoalUnit.values.byName(json['unit']),
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'],
      relatedItemId: json['relatedItemId'],
    );
  }

  // Método copyWith para facilitar a atualização de propriedades
  Goal copyWith({
    String? id,
    String? name,
    GoalType? type,
    double? targetValue,
    GoalUnit? unit,
    double? currentValue,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    String? notes,
    String? relatedItemId,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      currentValue: currentValue ?? this.currentValue,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      relatedItemId: relatedItemId ?? this.relatedItemId,
    );
  }
}