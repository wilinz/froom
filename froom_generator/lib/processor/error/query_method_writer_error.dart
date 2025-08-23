import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
class QueryMethodWriterError {
  final MethodElement2 _methodElement;

  QueryMethodWriterError(final MethodElement2 methodElement)
      : _methodElement = methodElement;

  InvalidGenerationSourceError queryMethodReturnType() {
    return InvalidGenerationSourceError(
      'Can not define return type',
      todo:
          'Add supported return type to your query. https://wilinz.github.io/froom/daos/#queries',
      element: _methodElement,
    );
  }
}
