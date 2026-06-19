import 'package:flutter/material.dart';

import '../../../core/api/educoach_api.dart';
import '../../../core/widgets/app_motion.dart';
import '../../../core/widgets/mascot_assets.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth >= 920;
          final cardWidth = useTwoColumns ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

          return Scrollbar(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AppEntrance(
                  child: _WelcomeHeroCard(
                    name: session.name,
                    email: session.email,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: AppEntrance(
                        delay: const Duration(milliseconds: 40),
                        child: _FeatureCard(
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
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: AppEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: _FeatureCard(
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
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: AppEntrance(
                        delay: const Duration(milliseconds: 120),
                        child: _FeatureCard(
                          title: 'Practica recomendada',
                          subtitle: 'Retoma el tema con menor precision para reforzarlo.',
                          icon: Icons.auto_awesome_outlined,
                          actionLabel: 'Empezar',
                          onTap: () async {
                            try {
                              final recommendation =
                                  await api.getPracticeRecommendation(session.token);
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
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: AppEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: _FeatureCard(
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
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: AppEntrance(
                        delay: const Duration(milliseconds: 200),
                        child: _FeatureCard(
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

class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 600;
              final info = Column(
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
                      'Listo para aprender',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Hola, $name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF12243A),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Continua practicando, revisa tu progreso o retoma el tema donde mas apoyo necesitas.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF425466),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroPill(label: 'Email activo', value: email),
                      const _HeroPill(label: 'Meta', value: 'Practicar hoy'),
                    ],
                  ),
                ],
              );

              final mascot = RepaintBoundary(
                child: Image.asset(
                  MascotAssets.wink,
                  height: stacked ? 140 : 160,
                  fit: BoxFit.contain,
                  cacheWidth: stacked ? 280 : 320,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.calculate_rounded,
                      size: stacked ? 96 : 108,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: mascot),
                    const SizedBox(height: 16),
                    info,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 16),
                  mascot,
                ],
              );
            },
          ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5B6B7D),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF12243A),
                ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF556476),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 18),
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
