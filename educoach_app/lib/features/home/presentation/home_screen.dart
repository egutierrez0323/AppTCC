import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../auth/session_storage.dart';
import '../../diagnostic/presentation/diagnostic_screen.dart';
import '../../practice/presentation/practice_history_screen.dart';
import '../../practice/presentation/practice_screen.dart';
import '../../progress/presentation/progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final EduCoachApi api;
  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    Future<void> handleUnauthorized() async {
      await onLogout();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduCoach'),
        actions: [
          IconButton(
            onPressed: () async {
              await onLogout();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${session.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('Email activo: ${session.email}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Diagnostico',
            subtitle: 'Realiza la prueba inicial y asigna nivel por tema.',
            icon: Icons.quiz_outlined,
            actionLabel: 'Iniciar diagnostico',
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiagnosticScreen(
                    api: api,
                    session: session,
                    onUnauthorized: handleUnauthorized,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Practica personalizada',
            subtitle: 'Responde ejercicios por tema y nivel.',
            icon: Icons.edit_note_outlined,
            actionLabel: 'Practicar',
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PracticeScreen(
                    api: api,
                    session: session,
                    onUnauthorized: handleUnauthorized,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Practica recomendada',
            subtitle: 'Retoma el tema con menor precision para reforzarlo.',
            icon: Icons.auto_awesome_outlined,
            actionLabel: 'Empezar',
            onTap: () async {
              try {
                final recommendation = await api.getPracticeRecommendation(session.token);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PracticeScreen(
                      api: api,
                      session: session,
                      onUnauthorized: handleUnauthorized,
                      initialTopicId: recommendation.topicId,
                      initialLevel: recommendation.recommendedLevel,
                    ),
                  ),
                );
              } catch (e) {
                if (e is ApiException && e.statusCode == 401) {
                  await handleUnauthorized();
                  return;
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Historial de practicas',
            subtitle: 'Revisa tus sesiones anteriores y errores cometidos.',
            icon: Icons.history_outlined,
            actionLabel: 'Ver historial',
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PracticeHistoryScreen(
                    api: api,
                    session: session,
                    onUnauthorized: handleUnauthorized,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'Progreso',
            subtitle: 'Visualiza nivel, aciertos y racha actual.',
            icon: Icons.bar_chart_outlined,
            actionLabel: 'Ver progreso',
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProgressScreen(
                    api: api,
                    session: session,
                    onUnauthorized: handleUnauthorized,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async => onTap(),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
