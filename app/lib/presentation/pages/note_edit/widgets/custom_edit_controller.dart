import 'package:flutter/material.dart';

/// This will only return the default composing style if the user did not search for something!
///
/// Otherwise it will highlight the searches and jump to them!
class CustomEditController extends TextEditingController {
  List<int> _searchPositions = <int>[];

  /// not zero based index of [_searchPositions]
  int _currentSearchPosition = 0;

  /// The text and size of the search pattern
  String _currentSearch = "";

  /// Updates the search positions for the new search text
  void updateSearch(String searchText) {
    _currentSearch = searchText;
    _currentSearchPosition = 0;
    if (searchSize == 0) {
      _searchPositions = <int>[];
    } else {
      _searchPositions = _currentSearch.allMatches(text).map((Match match) => match.start).toList();
    }
  }

  /// If [forward] is true, then this will move the current search position to the next element and otherwise to the
  /// previous element.
  ///
  /// This returns true if it has search elements to navigate to and otherwise false!
  bool moveSearch({required bool forward}) {
    if (_searchPositions.isNotEmpty) {
      if (forward) {
        if (++_currentSearchPosition > _searchPositions.length) {
          _currentSearchPosition = 1;
        }
      } else {
        if (--_currentSearchPosition <= 0) {
          _currentSearchPosition = _searchPositions.length;
        }
      }
      final int offset = _searchPositions[_currentSearchPosition - 1];
      selection = TextSelection.fromPosition(TextPosition(offset: offset));
      return true;
    } else {
      return false;
    }
  }

  int get currentSearchPosition => _currentSearchPosition;

  int get searchPositionAmount => _searchPositions.length;

  int get searchSize => _currentSearch.length;

  @override
  set text(String newText) {
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle? selectedColor =
        style?.merge(TextStyle(backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.80)));
    final TextStyle? highlightColor =
        style?.merge(TextStyle(backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.80)));

    final List<InlineSpan> children = <InlineSpan>[];
    int offset = 0;
    for (int i = 0; i < _searchPositions.length; ++i) {
      final int position = _searchPositions[i];
      final int charsBefore = position - offset;
      final TextStyle? myStyle = (i == _currentSearchPosition - 1) ? selectedColor : highlightColor;
      if (charsBefore > 0) {
        children.add(TextSpan(text: text.substring(offset, position), style: style));
      }
      children.add(TextSpan(text: text.substring(position, position + searchSize), style: myStyle));
      offset += charsBefore + searchSize;
    }

    // todo: improve performance for long texts with many search results. it would be better to then only already render
    // those results that are near the current scroll offset and rebuild when scrolling

    if (offset > 0) {
      if (offset < text.length) {
        children.add(TextSpan(text: text.substring(offset), style: style));
      }
      return TextSpan(style: style, children: children);
    } else {
      assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);
      final bool composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;
      if (composingRegionOutOfRange) {
        return TextSpan(style: style, text: text);
      }
      final TextStyle composingStyle = style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
          const TextStyle(decoration: TextDecoration.underline);
      return TextSpan(
        style: style,
        children: <TextSpan>[
          TextSpan(text: value.composing.textBefore(value.text)),
          TextSpan(
            style: composingStyle,
            text: value.composing.textInside(value.text),
          ),
          TextSpan(text: value.composing.textAfter(value.text)),
        ],
      );
    }
  }
}
