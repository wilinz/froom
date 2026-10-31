import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/misc/extension/set_extension.dart';
import 'package:froom_generator/misc/extension/type_converter_element_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/error/query_method_processor_error.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/processor/query_processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/fts.dart';
import 'package:froom_generator/value_object/query_method.dart';
import 'package:froom_generator/value_object/queryable.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:froom_generator/value_object/view.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

// The migration is complete
class QueryMethodProcessor extends Processor<QueryMethod> {
  /// Shared by all query methods, as it's only used for parsing.
  static final _sqlEngine = sql.SqlEngine();

  /// Engines knowing the tables and views of the queryables of databases.
  static final _analysisEngines = Expando<sql.SqlEngine>();

  final QueryMethodProcessorError _processorError;

  final MethodElement _methodElement;
  final List<Queryable> _queryables;
  final Set<TypeConverter> _typeConverters;

  QueryMethodProcessor(
    final MethodElement methodElement,
    final List<Queryable> queryables,
    final Set<TypeConverter> typeConverters,
  )   : _methodElement = methodElement,
        _queryables = queryables,
        _typeConverters = typeConverters,
        _processorError = QueryMethodProcessorError(methodElement);

  @override
  QueryMethod process() {
    final name = _methodElement.displayName;
    final parameters = _methodElement.formalParameters;
    final rawReturnType = _methodElement.returnType;

    final rawQuery = _getQuery();
    final query = QueryProcessor(_methodElement, rawQuery).process();

    final returnsStream = rawReturnType.isStream;

    _assertReturnsFutureOrStream(rawReturnType, returnsStream);

    final returnsList = _getReturnsList(rawReturnType, returnsStream);
    final flattenedReturnType = _getFlattenedReturnType(
      rawReturnType,
      returnsStream,
      returnsList,
    );

    // e.g. a class which isn't imported, reported before its nullability
    if (flattenedReturnType is InvalidType) {
      throw _processorError.unresolvedReturnType;
    }

    _assertReturnsNullableSingle(
      returnsStream,
      returnsList,
      flattenedReturnType,
    );

    final queryable = _queryables.firstWhereOrNull((queryable) =>
        queryable.classElement.displayName ==
        flattenedReturnType.getDisplayStringCompat(withNullability: false));

    if (queryable is Entity && queryable.fts is Fts5) {
      _assertSelectsFts5Rowid(rawQuery);
    }

    final parameterTypeConverters = parameters
        .expand((parameter) =>
            parameter.getTypeConverters(TypeConverterScope.daoMethodParameter))
        .toSet();

    final allTypeConverters = _typeConverters +
        _methodElement.getTypeConverters(TypeConverterScope.daoMethod) +
        parameterTypeConverters;

    if (queryable != null) {
      final fieldTypeConverters =
          queryable.fields.mapNotNull((field) => field.typeConverter);
      allTypeConverters.addAll(fieldTypeConverters);
    }

    return QueryMethod(
      _methodElement,
      name,
      query,
      rawReturnType,
      flattenedReturnType,
      parameters,
      queryable,
      allTypeConverters,
    );
  }

  String _getQuery() {
    final query = _methodElement
        .getAnnotation(annotations.Query)
        ?.getField(AnnotationField.queryValue)
        ?.toStringValue()
        ?.trim();

    if (query == null || query.isEmpty) throw _processorError.noQueryDefined;

    // the same check fails the query at runtime otherwise
    if (_sqlEngine.parse(sql.ParserEntrypoint.statement, query).rootNode
        is sql.InvalidStatement) {
      throw _processorError.invalidQuery(query);
    }
    return query;
  }

  /// FTS5 tables don't return their row id, the primary key of their
  /// entities, for `*`, so it's checked with the result columns resolved by
  /// sqlparser.
  void _assertSelectsFts5Rowid(final String query) {
    final engine = _analysisEngines[_queryables] ??= _createAnalysisEngine();
    final context = engine.analyze(query);
    // * of unknown tables may include a selected rowid
    if (context.errors.any((error) =>
        error.type == sql.AnalysisErrorType.referencedUnknownTable)) {
      return;
    }
    final root = context.root;
    final columns = root is sql.ResultSet
        ? (root as sql.ResultSet).resolvedColumns
        : null;
    // e.g. of subqueries, CTEs and compound selects, and named exactly rowid
    // for any case and alias of the row id, e.g. oid, unless aliased
    if (columns != null &&
        !columns.any((column) => column.name == Fts5.rowidColumnName)) {
      throw _processorError.fts5RowidNotSelected;
    }
  }

  /// Creates an engine knowing the tables and views of the [_queryables].
  sql.SqlEngine _createAnalysisEngine() {
    final engine = sql.SqlEngine(
        sql.EngineOptions(enabledExtensions: const [sql.Fts5Extension()]));
    var pending = _queryables;
    // views are registered after the tables and views they select from,
    // others never, e.g. of FTS3 and FTS4 tables, which aren't supported
    while (pending.isNotEmpty) {
      final unresolved = <Queryable>[];
      for (final queryable in pending) {
        final statement = queryable is Entity
            ? queryable.getCreateTableStatement()
            : (queryable as View).getCreateViewStatement();
        final context = engine.analyze(statement);
        final root = context.root;
        try {
          if (root is sql.CreateViewStatement) {
            if (context.errors.any((error) =>
                error.type == sql.AnalysisErrorType.referencedUnknownTable)) {
              unresolved.add(queryable);
            } else {
              engine.registerView(engine.schemaReader.readView(context, root));
            }
          } else if (root is sql.TableInducingStatement) {
            engine.registerTable(engine.schemaReader.read(root));
          }
        } on Object {
          continue;
        }
      }
      if (unresolved.length == pending.length) break;
      pending = unresolved;
    }
    return engine;
  }

  DartType _getFlattenedReturnType(
    final DartType rawReturnType,
    final bool returnsStream,
    final bool returnsList,
  ) {
    final type = returnsStream
        ? _methodElement.returnType.flatten()
        : _methodElement.library.typeSystem.flatten(rawReturnType);
    return returnsList ? type.flatten() : type;
  }

  bool _getReturnsList(final DartType returnType, final bool returnsStream) {
    final type = returnsStream
        ? returnType.flatten()
        : _methodElement.library.typeSystem.flatten(returnType);

    return type.isDartCoreList;
  }

  void _assertReturnsFutureOrStream(
    final DartType rawReturnType,
    final bool returnsStream,
  ) {
    if (!rawReturnType.isDartAsyncFuture && !returnsStream) {
      throw _processorError.doesNotReturnFutureNorStream;
    }
  }

  void _assertReturnsNullableSingle(
    final bool returnsStream,
    final bool returnsList,
    final DartType flattenedReturnType,
  ) {
    if (!returnsList &&
        !(flattenedReturnType is VoidType) &&
        !flattenedReturnType.isNullable) {
      if (returnsStream) {
        throw _processorError.doesNotReturnNullableStream;
      } else {
        throw _processorError.doesNotReturnNullableFuture;
      }
    }
  }
}
