import 'package:analyzer/dart/element/element.dart';
import 'package:froom_generator/value_object/dao.dart';

// The migration is complete
/// Representation of a DAO getter method defined in the database class.
class DaoGetter {
  final FieldElement fieldElement;
  final String name;
  final Dao dao;

  DaoGetter(this.fieldElement, this.name, this.dao);
}
