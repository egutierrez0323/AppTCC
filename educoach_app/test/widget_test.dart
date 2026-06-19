import 'package:educoach_app/core/api/educoach_api.dart';
import 'package:educoach_app/features/auth/session_storage.dart';
import 'package:educoach_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('muestra el login inicial', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(EduCoachApp(
      api: FakeEduCoachApi(),
      sessionStorage: SessionStorage(preferences),
      initialSession: null,
    ));

    await tester.pumpAndSettle();

    expect(find.text('EduCoach'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}

class FakeEduCoachApi implements EduCoachApi {
  @override
  Future<List<DiagnosticQuestion>> getDiagnosticQuestions(String token) async => [];

  @override
  Future<List<PracticeTopic>> getTopics(String token) async => [];

  @override
  Future<List<ProgressTopic>> getProgress(String token) async => [];

  @override
  Future<AuthSession> login(String email, String password) async => const AuthSession(
        name: 'Demo',
        email: 'demo@educoach.dev',
        token: 'token',
      );

  @override
  Future<AuthSession> register(String name, String email, String password) async =>
      AuthSession(name: name, email: email, token: 'token');

  @override
  Future<List<DiagnosticTopicResult>> submitDiagnostic(
    String token,
    List<DiagnosticAnswer> answers,
  ) async =>
      [];

  @override
  Future<PracticeSessionData> startPractice(
    String token,
    int topicId,
    int level, {
    String mode = PracticeMode.normal,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PracticeAnswerResult> submitPracticeAnswer(
    String token,
    PracticeAnswerSubmission submission,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PracticeSessionSummary>> getPracticeHistory(
    String token, {
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PracticeSessionDetail> getPracticeSessionDetail(
    String token,
    String sessionId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PracticeRecommendation> getPracticeRecommendation(String token) {
    throw UnimplementedError();
  }
}
