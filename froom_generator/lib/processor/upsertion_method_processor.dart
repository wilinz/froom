import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/change_method_processor_helper.dart';
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/error/change_method_processor_error.dart';
import 'package:froom_generator/processor/partial_entity_processor.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:froom_generator/value_object/upsertion_method.dart';

class UpsertionMethodProcessor implements Processor<UpsertionMethod> {
  final MethodElement _methodElement;
  final List<Entity> _entities;
  final Set<TypeConverter> _typeConverters;
  final String _daoGetterName;
  final String _databaseName;
  final ChangeMethodProcessorHelper _helper;
  final ChangeMethodProcessorError _errors;

  UpsertionMethodProcessor(
    final MethodElement methodElement,
    final List<Entity> entities,
    final Set<TypeConverter> typeConverters,
    final String daoGetterName,
    final String databaseName,
  )   : _methodElement = methodElement,
        _entities = entities,
        _typeConverters = typeConverters,
        _daoGetterName = daoGetterName,
        _databaseName = databaseName,
        _errors = ChangeMethodProcessorError(methodElement, 'Upsertion'),
        _helper = ChangeMethodProcessorHelper(methodElement, entities);

  @override
  UpsertionMethod process() {
    final name = _methodElement.name!;
    final returnType = _methodElement.returnType;

    if (!_helper.returnsFuture) {
      throw _errors.doesNotReturnFuture;
    }

    final parameters = _getParameters();

    final flattenedReturnType = _helper.flattenedReturnType;

    final returnsVoid = _helper.returnsVoid;
    final returnsInt = _helper.returnsInt;
    final returnsIntList = _helper.returnsIntList;

    if (!returnsVoid && !returnsIntList && !returnsInt) {
      throw _errors.doesNotReturnVoidNorIntNorListInt;
    }
    if (!returnsVoid) {
      if (parameters.length > 1) {
        throw _errors.multipleParametersDoNotReturnVoid;
      }
      final changesMultipleItems = parameters.first.changesMultipleItems;
      if (changesMultipleItems && returnsInt) {
        throw _errors.listParameterDoesNotReturnList;
      }
      if (!changesMultipleItems && returnsIntList) {
        throw _errors.singleParameterReturnsList;
      }
    }

    return UpsertionMethod(
      _methodElement,
      name,
      returnType,
      flattenedReturnType,
      parameters,
      _daoGetterName,
      _databaseName,
    );
  }

  List<UpsertionParameter> _getParameters() {
    final parameterElements = _helper.getParameterElements();

    final targetEntity = _getTargetEntity();

    return parameterElements.map((parameterElement) {
      final flattenedParameterType =
          _helper.getFlattenedParameterType(parameterElement);
      if (parameterElement.type.isNullable ||
          flattenedParameterType.isNullable) {
        throw _errors.nullableParameter(parameterElement);
      }

      if (targetEntity == null) {
        final entity = _helper.getEntity(flattenedParameterType);
        return UpsertionParameter(parameterElement, entity, null);
      }

      final parameterClassElement = flattenedParameterType.element;
      if (parameterClassElement == targetEntity.classElement) {
        return UpsertionParameter(parameterElement, targetEntity, null);
      }
      // e.g. int, String or List, which can't be (partial) entities
      if (parameterClassElement is! ClassElement ||
          parameterClassElement.library.isInSdk) {
        throw _errors.parameterIsNotAClass(parameterElement);
      }

      final partialEntity = PartialEntityProcessor(
        parameterClassElement,
        targetEntity,
        _typeConverters,
      ).process();
      return UpsertionParameter(parameterElement, targetEntity, partialEntity);
    }).toList();
  }

  Entity? _getTargetEntity() {
    final targetType = _methodElement
        .getAnnotation(annotations.Upsert)
        ?.getField(AnnotationField.upsertEntity)
        ?.toTypeValue();
    if (targetType == null) return null;

    return _entities.firstWhere(
      (entity) => entity.classElement == targetType.element,
      orElse: () => throw _errors.targetEntityIsNotAnEntity,
    );
  }
}
