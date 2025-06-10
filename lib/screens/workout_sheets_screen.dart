// lib/screens/workout_sheets_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:runfit_app/data/models/workout_sheet.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:flutter/cupertino.dart'; // Para CupertinoSlidingSegmentedControl
import 'package:runfit_app/screens/workout_sheet_form_screen.dart'; // NOVO: Importar a tela de formulário

class WorkoutSheetsScreen extends StatefulWidget {
  const WorkoutSheetsScreen({super.key});

  @override
  State<WorkoutSheetsScreen> createState() => _WorkoutSheetsScreenState();
}

class _WorkoutSheetsScreenState extends State<WorkoutSheetsScreen> {
  List<WorkoutSheet> _allWorkoutSheets = [];
  String? _activeWorkoutSheetId;
  String? _userModality;
  String? _userLevel;

  // Variáveis de filtro
  String? _selectedModalityFilter;
  String? _selectedLevelFilter;
  final TextEditingController _searchController = TextEditingController();

  // Mapa para agrupar as fichas por modalidade (ou outra categoria)
  Map<String, List<WorkoutSheet>> _groupedWorkouts = {};

  // NOVO: Lista para armazenar fichas criadas pelo usuário (não persistidas entre sessões)
  // Estas fichas serão adicionadas à _allWorkoutSheets em tempo de execução
  final List<WorkoutSheet> _userCreatedWorkouts = [];


  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadUserPreferences();
    await _loadAllWorkoutSheets();
    _applyFiltersAndGroupWorkouts(); // Chamada inicial
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userModality = prefs.getString(SharedPreferencesKeys.userModality);
      _userLevel = prefs.getString(SharedPreferencesKeys.userLevel);
      _activeWorkoutSheetId = prefs.getString(SharedPreferencesKeys.activeWorkoutSheetId);

