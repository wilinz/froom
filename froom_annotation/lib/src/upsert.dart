/// Marks a method as an upsert method.
///
/// An upsert tries to insert the entity. When the insertion fails because of a
/// unique constraint conflict (e.g. the primary key already exists), the
/// existing row gets updated instead.
///
/// The method parameters have to be entities or lists of entities.
/// Multiple parameters are upserted in a single transaction.
///
/// Upsert methods can return a [Future] of `void`, `int` or `List<int>`.
/// The returned ids are the row ids of inserted entities or `-1` for entities
/// that got updated. Returning ids is only supported for methods with a single
/// parameter: `int` for a single entity and `List<int>` for a list of entities.
///
/// When [entity] is set, the parameters can be partial entities, i.e. classes
/// containing a subset of the columns of the target entity. Only the columns
/// of the partial entity get inserted or updated.
class Upsert {
  /// The target entity of the upsert method.
  ///
  /// When declared, parameters of a different type are interpreted as partial
  /// entities of it. A partial entity has to contain all non-nullable columns
  /// of the target entity and its primary key columns, unless the primary key
  /// is auto generated.
  final Type? entity;

  /// Marks a method as an upsert method.
  const Upsert({this.entity});
}

/// Marks a method as an upsert method.
const upsert = Upsert();
