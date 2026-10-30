import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/change_method_processor_helper.dart';
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/extension/dart_object_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/error/change_method_processor_error.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/update_method.dart';

// The migration is complete
class UpdateMethodProcessor implements Processor<UpdateMethod> {
  final MethodElement _methodElement;
  final ChangeMethodProcessorHelper _helper;
  final ChangeMethodProcessorError _errors;

  UpdateMethodProcessor(
    final MethodElement methodElement,
    final List<Entity> entities, [
    final ChangeMethodProcessorHelper? changeMethodProcessorHelper,
  ])  : _methodElement = methodElement,
        _errors = ChangeMethodProcessorError(methodElement, 'Update'),
        _helper = changeMethodProcessorHelper ??
            ChangeMethodProcessorHelper(methodElement, entities);

  @override
  UpdateMethod process() {
    final name = _methodElement.name!;
    final returnType = _methodElement.returnType;

    if (!_helper.returnsFuture) {
      throw _errors.doesNotReturnFuture;
    }
    if (_helper.returnsList) {
      throw _errors.shouldNotReturnList;
    }

    final flattenedReturnType = _helper.flattenedReturnType;

    if (!_helper.returnsInt && !_helper.returnsVoid) {
      throw _errors.doesNotReturnVoidNorInt;
    }

    final parameterElement = _helper.getParameterElement();
    final flattenedParameterType =
        _helper.getFlattenedParameterType(parameterElement);
    final entity = _helper.getEntity(flattenedParameterType);
    final onConflict = _getOnConflictStrategy();

    return UpdateMethod(
      _methodElement,
      name,
      returnType,
      flattenedReturnType,
      parameterElement,
      entity,
      onConflict,
    );
  }

  String _getOnConflictStrategy() {
    final onConflictStrategy = _methodElement
        .getAnnotation(annotations.Update)
        ?.getField(AnnotationField.onConflict)
        ?.toEnumValueString();

    if (onConflictStrategy == null) {
      throw _errors.wrongOnConflictValue;
    } else {
      return onConflictStrategy;
    }
  }
}
