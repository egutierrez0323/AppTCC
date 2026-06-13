import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/educoach_api.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/session_storage.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final sessionStorage = SessionStorage(preferences);
  final session = await sessionStorage.read();

  runApp(EduCoachApp(
    api: HttpEduCoachApi(baseUrl: AppConfig.apiBaseUrl),
    sessionStorage: sessionStorage,
    initialSession: session,
  ));
}

class EduCoachApp extends StatefulWidget {
  const EduCoachApp({
    super.key,
    required this.api,
    required this.sessionStorage,
    required this.initialSession,
  });

  final EduCoachApi api;
  final SessionStorage sessionStorage;
  final AuthSession? initialSession;

  @override
  State<EduCoachApp> createState() => _EduCoachAppState();
}

class _EduCoachAppState extends State<EduCoachApp> {
  late AuthSession? _session = widget.initialSession;

  Future<void> _login(String email, String password) async {
    final session = await widget.api.login(email, password);
    await widget.sessionStorage.save(session);
    setState(() => _session = session);
  }

  Future<void> _register(String name, String email, String password) async {
    final session = await widget.api.register(name, email, password);
    await widget.sessionStorage.save(session);
    setState(() => _session = session);
  }

  Future<void> _signOut() async {
    await widget.sessionStorage.clear();
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduCoach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: _session == null
          ? LoginScreen(
              onLogin: _login,
              onRegister: _register,
            )
          : HomeScreen(
              api: widget.api,
              session: _session!,
              onLogout: _signOut,
            ),
    );
  }
}
