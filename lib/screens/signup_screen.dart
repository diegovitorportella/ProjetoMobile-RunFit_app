// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runfit_app/utils/app_colors.dart';
import 'package:runfit_app/utils/app_styles.dart';
// import 'package:runfit_app/screens/main_screen.dart'; // Removido, pois não vai mais direto para MainScreen
import 'package:runfit_app/screens/profile_setup_screen.dart'; // <--- ADICIONE ESTA LINHA


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Sucesso no registro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registro bem-sucedido! Agora, configure seu perfil.'),
              backgroundColor: AppColors.successColor,
            ),
          );
          // Redirecionar para ProfileSetupScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()), // <--- MUDANÇA AQUI
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'A senha fornecida é muito fraca.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Já existe uma conta com este e-mail.';
        } else {
          message = 'Erro ao registrar: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar', style: AppStyles.titleTextStyle),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Crie sua conta',
                  style: AppStyles.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppStyles.bodyStyle,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'E-mail',
                    hintText: 'seuemail@exemplo.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite seu e-mail.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'E-mail inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppStyles.bodyStyle,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Senha',
                    hintText: 'Mínimo de 6 caracteres',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite sua senha.';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.accentColor)
                    : ElevatedButton(
                  onPressed: _signUp,
                  style: AppStyles.buttonStyle,
                  child: Text('Registrar', style: AppStyles.buttonTextStyle),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Navegar para a tela de Login
                    Navigator.of(context).pop(); // Ou pushReplacement para tela de login
                  },
                  child: Text(
                    'Já tem uma conta? Faça login!',
                    style: AppStyles.smallTextStyle.copyWith(color: AppColors.accentColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}