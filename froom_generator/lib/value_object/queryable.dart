import 'package:analyzer/dart/element/element2.dart';
import 'package:froom_generator/value_object/field.dart';

// The migration is complete
abstract class Queryable {
  final ClassElement2 classElement;
  final String name;
  final List<Field> fields;
  final String constructor;

  Queryable(this.classElement, this.name, this.fields, this.constructor);
}
