import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/extension/dart_object_extension.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/error/entity_processor_error.dart';
import 'package:froom_generator/processor/queryable_processor.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/field.dart';
import 'package:froom_generator/value_object/foreign_key.dart';
import 'package:froom_generator/value_object/fts.dart';
import 'package:froom_generator/value_object/index.dart';
import 'package:froom_generator/value_object/primary_key.dart';
import 'package:froom_generator/value_object/type_converter.dart';

// The migration is complete
class EntityProcessor extends QueryableProcessor<Entity> {
  final EntityProcessorError _processorError;

  EntityProcessor(
    final ClassElement classElement,
    final Set<TypeConverter> typeConverters,
  )   : _processorError = EntityProcessorError(classElement),
        super(classElement, typeConverters);

  @override
  Entity process() {
    final name = _getName();
    final fields = getFields();
    final primaryKey = _getPrimaryKey(fields);
    final withoutRowid = _getWithoutRowid();

    if (primaryKey.autoGenerateId && withoutRowid) {
      throw _processorError.autoIncrementInWithoutRowid;
    }
    final foreignKeys = _getForeignKeys();
    final indices = _getIndices(fields, name);
    final fts = _getFts();
    if (fts is Fts5) {
      _validateFts5(
          fts, name, fields, primaryKey, foreignKeys, indices, withoutRowid);
    }

    return Entity(
      classElement,
      name,
      fields,
      primaryKey,
      foreignKeys,
      indices,
      withoutRowid,
      getConstructor(fields),
      getValueMapping(fields),
      fts,
      insertionValueMapping: getValueMapping(
        fields,
        unsetPrimaryKey: _getUnsetPrimaryKey(primaryKey),
      ),
    );
  }

  /// Returns the auto generated primary key field, for which `0` means unset,
  /// if it's a non-nullable integer without type converter.
  Field? _getUnsetPrimaryKey(final PrimaryKey primaryKey) {
    if (!primaryKey.autoGenerateId) return null;
    final field = primaryKey.fields.single;
    final type = field.fieldElement.type;
    return type.isDartCoreInt && !field.isNullable && field.typeConverter == null
        ? field
        : null;
  }

  String _getName() {
    return classElement
            .getAnnotation(annotations.Entity)
            ?.getField(AnnotationField.entityTableName)
            ?.toStringValue() ??
        classElement.displayName;
  }

  List<ForeignKey> _getForeignKeys() {
    return classElement
            .getAnnotation(annotations.Entity)
            ?.getField(AnnotationField.entityForeignKeys)
            ?.toListValue()
            ?.map((foreignKeyObject) {
          final parentType = foreignKeyObject
                  .getField(ForeignKeyField.entity)
                  ?.toTypeValue() ??
              (throw _processorError.foreignKeyNoEntity);

          final parentElement = parentType.element;
          final parentName = parentElement is ClassElement
              ? parentElement
                      .getAnnotation(annotations.Entity)
                      ?.getField(AnnotationField.entityTableName)
                      ?.toStringValue() ??
                  parentType.getDisplayStringCompat(withNullability: false)
              : throw _processorError.foreignKeyDoesNotReferenceEntity;

          final childColumns =
              _getColumns(foreignKeyObject, ForeignKeyField.childColumns);
          if (childColumns.isEmpty) {
            throw _processorError.missingChildColumns;
          }

          final parentColumns =
              _getColumns(foreignKeyObject, ForeignKeyField.parentColumns);
          if (parentColumns.isEmpty) {
            throw _processorError.missingParentColumns;
          }

          final onUpdate =
              _getForeignKeyAction(foreignKeyObject, ForeignKeyField.onUpdate);

          final onDelete =
              _getForeignKeyAction(foreignKeyObject, ForeignKeyField.onDelete);

          return ForeignKey(
            parentName,
            parentColumns,
            childColumns,
            onUpdate,
            onDelete,
          );
        }).toList() ??
        [];
  }

  Fts? _getFts() {
    final ftsAnnotations = [
      annotations.Fts3,
      annotations.Fts4,
      annotations.Fts5,
    ].where(classElement.hasAnnotation).toList();
    if (ftsAnnotations.length > 1) throw _processorError.multipleFts;
    final ftsAnnotation = ftsAnnotations.singleOrNull;
    if (ftsAnnotation == annotations.Fts3) return _getFts3();
    if (ftsAnnotation == annotations.Fts4) return _getFts4();
    if (ftsAnnotation == annotations.Fts5) return _getFts5();
    return null;
  }

  /// Rejects the tokenizers of FTS5 only in FTS3 and FTS4 tables.
  void _assertFts3Or4Tokenizer(final String tokenizer) {
    if (const {annotations.FtsTokenizer.ascii, annotations.FtsTokenizer.trigram}
        .contains(tokenizer.toLowerCase())) {
      throw _processorError.ftsUnsupportedTokenizer(tokenizer);
    }
  }

