import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';
import 'package:froom_generator/value_object/dao.dart';
import 'package:froom_generator/value_object/deletion_method.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/insertion_method.dart';
import 'package:froom_generator/value_object/query_method.dart';
import 'package:froom_generator/value_object/transaction_method.dart';
import 'package:froom_generator/value_object/update_method.dart';
import 'package:froom_generator/value_object/upsertion_method.dart';
import 'package:froom_generator/writer/deletion_method_writer.dart';
import 'package:froom_generator/writer/insertion_method_writer.dart';
import 'package:froom_generator/writer/query_method_writer.dart';
import 'package:froom_generator/writer/transaction_method_writer.dart';
import 'package:froom_generator/writer/update_method_writer.dart';
import 'package:froom_generator/writer/upsertion_method_writer.dart';
import 'package:froom_generator/writer/writer.dart';

/// Creates the implementation of a DAO.
class DaoWriter extends Writer {
  final Dao dao;
  final Set<Entity> streamEntities;
  final bool dbHasViewStreams;

  DaoWriter(this.dao, this.streamEntities, this.dbHasViewStreams);

  @override
  Class write() {
    const databaseFieldName = 'database';
    const changeListenerFieldName = 'changeListener';

    final daoName = dao.name;
    final classBuilder = ClassBuilder()
      ..name = '_\$$daoName'
      ..extend = refer(daoName)
      ..fields
          .addAll(_createFields(databaseFieldName, changeListenerFieldName));

    final databaseParameter = Parameter((builder) => builder
      ..name = databaseFieldName
      ..toThis = true);

    final changeListenerParameter = Parameter((builder) => builder
      ..name = changeListenerFieldName
      ..toThis = true);

    final constructorBuilder = ConstructorBuilder()
      ..requiredParameters.addAll([databaseParameter, changeListenerParameter]);

    final queryMethods = dao.queryMethods;
    if (queryMethods.isNotEmpty) {
      classBuilder
        ..fields.add(Field((builder) => builder
          ..modifier = FieldModifier.final$
          ..name = '_queryAdapter'
          ..type = refer('QueryAdapter')));

      // listening to changes for own streams and notifying the streams of
      // the database about changes of queries, e.g. DELETE statements
      final queriesRequireChangeListener = dao.streamEntities.isNotEmpty ||
          dao.streamViews.isNotEmpty ||
          streamEntities.isNotEmpty ||
          dbHasViewStreams;

      constructorBuilder
        ..initializers.add(Code(
            "_queryAdapter = QueryAdapter(database${queriesRequireChangeListener ? ', changeListener' : ''})"));
    }

    void addAdapter(
      final String adapterType,
      final String fieldName,
      final Entity entity, {
      final String? itemClassName,
      final String? valueMapping,
      final bool withPrimaryKey = true,
    }) {
      final itemType = itemClassName ?? entity.classElement.displayName;

      classBuilder.fields.add(Field((builder) => builder
        ..name = fieldName
        ..type = refer('$adapterType<$itemType>')
        ..modifier = FieldModifier.final$));

      final primaryKey = withPrimaryKey
          ? ', ${entity.primaryKey.fields.map((field) => '\'${field.columnName}\'').toList()}'
          : '';
      final valueMapper =
          '($itemType item) => ${valueMapping ?? entity.valueMapping}';
      final requiresChangeListener =
          dbHasViewStreams || streamEntities.contains(entity);

      constructorBuilder.initializers.add(Code(
          "$fieldName = $adapterType(database, '${entity.name}'$primaryKey, $valueMapper${requiresChangeListener ? ', changeListener' : ''})"));
    }

    final insertionMethods = dao.insertionMethods;
    final insertionEntities = insertionMethods.map((method) => method.entity).toSet();
    for (final entity in insertionEntities) {
      addAdapter(
        'InsertionAdapter',
        '_${entity.classElement.displayName.decapitalize()}InsertionAdapter',
        entity,
        valueMapping: entity.insertionValueMapping,
        withPrimaryKey: false,
      );
    }

    final updateMethods = dao.updateMethods;
    final updateEntities = updateMethods.map((method) => method.entity).toSet();
    for (final entity in updateEntities) {
      addAdapter(
        'UpdateAdapter',
        '_${entity.classElement.displayName.decapitalize()}UpdateAdapter',
        entity,
      );
    }

    final upsertionMethods = dao.upsertionMethods;
    final upsertionParameters = upsertionMethods
        .expand((method) => method.parameters)
        .distinctBy((parameter) => parameter.adapterName);
    for (final parameter in upsertionParameters) {
      addAdapter(
        'UpsertionAdapter',
        parameter.adapterName,
        parameter.entity,
        itemClassName: parameter.itemClassElement.displayName,
        valueMapping: parameter.valueMapping,
      );
    }

    final deleteMethods = dao.deletionMethods;
    final deletionEntities = deleteMethods.map((method) => method.entity).toSet();
    for (final entity in deletionEntities) {
      addAdapter(
        'DeletionAdapter',
        '_${entity.classElement.displayName.decapitalize()}DeletionAdapter',
        entity,
      );
    }

    classBuilder
      ..constructors.add(constructorBuilder.build())
      ..methods.addAll(_generateQueryMethods(queryMethods))
      ..methods.addAll(_generateInsertionMethods(insertionMethods))
      ..methods.addAll(_generateUpdateMethods(updateMethods))
      ..methods.addAll(_generateUpsertionMethods(upsertionMethods))
      ..methods.addAll(_generateDeletionMethods(deleteMethods))
      ..methods.addAll(_generateTransactionMethods(dao.transactionMethods));

    return classBuilder.build();
  }

  List<Field> _createFields(
    final String databaseName,
    final String changeListenerName,
  ) {
    final databaseField = Field((builder) => builder
      ..name = databaseName
      ..type = refer('sqflite.DatabaseExecutor')
      ..modifier = FieldModifier.final$);

    final changeListenerField = Field((builder) => builder
      ..name = changeListenerName
      ..type = refer('StreamController<String>')
      ..modifier = FieldModifier.final$);

    return [databaseField, changeListenerField];
  }

  List<Method> _generateInsertionMethods(
    final List<InsertionMethod> insertionMethods,
  ) {
    return insertionMethods
        .map((method) => InsertionMethodWriter(method).write())
        .toList();
  }

  List<Method> _generateUpdateMethods(
    final List<UpdateMethod> updateMethods,
  ) {
    return updateMethods
        .map((method) => UpdateMethodWriter(method).write())
        .toList();
  }

  List<Method> _generateUpsertionMethods(
    final List<UpsertionMethod> upsertionMethods,
  ) {
    return upsertionMethods
        .map((method) => UpsertionMethodWriter(method).write())
        .toList();
  }

  List<Method> _generateDeletionMethods(
    final List<DeletionMethod> deletionMethods,
  ) {
    return deletionMethods
        .map((method) => DeletionMethodWriter(method).write())
        .toList();
  }

  List<Method> _generateQueryMethods(final List<QueryMethod> queryMethods) {
    return queryMethods
        .map((method) => QueryMethodWriter(method).write())
        .toList();
  }

  List<Method> _generateTransactionMethods(
    final List<TransactionMethod> transactionMethods,
  ) {
    return transactionMethods
        .map((method) => TransactionMethodWriter(method).write())
        .toList();
  }
}
