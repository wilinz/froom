import 'package:analyzer/dart/element/element.dart';
import 'package:froom_generator/misc/change_method_processor_helper.dart';
import 'package:froom_generator/processor/error/change_method_processor_error.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/value_object/deletion_method.dart';
import 'package:froom_generator/value_object/entity.dart';

// The migration is complete
class DeletionMethodProcessor implements Processor<DeletionMethod> {
  final MethodElement _methodElement;
  final ChangeMethodProcessorHelper _helper;
  final ChangeMethodProcessorError _errors;

  DeletionMethodProcessor(
    final MethodElement methodElement,
    final List<Entity> entities, [
    final ChangeMethodProcessorHelper? changeMethodProcessorHelper,
  ])  : _methodElement = methodElement,
        _errors = ChangeMethodProcessorError(methodElement, 'Deletion'),
        _helper = changeMethodProcessorHelper ??
            ChangeMethodProcessorHelper(methodElement, entities);

  @override
  DeletionMethod process() {
    final name = _methodElement.name!;
    final returnType = _methodElement.returnType;

    if (!_helper.returnsFuture) {
      throw _errors.doesNotReturnFuture;
    }
    if (_helper.returnsList) {
      throw _errors.shouldNotReturnList;
    }

    final flattenedReturnType = _helper.flattenedReturnType;

    if (!_helper.returnsVoid && !_helper.returnsInt) {
      throw _errors.doesNotReturnVoidNorInt;
    }

    final parameterElement = _helper.getParameterElement();
    final flattenedParameterType =
        _helper.getFlattenedParameterType(parameterElement);

    final entity = _helper.getEntity(flattenedParameterType);

    return DeletionMethod(
      _methodElement,
      name,
      returnType,
      flattenedReturnType,
      parameterElement,
      entity,
    );
  }
}
