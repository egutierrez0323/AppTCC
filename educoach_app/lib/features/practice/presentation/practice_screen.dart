import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/api/educoach_api.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/mascot_assets.dart';
import '../../../core/widgets/mascot_state_card.dart';
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
  static const _modes = <String>[
    PracticeMode.normal,
    PracticeMode.review,
    PracticeMode.mixed,
  ];

  late int _topicId;
  late int _level;
  late Future<List<PracticeTopic>> _topicsFuture;
  final ScrollController _questionScrollController = ScrollController();
  String _mode = PracticeMode.normal;
  bool _isLoading = false;
  PracticeSessionData? _sessionData;
  PracticeAnswerResult? _summary;
  int _currentIndex = 0;
  String? _selectedOption;
  String? _sessionNotice;

  @override
  void initState() {
    super.initState();
    _topicId = widget.initialTopicId ?? 1;
    _level = widget.initialLevel ?? 1;
    _topicsFuture = _loadTopics();
  }

  @override
  void dispose() {
    _questionScrollController.dispose();
    super.dispose();
  }

  Future<List<PracticeTopic>> _loadTopics() async {
    return widget.api.getTopics(widget.session.token);
  }

  Future<void> _refreshTopics() async {
    setState(() => _topicsFuture = _loadTopics());
    await _topicsFuture;
  }

  Future<void> _startPractice() async {
    setState(() {
      _isLoading = true;
      _summary = null;
      _sessionNotice = null;
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
        _sessionNotice = session.modeMessage;
      });

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
              child: _PracticeAnswerFeedback(result: result),
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
        await _moveToQuestion(_currentIndex + 1);
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

  Future<void> _moveToQuestion(int index) async {
    if (_questionScrollController.hasClients) {
      await _questionScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _sessionData;

    return Scaffold(
      appBar: AppBar(title: const Text('Practica')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: session == null
            ? FutureBuilder<List<PracticeTopic>>(
                future: _topicsFuture,
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

                    return _PracticeErrorView(
                      title: 'No pudimos cargar los temas',
                      message: error.toString(),
                      onRetry: _refreshTopics,
                    );
                  }

                  final topics = snapshot.data ?? const <PracticeTopic>[];
                  if (topics.isEmpty) {
                    return _PracticeErrorView(
                      title: 'No hay temas disponibles',
                      message: 'No hay temas disponibles en este momento.',
                      onRetry: _refreshTopics,
                    );
                  }

                  final effectiveTopicId = topics.any((topic) => topic.id == _topicId)
                      ? _topicId
                      : topics.first.id;
                  if (effectiveTopicId != _topicId) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _topicId = effectiveTopicId);
                      }
                    });
                  }

                  return ListView(
                    children: [
                      AppEntrance(
                        child: _PracticeSetupHero(mode: _mode),
                      ),
                      const SizedBox(height: 16),
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
                      if (_mode == PracticeMode.review) ...[
                        const SizedBox(height: 16),
                        const MascotMessageBanner(
                          title: 'Repaso inteligente',
                          message:
                              'Vamos a priorizar preguntas que ya fallaste en este tema y nivel. Si todavia no hay errores previos, iniciaremos una practica normal.',
                          imageAsset: MascotAssets.poseThinking,
                          tone: MascotTone.info,
                        ),
                      ] else if (_mode == PracticeMode.mixed) ...[
                        const SizedBox(height: 16),
                        const MascotMessageBanner(
                          title: 'Sesion variada',
                          message:
                              'Combina preguntas de varios temas para entrenar de forma mas dinamica sin cambiar de pantalla.',
                          imageAsset: MascotAssets.books,
                          tone: MascotTone.info,
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: effectiveTopicId,
                        decoration: const InputDecoration(labelText: 'Tema'),
                        items: topics
                            .map(
                              (topic) => DropdownMenuItem<int>(
                                value: topic.id,
                                child: Text(topic.name),
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
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          topics
                              .firstWhere((topic) => topic.id == effectiveTopicId)
                              .description,
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
                  );
                },
              )
            : _summary != null
                ? ListView(
                    children: [
                      AppEntrance(
                        child: MascotStateCard(
                          imageAsset: _summary!.sessionCorrectCount >=
                                  (_summary!.sessionTotalCount / 2).ceil()
                              ? MascotAssets.applause
                              : MascotAssets.wink,
                          title: 'Sesion completada',
                          message:
                              'Buen trabajo. Ya registramos tus resultados y el progreso de esta practica.',
                          tone: MascotTone.success,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SummaryMetric(
                                label: 'Modo',
                                value: _modeLabel(session.mode),
                              ),
                              _SummaryMetric(
                                label: 'Tema',
                                value: session.topicName,
                              ),
                              _SummaryMetric(
                                label: 'Aciertos',
                                value:
                                    '${_summary!.sessionCorrectCount}/${_summary!.sessionTotalCount}',
                              ),
                              _SummaryMetric(
                                label: 'Nivel actual',
                                value: '${_summary!.currentLevel}',
                              ),
                              _SummaryMetric(
                                label: 'Racha',
                                value: '${_summary!.streakDays} dias',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _sessionData = null;
                                _summary = null;
                                _currentIndex = 0;
                                _sessionNotice = null;
                              });
                            },
                            child: const Text('Practicar otra vez'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Volver al inicio'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_sessionNotice != null && _sessionNotice!.isNotEmpty) ...[
                        MascotMessageBanner(
                          title: 'Aviso de la sesion',
                          message: _sessionNotice!,
                          imageAsset: session.mode == PracticeMode.review
                              ? MascotAssets.poseThinking
                              : MascotAssets.books,
                          tone: MascotTone.info,
                        ),
                        const SizedBox(height: 16),
                      ],
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                              const Color(0xFF6EE7F5).withValues(alpha: 0.08),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.topicName} · Nivel ${session.difficultyLevel}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(_modeLabel(session.mode)),
                              const SizedBox(height: 8),
                              Text('Pregunta ${_currentIndex + 1} de ${session.questions.length}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / session.questions.length,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: Scrollbar(
                            key: ValueKey(session.questions[_currentIndex].id),
                            controller: _questionScrollController,
                            child: ListView(
                              controller: _questionScrollController,
                              children: [
                                AppEntrance(
                                  child: _QuestionCard(
                                    statement: session.questions[_currentIndex].statement,
                                  ),
                                ),
                                const SizedBox(height: 20),
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

class _PracticeErrorView extends StatelessWidget {
  const _PracticeErrorView({
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

class _PracticeAnswerFeedback extends StatelessWidget {
  const _PracticeAnswerFeedback({required this.result});

  final PracticeAnswerResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            result.correct ? MascotAssets.happy : MascotAssets.poseThinking,
            height: 110,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.calculate_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (result.correct)
          Text(
            'Buen trabajo. Sigue avanzando.',
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else
          _ExplanationContent(
            correctOption: result.correctOption,
            explanation: result.explanation,
          ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5B6B7D),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF12243A),
                ),
          ),
        ],
      ),
    );
  }
}

class _PracticeSetupHero extends StatelessWidget {
  const _PracticeSetupHero({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final imageAsset = switch (mode) {
      PracticeMode.review => MascotAssets.poseThinking,
      PracticeMode.mixed => MascotAssets.books,
      _ => MascotAssets.writing,
    };

    final title = switch (mode) {
      PracticeMode.review => 'Repasa con enfoque',
      PracticeMode.mixed => 'Entrena con variedad',
      _ => 'Prepara tu proxima practica',
    };

    final message = switch (mode) {
      PracticeMode.review =>
        'Escoge tema y nivel para volver sobre los ejercicios donde mas apoyo necesitas.',
      PracticeMode.mixed =>
        'Elige el nivel y deja que EduCoach combine preguntas de distintos temas en una sola sesion.',
      _ => 'Selecciona el tema y el nivel para empezar una sesion clara, corta y enfocada.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 560;
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    switch (mode) {
                      PracticeMode.mixed => 'Practica mixta',
                      PracticeMode.review => 'Repasar errores',
                      _ => 'Practica normal',
                    },
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF12243A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF425466),
                        height: 1.4,
                      ),
                ),
              ],
            );

            final mascot = InteractiveParallax(
              maxOffset: 6,
              child: RepaintBoundary(
                child: Image.asset(
                  imageAsset,
                  height: stacked ? 120 : 136,
                  fit: BoxFit.contain,
                  cacheWidth: stacked ? 240 : 272,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.calculate_rounded,
                      size: stacked ? 80 : 88,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: mascot),
                  const SizedBox(height: 16),
                  text,
                ],
              );
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
                    const Color(0xFF6EE7F5).withValues(alpha: 0.10),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 16),
                    mascot,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return HoverLift(
      onTap: () => onChanged(value),
      lift: 3,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.32)
                : Colors.blueGrey.withValues(alpha: 0.10),
          ),
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    colorScheme.primary.withValues(alpha: 0.12),
                    colorScheme.secondary.withValues(alpha: 0.08),
                    Colors.white,
                  ]
                : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            title: Text('$value) $label'),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: colorScheme.primary)
                : Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.primary),
            onTap: () => onChanged(value),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.statement});

  final String statement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
            const Color(0xFF6EE7F5).withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          statement,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
