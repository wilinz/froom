import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
class QueryableProcessorError {
  final ClassElement _classElement;

  QueryableProcessorError(final ClassElement classElement)
      : _classElement = classElement;

  InvalidGenerationSourceError get missingUnnamedConstructor {
    return InvalidGenerationSourceError(
      'Entity constructor is not recognized.',
      todo:
          'Entity class must provide a public non-factory constructor for code generation.',
      element: _classElement,
    );
  }
}
