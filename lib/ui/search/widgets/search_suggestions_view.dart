import 'package:flutter/material.dart';

import '../../../domain/models/search_sort_option.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// WIDGET - Hiển thị Danh sách gợi ý tức thì khi người dùng đang gõ
class SearchSuggestionsView extends StatelessWidget {
  final String query;
  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion> onSuggestionSelected;

  const SearchSuggestionsView({
    super.key,
    this.query = '',
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space2,
      ),
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: colors.borderDefault.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        final item = suggestions[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space2,
            vertical: 2,
          ),
          leading: _buildLeadingIcon(colors, item.type),
          title: _buildHighlightedTitle(item, colors),
          subtitle: item.subtitle != null
              ? Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                )
              : null,
          trailing: Icon(
            Icons.north_west_rounded,
            size: 16,
            color: colors.textSecondary.withValues(alpha: 0.7),
          ),
          onTap: () => onSuggestionSelected(item),
        );
      },
    );
  }

  Widget _buildHighlightedTitle(SearchSuggestion item, AppColors colors) {
    final baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: item.type == SearchSuggestionType.aiSemantic
          ? FontWeight.bold
          : FontWeight.w600,
      color: item.type == SearchSuggestionType.aiSemantic
          ? colors.primaryBrand
          : colors.textPrimary,
    );
    final cleanQuery = query.trim();
    final matchStart = cleanQuery.isEmpty
        ? -1
        : item.text.toLowerCase().indexOf(cleanQuery.toLowerCase());

    if (matchStart < 0) {
      return Text(
        item.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final matchEnd = matchStart + cleanQuery.length;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          if (matchStart > 0)
            TextSpan(text: item.text.substring(0, matchStart)),
          TextSpan(
            text: item.text.substring(matchStart, matchEnd),
            style: TextStyle(
              color: colors.primaryBrand,
              fontWeight: FontWeight.w800,
              backgroundColor: colors.bgBrandSubtle,
            ),
          ),
          if (matchEnd < item.text.length)
            TextSpan(text: item.text.substring(matchEnd)),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(AppColors colors, SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.aiSemantic:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.bgBrandSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, size: 16, color: colors.primaryBrand),
        );
      case SearchSuggestionType.series:
        return Icon(
          Icons.menu_book_rounded,
          size: 18,
          color: colors.textSecondary,
        );
      case SearchSuggestionType.author:
        return Icon(
          Icons.person_outline_rounded,
          size: 18,
          color: colors.textSecondary,
        );
      case SearchSuggestionType.genre:
        return Icon(
          Icons.label_outline_rounded,
          size: 18,
          color: colors.textSecondary,
        );
    }
  }
}
