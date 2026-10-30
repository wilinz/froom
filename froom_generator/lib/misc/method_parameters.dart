import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/misc/extension/dart_type_extension.dart';

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

        final defaultValue = parameterElement.defaultValueCode;
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

/// The arguments for calling a method with [parameters] by passing on the
/// parameters of the same names.
String getArgumentsOf(final Iterable<FormalParameterElement> parameters) {
  return parameters.map((parameter) {
    final name = parameter.name!;
    return parameter.isNamed ? '$name: $name' : name;
  }).join(', ');
}
