import 'dart:convert';

enum BlockMode { now, limit, schedule }

class BlockSession {
  final String id;
  final BlockMode mode;
  final List<String> appNames;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes; // 0 = unlimited
  final bool strictMode;
  final bool completed; // 時間完走したか

  const BlockSession({
    required this.id,
    required this.mode,
    required this.appNames,
    required this.startedAt,
    this.endedAt,
    required this.durationMinutes,
    this.strictMode = false,
    this.completed = false,
  });

  int get elapsedSeconds {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt).inSeconds;
  }

  bool get isActive => endedAt == null;

  BlockSession copyWith({
    DateTime? endedAt,
    bool? completed,
  }) {
    return BlockSession(
      id: id,
      mode: mode,
      appNames: appNames,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes,
      strictMode: strictMode,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode.name,
    'appNames': appNames,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'durationMinutes': durationMinutes,
    'strictMode': strictMode,
    'completed': completed,
  };

  factory BlockSession.fromJson(Map<String, dynamic> json) => BlockSession(
    id: json['id'] as String,
    mode: BlockMode.values.byName(json['mode'] as String),
    appNames: List<String>.from(json['appNames'] as List),
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
    durationMinutes: json['durationMinutes'] as int,
    strictMode: json['strictMode'] as bool? ?? false,
    completed: json['completed'] as bool? ?? false,
  );

  static String encodeList(List<BlockSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());

  static List<BlockSession> decodeList(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => BlockSession.fromJson(e as Map<String, dynamic>)).toList();
  }
}
