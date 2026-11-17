/// Parses the plain-text marker format used by [Module.content] on the backend: each line is
/// tagged with a prefix like `EXPLICACAO:`, `ANALOGIA:`, `CURIOSIDADE:`, `RESUMO:` for a reading
/// module, or `QUESTAO:`/`A:`/`B:`/`C:`/`D:`/`GABARITO:`/`EXPLICACAO:` repeated for a quiz
/// module. Kept deliberately simple (line-prefix based, no real markup language) since the
/// content is authored in one place (LearningDataSeeder) and only ever read back here.
library;

class ModuleSections {
  final String explicacao;
  final String analogia;
  final List<String> curiosidades;
  final String resumo;

  const ModuleSections({required this.explicacao, required this.analogia, required this.curiosidades, required this.resumo});
}

class QuizQuestion {
  final String question;
  final Map<String, String> options; // 'A' -> text, 'B' -> text, ...
  final String correctLetter;
  final String explanation;

  const QuizQuestion({required this.question, required this.options, required this.correctLetter, required this.explanation});
}

bool isQuizContent(String content) => content.contains('QUESTAO:');

ModuleSections parseModuleSections(String content) {
  final explicacao = StringBuffer();
  final analogia = StringBuffer();
  final curiosidades = <String>[];
  final resumo = StringBuffer();

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('EXPLICACAO:')) {
      explicacao.write(line.substring('EXPLICACAO:'.length).trim());
    } else if (line.startsWith('ANALOGIA:')) {
      analogia.write(line.substring('ANALOGIA:'.length).trim());
    } else if (line.startsWith('CURIOSIDADE:')) {
      curiosidades.add(line.substring('CURIOSIDADE:'.length).trim());
    } else if (line.startsWith('RESUMO:')) {
      resumo.write(line.substring('RESUMO:'.length).trim());
    }
  }

  return ModuleSections(
    explicacao: explicacao.toString(),
    analogia: analogia.toString(),
    curiosidades: curiosidades,
    resumo: resumo.toString(),
  );
}

List<QuizQuestion> parseQuiz(String content) {
  final questions = <QuizQuestion>[];
  String? question;
  Map<String, String> options = {};
  String? correctLetter;

  void flush(String? explanation) {
    if (question != null && correctLetter != null) {
      questions.add(QuizQuestion(
        question: question!,
        options: Map.of(options),
        correctLetter: correctLetter!,
        explanation: explanation ?? '',
      ));
    }
    question = null;
    options = {};
    correctLetter = null;
  }

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('QUESTAO:')) {
      if (question != null && correctLetter != null && options.length == 4) {
        // Previous question had no explanation line before this one started — flush as-is.
        flush(null);
      }
      question = line.substring('QUESTAO:'.length).trim();
    } else if (RegExp(r'^[A-D]:').hasMatch(line)) {
      options[line.substring(0, 1)] = line.substring(2).trim();
    } else if (line.startsWith('GABARITO:')) {
      correctLetter = line.substring('GABARITO:'.length).trim();
    } else if (line.startsWith('EXPLICACAO:')) {
      flush(line.substring('EXPLICACAO:'.length).trim());
    }
  }
  flush(null);
  return questions;
}
