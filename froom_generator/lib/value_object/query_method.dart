import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:froom_generator/misc/extension/set_equality_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/value_object/query.dart';
import 'package:froom_generator/value_object/queryable.dart';
import 'package:froom_generator/value_object/type_converter.dart';

// The migration is complete
/// Wraps a method annotated with Query
/// to enable easy access to code generation relevant data.
class QueryMethod {
  final MethodElement methodElement;

  final String name;

  /// Query where the parameter mapping is stored.
  final Query query;

  final DartType rawReturnType;

  /// Flattened return type.
  ///
  /// E.g.
  /// Future<T> -> T,
  /// Future<List<T>> -> T
  ///
  /// Stream<T> -> T
  /// Stream<List<T>> -> T
  final DartType flattenedReturnType;

  final List<FormalParameterElement> parameters;

  final Queryable? queryable;

  final Set<TypeConverter> typeConverters;

  QueryMethod(
    this.methodElement,
    this.name,
    this.query,
    this.rawReturnType,
    this.flattenedReturnType,
    this.parameters,
    this.queryable,
    this.typeConverters,
  );

  bool get returnsList {
    final type = returnsStream
        ? rawReturnType.flatten()
        : methodElement.library.typeSystem.flatten(rawReturnType);

    return type.isDartCoreList;
  }

  bool get returnsStream => rawReturnType.isStream;

  bool get returnsVoid => flattenedReturnType is VoidType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryMethod &&
          runtimeType == other.runtimeType &&
          // 比较方法名而不是元素实例
          methodElement.name == other.methodElement.name &&
          name == other.name &&
          query == other.query &&
          // 比较类型的字符串表示
          rawReturnType.getDisplayString() ==
              other.rawReturnType.getDisplayString() &&
          flattenedReturnType.getDisplayString() ==
              other.flattenedReturnType.getDisplayString() &&
          // 使用自定义的参数比较
          _parametersEqual(parameters, other.parameters) &&
          queryable == other.queryable &&
          typeConverters.equals(other.typeConverters);

  bool _parametersEqual(
    List<FormalParameterElement> a,
    List<FormalParameterElement> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name ||
          a[i].type.getDisplayString() != b[i].type.getDisplayString()) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      methodElement.name.hashCode ^
      name.hashCode ^
      query.hashCode ^
      rawReturnType.getDisplayString().hashCode ^
      flattenedReturnType.getDisplayString().hashCode ^
      // 对参数列表生成 hashCode
      Object.hashAll(parameters
          .map((p) => Object.hash(p.name, p.type.getDisplayString()))) ^
      queryable.hashCode ^
      typeConverters.hashCode;

  @override
  String toString() {
    return 'QueryMethod{methodElement: $methodElement, name: $name, query: $query, rawReturnType: $rawReturnType, flattenedReturnType: $flattenedReturnType, parameters: $parameters, queryable: $queryable, typeConverters: $typeConverters}';
  }
}
