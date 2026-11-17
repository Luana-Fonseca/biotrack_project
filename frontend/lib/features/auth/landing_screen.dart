import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _features = [
    ('calc', 'Calcular impacto em segundos'),
    ('book', 'Trilhas de aprendizado ESG'),
    ('file', 'Relatórios em PDF prontos'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          // A plain Column can't put an Expanded hero inside a
          // SingleChildScrollView (unbounded height), so the hero gets an
          // explicit height instead: fill the screen minus the button area
          // on tall screens, but never shrink below a readable minimum on
          // short ones — the SingleChildScrollView then absorbs any
          // overflow instead of throwing a RenderFlex layout error.
          const buttonAreaHeight = 220.0;
          final heroHeight = (constraints.maxHeight - buttonAreaHeight).clamp(460.0, double.infinity);
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.azul, AppColors.azulDark],
                          ),
                        ),
                      ),
                      ..._decorativeRings(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: AppColors.verde, borderRadius: BorderRadius.circular(13)),
                                  child: const Center(child: BioIcon('leaf', size: 22, color: Colors.white, strokeWidth: 2)),
                                ),
                                const SizedBox(width: 12),
                                Text('BioTrack', style: AppText.inter(size: 21, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'SUSTENTABILIDADE LOGÍSTICA',
                              style: AppText.mono(size: 11, weight: FontWeight.w700, color: AppColors.verde, letterSpacing: 1.1),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Meça seu impacto.\nReduza suas emissões.',
                              style: AppText.inter(size: 28, weight: FontWeight.w700, color: Colors.white, height: 1.2, letterSpacing: -0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Calcule o CO₂ da sua operação, acompanhe a economia com biometano e emita certificados ESG.',
                              style: AppText.inter(size: 13.5, color: Colors.white.withOpacity(0.75), height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            ..._features.map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(color: AppColors.verde, borderRadius: BorderRadius.circular(7)),
                                        child: Center(child: BioIcon(f.$1, size: 13, color: Colors.white, strokeWidth: 2.2)),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(f.$2, style: AppText.inter(size: 13.5, weight: FontWeight.w500, color: Colors.white)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Criar conta grátis',
                        icon: 'plus',
                        iconLeading: true,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Já tenho conta',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  static List<Widget> _decorativeRings() {
    Widget ring(double size, double top, double right, double opacity) => Positioned(
          top: top,
          right: right,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(opacity), width: 1)),
          ),
        );
    return [
      ring(260, -60, -80, 0.10),
      ring(180, -20, -40, 0.14),
      ring(110, 20, 0, 0.18),
    ];
  }
}
