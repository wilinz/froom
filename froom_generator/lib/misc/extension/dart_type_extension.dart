import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

extension DartTypeExtension on DartType {
  /// Whether this [DartType] is nullable
  bool get isNullable {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
      case NullabilitySuffix.star: // support legacy code without non-nullables
        return true;
      case NullabilitySuffix.none:
        return false;
    }
  }

  /// Enhanced getDisplayString method that handles the deprecated withNullability parameter
  /// and provides backward compatibility for analyzer 7.x migration
  String getDisplayStringCompat({bool withNullability = true}) {
    final displayString = getDisplayString();
    if (!withNullability) {
      // Remove trailing ? if present when withNullability is false
      return displayString.endsWith('?') 
          ? displayString.substring(0, displayString.length - 1)
          : displayString;
    }
    return displayString;
  }
}
