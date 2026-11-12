import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// Ô NHẬP BÌNH LUẬN (CommentInputBox)
class CommentInputBox extends StatefulWidget {
  const CommentInputBox({
    super.key,
    required this.isSignedIn,
    required this.onSubmit,
    this.initialText,
    this.isEditing = false,
    this.onCancelEdit,
  });

  final bool isSignedIn;
  final Future<bool> Function(String content) onSubmit;
  final String? initialText;
  final bool isEditing;
  final VoidCallback? onCancelEdit;

  @override
  State<CommentInputBox> createState() => _CommentInputBoxState();
}

class _CommentInputBoxState extends State<CommentInputBox> {
  late final TextEditingController _controller;
  bool _isSending = false;
  bool _hasInteracted = false;

  String? get _contentError {
    if (!_hasInteracted) return null;
    if (_controller.text.isEmpty) return 'Vui lòng nhập nội dung bình luận.';
    if (_controller.text.trim().isEmpty) {
      return 'Vui lòng nhập nội dung bình luận, không chỉ khoảng trắng hoặc xuống dòng.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant CommentInputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      _hasInteracted = false;
      _controller.text = widget.initialText ?? '';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final success = await widget.onSubmit(text);
    if (!mounted) return;

    setState(() => _isSending = false);
    if (success) {
      _controller.clear();
      setState(() => _hasInteracted = false);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Nếu độc giả chưa đăng nhập: Yêu cầu đăng nhập để bình luận
    if (!widget.isSignedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(top: BorderSide(color: colors.borderDefault)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Đăng nhập để tham gia bình luận cùng độc giả khác.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(width: AppDimensions.space3),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBrand,
                foregroundColor: colors.textOnBrand,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space3,
                  vertical: AppDimensions.space2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              onPressed: () => context.push(AppPaths.signIn),
              child: const Text('Đăng nhập', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trạng thái đang chỉnh sửa bình luận
            if (widget.isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space2),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: colors.primaryBrand,
                    ),
                    const SizedBox(width: AppDimensions.space1),
                    Expanded(
                      child: Text(
                        'Đang chỉnh sửa bình luận',
                        style: TextStyle(
                          color: colors.primaryBrand,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: widget.onCancelEdit,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      errorText: _contentError,
                      errorMaxLines: 4,
                      hintText: widget.isEditing
                          ? 'Cập nhật bình luận của bạn...'
                          : 'Viết bình luận cảm nghĩ...',
                      hintStyle: TextStyle(
                        color: colors.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: colors.bgCanvas,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space3,
                        vertical: AppDimensions.space2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        borderSide: BorderSide(color: colors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        borderSide: BorderSide(color: colors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        borderSide: BorderSide(
                          color: colors.primaryBrand,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() => _hasInteracted = true),
                  ),
                ),
                const SizedBox(width: AppDimensions.space2),
                IconButton(
                  icon: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primaryBrand,
                            ),
                          ),
                        )
                      : Icon(
                          widget.isEditing
                              ? Icons.check_circle_rounded
                              : Icons.send_rounded,
                          color: _controller.text.trim().isEmpty
                              ? colors.textDisabled
                              : colors.primaryBrand,
                        ),
                  tooltip: widget.isEditing ? 'Lưu chỉnh sửa' : 'Gửi bình luận',
                  onPressed: _controller.text.trim().isEmpty || _isSending
                      ? null
                      : _handleSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
