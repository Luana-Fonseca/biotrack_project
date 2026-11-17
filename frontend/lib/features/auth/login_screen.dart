import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import '../../shell/app_shell.dart';
import '../legal/privacy_terms_screen.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    final ok = await auth.login(email: _emailController.text.trim(), password: _passwordController.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } else if (auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: BioIcon('chev-l', size: 20, color: p.gray),
              ),
              const SizedBox(height: 24),
              Text('Entrar', style: AppText.inter(size: 28, weight: FontWeight.w700, color: AppColors.azul)),
              const SizedBox(height: 6),
              Text('Acesse sua conta BioTrack', style: AppText.inter(size: 14, color: p.gray)),
              const SizedBox(height: 28),
              _field(p, 'E-mail', _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _field(p, 'Senha', _passwordController, obscure: _obscure, onToggleObscure: () => setState(() => _obscure = !_obscure)),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Entrar', loading: auth.isBusy, onPressed: () => _submit(auth)),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('Não tem conta? Criar agora', style: AppText.inter(size: 13, weight: FontWeight.w600, color: AppColors.azul)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyTermsScreen())),
                  child: Text('Termos de Uso e Privacidade', style: AppText.inter(size: 12, weight: FontWeight.w600, color: p.gray)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(AppPalette p, String label, TextEditingController controller,
      {TextInputType? keyboardType, bool obscure = false, VoidCallback? onToggleObscure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: AppText.inter(size: 14, color: p.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: p.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: BioIcon(obscure ? 'eye' : 'eye-off', size: 18, color: p.gray),
                    onPressed: onToggleObscure,
                  ),
          ),
        ),
      ],
    );
  }
}
