import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@module
abstract class UuidModule {
  @lazySingleton
  Uuid get uuid => const Uuid();
}