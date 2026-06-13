import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../auth/session_storage.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.api,
    required this.session,
  });

  final EduCoachApi api;
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: FutureBuilder<List<ProgressTopic>>(
        future: api.getProgress(session.token),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final topics = snapshot.data ?? const <ProgressTopic>[];
          if (topics.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aun no hay progreso registrado. Realiza el diagnostico o una practica primero.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Resumen de ${session.name}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              for (final topic in topics) ...[
                _ProgressTile(topic: topic),
                const SizedBox(height: 16),
              ],
            ],
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

    return Card(
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
    );
  }
}
