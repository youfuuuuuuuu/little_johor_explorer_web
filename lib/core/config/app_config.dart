import 'dart:convert';

class AppConfig {
  static final List<int> _scrambledKeyBytes = [
    65,
    81,
    46,
    65,
    98,
    56,
    82,
    78,
    54,
    73,
    88,
    80,
    49,
    110,
    95,
    100,
    116,
    84,
    103,
    69,
    55,
    89,
    78,
    56,
    76,
    100,
    68,
    113,
    66,
    54,
    56,
    67,
    52,
    106,
    105,
    120,
    108,
    53,
    50,
    112,
    99,
    121,
    105,
    112,
    73,
    99,
    88,
    45,
    118,
    101,
    105,
    70,
    81
  ];

  static String get geminiApiKey {
    if (_scrambledKeyBytes.isEmpty) return '';
    return utf8.decode(_scrambledKeyBytes);
  }
}
