import 'package:flutter/foundation.dart';

@immutable
class UploadMediaResponseDto {
  const UploadMediaResponseDto({this.url, this.publicId});

  factory UploadMediaResponseDto.fromJson(Map<String, dynamic> json) {
    return UploadMediaResponseDto(
      url: (json['url'] ?? json['Url']) as String?,
      publicId: (json['publicId'] ?? json['PublicId']) as String?,
    );
  }

  final String? url;
  final String? publicId;
}
