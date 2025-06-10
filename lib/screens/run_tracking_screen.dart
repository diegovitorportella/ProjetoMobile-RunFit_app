// lib/screens/run_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart';
import 'package:runfit_app/data/models/activity_history_entry.dart';
import 'package:runfit_app/services/achievement_service.dart';
import 'package:runfit_app/data/models/achievement.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:runfit_app/services/goal_service.dart'; // NOVO: Importar GoalService
import 'package:runfit_app/data/models/goal.dart'; // NOVO: Importar modelo Goal


class RunTrackingScreen extends StatefulWidget {
  const RunTrackingScreen({super.key});

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  bool _isTracking = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  double _currentSpeedMps = 0.0;
  Timer? _timer;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Position> _pathPositions = [];

  final MapController _mapController = MapController();

  final Uuid _uuid = const Uuid();
  final AchievementService _achievementService = AchievementService();
  final GoalService _goalService = GoalService(); // NOVO: Instanciar GoalService

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _notesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serviço de localização desativado. Por favor, ative-o.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permissão de localização negada.', style: AppStyles.smallTextStyle),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissão de localização negada permanentemente. Habilite nas configurações do app.', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _startTracking() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    if (!mounted) return;

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _pathPositions = [];
      _notesController.clear();
      _currentSpeedMps = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!_isPaused && _isTracking) {
        if (!mounted) {
          _positionStreamSubscription?.cancel();
          return;
        }
        setState(() {
          if (_pathPositions.isNotEmpty) {
            _distanceKm += Geolocator.distanceBetween(
              _pathPositions.last.latitude,
              _pathPositions.last.longitude,
              position.latitude,
              position.longitude,
            ) / 1000;
          }
          _pathPositions.add(position);
          _currentSpeedMps = position.speed;

          _mapController.move(LatLng(position.latitude, position.longitude), _mapController.zoom);
        });
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rastreamento Iniciado!', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)), backgroundColor: AppColors.primaryColor),
      );
    }
  }

  void _pauseOrResumeTracking() {
    if (!_isTracking) return;

    if (!mounted) return;

    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _positionStreamSubscription?.pause();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rastreamento Pausado.', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
    } else {
      _positionStreamSubscription?.resume();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rastreamento Retomado.', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    }
  }

  void _stopAndSaveTracking() async {
    if (!_isTracking && _elapsedSeconds == 0) return;

    _timer?.cancel();
    _positionStreamSubscription?.cancel();

    if (!mounted) return;

    setState(() {
      _isTracking = false;
      _isPaused = false;
      _currentSpeedMps = 0.0;
    });


    if (_elapsedSeconds > 0 || _distanceKm > 0) {
      String averagePace = _calculateAveragePace(_elapsedSeconds, _distanceKm);

      final bool? shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.cardColor,
            title: Text('Finalizar Corrida?', style: AppStyles.headingStyle),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tempo: ${Duration(seconds: _elapsedSeconds).toString().split('.').first.padLeft(8, "0")}', style: AppStyles.bodyStyle),
                    Text('Distância: ${_distanceKm.toStringAsFixed(2)} km', style: AppStyles.bodyStyle),
                    Text('Pace Médio: $averagePace', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: AppStyles.bodyStyle,
                      decoration: AppStyles.inputDecoration.copyWith(
                        labelText: 'Notas (opcional)',
                        hintText: 'Como foi sua corrida?',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Descartar', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.textSecondaryColor, fontSize: 14)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
              ),
              ElevatedButton(
                style: AppStyles.buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(AppColors.successColor)
                ),
                child: Text(
                    'Salvar Corrida',
                    style: AppStyles.buttonTextStyle.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryColor
                    )
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (mounted && shouldSave == true) {
        final prefs = await SharedPreferences.getInstance();
        List<String> historyJsonList = prefs.getStringList(SharedPreferencesKeys.activityHistory) ?? [];

        List<Map<String, double>> pathCoordsForStorage = _pathPositions.map((p) => {
          'latitude': p.latitude,
          'longitude': p.longitude,
        }).toList();

        final newEntry = ActivityHistoryEntry(
          id: _uuid.v4(),
          date: DateTime.now(),
          modality: WorkoutModality.corrida.name,
          activityType: 'Avulsa',
          durationMinutes: _elapsedSeconds / 60.0,
          distanceKm: _distanceKm,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          latitude: _pathPositions.isNotEmpty ? _pathPositions.first.latitude : null,
          longitude: _pathPositions.isNotEmpty ? _pathPositions.first.longitude : null,
          pathCoordinates: pathCoordsForStorage,
          averagePace: averagePace,
        );

        historyJsonList.add(json.encode(newEntry.toJson()));
        await prefs.setStringList(SharedPreferencesKeys.activityHistory, historyJsonList);

        final currentCompleted = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;
        await prefs.setInt(SharedPreferencesKeys.completedWorkoutsThisWeek, currentCompleted + 1);

        final unlockedAch = await _achievementService.notifyWorkoutCompleted(WorkoutModality.corrida.name);
        if (unlockedAch != null && mounted) {
          _showAchievementUnlockedDialog(unlockedAch);
        }

        // NOVO: Atualizar metas ao finalizar uma corrida
        final newlyCompletedGoals = await _goalService.updateGoalsProgress(
          modality: WorkoutModality.corrida.name,
          durationMinutes: _elapsedSeconds / 60.0,
          distanceKm: _distanceKm,
        );
        if (mounted) {
          for (var goal in newlyCompletedGoals) {
            _showGoalCompletedDialog(goal);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida registrada com sucesso!', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);

      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida descartada.', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)),
            backgroundColor: AppColors.warningColor,
          ),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    } else if (mounted) {
      int count = 0;
      Navigator.of(context).popUntil((_) => count++ >= 2);
    }
  }

  void _showAchievementUnlockedDialog(Achievement achievement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              Icon(achievement.icon, color: AppColors.successColor, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Conquista Desbloqueada!', style: AppStyles.headingStyle.copyWith(color: AppColors.successColor)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(achievement.title, style: AppStyles.titleTextStyle.copyWith(fontSize: 22, color: AppColors.textPrimaryColor)),
              const SizedBox(height: 8),
              Text(achievement.description, style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Entendi', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.accentColor)),
            ),
          ],
        );
      },
    );
  }

  // NOVO MÉTODO: Exibe um diálogo de meta concluída
  void _showGoalCompletedDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.successColor, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Meta Concluída!', style: AppStyles.headingStyle.copyWith(color: AppColors.successColor)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: AppStyles.titleTextStyle.copyWith(fontSize: 22, color: AppColors.textPrimaryColor)),
              const SizedBox(height: 8),
              Text('Parabéns! Você alcançou sua meta de ${goal.targetValue.toStringAsFixed(goal.type == GoalType.distance || goal.type == GoalType.weight ? 1 : 0)} ${goal.unit.name.toLowerCase()}.', style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Uhuul!', style: AppStyles.buttonTextStyle.copyWith(color: AppColors.accentColor)),
            ),
          ],
        );
      },
    );
  }


  // Método para formatar o pace (min/km)
  String _formatPace(double speedMps) {
    if (speedMps <= 0) return '0:00 min/km';

    double secondsPerKm = 1000 / speedMps;

    int minutes = (secondsPerKm / 60).floor();
    int seconds = (secondsPerKm % 60).round();

    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')} min/km';
  }

  // Método para calcular e formatar o Pace Médio
  String _calculateAveragePace(int elapsedSeconds, double distanceKm) {
    const double minDistanceForPace = 0.05;

    if (distanceKm < minDistanceForPace || elapsedSeconds <= 0) {
      return 'N/A';
    }

    double totalSeconds = elapsedSeconds.toDouble();
    double averageSecondsPerKm = totalSeconds / distanceKm;

    if (averageSecondsPerKm > (60 * 30)) {
      return 'N/A';
    }

    int minutes = (averageSecondsPerKm / 60).floor();
    int seconds = (averageSecondsPerKm % 60).round();

    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')} min/km';
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = Duration(seconds: _elapsedSeconds)
        .toString()
        .split('.')
        .first
        .padLeft(8, "0");

    String formattedPace = _formatPace(_currentSpeedMps);

    return Scaffold(
      appBar: AppBar(
        title: Text('Rastrear Corrida', style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
      ),
      body: Column(
        children: [
          // Seção do Mapa
          Expanded(
            flex: 1, // NOVO: Alterado de flex: 2 para flex: 1
            child: Container(
              color: AppColors.cardColor,
              child: _pathPositions.isEmpty && !_isTracking
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 50, color: AppColors.textSecondaryColor),
                    const SizedBox(height: 10),
                    Text(
                      'Inicie uma corrida para ver seu percurso aqui.',
                      style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _pathPositions.isNotEmpty
                      ? LatLng(_pathPositions.last.latitude, _pathPositions.last.longitude)
                      : LatLng(-23.55052, -46.633308),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                        points: _pathPositions.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                        color: AppColors.accentColor,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                  // Marcador de posição atual
                  if (_pathPositions.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_pathPositions.last.latitude, _pathPositions.last.longitude),
                          width: 40,
                          height: 40,
                          child: Icon(Icons.circle, color: AppColors.successColor, size: 20),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Seção de Estatísticas e Botões
          Expanded(
            flex: 1, // NOVO: Alterado de flex: 1 para flex: 1 (já estava 1)
            child: SingleChildScrollView( // NOVO: Envolvendo a Padding com SingleChildScrollView
              padding: const EdgeInsets.all(16.0),
              child: Column( // This is the column that was overflowing
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tempo Decorrido',
                    style: AppStyles.headingStyle.copyWith(fontSize: 22),
                  ),
                  Text(
                    formattedTime,
                    style: AppStyles.titleTextStyle.copyWith(fontSize: 60, color: AppColors.accentColor, fontWeight: FontWeight.w300),
                  ),
                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Distância',
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                          ),
                          Text(
                            '${_distanceKm.toStringAsFixed(2)} km',
                            style: AppStyles.bodyStyle.copyWith(fontSize: 28, color: AppColors.textPrimaryColor),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Pace Atual',
                            style: AppStyles.headingStyle.copyWith(fontSize: 18),
                          ),
                          Text(
                            formattedPace,
                            style: AppStyles.bodyStyle.copyWith(fontSize: 28, color: AppColors.textPrimaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  if (!_isTracking && _elapsedSeconds == 0)
                    ElevatedButton.icon(
                        icon: const Icon(
                            Icons.play_arrow,
                            size: 28,
                            color: AppColors.primaryColor
                        ),
                        label: Text(
                            'Iniciar Corrida',
                            style: AppStyles.buttonTextStyle.copyWith(
                                fontSize: 20,
                                color: AppColors.primaryColor
                            )
                        ),
                        onPressed: _startTracking,
                        style: AppStyles.buttonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(AppColors.successColor),
                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                        )
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 24, color: AppColors.primaryColor),
                          label: Text(
                              _isPaused ? 'Retomar' : 'Pausar',
                              style: AppStyles.buttonTextStyle.copyWith(color: AppColors.primaryColor)
                          ),
                          onPressed: _pauseOrResumeTracking,
                          style: AppStyles.buttonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(AppColors.warningColor),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop, size: 24),
                          label: Text('Finalizar', style: AppStyles.buttonTextStyle),
                          onPressed: _stopAndSaveTracking,
                          style: AppStyles.buttonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(AppColors.errorColor),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}