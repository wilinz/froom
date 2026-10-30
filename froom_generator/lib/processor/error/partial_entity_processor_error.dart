import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class PartialEntityProcessorError {
  final ClassElement _classElement;
  final String _entityName;

  PartialEntityProcessorError(this._classElement, this._entityName);

  InvalidGenerationSourceError get noColumns {
    return InvalidGenerationSourceError(
      'The partial entity ${_classElement.displayName} does not contain any column of $_entityName.',
      todo: 'Add fields matching the columns of $_entityName.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError unknownColumn(final FieldElement fieldElement) {
    return InvalidGenerationSourceError(
      'The field ${fieldElement.displayName} of the partial entity ${_classElement.displayName} does not match any column of $_entityName.',
      todo:
          'Make the field name or @ColumnInfo name match a column of $_entityName or annotate the field with @ignore.',
      element: fieldElement,
    );
  }

  InvalidGenerationSourceError duplicateColumn(final FieldElement fieldElement) {
    return InvalidGenerationSourceError(
      'The field ${fieldElement.displayName} of the partial entity ${_classElement.displayName} maps to a column of $_entityName another field maps to already.',
      todo: 'Map each column of $_entityName to a single field.',
      element: fieldElement,
    );
  }

  InvalidGenerationSourceError columnTypeMismatch(
    final FieldElement fieldElement,
  ) {
    return InvalidGenerationSourceError(
      'The field ${fieldElement.displayName} of the partial entity ${_classElement.displayName} does not have the same type as the column in $_entityName.',
      element: fieldElement,
    );
  }

  InvalidGenerationSourceError typeConverterMismatch(
    final FieldElement fieldElement,
  ) {
    return InvalidGenerationSourceError(
      'The field ${fieldElement.displayName} of the partial entity ${_classElement.displayName} does not use the same type converter as the column in $_entityName.',
      todo:
          'Remove the type converter from the field, the converter of the column in $_entityName is used.',
      element: fieldElement,
    );
  }

  InvalidGenerationSourceError nullabilityMismatch(
    final FieldElement fieldElement,
  ) {
    return InvalidGenerationSourceError(
      'The field ${fieldElement.displayName} of the partial entity ${_classElement.displayName} is nullable, but the column is not nullable in $_entityName.',
      todo: 'Make the field non-nullable.',
      element: fieldElement,
    );
  }

  InvalidGenerationSourceError missingPrimaryKeys(
    final List<String> columnNames,
  ) {
    return InvalidGenerationSourceError(
      'The partial entity ${_classElement.displayName} is missing the primary key columns ${columnNames.join(', ')} of $_entityName.',
      todo:
          'Add the primary key fields to the partial entity, the primary key is required to update existing rows.',
      element: _classElement,
    );
  }

  InvalidGenerationSourceError missingRequiredColumns(
    final List<String> columnNames,
  ) {
    return InvalidGenerationSourceError(
      'The partial entity ${_classElement.displayName} is missing the non-nullable columns ${columnNames.join(', ')} of $_entityName.',
      todo:
          'Add the fields to the partial entity, otherwise inserting it fails with a NOT NULL constraint.',
      element: _classElement,
    );
  }
}
