import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/field.dart';

/// A class containing a subset of the columns of an [entity].
class PartialEntity {
  final ClassElement classElement;
  final Entity entity;
  final List<Field> fields;
  final String valueMapping;

  PartialEntity(
    this.classElement,
    this.entity,
    this.fields,
    this.valueMapping,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartialEntity &&
          runtimeType == other.runtimeType &&
          classElement == other.classElement &&
          entity == other.entity &&
          fields.equals(other.fields) &&
          valueMapping == other.valueMapping;

  @override
  int get hashCode =>
      classElement.hashCode ^
      entity.hashCode ^
      fields.hashCode ^
      valueMapping.hashCode;

  @override
  String toString() {
    return 'PartialEntity{classElement: $classElement, entity: $entity, fields: $fields, valueMapping: $valueMapping}';
  }
}
