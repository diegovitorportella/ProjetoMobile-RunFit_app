// lib/screens/about_app_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Para obter a versão do app
import 'package:url_launcher/url_launcher.dart'; // Para abrir links externos
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _appVersion = '1.0.0'; // Valor padrão
  String _appName = 'RunFit App'; // Valor padrão

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _appName = packageInfo.appName;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o link: $url', style: AppStyles.smallTextStyle),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sobre o $_appName', style: AppStyles.titleTextStyle.copyWith(fontSize: 22)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo_hibridus.png', // Seu logo
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            Text(
              _appName,
              style: AppStyles.titleTextStyle.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão $_appVersion',
              style: AppStyles.smallTextStyle.copyWith(color: AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 30),
            Text(
              'RunFit é o seu parceiro completo para uma vida ativa e saudável! '
                  'Com ele, você pode registrar seus treinos de corrida e musculação, '
                  'acompanhar seu progresso com estatísticas detalhadas e mapas interativos, '
                  'e ser motivado por um sistema de conquistas personalizado. '
                  'Alcance seus objetivos de forma inteligente e divertida!',
              style: AppStyles.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Text(
              'Desenvolvido por: Diego Portella',
              style: AppStyles.smallTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '© ${DateTime.now().year} RunFit. Todos os direitos reservados.',
              style: AppStyles.smallTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Links opcionais
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: AppColors.accentColor),
              title: Text('Política de Privacidade', style: AppStyles.bodyStyle.copyWith(color: AppColors.accentColor)),
              onTap: () => _launchURL('https://pp.imobilead.me/politica?nome=RunFit'), // Substitua pelo seu link
            ),
            ListTile(
              leading: Icon(Icons.description_outlined, color: AppColors.accentColor),
              title: Text('Termos de Uso', style: AppStyles.bodyStyle.copyWith(color: AppColors.accentColor)),
              onTap: () => _launchURL('https://pp.imobilead.me/politica?nome=RunFit'), // Substitua pelo seu link
            ),
            ListTile(
              leading: Icon(Icons.code, color: AppColors.accentColor),
              title: Text('Licenças Open Source', style: AppStyles.bodyStyle.copyWith(color: AppColors.accentColor)),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: _appName,
                  applicationVersion: _appVersion,
                  applicationIcon: Image.asset('assets/images/logo_hibridus.png', width: 60, height: 60),
                  applicationLegalese: '© ${DateTime.now().year} DiegoPortella/RunFit.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}