      // Definir filtros iniciais baseados nas preferências do usuário
      _selectedModalityFilter = _userModality;
      _selectedLevelFilter = _userLevel;
    });
  }

  Future<void> _loadAllWorkoutSheets() async {
    try {
      final String response = await rootBundle.loadString('assets/data/workout_sheets.json');
      final data = json.decode(response) as List;
      setState(() {
        // Carrega as fichas padrão
        _allWorkoutSheets = data.map((json) => WorkoutSheet.fromJson(json)).toList();
        // Adiciona as fichas criadas pelo usuário na sessão atual
        _allWorkoutSheets.addAll(_userCreatedWorkouts);


        _allWorkoutSheets.forEach((sheet) {
          // Marca a ficha como ativa se o ID corresponder
          if (sheet.id == _activeWorkoutSheetId) {
            sheet.isActive = true;
          }
        });
      });
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar fichas de treino: $e');
    }
  }

  // NOVO: Método para aplicar filtros e agrupar
  void _applyFiltersAndGroupWorkouts() {
    // A lista a ser filtrada deve incluir tanto as fichas padrão quanto as criadas pelo usuário
    List<WorkoutSheet> currentWorkouts = List.from(_allWorkoutSheets);
    // Garante que não adiciona duplicatas se _loadAllWorkoutSheets já as incluiu
    currentWorkouts.addAll(_userCreatedWorkouts.where((sheet) => !_allWorkoutSheets.any((s) => s.id == sheet.id)));


    List<WorkoutSheet> filteredWorkouts = currentWorkouts.where((sheet) {
      bool matchesModality = true;
      bool matchesLevel = true;
      bool matchesSearch = true;

      // Filtro por Modalidade
      if (_selectedModalityFilter != null && _selectedModalityFilter != 'Todos') {
        matchesModality = sheet.modality.name == _selectedModalityFilter;
      }

      // Filtro por Nível
      if (_selectedLevelFilter != null && _selectedLevelFilter != 'Todos') {
        matchesLevel = sheet.level.name == _selectedLevelFilter;
      }

      // Filtro por busca (nome ou descrição)
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        matchesSearch = sheet.name.toLowerCase().contains(query) ||
            sheet.description.toLowerCase().contains(query);
      }

      return matchesModality && matchesLevel && matchesSearch;
    }).toList();

    // Agrupamento
    Map<String, List<WorkoutSheet>> newGroupedWorkouts = {};
    for (var sheet in filteredWorkouts) {
      final category = sheet.modality.name.toCapitalized(); // Agrupar por modalidade
      if (!newGroupedWorkouts.containsKey(category)) {
        newGroupedWorkouts[category] = [];
      }
      newGroupedWorkouts[category]!.add(sheet);
    }

    setState(() {
      _groupedWorkouts = newGroupedWorkouts;
    });
  }

  Future<void> _toggleActiveSheet(String sheetId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentActiveSheetId = prefs.getString(SharedPreferencesKeys.activeWorkoutSheetId);

    // Encontrar a ficha que está sendo ativada/desativada
    // Deve procurar tanto nas fichas padrão quanto nas criadas pelo usuário
    final targetSheet = [..._allWorkoutSheets, ..._userCreatedWorkouts].firstWhere((sheet) => sheet.id == sheetId);
    final bool willBeActive = !targetSheet.isActive; // Inverte o estado

    setState(() {
      // Desativar a ficha atualmente ativa, se houver
      if (currentActiveSheetId != null && currentActiveSheetId != sheetId) {
        // Procura e desativa na lista _allWorkoutSheets
        final oldActiveSheetIndex = _allWorkoutSheets.indexWhere((sheet) => sheet.id == currentActiveSheetId);
        if (oldActiveSheetIndex != -1) {
          _allWorkoutSheets[oldActiveSheetIndex].isActive = false;
        } else {
          // Também verificar nas fichas criadas pelo usuário
          final oldUserActiveSheetIndex = _userCreatedWorkouts.indexWhere((sheet) => sheet.id == currentActiveSheetId);
          if (oldUserActiveSheetIndex != -1) {
            _userCreatedWorkouts[oldUserActiveSheetIndex].isActive = false;
          }
        }
      }

      targetSheet.isActive = willBeActive;

      if (willBeActive) {
        _activeWorkoutSheetId = sheetId;
        // Salva o JSON completo da ficha (com o estado inicial dos exercícios resetado)
        // Garante que a ficha salva não está ativada, para que o progresso seja resetado
        final sheetToSave = WorkoutSheet(
          id: targetSheet.id,
          name: targetSheet.name,
          description: targetSheet.description,
          modality: targetSheet.modality,
          level: targetSheet.level,
          // Cria uma nova lista de exercícios com isCompleted = false
          exercises: targetSheet.exercises.map((e) => Exercise(
            name: e.name,
            setsReps: e.setsReps,
            notes: e.notes,
            imageUrl: e.imageUrl,
            load: e.load, // Inclui o campo 'load'
            isCompleted: false, // IMPORTANTE: Reseta o estado aqui
          )).toList(),
          icon: targetSheet.icon,
          isActive: true,
        );
        prefs.setString(SharedPreferencesKeys.activeWorkoutSheetId, sheetId);
        prefs.setString(SharedPreferencesKeys.activeWorkoutSheetData, json.encode(sheetToSave.toJson()));
      } else {
        _activeWorkoutSheetId = null;
        prefs.remove(SharedPreferencesKeys.activeWorkoutSheetId);
        prefs.remove(SharedPreferencesKeys.activeWorkoutSheetData);
      }
    });
    _applyFiltersAndGroupWorkouts(); // Reaplicar filtros para atualizar o estado visual
  }

  // NOVO: Método para navegar para a tela de criação/edição
  void _navigateToWorkoutSheetForm({WorkoutSheet? workoutSheet}) async {
    final result = await Navigator.push<WorkoutSheet>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSheetFormScreen(workoutSheet: workoutSheet),
      ),
    );

    if (result != null) {
      setState(() {
        if (workoutSheet == null) {
          // É uma nova ficha, adiciona à lista de fichas criadas pelo usuário
          _userCreatedWorkouts.add(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ficha "${result.name}" criada com sucesso!', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
            ),
          );
        } else {
          // É uma ficha existente sendo editada
          // Remove a versão antiga e adiciona a nova na lista de fichas criadas pelo usuário
          final int indexInUserCreated = _userCreatedWorkouts.indexWhere((sheet) => sheet.id == result.id);
          if (indexInUserCreated != -1) {
            _userCreatedWorkouts[indexInUserCreated] = result;
          } else {
            // Se a ficha editada era uma ficha padrão (que não está em _userCreatedWorkouts),
            // a adicionamos a _userCreatedWorkouts e a removemos de _allWorkoutSheets (se for uma cópia).
            // Em um cenário real com persistência, a lógica seria diferente aqui.
            // Para esta iteração, vamos simplesmente assumir que edições são de fichas do usuário
            // ou uma cópia da padrão que agora é "do usuário" para esta sessão.
            // Para simplificar, se não encontrou em userCreated, adiciona como nova.
            _userCreatedWorkouts.add(result);
            // Também, se uma ficha padrão foi editada, ela se torna uma ficha de usuário.
            // Em uma solução persistente, você a salvaria em um local separado.
            // Aqui, para a sessão, a removemos da lista _allWorkoutSheets para evitar duplicatas e a tratamos como do usuário.
            _allWorkoutSheets.removeWhere((sheet) => sheet.id == result.id); // Remove a versão antiga da lista geral.
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ficha "${result.name}" editada com sucesso!', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
            ),
          );
        }
      });
      // Recarrega todas as fichas, o que vai incluir as criadas/editadas na sessão atual
      _loadAllWorkoutSheets();
      _applyFiltersAndGroupWorkouts(); // Reaplicar filtros para atualizar o estado visual
    }
  }

  // NOVO: Helper para verificar se a ficha é uma das fichas padrão (não editável inicialmente)
  // Isso é uma simplificação. Em um sistema com persistência, você teria uma forma
  // mais robusta de diferenciar fichas padrão das criadas pelo usuário.
  // Por enquanto, consideramos padrão as que vêm do JSON inicial e não as que o usuário criou.
  bool _isDefaultWorkoutSheet(String id) {
    // Verifica se o ID existe na lista original carregada do JSON (antes de adicionar as criadas pelo usuário)
    // Para ser mais preciso, você precisaria ter uma lista _defaultWorkoutSheets separada.
    // Mas para este escopo, a lógica atual é aceitável, pois _userCreatedWorkouts já as diferencia.
    return !_userCreatedWorkouts.any((sheet) => sheet.id == id);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Fichas de Treino'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de Fundo
          Image.asset(
            'assets/images/tela_musculaçao.png',
            fit: BoxFit.cover,
            colorBlendMode: BlendMode.darken,
            color: Colors.black.withOpacity(0.6),
          ),

          // Conteúdo da tela
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Campo de Busca
                    TextFormField(
                      controller: _searchController,
                      style: AppStyles.bodyStyle.copyWith(
                          color: AppColors.textPrimaryColor),
                      decoration: InputDecoration(
                        labelText: 'Buscar ficha',
                        hintText: 'Digite o nome ou descrição da ficha',
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.textSecondaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear,
                              color: AppColors.textSecondaryColor),
                          onPressed: () {
                            _searchController.clear();
                            _applyFiltersAndGroupWorkouts();
                          },
                        )
                            : null,
                      ),
                      onChanged: (value) => _applyFiltersAndGroupWorkouts(),
                    ),
                    const SizedBox(height: 16),

                    // Filtro por Modalidade
                    DropdownButtonFormField<String>(
                      value: _selectedModalityFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por Modalidade',
                      ),
                      style: AppStyles.bodyStyle
                          .copyWith(color: AppColors.textPrimaryColor),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedModalityFilter = newValue;
                          _applyFiltersAndGroupWorkouts();
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'Todos',
                          child: Text('Todas as Modalidades',
                              style: AppStyles.bodyStyle),
                        ),
                        ...WorkoutModality.values
                            .map<DropdownMenuItem<String>>(
                                (WorkoutModality value) {
                              return DropdownMenuItem<String>(
                                value: value.name,
                                child: Text(value.name.toCapitalized(),
                                    style: AppStyles.bodyStyle),
                              );
                            }).toList(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filtro por Nível
                    DropdownButtonFormField<String>(
                      value: _selectedLevelFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por Nível',
                      ),
                      style: AppStyles.bodyStyle
                          .copyWith(color: AppColors.textPrimaryColor),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLevelFilter = newValue;
                          _applyFiltersAndGroupWorkouts();
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'Todos',
                          child: Text('Todos os Níveis',
                              style: AppStyles.bodyStyle),
                        ),
                        ...WorkoutLevel.values
                            .map<DropdownMenuItem<String>>((WorkoutLevel value) {
                          return DropdownMenuItem<String>(
                            value: value.name,
                            child: Text(value.name.toCapitalized(),
                                style: AppStyles.bodyStyle),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _groupedWorkouts.isEmpty
                    ? Center(
                  child: Text(
                    'Nenhuma ficha de treino encontrada com os filtros aplicados.',
                    style: AppStyles.bodyStyle
                        .copyWith(color: AppColors.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: _groupedWorkouts.keys.map((category) {
                    final workoutsInCategory = _groupedWorkouts[category]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: AppStyles.headingStyle
                                .copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 16),
                          ...workoutsInCategory.map((sheet) {
                            final isActive =
                                sheet.id == _activeWorkoutSheetId;
                            return Column(
                              children: [
                                _buildWorkoutSheetCard(sheet, isActive),
                                if (sheet != workoutsInCategory.last)
                                  Divider(
                                      color: AppColors.textSecondaryColor
                                          .withAlpha(
                                          (255 * 0.3).round()),
                                      height: 1),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToWorkoutSheetForm(), // Chama a tela de criação
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add, color: AppColors.textPrimaryColor),
      ),
    );
  }

  // B. Melhorando o Card da Ficha de Treino
  Widget _buildWorkoutSheetCard(WorkoutSheet sheet, bool isActive) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: isActive ? AppColors.accentColor : AppColors.borderColor,
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showWorkoutSheetDetailsModal(context, sheet), // Abre o modal de detalhes
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Adicione um ícone ou imagem se disponível
                  if (sheet.icon != null)
                    Icon(IconData(sheet.icon!, fontFamily: 'MaterialIcons'),
                        color: AppColors.accentColor, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sheet.name,
                      style: AppStyles.headingStyle.copyWith(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check_circle, color: AppColors.successColor, size: 24),
                    ),
                  // NOVO: Botão de edição para fichas não-padrão (ou todas, se preferir)
                  // Por enquanto, só permite editar fichas criadas pelo usuário nesta sessão
                  if (!_isDefaultWorkoutSheet(sheet.id)) // Apenas fichas criadas pelo usuário
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.textSecondaryColor),
                      onPressed: () => _navigateToWorkoutSheetForm(workoutSheet: sheet),
                      tooltip: 'Editar ficha',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sheet.description,
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(sheet.modality.name.toCapitalized(), AppColors.secondaryAccentColor),
                  _buildInfoChip(sheet.level.name.toCapitalized(), AppColors.secondaryAccentColor),
                  // Você pode adicionar mais chips aqui (ex: duração estimada)
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            isActive ? 'Desativar Ficha?' : 'Ativar Ficha?',
                            style: AppStyles.headingStyle.copyWith(fontSize: 20),
                          ),
                          content: Text(
                            isActive
                                ? 'Tem certeza que deseja desativar a ficha "${sheet.name}"?'
                                : 'Tem certeza que deseja ativar a ficha "${sheet.name}"? Isso desativará a ficha atual, se houver, e resetará o progresso dos exercícios desta ficha.',
                            style: AppStyles.bodyStyle,
                          ),
                          backgroundColor: AppColors.cardColor,
                          titleTextStyle: AppStyles.headingStyle.copyWith(fontSize: 20, color: AppColors.textPrimaryColor),
                          contentTextStyle: AppStyles.bodyStyle.copyWith(color: AppColors.textPrimaryColor),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancelar',
                                  style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                  isActive ? 'Desativar' : 'Ativar',
                                  style: AppStyles.buttonTextStyle.copyWith(color: isActive ? AppColors.errorColor : AppColors.accentColor)),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await _toggleActiveSheet(sheet.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isActive ? 'Ficha desativada!' : 'Ficha "${sheet.name}" ativada!',
                                style: AppStyles.smallTextStyle),
                            backgroundColor: isActive
                                ? AppColors.warningColor.withAlpha((255 * 0.7).round())
                                : AppColors.successColor.withAlpha((255 * 0.7).round()),
                          ),
                        );
                      }
                    }
                  },
                  style: AppStyles.buttonStyle,
                  child: Text(isActive ? 'Ficha Ativa' : 'Ativar Ficha',
                      style: AppStyles.buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: AppStyles.smallTextStyle.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // C. Pré-visualização Detalhada da Ficha (Modal)
  void _showWorkoutSheetDetailsModal(BuildContext context, WorkoutSheet sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Inicia ocupando 70% da tela
          minChildSize: 0.4,
          maxChildSize: 0.9, // Pode expandir até 90%
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (sheet.icon != null)
                                Icon(IconData(sheet.icon!, fontFamily: 'MaterialIcons'),
                                    color: AppColors.accentColor, size: 35),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  sheet.name,
                                  style: AppStyles.headingStyle.copyWith(fontSize: 24, color: AppColors.accentColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            sheet.description,
                            style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildInfoChip(sheet.modality.name.toCapitalized(), AppColors.secondaryAccentColor),
                              const SizedBox(width: 8),
                              _buildInfoChip(sheet.level.name.toCapitalized(), AppColors.secondaryAccentColor),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Exercícios:',
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), // Importante para não ter dois scrolls
                            itemCount: sheet.exercises.length,
                            itemBuilder: (context, idx) {
                              final exercise = sheet.exercises[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exercise.setsReps,
                                      style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                                    ),
                                    if (exercise.load != null && exercise.load!.isNotEmpty) // Exibir a carga
                                      Text(
                                        'Carga: ${exercise.load}',
                                        style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                                      ),
                                    if (exercise.notes != null && exercise.notes!.isNotEmpty)
                                      Text(
                                        'Notas: ${exercise.notes}',
                                        style: AppStyles.smallTextStyle.copyWith(fontStyle: FontStyle.italic),
                                      ),
                                    // --- ADICIONADO: Exibição da imagem do exercício ---
                                    if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.asset(
                                            exercise.imageUrl!,
                                            height: 220, // AUMENTADO PARA 220
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 220, // AUMENTADO PARA 220 (para o placeholder também)
                                              color: AppColors.borderColor,
                                              child: Center(
                                                child: Icon(Icons.image_not_supported, color: AppColors.textSecondaryColor),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop(); // Fecha o modal
                                await _toggleActiveSheet(sheet.id); // Ativa a ficha
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          sheet.isActive ? 'Ficha desativada!' : 'Ficha "${sheet.name}" ativada!',
                                          style: AppStyles.smallTextStyle),
                                      backgroundColor: sheet.isActive
                                          ? AppColors.warningColor.withAlpha((255 * 0.7).round())
                                          : AppColors.successColor.withAlpha((255 * 0.7).round()),
                                    ),
                                  );
                                }
                              },
                              style: AppStyles.buttonStyle,
                              child: Text(sheet.isActive ? 'Ficha Ativa' : 'Ativar Ficha',
                                  style: AppStyles.buttonTextStyle),
                            ),
                          ),
                        ],
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
  }
}