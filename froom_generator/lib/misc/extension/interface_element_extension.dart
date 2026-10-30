import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

extension InterfaceElementExtension on InterfaceElement {
  /// All supertypes ordered from the closest to the most distant one, where
  /// later mixins come before earlier ones, as they override them.
  ///
  /// Like Dart's member lookup, the superclasses and their mixins come first,
  /// as only they provide implementations, followed by the interfaces.
  List<InterfaceType> get supertypesClosestFirst {
    List<InterfaceType> directSupertypesOf(final InterfaceType type) => [
          ...type.mixins.reversed,
          if (type.superclass != null) type.superclass!,
          ...type.interfaces,
        ];

    final superclasses = <InterfaceType>[];
    for (InterfaceType? type = thisType;
        type != null;
        type = type.superclass) {
      superclasses.addAll(type.mixins.reversed);
      if (type.superclass != null) superclasses.add(type.superclass!);
    }

    final visited = <InterfaceElement>{};
    final supertypes = [...superclasses, ...directSupertypesOf(thisType)];
    final result = <InterfaceType>[];
    for (var index = 0; index < supertypes.length; index++) {
      final supertype = supertypes[index];
      if (!visited.add(supertype.element)) continue;
      result.add(supertype);
      supertypes.addAll(directSupertypesOf(supertype));
    }
    return result;
  }
}