  Fts _getFts3() {
    final ftsObject = classElement.getAnnotation(annotations.Fts3);

    final tokenizer =
        ftsObject?.getField(Fts3Field.tokenizer)?.toStringValue() ??
            annotations.FtsTokenizer.simple;
    _assertFts3Or4Tokenizer(tokenizer);

    final tokenizerArgs = ftsObject
            ?.getField(Fts3Field.tokenizerArgs)
            ?.toListValue()
            ?.mapNotNull((object) => object.toStringValue())
            .toList() ??
        [];

    return Fts3(tokenizer, tokenizerArgs);
  }

  Fts _getFts4() {
    final ftsObject = classElement.getAnnotation(annotations.Fts4);

    final tokenizer =
        ftsObject?.getField(Fts4Field.tokenizer)?.toStringValue() ??
            annotations.FtsTokenizer.simple;
    _assertFts3Or4Tokenizer(tokenizer);

    final tokenizerArgs = ftsObject
            ?.getField(Fts4Field.tokenizerArgs)
            ?.toListValue()
            ?.mapNotNull((object) => object.toStringValue())
            .toList() ??
        [];

    return Fts4(tokenizer, tokenizerArgs);
  }

  Fts _getFts5() {
    final ftsObject = classElement.getAnnotation(annotations.Fts5);

    final tokenizer =
        ftsObject?.getField(Fts5Field.tokenizer)?.toStringValue() ??
            annotations.FtsTokenizer.unicode61;

    List<T> getList<T>(final String field, T? Function(DartObject) toValue) =>
        ftsObject
            ?.getField(field)
            ?.toListValue()
            ?.mapNotNull(toValue)
            .toList() ??
        [];

    return Fts5(
      tokenizer,
      getList(Fts5Field.tokenizerArgs, (object) => object.toStringValue()),
      getList(Fts5Field.prefixes, (object) => object.toIntValue()),
      getList(Fts5Field.notIndexed, (object) => object.toStringValue()),
    );
  }

  /// FTS5 tables have the row id as primary key and no constraints.
  void _validateFts5(
    final Fts5 fts,
    final String tableName,
    final List<Field> fields,
    final PrimaryKey primaryKey,
    final List<ForeignKey> foreignKeys,
    final List<Index> indices,
    final bool withoutRowid,
  ) {
    final primaryKeyFields = primaryKey.fields;
    if (primaryKeyFields.length != 1 ||
        // exactly, as the row id is returned as rowid regardless of its case
        primaryKeyFields.single.columnName != Fts5.rowidColumnName ||
        primaryKeyFields.single.sqlType != SqlType.integer) {
      throw _processorError.fts5PrimaryKeyIsNotRowid;
    }

    // the primary key, which isn't a column of the FTS5 table
    final columnNames = fields
        .map((field) => field.columnName)
        .where((columnName) => columnName != Fts5.rowidColumnName)
        .toList();
    if (columnNames.isEmpty) throw _processorError.fts5WithoutColumns;

    // FTS5 tables have hidden columns of these names
    final reservedColumns = columnNames
        .where((columnName) => {
              Fts5.rowidColumnName,
              'rank',
              tableName.toLowerCase(),
            }
            .contains(columnName.toLowerCase()))
        .toList();
    if (reservedColumns.isNotEmpty) {
      throw _processorError.fts5ReservedColumns(reservedColumns);
    }

    // tokenizers of FTS3 and FTS4 only
    if (const {annotations.FtsTokenizer.simple, annotations.FtsTokenizer.icu}
        .contains(fts.tokenizer.toLowerCase())) {
      throw _processorError.fts5UnsupportedTokenizer(fts.tokenizer);
    }

    // https://www.sqlite.org/fts5.html#prefix_indexes
    if (fts.prefixes.any((prefix) => prefix < 1 || prefix > 999)) {
      throw _processorError.fts5InvalidPrefixes(fts.prefixes);
    }

    final lowerCaseColumnNames =
        columnNames.map((columnName) => columnName.toLowerCase()).toSet();
    final unknownColumns = fts.notIndexed
        .where((columnName) =>
            !lowerCaseColumnNames.contains(columnName.toLowerCase()))
        .toList();
    if (unknownColumns.isNotEmpty) {
      throw _processorError.fts5UnknownNotIndexedColumns(unknownColumns);
    }

    if (foreignKeys.isNotEmpty || indices.isNotEmpty || withoutRowid) {
      throw _processorError.fts5TableConstraints;
    }
  }

