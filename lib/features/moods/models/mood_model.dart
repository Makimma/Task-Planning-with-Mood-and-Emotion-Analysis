import 'package:equatable/equatable.dart';

class MoodModel extends Equatable {
  final String type;

  final String? note;

  final DateTime timestamp;

  final bool synced;

  const MoodModel({
    required this.type,
    this.note,
    required this.timestamp,
    this.synced = false,
  });

  MoodModel copyWith({
    String? type,
    String? note,
    DateTime? timestamp,
    bool? synced,
  }) {
    return MoodModel(
      type: type ?? this.type,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    return MoodModel(
      type: json['type'] as String,
      note: json['note'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (note != null) 'note': note,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
    };
  }

  @override
  List<Object?> get props => [type, note, timestamp, synced];
}
