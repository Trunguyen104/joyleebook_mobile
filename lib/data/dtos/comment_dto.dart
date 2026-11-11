class CommentDto {
  final String id;
  final String seriesId;
  final String? chapterId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;

  const CommentDto({
    required this.id,
    required this.seriesId,
    this.chapterId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isEdited,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return CommentDto(
      id: json['id']?.toString() ?? '',
      seriesId: json['seriesId']?.toString() ?? '',
      chapterId: json['chapterId']?.toString(),
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Độc giả',
      content: json['content']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seriesId': seriesId,
      if (chapterId != null) 'chapterId': chapterId,
      'userId': userId,
      'username': username,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }
}

class PagedCommentsDto {
  final List<CommentDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedCommentsDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedCommentsDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedCommentsDto(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CommentDto.fromJson)
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}
