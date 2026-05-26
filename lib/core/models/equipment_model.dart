import 'package:equatable/equatable.dart';

class Equipment extends Equatable {
  static const String tableName = 'equipments';
  static const String columnId = 'id';
  static const String columnName = 'name';

  final String id;
  final String name;

  const Equipment({required this.id, required this.name});

  Map<String, dynamic> toMap() => {columnId: id, columnName: name};

  factory Equipment.fromMap(Map<String, dynamic> map) =>
      Equipment(
        id: map[columnId] as String,
        name: map[columnName] as String,
      );

  factory Equipment.fromJson(Map<String, dynamic> json) =>
      Equipment(
        id: json[columnId] as String,
        name: json[columnName] as String,
      );

  @override
  List<Object?> get props => [id, name];
}
