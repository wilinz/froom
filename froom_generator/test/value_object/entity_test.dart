import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/extension/foreign_key_action_extension.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/field.dart';
import 'package:froom_generator/value_object/foreign_key.dart';
import 'package:froom_generator/value_object/fts.dart';
import 'package:froom_generator/value_object/primary_key.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  final fakeClassElement = FakeClassElement();
  final fakeFieldElement = FakeFieldElement();

  final field = Field(
    fakeFieldElement,
    'field1Name',
    'field1ColumnName',
    false,
    SqlType.integer,
    null,
  );
  final nullableField = Field(
    fakeFieldElement,
    'field2Name',
    'field2ColumnName',
    true,
    SqlType.text,
    null,
  );
  final allFields = [field, nullableField];

  group('Primary key', () {
    test('Create table statement with single primary key auto increment', () {
      final primaryKey = PrimaryKey([field], true);
      final entity = Entity(
        fakeClassElement,
        'entityName',
        allFields,
        primaryKey,
        [],
        [],
        false,
        '',
        '',
        null,
      );

      final actual = entity.getCreateTableStatement();

      final expected = 'CREATE TABLE IF NOT EXISTS `${entity.name}` '
          '(`${field.columnName}` ${field.sqlType} PRIMARY KEY AUTOINCREMENT NOT NULL, '
          '`${nullableField.columnName}` ${nullableField.sqlType}'
          ')';
      expect(actual, equals(expected));
    });

    test('Create table statement with single primary key', () {
      final primaryKey = PrimaryKey([field], false);
      final entity = Entity(
        fakeClassElement,
        'entityName',
        allFields,
        primaryKey,
        [],
        [],
        false,
        '',
        '',
        null,
      );

      final actual = entity.getCreateTableStatement();

      final expected = 'CREATE TABLE IF NOT EXISTS `${entity.name}` '
          '(`${field.columnName}` ${field.sqlType} NOT NULL, '
          '`${nullableField.columnName}` ${nullableField.sqlType}, '
          'PRIMARY KEY (`${field.columnName}`)'
          ')';
      expect(actual, equals(expected));
    });

    test('Create table statement with compound primary key', () {
      final primaryKey = PrimaryKey(allFields, false);
      final entity = Entity(
        fakeClassElement,
        'entityName',
        allFields,
        primaryKey,
        [],
        [],
        false,
        '',
        '',
        null,
      );

      final actual = entity.getCreateTableStatement();

      final expected = 'CREATE TABLE IF NOT EXISTS `${entity.name}` '
          '(`${field.columnName}` ${field.sqlType} NOT NULL, '
          '`${nullableField.columnName}` ${nullableField.sqlType}, '
          'PRIMARY KEY (`${field.columnName}`, `${nullableField.columnName}`)'
          ')';
      expect(actual, equals(expected));
    });
  });

  group('Foreign key', () {
    test('Create table statement with foreign key', () {
      final foreignKey = ForeignKey(
        'parentName',
        ['parentColumn'],
        ['childColumn'],
        annotations.ForeignKeyAction.cascade,
        annotations.ForeignKeyAction.noAction,
      );
      final primaryKey = PrimaryKey([nullableField], true);
      final entity = Entity(
        fakeClassElement,
        'entityName',
        [nullableField],
        primaryKey,
        [foreignKey],
        [],
        false,
        '',
        '',
        null,
      );

      final actual = entity.getCreateTableStatement();

      final expected = 'CREATE TABLE IF NOT EXISTS `${entity.name}` '
          '(`${nullableField.columnName}` ${nullableField.sqlType} PRIMARY KEY AUTOINCREMENT, '
          'FOREIGN KEY (`${foreignKey.childColumns[0]}`) '
          'REFERENCES `${foreignKey.parentName}` '
          '(`${foreignKey.parentColumns[0]}`) '
          'ON UPDATE ${foreignKey.onUpdate.toSql()} '
          'ON DELETE ${foreignKey.onDelete.toSql()}'
          ')';
      expect(actual, equals(expected));
    });
  });

  group('Fts key', () {
    test('Create table statement with fts key', () {
      final fts = Fts4(
        'porter',
        [],
      );
      final primaryKey = PrimaryKey([], true);
      final entity = Entity(
        fakeClassElement,
        'entityName',
        [nullableField],
        primaryKey,
        [],
        [],
        false,
        '',
        '',
        fts,
      );

      final actual = entity.getCreateTableStatement();

      final expected = 'CREATE VIRTUAL TABLE IF NOT EXISTS `${entity.name}` '
          'USING fts4'
          '(`${nullableField.columnName}` ${nullableField.sqlType}, '
          'tokenize=porter '
          ')';
      expect(actual, equals(expected));
    });
  });

  test('Create table statement with "WITHOUT ROWID"', () {
    final primaryKey = PrimaryKey([field], false);
    final entity = Entity(
      fakeClassElement,
      'entityName',
      allFields,
      primaryKey,
      [],
      [],
      true,
      '',
      '',
      null,
    );

    final actual = entity.getCreateTableStatement();

    final expected = 'CREATE TABLE IF NOT EXISTS `${entity.name}` '
        '(`${field.columnName}` ${field.sqlType} NOT NULL, '
        '`${nullableField.columnName}` ${nullableField.sqlType}, '
        'PRIMARY KEY (`${field.columnName}`)'
        ') WITHOUT ROWID';
    expect(actual, equals(expected));
  });
}
