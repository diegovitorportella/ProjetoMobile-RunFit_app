// lib/screens/workout_sheets_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Importar para jsonEncode/jsonDecode
import 'package:flutter/services.dart' show rootBundle;
import 'package:runfit_app/data/models/workout_sheet.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:flutter/cupertino.dart'; // Para CupertinoSlidingSegmentedControl
import 'package:runfit_app/screens/workout_sheet_form_screen.dart'; // NOVO: Importar a tela de formulário
import 'package:firebase_database/firebase_database.dart'; // Importar Firebase Database
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth


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


  DatabaseReference? _userWorkoutSheetsRef; // Referência ao Firebase

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userWorkoutSheetsRef = FirebaseDatabase.instance.ref('users/${user.uid}/workout_sheets');
      _initializeApp();
    } else {
      // Se não houver usuário logado, ainda carregamos as fichas padrão
      // mas as funcionalidades de salvar/deletar não estarão disponíveis.
      // ignore: avoid_print
      print('WorkoutSheetsScreen: Usuário não logado. Fichas personalizadas não serão carregadas/salvas.');
      _initializeApp(loadUserWorkouts: false); // Carrega apenas as padrão
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor, faça login para criar e gerenciar suas fichas de treino.', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      });
    }

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp({bool loadUserWorkouts = true}) async {
    await _loadUserPreferences();
    await _loadAllWorkoutSheets(loadUserWorkouts: loadUserWorkouts);
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

  Future<void> _loadAllWorkoutSheets({bool loadUserWorkouts = true}) async {
    List<WorkoutSheet> defaultSheets = [];
    List<WorkoutSheet> userSheets = [];

    try {
      final String response = await rootBundle.loadString('assets/data/workout_sheets.json');
      final data = json.decode(response) as List;
      defaultSheets = data.map((json) => WorkoutSheet.fromJson(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar fichas de treino padrão do JSON: $e');
    }

    if (loadUserWorkouts && _userWorkoutSheetsRef != null) {
      try {
        final dataSnapshot = await _userWorkoutSheetsRef!.once();
        final dynamic userData = dataSnapshot.snapshot.value;

        if (userData != null && userData is Map) {
          userData.forEach((key, value) {
            try {
              // AQUI ESTÁ A NOVA ABORDAGEM: Serializar e desserializar
              final Map<String, dynamic> typedValue = jsonDecode(jsonEncode(value));
              userSheets.add(WorkoutSheet.fromJson(typedValue));
            } catch (e) {
              // ignore: avoid_print
              print('Erro ao processar ficha do Firebase (chave: $key): $e, dado: $value');
            }
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('Erro ao carregar fichas de treino do usuário do Firebase: $e');
      }
    }

    setState(() {
      // Combina fichas padrão e fichas do usuário
      _allWorkoutSheets = [...defaultSheets, ...userSheets];

      _allWorkoutSheets.forEach((sheet) {
        // Marca a ficha como ativa se o ID corresponder
        if (sheet.id == _activeWorkoutSheetId) {
          sheet.isActive = true;
        }
      });
    });
  }


  void _applyFiltersAndGroupWorkouts() {
    List<WorkoutSheet> filteredWorkouts = _allWorkoutSheets.where((sheet) {
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

    final targetSheet = _allWorkoutSheets.firstWhere((sheet) => sheet.id == sheetId);
    final bool willBeActive = !targetSheet.isActive; // Inverte o estado

    setState(() {
      if (currentActiveSheetId != null && currentActiveSheetId != sheetId) {
        final oldActiveSheetIndex = _allWorkoutSheets.indexWhere((sheet) => sheet.id == currentActiveSheetId);
        if (oldActiveSheetIndex != -1) {
          _allWorkoutSheets[oldActiveSheetIndex].isActive = false;
        }
      }

      targetSheet.isActive = willBeActive;

      if (willBeActive) {
        _activeWorkoutSheetId = sheetId;
        final sheetToSave = WorkoutSheet(
          id: targetSheet.id,
          name: targetSheet.name,
          description: targetSheet.description,
          modality: targetSheet.modality,
          level: targetSheet.level,
          exercises: targetSheet.exercises.map((e) => Exercise(
            name: e.name,
            setsReps: e.setsReps,
            notes: e.notes,
            imageUrl: e.imageUrl,
            load: e.load,
            isCompleted: false,
          )).toList(),
          icon: targetSheet.icon,
          isActive: true,
          userId: targetSheet.userId, // Mantenha o userId
        );
        prefs.setString(SharedPreferencesKeys.activeWorkoutSheetId, sheetId);
        prefs.setString(SharedPreferencesKeys.activeWorkoutSheetData, json.encode(sheetToSave.toJson()));
      } else {
        _activeWorkoutSheetId = null;
        prefs.remove(SharedPreferencesKeys.activeWorkoutSheetId);
        prefs.remove(SharedPreferencesKeys.activeWorkoutSheetData);
      }
    });
    _applyFiltersAndGroupWorkouts();
  }

  Future<void> _saveWorkoutSheetToFirebase(WorkoutSheet sheet) async {
    if (_userWorkoutSheetsRef == null) {
      // ignore: avoid_print
      print('Não é possível salvar ficha: usuário não autenticado.');
      return;
    }
    try {
      await _userWorkoutSheetsRef!.child(sheet.id).set(sheet.toJson());
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao salvar ficha no Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ficha de treino no Firebase.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteWorkoutSheetFromFirebase(String sheetId) async {
    if (_userWorkoutSheetsRef == null) {
      // ignore: avoid_print
      print('Não é possível deletar ficha: usuário não autenticado.');
      return;
    }
    try {
      await _userWorkoutSheetsRef!.child(sheetId).remove();
      // Se a ficha deletada era a ativa, desativar
      if (_activeWorkoutSheetId == sheetId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(SharedPreferencesKeys.activeWorkoutSheetId);
        await prefs.remove(SharedPreferencesKeys.activeWorkoutSheetData);
        setState(() {
          _activeWorkoutSheetId = null;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ficha excluída com sucesso!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
          ),
        );
      }
      _loadAllWorkoutSheets(); // Recarrega para atualizar a UI
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao deletar ficha do Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar ficha de treino do Firebase.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToWorkoutSheetForm({WorkoutSheet? workoutSheet}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Faça login para criar ou editar fichas de treino.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push<WorkoutSheet>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSheetFormScreen(workoutSheet: workoutSheet),
      ),
    );

    if (result != null) {
      await _saveWorkoutSheetToFirebase(result);
      _loadAllWorkoutSheets(); // Recarrega as fichas após salvar no Firebase
      _applyFiltersAndGroupWorkouts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(workoutSheet == null ? 'Ficha "${result.name}" criada com sucesso!' : 'Ficha "${result.name}" editada com sucesso!', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.successColor.withAlpha((255 * 0.7).round()),
          ),
        );
      }
    }
  }

  bool _isUserCreatedWorkoutSheet(String id) {
    // Uma ficha é considerada criada pelo usuário se tiver um userId e não for uma das fichas padrão.
    // Para simplificar, verificamos se ela possui um userId diferente de nulo.
    // Em um cenário real, você poderia ter uma lista de IDs de fichas padrão para uma verificação mais rigorosa.
    return _allWorkoutSheets.any((sheet) => sheet.id == id && sheet.userId != null);
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
                  // NOVO: Botão de edição para fichas criadas pelo usuário
                  if (_isUserCreatedWorkoutSheet(sheet.id)) // Apenas fichas criadas pelo usuário
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.textSecondaryColor),
                      onPressed: () => _navigateToWorkoutSheetForm(workoutSheet: sheet),
                      tooltip: 'Editar ficha',
                    ),
                  // NOVO: Botão de exclusão para fichas criadas pelo usuário
                  if (_isUserCreatedWorkoutSheet(sheet.id))
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.errorColor),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text('Confirmar Exclusão', style: AppStyles.headingStyle),
                              content: Text('Tem certeza que deseja excluir a ficha "${sheet.name}"?', style: AppStyles.bodyStyle),
                              backgroundColor: AppColors.cardColor,
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: Text('Cancelar', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _deleteWorkoutSheetFromFirebase(sheet.id);
                                  },
                                  child: Text('Excluir', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.errorColor)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      tooltip: 'Excluir ficha',
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

  void _showWorkoutSheetDetailsModal(BuildContext context, WorkoutSheet sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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