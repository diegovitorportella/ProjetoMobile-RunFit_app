// lib/screens/activity_history_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:runfit_app/data/models/activity_history_entry.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:runfit_app/screens/activity_details_screen.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runfit_app/screens/login_screen.dart';


class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<ActivityHistoryEntry> _activityHistory = [];
  List<ActivityHistoryEntry> _filteredActivityHistory = [];
  bool _isLoading = true;

  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String? _selectedModalityFilter;
  String? _selectedActivityTypeFilter;
  double? _minDurationFilter;
  double? _maxDurationFilter;
  double? _minDistanceFilter;
  double? _maxDistanceFilter;
  String? _workoutSheetNameFilter;

  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  final TextEditingController _minDistanceController = TextEditingController();
  final TextEditingController _maxDistanceController = TextEditingController();
  final TextEditingController _workoutSheetNameController = TextEditingController();

  DatabaseReference? _userActivitiesRef;
  StreamSubscription<DatabaseEvent>? _activitiesSubscription;


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userActivitiesRef = FirebaseDatabase.instance.ref('users/${user.uid}/activities');
      _loadActivitiesFromFirebase();
    } else {
      // ignore: avoid_print
      print('ActivityHistoryScreen: Usuário não logado. Histórico de atividades não será carregado.');
      setState(() {
        _isLoading = false;
        _activityHistory = [];
        _filteredActivityHistory = [];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor, faça login para ver seu histórico.', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      });
    }
    _minDurationController.addListener(_applyFilters);
    _maxDurationController.addListener(_applyFilters);
    _minDistanceController.addListener(_applyFilters);
    _maxDistanceController.addListener(_applyFilters);
    _workoutSheetNameController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _minDurationController.dispose();
    _maxDurationController.dispose();
    _minDistanceController.dispose();
    _maxDistanceController.dispose();
    _workoutSheetNameController.dispose();
    _activitiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadActivitiesFromFirebase() async {
    if (_userActivitiesRef == null) {
      // ignore: avoid_print
      print('ActivityHistoryScreen: _userActivitiesRef é null, não carregando atividades do Firebase.');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activityHistory = [];
          _filteredActivityHistory = [];
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      _activitiesSubscription = _userActivitiesRef!.onValue.listen((event) {
        if (!mounted) {
          _activitiesSubscription?.cancel();
          return;
        }

        final data = event.snapshot.value;
        if (data != null) {
          final Map<String, dynamic> activitiesMap = Map<String, dynamic>.from(data as Map);

          List<ActivityHistoryEntry> fetchedActivities = [];
          activitiesMap.forEach((key, value) {
            fetchedActivities.add(ActivityHistoryEntry.fromJson(Map<String, dynamic>.from(value)));
          });
          setState(() {
            _activityHistory = fetchedActivities;
            _activityHistory.sort((a, b) => b.date.compareTo(a.date));
            _applyFilters();
            _isLoading = false;
          });
        } else {
          setState(() {
            _activityHistory = [];
            _filteredActivityHistory = [];
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar atividades do Firebase: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _applyFilters() {
    setState(() {
      _filteredActivityHistory = _activityHistory.where((entry) {
        bool matches = true;

        if (_startDateFilter != null) {
          if (entry.date.isBefore(DateTime(_startDateFilter!.year, _startDateFilter!.month, _startDateFilter!.day))) {
            matches = false;
          }
        }
        if (matches && _endDateFilter != null) {
          if (entry.date.isAfter(DateTime(_endDateFilter!.year, _endDateFilter!.month, _endDateFilter!.day, 23, 59, 59))) {
            matches = false;
          }
        }

        if (matches && _selectedModalityFilter != null && _selectedModalityFilter != 'Todos') {
          matches = entry.modality == _selectedModalityFilter;
        }

        if (matches && _selectedActivityTypeFilter != null && _selectedActivityTypeFilter != 'Todos') {
          matches = entry.activityType == _selectedActivityTypeFilter;
        }

        _minDurationFilter = double.tryParse(_minDurationController.text);
        _maxDurationFilter = double.tryParse(_maxDurationController.text);
        if (matches && _minDurationFilter != null) {
          if (entry.durationMinutes == null || entry.durationMinutes! < _minDurationFilter!) {
            matches = false;
          }
        }
        if (matches && _maxDurationFilter != null) {
          if (entry.durationMinutes == null || entry.durationMinutes! > _maxDurationFilter!) {
            matches = false;
          }
        }

        _minDistanceFilter = double.tryParse(_minDistanceController.text);
        _maxDistanceFilter = double.tryParse(_maxDistanceController.text);
        if (matches && _minDistanceFilter != null) {
          if (entry.distanceKm == null || entry.distanceKm! < _minDistanceFilter!) {
            matches = false;
          }
        }
        if (matches && _maxDistanceFilter != null) {
          if (entry.distanceKm == null || entry.distanceKm! > _maxDistanceFilter!) {
            matches = false;
          }
        }

        _workoutSheetNameFilter = _workoutSheetNameController.text.trim().toLowerCase();
        if (matches && _workoutSheetNameFilter != null && _workoutSheetNameFilter!.isNotEmpty) {
          if (entry.activityType != 'Ficha de Treino' || entry.workoutSheetName == null || !entry.workoutSheetName!.toLowerCase().contains(_workoutSheetNameFilter!)) {
            matches = false;
          }
        }

        return matches;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _startDateFilter = null;
      _endDateFilter = null;
      _selectedModalityFilter = null;
      _selectedActivityTypeFilter = null;
      _minDurationController.clear();
      _maxDurationController.clear();
      _minDistanceController.clear();
      _maxDistanceController.clear();
      _workoutSheetNameController.clear();
      _applyFilters();
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Filtrar Histórico', style: AppStyles.headingStyle),
                              const SizedBox(height: 24),

                              // Filtro de Data
                              Text('Período:', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: _startDateFilter ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
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
                                            _startDateFilter = picked;
                                          });
                                          _applyFilters();
                                        }
                                      },
                                      style: AppStyles.buttonStyle.copyWith(
                                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                                        backgroundColor: MaterialStateProperty.all(AppColors.cardColor),
                                        side: MaterialStateProperty.all(BorderSide(color: AppColors.borderColor)),
                                      ),
                                      child: Text(
                                        _startDateFilter == null
                                            ? 'Data Início'
                                            : DateFormat('dd/MM/yyyy').format(_startDateFilter!),
                                        style: AppStyles.bodyStyle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: _endDateFilter ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
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
                                            _endDateFilter = picked;
                                          });
                                          _applyFilters();
                                        }
                                      },
                                      style: AppStyles.buttonStyle.copyWith(
                                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                                        backgroundColor: MaterialStateProperty.all(AppColors.cardColor),
                                        side: MaterialStateProperty.all(BorderSide(color: AppColors.borderColor)),
                                      ),
                                      child: Text(
                                        _endDateFilter == null
                                            ? 'Data Fim'
                                            : DateFormat('dd/MM/yyyy').format(_endDateFilter!),
                                        style: AppStyles.bodyStyle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Filtro por Modalidade
                              Text('Modalidade:', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedModalityFilter,
                                decoration: AppStyles.inputDecoration,
                                style: AppStyles.bodyStyle,
                                dropdownColor: AppColors.cardColor,
                                items: [
                                  const DropdownMenuItem<String>(value: 'Todos', child: Text('Todas as Modalidades', style: AppStyles.bodyStyle)),
                                  ...WorkoutModality.values.map((modality) => DropdownMenuItem(
                                    value: modality.name,
                                    child: Text(modality.name.toCapitalized(), style: AppStyles.bodyStyle),
                                  )).toList(),
                                ],
                                onChanged: (value) {
                                  modalSetState(() {
                                    _selectedModalityFilter = value;
                                  });
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(height: 24),

                              // Filtro por Tipo de Atividade
                              Text('Tipo de Atividade:', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedActivityTypeFilter,
                                decoration: AppStyles.inputDecoration,
                                style: AppStyles.bodyStyle,
                                dropdownColor: AppColors.cardColor,
                                items: const [
                                  DropdownMenuItem<String>(value: 'Todos', child: Text('Todos os Tipos', style: AppStyles.bodyStyle)),
                                  DropdownMenuItem<String>(value: 'Avulsa', child: Text('Avulsa', style: AppStyles.bodyStyle)),
                                  DropdownMenuItem<String>(value: 'Ficha de Treino', child: Text('Ficha de Treino', style: AppStyles.bodyStyle)),
                                ],
                                onChanged: (value) {
                                  modalSetState(() {
                                    _selectedActivityTypeFilter = value;
                                  });
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(height: 24),

                              // Filtro de Duração
                              Text('Duração (minutos):', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _minDurationController,
                                      keyboardType: TextInputType.number,
                                      style: AppStyles.bodyStyle,
                                      decoration: AppStyles.inputDecoration.copyWith(labelText: 'Mínima'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _maxDurationController,
                                      keyboardType: TextInputType.number,
                                      style: AppStyles.bodyStyle,
                                      decoration: AppStyles.inputDecoration.copyWith(labelText: 'Máxima'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Filtro de Distância (apenas para Corrida ou geral)
                              Text('Distância (km):', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _minDistanceController,
                                      keyboardType: TextInputType.number,
                                      style: AppStyles.bodyStyle,
                                      decoration: AppStyles.inputDecoration.copyWith(labelText: 'Mínima'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _maxDistanceController,
                                      keyboardType: TextInputType.number,
                                      style: AppStyles.bodyStyle,
                                      decoration: AppStyles.inputDecoration.copyWith(labelText: 'Máxima'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Filtro por Nome da Planilha de Treino
                              Text('Nome da Ficha de Treino:', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _workoutSheetNameController,
                                style: AppStyles.bodyStyle,
                                decoration: AppStyles.inputDecoration.copyWith(hintText: 'Buscar por nome da ficha'),
                              ),
                              const SizedBox(height: 32),

                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _resetFilters();
                                    Navigator.of(context).pop();
                                  },
                                  style: AppStyles.buttonStyle.copyWith(
                                    backgroundColor: MaterialStateProperty.all(AppColors.warningColor),
                                  ),
                                  child: Text('Limpar Filtros', style: AppStyles.buttonTextStyle),
                                ),
                              ),
                              const SizedBox(height: 16),
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
      },
    );
  }


  // --- Métodos de Pie Chart (adicionados novamente) ---
  List<PieChartSectionData> _getPieChartSections(BuildContext context) {
    if (_filteredActivityHistory.isEmpty) {
      return [];
    }
    final Map<String, int> modalityCounts = {};
    for (var entry in _filteredActivityHistory) {
      modalityCounts[entry.modality] = (modalityCounts[entry.modality] ?? 0) + 1;
    }
    final List<Color> pieColors = [
      AppColors.accentColor,
      AppColors.successColor,
      AppColors.warningColor,
      AppColors.primaryColor,
      AppColors.textSecondaryColor.withOpacity(0.5),
      Colors.redAccent, Colors.blueAccent, Colors.yellowAccent, Colors.cyan, Colors.purpleAccent,
    ];
    int colorIndex = 0;
    return modalityCounts.entries.map((entry) {
      final String modality = entry.key;
      final int count = entry.value;
      final double percentage = (count / _filteredActivityHistory.length) * 100;
      // Garanta que `modality` não é nulo antes de chamar métodos nele
      String formattedModality = modality.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').toTitleCase();
      final color = pieColors[colorIndex % pieColors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: AppStyles.smallTextStyle.copyWith(
          color: AppColors.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)],
        ),
        badgeWidget: _Badge(formattedModality, size: 60, borderColor: color),
        badgePositionPercentageOffset: 1.5,
      );
    }).toList();
  }

  List<PieChartSectionData> _getDurationPieChartSections(BuildContext context) {
    if (_filteredActivityHistory.isEmpty) {
      return [];
    }
    final Map<String, double> modalityDurations = {};
    for (var entry in _filteredActivityHistory) {
      if (entry.durationMinutes != null) {
        modalityDurations[entry.modality] = (modalityDurations[entry.modality] ?? 0) + entry.durationMinutes!;
      }
    }
    if (modalityDurations.isEmpty) return [];
    final double totalDuration = modalityDurations.values.fold(0.0, (sum, item) => sum + item);
    final List<Color> pieColors = [
      AppColors.accentColor,
      AppColors.successColor,
      AppColors.warningColor,
      AppColors.primaryColor,
      AppColors.textSecondaryColor.withOpacity(0.5),
      Colors.redAccent, Colors.blueAccent, Colors.yellowAccent, Colors.cyan, Colors.purpleAccent,
    ];
    int colorIndex = 0;
    return modalityDurations.entries.map((entry) {
      final String modality = entry.key;
      final double duration = entry.value;
      final double percentage = (duration / totalDuration) * 100;
      // Garanta que `modality` não é nulo antes de chamar métodos nele
      String formattedModality = modality.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').toTitleCase();
      final color = pieColors[colorIndex % pieColors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: duration,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: AppStyles.smallTextStyle.copyWith(
          color: AppColors.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)],
        ),
        badgeWidget: _Badge(formattedModality, size: 60, borderColor: color),
        badgePositionPercentageOffset: 1.5,
      );
    }).toList();
  }


  String _formatDuration(double? durationMinutes) {
    if (durationMinutes == null) return 'N/A';

    final totalSeconds = (durationMinutes * 60).round();
    final duration = Duration(seconds: totalSeconds);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$hours:$minutes:$seconds';
  }


  @override
  Widget build(BuildContext context) {
    final pieChartSections = _getPieChartSections(context);
    final durationPieChartSections = _getDurationPieChartSections(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Atividades', style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
            tooltip: 'Filtrar Histórico',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredActivityHistory.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _activityHistory.isEmpty
                    ? 'Nenhuma atividade registrada ainda. Que tal começar a treinar?'
                    : 'Nenhum resultado encontrado para os filtros aplicados.',
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              if (_activityHistory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: _resetFilters,
                    style: AppStyles.buttonStyle,
                    child: Text('Limpar Filtros', style: AppStyles.buttonTextStyle),
                  ),
                ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GRÁFICO 1: Distribuição de Atividades por Modalidade (usa _filteredActivityHistory)
            if (pieChartSections.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atividades por Modalidade',
                    style: AppStyles.headingStyle.copyWith(fontSize: 20, color: AppColors.accentColor),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: AppColors.borderColor, width: 1.0),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // GRÁFICO 2: Duração Total de Atividades por Modalidade (usa _filteredActivityHistory)
            if (durationPieChartSections.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duração Total por Modalidade (min)',
                    style: AppStyles.headingStyle.copyWith(fontSize: 20, color: AppColors.accentColor),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: AppColors.borderColor, width: 1.0),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: PieChart(
                        PieChartData(
                          sections: durationPieChartSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            Text(
              'Detalhes do Histórico',
              style: AppStyles.headingStyle.copyWith(fontSize: 20, color: AppColors.accentColor),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredActivityHistory.length,
              itemBuilder: (context, index) {
                final entry = _filteredActivityHistory[index];
                final bool showMap = entry.modality == WorkoutModality.corrida.name &&
                    entry.pathCoordinates != null &&
                    entry.pathCoordinates!.isNotEmpty;

                List<LatLng> pathPoints = [];
                LatLng? mapCenter;
                List<Marker> mapMarkers = [];

                if (showMap) {
                  pathPoints = entry.pathCoordinates!
                      .map((coords) => LatLng(coords['latitude']!, coords['longitude']!))
                      .toList();

                  if (pathPoints.isNotEmpty) {
                    mapCenter = pathPoints.first;

                    mapMarkers.add(
                      Marker(
                        point: pathPoints.first,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                      ),
                    );
                    if (pathPoints.length > 1) {
                      mapMarkers.add(
                        Marker(
                          point: pathPoints.last,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.flag, color: Colors.red, size: 30),
                        ),
                      );
                    }
                  }
                }

                return Card(
                  color: AppColors.cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: AppColors.borderColor, width: 1.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityDetailsScreen(
                            activity: entry,
                            modality: entry.modality,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.activityType,
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy - HH:mm').format(entry.date),
                            style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modalidade: ${entry.modality.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').toTitleCase()}',
                            style: AppStyles.bodyStyle,
                          ),
                          if (entry.workoutSheetName != null)
                            Text(
                              'Ficha: ${entry.workoutSheetName}',
                              style: AppStyles.bodyStyle,
                            ),
                          if (entry.durationMinutes != null)
                            Text(
                              'Duração: ${_formatDuration(entry.durationMinutes)}',
                              style: AppStyles.bodyStyle,
                            ),
                          if (entry.distanceKm != null)
                            Text(
                              'Distância: ${entry.distanceKm?.toStringAsFixed(2)} km',
                              style: AppStyles.bodyStyle,
                            ),
                          if (entry.averagePace != null)
                            Text('Pace Médio: ${entry.averagePace}', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                          if (entry.notes != null && entry.notes!.isNotEmpty)
                            Text(
                              'Notas: ${entry.notes}',
                              style: AppStyles.bodyStyle.copyWith(fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          if (entry.modality == WorkoutModality.musculacao.name && entry.loggedExercises != null && entry.loggedExercises!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Exercícios:',
                              style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entry.loggedExercises!.length,
                              itemBuilder: (context, exerciseIndex) {
                                final exercise = entry.loggedExercises![exerciseIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                  child: Text(
                                    '• ${exercise.name}: ${exercise.sets}x${exercise.reps} ${exercise.load != null && exercise.load!.isNotEmpty ? '(${exercise.load})' : ''}',
                                    style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
                                  ),
                                );
                              },
                            ),
                          ],

                          if (showMap && mapCenter != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Percurso:',
                              style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: FlutterMap(
                                  options: MapOptions(
                                    center: mapCenter!,
                                    zoom: 14,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.runfit_app',
                                      tileProvider: CancellableNetworkTileProvider(),
                                    ),
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: pathPoints,
                                          color: AppColors.accentColor,
                                          strokeWidth: 4.0,
                                        ),
                                      ],
                                    ),
                                    MarkerLayer(
                                      markers: mapMarkers,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      this.text, {
        required this.size,
        required this.borderColor,
      });
  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size * 1.5,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: size * 0.1, vertical: size * 0.05),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: AppStyles.smallTextStyle.copyWith(
              color: AppColors.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}