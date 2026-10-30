import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
/// Groups common functionality of change method processors.
class ChangeMethodProcessorHelper {
  final MethodElement _methodElement;
  final List<Entity> _entities;

  const ChangeMethodProcessorHelper(
    final MethodElement methodElement,
    final List<Entity> entities,
  )   : _methodElement = methodElement,
        _entities = entities;

  /// Whether the method returns a [Future].
  bool get returnsFuture => _methodElement.returnType.isDartAsyncFuture;

  /// Whether the [Future] returned by the method completes with a [List].
  bool get returnsList => _futureValueType.isDartCoreList;

  /// The type the [Future] returned by the method completes with, unwrapping
  /// a [List], e.g. `int` for both `Future<int>` and `Future<List<int>>`.
  DartType get flattenedReturnType {
    final futureValueType = _futureValueType;
    return futureValueType.isDartCoreList
        ? futureValueType.flatten()
        : futureValueType;
  }

  /// Whether the method returns `Future<void>`.
  bool get returnsVoid => !returnsList && flattenedReturnType is VoidType;

  /// Whether the method returns `Future<int>`.
  bool get returnsInt => !returnsList && flattenedReturnType.isDartCoreInt;

  /// Whether the method returns `Future<List<int>>`.
  bool get returnsIntList => returnsList && flattenedReturnType.isDartCoreInt;

  DartType get _futureValueType =>
      _methodElement.library.typeSystem.flatten(_methodElement.returnType);

  /// Returns the parameters of the method, which must not be empty.
  List<FormalParameterElement> getParameterElements() {
    final parameters = _methodElement.formalParameters;
    if (parameters.isEmpty) {
      throw InvalidGenerationSourceError(
        'There is no parameter supplied for this method. Please add one.',
        element: _methodElement,
      );
    }
    return parameters;
  }

  FormalParameterElement getParameterElement() {
    final parameters = getParameterElements();
    if (parameters.length > 1) {
      throw InvalidGenerationSourceError(
        'Only one parameter is allowed on this.',
        element: _methodElement,
      );
    }
    return parameters.first;
  }

  DartType getFlattenedParameterType(
    final FormalParameterElement parameterElement,
  ) {
    final changesMultipleItems = parameterElement.type.isDartCoreList;

    return changesMultipleItems
        ? parameterElement.type.flatten()
        : parameterElement.type;
  }

  Entity getEntity(final DartType flattenedParameterType) {
    return _entities.firstWhere(
        (entity) =>
            entity.classElement.displayName ==
            flattenedParameterType.getDisplayStringCompat(
                withNullability: false),
        orElse: () => throw InvalidGenerationSourceError(
            'You are trying to change an object which is not an entity.',
            element: _methodElement));
  }
}
