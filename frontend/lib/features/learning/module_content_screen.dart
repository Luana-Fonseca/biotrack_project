import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import '../../shared/widgets/buttons.dart';
import 'learning_content_parser.dart';
import 'learning_models.dart';
import 'learning_provider.dart';
import 'quiz_question_card.dart';

class ModuleContentScreen extends StatefulWidget {
  final ModuleSummary module;
  final int trilhaId;

  const ModuleContentScreen(
      {super.key, required this.module, required this.trilhaId});

  @override
  State<ModuleContentScreen> createState() => _ModuleContentScreenState();
}

class _ModuleContentScreenState extends State<ModuleContentScreen> {
  bool _completing = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.module.completed;
  }

  Future<void> _complete() async {
    setState(() => _completing = true);
    await context
        .read<LearningProvider>()
        .completeModule(widget.module.id, widget.trilhaId);
    if (!mounted) return;
    setState(() {
      _completing = false;
      _completed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 20),
              Text('${widget.module.durationMinutes} min de leitura',
                  style: AppText.mono(size: 11.5, color: p.gray2)),
              const SizedBox(height: 8),
              Text(widget.module.title,
                  style: AppText.inter(
                      size: 24, weight: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 20),
              _ModuleBody(content: widget.module.content),
              const SizedBox(height: 32),
              if (_completed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: AppColors.verde.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BioIcon('check',
                          size: 16,
                          color: AppColors.verdeDark,
                          strokeWidth: 2.5),
                      const SizedBox(width: 8),
                      Text('Módulo concluído',
                          style: AppText.inter(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.verdeDark)),
                    ],
                  ),
                )
              else
                PrimaryButton(
                    label: 'Marcar como concluído',
                    icon: 'check',
                    loading: _completing,
                    onPressed: _complete),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a module's structured content: a quiz (one card per question, tap-to-reveal) when the
/// module is a "Teste de Conhecimento", or the usual explicação/analogia/curiosidades/resumo
/// reading sections otherwise.
class _ModuleBody extends StatelessWidget {
  final String content;

  const _ModuleBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (isQuizContent(content)) {
      final questions = parseQuiz(content);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < questions.length; i++)
            QuizQuestionCard(index: i, question: questions[i]),
        ],
      );
    }

    final s = parseModuleSections(content);
    if (s.explicacao.isEmpty &&
        s.analogia.isEmpty &&
        s.curiosidades.isEmpty &&
        s.resumo.isEmpty) {
      // Fallback for any legacy unmarked content.
      return Text(content,
          style: AppText.inter(size: 14.5, color: p.ink, height: 1.6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.explicacao.isNotEmpty) ...[
          const _SectionLabel(
              icon: 'book', label: 'Explicação', color: AppColors.azul),
          const SizedBox(height: 8),
          Text(s.explicacao,
              style: AppText.inter(size: 14.5, color: p.ink, height: 1.6)),
          const SizedBox(height: 22),
        ],
        if (s.analogia.isNotEmpty) ...[
          const _SectionLabel(
              icon: 'twin',
              label: 'Analogia prática',
              color: AppColors.verdeDark),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.verde.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Text(s.analogia,
                style: AppText.inter(size: 14, color: p.ink, height: 1.55)),
          ),
          const SizedBox(height: 22),
        ],
        if (s.curiosidades.isNotEmpty) ...[
          const _SectionLabel(
              icon: 'globe',
              label: 'Curiosidades rápidas',
              color: AppColors.azul),
          const SizedBox(height: 10),
          ...s.curiosidades.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                              color: AppColors.verde, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(c,
                            style: AppText.inter(
                                size: 13.5, color: p.gray, height: 1.5))),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],
        if (s.resumo.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.azul.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.azul.withOpacity(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BioIcon('flame',
                    size: 16, color: AppColors.azul, strokeWidth: 2.2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.resumo,
                      style: AppText.inter(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: p.ink,
                          height: 1.5)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BioIcon(icon, size: 15, color: color, strokeWidth: 2.2),
        const SizedBox(width: 8),
        Text(label,
            style: AppText.inter(
                size: 12,
                weight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3)),
      ],
    );
  }
}
