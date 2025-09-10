import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

import 'package:pub_semver/src/version.dart';

class FakeClassElement implements ClassElement {
  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    throw UnimplementedError();
  }

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    throw UnimplementedError();
  }

  @override
  List<InterfaceType> get allSupertypes => throw UnimplementedError();

  @override
  InstanceElement get baseElement => throw UnimplementedError();

  @override
  List<Element> get children => throw UnimplementedError();

  @override
  List<Element> get children2 => throw UnimplementedError();

  @override
  List<ConstructorElement> get constructors => throw UnimplementedError();

  @override
  List<ConstructorElement> get constructors2 => throw UnimplementedError();

  @override
  String get displayName => throw UnimplementedError();

  @override
  String displayString({bool multiline = false, bool preferTypeAlias = false}) {
    throw UnimplementedError();
  }

  @override
  String displayString2(
      {bool multiline = false, bool preferTypeAlias = false}) {
    throw UnimplementedError();
  }

  @override
  String? get documentationComment => throw UnimplementedError();

  @override
  LibraryElement get enclosingElement => throw UnimplementedError();

  @override
  LibraryElement get enclosingElement2 => throw UnimplementedError();

  @override
  List<FieldElement> get fields => throw UnimplementedError();

  @override
  List<FieldElement> get fields2 => throw UnimplementedError();

  @override
  ClassFragment get firstFragment => throw UnimplementedError();

  @override
  List<ClassFragment> get fragments => throw UnimplementedError();

  @override
  String getExtendedDisplayName({String? shortName}) {
    throw UnimplementedError();
  }

  @override
  String getExtendedDisplayName2({String? shortName}) {
    throw UnimplementedError();
  }

  @override
  FieldElement? getField(String name) {
    throw UnimplementedError();
  }

  @override
  FieldElement? getField2(String name) {
    throw UnimplementedError();
  }

  @override
  GetterElement? getGetter(String name) {
    throw UnimplementedError();
  }

  @override
  GetterElement? getGetter2(String name) {
    throw UnimplementedError();
  }

  @override
  ExecutableElement? getInheritedConcreteMember(Name name) {
    throw UnimplementedError();
  }

  @override
  ExecutableElement? getInheritedMember(Name name) {
    throw UnimplementedError();
  }

  @override
  ExecutableElement? getInterfaceMember(Name name) {
    throw UnimplementedError();
  }

  @override
  MethodElement? getMethod(String name) {
    throw UnimplementedError();
  }

  @override
  MethodElement? getMethod2(String name) {
    throw UnimplementedError();
  }

  @override
  ConstructorElement? getNamedConstructor(String name) {
    throw UnimplementedError();
  }

  @override
  ConstructorElement? getNamedConstructor2(String name) {
    throw UnimplementedError();
  }

  @override
  List<ExecutableElement>? getOverridden(Name name) {
    throw UnimplementedError();
  }

  @override
  SetterElement? getSetter(String name) {
    throw UnimplementedError();
  }

  @override
  SetterElement? getSetter2(String name) {
    throw UnimplementedError();
  }

  @override
  List<GetterElement> get getters => throw UnimplementedError();

  @override
  List<GetterElement> get getters2 => throw UnimplementedError();

  @override
  bool get hasNonFinalField => throw UnimplementedError();

  @override
  int get id => throw UnimplementedError();

  @override
  Map<Name, ExecutableElement> get inheritedConcreteMembers =>
      throw UnimplementedError();

  @override
  Map<Name, ExecutableElement> get inheritedMembers =>
      throw UnimplementedError();

  @override
  InterfaceType instantiate(
      {required List<DartType> typeArguments,
      required NullabilitySuffix nullabilitySuffix}) {
    throw UnimplementedError();
  }

  @override
  Map<Name, ExecutableElement> get interfaceMembers =>
      throw UnimplementedError();

  @override
  List<InterfaceType> get interfaces => throw UnimplementedError();

  @override
  bool get isAbstract => throw UnimplementedError();

  @override
  bool isAccessibleIn(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool isAccessibleIn2(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool get isBase => throw UnimplementedError();

  @override
  bool get isConstructable => throw UnimplementedError();

  @override
  bool get isDartCoreEnum => throw UnimplementedError();

  @override
  bool get isDartCoreObject => throw UnimplementedError();

  @override
  bool get isExhaustive => throw UnimplementedError();

  @override
  bool isExtendableIn(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool isExtendableIn2(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool get isExtendableOutside => throw UnimplementedError();

  @override
  bool get isFinal => throw UnimplementedError();

  @override
  bool isImplementableIn(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool isImplementableIn2(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool get isImplementableOutside => throw UnimplementedError();

  @override
  bool get isInterface => throw UnimplementedError();

  @override
  bool isMixableIn(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool isMixableIn2(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool get isMixableOutside => throw UnimplementedError();

  @override
  bool get isMixinApplication => throw UnimplementedError();

  @override
  bool get isMixinClass => throw UnimplementedError();

  @override
  bool get isPrivate => throw UnimplementedError();

  @override
  bool get isPublic => throw UnimplementedError();

  @override
  bool get isSealed => throw UnimplementedError();

  @override
  bool get isSimplyBounded => throw UnimplementedError();

  @override
  bool get isSynthetic => throw UnimplementedError();

  @override
  bool get isValidMixin => throw UnimplementedError();

  @override
  ElementKind get kind => throw UnimplementedError();

  @override
  LibraryElement get library => throw UnimplementedError();

  @override
  LibraryElement get library2 => throw UnimplementedError();

  @override
  MethodElement? lookUpConcreteMethod(
      String methodName, LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  GetterElement? lookUpGetter(
      {required String name, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  GetterElement? lookUpGetter2(
      {required String name, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  MethodElement? lookUpInheritedMethod(
      {required String methodName, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  MethodElement? lookUpInheritedMethod2(
      {required String methodName, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  MethodElement? lookUpMethod(
      {required String name, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  MethodElement? lookUpMethod2(
      {required String name, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  SetterElement? lookUpSetter(
      {required String name, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  SetterElement? lookUpSetter2(
      {required String name, required LibraryElement library}) {
    throw UnimplementedError();
  }

  @override
  String? get lookupName => throw UnimplementedError();

  @override
  Metadata get metadata => throw UnimplementedError();

  @override
  Metadata get metadata2 => throw UnimplementedError();

  @override
  List<MethodElement> get methods => throw UnimplementedError();

  @override
  List<MethodElement> get methods2 => throw UnimplementedError();

  @override
  List<InterfaceType> get mixins => throw UnimplementedError();

  @override
  String? get name => throw UnimplementedError();

  @override
  String? get name3 => throw UnimplementedError();

  @override
  Element get nonSynthetic => throw UnimplementedError();

  @override
  Element get nonSynthetic2 => throw UnimplementedError();

  @override
  AnalysisSession? get session => throw UnimplementedError();

  @override
  List<SetterElement> get setters => throw UnimplementedError();

  @override
  List<SetterElement> get setters2 => throw UnimplementedError();

  @override
  Version? get sinceSdkVersion => throw UnimplementedError();

  @override
  InterfaceType? get supertype => throw UnimplementedError();

  @override
  Element? thisOrAncestorMatching(bool Function(Element p1) predicate) {
    throw UnimplementedError();
  }

  @override
  Element? thisOrAncestorMatching2(bool Function(Element p1) predicate) {
    throw UnimplementedError();
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    throw UnimplementedError();
  }

  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    throw UnimplementedError();
  }

  @override
  InterfaceType get thisType => throw UnimplementedError();

  @override
  List<TypeParameterElement> get typeParameters => throw UnimplementedError();

  @override
  List<TypeParameterElement> get typeParameters2 => throw UnimplementedError();

  @override
  ConstructorElement? get unnamedConstructor => throw UnimplementedError();

  @override
  ConstructorElement? get unnamedConstructor2 => throw UnimplementedError();

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {}

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {}
}

class FakeFieldElement implements FieldElement {
  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    throw UnimplementedError();
  }

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    throw UnimplementedError();
  }

  @override
  FieldElement get baseElement => throw UnimplementedError();

  @override
  List<Element> get children => throw UnimplementedError();

  @override
  List<Element> get children2 => throw UnimplementedError();

  @override
  DartObject? computeConstantValue() {
    throw UnimplementedError();
  }

  @override
  Expression? get constantInitializer => throw UnimplementedError();

  @override
  String get displayName => throw UnimplementedError();

  @override
  String displayString({bool multiline = false, bool preferTypeAlias = false}) {
    throw UnimplementedError();
  }

  @override
  String displayString2(
      {bool multiline = false, bool preferTypeAlias = false}) {
    throw UnimplementedError();
  }

  @override
  String? get documentationComment => throw UnimplementedError();

  @override
  InstanceElement get enclosingElement => throw UnimplementedError();

  @override
  InstanceElement get enclosingElement2 => throw UnimplementedError();

  @override
  FieldFragment get firstFragment => throw UnimplementedError();

  @override
  List<FieldFragment> get fragments => throw UnimplementedError();

  @override
  String getExtendedDisplayName({String? shortName}) {
    throw UnimplementedError();
  }

  @override
  String getExtendedDisplayName2({String? shortName}) {
    throw UnimplementedError();
  }

  @override
  GetterElement? get getter => throw UnimplementedError();

  @override
  GetterElement? get getter2 => throw UnimplementedError();

  @override
  bool get hasImplicitType => throw UnimplementedError();

  @override
  bool get hasInitializer => throw UnimplementedError();

  @override
  int get id => throw UnimplementedError();

  @override
  bool get isAbstract => throw UnimplementedError();

  @override
  bool isAccessibleIn(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool isAccessibleIn2(LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  bool get isConst => throw UnimplementedError();

  @override
  bool get isCovariant => throw UnimplementedError();

  @override
  bool get isEnumConstant => throw UnimplementedError();

  @override
  bool get isExternal => throw UnimplementedError();

  @override
  bool get isFinal => throw UnimplementedError();

  @override
  bool get isLate => throw UnimplementedError();

  @override
  bool get isPrivate => throw UnimplementedError();

  @override
  bool get isPromotable => throw UnimplementedError();

  @override
  bool get isPublic => throw UnimplementedError();

  @override
  bool get isStatic => throw UnimplementedError();

  @override
  bool get isSynthetic => throw UnimplementedError();

  @override
  ElementKind get kind => throw UnimplementedError();

  @override
  LibraryElement get library => throw UnimplementedError();

  @override
  LibraryElement get library2 => throw UnimplementedError();

  @override
  String? get lookupName => throw UnimplementedError();

  @override
  Metadata get metadata => throw UnimplementedError();

  @override
  Metadata get metadata2 => throw UnimplementedError();

  @override
  String? get name => throw UnimplementedError();

  @override
  String? get name3 => throw UnimplementedError();

  @override
  Element get nonSynthetic => throw UnimplementedError();

  @override
  Element get nonSynthetic2 => throw UnimplementedError();

  @override
  AnalysisSession? get session => throw UnimplementedError();

  @override
  SetterElement? get setter => throw UnimplementedError();

  @override
  SetterElement? get setter2 => throw UnimplementedError();

  @override
  Version? get sinceSdkVersion => throw UnimplementedError();

  @override
  Element? thisOrAncestorMatching(bool Function(Element p1) predicate) {
    throw UnimplementedError();
  }

  @override
  Element? thisOrAncestorMatching2(bool Function(Element p1) predicate) {
    throw UnimplementedError();
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    throw UnimplementedError();
  }

  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    throw UnimplementedError();
  }

  @override
  DartType get type => throw UnimplementedError();

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {}

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {}
}
