import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../auth/session_storage.dart';
import 'practice_session_detail_screen.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onUnauthorized,
  });

  final EduCoachApi api;
  final AuthSession session;
  final Future<void> Function() onUnauthorized;

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  late Future<List<PracticeSessionSummary>> _future = _load();

  Future<List<PracticeSessionSummary>> _load() async {
    return widget.api.getPracticeHistory(widget.session.token, limit: 30);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de practicas')),
      body: FutureBuilder<List<PracticeSessionSummary>>(
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

          final sessions = snapshot.data ?? const <PracticeSessionSummary>[];
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aun no hay sesiones registradas. Realiza una practica primero.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final total = session.totalCount == 0 ? 1 : session.totalCount;
                final accuracy = (session.correctCount / total) * 100;

                return Card(
                  child: ListTile(
                    title: Text('${session.topicName} · Nivel ${session.difficultyLevel}'),
                    subtitle: Text(
                      'Aciertos: ${session.correctCount}/${session.totalCount} · ${accuracy.toStringAsFixed(0)}%',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PracticeSessionDetailScreen(
                            api: widget.api,
                            session: widget.session,
                            sessionId: session.sessionId,
                            onUnauthorized: widget.onUnauthorized,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
