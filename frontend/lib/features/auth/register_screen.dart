import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/password_rules.dart';
import '../../core/professions.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/floating_sheet.dart';
import '../../shell/app_shell.dart';
import '../legal/privacy_terms_screen.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  String? _profession;
  DateTime? _birthDate;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openLegal;
    _privacyTap = TapGestureRecognizer()..onTap = _openLegal;
  }

  void _openLegal() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyTermsScreen()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _pickProfession() async {
    final selected = await showFloatingSheet<String>(
      context,
      builder: (context) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shrinkWrap: true,
        children: kProfessions
            .map((p) => ListTile(
                  title: Text(p,
                      style: AppText.inter(
                          size: 14.5, color: context.palette.ink)),
                  onTap: () => Navigator.of(context).pop(p),
                ))
            .toList(),
      ),
    );
    if (selected != null) setState(() => _profession = selected);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!PasswordRules.isStrong(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'A senha precisa ter maiúscula, minúscula, número e caractere especial.')),
      );
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'É preciso concordar com os Termos de Uso e a Política de Privacidade.')),
      );
      return;
    }
    final ok = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      profession: _profession,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } else if (auth.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.lastError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.palette;
    final birthLabel = _birthDate == null
        ? ''
        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';

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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                              color: AppColors.verde,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                              color: p.border,
                              borderRadius: BorderRadius.circular(2)))),
                ],
              ),
              const SizedBox(height: 16),
              Text('PASSO 1 DE 2',
                  style: AppText.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.verde,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Text('Criar sua conta',
                  style: AppText.inter(
                      size: 26,
                      weight: FontWeight.w700,
                      color: AppColors.azul,
                      letterSpacing: -0.4)),
              const SizedBox(height: 6),
              Text('Grátis para uso individual. Sem cartão.',
                  style: AppText.inter(size: 13.5, color: p.gray)),
              const SizedBox(height: 28),
              _field(p, 'Nome completo', _nameController),
              const SizedBox(height: 20),
              _field(p, 'E-mail', _emailController,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _field(p, 'Senha', _passwordController,
                  obscure: _obscurePassword,
                  hint: 'Mínimo 8 caracteres',
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              _passwordChecklist(p, _passwordController.text),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(p, 'Cidade', _cityController)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _underlineField(
                      p,
                      label: 'Nascimento',
                      onTap: _pickBirthDate,
                      display: birthLabel,
                      hint: 'dd/mm/aaaa',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('PROFISSÃO',
                  style: AppText.mono(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: p.gray,
                      letterSpacing: 0.4)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickProfession,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: p.border))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _profession ?? 'Selecione sua profissão',
                        style: _profession == null
                            ? AppText.inter(size: 14, color: p.gray2)
                            : AppText.inter(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppColors.azul),
                      ),
                      BioIcon('chev-d', size: 16, color: p.gray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: _acceptedTerms ? AppColors.verde : p.card,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: _acceptedTerms ? AppColors.verde : p.gray3,
                            width: 1.4),
                      ),
                      child: _acceptedTerms
                          ? const Center(
                              child: BioIcon('check',
                                  size: 12,
                                  color: Colors.white,
                                  strokeWidth: 3))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Deliberately not wrapped in a tap handler of its own: "Termos de Uso" and
                  // "Política de Privacidade" carry their own recognizers below, and any
                  // ancestor GestureDetector/InkWell here would win the gesture arena and
                  // swallow taps meant for them. Only the checkbox square (above) toggles.
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppText.inter(
                            size: 12.5, color: p.gray, height: 1.4),
                        children: [
                          const TextSpan(text: 'Concordo com os '),
                          TextSpan(
                              text: 'Termos de Uso',
                              recognizer: _termsTap,
                              style: AppText.inter(
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.verdeDark)),
                          const TextSpan(text: ' e '),
                          TextSpan(
                              text: 'Política de Privacidade',
                              recognizer: _privacyTap,
                              style: AppText.inter(
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.verdeDark)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Criar conta e continuar',
                icon: 'chev-r',
                iconLeading: true,
                loading: auth.isBusy,
                onPressed: () => _submit(auth),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text('Já tem conta? Entrar',
                      style: AppText.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.azul)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordChecklist(AppPalette p, String password) {
    final rules = [
      ('Mínimo de 8 caracteres', PasswordRules.hasMinLength(password)),
      ('Letra maiúscula', PasswordRules.hasUpper(password)),
      ('Letra minúscula', PasswordRules.hasLower(password)),
      ('Número', PasswordRules.hasDigit(password)),
      ('Caractere especial (!@#\$...)', PasswordRules.hasSpecial(password)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: rules.map((r) {
        final (label, ok) = r;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BioIcon(ok ? 'check' : 'close',
                size: 12,
                color: ok ? AppColors.verdeDark : p.gray2,
                strokeWidth: 2.5),
            const SizedBox(width: 4),
            Text(label,
                style: AppText.inter(
                    size: 11, color: ok ? AppColors.verdeDark : p.gray2)),
          ],
        );
      }).toList(),
    );
  }

  Widget _field(AppPalette p, String label, TextEditingController controller,
      {TextInputType? keyboardType,
      bool obscure = false,
      String? hint,
      VoidCallback? onToggleObscure,
      ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppText.mono(
                size: 10.5,
                weight: FontWeight.w600,
                color: p.gray,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          onChanged: onChanged,
          style: AppText.inter(
              size: 15, weight: FontWeight.w600, color: AppColors.azul),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8),
            hintText: hint,
            hintStyle: AppText.inter(size: 14, color: p.gray2),
            border:
                UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.azul, width: 1.4)),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: BioIcon(obscure ? 'eye' : 'eye-off',
                        size: 18, color: p.gray),
                    onPressed: onToggleObscure,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _underlineField(AppPalette p,
      {required String label,
      required VoidCallback onTap,
      required String display,
      required String hint}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppText.mono(
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: p.gray,
                  letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.border))),
            child: Text(
              display.isEmpty ? hint : display,
              style: display.isEmpty
                  ? AppText.inter(size: 14, color: p.gray2)
                  : AppText.inter(
                      size: 15, weight: FontWeight.w600, color: AppColors.azul),
            ),
          ),
        ],
      ),
    );
  }
}
