// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$FoldersTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _titleMeta = const VerificationMeta('title');
@override
late final GeneratedColumn<String> title = GeneratedColumn<String>('title', aliasedName, false, additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1,maxTextLength: 100), type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
@override
late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>('created_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
@override
List<GeneratedColumn> get $columns => [id, title, createdAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'folders';
@override
VerificationContext validateIntegrity(Insertable<Folder> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('title')) {
context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));} else if (isInserting) {
context.missing(_titleMeta);
}
if (data.containsKey('created_at')) {
context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Folder map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Folder(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!, createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!, );
}
@override
$FoldersTable createAlias(String alias) {
return $FoldersTable(attachedDatabase, alias);}}class Folder extends DataClass implements Insertable<Folder> 
{
final int id;
final String title;
final DateTime createdAt;
const Folder({required this.id, required this.title, required this.createdAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['title'] = Variable<String>(title);
map['created_at'] = Variable<DateTime>(createdAt);
return map; 
}
FoldersCompanion toCompanion(bool nullToAbsent) {
return FoldersCompanion(id: Value(id),title: Value(title),createdAt: Value(createdAt),);
}
factory Folder.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Folder(id: serializer.fromJson<int>(json['id']),title: serializer.fromJson<String>(json['title']),createdAt: serializer.fromJson<DateTime>(json['createdAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'title': serializer.toJson<String>(title),'createdAt': serializer.toJson<DateTime>(createdAt),};}Folder copyWith({int? id,String? title,DateTime? createdAt}) => Folder(id: id ?? this.id,title: title ?? this.title,createdAt: createdAt ?? this.createdAt,);Folder copyWithCompanion(FoldersCompanion data) {
return Folder(
id: data.id.present ? data.id.value : this.id,title: data.title.present ? data.title.value : this.title,createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,);
}
@override
String toString() {return (StringBuffer('Folder(')..write('id: $id, ')..write('title: $title, ')..write('createdAt: $createdAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, title, createdAt);@override
bool operator ==(Object other) => identical(this, other) || (other is Folder && other.id == this.id && other.title == this.title && other.createdAt == this.createdAt);
}class FoldersCompanion extends UpdateCompanion<Folder> {
final Value<int> id;
final Value<String> title;
final Value<DateTime> createdAt;
const FoldersCompanion({this.id = const Value.absent(),this.title = const Value.absent(),this.createdAt = const Value.absent(),});
FoldersCompanion.insert({this.id = const Value.absent(),required String title,this.createdAt = const Value.absent(),}): title = Value(title);
static Insertable<Folder> custom({Expression<int>? id, 
Expression<String>? title, 
Expression<DateTime>? createdAt, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (title != null)'title': title,if (createdAt != null)'created_at': createdAt,});
}FoldersCompanion copyWith({Value<int>? id, Value<String>? title, Value<DateTime>? createdAt}) {
return FoldersCompanion(id: id ?? this.id,title: title ?? this.title,createdAt: createdAt ?? this.createdAt,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (title.present) {
map['title'] = Variable<String>(title.value);}
if (createdAt.present) {
map['created_at'] = Variable<DateTime>(createdAt.value);}
return map; 
}
@override
String toString() {return (StringBuffer('FoldersCompanion(')..write('id: $id, ')..write('title: $title, ')..write('createdAt: $createdAt')..write(')')).toString();}
}
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
static const VerificationMeta _riddlesVersionMeta = const VerificationMeta('riddlesVersion');
@override
late final GeneratedColumn<int> riddlesVersion = GeneratedColumn<int>('riddles_version', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _folderIdMeta = const VerificationMeta('folderId');
@override
late final GeneratedColumn<int> folderId = GeneratedColumn<int>('folder_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES folders (id) ON DELETE SET NULL'));
static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
@override
late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>('sort_order', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
@override
List<GeneratedColumn> get $columns => [id, title, description, subject, imageBytes, createdAt, riddlesVersion, folderId, sortOrder];
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
context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));}if (data.containsKey('riddles_version')) {
context.handle(_riddlesVersionMeta, riddlesVersion.isAcceptableOrUnknown(data['riddles_version']!, _riddlesVersionMeta));}if (data.containsKey('folder_id')) {
context.handle(_folderIdMeta, folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));}if (data.containsKey('sort_order')) {
context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override RiddleMap map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return RiddleMap(id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!, title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!, description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description']), subject: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject']), imageBytes: attachedDatabase.typeMapping.read(DriftSqlType.blob, data['${effectivePrefix}image_bytes']), createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!, riddlesVersion: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}riddles_version'])!, folderId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}folder_id']), sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!, );
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
final int riddlesVersion;
final int? folderId;
final int sortOrder;
const RiddleMap({required this.id, required this.title, this.description, this.subject, this.imageBytes, required this.createdAt, required this.riddlesVersion, this.folderId, required this.sortOrder});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<String>(id);
map['title'] = Variable<String>(title);
if (!nullToAbsent || description != null){map['description'] = Variable<String>(description);
}if (!nullToAbsent || subject != null){map['subject'] = Variable<String>(subject);
}if (!nullToAbsent || imageBytes != null){map['image_bytes'] = Variable<Uint8List>(imageBytes);
}map['created_at'] = Variable<DateTime>(createdAt);
map['riddles_version'] = Variable<int>(riddlesVersion);
if (!nullToAbsent || folderId != null){map['folder_id'] = Variable<int>(folderId);
}map['sort_order'] = Variable<int>(sortOrder);
return map; 
}
RiddleMapsCompanion toCompanion(bool nullToAbsent) {
return RiddleMapsCompanion(id: Value(id),title: Value(title),description: description == null && nullToAbsent ? const Value.absent() : Value(description),subject: subject == null && nullToAbsent ? const Value.absent() : Value(subject),imageBytes: imageBytes == null && nullToAbsent ? const Value.absent() : Value(imageBytes),createdAt: Value(createdAt),riddlesVersion: Value(riddlesVersion),folderId: folderId == null && nullToAbsent ? const Value.absent() : Value(folderId),sortOrder: Value(sortOrder),);
}
factory RiddleMap.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return RiddleMap(id: serializer.fromJson<String>(json['id']),title: serializer.fromJson<String>(json['title']),description: serializer.fromJson<String?>(json['description']),subject: serializer.fromJson<String?>(json['subject']),imageBytes: serializer.fromJson<Uint8List?>(json['imageBytes']),createdAt: serializer.fromJson<DateTime>(json['createdAt']),riddlesVersion: serializer.fromJson<int>(json['riddlesVersion']),folderId: serializer.fromJson<int?>(json['folderId']),sortOrder: serializer.fromJson<int>(json['sortOrder']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<String>(id),'title': serializer.toJson<String>(title),'description': serializer.toJson<String?>(description),'subject': serializer.toJson<String?>(subject),'imageBytes': serializer.toJson<Uint8List?>(imageBytes),'createdAt': serializer.toJson<DateTime>(createdAt),'riddlesVersion': serializer.toJson<int>(riddlesVersion),'folderId': serializer.toJson<int?>(folderId),'sortOrder': serializer.toJson<int>(sortOrder),};}RiddleMap copyWith({String? id,String? title,Value<String?> description = const Value.absent(),Value<String?> subject = const Value.absent(),Value<Uint8List?> imageBytes = const Value.absent(),DateTime? createdAt,int? riddlesVersion,Value<int?> folderId = const Value.absent(),int? sortOrder}) => RiddleMap(id: id ?? this.id,title: title ?? this.title,description: description.present ? description.value : this.description,subject: subject.present ? subject.value : this.subject,imageBytes: imageBytes.present ? imageBytes.value : this.imageBytes,createdAt: createdAt ?? this.createdAt,riddlesVersion: riddlesVersion ?? this.riddlesVersion,folderId: folderId.present ? folderId.value : this.folderId,sortOrder: sortOrder ?? this.sortOrder,);RiddleMap copyWithCompanion(RiddleMapsCompanion data) {
return RiddleMap(
id: data.id.present ? data.id.value : this.id,title: data.title.present ? data.title.value : this.title,description: data.description.present ? data.description.value : this.description,subject: data.subject.present ? data.subject.value : this.subject,imageBytes: data.imageBytes.present ? data.imageBytes.value : this.imageBytes,createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,riddlesVersion: data.riddlesVersion.present ? data.riddlesVersion.value : this.riddlesVersion,folderId: data.folderId.present ? data.folderId.value : this.folderId,sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,);
}
@override
String toString() {return (StringBuffer('RiddleMap(')..write('id: $id, ')..write('title: $title, ')..write('description: $description, ')..write('subject: $subject, ')..write('imageBytes: $imageBytes, ')..write('createdAt: $createdAt, ')..write('riddlesVersion: $riddlesVersion, ')..write('folderId: $folderId, ')..write('sortOrder: $sortOrder')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, title, description, subject, $driftBlobEquality.hash(imageBytes), createdAt, riddlesVersion, folderId, sortOrder);@override
bool operator ==(Object other) => identical(this, other) || (other is RiddleMap && other.id == this.id && other.title == this.title && other.description == this.description && other.subject == this.subject && $driftBlobEquality.equals(other.imageBytes, this.imageBytes) && other.createdAt == this.createdAt && other.riddlesVersion == this.riddlesVersion && other.folderId == this.folderId && other.sortOrder == this.sortOrder);
}class RiddleMapsCompanion extends UpdateCompanion<RiddleMap> {
final Value<String> id;
final Value<String> title;
final Value<String?> description;
final Value<String?> subject;
final Value<Uint8List?> imageBytes;
final Value<DateTime> createdAt;
final Value<int> riddlesVersion;
final Value<int?> folderId;
final Value<int> sortOrder;
final Value<int> rowid;
const RiddleMapsCompanion({this.id = const Value.absent(),this.title = const Value.absent(),this.description = const Value.absent(),this.subject = const Value.absent(),this.imageBytes = const Value.absent(),this.createdAt = const Value.absent(),this.riddlesVersion = const Value.absent(),this.folderId = const Value.absent(),this.sortOrder = const Value.absent(),this.rowid = const Value.absent(),});
RiddleMapsCompanion.insert({required String id,required String title,this.description = const Value.absent(),this.subject = const Value.absent(),this.imageBytes = const Value.absent(),this.createdAt = const Value.absent(),this.riddlesVersion = const Value.absent(),this.folderId = const Value.absent(),this.sortOrder = const Value.absent(),this.rowid = const Value.absent(),}): id = Value(id), title = Value(title);
static Insertable<RiddleMap> custom({Expression<String>? id, 
Expression<String>? title, 
Expression<String>? description, 
Expression<String>? subject, 
Expression<Uint8List>? imageBytes, 
Expression<DateTime>? createdAt, 
Expression<int>? riddlesVersion, 
Expression<int>? folderId, 
Expression<int>? sortOrder, 
Expression<int>? rowid, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (title != null)'title': title,if (description != null)'description': description,if (subject != null)'subject': subject,if (imageBytes != null)'image_bytes': imageBytes,if (createdAt != null)'created_at': createdAt,if (riddlesVersion != null)'riddles_version': riddlesVersion,if (folderId != null)'folder_id': folderId,if (sortOrder != null)'sort_order': sortOrder,if (rowid != null)'rowid': rowid,});
}RiddleMapsCompanion copyWith({Value<String>? id, Value<String>? title, Value<String?>? description, Value<String?>? subject, Value<Uint8List?>? imageBytes, Value<DateTime>? createdAt, Value<int>? riddlesVersion, Value<int?>? folderId, Value<int>? sortOrder, Value<int>? rowid}) {
return RiddleMapsCompanion(id: id ?? this.id,title: title ?? this.title,description: description ?? this.description,subject: subject ?? this.subject,imageBytes: imageBytes ?? this.imageBytes,createdAt: createdAt ?? this.createdAt,riddlesVersion: riddlesVersion ?? this.riddlesVersion,folderId: folderId ?? this.folderId,sortOrder: sortOrder ?? this.sortOrder,rowid: rowid ?? this.rowid,);
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
if (riddlesVersion.present) {
map['riddles_version'] = Variable<int>(riddlesVersion.value);}
if (folderId.present) {
map['folder_id'] = Variable<int>(folderId.value);}
if (sortOrder.present) {
map['sort_order'] = Variable<int>(sortOrder.value);}
if (rowid.present) {
map['rowid'] = Variable<int>(rowid.value);}
return map; 
}
@override
String toString() {return (StringBuffer('RiddleMapsCompanion(')..write('id: $id, ')..write('title: $title, ')..write('description: $description, ')..write('subject: $subject, ')..write('imageBytes: $imageBytes, ')..write('createdAt: $createdAt, ')..write('riddlesVersion: $riddlesVersion, ')..write('folderId: $folderId, ')..write('sortOrder: $sortOrder, ')..write('rowid: $rowid')..write(')')).toString();}
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
static const VerificationMeta _sourceExcerptMeta = const VerificationMeta('sourceExcerpt');
@override
late final GeneratedColumn<String> sourceExcerpt = GeneratedColumn<String>('source_excerpt', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [id, mapId, question, typeIndex, orderInMap, payloadJson, choicesJson, correctIndex, sourceExcerpt];
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
context.handle(_correctIndexMeta, correctIndex.isAcceptableOrUnknown(data['correct_index']!, _correctIndexMeta));}if (data.containsKey('source_excerpt')) {
context.handle(_sourceExcerptMeta, sourceExcerpt.isAcceptableOrUnknown(data['source_excerpt']!, _sourceExcerptMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Riddle map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Riddle(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, mapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}map_id'])!, question: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}question'])!, typeIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}type_index'])!, orderInMap: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}order_in_map'])!, payloadJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload_json']), choicesJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}choices_json']), correctIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct_index']), sourceExcerpt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_excerpt']), );
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
final String? sourceExcerpt;
const Riddle({required this.id, required this.mapId, required this.question, required this.typeIndex, required this.orderInMap, this.payloadJson, this.choicesJson, this.correctIndex, this.sourceExcerpt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['map_id'] = Variable<String>(mapId);
map['question'] = Variable<String>(question);
map['type_index'] = Variable<int>(typeIndex);
map['order_in_map'] = Variable<int>(orderInMap);
if (!nullToAbsent || payloadJson != null){map['payload_json'] = Variable<String>(payloadJson);
}if (!nullToAbsent || choicesJson != null){map['choices_json'] = Variable<String>(choicesJson);
}if (!nullToAbsent || correctIndex != null){map['correct_index'] = Variable<int>(correctIndex);
}if (!nullToAbsent || sourceExcerpt != null){map['source_excerpt'] = Variable<String>(sourceExcerpt);
}return map; 
}
RiddlesCompanion toCompanion(bool nullToAbsent) {
return RiddlesCompanion(id: Value(id),mapId: Value(mapId),question: Value(question),typeIndex: Value(typeIndex),orderInMap: Value(orderInMap),payloadJson: payloadJson == null && nullToAbsent ? const Value.absent() : Value(payloadJson),choicesJson: choicesJson == null && nullToAbsent ? const Value.absent() : Value(choicesJson),correctIndex: correctIndex == null && nullToAbsent ? const Value.absent() : Value(correctIndex),sourceExcerpt: sourceExcerpt == null && nullToAbsent ? const Value.absent() : Value(sourceExcerpt),);
}
factory Riddle.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Riddle(id: serializer.fromJson<int>(json['id']),mapId: serializer.fromJson<String>(json['mapId']),question: serializer.fromJson<String>(json['question']),typeIndex: serializer.fromJson<int>(json['typeIndex']),orderInMap: serializer.fromJson<int>(json['orderInMap']),payloadJson: serializer.fromJson<String?>(json['payloadJson']),choicesJson: serializer.fromJson<String?>(json['choicesJson']),correctIndex: serializer.fromJson<int?>(json['correctIndex']),sourceExcerpt: serializer.fromJson<String?>(json['sourceExcerpt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'mapId': serializer.toJson<String>(mapId),'question': serializer.toJson<String>(question),'typeIndex': serializer.toJson<int>(typeIndex),'orderInMap': serializer.toJson<int>(orderInMap),'payloadJson': serializer.toJson<String?>(payloadJson),'choicesJson': serializer.toJson<String?>(choicesJson),'correctIndex': serializer.toJson<int?>(correctIndex),'sourceExcerpt': serializer.toJson<String?>(sourceExcerpt),};}Riddle copyWith({int? id,String? mapId,String? question,int? typeIndex,int? orderInMap,Value<String?> payloadJson = const Value.absent(),Value<String?> choicesJson = const Value.absent(),Value<int?> correctIndex = const Value.absent(),Value<String?> sourceExcerpt = const Value.absent()}) => Riddle(id: id ?? this.id,mapId: mapId ?? this.mapId,question: question ?? this.question,typeIndex: typeIndex ?? this.typeIndex,orderInMap: orderInMap ?? this.orderInMap,payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,choicesJson: choicesJson.present ? choicesJson.value : this.choicesJson,correctIndex: correctIndex.present ? correctIndex.value : this.correctIndex,sourceExcerpt: sourceExcerpt.present ? sourceExcerpt.value : this.sourceExcerpt,);Riddle copyWithCompanion(RiddlesCompanion data) {
return Riddle(
id: data.id.present ? data.id.value : this.id,mapId: data.mapId.present ? data.mapId.value : this.mapId,question: data.question.present ? data.question.value : this.question,typeIndex: data.typeIndex.present ? data.typeIndex.value : this.typeIndex,orderInMap: data.orderInMap.present ? data.orderInMap.value : this.orderInMap,payloadJson: data.payloadJson.present ? data.payloadJson.value : this.payloadJson,choicesJson: data.choicesJson.present ? data.choicesJson.value : this.choicesJson,correctIndex: data.correctIndex.present ? data.correctIndex.value : this.correctIndex,sourceExcerpt: data.sourceExcerpt.present ? data.sourceExcerpt.value : this.sourceExcerpt,);
}
@override
String toString() {return (StringBuffer('Riddle(')..write('id: $id, ')..write('mapId: $mapId, ')..write('question: $question, ')..write('typeIndex: $typeIndex, ')..write('orderInMap: $orderInMap, ')..write('payloadJson: $payloadJson, ')..write('choicesJson: $choicesJson, ')..write('correctIndex: $correctIndex, ')..write('sourceExcerpt: $sourceExcerpt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, mapId, question, typeIndex, orderInMap, payloadJson, choicesJson, correctIndex, sourceExcerpt);@override
bool operator ==(Object other) => identical(this, other) || (other is Riddle && other.id == this.id && other.mapId == this.mapId && other.question == this.question && other.typeIndex == this.typeIndex && other.orderInMap == this.orderInMap && other.payloadJson == this.payloadJson && other.choicesJson == this.choicesJson && other.correctIndex == this.correctIndex && other.sourceExcerpt == this.sourceExcerpt);
}class RiddlesCompanion extends UpdateCompanion<Riddle> {
final Value<int> id;
final Value<String> mapId;
final Value<String> question;
final Value<int> typeIndex;
final Value<int> orderInMap;
final Value<String?> payloadJson;
final Value<String?> choicesJson;
final Value<int?> correctIndex;
final Value<String?> sourceExcerpt;
const RiddlesCompanion({this.id = const Value.absent(),this.mapId = const Value.absent(),this.question = const Value.absent(),this.typeIndex = const Value.absent(),this.orderInMap = const Value.absent(),this.payloadJson = const Value.absent(),this.choicesJson = const Value.absent(),this.correctIndex = const Value.absent(),this.sourceExcerpt = const Value.absent(),});
RiddlesCompanion.insert({this.id = const Value.absent(),required String mapId,required String question,required int typeIndex,required int orderInMap,this.payloadJson = const Value.absent(),this.choicesJson = const Value.absent(),this.correctIndex = const Value.absent(),this.sourceExcerpt = const Value.absent(),}): mapId = Value(mapId), question = Value(question), typeIndex = Value(typeIndex), orderInMap = Value(orderInMap);
static Insertable<Riddle> custom({Expression<int>? id, 
Expression<String>? mapId, 
Expression<String>? question, 
Expression<int>? typeIndex, 
Expression<int>? orderInMap, 
Expression<String>? payloadJson, 
Expression<String>? choicesJson, 
Expression<int>? correctIndex, 
Expression<String>? sourceExcerpt, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (mapId != null)'map_id': mapId,if (question != null)'question': question,if (typeIndex != null)'type_index': typeIndex,if (orderInMap != null)'order_in_map': orderInMap,if (payloadJson != null)'payload_json': payloadJson,if (choicesJson != null)'choices_json': choicesJson,if (correctIndex != null)'correct_index': correctIndex,if (sourceExcerpt != null)'source_excerpt': sourceExcerpt,});
}RiddlesCompanion copyWith({Value<int>? id, Value<String>? mapId, Value<String>? question, Value<int>? typeIndex, Value<int>? orderInMap, Value<String?>? payloadJson, Value<String?>? choicesJson, Value<int?>? correctIndex, Value<String?>? sourceExcerpt}) {
return RiddlesCompanion(id: id ?? this.id,mapId: mapId ?? this.mapId,question: question ?? this.question,typeIndex: typeIndex ?? this.typeIndex,orderInMap: orderInMap ?? this.orderInMap,payloadJson: payloadJson ?? this.payloadJson,choicesJson: choicesJson ?? this.choicesJson,correctIndex: correctIndex ?? this.correctIndex,sourceExcerpt: sourceExcerpt ?? this.sourceExcerpt,);
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
if (sourceExcerpt.present) {
map['source_excerpt'] = Variable<String>(sourceExcerpt.value);}
return map; 
}
@override
String toString() {return (StringBuffer('RiddlesCompanion(')..write('id: $id, ')..write('mapId: $mapId, ')..write('question: $question, ')..write('typeIndex: $typeIndex, ')..write('orderInMap: $orderInMap, ')..write('payloadJson: $payloadJson, ')..write('choicesJson: $choicesJson, ')..write('correctIndex: $correctIndex, ')..write('sourceExcerpt: $sourceExcerpt')..write(')')).toString();}
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
static const VerificationMeta _riddlesVersionMeta = const VerificationMeta('riddlesVersion');
@override
late final GeneratedColumn<int> riddlesVersion = GeneratedColumn<int>('riddles_version', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
@override
List<GeneratedColumn> get $columns => [id, publicId, mapId, lastCompletedIndex, startedAt, completedAt, totalRiddles, correctAnswers, riddleStarsJson, riddlesVersion];
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
context.handle(_riddleStarsJsonMeta, riddleStarsJson.isAcceptableOrUnknown(data['riddle_stars_json']!, _riddleStarsJsonMeta));}if (data.containsKey('riddles_version')) {
context.handle(_riddlesVersionMeta, riddlesVersion.isAcceptableOrUnknown(data['riddles_version']!, _riddlesVersionMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override PlaySession map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return PlaySession(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, publicId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}public_id'])!, mapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}map_id'])!, lastCompletedIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}last_completed_index'])!, startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!, completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']), totalRiddles: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}total_riddles'])!, correctAnswers: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct_answers'])!, riddleStarsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}riddle_stars_json']), riddlesVersion: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}riddles_version'])!, );
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
final int riddlesVersion;
const PlaySession({required this.id, required this.publicId, required this.mapId, required this.lastCompletedIndex, required this.startedAt, this.completedAt, required this.totalRiddles, required this.correctAnswers, this.riddleStarsJson, required this.riddlesVersion});@override
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
}map['riddles_version'] = Variable<int>(riddlesVersion);
return map; 
}
PlaySessionsCompanion toCompanion(bool nullToAbsent) {
return PlaySessionsCompanion(id: Value(id),publicId: Value(publicId),mapId: Value(mapId),lastCompletedIndex: Value(lastCompletedIndex),startedAt: Value(startedAt),completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),totalRiddles: Value(totalRiddles),correctAnswers: Value(correctAnswers),riddleStarsJson: riddleStarsJson == null && nullToAbsent ? const Value.absent() : Value(riddleStarsJson),riddlesVersion: Value(riddlesVersion),);
}
factory PlaySession.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return PlaySession(id: serializer.fromJson<int>(json['id']),publicId: serializer.fromJson<String>(json['publicId']),mapId: serializer.fromJson<String>(json['mapId']),lastCompletedIndex: serializer.fromJson<int>(json['lastCompletedIndex']),startedAt: serializer.fromJson<DateTime>(json['startedAt']),completedAt: serializer.fromJson<DateTime?>(json['completedAt']),totalRiddles: serializer.fromJson<int>(json['totalRiddles']),correctAnswers: serializer.fromJson<int>(json['correctAnswers']),riddleStarsJson: serializer.fromJson<String?>(json['riddleStarsJson']),riddlesVersion: serializer.fromJson<int>(json['riddlesVersion']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'publicId': serializer.toJson<String>(publicId),'mapId': serializer.toJson<String>(mapId),'lastCompletedIndex': serializer.toJson<int>(lastCompletedIndex),'startedAt': serializer.toJson<DateTime>(startedAt),'completedAt': serializer.toJson<DateTime?>(completedAt),'totalRiddles': serializer.toJson<int>(totalRiddles),'correctAnswers': serializer.toJson<int>(correctAnswers),'riddleStarsJson': serializer.toJson<String?>(riddleStarsJson),'riddlesVersion': serializer.toJson<int>(riddlesVersion),};}PlaySession copyWith({int? id,String? publicId,String? mapId,int? lastCompletedIndex,DateTime? startedAt,Value<DateTime?> completedAt = const Value.absent(),int? totalRiddles,int? correctAnswers,Value<String?> riddleStarsJson = const Value.absent(),int? riddlesVersion}) => PlaySession(id: id ?? this.id,publicId: publicId ?? this.publicId,mapId: mapId ?? this.mapId,lastCompletedIndex: lastCompletedIndex ?? this.lastCompletedIndex,startedAt: startedAt ?? this.startedAt,completedAt: completedAt.present ? completedAt.value : this.completedAt,totalRiddles: totalRiddles ?? this.totalRiddles,correctAnswers: correctAnswers ?? this.correctAnswers,riddleStarsJson: riddleStarsJson.present ? riddleStarsJson.value : this.riddleStarsJson,riddlesVersion: riddlesVersion ?? this.riddlesVersion,);PlaySession copyWithCompanion(PlaySessionsCompanion data) {
return PlaySession(
id: data.id.present ? data.id.value : this.id,publicId: data.publicId.present ? data.publicId.value : this.publicId,mapId: data.mapId.present ? data.mapId.value : this.mapId,lastCompletedIndex: data.lastCompletedIndex.present ? data.lastCompletedIndex.value : this.lastCompletedIndex,startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,totalRiddles: data.totalRiddles.present ? data.totalRiddles.value : this.totalRiddles,correctAnswers: data.correctAnswers.present ? data.correctAnswers.value : this.correctAnswers,riddleStarsJson: data.riddleStarsJson.present ? data.riddleStarsJson.value : this.riddleStarsJson,riddlesVersion: data.riddlesVersion.present ? data.riddlesVersion.value : this.riddlesVersion,);
}
@override
String toString() {return (StringBuffer('PlaySession(')..write('id: $id, ')..write('publicId: $publicId, ')..write('mapId: $mapId, ')..write('lastCompletedIndex: $lastCompletedIndex, ')..write('startedAt: $startedAt, ')..write('completedAt: $completedAt, ')..write('totalRiddles: $totalRiddles, ')..write('correctAnswers: $correctAnswers, ')..write('riddleStarsJson: $riddleStarsJson, ')..write('riddlesVersion: $riddlesVersion')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, publicId, mapId, lastCompletedIndex, startedAt, completedAt, totalRiddles, correctAnswers, riddleStarsJson, riddlesVersion);@override
bool operator ==(Object other) => identical(this, other) || (other is PlaySession && other.id == this.id && other.publicId == this.publicId && other.mapId == this.mapId && other.lastCompletedIndex == this.lastCompletedIndex && other.startedAt == this.startedAt && other.completedAt == this.completedAt && other.totalRiddles == this.totalRiddles && other.correctAnswers == this.correctAnswers && other.riddleStarsJson == this.riddleStarsJson && other.riddlesVersion == this.riddlesVersion);
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
final Value<int> riddlesVersion;
const PlaySessionsCompanion({this.id = const Value.absent(),this.publicId = const Value.absent(),this.mapId = const Value.absent(),this.lastCompletedIndex = const Value.absent(),this.startedAt = const Value.absent(),this.completedAt = const Value.absent(),this.totalRiddles = const Value.absent(),this.correctAnswers = const Value.absent(),this.riddleStarsJson = const Value.absent(),this.riddlesVersion = const Value.absent(),});
PlaySessionsCompanion.insert({this.id = const Value.absent(),this.publicId = const Value.absent(),required String mapId,this.lastCompletedIndex = const Value.absent(),this.startedAt = const Value.absent(),this.completedAt = const Value.absent(),this.totalRiddles = const Value.absent(),this.correctAnswers = const Value.absent(),this.riddleStarsJson = const Value.absent(),this.riddlesVersion = const Value.absent(),}): mapId = Value(mapId);
static Insertable<PlaySession> custom({Expression<int>? id, 
Expression<String>? publicId, 
Expression<String>? mapId, 
Expression<int>? lastCompletedIndex, 
Expression<DateTime>? startedAt, 
Expression<DateTime>? completedAt, 
Expression<int>? totalRiddles, 
Expression<int>? correctAnswers, 
Expression<String>? riddleStarsJson, 
Expression<int>? riddlesVersion, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (publicId != null)'public_id': publicId,if (mapId != null)'map_id': mapId,if (lastCompletedIndex != null)'last_completed_index': lastCompletedIndex,if (startedAt != null)'started_at': startedAt,if (completedAt != null)'completed_at': completedAt,if (totalRiddles != null)'total_riddles': totalRiddles,if (correctAnswers != null)'correct_answers': correctAnswers,if (riddleStarsJson != null)'riddle_stars_json': riddleStarsJson,if (riddlesVersion != null)'riddles_version': riddlesVersion,});
}PlaySessionsCompanion copyWith({Value<int>? id, Value<String>? publicId, Value<String>? mapId, Value<int>? lastCompletedIndex, Value<DateTime>? startedAt, Value<DateTime?>? completedAt, Value<int>? totalRiddles, Value<int>? correctAnswers, Value<String?>? riddleStarsJson, Value<int>? riddlesVersion}) {
return PlaySessionsCompanion(id: id ?? this.id,publicId: publicId ?? this.publicId,mapId: mapId ?? this.mapId,lastCompletedIndex: lastCompletedIndex ?? this.lastCompletedIndex,startedAt: startedAt ?? this.startedAt,completedAt: completedAt ?? this.completedAt,totalRiddles: totalRiddles ?? this.totalRiddles,correctAnswers: correctAnswers ?? this.correctAnswers,riddleStarsJson: riddleStarsJson ?? this.riddleStarsJson,riddlesVersion: riddlesVersion ?? this.riddlesVersion,);
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
if (riddlesVersion.present) {
map['riddles_version'] = Variable<int>(riddlesVersion.value);}
return map; 
}
@override
String toString() {return (StringBuffer('PlaySessionsCompanion(')..write('id: $id, ')..write('publicId: $publicId, ')..write('mapId: $mapId, ')..write('lastCompletedIndex: $lastCompletedIndex, ')..write('startedAt: $startedAt, ')..write('completedAt: $completedAt, ')..write('totalRiddles: $totalRiddles, ')..write('correctAnswers: $correctAnswers, ')..write('riddleStarsJson: $riddleStarsJson, ')..write('riddlesVersion: $riddlesVersion')..write(')')).toString();}
}
class $TrainingSessionsTable extends TrainingSessions with TableInfo<$TrainingSessionsTable, TrainingSession>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$TrainingSessionsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
@override
late final GeneratedColumn<String> mapId = GeneratedColumn<String>('map_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES riddle_maps (id) ON DELETE CASCADE'));
static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
@override
late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>('started_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
@override
late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>('ends_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
static const VerificationMeta _poolJsonMeta = const VerificationMeta('poolJson');
@override
late final GeneratedColumn<String> poolJson = GeneratedColumn<String>('pool_json', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: false, defaultValue: const Constant('[]'));
static const VerificationMeta _scheduledJsonMeta = const VerificationMeta('scheduledJson');
@override
late final GeneratedColumn<String> scheduledJson = GeneratedColumn<String>('scheduled_json', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: false, defaultValue: const Constant('[]'));
static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
@override
late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>('completed_at', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [id, mapId, startedAt, endsAt, poolJson, scheduledJson, completedAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'training_sessions';
@override
VerificationContext validateIntegrity(Insertable<TrainingSession> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('map_id')) {
context.handle(_mapIdMeta, mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta));} else if (isInserting) {
context.missing(_mapIdMeta);
}
if (data.containsKey('started_at')) {
context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));}if (data.containsKey('ends_at')) {
context.handle(_endsAtMeta, endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta));} else if (isInserting) {
context.missing(_endsAtMeta);
}
if (data.containsKey('pool_json')) {
context.handle(_poolJsonMeta, poolJson.isAcceptableOrUnknown(data['pool_json']!, _poolJsonMeta));}if (data.containsKey('scheduled_json')) {
context.handle(_scheduledJsonMeta, scheduledJson.isAcceptableOrUnknown(data['scheduled_json']!, _scheduledJsonMeta));}if (data.containsKey('completed_at')) {
context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override TrainingSession map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return TrainingSession(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, mapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}map_id'])!, startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!, endsAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}ends_at'])!, poolJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pool_json'])!, scheduledJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scheduled_json'])!, completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']), );
}
@override
$TrainingSessionsTable createAlias(String alias) {
return $TrainingSessionsTable(attachedDatabase, alias);}}class TrainingSession extends DataClass implements Insertable<TrainingSession> 
{
final int id;
final String mapId;
final DateTime startedAt;
final DateTime endsAt;
final String poolJson;
final String scheduledJson;
final DateTime? completedAt;
const TrainingSession({required this.id, required this.mapId, required this.startedAt, required this.endsAt, required this.poolJson, required this.scheduledJson, this.completedAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['map_id'] = Variable<String>(mapId);
map['started_at'] = Variable<DateTime>(startedAt);
map['ends_at'] = Variable<DateTime>(endsAt);
map['pool_json'] = Variable<String>(poolJson);
map['scheduled_json'] = Variable<String>(scheduledJson);
if (!nullToAbsent || completedAt != null){map['completed_at'] = Variable<DateTime>(completedAt);
}return map; 
}
TrainingSessionsCompanion toCompanion(bool nullToAbsent) {
return TrainingSessionsCompanion(id: Value(id),mapId: Value(mapId),startedAt: Value(startedAt),endsAt: Value(endsAt),poolJson: Value(poolJson),scheduledJson: Value(scheduledJson),completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),);
}
factory TrainingSession.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return TrainingSession(id: serializer.fromJson<int>(json['id']),mapId: serializer.fromJson<String>(json['mapId']),startedAt: serializer.fromJson<DateTime>(json['startedAt']),endsAt: serializer.fromJson<DateTime>(json['endsAt']),poolJson: serializer.fromJson<String>(json['poolJson']),scheduledJson: serializer.fromJson<String>(json['scheduledJson']),completedAt: serializer.fromJson<DateTime?>(json['completedAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'mapId': serializer.toJson<String>(mapId),'startedAt': serializer.toJson<DateTime>(startedAt),'endsAt': serializer.toJson<DateTime>(endsAt),'poolJson': serializer.toJson<String>(poolJson),'scheduledJson': serializer.toJson<String>(scheduledJson),'completedAt': serializer.toJson<DateTime?>(completedAt),};}TrainingSession copyWith({int? id,String? mapId,DateTime? startedAt,DateTime? endsAt,String? poolJson,String? scheduledJson,Value<DateTime?> completedAt = const Value.absent()}) => TrainingSession(id: id ?? this.id,mapId: mapId ?? this.mapId,startedAt: startedAt ?? this.startedAt,endsAt: endsAt ?? this.endsAt,poolJson: poolJson ?? this.poolJson,scheduledJson: scheduledJson ?? this.scheduledJson,completedAt: completedAt.present ? completedAt.value : this.completedAt,);TrainingSession copyWithCompanion(TrainingSessionsCompanion data) {
return TrainingSession(
id: data.id.present ? data.id.value : this.id,mapId: data.mapId.present ? data.mapId.value : this.mapId,startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,poolJson: data.poolJson.present ? data.poolJson.value : this.poolJson,scheduledJson: data.scheduledJson.present ? data.scheduledJson.value : this.scheduledJson,completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,);
}
@override
String toString() {return (StringBuffer('TrainingSession(')..write('id: $id, ')..write('mapId: $mapId, ')..write('startedAt: $startedAt, ')..write('endsAt: $endsAt, ')..write('poolJson: $poolJson, ')..write('scheduledJson: $scheduledJson, ')..write('completedAt: $completedAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, mapId, startedAt, endsAt, poolJson, scheduledJson, completedAt);@override
bool operator ==(Object other) => identical(this, other) || (other is TrainingSession && other.id == this.id && other.mapId == this.mapId && other.startedAt == this.startedAt && other.endsAt == this.endsAt && other.poolJson == this.poolJson && other.scheduledJson == this.scheduledJson && other.completedAt == this.completedAt);
}class TrainingSessionsCompanion extends UpdateCompanion<TrainingSession> {
final Value<int> id;
final Value<String> mapId;
final Value<DateTime> startedAt;
final Value<DateTime> endsAt;
final Value<String> poolJson;
final Value<String> scheduledJson;
final Value<DateTime?> completedAt;
const TrainingSessionsCompanion({this.id = const Value.absent(),this.mapId = const Value.absent(),this.startedAt = const Value.absent(),this.endsAt = const Value.absent(),this.poolJson = const Value.absent(),this.scheduledJson = const Value.absent(),this.completedAt = const Value.absent(),});
TrainingSessionsCompanion.insert({this.id = const Value.absent(),required String mapId,this.startedAt = const Value.absent(),required DateTime endsAt,this.poolJson = const Value.absent(),this.scheduledJson = const Value.absent(),this.completedAt = const Value.absent(),}): mapId = Value(mapId), endsAt = Value(endsAt);
static Insertable<TrainingSession> custom({Expression<int>? id, 
Expression<String>? mapId, 
Expression<DateTime>? startedAt, 
Expression<DateTime>? endsAt, 
Expression<String>? poolJson, 
Expression<String>? scheduledJson, 
Expression<DateTime>? completedAt, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (mapId != null)'map_id': mapId,if (startedAt != null)'started_at': startedAt,if (endsAt != null)'ends_at': endsAt,if (poolJson != null)'pool_json': poolJson,if (scheduledJson != null)'scheduled_json': scheduledJson,if (completedAt != null)'completed_at': completedAt,});
}TrainingSessionsCompanion copyWith({Value<int>? id, Value<String>? mapId, Value<DateTime>? startedAt, Value<DateTime>? endsAt, Value<String>? poolJson, Value<String>? scheduledJson, Value<DateTime?>? completedAt}) {
return TrainingSessionsCompanion(id: id ?? this.id,mapId: mapId ?? this.mapId,startedAt: startedAt ?? this.startedAt,endsAt: endsAt ?? this.endsAt,poolJson: poolJson ?? this.poolJson,scheduledJson: scheduledJson ?? this.scheduledJson,completedAt: completedAt ?? this.completedAt,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (mapId.present) {
map['map_id'] = Variable<String>(mapId.value);}
if (startedAt.present) {
map['started_at'] = Variable<DateTime>(startedAt.value);}
if (endsAt.present) {
map['ends_at'] = Variable<DateTime>(endsAt.value);}
if (poolJson.present) {
map['pool_json'] = Variable<String>(poolJson.value);}
if (scheduledJson.present) {
map['scheduled_json'] = Variable<String>(scheduledJson.value);}
if (completedAt.present) {
map['completed_at'] = Variable<DateTime>(completedAt.value);}
return map; 
}
@override
String toString() {return (StringBuffer('TrainingSessionsCompanion(')..write('id: $id, ')..write('mapId: $mapId, ')..write('startedAt: $startedAt, ')..write('endsAt: $endsAt, ')..write('poolJson: $poolJson, ')..write('scheduledJson: $scheduledJson, ')..write('completedAt: $completedAt')..write(')')).toString();}
}
class $TrainingNotifiedRiddlesTable extends TrainingNotifiedRiddles with TableInfo<$TrainingNotifiedRiddlesTable, TrainingNotifiedRiddle>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$TrainingNotifiedRiddlesTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
@override
late final GeneratedColumn<int> sessionId = GeneratedColumn<int>('session_id', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES training_sessions (id) ON DELETE CASCADE'));
static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
@override
late final GeneratedColumn<String> mapId = GeneratedColumn<String>('map_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _riddleIdMeta = const VerificationMeta('riddleId');
@override
late final GeneratedColumn<int> riddleId = GeneratedColumn<int>('riddle_id', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES riddles (id) ON DELETE CASCADE'));
static const VerificationMeta _notifiedAtMeta = const VerificationMeta('notifiedAt');
@override
late final GeneratedColumn<DateTime> notifiedAt = GeneratedColumn<DateTime>('notified_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
@override
List<GeneratedColumn> get $columns => [id, sessionId, mapId, riddleId, notifiedAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'training_notified_riddles';
@override
VerificationContext validateIntegrity(Insertable<TrainingNotifiedRiddle> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('session_id')) {
context.handle(_sessionIdMeta, sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));} else if (isInserting) {
context.missing(_sessionIdMeta);
}
if (data.containsKey('map_id')) {
context.handle(_mapIdMeta, mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta));} else if (isInserting) {
context.missing(_mapIdMeta);
}
if (data.containsKey('riddle_id')) {
context.handle(_riddleIdMeta, riddleId.isAcceptableOrUnknown(data['riddle_id']!, _riddleIdMeta));} else if (isInserting) {
context.missing(_riddleIdMeta);
}
if (data.containsKey('notified_at')) {
context.handle(_notifiedAtMeta, notifiedAt.isAcceptableOrUnknown(data['notified_at']!, _notifiedAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override TrainingNotifiedRiddle map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return TrainingNotifiedRiddle(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, sessionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}session_id'])!, mapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}map_id'])!, riddleId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}riddle_id'])!, notifiedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}notified_at'])!, );
}
@override
$TrainingNotifiedRiddlesTable createAlias(String alias) {
return $TrainingNotifiedRiddlesTable(attachedDatabase, alias);}}class TrainingNotifiedRiddle extends DataClass implements Insertable<TrainingNotifiedRiddle> 
{
final int id;
final int sessionId;
final String mapId;
final int riddleId;
final DateTime notifiedAt;
const TrainingNotifiedRiddle({required this.id, required this.sessionId, required this.mapId, required this.riddleId, required this.notifiedAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['session_id'] = Variable<int>(sessionId);
map['map_id'] = Variable<String>(mapId);
map['riddle_id'] = Variable<int>(riddleId);
map['notified_at'] = Variable<DateTime>(notifiedAt);
return map; 
}
TrainingNotifiedRiddlesCompanion toCompanion(bool nullToAbsent) {
return TrainingNotifiedRiddlesCompanion(id: Value(id),sessionId: Value(sessionId),mapId: Value(mapId),riddleId: Value(riddleId),notifiedAt: Value(notifiedAt),);
}
factory TrainingNotifiedRiddle.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return TrainingNotifiedRiddle(id: serializer.fromJson<int>(json['id']),sessionId: serializer.fromJson<int>(json['sessionId']),mapId: serializer.fromJson<String>(json['mapId']),riddleId: serializer.fromJson<int>(json['riddleId']),notifiedAt: serializer.fromJson<DateTime>(json['notifiedAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'sessionId': serializer.toJson<int>(sessionId),'mapId': serializer.toJson<String>(mapId),'riddleId': serializer.toJson<int>(riddleId),'notifiedAt': serializer.toJson<DateTime>(notifiedAt),};}TrainingNotifiedRiddle copyWith({int? id,int? sessionId,String? mapId,int? riddleId,DateTime? notifiedAt}) => TrainingNotifiedRiddle(id: id ?? this.id,sessionId: sessionId ?? this.sessionId,mapId: mapId ?? this.mapId,riddleId: riddleId ?? this.riddleId,notifiedAt: notifiedAt ?? this.notifiedAt,);TrainingNotifiedRiddle copyWithCompanion(TrainingNotifiedRiddlesCompanion data) {
return TrainingNotifiedRiddle(
id: data.id.present ? data.id.value : this.id,sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,mapId: data.mapId.present ? data.mapId.value : this.mapId,riddleId: data.riddleId.present ? data.riddleId.value : this.riddleId,notifiedAt: data.notifiedAt.present ? data.notifiedAt.value : this.notifiedAt,);
}
@override
String toString() {return (StringBuffer('TrainingNotifiedRiddle(')..write('id: $id, ')..write('sessionId: $sessionId, ')..write('mapId: $mapId, ')..write('riddleId: $riddleId, ')..write('notifiedAt: $notifiedAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, sessionId, mapId, riddleId, notifiedAt);@override
bool operator ==(Object other) => identical(this, other) || (other is TrainingNotifiedRiddle && other.id == this.id && other.sessionId == this.sessionId && other.mapId == this.mapId && other.riddleId == this.riddleId && other.notifiedAt == this.notifiedAt);
}class TrainingNotifiedRiddlesCompanion extends UpdateCompanion<TrainingNotifiedRiddle> {
final Value<int> id;
final Value<int> sessionId;
final Value<String> mapId;
final Value<int> riddleId;
final Value<DateTime> notifiedAt;
const TrainingNotifiedRiddlesCompanion({this.id = const Value.absent(),this.sessionId = const Value.absent(),this.mapId = const Value.absent(),this.riddleId = const Value.absent(),this.notifiedAt = const Value.absent(),});
TrainingNotifiedRiddlesCompanion.insert({this.id = const Value.absent(),required int sessionId,required String mapId,required int riddleId,this.notifiedAt = const Value.absent(),}): sessionId = Value(sessionId), mapId = Value(mapId), riddleId = Value(riddleId);
static Insertable<TrainingNotifiedRiddle> custom({Expression<int>? id, 
Expression<int>? sessionId, 
Expression<String>? mapId, 
Expression<int>? riddleId, 
Expression<DateTime>? notifiedAt, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (sessionId != null)'session_id': sessionId,if (mapId != null)'map_id': mapId,if (riddleId != null)'riddle_id': riddleId,if (notifiedAt != null)'notified_at': notifiedAt,});
}TrainingNotifiedRiddlesCompanion copyWith({Value<int>? id, Value<int>? sessionId, Value<String>? mapId, Value<int>? riddleId, Value<DateTime>? notifiedAt}) {
return TrainingNotifiedRiddlesCompanion(id: id ?? this.id,sessionId: sessionId ?? this.sessionId,mapId: mapId ?? this.mapId,riddleId: riddleId ?? this.riddleId,notifiedAt: notifiedAt ?? this.notifiedAt,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (sessionId.present) {
map['session_id'] = Variable<int>(sessionId.value);}
if (mapId.present) {
map['map_id'] = Variable<String>(mapId.value);}
if (riddleId.present) {
map['riddle_id'] = Variable<int>(riddleId.value);}
if (notifiedAt.present) {
map['notified_at'] = Variable<DateTime>(notifiedAt.value);}
return map; 
}
@override
String toString() {return (StringBuffer('TrainingNotifiedRiddlesCompanion(')..write('id: $id, ')..write('sessionId: $sessionId, ')..write('mapId: $mapId, ')..write('riddleId: $riddleId, ')..write('notifiedAt: $notifiedAt')..write(')')).toString();}
}
class $TrainingAttemptsTable extends TrainingAttempts with TableInfo<$TrainingAttemptsTable, TrainingAttempt>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$TrainingAttemptsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
@override
late final GeneratedColumn<int> sessionId = GeneratedColumn<int>('session_id', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES training_sessions (id) ON DELETE CASCADE'));
static const VerificationMeta _riddleIdMeta = const VerificationMeta('riddleId');
@override
late final GeneratedColumn<int> riddleId = GeneratedColumn<int>('riddle_id', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES riddles (id) ON DELETE CASCADE'));
static const VerificationMeta _correctMeta = const VerificationMeta('correct');
@override
late final GeneratedColumn<bool> correct = GeneratedColumn<bool>('correct', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("correct" IN (0, 1))'));
static const VerificationMeta _answeredAtMeta = const VerificationMeta('answeredAt');
@override
late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>('answered_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
@override
List<GeneratedColumn> get $columns => [id, sessionId, riddleId, correct, answeredAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'training_attempts';
@override
VerificationContext validateIntegrity(Insertable<TrainingAttempt> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('session_id')) {
context.handle(_sessionIdMeta, sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));} else if (isInserting) {
context.missing(_sessionIdMeta);
}
if (data.containsKey('riddle_id')) {
context.handle(_riddleIdMeta, riddleId.isAcceptableOrUnknown(data['riddle_id']!, _riddleIdMeta));} else if (isInserting) {
context.missing(_riddleIdMeta);
}
if (data.containsKey('correct')) {
context.handle(_correctMeta, correct.isAcceptableOrUnknown(data['correct']!, _correctMeta));} else if (isInserting) {
context.missing(_correctMeta);
}
if (data.containsKey('answered_at')) {
context.handle(_answeredAtMeta, answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override TrainingAttempt map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return TrainingAttempt(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, sessionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}session_id'])!, riddleId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}riddle_id'])!, correct: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}correct'])!, answeredAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}answered_at'])!, );
}
@override
$TrainingAttemptsTable createAlias(String alias) {
return $TrainingAttemptsTable(attachedDatabase, alias);}}class TrainingAttempt extends DataClass implements Insertable<TrainingAttempt> 
{
final int id;
final int sessionId;
final int riddleId;
final bool correct;
final DateTime answeredAt;
const TrainingAttempt({required this.id, required this.sessionId, required this.riddleId, required this.correct, required this.answeredAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['session_id'] = Variable<int>(sessionId);
map['riddle_id'] = Variable<int>(riddleId);
map['correct'] = Variable<bool>(correct);
map['answered_at'] = Variable<DateTime>(answeredAt);
return map; 
}
TrainingAttemptsCompanion toCompanion(bool nullToAbsent) {
return TrainingAttemptsCompanion(id: Value(id),sessionId: Value(sessionId),riddleId: Value(riddleId),correct: Value(correct),answeredAt: Value(answeredAt),);
}
factory TrainingAttempt.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return TrainingAttempt(id: serializer.fromJson<int>(json['id']),sessionId: serializer.fromJson<int>(json['sessionId']),riddleId: serializer.fromJson<int>(json['riddleId']),correct: serializer.fromJson<bool>(json['correct']),answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'sessionId': serializer.toJson<int>(sessionId),'riddleId': serializer.toJson<int>(riddleId),'correct': serializer.toJson<bool>(correct),'answeredAt': serializer.toJson<DateTime>(answeredAt),};}TrainingAttempt copyWith({int? id,int? sessionId,int? riddleId,bool? correct,DateTime? answeredAt}) => TrainingAttempt(id: id ?? this.id,sessionId: sessionId ?? this.sessionId,riddleId: riddleId ?? this.riddleId,correct: correct ?? this.correct,answeredAt: answeredAt ?? this.answeredAt,);TrainingAttempt copyWithCompanion(TrainingAttemptsCompanion data) {
return TrainingAttempt(
id: data.id.present ? data.id.value : this.id,sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,riddleId: data.riddleId.present ? data.riddleId.value : this.riddleId,correct: data.correct.present ? data.correct.value : this.correct,answeredAt: data.answeredAt.present ? data.answeredAt.value : this.answeredAt,);
}
@override
String toString() {return (StringBuffer('TrainingAttempt(')..write('id: $id, ')..write('sessionId: $sessionId, ')..write('riddleId: $riddleId, ')..write('correct: $correct, ')..write('answeredAt: $answeredAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, sessionId, riddleId, correct, answeredAt);@override
bool operator ==(Object other) => identical(this, other) || (other is TrainingAttempt && other.id == this.id && other.sessionId == this.sessionId && other.riddleId == this.riddleId && other.correct == this.correct && other.answeredAt == this.answeredAt);
}class TrainingAttemptsCompanion extends UpdateCompanion<TrainingAttempt> {
final Value<int> id;
final Value<int> sessionId;
final Value<int> riddleId;
final Value<bool> correct;
final Value<DateTime> answeredAt;
const TrainingAttemptsCompanion({this.id = const Value.absent(),this.sessionId = const Value.absent(),this.riddleId = const Value.absent(),this.correct = const Value.absent(),this.answeredAt = const Value.absent(),});
TrainingAttemptsCompanion.insert({this.id = const Value.absent(),required int sessionId,required int riddleId,required bool correct,this.answeredAt = const Value.absent(),}): sessionId = Value(sessionId), riddleId = Value(riddleId), correct = Value(correct);
static Insertable<TrainingAttempt> custom({Expression<int>? id, 
Expression<int>? sessionId, 
Expression<int>? riddleId, 
Expression<bool>? correct, 
Expression<DateTime>? answeredAt, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (sessionId != null)'session_id': sessionId,if (riddleId != null)'riddle_id': riddleId,if (correct != null)'correct': correct,if (answeredAt != null)'answered_at': answeredAt,});
}TrainingAttemptsCompanion copyWith({Value<int>? id, Value<int>? sessionId, Value<int>? riddleId, Value<bool>? correct, Value<DateTime>? answeredAt}) {
return TrainingAttemptsCompanion(id: id ?? this.id,sessionId: sessionId ?? this.sessionId,riddleId: riddleId ?? this.riddleId,correct: correct ?? this.correct,answeredAt: answeredAt ?? this.answeredAt,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (sessionId.present) {
map['session_id'] = Variable<int>(sessionId.value);}
if (riddleId.present) {
map['riddle_id'] = Variable<int>(riddleId.value);}
if (correct.present) {
map['correct'] = Variable<bool>(correct.value);}
if (answeredAt.present) {
map['answered_at'] = Variable<DateTime>(answeredAt.value);}
return map; 
}
@override
String toString() {return (StringBuffer('TrainingAttemptsCompanion(')..write('id: $id, ')..write('sessionId: $sessionId, ')..write('riddleId: $riddleId, ')..write('correct: $correct, ')..write('answeredAt: $answeredAt')..write(')')).toString();}
}
class $DownloadedPacksTable extends DownloadedPacks with TableInfo<$DownloadedPacksTable, DownloadedPack>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$DownloadedPacksTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _titleMeta = const VerificationMeta('title');
@override
late final GeneratedColumn<String> title = GeneratedColumn<String>('title', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _shareCodeMeta = const VerificationMeta('shareCode');
@override
late final GeneratedColumn<String> shareCode = GeneratedColumn<String>('share_code', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _creatorIdMeta = const VerificationMeta('creatorId');
@override
late final GeneratedColumn<String> creatorId = GeneratedColumn<String>('creator_id', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _downloadedAtMeta = const VerificationMeta('downloadedAt');
@override
late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>('downloaded_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
@override
List<GeneratedColumn> get $columns => [id, title, shareCode, creatorId, downloadedAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'downloaded_packs';
@override
VerificationContext validateIntegrity(Insertable<DownloadedPack> instance, {bool isInserting = false}) {
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
if (data.containsKey('share_code')) {
context.handle(_shareCodeMeta, shareCode.isAcceptableOrUnknown(data['share_code']!, _shareCodeMeta));} else if (isInserting) {
context.missing(_shareCodeMeta);
}
if (data.containsKey('creator_id')) {
context.handle(_creatorIdMeta, creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta));}if (data.containsKey('downloaded_at')) {
context.handle(_downloadedAtMeta, downloadedAt.isAcceptableOrUnknown(data['downloaded_at']!, _downloadedAtMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override DownloadedPack map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return DownloadedPack(id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!, title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!, shareCode: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}share_code'])!, creatorId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}creator_id']), downloadedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!, );
}
@override
$DownloadedPacksTable createAlias(String alias) {
return $DownloadedPacksTable(attachedDatabase, alias);}}class DownloadedPack extends DataClass implements Insertable<DownloadedPack> 
{
final String id;
final String title;
final String shareCode;
/// The Supabase creator_id — null if this device created the pack
/// (in that case the device IS the creator, so no need to store it here).
/// Populated for packs downloaded from someone else.
final String? creatorId;
final DateTime downloadedAt;
const DownloadedPack({required this.id, required this.title, required this.shareCode, this.creatorId, required this.downloadedAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<String>(id);
map['title'] = Variable<String>(title);
map['share_code'] = Variable<String>(shareCode);
if (!nullToAbsent || creatorId != null){map['creator_id'] = Variable<String>(creatorId);
}map['downloaded_at'] = Variable<DateTime>(downloadedAt);
return map; 
}
DownloadedPacksCompanion toCompanion(bool nullToAbsent) {
return DownloadedPacksCompanion(id: Value(id),title: Value(title),shareCode: Value(shareCode),creatorId: creatorId == null && nullToAbsent ? const Value.absent() : Value(creatorId),downloadedAt: Value(downloadedAt),);
}
factory DownloadedPack.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return DownloadedPack(id: serializer.fromJson<String>(json['id']),title: serializer.fromJson<String>(json['title']),shareCode: serializer.fromJson<String>(json['shareCode']),creatorId: serializer.fromJson<String?>(json['creatorId']),downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<String>(id),'title': serializer.toJson<String>(title),'shareCode': serializer.toJson<String>(shareCode),'creatorId': serializer.toJson<String?>(creatorId),'downloadedAt': serializer.toJson<DateTime>(downloadedAt),};}DownloadedPack copyWith({String? id,String? title,String? shareCode,Value<String?> creatorId = const Value.absent(),DateTime? downloadedAt}) => DownloadedPack(id: id ?? this.id,title: title ?? this.title,shareCode: shareCode ?? this.shareCode,creatorId: creatorId.present ? creatorId.value : this.creatorId,downloadedAt: downloadedAt ?? this.downloadedAt,);DownloadedPack copyWithCompanion(DownloadedPacksCompanion data) {
return DownloadedPack(
id: data.id.present ? data.id.value : this.id,title: data.title.present ? data.title.value : this.title,shareCode: data.shareCode.present ? data.shareCode.value : this.shareCode,creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,downloadedAt: data.downloadedAt.present ? data.downloadedAt.value : this.downloadedAt,);
}
@override
String toString() {return (StringBuffer('DownloadedPack(')..write('id: $id, ')..write('title: $title, ')..write('shareCode: $shareCode, ')..write('creatorId: $creatorId, ')..write('downloadedAt: $downloadedAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, title, shareCode, creatorId, downloadedAt);@override
bool operator ==(Object other) => identical(this, other) || (other is DownloadedPack && other.id == this.id && other.title == this.title && other.shareCode == this.shareCode && other.creatorId == this.creatorId && other.downloadedAt == this.downloadedAt);
}class DownloadedPacksCompanion extends UpdateCompanion<DownloadedPack> {
final Value<String> id;
final Value<String> title;
final Value<String> shareCode;
final Value<String?> creatorId;
final Value<DateTime> downloadedAt;
final Value<int> rowid;
const DownloadedPacksCompanion({this.id = const Value.absent(),this.title = const Value.absent(),this.shareCode = const Value.absent(),this.creatorId = const Value.absent(),this.downloadedAt = const Value.absent(),this.rowid = const Value.absent(),});
DownloadedPacksCompanion.insert({required String id,required String title,required String shareCode,this.creatorId = const Value.absent(),this.downloadedAt = const Value.absent(),this.rowid = const Value.absent(),}): id = Value(id), title = Value(title), shareCode = Value(shareCode);
static Insertable<DownloadedPack> custom({Expression<String>? id, 
Expression<String>? title, 
Expression<String>? shareCode, 
Expression<String>? creatorId, 
Expression<DateTime>? downloadedAt, 
Expression<int>? rowid, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (title != null)'title': title,if (shareCode != null)'share_code': shareCode,if (creatorId != null)'creator_id': creatorId,if (downloadedAt != null)'downloaded_at': downloadedAt,if (rowid != null)'rowid': rowid,});
}DownloadedPacksCompanion copyWith({Value<String>? id, Value<String>? title, Value<String>? shareCode, Value<String?>? creatorId, Value<DateTime>? downloadedAt, Value<int>? rowid}) {
return DownloadedPacksCompanion(id: id ?? this.id,title: title ?? this.title,shareCode: shareCode ?? this.shareCode,creatorId: creatorId ?? this.creatorId,downloadedAt: downloadedAt ?? this.downloadedAt,rowid: rowid ?? this.rowid,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<String>(id.value);}
if (title.present) {
map['title'] = Variable<String>(title.value);}
if (shareCode.present) {
map['share_code'] = Variable<String>(shareCode.value);}
if (creatorId.present) {
map['creator_id'] = Variable<String>(creatorId.value);}
if (downloadedAt.present) {
map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);}
if (rowid.present) {
map['rowid'] = Variable<int>(rowid.value);}
return map; 
}
@override
String toString() {return (StringBuffer('DownloadedPacksCompanion(')..write('id: $id, ')..write('title: $title, ')..write('shareCode: $shareCode, ')..write('creatorId: $creatorId, ')..write('downloadedAt: $downloadedAt, ')..write('rowid: $rowid')..write(')')).toString();}
}
class $DownloadedPackMapsTable extends DownloadedPackMaps with TableInfo<$DownloadedPackMapsTable, DownloadedPackMap>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$DownloadedPackMapsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
@override
late final GeneratedColumn<String> packId = GeneratedColumn<String>('pack_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true, defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES downloaded_packs (id) ON DELETE CASCADE'));
static const VerificationMeta _localMapIdMeta = const VerificationMeta('localMapId');
@override
late final GeneratedColumn<String> localMapId = GeneratedColumn<String>('local_map_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta('remoteUpdatedAt');
@override
late final GeneratedColumn<DateTime> remoteUpdatedAt = GeneratedColumn<DateTime>('remote_updated_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
@override
List<GeneratedColumn> get $columns => [id, packId, localMapId, remoteUpdatedAt];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'downloaded_pack_maps';
@override
VerificationContext validateIntegrity(Insertable<DownloadedPackMap> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));} else if (isInserting) {
context.missing(_idMeta);
}
if (data.containsKey('pack_id')) {
context.handle(_packIdMeta, packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta));} else if (isInserting) {
context.missing(_packIdMeta);
}
if (data.containsKey('local_map_id')) {
context.handle(_localMapIdMeta, localMapId.isAcceptableOrUnknown(data['local_map_id']!, _localMapIdMeta));} else if (isInserting) {
context.missing(_localMapIdMeta);
}
if (data.containsKey('remote_updated_at')) {
context.handle(_remoteUpdatedAtMeta, remoteUpdatedAt.isAcceptableOrUnknown(data['remote_updated_at']!, _remoteUpdatedAtMeta));} else if (isInserting) {
context.missing(_remoteUpdatedAtMeta);
}
return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override DownloadedPackMap map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return DownloadedPackMap(id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!, packId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pack_id'])!, localMapId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}local_map_id'])!, remoteUpdatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}remote_updated_at'])!, );
}
@override
$DownloadedPackMapsTable createAlias(String alias) {
return $DownloadedPackMapsTable(attachedDatabase, alias);}}class DownloadedPackMap extends DataClass implements Insertable<DownloadedPackMap> 
{
final String id;
final String packId;
final String localMapId;
final DateTime remoteUpdatedAt;
const DownloadedPackMap({required this.id, required this.packId, required this.localMapId, required this.remoteUpdatedAt});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<String>(id);
map['pack_id'] = Variable<String>(packId);
map['local_map_id'] = Variable<String>(localMapId);
map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
return map; 
}
DownloadedPackMapsCompanion toCompanion(bool nullToAbsent) {
return DownloadedPackMapsCompanion(id: Value(id),packId: Value(packId),localMapId: Value(localMapId),remoteUpdatedAt: Value(remoteUpdatedAt),);
}
factory DownloadedPackMap.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return DownloadedPackMap(id: serializer.fromJson<String>(json['id']),packId: serializer.fromJson<String>(json['packId']),localMapId: serializer.fromJson<String>(json['localMapId']),remoteUpdatedAt: serializer.fromJson<DateTime>(json['remoteUpdatedAt']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<String>(id),'packId': serializer.toJson<String>(packId),'localMapId': serializer.toJson<String>(localMapId),'remoteUpdatedAt': serializer.toJson<DateTime>(remoteUpdatedAt),};}DownloadedPackMap copyWith({String? id,String? packId,String? localMapId,DateTime? remoteUpdatedAt}) => DownloadedPackMap(id: id ?? this.id,packId: packId ?? this.packId,localMapId: localMapId ?? this.localMapId,remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,);DownloadedPackMap copyWithCompanion(DownloadedPackMapsCompanion data) {
return DownloadedPackMap(
id: data.id.present ? data.id.value : this.id,packId: data.packId.present ? data.packId.value : this.packId,localMapId: data.localMapId.present ? data.localMapId.value : this.localMapId,remoteUpdatedAt: data.remoteUpdatedAt.present ? data.remoteUpdatedAt.value : this.remoteUpdatedAt,);
}
@override
String toString() {return (StringBuffer('DownloadedPackMap(')..write('id: $id, ')..write('packId: $packId, ')..write('localMapId: $localMapId, ')..write('remoteUpdatedAt: $remoteUpdatedAt')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, packId, localMapId, remoteUpdatedAt);@override
bool operator ==(Object other) => identical(this, other) || (other is DownloadedPackMap && other.id == this.id && other.packId == this.packId && other.localMapId == this.localMapId && other.remoteUpdatedAt == this.remoteUpdatedAt);
}class DownloadedPackMapsCompanion extends UpdateCompanion<DownloadedPackMap> {
final Value<String> id;
final Value<String> packId;
final Value<String> localMapId;
final Value<DateTime> remoteUpdatedAt;
final Value<int> rowid;
const DownloadedPackMapsCompanion({this.id = const Value.absent(),this.packId = const Value.absent(),this.localMapId = const Value.absent(),this.remoteUpdatedAt = const Value.absent(),this.rowid = const Value.absent(),});
DownloadedPackMapsCompanion.insert({required String id,required String packId,required String localMapId,required DateTime remoteUpdatedAt,this.rowid = const Value.absent(),}): id = Value(id), packId = Value(packId), localMapId = Value(localMapId), remoteUpdatedAt = Value(remoteUpdatedAt);
static Insertable<DownloadedPackMap> custom({Expression<String>? id, 
Expression<String>? packId, 
Expression<String>? localMapId, 
Expression<DateTime>? remoteUpdatedAt, 
Expression<int>? rowid, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (packId != null)'pack_id': packId,if (localMapId != null)'local_map_id': localMapId,if (remoteUpdatedAt != null)'remote_updated_at': remoteUpdatedAt,if (rowid != null)'rowid': rowid,});
}DownloadedPackMapsCompanion copyWith({Value<String>? id, Value<String>? packId, Value<String>? localMapId, Value<DateTime>? remoteUpdatedAt, Value<int>? rowid}) {
return DownloadedPackMapsCompanion(id: id ?? this.id,packId: packId ?? this.packId,localMapId: localMapId ?? this.localMapId,remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,rowid: rowid ?? this.rowid,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<String>(id.value);}
if (packId.present) {
map['pack_id'] = Variable<String>(packId.value);}
if (localMapId.present) {
map['local_map_id'] = Variable<String>(localMapId.value);}
if (remoteUpdatedAt.present) {
map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);}
if (rowid.present) {
map['rowid'] = Variable<int>(rowid.value);}
return map; 
}
@override
String toString() {return (StringBuffer('DownloadedPackMapsCompanion(')..write('id: $id, ')..write('packId: $packId, ')..write('localMapId: $localMapId, ')..write('remoteUpdatedAt: $remoteUpdatedAt, ')..write('rowid: $rowid')..write(')')).toString();}
}
abstract class _$AppDatabase extends GeneratedDatabase{
_$AppDatabase(QueryExecutor e): super(e);
$AppDatabaseManager get managers => $AppDatabaseManager(this);
late final $FoldersTable folders = $FoldersTable(this);
late final $RiddleMapsTable riddleMaps = $RiddleMapsTable(this);
late final $RiddlesTable riddles = $RiddlesTable(this);
late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
late final $TrainingSessionsTable trainingSessions = $TrainingSessionsTable(this);
late final $TrainingNotifiedRiddlesTable trainingNotifiedRiddles = $TrainingNotifiedRiddlesTable(this);
late final $TrainingAttemptsTable trainingAttempts = $TrainingAttemptsTable(this);
late final $DownloadedPacksTable downloadedPacks = $DownloadedPacksTable(this);
late final $DownloadedPackMapsTable downloadedPackMaps = $DownloadedPackMapsTable(this);
@override
Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
@override
List<DatabaseSchemaEntity> get allSchemaEntities => [folders, riddleMaps, riddles, playSessions, trainingSessions, trainingNotifiedRiddles, trainingAttempts, downloadedPacks, downloadedPackMaps];
@override
StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([WritePropagation(on: TableUpdateQuery.onTableName('folders' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('riddle_maps', kind: UpdateKind.update), ],), WritePropagation(on: TableUpdateQuery.onTableName('riddle_maps' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('riddles', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('riddle_maps' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('play_sessions', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('riddle_maps' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('training_sessions', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('training_sessions' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('training_notified_riddles', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('riddles' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('training_notified_riddles', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('training_sessions' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('training_attempts', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('riddles' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('training_attempts', kind: UpdateKind.delete), ],), WritePropagation(on: TableUpdateQuery.onTableName('downloaded_packs' , limitUpdateKind: UpdateKind.delete), result: [TableUpdate('downloaded_pack_maps', kind: UpdateKind.delete), ],), ],);
}
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({Value<int> id,required String title,Value<DateTime> createdAt,});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({Value<int> id,Value<String> title,Value<DateTime> createdAt,});
      final class $$FoldersTableReferences extends BaseReferences<
        _$AppDatabase,
        $FoldersTable,
        Folder> {
        $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                  
                  static MultiTypedResultKey<
          $RiddleMapsTable,
          List<RiddleMap>
        > _riddleMapsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.riddleMaps, 
          aliasName: $_aliasNameGenerator(
            db.folders.id,
            db.riddleMaps.folderId)
        );

          $$RiddleMapsTableProcessedTableManager get riddleMapsRefs {
        final manager = $$RiddleMapsTableTableManager(
            $_db, $_db.riddleMaps
            ).filter(
              (f) => f.folderId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_riddleMapsRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        

      }class $$FoldersTableFilterComposer extends Composer<
        _$AppDatabase,
        $FoldersTable> {
        $$FoldersTableFilterComposer({
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
      
ColumnFilters<String> get title => $composableBuilder(
      column: $table.title,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => 
      ColumnFilters(column));
      
        Expression<bool> riddleMapsRefs(
          Expression<bool> Function( $$RiddleMapsTableFilterComposer f) f
        ) {
                final $$RiddleMapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.folderId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableFilterComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$FoldersTableOrderingComposer extends Composer<
        _$AppDatabase,
        $FoldersTable> {
        $$FoldersTableOrderingComposer({
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
      
ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$FoldersTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $FoldersTable> {
        $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get title => $composableBuilder(
      column: $table.title,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => column);
      
        Expression<T> riddleMapsRefs<T extends Object>(
          Expression<T> Function( $$RiddleMapsTableAnnotationComposer a) f
        ) {
                final $$RiddleMapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.riddleMaps,
      getReferencedColumn: (t) => t.folderId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddleMapsTableAnnotationComposer(
              $db: $db,
              $table: $db.riddleMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$FoldersTableTableManager extends RootTableManager    <_$AppDatabase,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (Folder,$$FoldersTableReferences),
    Folder,
    PrefetchHooks Function({bool riddleMapsRefs})
    > {
    $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$FoldersTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$FoldersTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$FoldersTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> title = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),})=> FoldersCompanion(id: id,title: title,createdAt: createdAt,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required String title,Value<DateTime> createdAt = const Value.absent(),})=> FoldersCompanion.insert(id: id,title: title,createdAt: createdAt,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$FoldersTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({riddleMapsRefs = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             if (riddleMapsRefs) db.riddleMaps
            ],
            addJoins: null,
            getPrefetchedDataCallback: (items) async {
            return [
                      if (riddleMapsRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$FoldersTableReferences._riddleMapsRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$FoldersTableReferences(db, table, p0).riddleMapsRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.folderId == item.id),
                  typedResults: items)
            
                ];
              },
          );
        }
,
        ));
        }
    typedef $$FoldersTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (Folder,$$FoldersTableReferences),
    Folder,
    PrefetchHooks Function({bool riddleMapsRefs})
    >;typedef $$RiddleMapsTableCreateCompanionBuilder = RiddleMapsCompanion Function({required String id,required String title,Value<String?> description,Value<String?> subject,Value<Uint8List?> imageBytes,Value<DateTime> createdAt,Value<int> riddlesVersion,Value<int?> folderId,Value<int> sortOrder,Value<int> rowid,});
typedef $$RiddleMapsTableUpdateCompanionBuilder = RiddleMapsCompanion Function({Value<String> id,Value<String> title,Value<String?> description,Value<String?> subject,Value<Uint8List?> imageBytes,Value<DateTime> createdAt,Value<int> riddlesVersion,Value<int?> folderId,Value<int> sortOrder,Value<int> rowid,});
      final class $$RiddleMapsTableReferences extends BaseReferences<
        _$AppDatabase,
        $RiddleMapsTable,
        RiddleMap> {
        $$RiddleMapsTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $FoldersTable _folderIdTable(_$AppDatabase db) => 
            db.folders.createAlias($_aliasNameGenerator(
            db.riddleMaps.folderId,
            db.folders.id));
          

        $$FoldersTableProcessedTableManager? get folderId {
          if ($_item.folderId == null) return null;
          final manager = $$FoldersTableTableManager($_db, $_db.folders).filter((f) => f.id($_item.folderId!));
          final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }

          
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
        
          
                  static MultiTypedResultKey<
          $TrainingSessionsTable,
          List<TrainingSession>
        > _trainingSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.trainingSessions, 
          aliasName: $_aliasNameGenerator(
            db.riddleMaps.id,
            db.trainingSessions.mapId)
        );

          $$TrainingSessionsTableProcessedTableManager get trainingSessionsRefs {
        final manager = $$TrainingSessionsTableTableManager(
            $_db, $_db.trainingSessions
            ).filter(
              (f) => f.mapId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_trainingSessionsRefsTable($_db));
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
      
ColumnFilters<int> get riddlesVersion => $composableBuilder(
      column: $table.riddlesVersion,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder,
      builder: (column) => 
      ColumnFilters(column));
      
        $$FoldersTableFilterComposer get folderId {
                final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$FoldersTableFilterComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
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

        Expression<bool> trainingSessionsRefs(
          Expression<bool> Function( $$TrainingSessionsTableFilterComposer f) f
        ) {
                final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.mapId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableFilterComposer(
              $db: $db,
              $table: $db.trainingSessions,
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
      
ColumnOrderings<int> get riddlesVersion => $composableBuilder(
      column: $table.riddlesVersion,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder,
      builder: (column) => 
      ColumnOrderings(column));
      
        $$FoldersTableOrderingComposer get folderId {
                final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$FoldersTableOrderingComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
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
      
GeneratedColumn<int> get riddlesVersion => $composableBuilder(
      column: $table.riddlesVersion,
      builder: (column) => column);
      
GeneratedColumn<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder,
      builder: (column) => column);
      
        $$FoldersTableAnnotationComposer get folderId {
                final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$FoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
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

        Expression<T> trainingSessionsRefs<T extends Object>(
          Expression<T> Function( $$TrainingSessionsTableAnnotationComposer a) f
        ) {
                final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.mapId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingSessions,
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
    PrefetchHooks Function({bool folderId,bool riddlesRefs,bool playSessionsRefs,bool trainingSessionsRefs})
    > {
    $$RiddleMapsTableTableManager(_$AppDatabase db, $RiddleMapsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$RiddleMapsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$RiddleMapsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$RiddleMapsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<String> id = const Value.absent(),Value<String> title = const Value.absent(),Value<String?> description = const Value.absent(),Value<String?> subject = const Value.absent(),Value<Uint8List?> imageBytes = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> riddlesVersion = const Value.absent(),Value<int?> folderId = const Value.absent(),Value<int> sortOrder = const Value.absent(),Value<int> rowid = const Value.absent(),})=> RiddleMapsCompanion(id: id,title: title,description: description,subject: subject,imageBytes: imageBytes,createdAt: createdAt,riddlesVersion: riddlesVersion,folderId: folderId,sortOrder: sortOrder,rowid: rowid,),
        createCompanionCallback: ({required String id,required String title,Value<String?> description = const Value.absent(),Value<String?> subject = const Value.absent(),Value<Uint8List?> imageBytes = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> riddlesVersion = const Value.absent(),Value<int?> folderId = const Value.absent(),Value<int> sortOrder = const Value.absent(),Value<int> rowid = const Value.absent(),})=> RiddleMapsCompanion.insert(id: id,title: title,description: description,subject: subject,imageBytes: imageBytes,createdAt: createdAt,riddlesVersion: riddlesVersion,folderId: folderId,sortOrder: sortOrder,rowid: rowid,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$RiddleMapsTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({folderId = false,riddlesRefs = false,playSessionsRefs = false,trainingSessionsRefs = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             if (riddlesRefs) db.riddles,if (playSessionsRefs) db.playSessions,if (trainingSessionsRefs) db.trainingSessions
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (folderId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.folderId,
                    referencedTable:
                        $$RiddleMapsTableReferences._folderIdTable(db),
                    referencedColumn:
                        $$RiddleMapsTableReferences._folderIdTable(db).id,
                  ) as T;
               }

                return state;
              }
,
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
            ,          if (trainingSessionsRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$RiddleMapsTableReferences._trainingSessionsRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$RiddleMapsTableReferences(db, table, p0).trainingSessionsRefs,
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
    PrefetchHooks Function({bool folderId,bool riddlesRefs,bool playSessionsRefs,bool trainingSessionsRefs})
    >;typedef $$RiddlesTableCreateCompanionBuilder = RiddlesCompanion Function({Value<int> id,required String mapId,required String question,required int typeIndex,required int orderInMap,Value<String?> payloadJson,Value<String?> choicesJson,Value<int?> correctIndex,Value<String?> sourceExcerpt,});
typedef $$RiddlesTableUpdateCompanionBuilder = RiddlesCompanion Function({Value<int> id,Value<String> mapId,Value<String> question,Value<int> typeIndex,Value<int> orderInMap,Value<String?> payloadJson,Value<String?> choicesJson,Value<int?> correctIndex,Value<String?> sourceExcerpt,});
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

          
                  static MultiTypedResultKey<
          $TrainingNotifiedRiddlesTable,
          List<TrainingNotifiedRiddle>
        > _trainingNotifiedRiddlesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.trainingNotifiedRiddles, 
          aliasName: $_aliasNameGenerator(
            db.riddles.id,
            db.trainingNotifiedRiddles.riddleId)
        );

          $$TrainingNotifiedRiddlesTableProcessedTableManager get trainingNotifiedRiddlesRefs {
        final manager = $$TrainingNotifiedRiddlesTableTableManager(
            $_db, $_db.trainingNotifiedRiddles
            ).filter(
              (f) => f.riddleId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_trainingNotifiedRiddlesRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        
          
                  static MultiTypedResultKey<
          $TrainingAttemptsTable,
          List<TrainingAttempt>
        > _trainingAttemptsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.trainingAttempts, 
          aliasName: $_aliasNameGenerator(
            db.riddles.id,
            db.trainingAttempts.riddleId)
        );

          $$TrainingAttemptsTableProcessedTableManager get trainingAttemptsRefs {
        final manager = $$TrainingAttemptsTableTableManager(
            $_db, $_db.trainingAttempts
            ).filter(
              (f) => f.riddleId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_trainingAttemptsRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


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
      
ColumnFilters<String> get sourceExcerpt => $composableBuilder(
      column: $table.sourceExcerpt,
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
        Expression<bool> trainingNotifiedRiddlesRefs(
          Expression<bool> Function( $$TrainingNotifiedRiddlesTableFilterComposer f) f
        ) {
                final $$TrainingNotifiedRiddlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingNotifiedRiddles,
      getReferencedColumn: (t) => t.riddleId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingNotifiedRiddlesTableFilterComposer(
              $db: $db,
              $table: $db.trainingNotifiedRiddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        Expression<bool> trainingAttemptsRefs(
          Expression<bool> Function( $$TrainingAttemptsTableFilterComposer f) f
        ) {
                final $$TrainingAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingAttempts,
      getReferencedColumn: (t) => t.riddleId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingAttemptsTableFilterComposer(
              $db: $db,
              $table: $db.trainingAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
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
      
ColumnOrderings<String> get sourceExcerpt => $composableBuilder(
      column: $table.sourceExcerpt,
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
      
GeneratedColumn<String> get sourceExcerpt => $composableBuilder(
      column: $table.sourceExcerpt,
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
        Expression<T> trainingNotifiedRiddlesRefs<T extends Object>(
          Expression<T> Function( $$TrainingNotifiedRiddlesTableAnnotationComposer a) f
        ) {
                final $$TrainingNotifiedRiddlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingNotifiedRiddles,
      getReferencedColumn: (t) => t.riddleId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingNotifiedRiddlesTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingNotifiedRiddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        Expression<T> trainingAttemptsRefs<T extends Object>(
          Expression<T> Function( $$TrainingAttemptsTableAnnotationComposer a) f
        ) {
                final $$TrainingAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingAttempts,
      getReferencedColumn: (t) => t.riddleId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingAttemptsTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
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
    PrefetchHooks Function({bool mapId,bool trainingNotifiedRiddlesRefs,bool trainingAttemptsRefs})
    > {
    $$RiddlesTableTableManager(_$AppDatabase db, $RiddlesTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$RiddlesTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$RiddlesTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$RiddlesTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> mapId = const Value.absent(),Value<String> question = const Value.absent(),Value<int> typeIndex = const Value.absent(),Value<int> orderInMap = const Value.absent(),Value<String?> payloadJson = const Value.absent(),Value<String?> choicesJson = const Value.absent(),Value<int?> correctIndex = const Value.absent(),Value<String?> sourceExcerpt = const Value.absent(),})=> RiddlesCompanion(id: id,mapId: mapId,question: question,typeIndex: typeIndex,orderInMap: orderInMap,payloadJson: payloadJson,choicesJson: choicesJson,correctIndex: correctIndex,sourceExcerpt: sourceExcerpt,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required String mapId,required String question,required int typeIndex,required int orderInMap,Value<String?> payloadJson = const Value.absent(),Value<String?> choicesJson = const Value.absent(),Value<int?> correctIndex = const Value.absent(),Value<String?> sourceExcerpt = const Value.absent(),})=> RiddlesCompanion.insert(id: id,mapId: mapId,question: question,typeIndex: typeIndex,orderInMap: orderInMap,payloadJson: payloadJson,choicesJson: choicesJson,correctIndex: correctIndex,sourceExcerpt: sourceExcerpt,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$RiddlesTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({mapId = false,trainingNotifiedRiddlesRefs = false,trainingAttemptsRefs = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             if (trainingNotifiedRiddlesRefs) db.trainingNotifiedRiddles,if (trainingAttemptsRefs) db.trainingAttempts
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
                      if (trainingNotifiedRiddlesRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$RiddlesTableReferences._trainingNotifiedRiddlesRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$RiddlesTableReferences(db, table, p0).trainingNotifiedRiddlesRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.riddleId == item.id),
                  typedResults: items)
            ,          if (trainingAttemptsRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$RiddlesTableReferences._trainingAttemptsRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$RiddlesTableReferences(db, table, p0).trainingAttemptsRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.riddleId == item.id),
                  typedResults: items)
            
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
    PrefetchHooks Function({bool mapId,bool trainingNotifiedRiddlesRefs,bool trainingAttemptsRefs})
    >;typedef $$PlaySessionsTableCreateCompanionBuilder = PlaySessionsCompanion Function({Value<int> id,Value<String> publicId,required String mapId,Value<int> lastCompletedIndex,Value<DateTime> startedAt,Value<DateTime?> completedAt,Value<int> totalRiddles,Value<int> correctAnswers,Value<String?> riddleStarsJson,Value<int> riddlesVersion,});
typedef $$PlaySessionsTableUpdateCompanionBuilder = PlaySessionsCompanion Function({Value<int> id,Value<String> publicId,Value<String> mapId,Value<int> lastCompletedIndex,Value<DateTime> startedAt,Value<DateTime?> completedAt,Value<int> totalRiddles,Value<int> correctAnswers,Value<String?> riddleStarsJson,Value<int> riddlesVersion,});
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
      
ColumnFilters<int> get riddlesVersion => $composableBuilder(
      column: $table.riddlesVersion,
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
      
ColumnOrderings<int> get riddlesVersion => $composableBuilder(
      column: $table.riddlesVersion,
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
      
GeneratedColumn<int> get riddlesVersion => $composableBuilder(
      column: $table.riddlesVersion,
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
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> publicId = const Value.absent(),Value<String> mapId = const Value.absent(),Value<int> lastCompletedIndex = const Value.absent(),Value<DateTime> startedAt = const Value.absent(),Value<DateTime?> completedAt = const Value.absent(),Value<int> totalRiddles = const Value.absent(),Value<int> correctAnswers = const Value.absent(),Value<String?> riddleStarsJson = const Value.absent(),Value<int> riddlesVersion = const Value.absent(),})=> PlaySessionsCompanion(id: id,publicId: publicId,mapId: mapId,lastCompletedIndex: lastCompletedIndex,startedAt: startedAt,completedAt: completedAt,totalRiddles: totalRiddles,correctAnswers: correctAnswers,riddleStarsJson: riddleStarsJson,riddlesVersion: riddlesVersion,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> publicId = const Value.absent(),required String mapId,Value<int> lastCompletedIndex = const Value.absent(),Value<DateTime> startedAt = const Value.absent(),Value<DateTime?> completedAt = const Value.absent(),Value<int> totalRiddles = const Value.absent(),Value<int> correctAnswers = const Value.absent(),Value<String?> riddleStarsJson = const Value.absent(),Value<int> riddlesVersion = const Value.absent(),})=> PlaySessionsCompanion.insert(id: id,publicId: publicId,mapId: mapId,lastCompletedIndex: lastCompletedIndex,startedAt: startedAt,completedAt: completedAt,totalRiddles: totalRiddles,correctAnswers: correctAnswers,riddleStarsJson: riddleStarsJson,riddlesVersion: riddlesVersion,),
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
    >;typedef $$TrainingSessionsTableCreateCompanionBuilder = TrainingSessionsCompanion Function({Value<int> id,required String mapId,Value<DateTime> startedAt,required DateTime endsAt,Value<String> poolJson,Value<String> scheduledJson,Value<DateTime?> completedAt,});
typedef $$TrainingSessionsTableUpdateCompanionBuilder = TrainingSessionsCompanion Function({Value<int> id,Value<String> mapId,Value<DateTime> startedAt,Value<DateTime> endsAt,Value<String> poolJson,Value<String> scheduledJson,Value<DateTime?> completedAt,});
      final class $$TrainingSessionsTableReferences extends BaseReferences<
        _$AppDatabase,
        $TrainingSessionsTable,
        TrainingSession> {
        $$TrainingSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $RiddleMapsTable _mapIdTable(_$AppDatabase db) => 
            db.riddleMaps.createAlias($_aliasNameGenerator(
            db.trainingSessions.mapId,
            db.riddleMaps.id));
          

        $$RiddleMapsTableProcessedTableManager? get mapId {
          if ($_item.mapId == null) return null;
          final manager = $$RiddleMapsTableTableManager($_db, $_db.riddleMaps).filter((f) => f.id($_item.mapId!));
          final item = $_typedResult.readTableOrNull(_mapIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }

          
                  static MultiTypedResultKey<
          $TrainingNotifiedRiddlesTable,
          List<TrainingNotifiedRiddle>
        > _trainingNotifiedRiddlesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.trainingNotifiedRiddles, 
          aliasName: $_aliasNameGenerator(
            db.trainingSessions.id,
            db.trainingNotifiedRiddles.sessionId)
        );

          $$TrainingNotifiedRiddlesTableProcessedTableManager get trainingNotifiedRiddlesRefs {
        final manager = $$TrainingNotifiedRiddlesTableTableManager(
            $_db, $_db.trainingNotifiedRiddles
            ).filter(
              (f) => f.sessionId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_trainingNotifiedRiddlesRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        
          
                  static MultiTypedResultKey<
          $TrainingAttemptsTable,
          List<TrainingAttempt>
        > _trainingAttemptsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.trainingAttempts, 
          aliasName: $_aliasNameGenerator(
            db.trainingSessions.id,
            db.trainingAttempts.sessionId)
        );

          $$TrainingAttemptsTableProcessedTableManager get trainingAttemptsRefs {
        final manager = $$TrainingAttemptsTableTableManager(
            $_db, $_db.trainingAttempts
            ).filter(
              (f) => f.sessionId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_trainingAttemptsRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        

      }class $$TrainingSessionsTableFilterComposer extends Composer<
        _$AppDatabase,
        $TrainingSessionsTable> {
        $$TrainingSessionsTableFilterComposer({
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
      
ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get poolJson => $composableBuilder(
      column: $table.poolJson,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get scheduledJson => $composableBuilder(
      column: $table.scheduledJson,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt,
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
        Expression<bool> trainingNotifiedRiddlesRefs(
          Expression<bool> Function( $$TrainingNotifiedRiddlesTableFilterComposer f) f
        ) {
                final $$TrainingNotifiedRiddlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingNotifiedRiddles,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingNotifiedRiddlesTableFilterComposer(
              $db: $db,
              $table: $db.trainingNotifiedRiddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        Expression<bool> trainingAttemptsRefs(
          Expression<bool> Function( $$TrainingAttemptsTableFilterComposer f) f
        ) {
                final $$TrainingAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingAttempts,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingAttemptsTableFilterComposer(
              $db: $db,
              $table: $db.trainingAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$TrainingSessionsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $TrainingSessionsTable> {
        $$TrainingSessionsTableOrderingComposer({
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
      
ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get poolJson => $composableBuilder(
      column: $table.poolJson,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get scheduledJson => $composableBuilder(
      column: $table.scheduledJson,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt,
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
      class $$TrainingSessionsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $TrainingSessionsTable> {
        $$TrainingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt,
      builder: (column) => column);
      
GeneratedColumn<String> get poolJson => $composableBuilder(
      column: $table.poolJson,
      builder: (column) => column);
      
GeneratedColumn<String> get scheduledJson => $composableBuilder(
      column: $table.scheduledJson,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt,
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
        Expression<T> trainingNotifiedRiddlesRefs<T extends Object>(
          Expression<T> Function( $$TrainingNotifiedRiddlesTableAnnotationComposer a) f
        ) {
                final $$TrainingNotifiedRiddlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingNotifiedRiddles,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingNotifiedRiddlesTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingNotifiedRiddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        Expression<T> trainingAttemptsRefs<T extends Object>(
          Expression<T> Function( $$TrainingAttemptsTableAnnotationComposer a) f
        ) {
                final $$TrainingAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trainingAttempts,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingAttemptsTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$TrainingSessionsTableTableManager extends RootTableManager    <_$AppDatabase,
    $TrainingSessionsTable,
    TrainingSession,
    $$TrainingSessionsTableFilterComposer,
    $$TrainingSessionsTableOrderingComposer,
    $$TrainingSessionsTableAnnotationComposer,
    $$TrainingSessionsTableCreateCompanionBuilder,
    $$TrainingSessionsTableUpdateCompanionBuilder,
    (TrainingSession,$$TrainingSessionsTableReferences),
    TrainingSession,
    PrefetchHooks Function({bool mapId,bool trainingNotifiedRiddlesRefs,bool trainingAttemptsRefs})
    > {
    $$TrainingSessionsTableTableManager(_$AppDatabase db, $TrainingSessionsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$TrainingSessionsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$TrainingSessionsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$TrainingSessionsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String> mapId = const Value.absent(),Value<DateTime> startedAt = const Value.absent(),Value<DateTime> endsAt = const Value.absent(),Value<String> poolJson = const Value.absent(),Value<String> scheduledJson = const Value.absent(),Value<DateTime?> completedAt = const Value.absent(),})=> TrainingSessionsCompanion(id: id,mapId: mapId,startedAt: startedAt,endsAt: endsAt,poolJson: poolJson,scheduledJson: scheduledJson,completedAt: completedAt,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required String mapId,Value<DateTime> startedAt = const Value.absent(),required DateTime endsAt,Value<String> poolJson = const Value.absent(),Value<String> scheduledJson = const Value.absent(),Value<DateTime?> completedAt = const Value.absent(),})=> TrainingSessionsCompanion.insert(id: id,mapId: mapId,startedAt: startedAt,endsAt: endsAt,poolJson: poolJson,scheduledJson: scheduledJson,completedAt: completedAt,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$TrainingSessionsTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({mapId = false,trainingNotifiedRiddlesRefs = false,trainingAttemptsRefs = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             if (trainingNotifiedRiddlesRefs) db.trainingNotifiedRiddles,if (trainingAttemptsRefs) db.trainingAttempts
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (mapId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mapId,
                    referencedTable:
                        $$TrainingSessionsTableReferences._mapIdTable(db),
                    referencedColumn:
                        $$TrainingSessionsTableReferences._mapIdTable(db).id,
                  ) as T;
               }

                return state;
              }
,
            getPrefetchedDataCallback: (items) async {
            return [
                      if (trainingNotifiedRiddlesRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$TrainingSessionsTableReferences._trainingNotifiedRiddlesRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$TrainingSessionsTableReferences(db, table, p0).trainingNotifiedRiddlesRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.sessionId == item.id),
                  typedResults: items)
            ,          if (trainingAttemptsRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$TrainingSessionsTableReferences._trainingAttemptsRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$TrainingSessionsTableReferences(db, table, p0).trainingAttemptsRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.sessionId == item.id),
                  typedResults: items)
            
                ];
              },
          );
        }
,
        ));
        }
    typedef $$TrainingSessionsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $TrainingSessionsTable,
    TrainingSession,
    $$TrainingSessionsTableFilterComposer,
    $$TrainingSessionsTableOrderingComposer,
    $$TrainingSessionsTableAnnotationComposer,
    $$TrainingSessionsTableCreateCompanionBuilder,
    $$TrainingSessionsTableUpdateCompanionBuilder,
    (TrainingSession,$$TrainingSessionsTableReferences),
    TrainingSession,
    PrefetchHooks Function({bool mapId,bool trainingNotifiedRiddlesRefs,bool trainingAttemptsRefs})
    >;typedef $$TrainingNotifiedRiddlesTableCreateCompanionBuilder = TrainingNotifiedRiddlesCompanion Function({Value<int> id,required int sessionId,required String mapId,required int riddleId,Value<DateTime> notifiedAt,});
typedef $$TrainingNotifiedRiddlesTableUpdateCompanionBuilder = TrainingNotifiedRiddlesCompanion Function({Value<int> id,Value<int> sessionId,Value<String> mapId,Value<int> riddleId,Value<DateTime> notifiedAt,});
      final class $$TrainingNotifiedRiddlesTableReferences extends BaseReferences<
        _$AppDatabase,
        $TrainingNotifiedRiddlesTable,
        TrainingNotifiedRiddle> {
        $$TrainingNotifiedRiddlesTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $TrainingSessionsTable _sessionIdTable(_$AppDatabase db) => 
            db.trainingSessions.createAlias($_aliasNameGenerator(
            db.trainingNotifiedRiddles.sessionId,
            db.trainingSessions.id));
          

        $$TrainingSessionsTableProcessedTableManager? get sessionId {
          if ($_item.sessionId == null) return null;
          final manager = $$TrainingSessionsTableTableManager($_db, $_db.trainingSessions).filter((f) => f.id($_item.sessionId!));
          final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }

                  static $RiddlesTable _riddleIdTable(_$AppDatabase db) => 
            db.riddles.createAlias($_aliasNameGenerator(
            db.trainingNotifiedRiddles.riddleId,
            db.riddles.id));
          

        $$RiddlesTableProcessedTableManager? get riddleId {
          if ($_item.riddleId == null) return null;
          final manager = $$RiddlesTableTableManager($_db, $_db.riddles).filter((f) => f.id($_item.riddleId!));
          final item = $_typedResult.readTableOrNull(_riddleIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }


      }class $$TrainingNotifiedRiddlesTableFilterComposer extends Composer<
        _$AppDatabase,
        $TrainingNotifiedRiddlesTable> {
        $$TrainingNotifiedRiddlesTableFilterComposer({
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
      
ColumnFilters<String> get mapId => $composableBuilder(
      column: $table.mapId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get notifiedAt => $composableBuilder(
      column: $table.notifiedAt,
      builder: (column) => 
      ColumnFilters(column));
      
        $$TrainingSessionsTableFilterComposer get sessionId {
                final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableFilterComposer(
              $db: $db,
              $table: $db.trainingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        $$RiddlesTableFilterComposer get riddleId {
                final $$RiddlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.riddleId,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableFilterComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$TrainingNotifiedRiddlesTableOrderingComposer extends Composer<
        _$AppDatabase,
        $TrainingNotifiedRiddlesTable> {
        $$TrainingNotifiedRiddlesTableOrderingComposer({
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
      
ColumnOrderings<String> get mapId => $composableBuilder(
      column: $table.mapId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get notifiedAt => $composableBuilder(
      column: $table.notifiedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
        $$TrainingSessionsTableOrderingComposer get sessionId {
                final $$TrainingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.trainingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        $$RiddlesTableOrderingComposer get riddleId {
                final $$RiddlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.riddleId,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableOrderingComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$TrainingNotifiedRiddlesTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $TrainingNotifiedRiddlesTable> {
        $$TrainingNotifiedRiddlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get mapId => $composableBuilder(
      column: $table.mapId,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get notifiedAt => $composableBuilder(
      column: $table.notifiedAt,
      builder: (column) => column);
      
        $$TrainingSessionsTableAnnotationComposer get sessionId {
                final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        $$RiddlesTableAnnotationComposer get riddleId {
                final $$RiddlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.riddleId,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableAnnotationComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$TrainingNotifiedRiddlesTableTableManager extends RootTableManager    <_$AppDatabase,
    $TrainingNotifiedRiddlesTable,
    TrainingNotifiedRiddle,
    $$TrainingNotifiedRiddlesTableFilterComposer,
    $$TrainingNotifiedRiddlesTableOrderingComposer,
    $$TrainingNotifiedRiddlesTableAnnotationComposer,
    $$TrainingNotifiedRiddlesTableCreateCompanionBuilder,
    $$TrainingNotifiedRiddlesTableUpdateCompanionBuilder,
    (TrainingNotifiedRiddle,$$TrainingNotifiedRiddlesTableReferences),
    TrainingNotifiedRiddle,
    PrefetchHooks Function({bool sessionId,bool riddleId})
    > {
    $$TrainingNotifiedRiddlesTableTableManager(_$AppDatabase db, $TrainingNotifiedRiddlesTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$TrainingNotifiedRiddlesTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$TrainingNotifiedRiddlesTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$TrainingNotifiedRiddlesTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int> sessionId = const Value.absent(),Value<String> mapId = const Value.absent(),Value<int> riddleId = const Value.absent(),Value<DateTime> notifiedAt = const Value.absent(),})=> TrainingNotifiedRiddlesCompanion(id: id,sessionId: sessionId,mapId: mapId,riddleId: riddleId,notifiedAt: notifiedAt,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required int sessionId,required String mapId,required int riddleId,Value<DateTime> notifiedAt = const Value.absent(),})=> TrainingNotifiedRiddlesCompanion.insert(id: id,sessionId: sessionId,mapId: mapId,riddleId: riddleId,notifiedAt: notifiedAt,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$TrainingNotifiedRiddlesTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({sessionId = false,riddleId = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (sessionId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$TrainingNotifiedRiddlesTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$TrainingNotifiedRiddlesTableReferences._sessionIdTable(db).id,
                  ) as T;
               }
                  if (riddleId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.riddleId,
                    referencedTable:
                        $$TrainingNotifiedRiddlesTableReferences._riddleIdTable(db),
                    referencedColumn:
                        $$TrainingNotifiedRiddlesTableReferences._riddleIdTable(db).id,
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
    typedef $$TrainingNotifiedRiddlesTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $TrainingNotifiedRiddlesTable,
    TrainingNotifiedRiddle,
    $$TrainingNotifiedRiddlesTableFilterComposer,
    $$TrainingNotifiedRiddlesTableOrderingComposer,
    $$TrainingNotifiedRiddlesTableAnnotationComposer,
    $$TrainingNotifiedRiddlesTableCreateCompanionBuilder,
    $$TrainingNotifiedRiddlesTableUpdateCompanionBuilder,
    (TrainingNotifiedRiddle,$$TrainingNotifiedRiddlesTableReferences),
    TrainingNotifiedRiddle,
    PrefetchHooks Function({bool sessionId,bool riddleId})
    >;typedef $$TrainingAttemptsTableCreateCompanionBuilder = TrainingAttemptsCompanion Function({Value<int> id,required int sessionId,required int riddleId,required bool correct,Value<DateTime> answeredAt,});
typedef $$TrainingAttemptsTableUpdateCompanionBuilder = TrainingAttemptsCompanion Function({Value<int> id,Value<int> sessionId,Value<int> riddleId,Value<bool> correct,Value<DateTime> answeredAt,});
      final class $$TrainingAttemptsTableReferences extends BaseReferences<
        _$AppDatabase,
        $TrainingAttemptsTable,
        TrainingAttempt> {
        $$TrainingAttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $TrainingSessionsTable _sessionIdTable(_$AppDatabase db) => 
            db.trainingSessions.createAlias($_aliasNameGenerator(
            db.trainingAttempts.sessionId,
            db.trainingSessions.id));
          

        $$TrainingSessionsTableProcessedTableManager? get sessionId {
          if ($_item.sessionId == null) return null;
          final manager = $$TrainingSessionsTableTableManager($_db, $_db.trainingSessions).filter((f) => f.id($_item.sessionId!));
          final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }

                  static $RiddlesTable _riddleIdTable(_$AppDatabase db) => 
            db.riddles.createAlias($_aliasNameGenerator(
            db.trainingAttempts.riddleId,
            db.riddles.id));
          

        $$RiddlesTableProcessedTableManager? get riddleId {
          if ($_item.riddleId == null) return null;
          final manager = $$RiddlesTableTableManager($_db, $_db.riddles).filter((f) => f.id($_item.riddleId!));
          final item = $_typedResult.readTableOrNull(_riddleIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }


      }class $$TrainingAttemptsTableFilterComposer extends Composer<
        _$AppDatabase,
        $TrainingAttemptsTable> {
        $$TrainingAttemptsTableFilterComposer({
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
      
ColumnFilters<bool> get correct => $composableBuilder(
      column: $table.correct,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt,
      builder: (column) => 
      ColumnFilters(column));
      
        $$TrainingSessionsTableFilterComposer get sessionId {
                final $$TrainingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableFilterComposer(
              $db: $db,
              $table: $db.trainingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        $$RiddlesTableFilterComposer get riddleId {
                final $$RiddlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.riddleId,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableFilterComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$TrainingAttemptsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $TrainingAttemptsTable> {
        $$TrainingAttemptsTableOrderingComposer({
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
      
ColumnOrderings<bool> get correct => $composableBuilder(
      column: $table.correct,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt,
      builder: (column) => 
      ColumnOrderings(column));
      
        $$TrainingSessionsTableOrderingComposer get sessionId {
                final $$TrainingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.trainingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        $$RiddlesTableOrderingComposer get riddleId {
                final $$RiddlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.riddleId,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableOrderingComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$TrainingAttemptsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $TrainingAttemptsTable> {
        $$TrainingAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<bool> get correct => $composableBuilder(
      column: $table.correct,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt,
      builder: (column) => column);
      
        $$TrainingSessionsTableAnnotationComposer get sessionId {
                final $$TrainingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trainingSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$TrainingSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        $$RiddlesTableAnnotationComposer get riddleId {
                final $$RiddlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.riddleId,
      referencedTable: $db.riddles,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$RiddlesTableAnnotationComposer(
              $db: $db,
              $table: $db.riddles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$TrainingAttemptsTableTableManager extends RootTableManager    <_$AppDatabase,
    $TrainingAttemptsTable,
    TrainingAttempt,
    $$TrainingAttemptsTableFilterComposer,
    $$TrainingAttemptsTableOrderingComposer,
    $$TrainingAttemptsTableAnnotationComposer,
    $$TrainingAttemptsTableCreateCompanionBuilder,
    $$TrainingAttemptsTableUpdateCompanionBuilder,
    (TrainingAttempt,$$TrainingAttemptsTableReferences),
    TrainingAttempt,
    PrefetchHooks Function({bool sessionId,bool riddleId})
    > {
    $$TrainingAttemptsTableTableManager(_$AppDatabase db, $TrainingAttemptsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$TrainingAttemptsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$TrainingAttemptsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$TrainingAttemptsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int> sessionId = const Value.absent(),Value<int> riddleId = const Value.absent(),Value<bool> correct = const Value.absent(),Value<DateTime> answeredAt = const Value.absent(),})=> TrainingAttemptsCompanion(id: id,sessionId: sessionId,riddleId: riddleId,correct: correct,answeredAt: answeredAt,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required int sessionId,required int riddleId,required bool correct,Value<DateTime> answeredAt = const Value.absent(),})=> TrainingAttemptsCompanion.insert(id: id,sessionId: sessionId,riddleId: riddleId,correct: correct,answeredAt: answeredAt,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$TrainingAttemptsTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({sessionId = false,riddleId = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (sessionId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$TrainingAttemptsTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$TrainingAttemptsTableReferences._sessionIdTable(db).id,
                  ) as T;
               }
                  if (riddleId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.riddleId,
                    referencedTable:
                        $$TrainingAttemptsTableReferences._riddleIdTable(db),
                    referencedColumn:
                        $$TrainingAttemptsTableReferences._riddleIdTable(db).id,
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
    typedef $$TrainingAttemptsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $TrainingAttemptsTable,
    TrainingAttempt,
    $$TrainingAttemptsTableFilterComposer,
    $$TrainingAttemptsTableOrderingComposer,
    $$TrainingAttemptsTableAnnotationComposer,
    $$TrainingAttemptsTableCreateCompanionBuilder,
    $$TrainingAttemptsTableUpdateCompanionBuilder,
    (TrainingAttempt,$$TrainingAttemptsTableReferences),
    TrainingAttempt,
    PrefetchHooks Function({bool sessionId,bool riddleId})
    >;typedef $$DownloadedPacksTableCreateCompanionBuilder = DownloadedPacksCompanion Function({required String id,required String title,required String shareCode,Value<String?> creatorId,Value<DateTime> downloadedAt,Value<int> rowid,});
typedef $$DownloadedPacksTableUpdateCompanionBuilder = DownloadedPacksCompanion Function({Value<String> id,Value<String> title,Value<String> shareCode,Value<String?> creatorId,Value<DateTime> downloadedAt,Value<int> rowid,});
      final class $$DownloadedPacksTableReferences extends BaseReferences<
        _$AppDatabase,
        $DownloadedPacksTable,
        DownloadedPack> {
        $$DownloadedPacksTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                  
                  static MultiTypedResultKey<
          $DownloadedPackMapsTable,
          List<DownloadedPackMap>
        > _downloadedPackMapsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(
          db.downloadedPackMaps, 
          aliasName: $_aliasNameGenerator(
            db.downloadedPacks.id,
            db.downloadedPackMaps.packId)
        );

          $$DownloadedPackMapsTableProcessedTableManager get downloadedPackMapsRefs {
        final manager = $$DownloadedPackMapsTableTableManager(
            $_db, $_db.downloadedPackMaps
            ).filter(
              (f) => f.packId.id(
              $_item.id
            )
          );

          final cache = $_typedResult.readTableOrNull(_downloadedPackMapsRefsTable($_db));
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));


        }
        

      }class $$DownloadedPacksTableFilterComposer extends Composer<
        _$AppDatabase,
        $DownloadedPacksTable> {
        $$DownloadedPacksTableFilterComposer({
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
      
ColumnFilters<String> get shareCode => $composableBuilder(
      column: $table.shareCode,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get creatorId => $composableBuilder(
      column: $table.creatorId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => 
      ColumnFilters(column));
      
        Expression<bool> downloadedPackMapsRefs(
          Expression<bool> Function( $$DownloadedPackMapsTableFilterComposer f) f
        ) {
                final $$DownloadedPackMapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadedPackMaps,
      getReferencedColumn: (t) => t.packId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$DownloadedPackMapsTableFilterComposer(
              $db: $db,
              $table: $db.downloadedPackMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$DownloadedPacksTableOrderingComposer extends Composer<
        _$AppDatabase,
        $DownloadedPacksTable> {
        $$DownloadedPacksTableOrderingComposer({
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
      
ColumnOrderings<String> get shareCode => $composableBuilder(
      column: $table.shareCode,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get creatorId => $composableBuilder(
      column: $table.creatorId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$DownloadedPacksTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $DownloadedPacksTable> {
        $$DownloadedPacksTableAnnotationComposer({
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
      
GeneratedColumn<String> get shareCode => $composableBuilder(
      column: $table.shareCode,
      builder: (column) => column);
      
GeneratedColumn<String> get creatorId => $composableBuilder(
      column: $table.creatorId,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => column);
      
        Expression<T> downloadedPackMapsRefs<T extends Object>(
          Expression<T> Function( $$DownloadedPackMapsTableAnnotationComposer a) f
        ) {
                final $$DownloadedPackMapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadedPackMaps,
      getReferencedColumn: (t) => t.packId,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$DownloadedPackMapsTableAnnotationComposer(
              $db: $db,
              $table: $db.downloadedPackMaps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return f(composer);
        }

        }
      class $$DownloadedPacksTableTableManager extends RootTableManager    <_$AppDatabase,
    $DownloadedPacksTable,
    DownloadedPack,
    $$DownloadedPacksTableFilterComposer,
    $$DownloadedPacksTableOrderingComposer,
    $$DownloadedPacksTableAnnotationComposer,
    $$DownloadedPacksTableCreateCompanionBuilder,
    $$DownloadedPacksTableUpdateCompanionBuilder,
    (DownloadedPack,$$DownloadedPacksTableReferences),
    DownloadedPack,
    PrefetchHooks Function({bool downloadedPackMapsRefs})
    > {
    $$DownloadedPacksTableTableManager(_$AppDatabase db, $DownloadedPacksTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$DownloadedPacksTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$DownloadedPacksTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$DownloadedPacksTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<String> id = const Value.absent(),Value<String> title = const Value.absent(),Value<String> shareCode = const Value.absent(),Value<String?> creatorId = const Value.absent(),Value<DateTime> downloadedAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> DownloadedPacksCompanion(id: id,title: title,shareCode: shareCode,creatorId: creatorId,downloadedAt: downloadedAt,rowid: rowid,),
        createCompanionCallback: ({required String id,required String title,required String shareCode,Value<String?> creatorId = const Value.absent(),Value<DateTime> downloadedAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> DownloadedPacksCompanion.insert(id: id,title: title,shareCode: shareCode,creatorId: creatorId,downloadedAt: downloadedAt,rowid: rowid,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$DownloadedPacksTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({downloadedPackMapsRefs = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             if (downloadedPackMapsRefs) db.downloadedPackMaps
            ],
            addJoins: null,
            getPrefetchedDataCallback: (items) async {
            return [
                      if (downloadedPackMapsRefs) await $_getPrefetchedData(
                  currentTable: table,
                  referencedTable:
                      $$DownloadedPacksTableReferences._downloadedPackMapsRefsTable(db),
                  managerFromTypedResult: (p0) =>
                      $$DownloadedPacksTableReferences(db, table, p0).downloadedPackMapsRefs,
                  referencedItemsForCurrentItem: (item, referencedItems) =>
                      referencedItems.where((e) => e.packId == item.id),
                  typedResults: items)
            
                ];
              },
          );
        }
,
        ));
        }
    typedef $$DownloadedPacksTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $DownloadedPacksTable,
    DownloadedPack,
    $$DownloadedPacksTableFilterComposer,
    $$DownloadedPacksTableOrderingComposer,
    $$DownloadedPacksTableAnnotationComposer,
    $$DownloadedPacksTableCreateCompanionBuilder,
    $$DownloadedPacksTableUpdateCompanionBuilder,
    (DownloadedPack,$$DownloadedPacksTableReferences),
    DownloadedPack,
    PrefetchHooks Function({bool downloadedPackMapsRefs})
    >;typedef $$DownloadedPackMapsTableCreateCompanionBuilder = DownloadedPackMapsCompanion Function({required String id,required String packId,required String localMapId,required DateTime remoteUpdatedAt,Value<int> rowid,});
typedef $$DownloadedPackMapsTableUpdateCompanionBuilder = DownloadedPackMapsCompanion Function({Value<String> id,Value<String> packId,Value<String> localMapId,Value<DateTime> remoteUpdatedAt,Value<int> rowid,});
      final class $$DownloadedPackMapsTableReferences extends BaseReferences<
        _$AppDatabase,
        $DownloadedPackMapsTable,
        DownloadedPackMap> {
        $$DownloadedPackMapsTableReferences(super.$_db, super.$_table, super.$_typedResult);
        
                          static $DownloadedPacksTable _packIdTable(_$AppDatabase db) => 
            db.downloadedPacks.createAlias($_aliasNameGenerator(
            db.downloadedPackMaps.packId,
            db.downloadedPacks.id));
          

        $$DownloadedPacksTableProcessedTableManager? get packId {
          if ($_item.packId == null) return null;
          final manager = $$DownloadedPacksTableTableManager($_db, $_db.downloadedPacks).filter((f) => f.id($_item.packId!));
          final item = $_typedResult.readTableOrNull(_packIdTable($_db));
          if (item == null) return manager;
          return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
        }


      }class $$DownloadedPackMapsTableFilterComposer extends Composer<
        _$AppDatabase,
        $DownloadedPackMapsTable> {
        $$DownloadedPackMapsTableFilterComposer({
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
      
ColumnFilters<String> get localMapId => $composableBuilder(
      column: $table.localMapId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => 
      ColumnFilters(column));
      
        $$DownloadedPacksTableFilterComposer get packId {
                final $$DownloadedPacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.downloadedPacks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$DownloadedPacksTableFilterComposer(
              $db: $db,
              $table: $db.downloadedPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$DownloadedPackMapsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $DownloadedPackMapsTable> {
        $$DownloadedPackMapsTableOrderingComposer({
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
      
ColumnOrderings<String> get localMapId => $composableBuilder(
      column: $table.localMapId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
        $$DownloadedPacksTableOrderingComposer get packId {
                final $$DownloadedPacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.downloadedPacks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$DownloadedPacksTableOrderingComposer(
              $db: $db,
              $table: $db.downloadedPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$DownloadedPackMapsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $DownloadedPackMapsTable> {
        $$DownloadedPackMapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<String> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get localMapId => $composableBuilder(
      column: $table.localMapId,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get remoteUpdatedAt => $composableBuilder(
      column: $table.remoteUpdatedAt,
      builder: (column) => column);
      
        $$DownloadedPacksTableAnnotationComposer get packId {
                final $$DownloadedPacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.downloadedPacks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder,{$addJoinBuilderToRootComposer,$removeJoinBuilderFromRootComposer }) => 
      $$DownloadedPacksTableAnnotationComposer(
              $db: $db,
              $table: $db.downloadedPacks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
        ));
          return composer;
        }
        }
      class $$DownloadedPackMapsTableTableManager extends RootTableManager    <_$AppDatabase,
    $DownloadedPackMapsTable,
    DownloadedPackMap,
    $$DownloadedPackMapsTableFilterComposer,
    $$DownloadedPackMapsTableOrderingComposer,
    $$DownloadedPackMapsTableAnnotationComposer,
    $$DownloadedPackMapsTableCreateCompanionBuilder,
    $$DownloadedPackMapsTableUpdateCompanionBuilder,
    (DownloadedPackMap,$$DownloadedPackMapsTableReferences),
    DownloadedPackMap,
    PrefetchHooks Function({bool packId})
    > {
    $$DownloadedPackMapsTableTableManager(_$AppDatabase db, $DownloadedPackMapsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$DownloadedPackMapsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$DownloadedPackMapsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$DownloadedPackMapsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<String> id = const Value.absent(),Value<String> packId = const Value.absent(),Value<String> localMapId = const Value.absent(),Value<DateTime> remoteUpdatedAt = const Value.absent(),Value<int> rowid = const Value.absent(),})=> DownloadedPackMapsCompanion(id: id,packId: packId,localMapId: localMapId,remoteUpdatedAt: remoteUpdatedAt,rowid: rowid,),
        createCompanionCallback: ({required String id,required String packId,required String localMapId,required DateTime remoteUpdatedAt,Value<int> rowid = const Value.absent(),})=> DownloadedPackMapsCompanion.insert(id: id,packId: packId,localMapId: localMapId,remoteUpdatedAt: remoteUpdatedAt,rowid: rowid,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), $$DownloadedPackMapsTableReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback:         ({packId = false}){
          return PrefetchHooks(
            db: db,
            explicitlyWatchedTables: [
             
            ],
            addJoins: <T extends TableManagerState<dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic,dynamic>>(state) {

                                  if (packId){
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.packId,
                    referencedTable:
                        $$DownloadedPackMapsTableReferences._packIdTable(db),
                    referencedColumn:
                        $$DownloadedPackMapsTableReferences._packIdTable(db).id,
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
    typedef $$DownloadedPackMapsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $DownloadedPackMapsTable,
    DownloadedPackMap,
    $$DownloadedPackMapsTableFilterComposer,
    $$DownloadedPackMapsTableOrderingComposer,
    $$DownloadedPackMapsTableAnnotationComposer,
    $$DownloadedPackMapsTableCreateCompanionBuilder,
    $$DownloadedPackMapsTableUpdateCompanionBuilder,
    (DownloadedPackMap,$$DownloadedPackMapsTableReferences),
    DownloadedPackMap,
    PrefetchHooks Function({bool packId})
    >;class $AppDatabaseManager {
final _$AppDatabase _db;
$AppDatabaseManager(this._db);
$$FoldersTableTableManager get folders => $$FoldersTableTableManager(_db, _db.folders);
$$RiddleMapsTableTableManager get riddleMaps => $$RiddleMapsTableTableManager(_db, _db.riddleMaps);
$$RiddlesTableTableManager get riddles => $$RiddlesTableTableManager(_db, _db.riddles);
$$PlaySessionsTableTableManager get playSessions => $$PlaySessionsTableTableManager(_db, _db.playSessions);
$$TrainingSessionsTableTableManager get trainingSessions => $$TrainingSessionsTableTableManager(_db, _db.trainingSessions);
$$TrainingNotifiedRiddlesTableTableManager get trainingNotifiedRiddles => $$TrainingNotifiedRiddlesTableTableManager(_db, _db.trainingNotifiedRiddles);
$$TrainingAttemptsTableTableManager get trainingAttempts => $$TrainingAttemptsTableTableManager(_db, _db.trainingAttempts);
$$DownloadedPacksTableTableManager get downloadedPacks => $$DownloadedPacksTableTableManager(_db, _db.downloadedPacks);
$$DownloadedPackMapsTableTableManager get downloadedPackMaps => $$DownloadedPackMapsTableTableManager(_db, _db.downloadedPackMaps);
}
