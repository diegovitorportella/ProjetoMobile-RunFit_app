// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:runfit_app/screens/home_screen.dart'; // Importe a HomeScreen
import 'package:runfit_app/screens/workout_sheets_screen.dart'; // Importe a WorkoutSheetsScreen
import 'package:runfit_app/screens/profile_screen.dart'; // Importe a ProfileScreen
import 'package:runfit_app/utils/app_colors.dart'; // Para cores da barra
import 'package:runfit_app/utils/app_styles.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Índice da aba selecionada (0: Home, 1: Fichas, 2: Perfil)

  // Função para mudar a aba selecionada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Novo método para navegar para a aba de Fichas de Treino
  void _navigateToWorkoutSheetsTab() {
    _onItemTapped(1); // O índice da aba de Fichas é 1
  }

  @override
  Widget build(BuildContext context) {
    // Lista das telas que serão exibidas na BottomNavigationBar
    // Passamos o callback para a HomeScreen
    final List<Widget> _screens = [
      HomeScreen(onNavigateToWorkoutSheets: _navigateToWorkoutSheetsTab), // MODIFICADO AQUI
      const WorkoutSheetsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Fichas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.textPrimaryColor, // Era AppColors.accentColor (vermelho), agora branco
        unselectedItemColor: AppColors.textSecondaryColor,
        backgroundColor: AppColors.cardColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppStyles.smallTextStyle.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppStyles.smallTextStyle,
      ),
    );
  }
}