// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RiddleMapsTable extends RiddleMaps with TableInfo<$RiddleMapsTable, RiddleMap>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$RiddleMapsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _titleMeta = const VerificationMeta('title');
@override
late final GeneratedColumn<String> title = GeneratedColumn<String>('title', aliasedName, false, additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1,maxTextLength: 100), type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
@override
late final GeneratedColumn<String> description = GeneratedColumn<String>('description', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _subjectMeta = const VerificationMeta('subject');
@override
late final GeneratedColumn<String> subject = GeneratedColumn<String>('subject', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _imageBytesMeta = const VerificationMeta('imageBytes');
@override
late final GeneratedColumn<Uint8List> imageBytes = GeneratedColumn<Uint8List>('image_bytes', aliasedName, true, type: DriftSqlType.blob, requiredDuringInsert: false);
static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
@override
late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>('created_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
@override
List<GeneratedColumn> get $columns => [id, title, description, subject, imageBytes, createdAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'riddle_maps';
@override
VerificationContext validateIntegrity(Insertable<RiddleMap> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));} else if (isInserting) {
context.missing(_idMeta);
}
if (data.containsKey('title')) {
context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));} else if (isInserting) {
context.missing(_titleMeta);
}
if (data.containsKey('description')) {
context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));}if (data.containsKey('subject')) {
context.handle(_subjectMeta, subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));}if (data.containsKey('image_bytes')) {
context.handle(_imageBytesMeta, imageBytes.isAcceptableOrUnknown(data['image_bytes']!, _imageBytesMeta));}if (data.containsKey('created_at')) {
context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override RiddleMap map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return RiddleMap(id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!, title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!, description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description']), subject: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject']), imageBytes: attachedDatabase.typeMapping.read(DriftSqlType.blob, data['${effectivePrefix}image_bytes']), createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!, );
}
@override
$RiddleMapsTable createAlias(String alias) {
return $RiddleMapsTable(attachedDatabase, alias);}}class RiddleMap extends DataClass implements Insertable<RiddleMap> 
{
final String id;
final String title;
final String? description;
final String? subject;
final Uint8List? imageBytes;
final DateTime createdAt;
const RiddleMap({required this.id, required this.title, this.description, this.subject, this.imageBytes, required this.createdAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<String>(id);
map['title'] = Variable<String>(title);
if (!nullToAbsent || description != null){map['description'] = Variable<String>(description);
}if (!nullToAbsent || subject != null){map['subject'] = Variable<String>(subject);
}if (!nullToAbsent || imageBytes != null){map['image_bytes'] = Variable<Uint8List>(imageBytes);
}map['created_at'] = Variable<DateTime>(createdAt);
return map; 
}
RiddleMapsCompanion toCompanion(bool nullToAbsent) {
return RiddleMapsCompanion(id: Value(id),title: Value(title),description: description == null && nullToAbsent ? const Value.absent() : Value(description),subject: subject == null && nullToAbsent ? const Value.absent() : Value(subject),imageBytes: imageBytes == null && nullToAbsent ? const Value.absent() : Value(imageBytes),createdAt: Value(createdAt),);
}
factory RiddleMap.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return RiddleMap(id: serializer.fromJson<String>(json['id']),title: serializer.fromJson<String>(json['title']),description: serializer.fromJson<String?>(json['description']),subject: serializer.fromJson<String?>(json['subject']),imageBytes: serializer.fromJson<Uint8List?>(json['imageBytes']),createdAt: serializer.fromJson<DateTime>(json['createdAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<String>(id),'title': serializer.toJson<String>(title),'description': serializer.toJson<String?>(description),'subject': serializer.toJson<String?>(subject),'imageBytes': serializer.toJson<Uint8List?>(imageBytes),'createdAt': serializer.toJson<DateTime>(createdAt),};}RiddleMap copyWith({String? id,String? title,Value<String?> description = const Value.absent(),Value<String?> subject = const Value.absent(),Value<Uint8List?> imageBytes = const Value.absent(),DateTime? createdAt}) => RiddleMap(id: id ?? this.id,title: title ?? this.title,description: description.present ? description.value : this.description,subject: subject.present ? subject.value : this.subject,imageBytes: imageBytes.present ? imageBytes.value : this.imageBytes,createdAt: createdAt ?? this.createdAt,);RiddleMap copyWithCompanion(RiddleMapsCompanion data) {
return RiddleMap(
id: data.id.present ? data.id.value : this.id,title: data.title.present ? data.title.value : this.title,description: data.description.present ? data.description.value : this.description,subject: data.subject.present ? data.subject.value : this.subject,imageBytes: data.imageBytes.present ? data.imageBytes.value : this.imageBytes,createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,);
}
@override
String toString() {return (StringBuffer('RiddleMap(')..write('id: $id, ')..write('title: $title, ')..write('description: $description, ')..write('subject: $subject, ')..write('imageBytes: $imageBytes, ')..write('createdAt: $createdAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, title, description, subject, $driftBlobEquality.hash(imageBytes), createdAt);@override
bool operator ==(Object other) => identical(this, other) || (other is RiddleMap && other.id == this.id && other.title == this.title && other.description == this.description && other.subject == this.subject && $driftBlobEquality.equals(other.imageBytes, this.imageBytes) && other.createdAt == this.createdAt);
}class RiddleMapsCompanion extends UpdateCompanion<RiddleMap> {
final Value<String> id;
final Value<String> title;
final Value<String?> description;
final Value<String?> subject;
final Value<Uint8List?> imageBytes;
final Value<DateTime> createdAt;
final Value<int> rowid;
const RiddleMapsCompanion({this.id = const Value.absent(),this.title = const Value.absent(),this.description = const Value.absent(),this.subject = const Value.absent(),this.imageBytes = const Value.absent(),this.createdAt = const Value.absent(),this.rowid = const Value.absent(),});
RiddleMapsCompanion.insert({required String id,required String title,this.description = const Value.absent(),this.subject = const Value.absent(),this.imageBytes = const Value.absent(),this.createdAt = const Value.absent(),this.rowid = const Value.absent(),}): id = Value(id), title = Value(title);
static Insertable<RiddleMap> custom({Expression<String>? id, 
Expression<String>? title, 
Expression<String>? description, 
Expression<String>? subject, 
Expression<Uint8List>? imageBytes, 
Expression<DateTime>? createdAt, 
Expression<int>? rowid, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (title != null)'title': title,if (description != null)'description': description,if (subject != null)'subject': subject,if (imageBytes != null)'image_bytes': imageBytes,if (createdAt != null)'created_at': createdAt,if (rowid != null)'rowid': rowid,});
}RiddleMapsCompanion copyWith({Value<String>? id, Value<String>? title, Value<String?>? description, Value<String?>? subject, Value<Uint8List?>? imageBytes, Value<DateTime>? createdAt, Value<int>? rowid}) {
return RiddleMapsCompanion(id: id ?? this.id,title: title ?? this.title,description: description ?? this.description,subject: subject ?? this.subject,imageBytes: imageBytes ?? this.imageBytes,createdAt: createdAt ?? this.createdAt,rowid: rowid ?? this.rowid,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<String>(id.value);}
if (title.present) {
map['title'] = Variable<String>(title.value);}
if (description.present) {
map['description'] = Variable<String>(description.value);}
if (subject.present) {
map['subject'] = Variable<String>(subject.value);}
if (imageBytes.present) {
map['image_bytes'] = Variable<Uint8List>(imageBytes.value);}
if (createdAt.present) {
map['created_at'] = Variable<DateTime>(createdAt.value);}
if (rowid.present) {
map['rowid'] = Variable<int>(rowid.value);}
return map; 
}
@override
String toString() {return (StringBuffer('RiddleMapsCompanion(')..write('id: $id, ')..write('title: $title, ')..write('description: $description, ')..write('subject: $subject, ')..write('imageBytes: $imageBytes, ')..write('createdAt: $createdAt, ')..write('rowid: $rowid')..write(')')).toString();}
}
class $RiddlesTable extends Riddles with TableInfo<$RiddlesTable, Riddle>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$RiddlesTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
@override
late final GeneratedColumn<String> mapId = GeneratedColumn<String>('map_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES riddle_maps (id) ON DELETE CASCADE'));
static const VerificationMeta _questionMeta = const VerificationMeta('question');
@override
late final GeneratedColumn<String> question = GeneratedColumn<String>('question', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _typeIndexMeta = const VerificationMeta('typeIndex');
@override
late final GeneratedColumn<int> typeIndex = GeneratedColumn<int>('type_index', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
static const VerificationMeta _orderInMapMeta = const VerificationMeta('orderInMap');
@override
late final GeneratedColumn<int> orderInMap = GeneratedColumn<int>('order_in_map', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
static const VerificationMeta _payloadJsonMeta = const VerificationMeta('payloadJson');
@override
late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>('payload_json', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _choicesJsonMeta = const VerificationMeta('choicesJson');
@override
late final GeneratedColumn<String> choicesJson = GeneratedColumn<String>('choices_json', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _correctIndexMeta = const VerificationMeta('correctIndex');
@override
late final GeneratedColumn<int> correctIndex = GeneratedColumn<int>('correct_index', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [id, mapId, question, typeIndex, orderInMap, payloadJson, choicesJson, correctIndex];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'riddles';
@override
VerificationContext validateIntegrity(Insertable<Riddle> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('map_id')) {
context.handle(_mapIdMeta, mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta));} else if (isInserting) {
context.missing(_mapIdMeta);
}
if (data.containsKey('question')) {
context.handle(_questionMeta, question.isAcceptableOrUnknown(data['question']!, _questionMeta));} else if (isInserting) {
context.missing(_questionMeta);
}
if (data.containsKey('type_index')) {
context.handle(_typeIndexMeta, typeIndex.isAcceptableOrUnknown(data['type_index']!, _typeIndexMeta));} else if (isInserting) {
context.missing(_typeIndexMeta);
}
if (data.containsKey('order_in_map')) {
context.handle(_orderInMapMeta, orderInMap.isAcceptableOrUnknown(data['order_in_map']!, _orderInMapMeta));} else if (isInserting) {
context.missing(_orderInMapMeta);
}
if (data.containsKey('payload_json')) {
context.handle(_payloadJsonMeta, payloadJson.isAcceptableOrUnknown(data['payload_json']!, _payloadJsonMeta));}if (data.containsKey('choices_json')) {
context.handle(_choicesJsonMeta, choicesJson.isAcceptableOrUnknown(data['choices_json']!, _choicesJsonMeta));}if (data.containsKey('correct_index')) {
context.handle(_correctIndexMeta, correctIndex.isAcceptableOrUnknown(data['correct_index']!, _correctIndexMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Riddle map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Riddle(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, mapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}map_id'])!, question: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}question'])!, typeIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}type_index'])!, orderInMap: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}order_in_map'])!, payloadJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload_json']), choicesJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}choices_json']), correctIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct_index']), );
}
@override
$RiddlesTable createAlias(String alias) {
return $RiddlesTable(attachedDatabase, alias);}}class Riddle extends DataClass implements Insertable<Riddle> 
{
final int id;
final String mapId;
final String question;
final int typeIndex;
final int orderInMap;
final String? payloadJson;
final String? choicesJson;
final int? correctIndex;
const Riddle({required this.id, required this.mapId, required this.question, required this.typeIndex, required this.orderInMap, this.payloadJson, this.choicesJson, this.correctIndex});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['map_id'] = Variable<String>(mapId);
map['question'] = Variable<String>(question);
map['type_index'] = Variable<int>(typeIndex);
map['order_in_map'] = Variable<int>(orderInMap);
if (!nullToAbsent || payloadJson != null){map['payload_json'] = Variable<String>(payloadJson);
}if (!nullToAbsent || choicesJson != null){map['choices_json'] = Variable<String>(choicesJson);
}if (!nullToAbsent || correctIndex != null){map['correct_index'] = Variable<int>(correctIndex);
}return map; 
}
RiddlesCompanion toCompanion(bool nullToAbsent) {
return RiddlesCompanion(id: Value(id),mapId: Value(mapId),question: Value(question),typeIndex: Value(typeIndex),orderInMap: Value(orderInMap),payloadJson: payloadJson == null && nullToAbsent ? const Value.absent() : Value(payloadJson),choicesJson: choicesJson == null && nullToAbsent ? const Value.absent() : Value(choicesJson),correctIndex: correctIndex == null && nullToAbsent ? const Value.absent() : Value(correctIndex),);
}
factory Riddle.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Riddle(id: serializer.fromJson<int>(json['id']),mapId: serializer.fromJson<String>(json['mapId']),question: serializer.fromJson<String>(json['question']),typeIndex: serializer.fromJson<int>(json['typeIndex']),orderInMap: serializer.fromJson<int>(json['orderInMap']),payloadJson: serializer.fromJson<String?>(json['payloadJson']),choicesJson: serializer.fromJson<String?>(json['choicesJson']),correctIndex: serializer.fromJson<int?>(json['correctIndex']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'mapId': serializer.toJson<String>(mapId),'question': serializer.toJson<String>(question),'typeIndex': serializer.toJson<int>(typeIndex),'orderInMap': serializer.toJson<int>(orderInMap),'payloadJson': serializer.toJson<String?>(payloadJson),'choicesJson': serializer.toJson<String?>(choicesJson),'correctIndex': serializer.toJson<int?>(correctIndex),};}Riddle copyWith({int? id,String? mapId,String? question,int? typeIndex,int? orderInMap,Value<String?> payloadJson = const Value.absent(),Value<String?> choicesJson = const Value.absent(),Value<int?> correctIndex = const Value.absent()}) => Riddle(id: id ?? this.id,mapId: mapId ?? this.mapId,question: question ?? this.question,typeIndex: typeIndex ?? this.typeIndex,orderInMap: orderInMap ?? this.orderInMap,payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,choicesJson: choicesJson.present ? choicesJson.value : this.choicesJson,correctIndex: correctIndex.present ? correctIndex.value : this.correctIndex,);Riddle copyWithCompanion(RiddlesCompanion data) {
return Riddle(
id: data.id.present ? data.id.value : this.id,mapId: data.mapId.present ? data.mapId.value : this.mapId,question: data.question.present ? data.question.value : this.question,typeIndex: data.typeIndex.present ? data.typeIndex.value : this.typeIndex,orderInMap: data.orderInMap.present ? data.orderInMap.value : this.orderInMap,payloadJson: data.payloadJson.present ? data.payloadJson.value : this.payloadJson,choicesJson: data.choicesJson.present ? data.choicesJson.value : this.choicesJson,correctIndex: data.correctIndex.present ? data.correctIndex.value : this.correctIndex,);
}
@override
String toString() {return (StringBuffer('Riddle(')..write('id: $id, ')..write('mapId: $mapId, ')..write('question: $question, ')..write('typeIndex: $typeIndex, ')..write('orderInMap: $orderInMap, ')..write('payloadJson: $payloadJson, ')..write('choicesJson: $choicesJson, ')..write('correctIndex: $correctIndex')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, mapId, question, typeIndex, orderInMap, payloadJson, choicesJson, correctIndex);@override
bool operator ==(Object other) => identical(this, other) || (other is Riddle && other.id == this.id && other.mapId == this.mapId && other.question == this.question && other.typeIndex == this.typeIndex && other.orderInMap == this.orderInMap && other.payloadJson == this.payloadJson && other.choicesJson == this.choicesJson && other.correctIndex == this.correctIndex);
}class RiddlesCompanion extends UpdateCompanion<Riddle> {
final Value<int> id;
final Value<String> mapId;
final Value<String> question;
final Value<int> typeIndex;
final Value<int> orderInMap;
final Value<String?> payloadJson;
final Value<String?> choicesJson;
final Value<int?> correctIndex;
const RiddlesCompanion({this.id = const Value.absent(),this.mapId = const Value.absent(),this.question = const Value.absent(),this.typeIndex = const Value.absent(),this.orderInMap = const Value.absent(),this.payloadJson = const Value.absent(),this.choicesJson = const Value.absent(),this.correctIndex = const Value.absent(),});
RiddlesCompanion.insert({this.id = const Value.absent(),required String mapId,required String question,required int typeIndex,required int orderInMap,this.payloadJson = const Value.absent(),this.choicesJson = const Value.absent(),this.correctIndex = const Value.absent(),}): mapId = Value(mapId), question = Value(question), typeIndex = Value(typeIndex), orderInMap = Value(orderInMap);
static Insertable<Riddle> custom({Expression<int>? id, 
Expression<String>? mapId, 
Expression<String>? question, 
Expression<int>? typeIndex, 
Expression<int>? orderInMap, 
Expression<String>? payloadJson, 
Expression<String>? choicesJson, 
Expression<int>? correctIndex, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (mapId != null)'map_id': mapId,if (question != null)'question': question,if (typeIndex != null)'type_index': typeIndex,if (orderInMap != null)'order_in_map': orderInMap,if (payloadJson != null)'payload_json': payloadJson,if (choicesJson != null)'choices_json': choicesJson,if (correctIndex != null)'correct_index': correctIndex,});
}RiddlesCompanion copyWith({Value<int>? id, Value<String>? mapId, Value<String>? question, Value<int>? typeIndex, Value<int>? orderInMap, Value<String?>? payloadJson, Value<String?>? choicesJson, Value<int?>? correctIndex}) {
return RiddlesCompanion(id: id ?? this.id,mapId: mapId ?? this.mapId,question: question ?? this.question,typeIndex: typeIndex ?? this.typeIndex,orderInMap: orderInMap ?? this.orderInMap,payloadJson: payloadJson ?? this.payloadJson,choicesJson: choicesJson ?? this.choicesJson,correctIndex: correctIndex ?? this.correctIndex,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (mapId.present) {
map['map_id'] = Variable<String>(mapId.value);}
if (question.present) {
map['question'] = Variable<String>(question.value);}
if (typeIndex.present) {
map['type_index'] = Variable<int>(typeIndex.value);}
if (orderInMap.present) {
map['order_in_map'] = Variable<int>(orderInMap.value);}
if (payloadJson.present) {
map['payload_json'] = Variable<String>(payloadJson.value);}
if (choicesJson.present) {
map['choices_json'] = Variable<String>(choicesJson.value);}
if (correctIndex.present) {
map['correct_index'] = Variable<int>(correctIndex.value);}
return map; 
}
@override
String toString() {return (StringBuffer('RiddlesCompanion(')..write('id: $id, ')..write('mapId: $mapId, ')..write('question: $question, ')..write('typeIndex: $typeIndex, ')..write('orderInMap: $orderInMap, ')..write('payloadJson: $payloadJson, ')..write('choicesJson: $choicesJson, ')..write('correctIndex: $correctIndex')..write(')')).toString();}
}
class $PlaySessionsTable extends PlaySessions with TableInfo<$PlaySessionsTable, PlaySession>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$PlaySessionsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _publicIdMeta = const VerificationMeta('publicId');
@override
late final GeneratedColumn<String> publicId = GeneratedColumn<String>('public_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: false, clientDefault: () => const Uuid().v4());
static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
@override
late final GeneratedColumn<String> mapId = GeneratedColumn<String>('map_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES riddle_maps (id) ON DELETE CASCADE'));
static const VerificationMeta _lastCompletedIndexMeta = const VerificationMeta('lastCompletedIndex');
@override
late final GeneratedColumn<int> lastCompletedIndex = GeneratedColumn<int>('last_completed_index', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(-1));
static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
@override
late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>('started_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
@override
late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>('completed_at', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
static const VerificationMeta _totalRiddlesMeta = const VerificationMeta('totalRiddles');
@override
late final GeneratedColumn<int> totalRiddles = GeneratedColumn<int>('total_riddles', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _correctAnswersMeta = const VerificationMeta('correctAnswers');
@override
late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>('correct_answers', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _riddleStarsJsonMeta = const VerificationMeta('riddleStarsJson');
@override
late final GeneratedColumn<String> riddleStarsJson = GeneratedColumn<String>('riddle_stars_json', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [id, publicId, mapId, lastCompletedIndex, startedAt, completedAt, totalRiddles, correctAnswers, riddleStarsJson];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'play_sessions';
@override
VerificationContext validateIntegrity(Insertable<PlaySession> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('public_id')) {
context.handle(_publicIdMeta, publicId.isAcceptableOrUnknown(data['public_id']!, _publicIdMeta));}if (data.containsKey('map_id')) {
context.handle(_mapIdMeta, mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta));} else if (isInserting) {
context.missing(_mapIdMeta);
}
if (data.containsKey('last_completed_index')) {
context.handle(_lastCompletedIndexMeta, lastCompletedIndex.isAcceptableOrUnknown(data['last_completed_index']!, _lastCompletedIndexMeta));}if (data.containsKey('started_at')) {
context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));}if (data.containsKey('completed_at')) {
context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));}if (data.containsKey('total_riddles')) {
context.handle(_totalRiddlesMeta, totalRiddles.isAcceptableOrUnknown(data['total_riddles']!, _totalRiddlesMeta));}if (data.containsKey('correct_answers')) {
context.handle(_correctAnswersMeta, correctAnswers.isAcceptableOrUnknown(data['correct_answers']!, _correctAnswersMeta));}if (data.containsKey('riddle_stars_json')) {
context.handle(_riddleStarsJsonMeta, riddleStarsJson.isAcceptableOrUnknown(data['riddle_stars_json']!, _riddleStarsJsonMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override PlaySession map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return PlaySession(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, publicId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}public_id'])!, mapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}map_id'])!, lastCompletedIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}last_completed_index'])!, startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!, completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']), totalRiddles: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}total_riddles'])!, correctAnswers: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct_answers'])!, riddleStarsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}riddle_stars_json']), );
}
@override
$PlaySessionsTable createAlias(String alias) {
return $PlaySessionsTable(attachedDatabase, alias);}}class PlaySession extends DataClass implements Insertable<PlaySession> 
{
final int id;
final String publicId;
final String mapId;
final int lastCompletedIndex;
final DateTime startedAt;
final DateTime? completedAt;
final int totalRiddles;
final int correctAnswers;
final String? riddleStarsJson;
const PlaySession({required this.id, required this.publicId, required this.mapId, required this.lastCompletedIndex, required this.startedAt, this.completedAt, required this.totalRiddles, required this.correctAnswers, this.riddleStarsJson});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['public_id'] = Variable<String>(publicId);
map['map_id'] = Variable<String>(mapId);
map['last_completed_index'] = Variable<int>(lastCompletedIndex);
map['started_at'] = Variable<DateTime>(startedAt);
if (!nullToAbsent || completedAt != null){map['completed_at'] = Variable<DateTime>(completedAt);
}map['total_riddles'] = Variable<int>(totalRiddles);
map['correct_answers'] = Variable<int>(correctAnswers);
if (!nullToAbsent || riddleStarsJson != null){map['riddle_stars_json'] = Variable<String>(riddleStarsJson);
}return map; 
}
PlaySessionsCompanion toCompanion(bool nullToAbsent) {
return PlaySessionsCompanion(id: Value(id),publicId: Value(publicId),mapId: Value(mapId),lastCompletedIndex: Value(lastCompletedIndex),startedAt: Value(startedAt),completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),totalRiddles: Value(totalRiddles),correctAnswers: Value(correctAnswers),riddleStarsJson: riddleStarsJson == null && nullToAbsent ? const Value.absent() : Value(riddleStarsJson),);
}
factory PlaySession.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return PlaySession(id: serializer.fromJson<int>(json['id']),publicId: serializer.fromJson<String>(json['publicId']),mapId: serializer.fromJson<String>(json['mapId']),lastCompletedIndex: serializer.fromJson<int>(json['lastCompletedIndex']),startedAt: serializer.fromJson<DateTime>(json['startedAt']),completedAt: serializer.fromJson<DateTime?>(json['completedAt']),totalRiddles: serializer.fromJson<int>(json['totalRiddles']),correctAnswers: serializer.fromJson<int>(json['correctAnswers']),riddleStarsJson: serializer.fromJson<String?>(json['riddleStarsJson']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'publicId': serializer.toJson<String>(publicId),'mapId': serializer.toJson<String>(mapId),'lastCompletedIndex': serializer.toJson<int>(lastCompletedIndex),'startedAt': serializer.toJson<DateTime>(startedAt),'completedAt': serializer.toJson<DateTime?>(completedAt),'totalRiddles': serializer.toJson<int>(totalRiddles),'correctAnswers': serializer.toJson<int>(correctAnswers),'riddleStarsJson': serializer.toJson<String?>(riddleStarsJson),};}PlaySession copyWith({int? id,String? publicId,String? mapId,int? lastCompletedIndex,DateTime? startedAt,Value<DateTime?> completedAt = const Value.absent(),int? totalRiddles,int? correctAnswers,Value<String?> riddleStarsJson = const Value.absent()}) => PlaySession(id: id ?? this.id,publicId: publicId ?? this.publicId,mapId: mapId ?? this.mapId,lastCompletedIndex: lastCompletedIndex ?? this.lastCompletedIndex,startedAt: startedAt ?? this.startedAt,completedAt: completedAt.present ? completedAt.value : this.completedAt,totalRiddles: totalRiddles ?? this.totalRiddles,correctAnswers: correctAnswers ?? this.correctAnswers,riddleStarsJson: riddleStarsJson.present ? riddleStarsJson.value : this.riddleStarsJson,);PlaySession copyWithCompanion(PlaySessionsCompanion data) {
return PlaySession(
id: data.id.present ? data.id.value : this.id,publicId: data.publicId.present ? data.publicId.value : this.publicId,mapId: data.mapId.present ? data.mapId.value : this.mapId,lastCompletedIndex: data.lastCompletedIndex.present ? data.lastCompletedIndex.value : this.lastCompletedIndex,startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,totalRiddles: data.totalRiddles.present ? data.totalRiddles.value : this.totalRiddles,correctAnswers: data.correctAnswers.present ? data.correctAnswers.value : this.correctAnswers,riddleStarsJson: data.riddleStarsJson.present ? data.riddleStarsJson.value : this.riddleStarsJson,);
}
@override
String toString() {return (StringBuffer('PlaySession(')..write('id: $id, ')..write('publicId: $publicId, ')..write('mapId: $mapId, ')..write('lastCompletedIndex: $lastCompletedIndex, ')..write('startedAt: $startedAt, ')..write('completedAt: $completedAt, ')..write('totalRiddles: $totalRiddles, ')..write('correctAnswers: $correctAnswers, ')..write('riddleStarsJson: $riddleStarsJson')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, publicId, mapId, lastCompletedIndex, startedAt, completedAt, totalRiddles, correctAnswers, riddleStarsJson);@override
bool operator ==(Object other) => identical(this, other) || (other is PlaySession && other.id == this.id && other.publicId == this.publicId && other.mapId == this.mapId && other.lastCompletedIndex == this.lastCompletedIndex && other.startedAt == this.startedAt && other.completedAt == this.completedAt && other.totalRiddles == this.totalRiddles && other.correctAnswers == this.correctAnswers && other.riddleStarsJson == this.riddleStarsJson);
}class PlaySessionsCompanion extends UpdateCompanion<PlaySession> {
final Value<int> id;
final Value<String> publicId;
final Value<String> mapId;
final Value<int> lastCompletedIndex;
final Value<DateTime> startedAt;
final Value<DateTime?> completedAt;
final Value<int> totalRiddles;
final Value<int> correctAnswers;
final Value<String?> riddleStarsJson;
const PlaySessionsCompanion({this.id = const Value.absent(),this.publicId = const Value.absent(),this.mapId = const Value.absent(),this.lastCompletedIndex = const Value.absent(),this.startedAt = const Value.absent(),this.completedAt = const Value.absent(),this.totalRiddles = const Value.absent(),this.correctAnswers = const Value.absent(),this.riddleStarsJson = const Value.absent(),});
PlaySessionsCompanion.insert({this.id = const Value.absent(),this.publicId = const Value.absent(),required String mapId,this.lastCompletedIndex = const Value.absent(),this.startedAt = const Value.absent(),this.completedAt = const Value.absent(),this.totalRiddles = const Value.absent(),this.correctAnswers = const Value.absent(),this.riddleStarsJson = const Value.absent(),}): mapId = Value(mapId);
static Insertable<PlaySession> custom({Expression<int>? id, 
Expression<String>? publicId, 
Expression<String>? mapId, 
Expression<int>? lastCompletedIndex, 
Expression<DateTime>? startedAt, 
Expression<DateTime>? completedAt, 
Expression<int>? totalRiddles, 
Expression<int>? correctAnswers, 
Expression<String>? riddleStarsJson, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (publicId != null)'public_id': publicId,if (mapId != null)'map_id': mapId,if (lastCompletedIndex != null)'last_completed_index': lastCompletedIndex,if (startedAt != null)'started_at': startedAt,if (completedAt != null)'completed_at': completedAt,if (totalRiddles != null)'total_riddles': totalRiddles,if (correctAnswers != null)'correct_answers': correctAnswers,if (riddleStarsJson != null)'riddle_stars_json': riddleStarsJson,});
}PlaySessionsCompanion copyWith({Value<int>? id, Value<String>? publicId, Value<String>? mapId, Value<int>? lastCompletedIndex, Value<DateTime>? startedAt, Value<DateTime?>? completedAt, Value<int>? totalRiddles, Value<int>? correctAnswers, Value<String?>? riddleStarsJson}) {
return PlaySessionsCompanion(id: id ?? this.id,publicId: publicId ?? this.publicId,mapId: mapId ?? this.mapId,lastCompletedIndex: lastCompletedIndex ?? this.lastCompletedIndex,startedAt: startedAt ?? this.startedAt,completedAt: completedAt ?? this.completedAt,totalRiddles: totalRiddles ?? this.totalRiddles,correctAnswers: correctAnswers ?? this.correctAnswers,riddleStarsJson: riddleStarsJson ?? this.riddleStarsJson,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (publicId.present) {
map['public_id'] = Variable<String>(publicId.value);}
if (mapId.present) {
map['map_id'] = Variable<String>(mapId.value);}
if (lastCompletedIndex.present) {
map['last_completed_index'] = Variable<int>(lastCompletedIndex.value);}
if (startedAt.present) {
map['started_at'] = Variable<DateTime>(startedAt.value);}
if (completedAt.present) {
map['completed_at'] = Variable<DateTime>(completedAt.value);}
if (totalRiddles.present) {
map['total_riddles'] = Variable<int>(totalRiddles.value);}
if (correctAnswers.present) {
map['correct_answers'] = Variable<int>(correctAnswers.value);}
if (riddleStarsJson.present) {
map['riddle_stars_json'] = Variable<String>(riddleStarsJson.value);}
return map; 
}
@override
String toString() {return (StringBuffer('PlaySessionsCompanion(')..write('id: $id, ')..write('publicId: $publicId, ')..write('mapId: $mapId, ')..write('lastCompletedIndex: $lastCompletedIndex, ')..write('startedAt: $startedAt, ')..write('completedAt: $completedAt, ')..write('totalRiddles: $totalRiddles, ')..write('correctAnswers: $correctAnswers, ')..write('riddleStarsJson: $riddleStarsJson')..write(')')).toString();}
}
abstract class _$AppDatabase extends GeneratedDatabase{
_$AppDatabase(QueryExecutor e): super(e);
$AppDatabaseManager get managers => $AppDatabaseManager(this);
late final $RiddleMapsTable riddleMaps = $RiddleMapsTable(this);
late final $RiddlesTable riddles = $RiddlesTable(this);
late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
@override
Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
@override
List<DatabaseSchemaEntity> get allSchemaEntities => [riddleMaps, riddles, playSessions];
@override
StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([WritePropagation(on: TableUpdateQuery.onTableName('riddle_maps' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('riddles', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('riddle_maps' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('play_sessions', kind: UpdateKind.delete), ],), ],);
}
typedef $$RiddleMapsTableCreateCompanionBuilder = RiddleMapsCompanion Function({required String id,required String title,Value<String?> description,Value<String?> subject,Value<Uint8List?> imageBytes,Value<DateTime> createdAt,Value<int> rowid,});
typedef $$RiddleMapsTableUpdateCompanionBuilder = RiddleMapsCompanion Function({Value<String> id,Value<String> title,Value<String?> description,Value<String?> subject,Value<Uint8List?> imageBytes,Value<DateTime> createdAt,Value<int> rowid,});
      final class $$RiddleMapsTableReferences extends BaseReferences<
        _$AppDatabase,
        $RiddleMapsTable,
        RiddleMap> {
        $$RiddleMapsTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                  
                  static MultiTypedResultKey<
          $RiddlesTable,
          List<Riddle>
        > _riddlesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.riddles, 
          aliasName: $_aliasNameGenerator(
            db.riddleMaps.id,
            db.riddles.mapId)
        );

          $$RiddlesTableProcessedTableManager get riddlesRefs {
        final manager = $$RiddlesTableTableManager(
            $_db, $_db.riddles
            ).filter(
              (f) => f.mapId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_riddlesRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        
          
                  static MultiTypedResultKey<
          $PlaySessionsTable,
          List<PlaySession>
        > _playSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.playSessions, 
          aliasName: $_aliasNameGenerator(
            db.riddleMaps.id,
            db.playSessions.mapId)
        );

          $$PlaySessionsTableProcessedTableManager get playSessionsRefs {
        final manager = $$PlaySessionsTableTableManager(
            $_db, $_db.playSessions
            ).filter(
              (f) => f.mapId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_playSessionsRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        

      }class $$RiddleMapsTableFilterComposer extends Composer<
        _$AppDatabase,
        $RiddleMapsTable> {
        $$RiddleMapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get title => $composableBuilder(
      column: $table.title,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get description => $composableBuilder(
      column: $table.description,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<Uint8List> get imageBytes => $composableBuilder(
      column: $table.imageBytes,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => 
      ColumnFilters(column));
      
        Expression<bool> riddlesRefs(
          Expression<bool> Function( $$RiddlesTableFilterComposer f) f
        ) {
                final $$RiddlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.mapId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableFilterComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        Expression<bool> playSessionsRefs(
          Expression<bool> Function( $$PlaySessionsTableFilterComposer f) f
        ) {
                final $$PlaySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.mapId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$PlaySessionsTableFilterComposer(
              $db: $db,
              $table: $db.playSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$RiddleMapsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $RiddleMapsTable> {
        $$RiddleMapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<Uint8List> get imageBytes => $composableBuilder(
      column: $table.imageBytes,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$RiddleMapsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $RiddleMapsTable> {
        $$RiddleMapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get title => $composableBuilder(
      column: $table.title,
      builder: (column) => column);
      
GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description,
      builder: (column) => column);
      
GeneratedColumn<String> get subject => $composableBuilder(
      column: $table.subject,
      builder: (column) => column);
      
GeneratedColumn<Uint8List> get imageBytes => $composableBuilder(
      column: $table.imageBytes,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => column);
      
        Expression<T> riddlesRefs<T extends Object>(
          Expression<T> Function( $$RiddlesTableAnnotationComposer a) f
        ) {
                final $$RiddlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.mapId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableAnnotationComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        Expression<T> playSessionsRefs<T extends Object>(
          Expression<T> Function( $$PlaySessionsTableAnnotationComposer a) f
        ) {
                final $$PlaySessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.mapId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$PlaySessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.playSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$RiddleMapsTableTableManager extends RootTableManager    <_$AppDatabase,
    $RiddleMapsTable,
    RiddleMap,
    $$RiddleMapsTableFilterComposer,
    $$RiddleMapsTableOrderingComposer,
    $$RiddleMapsTableAnnotationComposer,
    $$RiddleMapsTableCreateCompanionBuilder,
    $$RiddleMapsTableUpdateCompanionBuilder,
    (RiddleMap,$$RiddleMapsTableReferences),
    RiddleMap,
    PrefetchHooks Function({bool riddlesRefs,bool playSessionsRefs})
    > {
    $$RiddleMapsTableTableManager(_$AppDatabase db, $RiddleMapsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$RiddleMapsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$RiddleMapsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$RiddleMapsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<String> id = const Value.absent(),Value<String> title = const Value.absent(),Value<String?> description = const Value.absent(),Value<String?> subject = const Value.absent(),Value<Uint8List?> imageBytes = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> RiddleMapsCompanion(id: id,title: title,description: description,subject: subject,imageBytes: imageBytes,createdAt: createdAt,rowid: rowid,),
        createCompanionCallback: ({required String id,required String title,Value<String?> description = const Value.absent(),Value<String?> subject = const Value.absent(),Value<Uint8List?> imageBytes = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> RiddleMapsCompanion.insert(id: id,title: title,description: description,subject: subject,imageBytes: imageBytes,createdAt: createdAt,rowid: rowid,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$RiddleMapsTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({riddlesRefs = false,playSessionsRefs = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             if (riddlesRefs) db.riddles,if (playSessionsRefs) db.playSessions
            ],
            addJoins: null,
            getPrefetchedDataCallback: (items) async {
            return [
                      if (riddlesRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$RiddleMapsTableReferences._riddlesRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$RiddleMapsTableReferences(db, table, p0).riddlesRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.mapId == item.id),
                  typedResults: items)
            ,          if (playSessionsRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$RiddleMapsTableReferences._playSessionsRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$RiddleMapsTableReferences(db, table, p0).playSessionsRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.mapId == item.id),
                  typedResults: items)
            
                ];
              },
          );
        }
,
        ));
        }
    typedef $$RiddleMapsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $RiddleMapsTable,
    RiddleMap,
    $$RiddleMapsTableFilterComposer,
    $$RiddleMapsTableOrderingComposer,
    $$RiddleMapsTableAnnotationComposer,
    $$RiddleMapsTableCreateCompanionBuilder,
    $$RiddleMapsTableUpdateCompanionBuilder,
    (RiddleMap,$$RiddleMapsTableReferences),
    RiddleMap,
    PrefetchHooks Function({bool riddlesRefs,bool playSessionsRefs})
    >;typedef $$RiddlesTableCreateCompanionBuilder = RiddlesCompanion Function({Value<int> id,required String mapId,required String question,required int typeIndex,required int orderInMap,Value<String?> payloadJson,Value<String?> choicesJson,Value<int?> correctIndex,});
typedef $$RiddlesTableUpdateCompanionBuilder = RiddlesCompanion Function({Value<int> id,Value<String> mapId,Value<String> question,Value<int> typeIndex,Value<int> orderInMap,Value<String?> payloadJson,Value<String?> choicesJson,Value<int?> correctIndex,});
      final class $$RiddlesTableReferences extends BaseReferences<
        _$AppDatabase,
        $RiddlesTable,
        Riddle> {
        $$RiddlesTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $RiddleMapsTable _mapIdTable(_$AppDatabase db) => 
            db.riddleMaps.createAlias($_aliasNameGenerator(
            db.riddles.mapId,
            db.riddleMaps.id));
          

        $$RiddleMapsTableProcessedTableManager? get mapId {
          if ($_item.mapId == null) return null;
          final manager = $$RiddleMapsTableTableManager($_db, $_db.riddleMaps).filter((f) => f.id($_item.mapId!));
          final item = $_typedResult.readTableOrNull(_mapIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }


      }class $$RiddlesTableFilterComposer extends Composer<
        _$AppDatabase,
        $RiddlesTable> {
        $$RiddlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get question => $composableBuilder(
      column: $table.question,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get typeIndex => $composableBuilder(
      column: $table.typeIndex,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get orderInMap => $composableBuilder(
      column: $table.orderInMap,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get choicesJson => $composableBuilder(
      column: $table.choicesJson,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get correctIndex => $composableBuilder(
      column: $table.correctIndex,
      builder: (column) => 
      ColumnFilters(column));
      
        $$RiddleMapsTableFilterComposer get mapId {
                final $$RiddleMapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mapId,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableFilterComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$RiddlesTableOrderingComposer extends Composer<
        _$AppDatabase,
        $RiddlesTable> {
        $$RiddlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get question => $composableBuilder(
      column: $table.question,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get typeIndex => $composableBuilder(
      column: $table.typeIndex,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get orderInMap => $composableBuilder(
      column: $table.orderInMap,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get choicesJson => $composableBuilder(
      column: $table.choicesJson,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get correctIndex => $composableBuilder(
      column: $table.correctIndex,
      builder: (column) => 
      ColumnOrderings(column));
      
        $$RiddleMapsTableOrderingComposer get mapId {
                final $$RiddleMapsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mapId,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableOrderingComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$RiddlesTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $RiddlesTable> {
        $$RiddlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get question => $composableBuilder(
      column: $table.question,
      builder: (column) => column);
      
GeneratedColumn<int> get typeIndex => $composableBuilder(
      column: $table.typeIndex,
      builder: (column) => column);
      
GeneratedColumn<int> get orderInMap => $composableBuilder(
      column: $table.orderInMap,
      builder: (column) => column);
      
GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson,
      builder: (column) => column);
      
GeneratedColumn<String> get choicesJson => $composableBuilder(
      column: $table.choicesJson,
      builder: (column) => column);
      
GeneratedColumn<int> get correctIndex => $composableBuilder(
      column: $table.correctIndex,
      builder: (column) => column);
      
        $$RiddleMapsTableAnnotationComposer get mapId {
                final $$RiddleMapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mapId,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableAnnotationComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$RiddlesTableTableManager extends RootTableManager    <_$AppDatabase,
    $RiddlesTable,
    Riddle,
    $$RiddlesTableFilterComposer,
    $$RiddlesTableOrderingComposer,
    $$RiddlesTableAnnotationComposer,
    $$RiddlesTableCreateCompanionBuilder,
    $$RiddlesTableUpdateCompanionBuilder,
    (Riddle,$$RiddlesTableReferences),
    Riddle,
    PrefetchHooks Function({bool mapId})
    > {
    $$RiddlesTableTableManager(_$AppDatabase db, $RiddlesTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$RiddlesTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$RiddlesTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$RiddlesTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> mapId = const Value.absent(),Value<String> question = const Value.absent(),Value<int> typeIndex = const Value.absent(),Value<int> orderInMap = const Value.absent(),Value<String?> payloadJson = const Value.absent(),Value<String?> choicesJson = const Value.absent(),Value<int?> correctIndex = const Value.absent(),})=> RiddlesCompanion(id: id,mapId: mapId,question: question,typeIndex: typeIndex,orderInMap: orderInMap,payloadJson: payloadJson,choicesJson: choicesJson,correctIndex: correctIndex,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required String mapId,required String question,required int typeIndex,required int orderInMap,Value<String?> payloadJson = const Value.absent(),Value<String?> choicesJson = const Value.absent(),Value<int?> correctIndex = const Value.absent(),})=> RiddlesCompanion.insert(id: id,mapId: mapId,question: question,typeIndex: typeIndex,orderInMap: orderInMap,payloadJson: payloadJson,choicesJson: choicesJson,correctIndex: correctIndex,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$RiddlesTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({mapId = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (mapId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mapId,
                    referencedTable:
                        $$RiddlesTableReferences._mapIdTable(db),
                    referencedColumn:
                        $$RiddlesTableReferences._mapIdTable(db).id,
                  ) as T;
               }

                return state;
              }
,
            getPrefetchedDataCallback: (items) async {
            return [
            
                ];
              },
          );
        }
,
        ));
        }
    typedef $$RiddlesTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $RiddlesTable,
    Riddle,
    $$RiddlesTableFilterComposer,
    $$RiddlesTableOrderingComposer,
    $$RiddlesTableAnnotationComposer,
    $$RiddlesTableCreateCompanionBuilder,
    $$RiddlesTableUpdateCompanionBuilder,
    (Riddle,$$RiddlesTableReferences),
    Riddle,
    PrefetchHooks Function({bool mapId})
    >;typedef $$PlaySessionsTableCreateCompanionBuilder = PlaySessionsCompanion Function({Value<int> id,Value<String> publicId,required String mapId,Value<int> lastCompletedIndex,Value<DateTime> startedAt,Value<DateTime?> completedAt,Value<int> totalRiddles,Value<int> correctAnswers,Value<String?> riddleStarsJson,});
typedef $$PlaySessionsTableUpdateCompanionBuilder = PlaySessionsCompanion Function({Value<int> id,Value<String> publicId,Value<String> mapId,Value<int> lastCompletedIndex,Value<DateTime> startedAt,Value<DateTime?> completedAt,Value<int> totalRiddles,Value<int> correctAnswers,Value<String?> riddleStarsJson,});
      final class $$PlaySessionsTableReferences extends BaseReferences<
        _$AppDatabase,
        $PlaySessionsTable,
        PlaySession> {
        $$PlaySessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $RiddleMapsTable _mapIdTable(_$AppDatabase db) => 
            db.riddleMaps.createAlias($_aliasNameGenerator(
            db.playSessions.mapId,
            db.riddleMaps.id));
          

        $$RiddleMapsTableProcessedTableManager? get mapId {
          if ($_item.mapId == null) return null;
          final manager = $$RiddleMapsTableTableManager($_db, $_db.riddleMaps).filter((f) => f.id($_item.mapId!));
          final item = $_typedResult.readTableOrNull(_mapIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }


      }class $$PlaySessionsTableFilterComposer extends Composer<
        _$AppDatabase,
        $PlaySessionsTable> {
        $$PlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get publicId => $composableBuilder(
      column: $table.publicId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get lastCompletedIndex => $composableBuilder(
      column: $table.lastCompletedIndex,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get totalRiddles => $composableBuilder(
      column: $table.totalRiddles,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get riddleStarsJson => $composableBuilder(
      column: $table.riddleStarsJson,
      builder: (column) => 
      ColumnFilters(column));
      
        $$RiddleMapsTableFilterComposer get mapId {
                final $$RiddleMapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mapId,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableFilterComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$PlaySessionsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $PlaySessionsTable> {
        $$PlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get publicId => $composableBuilder(
      column: $table.publicId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get lastCompletedIndex => $composableBuilder(
      column: $table.lastCompletedIndex,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get totalRiddles => $composableBuilder(
      column: $table.totalRiddles,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get riddleStarsJson => $composableBuilder(
      column: $table.riddleStarsJson,
      builder: (column) => 
      ColumnOrderings(column));
      
        $$RiddleMapsTableOrderingComposer get mapId {
                final $$RiddleMapsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mapId,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableOrderingComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$PlaySessionsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $PlaySessionsTable> {
        $$PlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get publicId => $composableBuilder(
      column: $table.publicId,
      builder: (column) => column);
      
GeneratedColumn<int> get lastCompletedIndex => $composableBuilder(
      column: $table.lastCompletedIndex,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt,
      builder: (column) => column);
      
GeneratedColumn<int> get totalRiddles => $composableBuilder(
      column: $table.totalRiddles,
      builder: (column) => column);
      
GeneratedColumn<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => column);
      
GeneratedColumn<String> get riddleStarsJson => $composableBuilder(
      column: $table.riddleStarsJson,
      builder: (column) => column);
      
        $$RiddleMapsTableAnnotationComposer get mapId {
                final $$RiddleMapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mapId,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableAnnotationComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$PlaySessionsTableTableManager extends RootTableManager    <_$AppDatabase,
    $PlaySessionsTable,
    PlaySession,
    $$PlaySessionsTableFilterComposer,
    $$PlaySessionsTableOrderingComposer,
    $$PlaySessionsTableAnnotationComposer,
    $$PlaySessionsTableCreateCompanionBuilder,
    $$PlaySessionsTableUpdateCompanionBuilder,
    (PlaySession,$$PlaySessionsTableReferences),
    PlaySession,
    PrefetchHooks Function({bool mapId})
    > {
    $$PlaySessionsTableTableManager(_$AppDatabase db, $PlaySessionsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$PlaySessionsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$PlaySessionsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$PlaySessionsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> publicId = const Value.absent(),Value<String> mapId = const Value.absent(),Value<int> lastCompletedIndex = const Value.absent(),Value<DateTime> startedAt = const Value.absent(),Value<DateTime?> completedAt = const Value.absent(),Value<int> totalRiddles = const Value.absent(),Value<int> correctAnswers = const Value.absent(),Value<String?> riddleStarsJson = const Value.absent(),})=> PlaySessionsCompanion(id: id,publicId: publicId,mapId: mapId,lastCompletedIndex: lastCompletedIndex,startedAt: startedAt,completedAt: completedAt,totalRiddles: totalRiddles,correctAnswers: correctAnswers,riddleStarsJson: riddleStarsJson,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> publicId = const Value.absent(),required String mapId,Value<int> lastCompletedIndex = const Value.absent(),Value<DateTime> startedAt = const Value.absent(),Value<DateTime?> completedAt = const Value.absent(),Value<int> totalRiddles = const Value.absent(),Value<int> correctAnswers = const Value.absent(),Value<String?> riddleStarsJson = const Value.absent(),})=> PlaySessionsCompanion.insert(id: id,publicId: publicId,mapId: mapId,lastCompletedIndex: lastCompletedIndex,startedAt: startedAt,completedAt: completedAt,totalRiddles: totalRiddles,correctAnswers: correctAnswers,riddleStarsJson: riddleStarsJson,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$PlaySessionsTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({mapId = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (mapId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mapId,
                    referencedTable:
                        $$PlaySessionsTableReferences._mapIdTable(db),
                    referencedColumn:
                        $$PlaySessionsTableReferences._mapIdTable(db).id,
                  ) as T;
               }

                return state;
              }
,
            getPrefetchedDataCallback: (items) async {
            return [
            
                ];
              },
          );
        }
,
        ));
        }
    typedef $$PlaySessionsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $PlaySessionsTable,
    PlaySession,
    $$PlaySessionsTableFilterComposer,
    $$PlaySessionsTableOrderingComposer,
    $$PlaySessionsTableAnnotationComposer,
    $$PlaySessionsTableCreateCompanionBuilder,
    $$PlaySessionsTableUpdateCompanionBuilder,
    (PlaySession,$$PlaySessionsTableReferences),
    PlaySession,
    PrefetchHooks Function({bool mapId})
    >;class $AppDatabaseManager {
final _$AppDatabase _db;
$AppDatabaseManager(this._db);
$$RiddleMapsTableTableManager get riddleMaps => $$RiddleMapsTableTableManager(_db, _db.riddleMaps);
$$RiddlesTableTableManager get riddles => $$RiddlesTableTableManager(_db, _db.riddles);
$$PlaySessionsTableTableManager get playSessions => $$PlaySessionsTableTableManager(_db, _db.playSessions);
}
