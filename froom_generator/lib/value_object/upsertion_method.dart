import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/partial_entity.dart';

class UpsertionMethod {
  final MethodElement methodElement;
  final String name;
  final DartType returnType;
  final DartType flattenedReturnType;
  final List<UpsertionParameter> parameters;

  /// The name of the DAO getter in the database, required to run upsertions
  /// of multiple parameters in a transaction.
  final String daoGetterName;
  final String databaseName;

  UpsertionMethod(
    this.methodElement,
    this.name,
    this.returnType,
    this.flattenedReturnType,
    this.parameters,
    this.daoGetterName,
    this.databaseName,
  );

  bool get requiresAsyncModifier => flattenedReturnType is VoidType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpsertionMethod &&
          runtimeType == other.runtimeType &&
          methodElement == other.methodElement &&
          name == other.name &&
          returnType == other.returnType &&
          flattenedReturnType == other.flattenedReturnType &&
          parameters.equals(other.parameters) &&
          daoGetterName == other.daoGetterName &&
          databaseName == other.databaseName;

  @override
  int get hashCode =>
      methodElement.hashCode ^
      name.hashCode ^
      returnType.hashCode ^
      flattenedReturnType.hashCode ^
      parameters.hashCode ^
      daoGetterName.hashCode ^
      databaseName.hashCode;

  @override
  String toString() {
    return 'UpsertionMethod{methodElement: $methodElement, name: $name, returnType: $returnType, flattenedReturnType: $flattenedReturnType, parameters: $parameters, daoGetterName: $daoGetterName, databaseName: $databaseName}';
  }
}

/// A parameter of an [UpsertionMethod] holding an entity, a partial entity
/// or a list of either.
class UpsertionParameter {
  final FormalParameterElement parameterElement;
  final Entity entity;
  final PartialEntity? partialEntity;

  UpsertionParameter(this.parameterElement, this.entity, this.partialEntity);

  bool get changesMultipleItems => parameterElement.type.isDartCoreList;

  /// The class of the upserted items.
  ClassElement get itemClassElement =>
      partialEntity?.classElement ?? entity.classElement;

  String get valueMapping => partialEntity?.valueMapping ?? entity.valueMapping;

  /// Partial entities can target different entities, thus the target entity
  /// is part of their adapter name.
  String get adapterName {
    final partialEntity = this.partialEntity;
    if (partialEntity == null) {
      return '_${entity.classElement.displayName.decapitalize()}UpsertionAdapter';
    }
    final partialEntityName =
        partialEntity.classElement.displayName.decapitalize();
    return '_${partialEntityName}To${entity.classElement.displayName}UpsertionAdapter';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpsertionParameter &&
          runtimeType == other.runtimeType &&
          parameterElement == other.parameterElement &&
          entity == other.entity &&
          partialEntity == other.partialEntity;

  @override
  int get hashCode =>
      parameterElement.hashCode ^ entity.hashCode ^ partialEntity.hashCode;

  @override
  String toString() {
    return 'UpsertionParameter{parameterElement: $parameterElement, entity: $entity, partialEntity: $partialEntity}';
  }
}
