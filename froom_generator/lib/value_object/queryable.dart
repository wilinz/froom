import 'package:analyzer/dart/element/element.dart';
import 'package:froom_generator/value_object/field.dart';

// The migration is complete
abstract class Queryable {
  final ClassElement classElement;
  final String name;
  final List<Field> fields;
  final String constructor;

  Queryable(this.classElement, this.name, this.fields, this.constructor);
}
