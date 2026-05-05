// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlaySessionCollection on Isar {
  IsarCollection<PlaySession> get playSessions => this.collection();
}

const PlaySessionSchema = CollectionSchema(
  name: r'PlaySession',
  id: -297187889808848330,
  properties: {
    r'completedAt': PropertySchema(
      id: 0,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'correctAnswers': PropertySchema(
      id: 1,
      name: r'correctAnswers',
      type: IsarType.long,
    ),
    r'isCompleted': PropertySchema(
      id: 2,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'mapId': PropertySchema(
      id: 3,
      name: r'mapId',
      type: IsarType.long,
    ),
    r'scorePercent': PropertySchema(
      id: 4,
      name: r'scorePercent',
      type: IsarType.double,
    ),
    r'startedAt': PropertySchema(
      id: 5,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'totalRiddles': PropertySchema(
      id: 6,
      name: r'totalRiddles',
      type: IsarType.long,
    )
  },
  estimateSize: _playSessionEstimateSize,
  serialize: _playSessionSerialize,
  deserialize: _playSessionDeserialize,
  deserializeProp: _playSessionDeserializeProp,
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
  getId: _playSessionGetId,
  getLinks: _playSessionGetLinks,
  attach: _playSessionAttach,
  version: '3.1.0+1',
);

int _playSessionEstimateSize(
  PlaySession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _playSessionSerialize(
  PlaySession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.completedAt);
  writer.writeLong(offsets[1], object.correctAnswers);
  writer.writeBool(offsets[2], object.isCompleted);
  writer.writeLong(offsets[3], object.mapId);
  writer.writeDouble(offsets[4], object.scorePercent);
  writer.writeDateTime(offsets[5], object.startedAt);
  writer.writeLong(offsets[6], object.totalRiddles);
}

PlaySession _playSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaySession(
    mapId: reader.readLong(offsets[3]),
    totalRiddles: reader.readLong(offsets[6]),
  );
  object.completedAt = reader.readDateTimeOrNull(offsets[0]);
  object.correctAnswers = reader.readLong(offsets[1]);
  object.id = id;
  object.startedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _playSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playSessionGetId(PlaySession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playSessionGetLinks(PlaySession object) {
  return [];
}

void _playSessionAttach(
    IsarCollection<dynamic> col, Id id, PlaySession object) {
  object.id = id;
}

extension PlaySessionQueryWhereSort
    on QueryBuilder<PlaySession, PlaySession, QWhere> {
  QueryBuilder<PlaySession, PlaySession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterWhere> anyMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'mapId'),
      );
    });
  }
}

extension PlaySessionQueryWhere
    on QueryBuilder<PlaySession, PlaySession, QWhereClause> {
  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> idBetween(
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

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> mapIdEqualTo(
      int mapId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mapId',
        value: [mapId],
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> mapIdNotEqualTo(
      int mapId) {
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

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> mapIdGreaterThan(
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

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> mapIdLessThan(
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

  QueryBuilder<PlaySession, PlaySession, QAfterWhereClause> mapIdBetween(
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

extension PlaySessionQueryFilter
    on QueryBuilder<PlaySession, PlaySession, QFilterCondition> {
  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      completedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      correctAnswersEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctAnswers',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      correctAnswersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctAnswers',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      correctAnswersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctAnswers',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      correctAnswersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctAnswers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> mapIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mapId',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      mapIdGreaterThan(
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

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> mapIdLessThan(
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

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition> mapIdBetween(
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

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      scorePercentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scorePercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      scorePercentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scorePercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      scorePercentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scorePercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      scorePercentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scorePercent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      totalRiddlesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalRiddles',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      totalRiddlesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalRiddles',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      totalRiddlesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalRiddles',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterFilterCondition>
      totalRiddlesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalRiddles',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PlaySessionQueryObject
    on QueryBuilder<PlaySession, PlaySession, QFilterCondition> {}

extension PlaySessionQueryLinks
    on QueryBuilder<PlaySession, PlaySession, QFilterCondition> {}

extension PlaySessionQuerySortBy
    on QueryBuilder<PlaySession, PlaySession, QSortBy> {
  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByCorrectAnswers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswers', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy>
      sortByCorrectAnswersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswers', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByMapIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByScorePercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorePercent', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy>
      sortByScorePercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorePercent', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> sortByTotalRiddles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRiddles', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy>
      sortByTotalRiddlesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRiddles', Sort.desc);
    });
  }
}

extension PlaySessionQuerySortThenBy
    on QueryBuilder<PlaySession, PlaySession, QSortThenBy> {
  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByCorrectAnswers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswers', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy>
      thenByCorrectAnswersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswers', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByMapIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapId', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByScorePercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorePercent', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy>
      thenByScorePercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorePercent', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy> thenByTotalRiddles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRiddles', Sort.asc);
    });
  }

  QueryBuilder<PlaySession, PlaySession, QAfterSortBy>
      thenByTotalRiddlesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalRiddles', Sort.desc);
    });
  }
}

extension PlaySessionQueryWhereDistinct
    on QueryBuilder<PlaySession, PlaySession, QDistinct> {
  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByCorrectAnswers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctAnswers');
    });
  }

  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByMapId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mapId');
    });
  }

  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByScorePercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scorePercent');
    });
  }

  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<PlaySession, PlaySession, QDistinct> distinctByTotalRiddles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalRiddles');
    });
  }
}

extension PlaySessionQueryProperty
    on QueryBuilder<PlaySession, PlaySession, QQueryProperty> {
  QueryBuilder<PlaySession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlaySession, DateTime?, QQueryOperations> completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<PlaySession, int, QQueryOperations> correctAnswersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctAnswers');
    });
  }

  QueryBuilder<PlaySession, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<PlaySession, int, QQueryOperations> mapIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mapId');
    });
  }

  QueryBuilder<PlaySession, double, QQueryOperations> scorePercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scorePercent');
    });
  }

  QueryBuilder<PlaySession, DateTime, QQueryOperations> startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<PlaySession, int, QQueryOperations> totalRiddlesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalRiddles');
    });
  }
}
