import 'package:json_annotation/json_annotation.dart';

part 'cv.g.dart';

@JsonSerializable()
class Cv {
  final String id;
  final String fileName;
  final DateTime uploadDate;

  Cv({
    required this.id,
    required this.fileName,
    required this.uploadDate,
  });

  factory Cv.fromJson(Map<String, dynamic> json) => _$CvFromJson(json);

  Map<String, dynamic> toJson() => _$CvToJson(this);
}
