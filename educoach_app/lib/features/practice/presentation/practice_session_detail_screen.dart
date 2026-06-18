import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${detail.topicName} · Nivel ${detail.difficultyLevel}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aciertos: ${detail.correctCount}/${detail.totalCount}'),
                        Text('Respuestas: ${detail.answers.length}'),
                      ],
                    ),
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
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay errores en esta sesion.'),
                    ),
                  )
                else
                  for (final answer in incorrect) ...[
                    Card(
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
                            if ((answer.aiExplanation ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(answer.aiExplanation!.trim()),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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

