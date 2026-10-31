import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

// The migration is complete
class EntityProcessorError {
  final ClassElement _classElement;

  EntityProcessorError(final ClassElement classElement)
      : _classElement = classElement;

  InvalidGenerationSourceError get missingPrimaryKey {
    return InvalidGenerationSourceError(
      'There is no primary key defined on the entity ${_classElement.displayName}.',
      todo:
          'Define a primary key for this entity with @primaryKey/@PrimaryKey() '
          'or by using the primaryKeys field of @Entity().',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get missingParentColumns {
    return InvalidGenerationSourceError(
      'No parent columns defined for foreign key.',
      todo: 'Add parent columns to the foreign key.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get missingChildColumns {
    return InvalidGenerationSourceError(
      'No child columns defined for foreign key.',
      todo: 'Add child columns to the foreign key.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get foreignKeyDoesNotReferenceEntity {
    return InvalidGenerationSourceError(
      "The foreign key doesn't reference an entity class.",
      todo: 'Make sure to add an entity to the foreign key. ',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get foreignKeyNoEntity {
    return InvalidGenerationSourceError(
      'No entity defined for foreign key',
      todo: 'Make sure to add an entity to the foreign key. ',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get missingIndexColumnName {
    return InvalidGenerationSourceError(
      'No index column name defined.',
      todo:
          "Make sure to add an index column name like: Index(values: ['foo'])').",
      element: _classElement,
    );
  }

  InvalidGenerationSourceError noMatchingPrimaryKeyColumn(
    final String columnName,
  ) {
    return InvalidGenerationSourceError(
      'No matching column found for the primary key column `$columnName` of the entity ${_classElement.displayName}.',
      todo:
          'Make sure the primaryKeys of @Entity() contain column names of the entity, e.g. the names of @ColumnInfo.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError noMatchingColumn(
    final String columnName,
  ) {
    return InvalidGenerationSourceError(
      'No matching column found for the given index. (`$columnName`)',
      todo:
          "Make sure to add a correct index column name like: Index(values: ['foo'])').",
      element: _classElement,
    );
  }

  InvalidGenerationSourceError wrongForeignKeyAction(
      DartObject field, String triggerName) {
    return InvalidGenerationSourceError(
      'No ForeignKeyAction with the value $field exists for the $triggerName trigger.',
      todo:
          'Make sure to add a correct ForeignKeyAction like `ForeignKeyAction.noAction` or leave it out entirely.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get fts5PrimaryKeyIsNotRowid {
    return InvalidGenerationSourceError(
      'The primary key of the FTS5 entity ${_classElement.displayName} is not '
      'a single integer field of the column rowid.',
      todo: "Annotate an int field with @PrimaryKey() and @ColumnInfo(name: 'rowid'), "
          'which is the row id of the FTS5 table.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get multipleFts {
    return InvalidGenerationSourceError(
      'The entity ${_classElement.displayName} has multiple FTS annotations.',
      todo: 'Keep one of @Fts3, @Fts4 and @Fts5.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get fts5WithoutColumns {
    return InvalidGenerationSourceError(
      'The FTS5 entity ${_classElement.displayName} has no columns besides its '
      'row id.',
      todo: 'Add a field for a column to index.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError fts5UnknownNotIndexedColumns(
    final List<String> columnNames,
  ) {
    return InvalidGenerationSourceError(
      'The columns ${columnNames.join(', ')} of notIndexed of the FTS5 entity '
      '${_classElement.displayName} are not columns of the entity.',
      todo: 'Use the column names of fields of the entity, except rowid.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError fts5InvalidPrefixes(final List<int> prefixes) {
    return InvalidGenerationSourceError(
      'The prefixes ${prefixes.join(', ')} of the FTS5 entity '
      '${_classElement.displayName} are not all between 1 and 999.',
      todo: 'Use prefix lengths from 1 to 999.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError fts5ReservedColumns(
    final List<String> columnNames,
  ) {
    return InvalidGenerationSourceError(
      'The columns ${columnNames.join(', ')} of the FTS5 entity '
      '${_classElement.displayName} have names reserved by FTS5, which are '
      'rowid, rank and the name of the table, ignoring case.',
      todo: 'Rename the columns, e.g. with @ColumnInfo(name: ...).',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError ftsUnsupportedTokenizer(final String tokenizer) {
    return InvalidGenerationSourceError(
      'The tokenizer $tokenizer of the FTS entity '
      "${_classElement.displayName} only exists in FTS5.",
      todo: 'Use @Fts5() or one of the FTS3 and FTS4 tokenizers simple, '
          'porter, icu or unicode61.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError fts5UnsupportedTokenizer(final String tokenizer) {
    return InvalidGenerationSourceError(
      'The tokenizer $tokenizer of the FTS5 entity '
      "${_classElement.displayName} doesn't exist in FTS5.",
      todo: 'Use one of the FTS5 tokenizers unicode61, ascii, porter or '
          'trigram.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get fts5TableConstraints {
    return InvalidGenerationSourceError(
      'The FTS5 entity ${_classElement.displayName} has indices, foreign keys '
      'or is WITHOUT ROWID, which FTS5 tables do not support.',
      todo: 'Remove indices, foreignKeys and withoutRowid from @Entity().',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError get autoIncrementInWithoutRowid {
    return InvalidGenerationSourceError(
      'autoGenerate is not allowed in WITHOUT ROWID tables',
      todo:
          'Remove autoGenerate in @PrimaryKey() or withoutRowid in @Entity().',
      element: _classElement,
    );
  }
}
