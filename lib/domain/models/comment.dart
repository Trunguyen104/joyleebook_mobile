import 'package:flutter/foundation.dart';

import '../../data/dtos/comment_dto.dart';

/// DOMAIN MODEL: Bình luận của độc giả
@immutable
class Comment {
  final String id;
  final String seriesId;
  final String? chapterId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;

  const Comment({
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

  factory Comment.fromDto(CommentDto dto) {
    return Comment(
      id: dto.id,
      seriesId: dto.seriesId,
      chapterId: dto.chapterId,
      userId: dto.userId,
      username: dto.username,
      content: dto.content,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      isEdited: dto.isEdited,
    );
  }

  Comment copyWith({
    String? id,
    String? seriesId,
    String? chapterId,
    String? userId,
    String? username,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return Comment(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      chapterId: chapterId ?? this.chapterId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          seriesId == other.seriesId &&
          chapterId == other.chapterId &&
          userId == other.userId &&
          username == other.username &&
          content == other.content &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          isEdited == other.isEdited;

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    chapterId,
    userId,
    username,
    content,
    createdAt,
    updatedAt,
    isEdited,
  );
}

/// DOMAIN MODEL: Danh sách bình luận phân trang
@immutable
class PagedComments {
  final List<Comment> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const PagedComments({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedComments.fromDto(PagedCommentsDto dto) {
    return PagedComments(
      items: dto.items.map(Comment.fromDto).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
      totalPages: dto.totalPages,
    );
  }

  PagedComments copyWith({
    List<Comment>? items,
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
  }) {
    return PagedComments(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
