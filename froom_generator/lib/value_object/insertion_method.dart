import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:froom_generator/value_object/change_method.dart';
import 'package:froom_generator/value_object/entity.dart';

// The migration is complete
class InsertionMethod extends ChangeMethod {
  final String onConflict;

  InsertionMethod(
    final MethodElement2 methodElement,
    final String name,
    final DartType returnType,
    final DartType flattenedReturnType,
    final FormalParameterElement parameterElement,
    final Entity entity,
    this.onConflict,
  ) : super(
          methodElement,
          name,
          returnType,
          flattenedReturnType,
          parameterElement,
          entity,
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is InsertionMethod &&
          runtimeType == other.runtimeType &&
          onConflict == other.onConflict;

  @override
  int get hashCode => super.hashCode ^ onConflict.hashCode;

  @override
  String toString() {
    return 'InsertionMethod{methodElement: $methodElement, name: $name, returnType: $returnType, flattenedReturnType: $flattenedReturnType, parameterElement: $parameterElement, entity: $entity, onConflict: $onConflict}';
  }
}
