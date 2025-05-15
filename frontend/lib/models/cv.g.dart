// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cv _$CvFromJson(Map<String, dynamic> json) => Cv(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
    );

Map<String, dynamic> _$CvToJson(Cv instance) => <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'uploadDate': instance.uploadDate.toIso8601String(),
    };
