class Routine {
  static const String tableName = 'routines';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnNotes = 'notes';

  final String id;
  final String name;
  final String? notes;

  Routine({required this.id, required this.name, this.notes});

  Map<String, dynamic> toMap() => {
    columnId: id,
    columnName: name,
    columnNotes: notes,
  };

  factory Routine.fromMap(Map<String, dynamic> map) => Routine(
    id: map[columnId] as String,
    name: map[columnName] as String,
    notes: map[columnNotes] as String?,
  );
}
