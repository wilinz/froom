import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/annotation_expression.dart';
import 'package:froom_generator/misc/method_parameters.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/value_object/transaction_method.dart';
import 'package:froom_generator/writer/writer.dart';

// The migration is complete
class TransactionMethodWriter implements Writer {
  final TransactionMethod method;

  TransactionMethodWriter(this.method);

  @override
  Method write() {
    return Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..returns = refer(method.returnType.getDisplayStringCompat(
        withNullability: true,
      ))
      ..name = method.name
      ..addParametersOf(method.parameterElements)
      ..modifier = MethodModifier.async
      ..body = Code(_generateMethodBody()));
  }

  String _generateMethodBody() {
    final methodCall =
        '${method.name}(${getArgumentsOf(method.parameterElements)})';
    final innerType = method.returnType.flatten();
    final innerTypeName =
        innerType.getDisplayStringCompat(withNullability: false);
    final finalExpression = innerType is VoidType ? 'await' : 'return';

    return '''
    if (database is sqflite.Transaction) {
      $finalExpression super.$methodCall;
    } else {
      $finalExpression (database as sqflite.Database).transaction<$innerTypeName>((transaction) async {
        final transactionDatabase = _\$${method.databaseName}(changeListener)..database = transaction;
        $finalExpression transactionDatabase.${method.daoFieldName}.$methodCall;
      });
    }
    ''';
  }
}
