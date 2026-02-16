import 'package:flutter/material.dart';

/// A responsive grid that calculates columns based on a minimum card width.
///
/// - On mobile (1 column): uses ListView for natural height per item.
/// - On wider screens (2+ columns): uses GridView with fixed [mainAxisExtent].
///
/// Columns = min(maxColumns, availableWidth ~/ minCardWidth), clamped to 1..4.
class ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  /// Fixed height for each item in grid mode (2+ columns).
  final double mainAxisExtent;

  /// Minimum width a card must have. Columns are calculated from this.
  /// Default 360 ensures readable card content.
  final double minCardWidth;

  /// Spacing between items horizontally and vertically.
  final double spacing;

  /// Extra widget appended after all items (e.g. loading indicator).
  final Widget? trailing;

  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.mainAxisExtent,
    this.minCardWidth = 500,
    this.padding,
    this.controller,
    this.spacing = 12,
    this.trailing,
  });

  static int columnCount(double width, {double minCardWidth = 500}) {
    final cols = (width / minCardWidth).floor();
    return cols.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnCount(constraints.maxWidth, minCardWidth: minCardWidth);

        if (columns == 1) {
          // Single column — use ListView for natural item height
          final totalCount = itemCount + (trailing != null ? 1 : 0);
          return ListView.builder(
            controller: controller,
            padding: padding,
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (index >= itemCount) return trailing!;
              return itemBuilder(context, index);
            },
          );
        }

        // Multi-column — use GridView with fixed height
        final totalCount = itemCount + (trailing != null ? 1 : 0);
        return GridView.builder(
          controller: controller,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index >= itemCount) return trailing!;
            return itemBuilder(context, index);
          },
        );
      },
    );
  }
}
