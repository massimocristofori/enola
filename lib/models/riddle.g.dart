// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riddle.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRiddleCollection on Isar {
  IsarCollection<Riddle> get riddles => this.collection();
}

const RiddleSchema = CollectionSchema(
  name: r'Riddle',
  id: 531918094386802516,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'mapId': PropertySchema(
      id: 1,
      name: r'mapId',
      type: IsarType.long,
    ),
    r'mcChoicesJson': PropertySchema(
      id: 2,
      name: r'mcChoicesJson',
      type: IsarType.string,
    ),
    r'mcCorrectIndex': PropertySchema(
      id: 3,
      name: r'mcCorrectIndex',
      type: IsarType.long,
    ),
    r'orderInMap': PropertySchema(
      id: 4,
      name: r'orderInMap',
      type: IsarType.long,
    ),
    r'orderItemsJson': PropertySchema(
      id: 5,
      name: r'orderItemsJson',
      type: IsarType.string,
    ),
    r'question': PropertySchema(
      id: 6,
      name: r'question',
      type: IsarType.string,
    ),
    r'sourceText': PropertySchema(
      id: 7,
      name: r'sourceText',
      type: IsarType.string,
    ),
    r'typeIndex': PropertySchema(
      id: 8,
      name: r'typeIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _riddleEstimateSize,
  serialize: _riddleSerialize,
  deserialize: _riddleDeserialize,
  deserializeProp: _riddleDeserializeProp,
  idName: r'id',
  indexes: {
    r'mapId': IndexSchema(
      id: -6043270103971104264,
      name: r'mapId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mapId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _riddleGetId,
  getLinks: _riddleGetLinks,
  attach: _riddleAttach,
  version: '3.1.0+1',
);

int _riddleEstimateSize(
  Riddle object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.mcChoicesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.orderItemsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.question.length * 3;
  {
    final value = object.sourceText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _riddleSerialize(
  Riddle object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.mapId);
  writer.writeString(offsets[2], object.mcChoicesJson);
  writer.writeLong(offsets[3], object.mcCorrectIndex);
  writer.writeLong(offsets[4], object.orderInMap);
  writer.writeString(offsets[5], object.orderItemsJson);
  writer.writeString(offsets[6], object.question);
  writer.writeString(offsets[7], object.sourceText);
  writer.writeLong(offsets[8], object.typeIndex);
}

Riddle _riddleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Riddle();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.mapId = reader.readLong(offsets[1]);
  object.mcChoicesJson = reader.readStringOrNull(offsets[2]);
  object.mcCorrectIndex = reader.readLongOrNull(offsets[3]);
  object.orderInMap = reader.readLong(offsets[4]);
  object.orderItemsJson = reader.readStringOrNull(offsets[5]);
  object.question = reader.readString(offsets[6]);
  object.sourceText = reader.readStringOrNull(offsets[7]);
  object.typeIndex = reader.readLong(offsets[8]);
  return object;
}

P _riddleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _riddleGetId(Riddle object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _riddleGetLinks(Riddle object) {
  return [];
}

void _riddleAttach(IsarCollection<dynamic> col, Id id, Riddle object) {
  object.id = id;
}

extension RiddleQueryWhereSort on QueryBuilder<Riddle, Riddle, QWhere> {
  QueryBuilder<Riddle, Riddle, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhere> anyMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'mapId'),
      );
    });
  }
}

