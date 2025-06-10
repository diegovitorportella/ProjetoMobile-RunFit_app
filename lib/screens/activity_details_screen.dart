// lib/screens/activity_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Importe LatLng daqui
import 'package:runfit_app/data/models/activity_history_entry.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
import 'package:runfit_app/utils/app_constants.dart'; // Importe para usar WorkoutModality
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final ActivityHistoryEntry activity;
  final String modality; // ADICIONADO: Para receber a modalidade

  const ActivityDetailsScreen({Key? key, required this.activity, required this.modality}) : super(key: key); // MODIFICADO O CONSTRUTOR

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  List<LatLng> _pathPoints = [];
  LatLng? _mapCenter;
  double _zoomLevel = 13.0; // Zoom inicial

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  void _loadMapData() {
    // Carrega os dados do mapa apenas se a modalidade for corrida
    if (widget.modality == WorkoutModality.corrida.name && widget.activity.pathCoordinates != null && widget.activity.pathCoordinates!.isNotEmpty) { // Condição adicionada
      _pathPoints = widget.activity.pathCoordinates!
          .map((coords) => LatLng(coords['latitude']!, coords['longitude']!))
          .toList();

      if (_pathPoints.isNotEmpty) {
        _mapCenter = _pathPoints.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.activityType, style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: widget.modality == WorkoutModality.musculacao.name // NOVA CONDIÇÃO: Se for musculação, exibe mensagem específica
                ? Center(
              child: Text(
                'Esta atividade é de musculação, não há mapa de percurso.', // Mensagem para musculação
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            )
                : _pathPoints.isEmpty || _mapCenter == null // Se não for musculação, verifica se há dados de mapa
                ? Center(
              child: Text(
                'Mapa não disponível para esta atividade ou sem coordenadas.', // Mensagem para corrida sem dados
                style: AppStyles.bodyStyle.copyWith(color: AppColors.textSecondaryColor),
              ),
            )
                : FlutterMap( // Exibe o mapa se for corrida e houver dados
              options: MapOptions(
                center: _mapCenter!,
                zoom: _zoomLevel,
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
                      points: _pathPoints,
                      color: AppColors.accentColor,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (_pathPoints.isNotEmpty)
                      Marker(
                        point: _pathPoints.first,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                      ),
                    if (_pathPoints.length > 1)
                      Marker(
                        point: _pathPoints.last,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.flag, color: Colors.red, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes da Atividade',
                    style: AppStyles.headingStyle,
                  ),
                  const SizedBox(height: 10),
                  Text('Data: ${widget.activity.date.day}/${widget.activity.date.month}/${widget.activity.date.year}', style: AppStyles.bodyStyle),
                  Text('Modalidade: ${widget.activity.modality.toCapitalized()}', style: AppStyles.bodyStyle),
                  if (widget.activity.durationMinutes != null)
                    Text('Duração: ${widget.activity.durationMinutes?.toStringAsFixed(0)} min', style: AppStyles.bodyStyle),
                  if (widget.activity.distanceKm != null)
                    Text('Distância: ${widget.activity.distanceKm?.toStringAsFixed(2)} km', style: AppStyles.bodyStyle),
                  if (widget.activity.averagePace != null) // NOVO: Exibe o pace médio
                    Text('Pace Médio: ${widget.activity.averagePace}', style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                  if (widget.activity.notes != null && widget.activity.notes!.isNotEmpty)
                    Text('Notas: ${widget.activity.notes}', style: AppStyles.bodyStyle),
                  // Adicione outros detalhes relevantes aqui
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}