import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/widgets/bio_icon.dart';
import 'learning_content_parser.dart';

/// A single multiple-choice question: tapping an option locks it in, highlights it green
/// (correct) or red (wrong, with the correct one also marked), and reveals the explanation.
class QuizQuestionCard extends StatefulWidget {
  final int index;
  final QuizQuestion question;

  const QuizQuestionCard({super.key, required this.index, required this.question});

  @override
  State<QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = widget.question;
    final answered = _selected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pergunta ${widget.index + 1}', style: AppText.mono(size: 11, weight: FontWeight.w700, color: AppColors.verdeDark)),
          const SizedBox(height: 6),
          Text(q.question, style: AppText.inter(size: 14.5, weight: FontWeight.w700, color: p.ink, height: 1.4)),
          const SizedBox(height: 12),
          ...q.options.entries.map((entry) {
            final letter = entry.key;
            final isCorrect = letter == q.correctLetter;
            final isSelected = letter == _selected;

            Color bg = p.bg;
            Color border = p.border;
            Color text = p.ink;
            if (answered && isCorrect) {
              bg = AppColors.verde.withOpacity(0.12);
              border = AppColors.verde;
              text = AppColors.verdeDark;
            } else if (answered && isSelected && !isCorrect) {
              bg = AppColors.red.withOpacity(0.1);
              border = AppColors.red;
              text = AppColors.red;
            }

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: answered ? null : () => setState(() => _selected = letter),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border)),
                      child: Text(letter, style: AppText.mono(size: 11, weight: FontWeight.w700, color: text)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.value, style: AppText.inter(size: 13, color: text))),
                    if (answered && isCorrect) const BioIcon('check', size: 16, color: AppColors.verdeDark, strokeWidth: 2.5),
                  ],
                ),
              ),
            );
          }),
          if (answered && q.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.azul.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Text(q.explanation, style: AppText.inter(size: 12.5, color: p.ink, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}
