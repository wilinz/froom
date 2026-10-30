import 'package:build/build.dart';
import 'package:froom_generator/generator.dart';
import 'package:source_gen/source_gen.dart';

/// This triggers the code generation process.
///
/// Use 'flutter packages pub run build_runner build' to start code generation.
///
/// Use 'flutter packages pub run build_runner watch' to trigger
/// code generation on changes.
/// The schemas of the databases are exported to the directory configured by
/// the `schema_location` option, `froom_schemas` by default.
Builder froomBuilder(final BuilderOptions options) {
  final schemaLocation = options.config['schema_location'] as String?;
  final froom = schemaLocation == null
      ? FroomGenerator()
      : FroomGenerator(schemaLocation: schemaLocation);
  print(froom.hashCode); // enable debug
  return SharedPartBuilder([froom], 'froom');
}
