import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:froom_generator/misc/extension/field_element_extension.dart';
import 'package:froom_generator/processor/error/partial_entity_processor_error.dart';
import 'package:froom_generator/processor/queryable_processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/field.dart';
import 'package:froom_generator/value_object/partial_entity.dart';
import 'package:froom_generator/value_object/type_converter.dart';

/// Processes a class containing a subset of the columns of an [Entity].
class PartialEntityProcessor extends QueryableProcessor<PartialEntity> {
  final Entity _entity;
  final PartialEntityProcessorError _processorError;

  PartialEntityProcessor(
    final ClassElement classElement,
    final Entity entity,
    final Set<TypeConverter> typeConverters,
  ) : _entity = entity,
      _processorError = PartialEntityProcessorError(classElement, entity.name),
      super(classElement, typeConverters);

  @override
  PartialEntity process() {
    final fields = getFields();
    if (fields.isEmpty) {
      throw _processorError.noColumns;
    }

    final duplicateField = fields
        .whereIndexed((index, field) => fields
            .take(index)
            .any((other) => other.columnName == field.columnName))
        .firstOrNull;
    if (duplicateField != null) {
      throw _processorError.duplicateColumn(duplicateField.fieldElement);
    }

    for (final field in fields) {
      final entityField = _entity.fields.firstWhereOrNull(
        (entityField) => entityField.columnName == field.columnName,
      );
      if (entityField == null) {
        throw _processorError.unknownColumn(field.fieldElement);
      }
      if (!_hasSameType(field, entityField)) {
        throw _processorError.columnTypeMismatch(field.fieldElement);
      }
      if (field.typeConverter?.name != entityField.typeConverter?.name) {
        throw _processorError.typeConverterMismatch(field.fieldElement);
      }
      if (!entityField.isNullable && field.isNullable) {
        throw _processorError.nullabilityMismatch(field.fieldElement);
      }
    }

    final columnNames = fields.map((field) => field.columnName).toSet();
    final primaryKey = _entity.primaryKey;

    final missingPrimaryKeys = primaryKey.fields
        .map((field) => field.columnName)
        .where((columnName) => !columnNames.contains(columnName))
        .toList();
    if (!primaryKey.autoGenerateId && missingPrimaryKeys.isNotEmpty) {
      throw _processorError.missingPrimaryKeys(missingPrimaryKeys);
    }

    final missingRequiredColumns = _entity.fields
        .where((field) => !primaryKey.fields.contains(field))
        .where((field) => !field.isNullable)
        .map((field) => field.columnName)
        .where((columnName) => !columnNames.contains(columnName))
        .toList();
    if (missingRequiredColumns.isNotEmpty) {
      throw _processorError.missingRequiredColumns(missingRequiredColumns);
    }

    return PartialEntity(
      classElement,
      _entity,
      fields,
      getValueMapping(fields),
    );
  }

  /// Whether both fields have the same type, ignoring nullability.
  bool _hasSameType(final Field field, final Field entityField) {
    final typeSystem = classElement.library.typeSystem;
    return typeSystem.promoteToNonNull(field.fieldElement.type) ==
        typeSystem.promoteToNonNull(entityField.fieldElement.type);
  }

  /// Uses the type converter of the matching entity column, which covers
  /// converters of the database, the entity class and the entity field, so
  /// that the column gets encoded exactly like by the entity.
  @override
  TypeConverter? getFieldTypeConverter(final FieldElement fieldElement) {
    final entityField = _entity.fields.firstWhereOrNull(
      (field) => field.columnName == fieldElement.columnName,
    );
    // reported before processing the field, which fails on unsupported types
    if (entityField == null) {
      throw _processorError.unknownColumn(fieldElement);
    }
    return entityField.typeConverter;
  }

  /// Encodes values only with the converter of the entity column, ignoring
  /// converters of the DAO the entity doesn't know of.
  @override
  TypeConverter? getValueTypeConverter(final Field field) {
    return field.typeConverter;
  }
}
