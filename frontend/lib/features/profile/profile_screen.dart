import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../shared/widgets/bio_icon.dart';
import '../auth/auth_provider.dart';
import '../auth/landing_screen.dart';
import '../legal/privacy_terms_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickPhoto(AuthProvider auth) async {
    final p = context.palette;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const BioIcon('camera', size: 20, color: AppColors.azul),
              title: Text('Tirar foto', style: TextStyle(color: p.ink)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const BioIcon('image', size: 20, color: AppColors.azul),
              title: Text('Escolher da galeria', style: TextStyle(color: p.ink)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final ok = await auth.updatePhoto(base64Str);
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar a foto.')));
    }
  }

  void _logout(AuthProvider auth) async {
    await auth.logout();
    if (!mounted) return;
    // ProfileScreen lives inside AppShell's nested per-tab Navigator, so a
    // plain Navigator.of(context) here would resolve to that nested
    // Navigator and merely push LandingScreen on top of it — leaving the
    // AppShell's own Scaffold/BioTabBar (mounted via the root Navigator)
    // visible underneath. rootNavigator: true escapes to the app's actual
    // root Navigator so the whole shell gets replaced.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text('Perfil', style: AppText.inter(size: 26, weight: FontWeight.w700, color: AppColors.azul, letterSpacing: -0.5)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.azul.withOpacity(0.08),
                          image: user?.profilePhotoBase64 != null
                              ? DecorationImage(image: MemoryImage(base64Decode(user!.profilePhotoBase64!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: user?.profilePhotoBase64 == null
                            ? const Center(child: BioIcon('user', size: 36, color: AppColors.azul, strokeWidth: 1.6))
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _uploadingPhoto ? null : () => _pickPhoto(auth),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.verde),
                            child: _uploadingPhoto
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Center(child: BioIcon('camera', size: 15, color: Colors.white, strokeWidth: 2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '', style: AppText.inter(size: 17, weight: FontWeight.w700, color: p.ink)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: AppText.inter(size: 12.5, color: p.gray)),
                  if (user?.profession != null && user!.profession!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.azul.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
                      child: Text(user.profession!, style: AppText.inter(size: 11.5, weight: FontWeight.w600, color: AppColors.azul)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                children: [
                  _menuItem(p, 'edit', 'Editar perfil', () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  }),
                  _darkModeItem(p, themeProvider),
                  _menuItem(p, 'shield', 'Privacidade e segurança',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyTermsScreen()))),
                  _menuItem(p, 'logout', 'Sair', () => _logout(auth), color: AppColors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(AppPalette p, String icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
        child: Row(
          children: [
            BioIcon(icon, size: 18, color: color ?? AppColors.azul, strokeWidth: 2),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.inter(size: 14, weight: FontWeight.w600, color: color ?? p.ink))),
            BioIcon('chev-r', size: 14, color: p.gray2, strokeWidth: 2),
          ],
        ),
      ),
    );
  }

  Widget _darkModeItem(AppPalette p, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Row(
        children: [
          const BioIcon('moon', size: 18, color: AppColors.azul, strokeWidth: 2),
          const SizedBox(width: 14),
          Expanded(child: Text('Modo escuro', style: AppText.inter(size: 14, weight: FontWeight.w600, color: p.ink))),
          Switch(
            value: themeProvider.isDark,
            activeColor: AppColors.verde,
            onChanged: (value) => themeProvider.toggle(value),
          ),
        ],
      ),
    );
  }
}
