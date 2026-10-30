import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/error/processor_error.dart';
import 'package:froom_generator/processor/type_converter_processor.dart';
import 'package:froom_generator/value_object/type_converter.dart';

// The migration is complete
extension TypeConverterElementExtension on Element {
  /// Returns a set of [TypeConverter]s found in the @TypeConverters
  /// annotation on this element
  Set<TypeConverter> getTypeConverters(final TypeConverterScope scope) {
    if (hasAnnotation(annotations.TypeConverters)) {
      final typeConverterElements = getAnnotation(annotations.TypeConverters)
          ?.getField(AnnotationField.typeConverterValue)
          ?.toListValue()
          ?.mapNotNull((object) => object.toTypeValue()?.element);

      if (typeConverterElements == null || typeConverterElements.isEmpty) {
        throw ProcessorError(
          message:
              'There are no type converts defined even though the @TypeConverters annotation is used.',
          todo: 'Supply a type converter class to the annotation.',
          element: this,
        );
      }

      final typeConverterClassElements =
          typeConverterElements.cast<ClassElement>();

      if (typeConverterClassElements
          .any((element) => element.typeConverterSupertype == null)) {
        throw ProcessorError(
          message:
              'Only classes that extend or implement TypeConverter can be used as type converters.',
          todo: 'Make sure to use a class that extends or implements TypeConverter.',
          element: this,
        );
      }

      return typeConverterClassElements
          .map((element) => TypeConverterProcessor(element, scope).process())
          .toSet();
    } else {
      return {};
    }
  }
}

extension TypeConverterClassElementExtension on ClassElement {
  /// The `TypeConverter` supertype of this class, which it can extend or
  /// implement, directly or indirectly.
  InterfaceType? get typeConverterSupertype {
    return allSupertypes.firstWhereOrNull((type) =>
        type.element.name == 'TypeConverter' &&
        type.element.library.uri.toString().startsWith('package:froom_annotation/'));
  }
}
