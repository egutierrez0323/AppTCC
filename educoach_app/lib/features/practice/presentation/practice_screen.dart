import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/api/educoach_api.dart';
import '../../auth/session_storage.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onUnauthorized,
    this.initialTopicId,
    this.initialLevel,
  });

  final EduCoachApi api;
  final AuthSession session;
  final Future<void> Function() onUnauthorized;
  final int? initialTopicId;
  final int? initialLevel;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const _topics = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Fracciones'},
    {'id': 2, 'name': 'Algebra Basica'},
    {'id': 3, 'name': 'Decimales'},
    {'id': 4, 'name': 'Geometria Basica'},
  ];
  static const _modes = <String>[
    PracticeMode.normal,
    PracticeMode.review,
    PracticeMode.mixed,
  ];

  late int _topicId;
  late int _level;
  String _mode = PracticeMode.normal;
  bool _isLoading = false;
  PracticeSessionData? _sessionData;
  PracticeAnswerResult? _summary;
  int _currentIndex = 0;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _topicId = widget.initialTopicId ?? 1;
    _level = widget.initialLevel ?? 1;
  }

  Future<void> _startPractice() async {
    setState(() {
      _isLoading = true;
      _summary = null;
    });

    try {
      final session = await widget.api.startPractice(
        widget.session.token,
        _topicId,
        _level,
        mode: _mode,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sessionData = session;
        _currentIndex = 0;
        _selectedOption = null;
      });

      final message = session.modeMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAnswer() async {
    final session = _sessionData;
    if (session == null || _selectedOption == null) {
      return;
    }

    setState(() => _isLoading = true);
    final question = session.questions[_currentIndex];

    try {
      final result = await widget.api.submitPracticeAnswer(
        widget.session.token,
        PracticeAnswerSubmission(
          sessionId: session.sessionId,
          questionId: question.id,
          selectedOption: _selectedOption!,
          responseTimeSeconds: 0,
        ),
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(result.correct ? 'Respuesta correcta' : 'Respuesta incorrecta'),
            content: SingleChildScrollView(
              child: result.correct
                  ? const Text('Buen trabajo. Sigue avanzando.')
                  : _ExplanationContent(
                      correctOption: result.correctOption,
                      explanation: result.explanation,
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (result.sessionCompleted || _currentIndex == session.questions.length - 1) {
        setState(() {
          _summary = result;
          _selectedOption = null;
        });
      } else {
        setState(() {
          _currentIndex += 1;
          _selectedOption = null;
        });
      }
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _sessionData;

    return Scaffold(
      appBar: AppBar(title: const Text('Practica')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: session == null
            ? ListView(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _mode,
                    decoration: const InputDecoration(labelText: 'Modo'),
                    items: _modes
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(_modeLabel(mode)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _mode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modeDescription(_mode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _topicId,
                    decoration: const InputDecoration(labelText: 'Tema'),
                    items: _topics
                        .map(
                          (topic) => DropdownMenuItem<int>(
                            value: topic['id'] as int,
                            child: Text(topic['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: _mode == PracticeMode.mixed
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _topicId = value);
                            }
                          },
                  ),
                  if (_mode == PracticeMode.mixed) ...[
                    const SizedBox(height: 8),
                    Text(
                      'En practica mixta el tema se ignora y se combinan preguntas de varios temas en el nivel elegido.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _level,
                    decoration: const InputDecoration(labelText: 'Nivel'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Basico')),
                      DropdownMenuItem(value: 2, child: Text('Intermedio')),
                      DropdownMenuItem(value: 3, child: Text('Avanzado')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _level = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _startPractice,
                    child: Text(_isLoading ? 'Cargando...' : 'Iniciar practica'),
                  ),
                ],
              )
            : _summary != null
                ? ListView(
                    children: [
                      Text(
                        'Sesion completada',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modo: ${_modeLabel(session.mode)}'),
                              Text('Tema: ${session.topicName}'),
                              Text('Nivel actual: ${_summary!.currentLevel}'),
                              Text(
                                'Aciertos: ${_summary!.sessionCorrectCount}/${_summary!.sessionTotalCount}',
                              ),
                              Text('Racha: ${_summary!.streakDays} dias'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sessionData = null;
                            _summary = null;
                            _currentIndex = 0;
                          });
                        },
                        child: const Text('Practicar otra vez'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${session.topicName} · Nivel ${session.difficultyLevel}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(_modeLabel(session.mode)),
                      const SizedBox(height: 8),
                      Text('Pregunta ${_currentIndex + 1} de ${session.questions.length}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / session.questions.length,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        session.questions[_currentIndex].statement,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: [
                            _PracticeOption(
                              value: 'A',
                              label: session.questions[_currentIndex].optionA,
                              isSelected: _selectedOption == 'A',
                              onChanged: (value) => setState(() => _selectedOption = value),
                            ),
                            _PracticeOption(
                              value: 'B',
                              label: session.questions[_currentIndex].optionB,
                              isSelected: _selectedOption == 'B',
                              onChanged: (value) => setState(() => _selectedOption = value),
                            ),
                            _PracticeOption(
                              value: 'C',
                              label: session.questions[_currentIndex].optionC,
                              isSelected: _selectedOption == 'C',
                              onChanged: (value) => setState(() => _selectedOption = value),
                            ),
                            _PracticeOption(
                              value: 'D',
                              label: session.questions[_currentIndex].optionD,
                              isSelected: _selectedOption == 'D',
                              onChanged: (value) => setState(() => _selectedOption = value),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading || _selectedOption == null ? null : _submitAnswer,
                        child: Text(_isLoading ? 'Enviando...' : 'Confirmar respuesta'),
                      ),
                    ],
                  ),
      ),
    );
  }

  String _modeLabel(String mode) {
    return switch (mode) {
      PracticeMode.mixed => 'Practica mixta',
      PracticeMode.review => 'Repasar errores',
      _ => 'Practica normal',
    };
  }

  String _modeDescription(String mode) {
    return switch (mode) {
      PracticeMode.mixed =>
        'Combina preguntas de varios temas usando el nivel seleccionado. El tema queda solo como referencia y no limita la sesion.',
      PracticeMode.review =>
        'Prioriza preguntas que ya fallaste antes en el tema y nivel elegidos. Si aun no hay errores previos, inicia una practica normal.',
      _ => 'Inicia una sesion normal con preguntas del tema y nivel seleccionados.',
    };
  }
}

class _ExplanationContent extends StatelessWidget {
  const _ExplanationContent({
    required this.correctOption,
    required this.explanation,
  });

  final String correctOption;
  final AiMathExplanation? explanation;

  @override
  Widget build(BuildContext context) {
    final explanation = this.explanation;
    if (explanation == null) {
      return Text('La opcion correcta es $correctOption.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('La opcion correcta es $correctOption.'),
        if (explanation.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(explanation.summary),
        ],
        for (var index = 0; index < explanation.steps.length; index++) ...[
          const SizedBox(height: 12),
          Text(
            '${index + 1}. ${explanation.steps[index].title}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(explanation.steps[index].text),
          if (explanation.steps[index].formulaLatex.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FormulaView(formulaLatex: explanation.steps[index].formulaLatex),
          ],
        ],
        if (explanation.finalAnswerText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            explanation.finalAnswerText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        if (explanation.encouragement.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(explanation.encouragement),
        ],
      ],
    );
  }
}

class _FormulaView extends StatelessWidget {
  const _FormulaView({required this.formulaLatex});

  final String formulaLatex;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Math.tex(
        formulaLatex,
        mathStyle: MathStyle.display,
        onErrorFallback: (error) => Text(formulaLatex),
      ),
    );
  }
}

class _PracticeOption extends StatelessWidget {
  const _PracticeOption({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  final String value;
  final String label;
  final bool isSelected;
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
