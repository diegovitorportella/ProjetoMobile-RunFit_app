// lib/screens/run_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'package:runfit_app/utils/app_colors.dart';           // CORES DO PROJETO
import 'package:runfit_app/utils/app_styles.dart';           // ESTILOS DO PROJETO
import 'package:runfit_app/utils/app_constants.dart';        // CONSTANTES DO PROJETO
import 'package:runfit_app/data/models/activity_history_entry.dart'; // MODELO DO PROJETO
import 'package:runfit_app/services/achievement_service.dart';     // SERVIÇO DE CONQUISTAS


class RunTrackingScreen extends StatefulWidget {
  const RunTrackingScreen({super.key});

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  final _formKey = GlobalKey<FormState>(); // Para o formulário no dialog
  final TextEditingController _notesController = TextEditingController();

  bool _isTracking = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  double _currentSpeedMps = 0.0;
  Timer? _timer;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Position> _pathPositions = [];

  final Uuid _uuid = const Uuid();
  final AchievementService _achievementService = AchievementService();

  @override
  void dispose() {
    _timer?.cancel(); // Cancela o timer quando o widget é descartado
    _positionStreamSubscription?.cancel(); // Cancela a subscription do GPS quando o widget é descartado
    _notesController.dispose();
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

    if (!mounted) return; // Verifica se o widget ainda está montado antes de chamar setState

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _currentSpeedMps = 0.0;
      _pathPositions = [];
      _notesController.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        if (!mounted) { // Verifica se o widget ainda está montado antes de chamar setState
          timer.cancel(); // Cancela o timer se o widget não está mais montado
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
        distanceFilter: 5, // Atualiza a cada 5 metros de mudança
      ),
    ).listen((Position position) {
      if (!_isPaused && _isTracking) {
        if (!mounted) { // Verifica se o widget ainda está montado antes de chamar setState
          _positionStreamSubscription?.cancel(); // Cancela a subscription se o widget não está mais montado
          return;
        }
        setState(() {
          if (_pathPositions.isNotEmpty) {
            _distanceKm += Geolocator.distanceBetween(
              _pathPositions.last.latitude,
              _pathPositions.last.longitude,
              position.latitude,
              position.longitude,
            ) / 1000; // Converte para KM
          }
          _pathPositions.add(position);
          _currentSpeedMps = position.speed; // A propriedade 'speed' já vem em m/s
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

    if (!mounted) return; // Adicione esta verificação

    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _positionStreamSubscription?.pause();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rastreamento Pausado.', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)), backgroundColor: AppColors.warningColor),
        );
      }
    } else {
      _positionStreamSubscription?.resume();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rastreamento Retomado.', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)), backgroundColor: AppColors.primaryColor),
        );
      }
    }
  }

  void _stopAndSaveTracking() async {
    if (!_isTracking && _elapsedSeconds == 0) return;

    _timer?.cancel(); // Cancela o timer
    _positionStreamSubscription?.cancel(); // Cancela a subscription

    if (!mounted) return; // Verifica se o widget ainda está montado antes de chamar setState

    setState(() {
      _isTracking = false;
      _isPaused = false;
      _currentSpeedMps = 0.0;
    });


    if (_elapsedSeconds > 0 || _distanceKm > 0) {
      // NOVO: Calcular Pace Médio antes de exibir o diálogo
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
                    Text('Pace Médio: $averagePace', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)), // NOVO: Exibe o pace médio no diálogo
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

      if (mounted && shouldSave == true) { // Adiciona verificação `mounted` antes de acessar o contexto e chamar Navigator.popUntil
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
          averagePace: averagePace, // NOVO: Salva o pace médio formatado
        );

        historyJsonList.add(json.encode(newEntry.toJson()));
        await prefs.setStringList(SharedPreferencesKeys.activityHistory, historyJsonList);

        final currentCompleted = prefs.getInt(SharedPreferencesKeys.completedWorkoutsThisWeek) ?? 0;
        await prefs.setInt(SharedPreferencesKeys.completedWorkoutsThisWeek, currentCompleted + 1);

        await _achievementService.notifyWorkoutCompleted(WorkoutModality.corrida.name);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida registrada com sucesso!', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);

      } else if (mounted) { // Adiciona verificação `mounted`
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida descartada.', style: AppStyles.smallTextStyle.copyWith(color: AppColors.textPrimaryColor)),
            backgroundColor: AppColors.warningColor,
          ),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    } else if (mounted) { // Adiciona verificação `mounted`
      int count = 0;
      Navigator.of(context).popUntil((_) => count++ >= 2);
    }
  }

  // Método para formatar o pace (min/km) - MANTIDO PARA PACE ATUAL
  String _formatPace(double speedMps) {
    if (speedMps <= 0) return '0:00 min/km';

    double secondsPerKm = 1000 / speedMps;

    int minutes = (secondsPerKm / 60).floor();
    int seconds = (secondsPerKm % 60).round();

    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')} min/km';
  }

  // NOVO MÉTODO: Calcular e formatar o Pace Médio
  String _calculateAveragePace(int elapsedSeconds, double distanceKm) {
    // Se a distância é zero ou muito pequena (ex: menos de 50 metros),
    // e o tempo decorrido não é zero, o pace é indefinido ou irreal.
    // Definimos um limite mínimo de distância para que o cálculo seja válido.
    const double minDistanceForPace = 0.05; // 50 metros

    if (distanceKm < minDistanceForPace || elapsedSeconds <= 0) {
      return 'N/A'; // Ou 'Pace Inválido'
    }

    double totalSeconds = elapsedSeconds.toDouble();
    double averageSecondsPerKm = totalSeconds / distanceKm;

    // Limitar o pace máximo para evitar valores absurdos (ex: se o GPS pulou um pouco)
    if (averageSecondsPerKm > (60 * 30)) { // Se for mais de 30 minutos/km, considere irreal
      return 'N/A'; // Ou 'Pace Inválido'
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
              const SizedBox(height: 30),
              Text(
                'Distância Percorrida',
                style: AppStyles.headingStyle.copyWith(fontSize: 22),
              ),
              Text(
                '${_distanceKm.toStringAsFixed(2)} km',
                style: AppStyles.titleTextStyle.copyWith(fontSize: 60, color: AppColors.accentColor, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 30),
              Text(
                'Pace Atual',
                style: AppStyles.headingStyle.copyWith(fontSize: 22),
              ),
              Text(
                formattedPace,
                style: AppStyles.titleTextStyle.copyWith(fontSize: 48, color: AppColors.textSecondaryColor, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 50),
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
    );
  }
}