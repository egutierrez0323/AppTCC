import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/api/educoach_api.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/mascot_assets.dart';
import '../../../core/widgets/mascot_state_card.dart';
import '../../auth/session_storage.dart';

class PracticeSessionDetailScreen extends StatefulWidget {
  const PracticeSessionDetailScreen({
    super.key,
    required this.api,
    required this.session,
    required this.sessionId,
    required this.onUnauthorized,
  });

  final EduCoachApi api;
  final AuthSession session;
  final String sessionId;
  final Future<void> Function() onUnauthorized;

  @override
  State<PracticeSessionDetailScreen> createState() => _PracticeSessionDetailScreenState();
}

class _PracticeSessionDetailScreenState extends State<PracticeSessionDetailScreen> {
  late Future<PracticeSessionDetail> _future = _load();

  Future<PracticeSessionDetail> _load() async {
    return widget.api.getPracticeSessionDetail(widget.session.token, widget.sessionId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de practica')),
      body: FutureBuilder<PracticeSessionDetail>(
        future: _future,
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
              title: 'No pudimos cargar la sesion',
              message: error.toString(),
              onRetry: _refresh,
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('No se pudo cargar la sesion.'));
          }

          final incorrect = detail.answers.where((item) => !item.isCorrect).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Scrollbar(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  MascotStateCard(
                    imageAsset: incorrect.isEmpty ? MascotAssets.applause : MascotAssets.poseThinking,
                    title: '${detail.topicName} · Nivel ${detail.difficultyLevel}',
                    message: incorrect.isEmpty
                        ? 'Excelente trabajo. En esta sesion no hubo errores y tu progreso quedo registrado.'
                        : 'Aqui puedes repasar con calma las respuestas que fallaste y entender mejor cada solucion.',
                    tone: incorrect.isEmpty ? MascotTone.success : MascotTone.info,
                    centered: false,
                    imageSize: 120,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DetailMetric(
                          label: 'Aciertos',
                          value: '${detail.correctCount}/${detail.totalCount}',
                        ),
                        _DetailMetric(
                          label: 'Respuestas',
                          value: '${detail.answers.length}',
                        ),
                        _DetailMetric(
                          label: 'Errores',
                          value: '${incorrect.length}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Respuestas incorrectas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (incorrect.isEmpty)
                    const MascotStateCard(
                      imageAsset: MascotAssets.happy,
                      title: 'No hay errores en esta sesion',
                      message:
                          'Aprovecha este resultado para continuar con practica mixta o subir de nivel en tu siguiente sesion.',
                      tone: MascotTone.success,
                      imageSize: 110,
                    )
                  else
                    for (final answer in incorrect) ...[
                      HoverLift(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  answer.statement,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text('Tu respuesta: ${answer.selectedOption}'),
                                Text('Correcta: ${answer.correctOption}'),
                                if (answer.aiExplanation != null) ...[
                                  const SizedBox(height: 8),
                                  _StoredExplanationView(explanation: answer.aiExplanation!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoredExplanationView extends StatelessWidget {
  const _StoredExplanationView({required this.explanation});

  final AiMathExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (explanation.summary.isNotEmpty) Text(explanation.summary),
        for (final step in explanation.steps) ...[
          const SizedBox(height: 8),
          Text(
            step.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(step.text),
          if (step.formulaLatex.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                step.formulaLatex,
                mathStyle: MathStyle.display,
                onErrorFallback: (error) => Text(step.formulaLatex),
              ),
            ),
          ],
        ],
        if (explanation.finalAnswerText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            explanation.finalAnswerText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        if (explanation.encouragement.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(explanation.encouragement),
        ],
      ],
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

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
