import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/password_rules.dart';
import '../../core/professions.dart';
import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/floating_sheet.dart';
import '../auth/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  final _newPasswordController = TextEditingController();
  String? _profession;
  DateTime? _birthDate;
  bool _saving = false;
  bool _changingPassword = false;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _profession = user?.profession;
    _birthDate = user?.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfession() async {
    final p = context.palette;
    final selected = await showFloatingSheet<String>(
      context,
      builder: (context) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shrinkWrap: true,
        children: kProfessions
            .map((prof) => ListTile(
                  title: Text(prof, style: AppText.inter(size: 14.5, color: p.ink)),
                  onTap: () => Navigator.of(context).pop(prof),
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

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: _nameController.text.trim(),
      profession: _profession,
      city: _cityController.text.trim(),
      birthDate: _birthDate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
      Navigator.of(context).pop();
    } else if (auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError!)));
    }
  }

  Future<void> _savePassword() async {
    if (!PasswordRules.isStrong(_newPasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A nova senha precisa ter maiúscula, minúscula, número e caractere especial.')),
      );
      return;
    }
    setState(() => _changingPassword = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(newPassword: _newPasswordController.text);
    if (!mounted) return;
    setState(() => _changingPassword = false);
    if (ok) {
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso.')));
    } else if (auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 24),
              Text('Editar perfil', style: AppText.inter(size: 26, weight: FontWeight.w700, color: AppColors.azul)),
              const SizedBox(height: 28),
              _label(p, 'Nome completo'),
              const SizedBox(height: 6),
              _textField(p, _nameController),
              const SizedBox(height: 20),
              _label(p, 'Profissão'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickProfession,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_profession ?? 'Selecione sua profissão', style: AppText.inter(size: 14, color: _profession == null ? p.gray2 : p.ink)),
                      BioIcon('chev-d', size: 16, color: p.gray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label(p, 'Cidade'),
              const SizedBox(height: 6),
              _textField(p, _cityController),
              const SizedBox(height: 20),
              _label(p, 'Data de nascimento'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(birthLabel.isEmpty ? 'dd/mm/aaaa' : birthLabel, style: AppText.inter(size: 14, color: birthLabel.isEmpty ? p.gray2 : p.ink)),
                      BioIcon('chev-d', size: 16, color: p.gray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Salvar alterações', loading: _saving, onPressed: _save),
              const SizedBox(height: 40),
              Row(
                children: [
                  const BioIcon('lock', size: 18, color: AppColors.azul, strokeWidth: 2),
                  const SizedBox(width: 10),
                  Text('Alterar senha de login', style: AppText.inter(size: 16, weight: FontWeight.w700, color: p.ink)),
                ],
              ),
              const SizedBox(height: 6),
              Text('A senha é salva no banco de dados assim que confirmada.', style: AppText.inter(size: 12.5, color: p.gray)),
              const SizedBox(height: 20),
              _label(p, 'Nova senha'),
              const SizedBox(height: 6),
              _passwordField(p, _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              _passwordChecklist(p, _newPasswordController.text),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Alterar senha', icon: 'lock', iconLeading: true, loading: _changingPassword, onPressed: _savePassword),
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
            BioIcon(ok ? 'check' : 'close', size: 12, color: ok ? AppColors.verdeDark : p.gray2, strokeWidth: 2.5),
            const SizedBox(width: 4),
            Text(label, style: AppText.inter(size: 11, color: ok ? AppColors.verdeDark : p.gray2)),
          ],
        );
      }).toList(),
    );
  }

  Widget _label(AppPalette p, String text) => Text(text, style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: p.gray, letterSpacing: 0.4));

  Widget _textField(AppPalette p, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: AppText.inter(size: 14, color: p.ink),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
      ),
    );
  }

  Widget _passwordField(AppPalette p, TextEditingController controller, bool obscure, VoidCallback toggle, {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: AppText.inter(size: 14, color: p.ink),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
        suffixIcon: IconButton(
          icon: BioIcon(obscure ? 'eye' : 'eye-off', size: 18, color: p.gray),
          onPressed: toggle,
        ),
      ),
    );
  }
}
