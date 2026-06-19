import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/session_storage.dart';

abstract class EduCoachApi {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> register(String name, String email, String password);
  Future<List<DiagnosticQuestion>> getDiagnosticQuestions(String token);
  Future<List<DiagnosticTopicResult>> submitDiagnostic(
    String token,
    List<DiagnosticAnswer> answers,
  );
  Future<PracticeSessionData> startPractice(
    String token,
    int topicId,
    int level, {
    String mode = PracticeMode.normal,
  });
  Future<PracticeAnswerResult> submitPracticeAnswer(
    String token,
    PracticeAnswerSubmission submission,
  );
  Future<List<ProgressTopic>> getProgress(String token);
  Future<List<PracticeSessionSummary>> getPracticeHistory(String token, {int limit = 20});
  Future<PracticeSessionDetail> getPracticeSessionDetail(String token, String sessionId);
  Future<PracticeRecommendation> getPracticeRecommendation(String token);
}

const Duration _requestTimeout = Duration(seconds: 45);
const String _timeoutMessage =
    'El servidor tardó demasiado en responder. Si estaba inactivo, espera unos segundos y vuelve a intentar.';

class HttpEduCoachApi implements EduCoachApi {
  HttpEduCoachApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AuthSession> login(String email, String password) async {
    final response = await _post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return _parseSession(response);
  }

  @override
  Future<AuthSession> register(String name, String email, String password) async {
    final response = await _post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return _parseSession(response);
  }

