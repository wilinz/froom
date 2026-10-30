import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:collection/collection.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:source_gen/source_gen.dart';

extension TypeConvertersExtension on Iterable<TypeConverter> {
  /// Returns the [TypeConverter] in the closest [TypeConverterScope] or null
  TypeConverter? get closestOrNull {
    return sortedByDescending((typeConverter) => typeConverter.scope.index)
        .firstOrNull;
  }

  /// Returns the [TypeConverter] in the closest [TypeConverterScope] for
  /// [dartType] or null
  TypeConverter? getClosestOrNull(DartType dartType) {
    return sortedByDescending((typeConverter) => typeConverter.scope.index)
        .firstWhereOrNull((typeConverter) {
      return typeConverter.fieldType == dartType;
    });
  }

  /// Like [getClosestOrNull], but a nullable [dartType] falls back to a
  /// converter of its non-nullable type, which then only converts non-null
  /// values, see [TypeConverterNullabilityExtension.convertsOnlyNonNull].
  TypeConverter? getClosestOrNullForNullable(
    DartType dartType,
    TypeSystem typeSystem,
  ) {
    return getClosestOrNull(dartType) ??
        (dartType.isNullable
            ? getClosestOrNull(typeSystem.promoteToNonNull(dartType))
            : null);
  }

  /// Returns the [TypeConverter] in the closest [TypeConverterScope] for
  /// [dartType]
  TypeConverter getClosest(DartType dartType) {
    final closest = getClosestOrNull(dartType);
    if (closest == null) {
      throw InvalidGenerationSourceError(
        'Column type is not supported for $dartType',
        todo: 'Either use a supported type or supply a type converter.',
      );
    }
    return closest;
  }
}

extension TypeConverterNullabilityExtension on TypeConverter {
  /// Whether the converter of a non-nullable type is used for the nullable
  /// [dartType], so that null values have to bypass it.
  bool convertsOnlyNonNull(DartType dartType) {
    return dartType.isNullable && !fieldType.isNullable;
  }
}