extension RiddleQueryWhere on QueryBuilder<Riddle, Riddle, QWhereClause> {
  QueryBuilder<Riddle, Riddle, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> mapIdEqualTo(int mapId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mapId',
        value: [mapId],
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> mapIdNotEqualTo(int mapId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mapId',
              lower: [],
              upper: [mapId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mapId',
              lower: [mapId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mapId',
              lower: [mapId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mapId',
              lower: [],
              upper: [mapId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> mapIdGreaterThan(
    int mapId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mapId',
        lower: [mapId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> mapIdLessThan(
    int mapId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mapId',
        lower: [],
        upper: [mapId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterWhereClause> mapIdBetween(
    int lowerMapId,
    int upperMapId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mapId',
        lower: [lowerMapId],
        includeLower: includeLower,
        upper: [upperMapId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RiddleQueryFilter on QueryBuilder<Riddle, Riddle, QFilterCondition> {
  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mapIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mapId',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mapIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mapId',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mapIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mapId',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mapIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mapId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mcChoicesJson',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mcChoicesJson',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcChoicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mcChoicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mcChoicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mcChoicesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mcChoicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mcChoicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mcChoicesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mcChoicesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcChoicesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcChoicesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition>
      mcChoicesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mcChoicesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcCorrectIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mcCorrectIndex',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition>
      mcCorrectIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mcCorrectIndex',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcCorrectIndexEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mcCorrectIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcCorrectIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mcCorrectIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcCorrectIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mcCorrectIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> mcCorrectIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mcCorrectIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderInMapEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderInMap',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderInMapGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderInMap',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderInMapLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderInMap',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderInMapBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderInMap',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderItemsJson',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition>
      orderItemsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderItemsJson',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderItemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderItemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderItemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderItemsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderItemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderItemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderItemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderItemsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> orderItemsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderItemsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition>
      orderItemsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderItemsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'question',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'question',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'question',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> questionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'question',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceText',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceText',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceText',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> sourceTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceText',
        value: '',
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> typeIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> typeIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> typeIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterFilterCondition> typeIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RiddleQueryObject on QueryBuilder<Riddle, Riddle, QFilterCondition> {}

extension RiddleQueryLinks on QueryBuilder<Riddle, Riddle, QFilterCondition> {}

extension RiddleQuerySortBy on QueryBuilder<Riddle, Riddle, QSortBy> {
  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByMapIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByMcChoicesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcChoicesJson', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByMcChoicesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcChoicesJson', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByMcCorrectIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcCorrectIndex', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByMcCorrectIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcCorrectIndex', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByOrderInMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderInMap', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByOrderInMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderInMap', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByOrderItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderItemsJson', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByOrderItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderItemsJson', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByQuestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByQuestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortBySourceText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortBySourceTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIndex', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> sortByTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIndex', Sort.desc);
    });
  }
}

extension RiddleQuerySortThenBy on QueryBuilder<Riddle, Riddle, QSortThenBy> {
  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByMapIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByMcChoicesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcChoicesJson', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByMcChoicesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcChoicesJson', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByMcCorrectIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcCorrectIndex', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByMcCorrectIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mcCorrectIndex', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByOrderInMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderInMap', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByOrderInMapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderInMap', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByOrderItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderItemsJson', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByOrderItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderItemsJson', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByQuestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByQuestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenBySourceText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenBySourceTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.desc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIndex', Sort.asc);
    });
  }

  QueryBuilder<Riddle, Riddle, QAfterSortBy> thenByTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIndex', Sort.desc);
    });
  }
}

extension RiddleQueryWhereDistinct on QueryBuilder<Riddle, Riddle, QDistinct> {
  QueryBuilder<Riddle, Riddle, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mapId');
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByMcChoicesJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mcChoicesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByMcCorrectIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mcCorrectIndex');
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByOrderInMap() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderInMap');
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByOrderItemsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderItemsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByQuestion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'question', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctBySourceText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Riddle, Riddle, QDistinct> distinctByTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeIndex');
    });
  }
}

extension RiddleQueryProperty on QueryBuilder<Riddle, Riddle, QQueryProperty> {
  QueryBuilder<Riddle, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Riddle, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Riddle, int, QQueryOperations> mapIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mapId');
    });
  }

  QueryBuilder<Riddle, String?, QQueryOperations> mcChoicesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mcChoicesJson');
    });
  }

  QueryBuilder<Riddle, int?, QQueryOperations> mcCorrectIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mcCorrectIndex');
    });
  }

  QueryBuilder<Riddle, int, QQueryOperations> orderInMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderInMap');
    });
  }

  QueryBuilder<Riddle, String?, QQueryOperations> orderItemsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderItemsJson');
    });
  }

  QueryBuilder<Riddle, String, QQueryOperations> questionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'question');
    });
  }

  QueryBuilder<Riddle, String?, QQueryOperations> sourceTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceText');
    });
  }

  QueryBuilder<Riddle, int, QQueryOperations> typeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeIndex');
    });
  }
}
