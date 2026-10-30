import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/extension/set_extension.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';
import 'package:froom_generator/misc/extension/type_converter_element_extension.dart';
import 'package:froom_generator/misc/extension/type_converters_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/error/queryable_processor_error.dart';
import 'package:froom_generator/processor/field_processor.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/value_object/field.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
abstract class QueryableProcessor<T> extends Processor<T> {
  final QueryableProcessorError _queryableProcessorError;

  @protected
  final ClassElement classElement;

  final Set<TypeConverter> queryableTypeConverters;

  @protected
  QueryableProcessor(
    this.classElement,
    final Set<TypeConverter> typeConverters,
  )   : _queryableProcessorError = QueryableProcessorError(classElement),
        queryableTypeConverters = typeConverters +
            classElement.getTypeConverters(TypeConverterScope.queryable);

  @protected
  List<Field> getFields() {
    if (classElement.mixins.isNotEmpty) {
      throw _queryableProcessorError.prohibitedMixinUsage;
    }
    final fields = [
      ...classElement.fields,
      ...classElement.allSupertypes.expand((type) => type.element.fields),
    ];

    return fields
        .where((fieldElement) => fieldElement.shouldBeIncluded())
        .map((field) {
      final typeConverter = getFieldTypeConverter(field);
      return FieldProcessor(field, typeConverter).process();
    }).toList();
  }

  /// The type converter to use for [fieldElement] unless the field declares
  /// its own one.
  @protected
  TypeConverter? getFieldTypeConverter(final FieldElement fieldElement) {
    return queryableTypeConverters.getClosestOrNull(fieldElement.type);
  }

  @protected
  String getConstructor(final List<Field> fields) {
    final constructors = classElement.constructors
        .where((element) => element.isPublic && !element.isFactory);
    // prefer the unnamed constructor, the name of which is `new`
    final constructor =
        constructors.firstWhereOrNull((element) => element.name == 'new') ??
            constructors.firstOrNull;
    final constructorParameters = constructor?.formalParameters;

    if (constructor == null || constructorParameters == null) {
      throw _queryableProcessorError.missingUnnamedConstructor;
    } else {
      final parameterValues = constructorParameters
          .map((parameterElement) =>
              _getParameterValue(parameterElement, fields))
          .where((parameterValue) => parameterValue != null)
          .join(', ');

      // fields which aren't initialized by the constructor but have a setter
      final constructorParameterNames = constructorParameters
          .map((parameterElement) => parameterElement.displayName)
          .toSet();
      final setterAssignments = fields
          .where((field) => !constructorParameterNames.contains(field.name))
          .where((field) => field.fieldElement.setter != null)
          .map((field) {
        final value =
            _getDecodedValue(field, field.fieldElement.type, field.fieldElement);
        return '..${field.name} = ($value)';
      }).join();

      final constructorName = constructor.name == 'new'
          ? classElement.displayName
          : '${classElement.displayName}.${constructor.name}';

      return '$constructorName($parameterValues)$setterAssignments';
    }
  }

  /// Returns `null` whenever field is @ignored
  String? _getParameterValue(
    final FormalParameterElement parameterElement,
    final List<Field> fields,
  ) {
    final parameterName = parameterElement.displayName;
    final field =
        // null whenever field is @ignored
        fields.firstWhereOrNull((field) => field.name == parameterName);
    if (field != null) {
      final parameterValue = _getDecodedValue(
        field,
        parameterElement.type,
        parameterElement,
      );

      if (parameterElement.isNamed) {
        return '$parameterName: $parameterValue';
      }
      return parameterValue; // also covers positional parameter
    } else {
      return null;
    }
  }

  /// The type converter encoding the value of [field] for the database.
  @protected
  TypeConverter? getValueTypeConverter(final Field field) {
    return [...queryableTypeConverters, field.typeConverter]
        .nonNulls
        .getClosestOrNull(field.fieldElement.type);
  }

  /// Decodes the database value of [field] into a value of [type].
  String _getDecodedValue(
    final Field field,
    final DartType type,
    final Element element,
  ) {
    final databaseValue = "row['${field.columnName}']";

    final typeConverter = [...queryableTypeConverters, field.typeConverter]
        .nonNulls
        .getClosestOrNull(type);

    if (typeConverter != null) {
      final castedDatabaseValue = databaseValue.cast(
        typeConverter.databaseType,
        element,
      );
      return '_${typeConverter.name.decapitalize()}.decode($castedDatabaseValue)';
    } else if (type.isDefaultSqlType || type.isEnumType) {
      return databaseValue.cast(type, element);
    } else {
      throw InvalidGenerationSourceError(
        'Column type is not supported for $type',
        todo:
            'Either use a supported type https://wilinz.github.io/froom/entities/#supported-types or supply a type converter.',
      );
    }
  }

  /// Maps the fields of an item to its database column values.
  @protected
  String getValueMapping(final List<Field> fields) {
    final keyValueList = fields.map((field) {
      final columnName = field.columnName;
      final attributeValue = _getAttributeValue(field);
      return "'$columnName': $attributeValue";
    }).toList();

    return '<String, Object?>{${keyValueList.join(', ')}}';
  }

  String _getAttributeValue(final Field field) {
    final fieldElement = field.fieldElement;
    final parameterName = fieldElement.displayName;
    final fieldType = fieldElement.type;
    final typeConverter = getValueTypeConverter(field);
    String attributeValue = 'item.$parameterName';

    if (typeConverter != null) {
      attributeValue =
          '_${typeConverter.name.decapitalize()}.encode(item.$parameterName)';
    } else if (fieldType.isDartCoreBool) {
      attributeValue = _serializeBoolean(field, attributeValue);
    } else if (fieldType.isEnumType) {
      attributeValue = _serializeEnum(attributeValue, field);
    }
    return attributeValue;
  }

  String _serializeBoolean(Field field, String attributeValue) {
    return field.isNullable
        // force! underlying non-nullable type as null check has been done
        ? '$attributeValue == null ? null : ($attributeValue! ? 1 : 0)'
        : '$attributeValue ? 1 : 0';
  }

  String _serializeEnum(String attributeValue, Field field) {
    final operator = field.isNullable ? '?.' : '.';
    return '$attributeValue${operator}index';
  }
}

extension on FieldElement {
  bool shouldBeIncluded() {
    final isIgnored = hasAnnotation(annotations.ignore.runtimeType);
    final isDeclared = isOriginDeclaration || isOriginDeclaringFormalParameter;
    return !(isStatic || !isDeclared || isIgnored);
  }
}
