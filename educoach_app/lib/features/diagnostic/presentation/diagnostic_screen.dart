import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
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
  int _currentIndex = 0;
  bool _isSubmitting = false;
  List<DiagnosticTopicResult>? _results;

  @override
  void initState() {
    super.initState();
    _questionsFuture = widget.api.getDiagnosticQuestions(widget.session.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _selectedAnswers.clear();
      _currentIndex = 0;
      _results = null;
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

    setState(() => _isSubmitting = true);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              message: error.toString(),
              onRetry: _refresh,
            );
          }

          final questions = snapshot.data ?? const <DiagnosticQuestion>[];
          if (questions.isEmpty) {
            return const Center(child: Text('No hay preguntas disponibles.'));
          }

          if (_results != null) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Resultados del diagnostico',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                Text(
                  '${question.topicName} · Nivel ${question.difficultyLevel}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  question.statement,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
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
                Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _currentIndex -= 1);
                          },
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
                                  setState(() => _currentIndex += 1);
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
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async => onRetry(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
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
      child: ListTile(
        title: Text('$value) $label'),
        trailing: isSelected ? const Icon(Icons.check_circle) : null,
        onTap: () => onChanged(value),
      ),
    );
  }
}
