import 'package:analyzer/dart/element/element2.dart';
import 'package:froom_annotation/froom_annotation.dart' as annotations;
import 'package:froom_generator/misc/extension/iterable_extension.dart';
import 'package:froom_generator/misc/extension/set_extension.dart';
import 'package:froom_generator/misc/extension/type_converter_element_extension.dart';
import 'package:froom_generator/misc/type_utils.dart';
import 'package:froom_generator/processor/dao_processor.dart';
import 'package:froom_generator/processor/entity_processor.dart';
import 'package:froom_generator/processor/error/database_processor_error.dart';
import 'package:froom_generator/processor/processor.dart';
import 'package:froom_generator/processor/view_processor.dart';
import 'package:froom_generator/value_object/dao_getter.dart';
import 'package:froom_generator/value_object/database.dart';
import 'package:froom_generator/value_object/entity.dart';
import 'package:froom_generator/value_object/queryable.dart';
import 'package:froom_generator/value_object/type_converter.dart';
import 'package:froom_generator/value_object/view.dart';

import '../misc/constants.dart';

// The migration is complete
class DatabaseProcessor extends Processor<Database> {
  final DatabaseProcessorError _processorError;

  final ClassElement2 _classElement;

  DatabaseProcessor(final ClassElement2 classElement)
      : _classElement = classElement,
        _processorError = DatabaseProcessorError(classElement);

  @override
  Database process() {
    final databaseName = _classElement.displayName;
    final databaseTypeConverters =
        _classElement.getTypeConverters(TypeConverterScope.database);
    final entities = _getEntities(_classElement, databaseTypeConverters);
    final views = _getViews(_classElement, databaseTypeConverters);
    final daoGetters = _getDaoGetters(
      databaseName,
      entities,
      views,
      databaseTypeConverters,
    );
    final version = _getDatabaseVersion();
    final allTypeConverters = _getAllTypeConverters(
      daoGetters,
      [...entities, ...views],
    );

    return Database(
      _classElement,
      databaseName,
      entities,
      views,
      daoGetters,
      version,
      databaseTypeConverters,
      allTypeConverters,
    );
  }

  int _getDatabaseVersion() {
    final version = _classElement
        .getAnnotation(annotations.Database)
        ?.getField(AnnotationField.databaseVersion)
        ?.toIntValue();

    if (version == null) throw _processorError.versionIsMissing;
    if (version < 1) throw _processorError.versionIsBelowOne;

    return version;
  }

  List<DaoGetter> _getDaoGetters(
    final String databaseName,
    final List<Entity> entities,
    final List<View> views,
    final Set<TypeConverter> typeConverters,
  ) {
    final result = <DaoGetter>[];

    for (final field in _classElement.fields2) {
      if (_isDao(field)) {
        final classElement = field.type.element3;
        final name = field.displayName;

        if (classElement is ClassElement2) {
          final dao = DaoProcessor(
            classElement,
            name,
            databaseName,
            entities,
            views,
            typeConverters,
          ).process();

          result.add(DaoGetter(field, name, dao));
        }
      }
    }

    return result;
  }

  bool _isDao(final FieldElement2 fieldElement) {
    final element = fieldElement.type.element3;
    return element is ClassElement2 ? _isDaoClass(element) : false;
  }

  bool _isDaoClass(final ClassElement2 classElement) {
    return classElement.hasAnnotation(annotations.dao.runtimeType) &&
        classElement.isAbstract;
  }

  List<Entity> _getEntities(
    final ClassElement2 databaseClassElement,
    final Set<TypeConverter> typeConverters,
  ) {
    final entities = _classElement
        .getAnnotation(annotations.Database)
        ?.getField(AnnotationField.databaseEntities)
        ?.toListValue()
        ?.mapNotNull((object) => object.toTypeValue()?.element3)
        .whereType<ClassElement2>()
        .where(_isEntity)
        .map((classElement) => EntityProcessor(
              classElement,
              typeConverters,
            ).process())
        .toList();

    if (entities == null || entities.isEmpty) {
      throw _processorError.noEntitiesDefined;
    }

    return entities;
  }

  List<View> _getViews(
    final ClassElement2 databaseClassElement,
    final Set<TypeConverter> typeConverters,
  ) {
    return _classElement
            .getAnnotation(annotations.Database)
            ?.getField(AnnotationField.databaseViews)
            ?.toListValue()
            ?.mapNotNull((object) => object.toTypeValue()?.element3)
            .whereType<ClassElement2>()
            .where(_isView)
            .map((classElement) => ViewProcessor(
                  classElement,
                  typeConverters,
                ).process())
            .toList() ??
        [];
  }

  Set<TypeConverter> _getAllTypeConverters(
    final List<DaoGetter> daoGetters,
    final List<Queryable> queryables,
  ) {
    // DAO query methods have access to all type converters
    final daoQueryMethodTypeConverters = daoGetters
        .expand((daoGetter) => daoGetter.dao.queryMethods)
        .expand((queryMethod) => queryMethod.typeConverters)
        .toSet();

    // but when no query methods are defined, we need to collect them differently
    final daoTypeConverters =
        daoGetters.expand((daoGetter) => daoGetter.dao.typeConverters).toSet();

    final fieldTypeConverters = queryables
        .expand((queryable) => queryable.fields)
        .mapNotNull((field) => field.typeConverter)
        .toSet();

    return daoQueryMethodTypeConverters +
        daoTypeConverters +
        fieldTypeConverters;
  }

  bool _isEntity(final ClassElement2 classElement) {
    return classElement.hasAnnotation(annotations.Entity) &&
        !classElement.isAbstract;
  }

  bool _isView(final ClassElement2 classElement) {
    return classElement.hasAnnotation(annotations.DatabaseView) &&
        !classElement.isAbstract;
  }
}
