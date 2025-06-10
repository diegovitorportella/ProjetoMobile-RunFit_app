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
import 'package:runfit_app/screens/activity_details_screen.dart'; // Importe a tela de detalhes da atividade

// NOVO: Importe o flutter_map e latlong2
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart'; // NOVO: Adicione este import


class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<ActivityHistoryEntry> _activityHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityHistory();
  }

  Future<void> _loadActivityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyJsonList = prefs.getStringList(SharedPreferencesKeys.activityHistory) ?? [];
    setState(() {
      _activityHistory = historyJsonList.map((jsonString) => ActivityHistoryEntry.fromJson(json.decode(jsonString))).toList();
      _activityHistory.sort((a, b) => b.date.compareTo(a.date)); // Ordena do mais recente para o mais antigo
      _isLoading = false;
    });
  }

  // --- Métodos de Pie Chart (mantidos iguais) ---
  List<PieChartSectionData> _getPieChartSections(BuildContext context) {
    if (_activityHistory.isEmpty) {
      return [];
    }
    final Map<String, int> modalityCounts = {};
    for (var entry in _activityHistory) {
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
      final double percentage = (count / _activityHistory.length) * 100;
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
    if (_activityHistory.isEmpty) {
      return [];
    }
    final Map<String, double> modalityDurations = {};
    for (var entry in _activityHistory) {
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
  // --- Fim dos Métodos de Pie Chart ---

  // NOVO MÉTODO: Função para formatar a duração em HH:mm:ss
  String _formatDuration(double? durationMinutes) {
    if (durationMinutes == null) return 'N/A';

    final totalSeconds = (durationMinutes * 60).round(); // Converte minutos para segundos
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activityHistory.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Nenhuma atividade registrada ainda. Que tal começar a treinar?',
            style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GRÁFICO 1: Distribuição de Atividades por Modalidade
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

            // GRÁFICO 2: Duração Total de Atividades por Modalidade
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
              itemCount: _activityHistory.length,
              itemBuilder: (context, index) {
                final entry = _activityHistory[index];
                // Condição para exibir o mapa: Modalidade Corrida e ter coordenadas
                final bool showMap = entry.modality == WorkoutModality.corrida.name &&
                    entry.pathCoordinates != null &&
                    entry.pathCoordinates!.isNotEmpty;

                // Dados para o mapa (se houver)
                List<LatLng> pathPoints = [];
                LatLng? mapCenter;
                List<Marker> mapMarkers = []; // Para início e fim

                if (showMap) {
                  pathPoints = entry.pathCoordinates!
                      .map((coords) => LatLng(coords['latitude']!, coords['longitude']!))
                      .toList();

                  if (pathPoints.isNotEmpty) {
                    mapCenter = pathPoints.first; // Centro inicial será o primeiro ponto

                    // Adicionar marcadores para início e fim
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
                      // Ao tocar no card, ainda navegamos para a tela de detalhes completa
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityDetailsScreen(
                            activity: entry,
                            modality: entry.modality, // ADICIONADO: Passando a modalidade
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
                              'Duração: ${_formatDuration(entry.durationMinutes)}', // AQUI ESTÁ A ALTERAÇÃO USANDO O NOVO MÉTODO
                              style: AppStyles.bodyStyle,
                            ),
                          if (entry.distanceKm != null)
                            Text(
                              'Distância: ${entry.distanceKm?.toStringAsFixed(2)} km',
                              style: AppStyles.bodyStyle,
                            ),
                          if (entry.notes != null && entry.notes!.isNotEmpty)
                            Text(
                              'Notas: ${entry.notes}',
                              style: AppStyles.bodyStyle.copyWith(fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          // NOVO: Widget do Mini-Mapa com FlutterMap
                          if (showMap && mapCenter != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Percurso:',
                              style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect( // Borda arredondada para o mapa
                              borderRadius: BorderRadius.circular(8.0),
                              child: SizedBox( // Usar SizedBox em vez de Container para evitar warnings de layout
                                height: 150, // Altura fixa para o mini-mapa
                                width: double.infinity, // Largura total
                                child: FlutterMap(
                                  options: MapOptions(
                                    center: mapCenter!,
                                    zoom: 14, // Zoom inicial para o mini-mapa
                                    // Desabilita interação para o mini-mapa
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none, // Desabilita todos os gestos
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.runfit_app', // Substitua pelo seu ID de pacote
                                      tileProvider: CancellableNetworkTileProvider(), // ADICIONADO: Provedor de tiles otimizado
                                    ),
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: pathPoints,
                                          color: AppColors.accentColor, // Sua cor de destaque
                                          strokeWidth: 4.0, // Largura menor para o mini-mapa
                                        ),
                                      ],
                                    ),
                                    // Adicionar marcadores de início e fim
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

// Widget auxiliar para os badges do Pie Chart (mantido igual)
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