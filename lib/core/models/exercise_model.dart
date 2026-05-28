import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';

class Exercise extends Equatable {
  static const String tableName = 'exercises';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnTrackingType = 'tracking_type';
  static const String columnShortDescription = 'short_description';
  static const String columnInstructions = 'instructions';
  static const String columnPrimaryMuscleId = 'primary_muscle_id';
  static const String columnEquipmentId = 'equipment_id';
  static const String columnImageUrl = 'image_url';
  static const String columnVideoUrl = 'video_url';

  final String id;
  final String name;
  final ExerciseTrackingType trackingType;
  final String? shortDescription;
  final List<String> instructions;
  final String primaryMuscleId;
  final String? equipmentId;
  final String? imageUrl;
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.trackingType,
    this.shortDescription,
    this.instructions = const [],
    required this.primaryMuscleId,
    this.equipmentId,
    this.imageUrl,
    this.videoUrl,
  });

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnName: name,
    columnTrackingType: trackingType.dbValue,
    columnShortDescription: shortDescription,
    columnInstructions: jsonEncode(instructions),
    columnPrimaryMuscleId: primaryMuscleId,
    columnEquipmentId: equipmentId,
    columnImageUrl: imageUrl,
    columnVideoUrl: videoUrl,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map[columnId] as String,
    name: map[columnName] as String,
    trackingType: trackingTypeFromDbValue(map[columnTrackingType] as String?),
    shortDescription: map[columnShortDescription] as String?,
    instructions: _parseInstructions(map[columnInstructions]),
    primaryMuscleId: map[columnPrimaryMuscleId] as String,
    equipmentId: map[columnEquipmentId] as String?,
    imageUrl: map[columnImageUrl] as String?,
    videoUrl: map[columnVideoUrl] as String?,
  );

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json[columnId] as String,
    name: json[columnName] as String,
    trackingType: trackingTypeFromDbValue(json[columnTrackingType] as String?),
    shortDescription: json[columnShortDescription] as String?,
    instructions: _parseInstructions(json[columnInstructions]),
    primaryMuscleId: json[columnPrimaryMuscleId] as String,
    equipmentId: json[columnEquipmentId] as String?,
    imageUrl: json[columnImageUrl] as String?,
    videoUrl: json[columnVideoUrl] as String?,
  );

  static List<String> _parseInstructions(dynamic rawValue) {
    if (rawValue == null) {
      return const [];
    }

    if (rawValue is List) {
      return rawValue.map((item) => item.toString()).toList(growable: false);
    }

    if (rawValue is String && rawValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList(growable: false);
        }
      } on FormatException {
        return const [];
      }
    }

    return const [];
  }

  @override
  List<Object?> get props => [
        id,
        name,
        trackingType,
        shortDescription,
        instructions,
        primaryMuscleId,
        equipmentId,
        imageUrl,
        videoUrl,
      ];
}
