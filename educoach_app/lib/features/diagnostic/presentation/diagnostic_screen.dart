import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/mascot_assets.dart';
import '../../../core/widgets/mascot_state_card.dart';
import '../../auth/session_storage.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onUnauthorized,
  });

  final EduCoachApi api;
  final AuthSession session;
  final Future<void> Function() onUnauthorized;

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  late Future<List<DiagnosticQuestion>> _questionsFuture;

  final Map<String, String> _selectedAnswers = {};
  final ScrollController _optionsScrollController = ScrollController();
  int _currentIndex = 0;
  bool _isSubmitting = false;
  List<DiagnosticTopicResult>? _results;
  String? _submitErrorMessage;

  @override
  void initState() {
    super.initState();
    _questionsFuture = widget.api.getDiagnosticQuestions(widget.session.token);
  }

  @override
  void dispose() {
    _optionsScrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _selectedAnswers.clear();
      _currentIndex = 0;
      _results = null;
      _submitErrorMessage = null;
      _questionsFuture = widget.api.getDiagnosticQuestions(widget.session.token);
    });
    await _questionsFuture;
  }

  Future<void> _submit(List<DiagnosticQuestion> questions) async {
    if (_selectedAnswers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes responder todas las preguntas.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = null;
    });

    try {
      final results = await widget.api.submitDiagnostic(
        widget.session.token,
        questions
            .map(
              (question) => DiagnosticAnswer(
                questionId: question.id,
                selectedOption: _selectedAnswers[question.id]!,
              ),
            )
            .toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() => _results = results);
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiException && error.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }
      setState(() => _submitErrorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _moveToQuestion(int index) async {
    if (_optionsScrollController.hasClients) {
      await _optionsScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostico')),
      body: FutureBuilder<List<DiagnosticQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            if (error is ApiException && error.statusCode == 401) {
              WidgetsBinding.instance.addPostFrameCallback((_) => widget.onUnauthorized());
              return const Center(child: Text('Sesion expirada. Inicia sesion nuevamente.'));
            }

            return _ErrorView(
              title: 'No pudimos cargar el diagnostico',
              message: error.toString(),
              onRetry: _refresh,
            );
          }

          final questions = snapshot.data ?? const <DiagnosticQuestion>[];
          if (questions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: MascotStateCard(
                imageAsset: MascotAssets.reading,
                title: 'No hay preguntas disponibles',
                message:
                    'Todavia no encontramos preguntas de diagnostico. Intenta de nuevo en unos minutos.',
                tone: MascotTone.warning,
                primaryLabel: 'Reintentar',
                onPrimaryPressed: _refresh,
              ),
            );
          }

          if (_results != null) {
            final totalQuestions = _results!.fold<int>(
              0,
              (sum, result) => sum + result.totalQuestions,
            );
            final totalCorrect = _results!.fold<int>(
              0,
              (sum, result) => sum + result.score,
            );

            return Scrollbar(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  AppEntrance(
                    child: MascotStateCard(
                      imageAsset: MascotAssets.celebrate,
                      title: 'Diagnostico completado',
                      message:
                          'Ya tenemos una base para recomendarte ejercicios y seguir tu avance por tema.',
                      tone: MascotTone.success,
                      primaryLabel: 'Repetir diagnostico',
                      onPrimaryPressed: _refresh,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ResultPill(
                            label: 'Aciertos totales',
                            value: '$totalCorrect/$totalQuestions',
                          ),
                          _ResultPill(
                            label: 'Temas evaluados',
                            value: '${_results!.length}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resultado por tema',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  for (final result in _results!) ...[
                    Card(
                      child: ListTile(
                        title: Text(result.topicName),
                        subtitle: Text(
                          'Aciertos: ${result.score}/${result.totalQuestions}',
                        ),
                        trailing: Text('Nivel ${result.assignedLevel}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          }

          final question = questions[_currentIndex];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregunta ${_currentIndex + 1} de ${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / questions.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(12),
                ),
                if (_submitErrorMessage != null) ...[
                  const SizedBox(height: 16),
                  MascotMessageBanner(
                    title: 'No pudimos enviar tus respuestas',
                    message: _submitErrorMessage!,
                    imageAsset: MascotAssets.worried,
                    tone: MascotTone.error,
                  ),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: Scrollbar(
                      key: ValueKey(question.id),
                      controller: _optionsScrollController,
                      child: ListView(
                        controller: _optionsScrollController,
                        children: [
                          AppEntrance(
                            child: _QuestionPanel(
                              header: '${question.topicName} · Nivel ${question.difficultyLevel}',
                              statement: question.statement,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _AnswerOption(
                            value: 'A',
                            isSelected: _selectedAnswers[question.id] == 'A',
                            label: question.optionA,
                            onChanged: (value) {
                              setState(() => _selectedAnswers[question.id] = value);
                            },
                          ),
                          _AnswerOption(
                            value: 'B',
                            isSelected: _selectedAnswers[question.id] == 'B',
                            label: question.optionB,
                            onChanged: (value) {
                              setState(() => _selectedAnswers[question.id] = value);
                            },
                          ),
                          _AnswerOption(
                            value: 'C',
                            isSelected: _selectedAnswers[question.id] == 'C',
                            label: question.optionC,
                            onChanged: (value) {
                              setState(() => _selectedAnswers[question.id] = value);
                            },
                          ),
                          _AnswerOption(
                            value: 'D',
                            isSelected: _selectedAnswers[question.id] == 'D',
                            label: question.optionD,
                            onChanged: (value) {
                              setState(() => _selectedAnswers[question.id] = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _moveToQuestion(_currentIndex - 1),
                          child: const Text('Anterior'),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (_selectedAnswers[question.id] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Selecciona una opcion para continuar.'),
                                    ),
                                  );
                                  return;
                                }

                                if (_currentIndex == questions.length - 1) {
                                  _submit(questions);
                                } else {
                                  _moveToQuestion(_currentIndex + 1);
                                }
                              },
                        child: Text(
                          _isSubmitting
                              ? 'Enviando...'
                              : _currentIndex == questions.length - 1
                                  ? 'Finalizar diagnostico'
                                  : 'Siguiente',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: MascotStateCard(
        imageAsset: MascotAssets.sad,
        title: title,
        message: message,
        tone: MascotTone.error,
        primaryLabel: 'Reintentar',
        onPrimaryPressed: () async => onRetry(),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5B6B7D),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF12243A),
                ),
          ),
        ],
      ),
    );
  }

}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.value,
    required this.isSelected,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final bool isSelected;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text('$value) $label'),
        trailing: isSelected ? const Icon(Icons.check_circle) : null,
        onTap: () => onChanged(value),
      ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.header,
    required this.statement,
  });

  final String header;
  final String statement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF425466),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              statement,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
