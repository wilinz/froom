import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

// The migration is complete
class TransactionMethod {
  final MethodElement2 methodElement;
  final String name;
  final DartType returnType;
  final List<FormalParameterElement> parameterElements;
  final String daoFieldName;
  final String databaseName;

  TransactionMethod(
    this.methodElement,
    this.name,
    this.returnType,
    this.parameterElements,
    this.daoFieldName,
    this.databaseName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TransactionMethod &&
              runtimeType == other.runtimeType &&
              // 比较元素的名称而不是实例
              methodElement.name3 == other.methodElement.name3 &&
              name == other.name &&
              // 比较类型的字符串表示
              returnType.getDisplayString() == other.returnType.getDisplayString() &&
              // 使用 ListEquality 或自定义比较
              _parametersEqual(parameterElements, other.parameterElements) &&
              daoFieldName == other.daoFieldName &&
              databaseName == other.databaseName;

  bool _parametersEqual(
      List<FormalParameterElement> a,
      List<FormalParameterElement> b
      ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      // 比较参数名和类型
      if (a[i].name3 != b[i].name3 ||
          a[i].type.getDisplayString() != b[i].type.getDisplayString()) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      methodElement.name3.hashCode ^
      name.hashCode ^
      returnType.getDisplayString().hashCode ^
      parameterElements.map((e) => e.name3).join(',').hashCode ^
      daoFieldName.hashCode ^
      databaseName.hashCode;

  @override
  String toString() {
    return 'NewTransactionMethod{methodElement: $methodElement, name: $name, returnType: $returnType, parameterElements: $parameterElements, daoFieldName: $daoFieldName, databaseName: $databaseName}';
  }
}
