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
  Future<PracticeSessionData> startPractice(String token, int topicId, int level);
  Future<PracticeAnswerResult> submitPracticeAnswer(
    String token,
    PracticeAnswerSubmission submission,
  );
  Future<List<ProgressTopic>> getProgress(String token);
}

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
  Future<PracticeSessionData> startPractice(String token, int topicId, int level) async {
    final response = await _get(
      '/practice/questions?topicId=$topicId&level=$level',
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

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
    return _decodeObject(response);
  }

  Future<List<dynamic>> _getList(String path, {String? token}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    String? token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decodeObject(response);
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
      throw ApiException(message);
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
      throw ApiException(message);
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
  const ApiException(this.message);

  final String message;

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

class PracticeSessionData {
  const PracticeSessionData({
    required this.sessionId,
    required this.topicId,
    required this.topicName,
    required this.difficultyLevel,
    required this.questions,
  });

  final String sessionId;
  final int topicId;
  final String topicName;
  final int difficultyLevel;
  final List<PracticeQuestion> questions;

  factory PracticeSessionData.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'] as List<dynamic>;
    return PracticeSessionData(
      sessionId: json['sessionId'] as String,
      topicId: json['topicId'] as int,
      topicName: json['topicName'] as String,
      difficultyLevel: json['difficultyLevel'] as int,
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
    this.explanation,
  });

  final bool correct;
  final String correctOption;
  final String? explanation;
  final int sessionCorrectCount;
  final int sessionTotalCount;
  final int currentLevel;
  final int streakDays;
  final bool sessionCompleted;

  factory PracticeAnswerResult.fromJson(Map<String, dynamic> json) {
    return PracticeAnswerResult(
      correct: json['correct'] as bool,
      correctOption: json['correctOption'] as String,
      explanation: json['explanation'] as String?,
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
