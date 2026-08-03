import 'package:flutter/foundation.dart';

class StoryPage {
  final String imageUrl;
  final String textEn;
  final String textMs;

  StoryPage({required this.imageUrl, required this.textEn, this.textMs = ''});

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
      imageUrl: json['imageUrl']?.toString() ?? '',
      textEn: json['textEn']?.toString() ?? '',
      textMs: json['textMs']?.toString() ?? '');

  Map<String, dynamic> toJson() =>
      {'imageUrl': imageUrl, 'textEn': textEn, 'textMs': textMs};
}

class StoryQuizQuestion {
  final String questionMs;
  final List<String> answersMs;
  final int correct;
  final String? qImage;
  final String? hintMs;

  StoryQuizQuestion({
    required this.questionMs,
    required this.answersMs,
    required this.correct,
    this.qImage,
    this.hintMs,
  });

  factory StoryQuizQuestion.fromMap(Map<String, dynamic> map) {
    return StoryQuizQuestion(
      questionMs: map['questionMs']?.toString() ?? '',
      answersMs:
          map['answersMs'] != null ? List<String>.from(map['answersMs']) : [],
      correct: int.tryParse(map['correct']?.toString() ?? '0') ?? 0,
      qImage: map['qImage']?.toString(),
      hintMs: map['hintMs']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionMs': questionMs,
      'answersMs': answersMs,
      'correct': correct,
      'qImage': qImage,
      'hintMs': hintMs,
    };
  }
}

class Story {
  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final List<StoryPage> pages;
  final List<String> tags;
  final int estimatedReadingTime;
  final int orderIndex;
  final List<StoryQuizQuestion> quizQuestions;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.pages,
    this.tags = const [],
    this.estimatedReadingTime = 5,
    this.orderIndex = 0,
    this.quizQuestions = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json, String documentId) {
    var pagesList = json['pages'] as List? ?? [];
    List<StoryPage> parsedPages = pagesList
        .map((p) => StoryPage.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();

    List<StoryQuizQuestion> parsedQuizzes = [];
    if (json['quizQuestions'] != null) {
      try {
        final Iterable rawItems = json['quizQuestions'] as Iterable;
        parsedQuizzes = rawItems.map((item) {
          final Map<String, dynamic> safeMap =
              Map<String, dynamic>.from(item as Map);
          return StoryQuizQuestion.fromMap(safeMap);
        }).toList();
      } catch (e) {
        debugPrint("Error parsing quiz questions for story $documentId: $e");
        parsedQuizzes = [];
      }
    }

    return Story(
      id: documentId,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coverImageUrl: json['coverImageUrl']?.toString() ?? '',
      pages: parsedPages,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      estimatedReadingTime:
          int.tryParse(json['estimatedReadingTime']?.toString() ?? '5') ?? 5,
      orderIndex: int.tryParse(json['orderIndex']?.toString() ?? '0') ?? 0,
      quizQuestions: parsedQuizzes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'estimatedReadingTime': estimatedReadingTime,
      'orderIndex': orderIndex,
      'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
      'pages': pages.map((p) => p.toJson()).toList(),
    };
  }
}
