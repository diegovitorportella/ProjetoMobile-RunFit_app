// lib/screens/activity_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/screens/activity_log_screen.dart'; // Tela de log manual (adaptada)
import 'package:runfit_app/screens/run_tracking_screen.dart';   // Tela de rastreamento de corrida
import 'package:runfit_app/utils/app_colors.dart';             // CORES DO PROJETO
import 'package:runfit_app/utils/app_styles.dart';             // ESTILOS DO PROJETO
import 'package:runfit_app/utils/app_constants.dart';          // CONSTANTES DO PROJETO (para WorkoutModality)

class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({super.key});

  @override
  State<ActivitySelectionScreen> createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  // Usar o enum WorkoutModality do app_constants.dart
  // Valor padrão pode ser musculacao ou corrida.
  String _selectedModality = WorkoutModality.musculacao.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nova Atividade Avulsa', // Título ajustado
          style: AppStyles.titleTextStyle.copyWith(fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qual modalidade você praticou?', // Texto ajustado
              style: AppStyles.headingStyle,
            ),
            const SizedBox(height: 24),
            Text('Modalidade', style: AppStyles.bodyStyle),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedModality,
              decoration: AppStyles.inputDecoration, // Usar InputDecoration do AppStyles global
              style: AppStyles.bodyStyle,
              dropdownColor: AppColors.cardColor, // Cor do dropdown
              items: [ // Oferecer apenas Musculação e Corrida para atividades avulsas
                WorkoutModality.musculacao,
                WorkoutModality.corrida,
              ].map((modality) {
                // Usar a extensão toCapitalized de app_constants.dart se ainda for necessária,
                // ou formatar diretamente aqui.
                String formattedName = modality.name.toCapitalized();
                return DropdownMenuItem<String>(
                  value: modality.name,
                  child: Text(formattedName, style: AppStyles.bodyStyle),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedModality = value;
                  });
                }
              },
              validator: (value) { // Adicionado validator para consistência
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione uma modalidade.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedModality == WorkoutModality.corrida.name) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RunTrackingScreen(),
                      ),
                    );
                  } else if (_selectedModality == WorkoutModality.musculacao.name) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ActivityLogScreen( // Navega para a ActivityLogScreen adaptada
                          selectedModality: _selectedModality,
                        ),
                      ),
                    );
                  }
                  // Adicionar um else para outros casos se o dropdown permitir mais opções no futuro
                },
                style: AppStyles.buttonStyle,
                child: Text('Continuar', style: AppStyles.buttonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}