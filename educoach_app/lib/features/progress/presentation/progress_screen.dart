import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../auth/session_storage.dart';

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
              message: error.toString(),
              onRetry: _refresh,
            );
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

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Resumen de ${widget.session.name}',
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