  List<Index> _getIndices(final List<Field> fields, final String tableName) {
    return classElement
            .getAnnotation(annotations.Entity)
            ?.getField(AnnotationField.entityIndices)
            ?.toListValue()
            ?.map((indexObject) {
          final unique = indexObject.getField(IndexField.unique)?.toBoolValue();
          // can't happen as Index.unique is non-nullable
          if (unique == null) throw ArgumentError.notNull();

          final indexColumnNames = indexObject
              .getField(IndexField.value)
              ?.toListValue()
              ?.mapNotNull((valueObject) => valueObject.toStringValue())
              .toList();

          if (indexColumnNames == null || indexColumnNames.isEmpty) {
            throw _processorError.missingIndexColumnName;
          }

          final expressions = <String>{};
          for (final indexColumnName in indexColumnNames) {
            if (fields.any((field) => field.columnName == indexColumnName)) {
              continue;
            }
            // anything else than a plain name is an expression like `y + z`
            if (RegExp(r'\W').hasMatch(indexColumnName)) {
              expressions.add(indexColumnName);
            } else {
              throw _processorError.noMatchingColumn(indexColumnName);
            }
          }

          final name = indexObject.getField(IndexField.name)?.toStringValue() ??
              _generateIndexName(tableName, indexColumnNames, expressions);

          final where = indexObject.getField(IndexField.where)?.toStringValue();

          return Index(
            name,
            tableName,
            unique,
            indexColumnNames,
            where: where != null && where.trim().isNotEmpty ? where : null,
            expressions: expressions,
          );
        }).toList() ??
        [];
  }

  String _generateIndexName(
    final String tableName,
    final List<String> columnNames,
    final Set<String> expressions,
  ) {
    // expressions can contain any characters
    final names = columnNames.map((columnName) =>
        expressions.contains(columnName)
            ? columnName.replaceAll(RegExp(r'\W+'), '_')
            : columnName);
    return Index.defaultPrefix + tableName + '_' + names.join('_');
  }

  List<String> _getColumns(
    final DartObject object,
    final String foreignKeyField,
  ) {
    return object
            .getField(foreignKeyField)
            ?.toListValue()
            ?.mapNotNull((object) => object.toStringValue())
            .toList() ??
        [];
  }

  PrimaryKey _getPrimaryKey(final List<Field> fields) {
    final compoundPrimaryKey = _getCompoundPrimaryKey(fields);

    if (compoundPrimaryKey != null) {
      return compoundPrimaryKey;
    } else {
      return _getPrimaryKeyFromAnnotation(fields);
    }
  }

  PrimaryKey? _getCompoundPrimaryKey(final List<Field> fields) {
    final compoundPrimaryKeyColumnNames = classElement
        .getAnnotation(annotations.Entity)
        ?.getField(AnnotationField.entityPrimaryKeys)
        ?.toListValue()
        ?.map((object) => object.toStringValue());

    if (compoundPrimaryKeyColumnNames == null ||
        compoundPrimaryKeyColumnNames.isEmpty) {
      return null;
    }

    for (final primaryKeyColumnName in compoundPrimaryKeyColumnNames) {
      if (!fields.any((field) => field.columnName == primaryKeyColumnName)) {
        throw _processorError.noMatchingPrimaryKeyColumn(
          primaryKeyColumnName ?? 'null',
        );
      }
    }

    final compoundPrimaryKeyFields = fields.where((field) {
      return compoundPrimaryKeyColumnNames.any(
          (primaryKeyColumnName) => field.columnName == primaryKeyColumnName);
    }).toList();

    return PrimaryKey(compoundPrimaryKeyFields, false);
  }

  PrimaryKey _getPrimaryKeyFromAnnotation(final List<Field> fields) {
    final primaryKeyField = fields.firstWhere(
        (field) => field.fieldElement.hasAnnotation(annotations.PrimaryKey),
        orElse: () => throw _processorError.missingPrimaryKey);

    final autoGenerate = primaryKeyField.fieldElement
            .getAnnotation(annotations.PrimaryKey)
            ?.getField(AnnotationField.primaryKeyAutoGenerate)
            ?.toBoolValue() ??
        false;

    return PrimaryKey([primaryKeyField], autoGenerate);
  }

  bool _getWithoutRowid() {
    return classElement
            .getAnnotation(annotations.Entity)
            ?.getField(AnnotationField.entityWithoutRowid)
            ?.toBoolValue() ??
        false;
  }

  annotations.ForeignKeyAction _getForeignKeyAction(
    DartObject foreignKeyObject,
    String triggerName,
  ) {
    final field = foreignKeyObject.getField(triggerName);
    if (field == null) {
      // field was not defined, return default value
      return annotations.ForeignKeyAction.noAction;
    }

    final foreignKeyAction = field.toForeignKeyAction();
    if (foreignKeyAction == null) {
      throw _processorError.wrongForeignKeyAction(field, triggerName);
    } else {
      return foreignKeyAction;
    }
  }
}
