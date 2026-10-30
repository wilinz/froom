import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations
    show OnConflictStrategy;
import 'package:froom_generator/misc/constants.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
class ChangeMethodProcessorError {
  final MethodElement _methodElement;
  final String _methodType;

  ChangeMethodProcessorError(this._methodElement, this._methodType);

  InvalidGenerationSourceError get doesNotReturnVoidNorInt =>
      InvalidGenerationSourceError(
        '$_methodType methods have to return a Future of either void or int.',
        element: _methodElement,
      );

  InvalidGenerationSourceError get doesNotReturnFuture =>
      InvalidGenerationSourceError(
        '$_methodType methods have to return a Future.',
        element: _methodElement,
      );

  InvalidGenerationSourceError get shouldNotReturnList =>
      InvalidGenerationSourceError(
        '$_methodType methods have to return a Future of either void or int but not a list.',
        element: _methodElement,
      );
  InvalidGenerationSourceError get doesNotReturnVoidNorIntNorListInt =>
      InvalidGenerationSourceError(
        '$_methodType methods have to return a Future of either void, int or List<int>.',
        element: _methodElement,
      );
  InvalidGenerationSourceError get wrongOnConflictValue =>
      InvalidGenerationSourceError(
        'Value of ${AnnotationField.onConflict} must be one of ${annotations.OnConflictStrategy.values.map((e) => e.toString()).join(',')}',
        element: _methodElement,
      );

  InvalidGenerationSourceError get multipleParametersDoNotReturnVoid =>
      InvalidGenerationSourceError(
        '$_methodType methods with multiple parameters have to return a Future of void.',
        element: _methodElement,
      );

  InvalidGenerationSourceError get listParameterDoesNotReturnList =>
      InvalidGenerationSourceError(
        '$_methodType methods with a list parameter have to return a Future of either void or List<int>.',
        element: _methodElement,
      );

  InvalidGenerationSourceError get singleParameterReturnsList =>
      InvalidGenerationSourceError(
        '$_methodType methods with a single item parameter have to return a Future of either void or int.',
        element: _methodElement,
      );

  InvalidGenerationSourceError get targetEntityIsNotAnEntity =>
      InvalidGenerationSourceError(
        'The target entity of the ${_methodType.toLowerCase()} method is not an entity of the database.',
        element: _methodElement,
      );

  InvalidGenerationSourceError nullableParameter(
    final FormalParameterElement parameterElement,
  ) =>
      InvalidGenerationSourceError(
        'The parameter ${parameterElement.displayName} and its list items must not be nullable.',
        element: parameterElement,
      );

  InvalidGenerationSourceError parameterIsNotAClass(
    final FormalParameterElement parameterElement,
  ) =>
      InvalidGenerationSourceError(
        'The parameter ${parameterElement.displayName} has to be an entity, a partial entity or a list of either.',
        element: parameterElement,
      );
}
