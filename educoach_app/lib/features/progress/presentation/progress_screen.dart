import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/mascot_assets.dart';
import '../../../core/widgets/mascot_state_card.dart';
import '../../auth/session_storage.dart';
import '../../practice/presentation/practice_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onUnauthorized,
  });

  final EduCoachApi api;
  final AuthSession session;
  final Future<void> Function() onUnauthorized;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<List<ProgressTopic>> _future = _load();

  Future<List<ProgressTopic>> _load() async {
    return widget.api.getProgress(widget.session.token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _openPractice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          api: widget.api,
          session: widget.session,
          onUnauthorized: widget.onUnauthorized,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: FutureBuilder<List<ProgressTopic>>(
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
              title: 'No pudimos cargar tu progreso',
              message: error.toString(),
              onRetry: _refresh,
            );
          }

          final topics = snapshot.data ?? const <ProgressTopic>[];
          if (topics.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: MascotStateCard(
                imageAsset: MascotAssets.poseThinking,
                title: 'Todavia no hay progreso registrado',
                message:
                    'Completa un diagnostico o una practica para ver tu avance por tema, tu nivel actual y tu racha.',
                tone: MascotTone.info,
                primaryLabel: 'Ir a practicar',
                onPrimaryPressed: _openPractice,
              ),
            );
          }

          final totalAttempts = topics.fold<int>(0, (sum, topic) => sum + topic.totalAttempts);
          final totalCorrect = topics.fold<int>(0, (sum, topic) => sum + topic.totalCorrect);
          final bestTopic = topics.reduce(
            (current, next) =>
                current.accuracyPercentage >= next.accuracyPercentage ? current : next,
          );
          final focusTopic = topics.reduce(
            (current, next) =>
                current.accuracyPercentage <= next.accuracyPercentage ? current : next,
          );
          final overallAccuracy =
              totalAttempts == 0 ? 0.0 : (totalCorrect / totalAttempts) * 100;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Scrollbar(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  MascotStateCard(
                    imageAsset: MascotAssets.applause,
                    title: 'Resumen de ${widget.session.name}',
                    message:
                        'Tu avance ya muestra fortalezas y temas por reforzar. Usa esta vista para decidir que practicar despues.',
                    tone: MascotTone.success,
                    centered: false,
                    imageSize: 128,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(
                          label: 'Precision global',
                          value: '${overallAccuracy.toStringAsFixed(1)}%',
                        ),
                        _SummaryChip(
                          label: 'Mejor tema',
                          value: bestTopic.topicName,
                        ),
                        _SummaryChip(
                          label: 'Tema a reforzar',
                          value: focusTopic.topicName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final topic in topics) ...[
                    _ProgressTile(topic: topic),
                    const SizedBox(height: 16),
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

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.topic,
  });

  final ProgressTopic topic;

  @override
  Widget build(BuildContext context) {
    final progressValue = topic.accuracyPercentage.clamp(0, 100) / 100;

    return HoverLift(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.topicName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text('Nivel actual: ${topic.currentLevel}'),
              Text('Aciertos: ${topic.totalCorrect}/${topic.totalAttempts}'),
              Text('Precision: ${topic.accuracyPercentage.toStringAsFixed(2)}%'),
              Text('Racha: ${topic.streakDays} dias'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
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
