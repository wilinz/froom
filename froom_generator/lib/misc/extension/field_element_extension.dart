import 'package:analyzer/dart/element/element.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/constants.dart';
import 'package:froom_generator/misc/type_utils.dart';

extension FieldElementExtension on FieldElement {
  /// The name of the database column of this field, which is either the name
  /// declared by `@ColumnInfo` or the field name.
  String get columnName {
    return getAnnotation(annotations.ColumnInfo)
            ?.getField(AnnotationField.columnInfoName)
            ?.toStringValue() ??
        name!;
  }
}
