// lib/screens/activity_log_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'package:runfit_app/utils/app_colors.dart';           // CORES DO PROJETO
import 'package:runfit_app/utils/app_styles.dart';           // ESTILOS DO PROJETO
import 'package:runfit_app/utils/app_constants.dart';        // CONSTANTES DO PROJETO
import 'package:runfit_app/data/models/activity_history_entry.dart'; // MODELO DO PROJETO
import 'package:runfit_app/services/achievement_service.dart';     // SERVIÇO DE CONQUISTAS

class ActivityLogScreen extends StatefulWidget {
  final String? selectedModality; // Recebe a modalidade (ex: musculacao)
  // Removido activeWorkoutSheet, pois esta tela é para atividades avulsas manuais.
  // Se precisar logar conclusão de ficha, a lógica da HomeScreen original seria mantida/adaptada.

  const ActivityLogScreen({
    super.key,
    this.selectedModality,
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _currentModality;
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController(); // Mantido caso outra modalidade manual precise
  final TextEditingController _notesController = TextEditingController();

  final Uuid _uuid = const Uuid();
  final AchievementService _achievementService = AchievementService(); // Instância do serviço

  @override
  void initState() {
    super.initState();
    // Define a modalidade baseada no que foi passado, ou um padrão.
    // Para este fluxo, widget.selectedModality sempre deve ser 'musculacao'.
    _currentModality = widget.selectedModality ?? WorkoutModality.musculacao.name;
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      // Usar a chave de SharedPreferencesKeys do app_constants.dart
      List<String> historyJsonList = prefs.getStringList(SharedPreferencesKeys.activityHistory) ?? [];

      final newEntry = ActivityHistoryEntry(
        id: _uuid.v4(),
        date: DateTime.now(),
        modality: _currentModality, // Será 'musculacao' neste caso
        activityType: 'Avulsa', // Sempre 'Avulsa' para esta tela
        durationMinutes: double.tryParse(_durationController.text),
        // DistanceKm será null ou não preenchido para musculação,
        // mas o campo pode ser útil se esta tela for reutilizada para outras atividades manuais.
        distanceKm: _currentModality == WorkoutModality.corrida.name // Exemplo, não aplicável para musculacao
            ? double.tryParse(_distanceController.text)
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        // Campos de GPS não são preenchidos aqui
        latitude: null,
        longitude: null,
        pathCoordinates: null,
      );

      historyJsonList.add(json.encode(newEntry.toJson()));
      await prefs.setStringList(SharedPreferencesKeys.activityHistory, historyJsonList);

      // NOVO: Atualizar contador de treinos concluídos esta semana
      final currentCompleted = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;
      await prefs.setInt(SharedPreferencesKeys.completedWorkoutsThisWeek, currentCompleted + 1);

      // Notificar o serviço de conquistas sobre a conclusão da atividade
      await _achievementService.notifyWorkoutCompleted(_currentModality);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Atividade de ${_currentModality.toCapitalized()} registrada!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
          ),
        );
        // Pop duas vezes para voltar para a tela antes da ActivitySelectionScreen (provavelmente a HomeScreen)
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // O campo de distância não é relevante para musculação neste fluxo.
    // Poderia ser condicionalmente mostrado se esta tela fosse mais genérica.
    // final bool showDistanceField = _currentModality == WorkoutModality.corrida.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar ${_currentModality.toCapitalized()}', // Título dinâmico
          style: AppStyles.titleTextStyle.copyWith(fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalhes da Atividade',
                style: AppStyles.headingStyle,
              ),
              const SizedBox(height: 24),
              // A modalidade é definida pela seleção anterior, não precisa de Dropdown aqui.
              Text('Modalidade: ${_currentModality.toCapitalized()}', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                // Usar InputDecoration do AppStyles global
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Duração (minutos)',
                  hintText: 'Ex: 45',
                ),
                style: AppStyles.bodyStyle,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite a duração';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                    return 'Duração inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // O campo de distância pode ser omitido para musculação
              // if (showDistanceField) ...[
              //   TextFormField(
              //     controller: _distanceController,
              //     keyboardType: TextInputType.number,
              //     decoration: AppStyles.inputDecoration.copyWith(
              //       labelText: 'Distância (km, opcional)',
              //       hintText: 'Ex: 5.5',
              //     ),
              //     style: AppStyles.bodyStyle,
              //   ),
              //   const SizedBox(height: 16),
              // ],
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Notas (opcional)',
                  hintText: 'Adicione observações sobre o treino',
                ),
                style: AppStyles.bodyStyle,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveActivity,
                  style: AppStyles.buttonStyle,
                  child: Text('Registrar Atividade', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}