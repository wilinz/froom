import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:froom_generator/value_object/change_method.dart';
import 'package:froom_generator/value_object/entity.dart';

class UpdateMethod extends ChangeMethod {
  final String onConflict;

  UpdateMethod(
    final MethodElement methodElement,
    final String name,
    final DartType returnType,
    final DartType flattenedReturnType,
    final ParameterElement parameterElement,
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
          other is UpdateMethod &&
          runtimeType == other.runtimeType &&
          onConflict == other.onConflict;

  @override
  int get hashCode => super.hashCode ^ onConflict.hashCode;

  @override
  String toString() {
    return 'UpdateMethod{methodElement: $methodElement, name: $name, returnType: $returnType, flattenedReturnType: $flattenedReturnType, parameterElement: $parameterElement, entity: $entity, onConflict: $onConflict}';
  }
}
