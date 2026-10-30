import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/annotation_expression.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/value_object/upsertion_method.dart';
import 'package:froom_generator/writer/writer.dart';

class UpsertionMethodWriter implements Writer {
  final UpsertionMethod _method;

  UpsertionMethodWriter(final UpsertionMethod method) : _method = method;

  @override
  Method write() {
    return Method((builder) {
      builder
        ..annotations.add(overrideAnnotationExpression)
        ..returns = refer(
          _method.returnType.getDisplayStringCompat(withNullability: false),
        )
        ..name = _method.name
        ..requiredParameters.addAll(_generateParameters())
        ..body = Code(_generateMethodBody());

      if (_method.requiresAsyncModifier) {
        builder.modifier = MethodModifier.async;
      }
    });
  }

  List<Parameter> _generateParameters() {
    return _method.parameters.map((parameter) {
      final parameterElement = parameter.parameterElement;
      return Parameter(
        (builder) => builder
          ..name = parameterElement.name!
          ..type = refer(
            parameterElement.type.getDisplayStringCompat(
              withNullability: false,
            ),
          ),
      );
    }).toList();
  }

  String _generateMethodBody() {
    final parameters = _method.parameters;

    if (parameters.length > 1) {
      return _generateMultipleParametersMethodBody();
    }

    final parameter = parameters.first;
    final parameterName = parameter.parameterElement.displayName;
    final adapter = parameter.adapterName;

    if (_method.flattenedReturnType is VoidType) {
      return parameter.changesMultipleItems
          ? 'await $adapter.upsertList($parameterName);'
          : 'await $adapter.upsert($parameterName);';
    } else {
      // if not void then must be int return
      return parameter.changesMultipleItems
          ? 'return $adapter.upsertListAndReturnIds($parameterName);'
          : 'return $adapter.upsertAndReturnId($parameterName);';
    }
  }

  /// Multiple parameters are upserted in a single transaction, like Room does.
  String _generateMultipleParametersMethodBody() {
    final upsertions = _method.parameters
        .map((parameter) {
          final parameterName = parameter.parameterElement.displayName;
          final adapter = parameter.adapterName;
          return parameter.changesMultipleItems
              ? 'await $adapter.upsertList($parameterName);'
              : 'await $adapter.upsert($parameterName);';
        })
        .join('\n');

    final parameterNames = _method.parameters
        .map((parameter) => parameter.parameterElement.displayName)
        .join(', ');

    return '''
    if (database is sqflite.Transaction) {
      $upsertions
    } else {
      await (database as sqflite.Database).transaction<void>((transaction) async {
        final transactionDatabase = _\$${_method.databaseName}(changeListener)..database = transaction;
        await transactionDatabase.${_method.daoGetterName}.${_method.name}($parameterNames);
      });
    }
    ''';
  }
}
