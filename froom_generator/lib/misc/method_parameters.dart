import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';

extension MethodParametersExtension on MethodBuilder {
  /// Adds [parameters] as required positional, optional positional or named
  /// parameters with their default values, as overriding methods have to.
  void addParametersOf(final Iterable<FormalParameterElement> parameters) {
    for (final parameterElement in parameters) {
      final parameter = Parameter((builder) {
        builder
          ..name = parameterElement.name!
          ..type = refer(parameterElement.type.getDisplayStringCompat(
            withNullability: true,
          ))
          ..named = parameterElement.isNamed
          ..required = parameterElement.isRequiredNamed;

        final defaultValue = _getDefaultValueCode(parameterElement);
        if (defaultValue != null) {
          builder.defaultTo = Code(defaultValue);
        }
      });

      if (parameterElement.isRequiredPositional) {
        requiredParameters.add(parameter);
      } else {
        optionalParameters.add(parameter);
      }
    }
  }
}

/// The default value of [parameterElement] as literal or enum value if
/// possible, as its code can refer to constants not accessible from the
/// generated code, e.g. when the parameter is inherited from a supertype of
/// another library.
String? _getDefaultValueCode(final FormalParameterElement parameterElement) {
  final code = parameterElement.defaultValueCode;
  if (code == null) return null;

  final value = parameterElement.computeConstantValue();
  final type = value?.type;
  if (value == null || type == null) return code;
  if (value.isNull) return 'null';
  if (type.isDartCoreBool) return value.toBoolValue().toString();
  if (type.isDartCoreInt) return value.toIntValue().toString();
  if (type.isDartCoreString) return value.toStringValue().toLiteral();
  if (type.isDartCoreDouble) {
    final doubleValue = value.toDoubleValue()!;
    if (doubleValue.isFinite) return doubleValue.toString();
  }
  final enumName = value.getField('_name')?.toStringValue();
  if (type.element is EnumElement && enumName != null) {
    return '${type.element!.displayName}.$enumName';
  }
  return code;
}

/// The arguments for calling a method with [parameters] by passing on the
/// parameters of the same names.
String getArgumentsOf(final Iterable<FormalParameterElement> parameters) {
  return parameters.map((parameter) {
    final name = parameter.name!;
    return parameter.isNamed ? '$name: $name' : name;
  }).join(', ');
}
