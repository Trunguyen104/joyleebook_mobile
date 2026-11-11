import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// BOTTOM SHEET - Nhập câu mô tả gu đọc tự do cho AI
class AiCustomPromptBottomSheet extends StatefulWidget {
  final ValueChanged<String> onSubmitted;
  final String? initialPrompt;

  const AiCustomPromptBottomSheet({
    super.key,
    required this.onSubmitted,
    this.initialPrompt,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSubmitted,
    String? initialPrompt,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiCustomPromptBottomSheet(
        onSubmitted: onSubmitted,
        initialPrompt: initialPrompt,
      ),
    );
  }

  @override
  State<AiCustomPromptBottomSheet> createState() =>
      _AiCustomPromptBottomSheetState();
}

class _AiCustomPromptBottomSheetState extends State<AiCustomPromptBottomSheet> {
  late final TextEditingController _controller;
  bool _canSubmit = false;

  static const List<String> _suggestions = [
    'Tu tiên phế vật nghịch tập hài hước',
    'Ngôn tình ngọt sủng ấm áp chữa lành',
    'Kỳ ảo phiêu lưu dị giới phép thuật',
    'Hành động kịch tính báo thù giang hồ',
    'Trinh thám bí ẩn đấu trí nghẹt thở',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt ?? '');
    _canSubmit = _controller.text.trim().isNotEmpty;
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final valid = _controller.text.trim().isNotEmpty;
    if (valid != _canSubmit) {
      setState(() => _canSubmit = valid);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _submit(String prompt) {
    final text = prompt.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop();
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space4,
        AppDimensions.space3,
        AppDimensions.space4,
        AppDimensions.space4 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.space3),
                  decoration: BoxDecoration(
                    color: colors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Tiêu đề với Icon AI
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.bgBrandSubtle,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: colors.primaryBrand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tìm truyện cùng Trợ lý AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Mô tả gu đọc bạn thích để AI tìm kiếm theo ngữ nghĩa',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space3),

              // Ô nhập liệu
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 3,
                minLines: 2,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: "tìm truyện tu tiên nhân vật chính thông minh quyết đoán, cốt truyện chặt chẽ..."',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: colors.bgSurfaceSubtle,
                  contentPadding: const EdgeInsets.all(AppDimensions.space3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide(color: colors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide(
                      color: colors.primaryBrand,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: AppDimensions.space3),

              // Gợi ý mẫu (Suggestion Chips)
              Text(
                'Gợi ý mẫu từ độc giả:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.space2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    onTap: () {
                      _controller.text = s;
                      _submit(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurfaceSubtle,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(color: colors.borderDefault),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 14, color: colors.accent),
                          const SizedBox(width: 4),
                          Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space4),

              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSubmit
                      ? () => _submit(_controller.text)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryBrand,
                    foregroundColor: colors.textOnBrand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(
                    'AI Gợi ý ngay',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
