import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/extension/interface_element_extension.dart';
import 'package:froom_generator/misc/extension/type_converter_element_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/processor/query_method_processor.dart';
import 'package:froom_generator/processor/transaction_method_processor.dart';
import 'package:froom_generator/processor/update_method_processor.dart';
import 'package:froom_generator/processor/upsertion_method_processor.dart';
import 'package:froom_generator/value_object/dao.dart';
import 'package:froom_generator/value_object/deletion_method.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/insertion_method.dart';
import 'package:froom_generator/value_object/query_method.dart';
import 'package:froom_generator/value_object/transaction_method.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:froom_generator/value_object/update_method.dart';
import 'package:froom_generator/value_object/upsertion_method.dart';
import 'package:froom_generator/value_object/view.dart';

import 'deletion_method_processor.dart';
import 'insertion_method_processor.dart';

// The migration is complete
class DaoProcessor extends Processor<Dao> {
  final ClassElement _classElement;
  final String _daoGetterName;
  final String _databaseName;
  final List<Entity> _entities;
  final List<View> _views;
  final Set<TypeConverter> _typeConverters;

  DaoProcessor(
    final ClassElement classElement,
    final String daoGetterName,
    final String databaseName,
    final List<Entity> entities,
    final List<View> views,
    final Set<TypeConverter> typeConverters,
  )   : _classElement = classElement,
        _daoGetterName = daoGetterName,
        _databaseName = databaseName,
        _entities = entities,
        _views = views,
        _typeConverters = typeConverters;

  @override
  Dao process() {
    final name = _classElement.displayName;
    final methods = _getMethods();

    final typeConverters = Set.of(_typeConverters)
      ..addAll(_classElement.getTypeConverters(TypeConverterScope.dao));

    final queryMethods = _getQueryMethods(methods, typeConverters);
    final insertionMethods = _getInsertionMethods(methods);
    final updateMethods = _getUpdateMethods(methods);
    final upsertionMethods = _getUpsertionMethods(methods, typeConverters);
    final deletionMethods = _getDeletionMethods(methods);
    final transactionMethods = _getTransactionMethods(methods);

    final streamQueryables = queryMethods
        .where((method) => method.returnsStream)
        .map((method) => method.queryable);
    final streamEntities = streamQueryables.whereType<Entity>().toSet();
    final streamViews = streamQueryables.whereType<View>().toSet();

    return Dao(
      _classElement,
      name,
      queryMethods,
      insertionMethods,
      updateMethods,
      upsertionMethods,
      deletionMethods,
      transactionMethods,
      streamEntities,
      streamViews,
      typeConverters,
    );
  }

  /// Returns the methods of the DAO and its supertypes, of which only the
  /// most specific declaration is kept for overridden methods.
  ///
  /// An abstract redeclaration without annotation keeps the annotation of the
  /// overridden method, while a concrete one replaces it.
  List<MethodElement> _getMethods() {
    final methods = <String, MethodElement>{};
    void addMethods(final Iterable<MethodElement> declaredMethods) {
      for (final method in declaredMethods) {
        final name = method.name!;
        final declared = methods[name];
        if (declared == null ||
            (declared.isAbstract &&
                !_isAnnotated(declared) &&
                _isAnnotated(method))) {
          methods[name] = method;
        }
      }
    }

    addMethods(_classElement.methods);
    for (final supertype in _classElement.supertypesClosestFirst) {
      addMethods(supertype.methods);
    }

    return methods.values.toList();
  }

  List<QueryMethod> _getQueryMethods(
    final List<MethodElement> methods,
    final Set<TypeConverter> typeConverters,
  ) {
    return methods
        .where((method) => method.hasAnnotation(annotations.Query))
        .map((method) => QueryMethodProcessor(
              method,
              [..._entities, ..._views],
              typeConverters,
            ).process())
        .toList();
  }

  List<InsertionMethod> _getInsertionMethods(
    final List<MethodElement> methodElements,
  ) {
    return methodElements
        .where(
            (methodElement) => methodElement.hasAnnotation(annotations.Insert))
        .map((method) => InsertionMethodProcessor(method, _entities).process())
        .toList();
  }

  List<UpdateMethod> _getUpdateMethods(
    final List<MethodElement> methodElements,
  ) {
    return methodElements
        .where(
            (methodElement) => methodElement.hasAnnotation(annotations.Update))
        .map((methodElement) =>
            UpdateMethodProcessor(methodElement, _entities).process())
        .toList();
  }

  List<UpsertionMethod> _getUpsertionMethods(
    final List<MethodElement> methodElements,
    final Set<TypeConverter> typeConverters,
  ) {
    return methodElements
        .where(
            (methodElement) => methodElement.hasAnnotation(annotations.Upsert))
        .map((methodElement) => UpsertionMethodProcessor(
              methodElement,
              _entities,
              typeConverters,
              _daoGetterName,
              _databaseName,
            ).process())
        .toList();
  }

  List<DeletionMethod> _getDeletionMethods(
    final List<MethodElement> methodElements,
  ) {
    return methodElements
        .where((methodElement) =>
            methodElement.hasAnnotation(annotations.delete.runtimeType))
        .map((methodElement) =>
            DeletionMethodProcessor(methodElement, _entities).process())
        .toList();
  }

  bool _isAnnotated(final MethodElement methodElement) {
    return _isQueryOrChangeMethod(methodElement) ||
        methodElement.hasAnnotation(annotations.transaction.runtimeType);
  }

  bool _isQueryOrChangeMethod(final MethodElement methodElement) {
    return methodElement.hasAnnotation(annotations.Query) ||
        methodElement.hasAnnotation(annotations.Insert) ||
        methodElement.hasAnnotation(annotations.Update) ||
        methodElement.hasAnnotation(annotations.Upsert) ||
        methodElement.hasAnnotation(annotations.delete.runtimeType);
  }

  List<TransactionMethod> _getTransactionMethods(
    final List<MethodElement> methodElements,
  ) {
    // query and change methods run atomically already, so they aren't
    // wrapped in a transaction again
    return methodElements
        .where((methodElement) =>
            methodElement.hasAnnotation(annotations.transaction.runtimeType) &&
            !_isQueryOrChangeMethod(methodElement))
        .map((methodElement) => TransactionMethodProcessor(
              methodElement,
              _daoGetterName,
              _databaseName,
            ).process())
        .toList();
  }
}
