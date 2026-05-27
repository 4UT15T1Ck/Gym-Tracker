import 'package:equatable/equatable.dart';

class Muscle extends Equatable {
  static const String tableName = 'muscles';
  static const String columnId = 'id';
  static const String columnName = 'name';

  final String id;
  final String name;

  const Muscle({required this.id, required this.name});

  Map<String, dynamic> toMap() => {columnId: id, columnName: name};

  factory Muscle.fromMap(Map<String, dynamic> map) =>
      Muscle(id: map[columnId] as String, name: map[columnName] as String);

  factory Muscle.fromJson(Map<String, dynamic> json) =>
      Muscle(id: json[columnId] as String, name: json[columnName] as String);

  @override
  List<Object?> get props => [id, name];
}
