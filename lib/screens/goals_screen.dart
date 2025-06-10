// lib/screens/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:runfit_app/data/models/goal.dart'; // Importa o modelo Goal
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Para os enums e StringCasingExtension

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _userGoals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserGoals();
  }

  Future<void> _loadUserGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? goalsJson = prefs.getString(SharedPreferencesKeys.userGoalsList);

    if (goalsJson != null) {
      final List<dynamic> jsonList = jsonDecode(goalsJson);
      setState(() {
        _userGoals = jsonList.map((json) => Goal.fromJson(json)).toList();
        _userGoals.sort((a, b) {
          // Concluídas para o final da lista, em andamento para o início
          if (a.isCompleted && !b.isCompleted) return 1;
          if (!a.isCompleted && b.isCompleted) return -1;
          // Dentro de cada grupo, as mais recentes primeiro
          return b.createdAt.compareTo(a.createdAt);
        });
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_userGoals.map((goal) => goal.toJson()).toList());
    await prefs.setString(SharedPreferencesKeys.userGoalsList, jsonString);
  }

  // NOVO: Método para exibir o formulário de criação/edição de meta
  void _showGoalFormModal({Goal? goal}) async {
    final TextEditingController nameController = TextEditingController(text: goal?.name);
    GoalType? selectedType = goal?.type;
    TextEditingController targetValueController = TextEditingController(text: goal?.targetValue.toString());
    GoalUnit? selectedUnit = goal?.unit;
    DateTime? selectedDeadline = goal?.deadline;
    TextEditingController notesController = TextEditingController(text: goal?.notes);

    final _goalFormKey = GlobalKey<FormState>();

    // Define as unidades disponíveis com base no tipo de meta
    List<GoalUnit> _getUnitsForGoalType(GoalType type) {
      switch (type) {
        case GoalType.distance:
          return [GoalUnit.km, GoalUnit.meters, GoalUnit.miles];
        case GoalType.duration:
          return [GoalUnit.minutes, GoalUnit.hours];
        case GoalType.weight:
          return [GoalUnit.kg, GoalUnit.lbs];
        case GoalType.frequency:
          return [GoalUnit.times];
        case GoalType.workoutSheetCompletion:
          return [GoalUnit.none]; // Nenhuma unidade para conclusão de ficha
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondaryColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _goalFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(goal == null ? 'Nova Meta' : 'Editar Meta', style: AppStyles.headingStyle),
                                const SizedBox(height: 24),

                                TextFormField(
                                  controller: nameController,
                                  style: AppStyles.bodyStyle,
                                  decoration: AppStyles.inputDecoration.copyWith(labelText: 'Nome da Meta'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, digite o nome da meta.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                DropdownButtonFormField<GoalType>(
                                  value: selectedType,
                                  decoration: AppStyles.inputDecoration.copyWith(labelText: 'Tipo de Meta'),
                                  style: AppStyles.bodyStyle,
                                  dropdownColor: AppColors.cardColor,
                                  items: GoalType.values.map((type) {
                                    String formattedName;
                                    switch (type) {
                                      case GoalType.distance:
                                        formattedName = 'Distância';
                                        break;
                                      case GoalType.duration:
                                        formattedName = 'Duração';
                                        break;
                                      case GoalType.weight:
                                        formattedName = 'Peso';
                                        break;
                                      case GoalType.frequency:
                                        formattedName = 'Frequência';
                                        break;
                                      case GoalType.workoutSheetCompletion:
                                        formattedName = 'Conclusão de Ficha';
                                        break;
                                    }
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(formattedName, style: AppStyles.bodyStyle),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    modalSetState(() {
                                      selectedType = value;
                                      selectedUnit = null; // Reseta a unidade ao mudar o tipo
                                      if (selectedType == GoalType.workoutSheetCompletion) {
                                        targetValueController.text = '1.0'; // Define 1 para conclusão de ficha
                                        selectedUnit = GoalUnit.none;
                                      } else {
                                        targetValueController.clear();
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) return 'Selecione o tipo de meta.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: targetValueController,
                                        keyboardType: TextInputType.number,
                                        style: AppStyles.bodyStyle,
                                        decoration: AppStyles.inputDecoration.copyWith(
                                            labelText: selectedType == GoalType.workoutSheetCompletion ? 'Valor (1)' : 'Valor da Meta'
                                        ),
                                        readOnly: selectedType == GoalType.workoutSheetCompletion,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Digite o valor.';
                                          }
                                          if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                                            return 'Valor inválido.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<GoalUnit>(
                                        value: selectedUnit,
                                        decoration: AppStyles.inputDecoration.copyWith(labelText: 'Unidade'),
                                        style: AppStyles.bodyStyle,
                                        dropdownColor: AppColors.cardColor,
                                        items: selectedType == null
                                            ? []
                                            : _getUnitsForGoalType(selectedType!).map((unit) {
                                          String formattedUnit;
                                          switch (unit) {
                                            case GoalUnit.km:
                                              formattedUnit = 'Km';
                                              break;
                                            case GoalUnit.meters:
                                              formattedUnit = 'Metros';
                                              break;
                                            case GoalUnit.miles:
                                              formattedUnit = 'Milhas';
                                              break;
                                            case GoalUnit.minutes:
                                              formattedUnit = 'Minutos';
                                              break;
                                            case GoalUnit.hours:
                                              formattedUnit = 'Horas';
                                              break;
                                            case GoalUnit.kg:
                                              formattedUnit = 'Kg';
                                              break;
                                            case GoalUnit.lbs:
                                              formattedUnit = 'Lbs';
                                              break;
                                            case GoalUnit.times:
                                              formattedUnit = 'Vezes';
                                              break;
                                            case GoalUnit.none:
                                              formattedUnit = 'N/A'; // Ou vazio, dependendo do contexto
                                              break;
                                          }
                                          return DropdownMenuItem(
                                            value: unit,
                                            child: Text(formattedUnit, style: AppStyles.bodyStyle),
                                          );
                                        }).toList(),
                                        onChanged: selectedType == GoalType.workoutSheetCompletion
                                            ? null // Desabilita o dropdown se for conclusão de ficha
                                            : (value) {
                                          modalSetState(() {
                                            selectedUnit = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (selectedType != GoalType.workoutSheetCompletion && value == null) {
                                            return 'Unidade?';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDeadline ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(DateTime.now().year + 5),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.dark(
                                              primary: AppColors.accentColor,
                                              onPrimary: AppColors.textPrimaryColor,
                                              surface: AppColors.cardColor,
                                              onSurface: AppColors.textPrimaryColor,
                                            ),
                                            textButtonTheme: TextButtonThemeData(
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.accentColor,
                                              ),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      modalSetState(() {
                                        selectedDeadline = picked;
                                      });
                                    }
                                  },
                                  style: AppStyles.buttonStyle.copyWith(
                                    backgroundColor: MaterialStateProperty.all(AppColors.cardColor),
                                    side: MaterialStateProperty.all(BorderSide(color: AppColors.borderColor)),
                                  ),
                                  child: Text(
                                    selectedDeadline == null
                                        ? 'Definir Prazo (Opcional)'
                                        : 'Prazo: ${DateFormat('dd/MM/yyyy').format(selectedDeadline!)}',
                                    style: AppStyles.bodyStyle,
                                  ),
                                ),
                                if (selectedDeadline != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        modalSetState(() {
                                          selectedDeadline = null;
                                        });
                                      },
                                      child: Text('Remover Prazo', style: AppStyles.smallTextStyle.copyWith(color: AppColors.errorColor)),
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: notesController,
                                  style: AppStyles.bodyStyle,
                                  decoration: AppStyles.inputDecoration.copyWith(labelText: 'Notas (opcional)'),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),

                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_goalFormKey.currentState!.validate() && selectedType != null && (selectedType == GoalType.workoutSheetCompletion || selectedUnit != null)) {
                                        final newGoal = Goal(
                                          id: goal?.id, // Mantém o ID se for edição
                                          name: nameController.text.trim(),
                                          type: selectedType!,
                                          targetValue: double.parse(targetValueController.text.trim()),
                                          unit: selectedUnit ?? GoalUnit.none, // Garante que a unidade não é nula
                                          currentValue: goal?.currentValue ?? 0.0, // Mantém o progresso atual na edição
                                          deadline: selectedDeadline,
                                          createdAt: goal?.createdAt,
                                          isCompleted: goal?.isCompleted ?? false,
                                          completedAt: goal?.completedAt,
                                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                        );
                                        Navigator.of(context).pop(newGoal);
                                      }
                                    },
                                    style: AppStyles.buttonStyle,
                                    child: Text(goal == null ? 'Adicionar Meta' : 'Salvar Meta', style: AppStyles.buttonTextStyle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is Goal) {
        setState(() {
          final int existingIndex = _userGoals.indexWhere((g) => g.id == result.id);
          if (existingIndex != -1) {
            _userGoals[existingIndex] = result; // Edita a meta existente
          } else {
            _userGoals.add(result); // Adiciona nova meta
          }
          _saveUserGoals(); // Salva após adicionar/editar
          _loadUserGoals(); // Recarrega para ordenar e exibir
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(goal == null ? 'Meta criada com sucesso!' : 'Meta salva com sucesso!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
          ),
        );
      }
    });
  }

  // NOVO: Método para confirmar e excluir uma meta
  void _confirmDeleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Text('Excluir Meta?', style: AppStyles.headingStyle),
          content: Text('Tem certeza que deseja excluir a meta "${goal.name}"?', style: AppStyles.bodyStyle),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _userGoals.removeWhere((g) => g.id == goal.id);
                  _saveUserGoals();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Meta "${goal.name}" excluída!', style: AppStyles.smallTextStyle),
                    backgroundColor: AppColors.errorColor.withAlpha((255 * 0.7).round()),
                  ),
                );
              },
              child: Text('Excluir', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.errorColor)),
            ),
          ],
        );
      },
    );
  }

  // NOVO: Método para marcar/desmarcar meta como concluída manualmente
  void _toggleGoalCompletion(Goal goal) {
    setState(() {
      final int index = _userGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        final updatedGoal = goal.copyWith(
          isCompleted: !goal.isCompleted,
          completedAt: !goal.isCompleted ? DateTime.now() : null, // Define ou limpa a data de conclusão
          currentValue: !goal.isCompleted ? goal.targetValue : 0.0, // Se concluiu, assume 100%
        );
        _userGoals[index] = updatedGoal;
        _saveUserGoals();
        _loadUserGoals(); // Recarrega para reordenar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meta "${goal.name}" ${updatedGoal.isCompleted ? 'concluída!' : 'reaberta!'}', style: AppStyles.smallTextStyle),
            backgroundColor: updatedGoal.isCompleted ? AppColors.successColor.withAlpha((255 * 0.7).round()) : AppColors.warningColor.withAlpha((255 * 0.7).round()),
          ),
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Metas', style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showGoalFormModal(), // Botão para adicionar nova meta
            tooltip: 'Adicionar nova meta',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userGoals.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Você ainda não tem metas! Que tal definir uma?',
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showGoalFormModal(),
                style: AppStyles.buttonStyle,
                child: Text('Criar Primeira Meta', style: AppStyles.buttonTextStyle),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _userGoals.length,
        itemBuilder: (context, index) {
          final goal = _userGoals[index];
          double progress = goal.targetValue > 0 ? (goal.currentValue / goal.targetValue).clamp(0.0, 1.0) : 0.0;
          Color progressColor = goal.isCompleted ? AppColors.successColor : AppColors.accentColor;
          IconData goalIcon;

          switch (goal.type) {
            case GoalType.distance:
              goalIcon = Icons.directions_run;
              break;
            case GoalType.duration:
              goalIcon = Icons.timer;
              break;
            case GoalType.weight:
              goalIcon = Icons.fitness_center;
              break;
            case GoalType.frequency:
              goalIcon = Icons.calendar_today;
              break;
            case GoalType.workoutSheetCompletion:
              goalIcon = Icons.assignment_turned_in;
              break;
          }


          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppColors.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: goal.isCompleted ? AppColors.successColor : AppColors.borderColor,
                width: 1.5,
              ),
            ),
            elevation: goal.isCompleted ? 4 : 2,
            child: InkWell(
              onTap: () => _showGoalFormModal(goal: goal), // Editar meta ao tocar
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(goalIcon, color: progressColor, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Ícone de conclusão ou ação para marcar
                        if (goal.isCompleted)
                          Icon(Icons.check_circle, color: AppColors.successColor, size: 24)
                        else
                          IconButton(
                            icon: Icon(Icons.check_circle_outline, color: AppColors.textSecondaryColor),
                            onPressed: () => _toggleGoalCompletion(goal),
                            tooltip: 'Marcar como Concluída',
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.errorColor),
                          onPressed: () => _confirmDeleteGoal(goal),
                          tooltip: 'Excluir Meta',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meta: ${goal.targetValue.toStringAsFixed(goal.type == GoalType.distance || goal.type == GoalType.weight ? 1 : 0)} ${goal.unit.name}',
                      style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                    ),
                    if (goal.notes != null && goal.notes!.isNotEmpty)
                      Text(
                        'Notas: ${goal.notes}',
                        style: AppStyles.smallTextStyle.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    if (goal.type != GoalType.workoutSheetCompletion) // Não exibe progresso para conclusão de ficha
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progresso: ${goal.currentValue.toStringAsFixed(goal.type == GoalType.distance || goal.type == GoalType.weight ? 1 : 0)} / ${goal.targetValue.toStringAsFixed(goal.type == GoalType.distance || goal.type == GoalType.weight ? 1 : 0)} ${goal.unit.name} (${(progress * 100).toStringAsFixed(0)}%)',
                            style: AppStyles.smallTextStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.borderColor,
                            color: progressColor,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                    if (goal.deadline != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Prazo: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}',
                        style: AppStyles.smallTextStyle.copyWith(
                          color: goal.isCompleted
                              ? AppColors.textSecondaryColor
                              : (goal.deadline!.isBefore(DateTime.now()) ? AppColors.errorColor : AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                    if (goal.isCompleted && goal.completedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Concluída em: ${DateFormat('dd/MM/yyyy').format(goal.completedAt!)}',
                        style: AppStyles.smallTextStyle.copyWith(color: AppColors.successColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}