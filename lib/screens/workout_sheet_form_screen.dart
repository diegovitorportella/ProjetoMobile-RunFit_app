// lib/screens/workout_sheet_form_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:runfit_app/data/models/workout_sheet.dart'; // Importa o modelo
import 'package:runfit_app/utils/app_colors.dart'; // Para as cores
import 'package:runfit_app/utils/app_styles.dart'; // Para os estilos
import 'package:runfit_app/utils/app_constants.dart'; // Para os enums e extensão de String
import 'package:image_picker/image_picker.dart'; // Para seleção de imagem (opcional)
import 'dart:io'; // Para File (opcional)
import 'package:flutter/foundation.dart' show kIsWeb; // Para kIsWeb (opcional)


class WorkoutSheetFormScreen extends StatefulWidget {
  final WorkoutSheet? workoutSheet; // Opcional: para edição de ficha existente

  const WorkoutSheetFormScreen({super.key, this.workoutSheet});

  @override
  State<WorkoutSheetFormScreen> createState() => _WorkoutSheetFormScreenState();
}

class _WorkoutSheetFormScreenState extends State<WorkoutSheetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker(); // Para seleção de imagem

  late String _sheetId;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late WorkoutModality _selectedModality;
  late WorkoutLevel _selectedLevel;
  late List<Exercise> _exercises; // Lista de exercícios para esta ficha
  late int _selectedIconCodePoint; // Para o ícone da ficha

  @override
  void initState() {
    super.initState();
    if (widget.workoutSheet != null) {
      // Modo Edição
      _sheetId = widget.workoutSheet!.id;
      _nameController = TextEditingController(text: widget.workoutSheet!.name);
      _descriptionController = TextEditingController(text: widget.workoutSheet!.description);
      _selectedModality = widget.workoutSheet!.modality;
      _selectedLevel = widget.workoutSheet!.level;
      // Cria cópias dos exercícios para que a edição não afete a ficha original até salvar
      _exercises = List.from(widget.workoutSheet!.exercises.map((e) => Exercise.fromJson(e.toJson())));
      _selectedIconCodePoint = widget.workoutSheet!.icon ?? Icons.fitness_center.codePoint; // Padrão se não houver
    } else {
      // Modo Criação
      _sheetId = _uuid.v4(); // Gera um novo ID para a ficha
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedModality = WorkoutModality.musculacao; // Padrão
      _selectedLevel = WorkoutLevel.iniciante; // Padrão
      _exercises = [];
      _selectedIconCodePoint = Icons.fitness_center.codePoint; // Ícone padrão
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _exercises.forEach((exercise) {
      // Não há controllers de texto diretos para exercícios, mas se houvesse, seriam descartados aqui.
    });
    super.dispose();
  }

  // Função para adicionar um novo exercício à lista
  void _addExercise() {
    setState(() {
      _exercises.add(Exercise(name: '', setsReps: '', isCompleted: false));
    });
  }

  // Função para remover um exercício da lista
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  // Função para salvar a ficha (ou retornar para a tela anterior)
  void _saveWorkoutSheet() {
    if (_formKey.currentState!.validate()) {
      if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, adicione pelo menos um exercício à ficha.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      final newWorkoutSheet = WorkoutSheet(
        id: _sheetId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        modality: _selectedModality,
        level: _selectedLevel,
        exercises: _exercises.map((e) => e.copyWith(isCompleted: false)).toList(), // Garante que estejam como não concluídos ao criar/salvar
        icon: _selectedIconCodePoint,
        isActive: false, // Fichas criadas/editadas não são ativadas automaticamente
      );

      // Retorna a nova ficha para a tela anterior (WorkoutSheetsScreen)
      Navigator.of(context).pop(newWorkoutSheet);
    }
  }

  // Abre um modal para adicionar/editar um exercício
  Future<void> _showExerciseFormModal({Exercise? exercise, int? index}) async {
    final TextEditingController nameController = TextEditingController(text: exercise?.name);
    final TextEditingController setsRepsController = TextEditingController(text: exercise?.setsReps);
    final TextEditingController loadController = TextEditingController(text: exercise?.load);
    final TextEditingController notesController = TextEditingController(text: exercise?.notes);
    String? imageUrl = exercise?.imageUrl; // Para armazenar o caminho da imagem

    final _exerciseFormKey = GlobalKey<FormState>();

    // Lista de ícones disponíveis para escolher (apenas alguns para exemplo)
    final List<IconData> availableIcons = [
      Icons.fitness_center,
      Icons.run_circle,
      Icons.self_improvement,
      Icons.rowing,
      Icons.directions_bike,
      Icons.sports_gymnastics,
    ];


    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Para o borderRadius do Container
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder para atualizar o modal internamente
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
                            key: _exerciseFormKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  exercise == null ? 'Novo Exercício' : 'Editar Exercício',
                                  style: AppStyles.headingStyle,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: nameController,
                                  style: AppStyles.bodyStyle,
                                  decoration: const InputDecoration(labelText: 'Nome do Exercício'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, digite o nome do exercício.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: setsRepsController,
                                  style: AppStyles.bodyStyle,
                                  decoration: const InputDecoration(labelText: 'Séries e Repetições'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, digite as séries e repetições.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: loadController,
                                  style: AppStyles.bodyStyle,
                                  decoration: AppStyles.inputDecoration.copyWith( // Usar AppStyles.inputDecoration
                                    labelText: 'Carga (opcional)',
                                    hintText: 'Ex: 10kg, Peso Corporal, 5lb',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: notesController,
                                  style: AppStyles.bodyStyle,
                                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                // Seletor de Imagem (simplificado, sem persistência real de arquivo)
                                // Para o MVP sem DB, vamos apenas permitir a inserção de caminhos de assets existentes
                                TextFormField(
                                  initialValue: imageUrl, // Exibe o caminho atual
                                  decoration: const InputDecoration(
                                    labelText: 'Caminho da Imagem (assets/images/...)',
                                    hintText: 'Ex: images/AgachamentoLivre.webp',
                                  ),
                                  style: AppStyles.bodyStyle,
                                  onChanged: (value) {
                                    imageUrl = value; // Atualiza a variável local
                                  },
                                ),
                                // Botão para abrir o seletor de imagens da galeria/câmera (se a imagem for persistida, isso seria útil)
                                // Por enquanto, como não estamos persistindo a imagem localmente com image_picker
                                // de forma complexa (apenas o path), esta parte é mais um placeholder ou para Web
                                const SizedBox(height: 16),
                                if (imageUrl != null && imageUrl!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.asset(
                                        imageUrl!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 150,
                                          color: AppColors.borderColor,
                                          child: Center(
                                            child: Icon(Icons.image_not_supported, color: AppColors.textSecondaryColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('Cancelar', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor)),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_exerciseFormKey.currentState!.validate()) {
                                          final newExercise = Exercise(
                                            name: nameController.text.trim(),
                                            setsReps: setsRepsController.text.trim(),
                                            load: loadController.text.trim().isEmpty ? null : loadController.text.trim(),
                                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                            imageUrl: imageUrl?.isEmpty ?? true ? null : imageUrl, // Salva o caminho da imagem
                                            isCompleted: false,
                                          );
                                          Navigator.of(context).pop(newExercise); // Retorna o exercício salvo
                                        }
                                      },
                                      style: AppStyles.buttonStyle,
                                      child: Text(exercise == null ? 'Adicionar' : 'Salvar', style: AppStyles.buttonTextStyle),
                                    ),
                                  ],
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
      if (result != null && result is Exercise) {
        setState(() {
          if (index != null) {
            _exercises[index] = result; // Edita o exercício existente
          } else {
            _exercises.add(result); // Adiciona um novo exercício
          }
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutSheet == null ? 'Criar Nova Ficha' : 'Editar Ficha'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: AppStyles.bodyStyle,
                decoration: const InputDecoration(labelText: 'Nome da Ficha'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o nome da ficha.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: AppStyles.bodyStyle,
                decoration: const InputDecoration(labelText: 'Descrição da Ficha'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite a descrição da ficha.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WorkoutModality>(
                value: _selectedModality,
                decoration: const InputDecoration(labelText: 'Modalidade'),
                style: AppStyles.bodyStyle,
                dropdownColor: AppColors.cardColor,
                items: WorkoutModality.values.map((modality) {
                  return DropdownMenuItem(
                    value: modality,
                    child: Text(modality.name.toCapitalized(), style: AppStyles.bodyStyle),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModality = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WorkoutLevel>(
                value: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Nível'),
                style: AppStyles.bodyStyle,
                dropdownColor: AppColors.cardColor,
                items: WorkoutLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.name.toCapitalized(), style: AppStyles.bodyStyle),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Exercícios:',
                style: AppStyles.headingStyle,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.cardColor.withOpacity(0.7),
                    child: ListTile(
                      title: Text(exercise.name.isEmpty ? 'Novo Exercício' : exercise.name, style: AppStyles.bodyStyle),
                      subtitle: Text(
                        '${exercise.setsReps} ${exercise.load != null && exercise.load!.isNotEmpty ? '(${exercise.load})' : ''}',
                        style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.textPrimaryColor),
                            onPressed: () => _showExerciseFormModal(exercise: exercise, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.errorColor),
                            onPressed: () => _removeExercise(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add, color: AppColors.primaryColor),
                  label: Text('Adicionar Exercício', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.primaryColor)),
                  style: AppStyles.buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(AppColors.successColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveWorkoutSheet,
                  style: AppStyles.buttonStyle,
                  child: Text('Salvar Ficha de Treino', style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}