  @override
  Future<List<DiagnosticQuestion>> getDiagnosticQuestions(String token) async {
    final response = await _getList('/diagnostic/questions', token: token);
    return response
        .map((item) => DiagnosticQuestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DiagnosticTopicResult>> submitDiagnostic(
    String token,
    List<DiagnosticAnswer> answers,
  ) async {
    final response = await _post(
      '/diagnostic/submit',
      token: token,
      body: {
        'answers': answers.map((item) => item.toJson()).toList(),
      },
    );

    final results = response['results'] as List<dynamic>;
    return results
        .map((item) => DiagnosticTopicResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PracticeSessionData> startPractice(
    String token,
    int topicId,
    int level, {
    String mode = PracticeMode.normal,
  }) async {
    final response = await _get(
      '/practice/questions?topicId=$topicId&level=$level&mode=${Uri.encodeQueryComponent(mode)}',
      token: token,
    );
    return PracticeSessionData.fromJson(response);
  }

  @override
  Future<PracticeAnswerResult> submitPracticeAnswer(
    String token,
    PracticeAnswerSubmission submission,
  ) async {
    final response = await _post(
      '/practice/answer',
      token: token,
      body: submission.toJson(),
    );
    return PracticeAnswerResult.fromJson(response);
  }

  @override
  Future<List<ProgressTopic>> getProgress(String token) async {
    final response = await _get('/progress', token: token);
    final topics = response['topics'] as List<dynamic>;
    return topics
        .map((item) => ProgressTopic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PracticeSessionSummary>> getPracticeHistory(String token, {int limit = 20}) async {
    final response = await _get('/practice/history?limit=$limit', token: token);
    final sessions = response['sessions'] as List<dynamic>;
    return sessions
        .map((item) => PracticeSessionSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PracticeSessionDetail> getPracticeSessionDetail(String token, String sessionId) async {
    final response = await _get('/practice/sessions/$sessionId', token: token);
    return PracticeSessionDetail.fromJson(response);
  }

  @override
  Future<PracticeRecommendation> getPracticeRecommendation(String token) async {
    final response = await _get('/practice/recommendation', token: token);
    return PracticeRecommendation.fromJson(response);
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .get(
            uri,
            headers: _headers(token),
          )
          .timeout(_requestTimeout);
      return _decodeObject(response);
    } on TimeoutException {
      throw const ApiException(_timeoutMessage);
    } catch (_) {
      throw const ApiException('No se pudo conectar al servidor. Verifica tu conexion.');
    }
  }

  Future<List<dynamic>> _getList(String path, {String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .get(
            uri,
            headers: _headers(token),
          )
          .timeout(_requestTimeout);
      return _decodeList(response);
    } on TimeoutException {
      throw const ApiException(_timeoutMessage);
    } catch (_) {
      throw const ApiException('No se pudo conectar al servidor. Verifica tu conexion.');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    String? token,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      return _decodeObject(response);
    } on TimeoutException {
      throw const ApiException(_timeoutMessage);
    } catch (_) {
      throw const ApiException('No se pudo conectar al servidor. Verifica tu conexion.');
    }
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final dynamic body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = body is Map<String, dynamic>
          ? (body['message'] as String? ?? 'Ocurrio un error al procesar la solicitud.')
          : 'Ocurrio un error al procesar la solicitud.';
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (body is Map<String, dynamic>) {
      return body;
    }

    if (body is List<dynamic>) {
      return {'items': body};
    }

    throw const ApiException('La respuesta del servidor no tiene el formato esperado.');
  }

  List<dynamic> _decodeList(http.Response response) {
    final dynamic body = response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = body is Map<String, dynamic>
          ? (body['message'] as String? ?? 'Ocurrio un error al procesar la solicitud.')
          : 'Ocurrio un error al procesar la solicitud.';
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (body is List<dynamic>) {
      return body;
    }

    throw const ApiException('La respuesta del servidor no tiene el formato esperado.');
  }

  AuthSession _parseSession(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      name: user['name'] as String,
      email: user['email'] as String,
      token: json['token'] as String,
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class DiagnosticQuestion {
  const DiagnosticQuestion({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.difficultyLevel,
    required this.statement,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.hint,
  });

  final String id;
  final int topicId;
  final String topicName;
  final int difficultyLevel;
  final String statement;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? hint;

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) {
    return DiagnosticQuestion(
      id: json['id'] as String,
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
      statement: json['statement'] as String,
      optionA: json['optionA'] as String,
      optionB: json['optionB'] as String,
      optionC: json['optionC'] as String,
      optionD: json['optionD'] as String,
      hint: json['hint'] as String?,
    );
  }
}

class DiagnosticAnswer {
  const DiagnosticAnswer({
    required this.questionId,
    required this.selectedOption,
  });

  final String questionId;
  final String selectedOption;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption,
    };
  }
}

class DiagnosticTopicResult {
  const DiagnosticTopicResult({
    required this.topicId,
    required this.topicName,
    required this.score,
    required this.totalQuestions,
    required this.assignedLevel,
  });

  final int topicId;
  final String topicName;
  final int score;
  final int totalQuestions;
  final int assignedLevel;

  factory DiagnosticTopicResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticTopicResult(
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      assignedLevel: json['assignedLevel'] as int,
    );
  }
}

abstract final class PracticeMode {
  static const normal = 'normal';
  static const review = 'review';
  static const mixed = 'mixed';
}

class PracticeSessionData {
  const PracticeSessionData({
    required this.sessionId,
    required this.topicId,
    required this.topicName,
    required this.difficultyLevel,
    required this.mode,
    this.modeMessage,
    required this.questions,
  });

  final String sessionId;
  final int topicId;
  final String topicName;
  final int difficultyLevel;
  final String mode;
  final String? modeMessage;
  final List<PracticeQuestion> questions;

  factory PracticeSessionData.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'] as List<dynamic>;
    return PracticeSessionData(
      sessionId: json['sessionId'] as String,
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
      mode: json['mode'] as String? ?? PracticeMode.normal,
      modeMessage: json['modeMessage'] as String?,
      questions: questions
          .map((item) => PracticeQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.statement,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.hint,
  });

  final String id;
  final String statement;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? hint;

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    return PracticeQuestion(
      id: json['id'] as String,
      statement: json['statement'] as String,
      optionA: json['optionA'] as String,
      optionB: json['optionB'] as String,
      optionC: json['optionC'] as String,
      optionD: json['optionD'] as String,
      hint: json['hint'] as String?,
    );
  }
}

class PracticeAnswerSubmission {
  const PracticeAnswerSubmission({
    required this.sessionId,
    required this.questionId,
    required this.selectedOption,
    required this.responseTimeSeconds,
  });

  final String sessionId;
  final String questionId;
  final String selectedOption;
  final int responseTimeSeconds;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'questionId': questionId,
      'selectedOption': selectedOption,
      'responseTimeSeconds': responseTimeSeconds,
    };
  }
}

class PracticeAnswerResult {
  const PracticeAnswerResult({
    required this.correct,
    required this.correctOption,
    required this.sessionCorrectCount,
    required this.sessionTotalCount,
    required this.currentLevel,
    required this.streakDays,
    required this.sessionCompleted,
    this.explanationRaw,
    this.explanation,
  });

  final bool correct;
  final String correctOption;
  final String? explanationRaw;
  final AiMathExplanation? explanation;
  final int sessionCorrectCount;
  final int sessionTotalCount;
  final int currentLevel;
  final int streakDays;
  final bool sessionCompleted;

  factory PracticeAnswerResult.fromJson(Map<String, dynamic> json) {
    final explanationRaw = json['explanation'] as String?;
    return PracticeAnswerResult(
      correct: json['correct'] as bool,
      correctOption: json['correctOption'] as String,
      explanationRaw: explanationRaw,
      explanation: AiMathExplanation.tryParse(explanationRaw),
      sessionCorrectCount: json['sessionCorrectCount'] as int,
      sessionTotalCount: json['sessionTotalCount'] as int,
      currentLevel: json['currentLevel'] as int,
      streakDays: json['streakDays'] as int,
      sessionCompleted: json['sessionCompleted'] as bool,
    );
  }
}

class ProgressTopic {
  const ProgressTopic({
    required this.topicId,
    required this.topicName,
    required this.currentLevel,
    required this.totalCorrect,
    required this.totalAttempts,
    required this.accuracyPercentage,
    required this.streakDays,
  });

  final int topicId;
  final String topicName;
  final int currentLevel;
  final int totalCorrect;
  final int totalAttempts;
  final double accuracyPercentage;
  final int streakDays;

  factory ProgressTopic.fromJson(Map<String, dynamic> json) {
    return ProgressTopic(
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      currentLevel: json['currentLevel'] as int,
      totalCorrect: json['totalCorrect'] as int,
      totalAttempts: json['totalAttempts'] as int,
      accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
    );
  }
}

class PracticeSessionSummary {
  const PracticeSessionSummary({
    required this.sessionId,
    required this.topicId,
    required this.topicName,
    required this.difficultyLevel,
    required this.correctCount,
    required this.totalCount,
    required this.startedAtUtc,
    this.endedAtUtc,
  });

  final String sessionId;
  final int topicId;
  final String topicName;
  final int difficultyLevel;
  final int correctCount;
  final int totalCount;
  final DateTime startedAtUtc;
  final DateTime? endedAtUtc;

  factory PracticeSessionSummary.fromJson(Map<String, dynamic> json) {
    return PracticeSessionSummary(
      sessionId: json['sessionId'] as String,
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
      correctCount: json['correctCount'] as int,
      totalCount: json['totalCount'] as int,
      startedAtUtc: DateTime.parse(json['startedAtUtc'] as String),
      endedAtUtc: json['endedAtUtc'] == null ? null : DateTime.parse(json['endedAtUtc'] as String),
    );
  }
}

class PracticeSessionDetail {
  const PracticeSessionDetail({
    required this.sessionId,
    required this.topicId,
    required this.topicName,
    required this.difficultyLevel,
    required this.correctCount,
    required this.totalCount,
    required this.startedAtUtc,
    this.endedAtUtc,
    required this.answers,
  });

  final String sessionId;
  final int topicId;
  final String topicName;
  final int difficultyLevel;
  final int correctCount;
  final int totalCount;
  final DateTime startedAtUtc;
  final DateTime? endedAtUtc;
  final List<PracticeSessionAnswer> answers;

  factory PracticeSessionDetail.fromJson(Map<String, dynamic> json) {
    final answers = json['answers'] as List<dynamic>? ?? const <dynamic>[];
    return PracticeSessionDetail(
      sessionId: json['sessionId'] as String,
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
      correctCount: json['correctCount'] as int,
      totalCount: json['totalCount'] as int,
      startedAtUtc: DateTime.parse(json['startedAtUtc'] as String),
      endedAtUtc: json['endedAtUtc'] == null ? null : DateTime.parse(json['endedAtUtc'] as String),
      answers: answers
          .map((item) => PracticeSessionAnswer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PracticeSessionAnswer {
  const PracticeSessionAnswer({
    required this.questionId,
    required this.statement,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
    this.aiExplanationRaw,
    this.aiExplanation,
    required this.answeredAtUtc,
  });

  final String questionId;
  final String statement;
  final String selectedOption;
  final String correctOption;
  final bool isCorrect;
  final String? aiExplanationRaw;
  final AiMathExplanation? aiExplanation;
  final DateTime answeredAtUtc;

  factory PracticeSessionAnswer.fromJson(Map<String, dynamic> json) {
    final aiExplanationRaw = json['aiExplanation'] as String?;
    return PracticeSessionAnswer(
      questionId: json['questionId'] as String,
      statement: json['statement'] as String,
      selectedOption: json['selectedOption'] as String,
      correctOption: json['correctOption'] as String,
      isCorrect: json['isCorrect'] as bool,
      aiExplanationRaw: aiExplanationRaw,
      aiExplanation: AiMathExplanation.tryParse(aiExplanationRaw),
      answeredAtUtc: DateTime.parse(json['answeredAtUtc'] as String),
    );
  }
}

class AiMathExplanation {
  const AiMathExplanation({
    required this.summary,
    required this.steps,
    required this.finalAnswerText,
    required this.encouragement,
  });

  final String summary;
  final List<AiMathExplanationStep> steps;
  final String finalAnswerText;
  final String encouragement;

  static AiMathExplanation? tryParse(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return AiMathExplanation.fromJson(decoded);
        }
      } catch (_) {
        // Legacy or malformed payloads fall back to plain text rendering.
      }
    }

    return AiMathExplanation(
      summary: trimmed,
      steps: const [],
      finalAnswerText: '',
      encouragement: '',
    );
  }

  factory AiMathExplanation.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] as List<dynamic>? ?? const <dynamic>[];
    return AiMathExplanation(
      summary: (json['summary'] as String? ?? '').trim(),
      steps: steps
          .map((item) => AiMathExplanationStep.fromJson(item as Map<String, dynamic>))
          .where((item) => item.title.isNotEmpty && item.text.isNotEmpty)
          .toList(),
      finalAnswerText: (json['finalAnswerText'] as String? ?? '').trim(),
      encouragement: (json['encouragement'] as String? ?? '').trim(),
    );
  }
}

class AiMathExplanationStep {
  const AiMathExplanationStep({
    required this.title,
    required this.text,
    required this.formulaLatex,
  });

  final String title;
  final String text;
  final String formulaLatex;

  factory AiMathExplanationStep.fromJson(Map<String, dynamic> json) {
    return AiMathExplanationStep(
      title: (json['title'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      formulaLatex: (json['formulaLatex'] as String? ?? '').trim(),
    );
  }
}

class PracticeRecommendation {
  const PracticeRecommendation({
    required this.topicId,
    required this.topicName,
    required this.recommendedLevel,
  });

  final int topicId;
  final String topicName;
  final int recommendedLevel;

  factory PracticeRecommendation.fromJson(Map<String, dynamic> json) {
    return PracticeRecommendation(
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      recommendedLevel: json['recommendedLevel'] as int,
    );
  }
}
